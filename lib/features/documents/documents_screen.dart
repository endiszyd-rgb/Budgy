import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/transitions.dart';
import '../../shared/widgets/hover_lift.dart';
import '../../shared/widgets/responsive_page.dart';
import '../../shared/widgets/staggered_fade_in.dart';
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Brak zeskanowanych dokumentów.\nUżyj przycisku "Dodaj" → "Skanuj dokument WZ"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
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

          // Indeks globalny per dokument (dla kaskady animacji) — wyliczony
          // z wyprzedzeniem, bo GridView.builder może wywołać itemBuilder
          // wielokrotnie dla tego samego j w trakcie layoutu.
          var runningIndex = 0;
          final groupStartIndex = <String, int>{};
          for (final key in grouped.keys) {
            groupStartIndex[key] = runningIndex;
            runningIndex += grouped[key]!.length;
          }

          return SingleChildScrollView(
            child: ResponsivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.keys.map((key) {
                  final items = grouped[key]!;
                  final startIndex = groupStartIndex[key]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: items.length,
                        itemBuilder: (ctx, j) => StaggeredFadeIn(
                          index: startIndex + j,
                          child: _DocumentThumbnail(document: items[j], db: db),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
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
    final scheme = Theme.of(context).colorScheme;

    return HoverLift(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            premiumRoute(
              DocumentViewerScreen(
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
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image,
                          color: scheme.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                    ),
                    if (document.transactionId != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.wzNumber ?? 'Bez numeru',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeFmt.format(document.scannedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (document.amount != null)
                          Text(
                            moneyFmt.format(document.amount),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
