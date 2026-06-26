import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../features/documents/document_viewer_screen.dart';
import '../../features/transactions/add_transaction_screen.dart';
import 'animated_amount.dart';
import 'hover_lift.dart';

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

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return HoverLift(
      liftPx: 2,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)
                  .withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
              size: 22,
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.category,
                style: TextStyle(fontSize: 13, color: muted),
              ),
              if (transaction.wzNumber != null)
                Text(
                  'WZ: ${transaction.wzNumber}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              if (!transaction.isPaid)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: AppTheme.pendingColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.paidAmount > 0
                            ? '${isIncome ? "Należność" : "Zobowiązanie"} • spłacono ${formatter.format(transaction.paidAmount)}'
                            : (isIncome ? 'Należność' : 'Zobowiązanie'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pendingColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (db != null)
                FutureBuilder<ScannedDocument?>(
                  future: db!.documentsDao.getDocumentByTransactionId(
                    transaction.id,
                  ),
                  builder: (context, snapshot) {
                    final document = snapshot.data;
                    if (document == null) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.image_outlined),
                      tooltip: 'Zobacz zeskanowany dokument',
                      onPressed: () => Navigator.push(
                        context,
                        premiumRoute(
                          DocumentViewerScreen(
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
                  AnimatedAmount(
                    amount: transaction.amount,
                    format: (v) =>
                        '${isIncome ? '+' : '-'}${formatter.format(v)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIncome
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                  Text(
                    dateFormatter.format(transaction.date),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ],
          ),
          onTap: db == null
              ? null
              : () => Navigator.push(
                  context,
                  premiumRoute(
                    AddTransactionScreen(
                      db: db!,
                      initialType: transaction.type,
                      existing: transaction,
                    ),
                  ),
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
                        child: const Text('Anuluj'),
                      ),
                      TextButton(
                        onPressed: () {
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
                )
              : null,
        ),
      ),
    );
  }
}
