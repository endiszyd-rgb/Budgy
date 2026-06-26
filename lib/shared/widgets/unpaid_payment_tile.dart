import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import 'numeric_keypad_dialog.dart';

/// Wiersz nierozliczonej transakcji z możliwością częściowej spłaty
/// (zmniejszenia pozostałej kwoty) lub oznaczenia jej jako rozliczonej w całości.
class UnpaidPaymentTile extends StatelessWidget {
  final AppDatabase db;
  final Transaction transaction;
  final Color color;

  const UnpaidPaymentTile({
    super.key,
    required this.db,
    required this.transaction,
    required this.color,
  });

  Future<void> _partialPayment(BuildContext context) async {
    final remaining = transaction.amount - transaction.paidAmount;
    final value = await showNumericKeypad(
      context,
      initialValue: remaining,
      accentColor: color,
    );
    if (value == null || value <= 0) return;
    final capped = value > remaining ? remaining : value;
    await db.transactionsDao.addPartialPayment(transaction.id, capped);
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');
    final remaining = transaction.amount - transaction.paidAmount;
    final progress = transaction.amount <= 0
        ? 0.0
        : (transaction.paidAmount / transaction.amount).clamp(0.0, 1.0);

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${transaction.category} • ${dateFmt.format(transaction.date)}',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  moneyFmt.format(remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
            if (transaction.paidAmount > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Spłacono ${moneyFmt.format(transaction.paidAmount)} z ${moneyFmt.format(transaction.amount)}',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _partialPayment(context),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Spłać częściowo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () =>
                        db.transactionsDao.setPaidStatus(transaction.id, true),
                    child: const Text('Rozlicz całość'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
