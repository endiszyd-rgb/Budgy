import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';

class UnpaidSummaryCard extends StatelessWidget {
  final AppDatabase db;
  const UnpaidSummaryCard({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 22),
                const SizedBox(width: 8),
                Text('Należności i zobowiązania',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _UnpaidRow(
              db: db,
              type: TransactionType.income,
              label: 'Należności od klientów',
              hint: 'czeka na wpłatę',
              color: AppTheme.incomeColor,
              icon: Icons.arrow_circle_down_outlined,
            ),
            const Divider(height: 20),
            _UnpaidRow(
              db: db,
              type: TransactionType.expense,
              label: 'Zobowiązania wobec hurtowni',
              hint: 'do zapłaty',
              color: AppTheme.expenseColor,
              icon: Icons.arrow_circle_up_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnpaidRow extends StatelessWidget {
  final AppDatabase db;
  final TransactionType type;
  final String label;
  final String hint;
  final Color color;
  final IconData icon;

  const _UnpaidRow({
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

    return StreamBuilder<List<Transaction>>(
      stream: db.transactionsDao.watchUnpaidByType(type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final total = items.fold(0.0, (s, t) => s + t.amount);

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: items.isEmpty
              ? null
              : () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => _UnpaidListSheet(
                      db: db,
                      type: type,
                      title: label,
                      color: color,
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 14)),
                      Text(
                        items.isEmpty
                            ? 'Wszystko rozliczone ✓'
                            : '${items.length} ${items.length == 1 ? "pozycja" : "pozycji"} • $hint',
                        style: TextStyle(
                            fontSize: 12,
                            color: items.isEmpty ? Colors.grey : color),
                      ),
                    ],
                  ),
                ),
                Text(
                  moneyFmt.format(total),
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                if (items.isNotEmpty)
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
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
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');

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
                padding: const EdgeInsets.all(16),
                child: Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Wszystko rozliczone ✓',
                      style: TextStyle(color: Colors.grey)),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return ListTile(
                      title: Text(t.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${t.category} • ${dateFmt.format(t.date)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(moneyFmt.format(t.amount),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: color)),
                          TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28)),
                            onPressed: () =>
                                db.transactionsDao.setPaidStatus(t.id, true),
                            child: const Text('Oznacz jako rozliczone',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
