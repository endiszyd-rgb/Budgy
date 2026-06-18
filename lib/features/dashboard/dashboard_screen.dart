import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/amount_card.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../settings/settings_screen.dart';
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

  void _prevMonth() =>
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  void _nextMonth() =>
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Transaction>>(
        stream: widget.db.transactionsDao.watchTransactionsByMonth(
            _selectedMonth.year, _selectedMonth.month),
        builder: (context, snapshot) {
          final txList = snapshot.data ?? [];
          final income = txList
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final expense = txList
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
          final balance = income - expense;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 80,
                floating: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left)),
                    Text(
                      DateFormat('MMMM yyyy', 'pl_PL').format(_selectedMonth),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Ustawienia',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(db: widget.db),
                      ),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Bilans
                    Card(
                      color: balance >= 0
                          ? AppTheme.incomeColor.withOpacity(0.1)
                          : AppTheme.expenseColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('BILANS MIESIĘCZNY',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.currency(
                                          locale: 'pl_PL', symbol: 'zł')
                                      .format(balance),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0
                                        ? AppTheme.incomeColor
                                        : AppTheme.expenseColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              balance >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 48,
                              color: balance >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Karty przychody / wydatki
                    Row(
                      children: [
                        Expanded(
                          child: AmountCard(
                            label: 'Przychody',
                            amount: income,
                            color: AppTheme.incomeColor,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AmountCard(
                            label: 'Wydatki',
                            amount: expense,
                            color: AppTheme.expenseColor,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    UnpaidSummaryCard(db: widget.db),
                    const SizedBox(height: 20),
                    // Wykres kołowy
                    if (txList.isNotEmpty) ...[
                      Text('Struktura wydatków',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: _buildPieChart(txList),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Ostatnie transakcje
                    Text('Ostatnie transakcje',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (txList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Brak transakcji w tym miesiącu.\nDodaj pierwszą przyciskiem +',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...txList.take(10).map((t) => TransactionTile(
                            transaction: t,
                            db: widget.db,
                            onDelete: () => widget.db.transactionsDao
                                .deleteTransaction(t.id),
                          )),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPieChart(List<Transaction> txList) {
    final expenses = txList.where((t) => t.type == TransactionType.expense);
    final Map<String, double> byCategory = {};
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    if (byCategory.isEmpty) return const SizedBox();

    final colors = [
      Colors.red, Colors.orange, Colors.purple, Colors.blue,
      Colors.teal, Colors.green, Colors.indigo, Colors.pink,
    ];
    final entries = byCategory.entries.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(entries.length, (i) {
                final e = entries[i];
                return PieChartSectionData(
                  value: e.value,
                  color: colors[i % colors.length],
                  title: '',
                  radius: 70,
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(entries.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entries[i].key,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
