import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/unpaid_payment_tile.dart';

/// Para kart "Należności od klientów" / "Zobowiązania wobec hurtowni",
/// pokazana jako dwie samodzielne karty obok siebie.
class UnpaidSummaryRow extends StatelessWidget {
  final AppDatabase db;
  const UnpaidSummaryRow({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _UnpaidCard(
            db: db,
            type: TransactionType.income,
            label: 'Należności od klientów',
            hint: 'czeka na wpłatę',
            color: AppTheme.incomeColor,
            icon: Icons.arrow_circle_down_outlined,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _UnpaidCard(
            db: db,
            type: TransactionType.expense,
            label: 'Zobowiązania wobec hurtowni',
            hint: 'do zapłaty',
            color: AppTheme.expenseColor,
            icon: Icons.arrow_circle_up_outlined,
          ),
        ),
      ],
    );
  }
}

class _UnpaidCard extends StatelessWidget {
  final AppDatabase db;
  final TransactionType type;
  final String label;
  final String hint;
  final Color color;
  final IconData icon;

  const _UnpaidCard({
    required this.db,
    required this.type,
    required this.label,
    required this.hint,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Transaction>>(
      stream: db.transactionsDao.watchUnpaidByType(type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final total = items.fold(0.0, (s, t) => s + (t.amount - t.paidAmount));

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: items.isEmpty
                ? null
                : () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => _UnpaidListSheet(
                      db: db,
                      type: type,
                      title: label,
                      color: color,
                    ),
                  ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (items.isNotEmpty)
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    moneyFmt.format(total),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    items.isEmpty
                        ? 'Wszystko rozliczone ✓'
                        : '${items.length} ${items.length == 1 ? "pozycja" : "pozycji"} • $hint',
                    style: TextStyle(
                      fontSize: 13,
                      color: items.isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnpaidListSheet extends StatelessWidget {
  final AppDatabase db;
  final TransactionType type;
  final String title;
  final Color color;

  const _UnpaidListSheet({
    required this.db,
    required this.type,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => StreamBuilder<List<Transaction>>(
        stream: db.transactionsDao.watchUnpaidByType(type),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Wszystko rozliczone ✓',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) => UnpaidPaymentTile(
                    db: db,
                    transaction: items[i],
                    color: color,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
