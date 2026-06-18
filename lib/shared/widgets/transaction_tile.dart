import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../features/documents/document_viewer_screen.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final AppDatabase? db;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.db,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final dateFormatter = DateFormat('dd.MM.yyyy', 'pl_PL');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)
                  .withOpacity(0.15),
          radius: 24,
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
            size: 22,
          ),
        ),
        title: Text(transaction.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (transaction.wzNumber != null)
              Text('WZ: ${transaction.wzNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (db != null)
              FutureBuilder<ScannedDocument?>(
                future: db!.documentsDao
                    .getDocumentByTransactionId(transaction.id),
                builder: (context, snapshot) {
                  final document = snapshot.data;
                  if (document == null) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Zobacz zeskanowany dokument',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentViewerScreen(
                          document: document,
                          onDelete: () =>
                              db!.documentsDao.deleteDocument(document.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${formatter.format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                  ),
                ),
                Text(dateFormatter.format(transaction.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        onLongPress: onDelete != null
            ? () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Usuń transakcję?'),
                    content: Text('Czy usunąć "${transaction.title}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Anuluj')),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                          child: const Text('Usuń',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                )
            : null,
      ),
    );
  }
}
