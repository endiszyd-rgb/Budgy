import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import 'document_viewer_screen.dart';

class DocumentsScreen extends StatelessWidget {
  final AppDatabase db;
  const DocumentsScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumenty WZ')),
      body: StreamBuilder<List<ScannedDocument>>(
        stream: db.documentsDao.watchAllDocuments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Brak zeskanowanych dokumentów.\nUżyj przycisku + → "Skanuj dokument WZ"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          // Grupowanie po dacie skanowania
          final dayFmt = DateFormat('EEEE, dd MMMM yyyy', 'pl_PL');
          final grouped = <String, List<ScannedDocument>>{};
          for (final doc in docs) {
            final key = dayFmt.format(doc.scannedAt);
            grouped.putIfAbsent(key, () => []).add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final key = grouped.keys.elementAt(i);
              final items = grouped[key]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 13),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, j) =>
                        _DocumentThumbnail(document: items[j], db: db),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  final ScannedDocument document;
  final AppDatabase db;

  const _DocumentThumbnail({required this.document, required this.db});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'pl_PL');
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(
              document: document,
              onDelete: () => db.documentsDao.deleteDocument(document.id),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(document.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 40),
                    ),
                  ),
                  if (document.transactionId != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.wzNumber ?? 'Bez numeru',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(timeFmt.format(document.scannedAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      if (document.amount != null)
                        Text(moneyFmt.format(document.amount),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
