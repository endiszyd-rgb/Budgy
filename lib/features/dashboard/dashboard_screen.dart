import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/amount_card.dart';
import '../../shared/widgets/hover_lift.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../../shared/widgets/responsive_page.dart';
import 'unpaid_summary_card.dart';

class DashboardScreen extends StatefulWidget {
  final AppDatabase db;
  const DashboardScreen({super.key, required this.db});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _prevMonth() => setState(
    () => _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    ),
  );
  void _nextMonth() => setState(
    () => _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _MonthSwitcher(
              month: _selectedMonth,
              onPrev: _prevMonth,
              onNext: _nextMonth,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: widget.db.transactionsDao.watchTransactionsByMonth(
          _selectedMonth.year,
          _selectedMonth.month,
        ),
        builder: (context, snapshot) {
          final txList = snapshot.data ?? [];
          final income = txList
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final expense = txList
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
          final balance = income - expense;

          return SingleChildScrollView(
            child: ResponsivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: StaggeredFadeIn(
                          index: 0,
                          child: AmountCard(
                            label: 'Bilans miesięczny',
                            amount: balance,
                            color: balance >= 0
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor,
                            icon: balance >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            hero: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StaggeredFadeIn(
                          index: 1,
                          child: AmountCard(
                            label: 'Przychody',
                            amount: income,
                            color: AppTheme.incomeColor,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StaggeredFadeIn(
                          index: 2,
                          child: AmountCard(
                            label: 'Wydatki',
                            amount: expense,
                            color: AppTheme.expenseColor,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StaggeredFadeIn(
                    index: 3,
                    child: UnpaidSummaryRow(db: widget.db),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: StaggeredFadeIn(
                          index: 4,
                          child: _ExpenseChartCard(txList: txList),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 7,
                        child: _RecentTransactionsSection(
                          txList: txList,
                          db: widget.db,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSwitcher({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(
            DateFormat('MMMM yyyy', 'pl_PL').format(month),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _ExpenseChartCard extends StatelessWidget {
  final List<Transaction> txList;
  const _ExpenseChartCard({required this.txList});

  @override
  Widget build(BuildContext context) {
    final expenses = txList.where((t) => t.type == TransactionType.expense);
    final Map<String, double> byCategory = {};
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final total = byCategory.values.fold(0.0, (s, v) => s + v);
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    const colors = [
      AppPalette.indigo500,
      AppPalette.rose600,
      AppPalette.amber600,
      AppPalette.emerald600,
      AppPalette.indigo300,
      AppPalette.slate500,
      AppPalette.rose400,
      AppPalette.slate400,
    ];
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return HoverLift(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Struktura wydatków',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Brak wydatków w tym miesiącu',
                      style: TextStyle(color: muted),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: List.generate(entries.length, (i) {
                            final e = entries[i];
                            return PieChartSectionData(
                              value: e.value,
                              color: colors[i % colors.length],
                              title: '',
                              radius: 38,
                            );
                          }),
                          sectionsSpace: 3,
                          centerSpaceRadius: 64,
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Łącznie',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            moneyFmt.format(total),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.expenseColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final pct = total > 0 ? e.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            moneyFmt.format(e.value),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> txList;
  final AppDatabase db;
  const _RecentTransactionsSection({required this.txList, required this.db});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ostatnie transakcje',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (txList.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Brak transakcji w tym miesiącu.\nDodaj pierwszą przyciskiem "Dodaj".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )
        else
          ...txList.take(8).indexed.map((entry) {
            final (i, t) = entry;
            return StaggeredFadeIn(
              index: i,
              child: TransactionTile(
                transaction: t,
                db: db,
                onDelete: () => db.transactionsDao.deleteTransaction(t.id),
              ),
            );
          }),
      ],
    );
  }
}
