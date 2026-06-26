import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../transactions/add_transaction_screen.dart';
import '../../core/database/database.dart';
import '../../core/transitions.dart';

class WzScannerScreen extends StatefulWidget {
  final AppDatabase db;
  const WzScannerScreen({super.key, required this.db});

  @override
  State<WzScannerScreen> createState() => _WzScannerScreenState();
}

class _WzScannerScreenState extends State<WzScannerScreen> {
  File? _image;
  bool _processing = false;
  String? _rawText;
  WzParseResult? _parsed;
  int? _savedDocumentId;

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (xFile == null) return;
    setState(() {
      _image = File(xFile.path);
      _processing = true;
      _rawText = null;
      _parsed = null;
      _savedDocumentId = null;
    });
    await _runOcr(xFile.path);
  }

  Future<void> _runOcr(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);
      final text = recognized.text;
      final parsed = WzParseResult.fromText(text);
      final savedPath = await _persistImage(imagePath);
      final documentId = await widget.db.documentsDao.insertDocument(
        ScannedDocumentsCompanion.insert(
          imagePath: savedPath,
          wzNumber: Value(parsed.wzNumber),
          supplier: Value(parsed.supplier),
          amount: Value(parsed.amount),
          rawText: Value(text),
        ),
      );
      setState(() {
        _rawText = text;
        _parsed = parsed;
        _savedDocumentId = documentId;
        _processing = false;
      });
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd OCR: $e')));
      }
    } finally {
      recognizer.close();
    }
  }

  Future<String> _persistImage(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final wzDir = Directory(p.join(docsDir.path, 'wz_documents'));
    if (!await wzDir.exists()) await wzDir.create(recursive: true);
    final ext = p.extension(sourcePath);
    final fileName = '${const Uuid().v4()}$ext';
    final destPath = p.join(wzDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  void _proceed() {
    Navigator.pushReplacement(
      context,
      premiumRoute(
        AddTransactionScreen(
          db: widget.db,
          initialType: TransactionType.expense,
          prefillTitle: _parsed?.title ?? '',
          prefillAmount: _parsed?.amount,
          prefillWzNumber: _parsed?.wzNumber,
          sourceDocumentId: _savedDocumentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skan dokumentu WZ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informacja
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zrób zdjęcie dokumentu WZ lub wybierz z galerii. '
                        'System automatycznie odczyta numer, kwotę i dostawcę.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Przyciski wyboru zdjęcia
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text('Aparat', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 28),
                    label: const Text(
                      'Galeria',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Podgląd zdjęcia
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            // Przetwarzanie
            if (_processing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Rozpoznaję tekst...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            // Wyniki OCR
            if (_parsed != null) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rozpoznane dane',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_savedDocumentId != null)
                    Chip(
                      avatar: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      label: const Text(
                        'Zapisano w archiwum',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green.shade50,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _ResultRow(label: 'Numer WZ', value: _parsed!.wzNumber ?? '—'),
              _ResultRow(label: 'Dostawca', value: _parsed!.supplier ?? '—'),
              _ResultRow(
                label: 'Kwota',
                value: _parsed!.amount != null
                    ? '${_parsed!.amount!.toStringAsFixed(2)} zł'
                    : '—',
              ),
              _ResultRow(label: 'Data', value: _parsed!.date ?? '—'),
              const SizedBox(height: 8),
              Card(
                color: Colors.grey.shade100,
                child: ExpansionTile(
                  title: const Text(
                    'Surowy tekst OCR',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _rawText ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _proceed,
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Przejdź do formularza',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class WzParseResult {
  final String? wzNumber;
  final String? supplier;
  final double? amount;
  final String? date;
  final String? title;

  WzParseResult({
    this.wzNumber,
    this.supplier,
    this.amount,
    this.date,
    this.title,
  });

  factory WzParseResult.fromText(String text) {
    String? wzNumber, supplier, date;
    double? amount;

    final lines = text.split('\n').map((l) => l.trim()).toList();

    // Numer WZ: "WZ/2026/001", "WZ 2026/001", "WZ-001"
    final wzRegex = RegExp(r'WZ[/ -]?\d{4}[/ -]?\d+', caseSensitive: false);
    final wzMatch = wzRegex.firstMatch(text);
    if (wzMatch != null) wzNumber = wzMatch.group(0);

    // Data: "dd.mm.yyyy" lub "dd-mm-yyyy"
    final dateRegex = RegExp(r'\d{2}[.\-/]\d{2}[.\-/]\d{4}');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) date = dateMatch.group(0);

    // Kwota: szuka wartości z PLN/zł lub dużych liczb dziesiętnych
    final amountRegex = RegExp(
      r'(\d{1,6}[.,]\d{2})\s*(z[łl]|PLN|pln)',
      caseSensitive: false,
    );
    double? maxAmount;
    for (final m in amountRegex.allMatches(text)) {
      final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (val != null && (maxAmount == null || val > maxAmount)) {
        maxAmount = val;
      }
    }
    if (maxAmount == null) {
      // Bez waluty — szukaj największej liczby dziesiętnej
      final numRegex = RegExp(r'\b\d{1,6}[.,]\d{2}\b');
      for (final m in numRegex.allMatches(text)) {
        final val = double.tryParse(m.group(0)!.replaceAll(',', '.'));
        if (val != null && val > 1 && (maxAmount == null || val > maxAmount)) {
          maxAmount = val;
        }
      }
    }
    amount = maxAmount;

    // Dostawca: szuka linii po "dostawca:", "nabywca:", lub "firma:"
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('dostawca') ||
          lower.contains('sprzedawca') ||
          lower.contains('firma')) {
        final parts = line.split(RegExp(r'[:：]'));
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          supplier = parts[1].trim();
          break;
        }
      }
    }

    final title = wzNumber != null
        ? 'WZ $wzNumber${supplier != null ? " — $supplier" : ""}'
        : (supplier ?? 'Zakup z WZ');

    return WzParseResult(
      wzNumber: wzNumber,
      supplier: supplier,
      amount: amount,
      date: date,
      title: title,
    );
  }
}
