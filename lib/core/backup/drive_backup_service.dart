import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

const _backupFileName = 'budgy_backup.zip';
const _backupFolderName = 'Budgy Backups';
const _prefsLastBackupKey = 'last_backup_at';
const _driveScopes = <String>[drive.DriveApi.driveFileScope];

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// google_sign_in 7.x splits identity (this class) from per-scope
/// authorization (see [_getDriveApi]) and requires an explicit
/// [GoogleSignIn.initialize] call before any other method.
class DriveBackupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final _userController = StreamController<GoogleSignInAccount?>.broadcast();
  Future<void>? _initFuture;
  GoogleSignInAccount? _currentUser;

  Future<void> _ensureInitialized() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    await _googleSignIn.initialize();
    _googleSignIn.authenticationEvents.listen((event) {
      _currentUser = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };
      _userController.add(_currentUser);
    });
  }

  GoogleSignInAccount? get currentUser => _currentUser;

  Stream<GoogleSignInAccount?> get onUserChanged => _userController.stream;

  Future<GoogleSignInAccount?> signInSilently() async {
    await _ensureInitialized();
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account != null) _currentUser = account;
      return account;
    } on GoogleSignInException {
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      final account = await _googleSignIn.authenticate();
      _currentUser = account;
      return account;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.disconnect();
    _currentUser = null;
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_prefsLastBackupKey);
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  Future<void> _setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastBackupKey, time.toIso8601String());
  }

  Future<drive.DriveApi> _getDriveApi() async {
    await _ensureInitialized();
    final account = currentUser ?? await signInSilently() ?? await signIn();
    if (account == null) {
      throw Exception('Logowanie do Google nie powiodło się');
    }
    var authHeaders = await account.authorizationClient.authorizationHeaders(
      _driveScopes,
    );
    if (authHeaders == null) {
      await account.authorizationClient.authorizeScopes(_driveScopes);
      authHeaders = await account.authorizationClient.authorizationHeaders(
        _driveScopes,
      );
    }
    if (authHeaders == null) {
      throw Exception('Brak autoryzacji dostępu do Google Drive');
    }
    final client = GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  Future<File> _createBackupZip(AppDatabase db) async {
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'budzet_warsztatu.sqlite'));
    final wzDir = Directory(p.join(docsDir.path, 'wz_documents'));

    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, _backupFileName);
    final zipFile = File(zipPath);
    if (await zipFile.exists()) await zipFile.delete();

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    if (await dbFile.exists()) {
      encoder.addFile(dbFile, 'database.sqlite');
    }
    if (await wzDir.exists()) {
      encoder.addDirectory(wzDir, includeDirName: true);
    }
    encoder.close();
    return zipFile;
  }

  Future<String?> _findBackupFolderId(drive.DriveApi api) async {
    final result = await api.files.list(
      q: "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id;
    }
    return null;
  }

  Future<String> _ensureBackupFolder(drive.DriveApi api) async {
    final existing = await _findBackupFolderId(api);
    if (existing != null) return existing;
    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }

  Future<drive.File?> _findExistingBackup(
    drive.DriveApi api,
    String folderId,
  ) async {
    final result = await api.files.list(
      q: "name = '$_backupFileName' and '$folderId' in parents and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first;
    }
    return null;
  }

  Future<void> backup(AppDatabase db) async {
    final api = await _getDriveApi();
    final zipFile = await _createBackupZip(db);
    final folderId = await _ensureBackupFolder(api);
    final existing = await _findExistingBackup(api, folderId);

    final media = drive.Media(zipFile.openRead(), await zipFile.length());

    if (existing != null) {
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
    } else {
      final file = drive.File()
        ..name = _backupFileName
        ..parents = [folderId];
      await api.files.create(file, uploadMedia: media);
    }

    await zipFile.delete();
    await _setLastBackupTime(DateTime.now());
  }

  /// Pobiera ostatni backup i wypakowuje go, nadpisując lokalne dane.
  /// Aplikacja powinna zostać zrestartowana po wywołaniu tej metody.
  Future<bool> restoreLatest(AppDatabase db) async {
    final api = await _getDriveApi();
    final folderId = await _findBackupFolderId(api);
    if (folderId == null) return false;
    final existing = await _findExistingBackup(api, folderId);
    if (existing == null) return false;

    final media =
        await api.files.get(
              existing.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, 'restore_$_backupFileName');
    final zipFile = File(zipPath);
    final sink = zipFile.openWrite();
    await media.stream.forEach(sink.add);
    await sink.close();

    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();

    final docsDir = await getApplicationDocumentsDirectory();
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final entry in archive) {
      final relativeName = entry.name == 'database.sqlite'
          ? 'budzet_warsztatu.sqlite'
          : entry.name;
      final outPath = p.join(docsDir.path, relativeName);
      if (entry.isFile) {
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    await zipFile.delete();
    return true;
  }
}
