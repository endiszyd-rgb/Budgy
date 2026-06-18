import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../../core/backup/drive_backup_service.dart';
import '../../core/database/database.dart';
import '../categories/categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase db;
  const SettingsScreen({super.key, required this.db});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = DriveBackupService();
  GoogleSignInAccount? _account;
  DateTime? _lastBackup;
  bool _busy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final account = await _backupService.signInSilently();
    final lastBackup = await _backupService.getLastBackupTime();
    setState(() {
      _account = account;
      _lastBackup = lastBackup;
    });
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final account = await _backupService.signIn();
      setState(() => _account = account);
    } catch (e) {
      _showError('Logowanie nie powiodło się: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await _backupService.signOut();
    setState(() => _account = null);
  }

  Future<void> _doBackup() async {
    setState(() {
      _busy = true;
      _statusMessage = 'Wykonuję backup...';
    });
    try {
      await _backupService.backup(widget.db);
      final lastBackup = await _backupService.getLastBackupTime();
      setState(() {
        _lastBackup = lastBackup;
        _statusMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Backup zapisany na Dysku Google ✓')));
      }
    } catch (e) {
      setState(() => _statusMessage = null);
      _showError('Backup nie powiódł się: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _doRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Przywrócić dane z Dysku?'),
        content: const Text(
            'Lokalne dane (transakcje, dokumenty) zostaną nadpisane danymi z ostatniego backupu. Tej operacji nie można odwrócić.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Przywróć', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _statusMessage = 'Przywracam dane...';
    });
    try {
      final found = await _backupService.restoreLatest(widget.db);
      setState(() => _statusMessage = null);
      if (!found) {
        _showError('Nie znaleziono backupu na Dysku Google');
        setState(() => _busy = false);
        return;
      }
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Dane przywrócone'),
            content: const Text(
                'Aplikacja zostanie teraz zamknięta. Uruchom ją ponownie, aby wczytać przywrócone dane.'),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Zamknij aplikację'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _statusMessage = null);
      _showError('Przywracanie nie powiodło się: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', 'pl_PL');
    final signedIn = _account != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_outlined, size: 28),
                      const SizedBox(width: 12),
                      Text('Backup na Dysku Google',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (signedIn) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _account!.photoUrl != null
                              ? NetworkImage(_account!.photoUrl!)
                              : null,
                          child: _account!.photoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_account!.displayName ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(_account!.email,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _signOut,
                          child: const Text('Wyloguj'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _lastBackup != null
                          ? 'Ostatni backup: ${dateFmt.format(_lastBackup!)}'
                          : 'Brak wykonanego backupu',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_statusMessage != null) ...[
                      Row(
                        children: [
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(_statusMessage!),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _doBackup,
                            icon: const Icon(Icons.backup),
                            label: const Text('Backup teraz'),
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _doRestore,
                            icon: const Icon(Icons.restore),
                            label: const Text('Przywróć'),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Zaloguj się kontem Google, aby wykonywać backup bazy danych i zeskanowanych dokumentów na Dysku Google.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _signIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Zaloguj się Google'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined, size: 28),
              title: const Text('Kategorie'),
              subtitle: const Text('Zmień nazwy, dodaj lub usuń kategorie'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoriesScreen(db: widget.db),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
