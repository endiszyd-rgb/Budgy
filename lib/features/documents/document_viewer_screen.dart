import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';

class DocumentViewerScreen extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback? onDelete;

  const DocumentViewerScreen({
    super.key,
    required this.document,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', 'pl_PL');
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(document.wzNumber ?? 'Dokument WZ'),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Usunąć dokument?'),
                  content: const Text(
                    'Zdjęcie zostanie usunięte z archiwum. Powiązana transakcja (jeśli istnieje) nie zostanie usunięta.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Anuluj'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        onDelete!();
                      },
                      child: const Text(
                        'Usuń',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(child: Image.file(File(document.imagePath))),
            ),
          ),
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Zeskanowano',
                  value: dateFmt.format(document.scannedAt),
                ),
                _InfoRow(label: 'Numer WZ', value: document.wzNumber ?? '—'),
                _InfoRow(label: 'Dostawca', value: document.supplier ?? '—'),
                _InfoRow(
                  label: 'Kwota',
                  value: document.amount != null
                      ? moneyFmt.format(document.amount)
                      : '—',
                ),
                _InfoRow(
                  label: 'Transakcja',
                  value: document.transactionId != null
                      ? 'Powiązana ✓'
                      : 'Brak',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
