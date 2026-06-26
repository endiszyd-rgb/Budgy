import 'package:flutter/material.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/responsive_page.dart';
import '../../shared/widgets/unpaid_payment_tile.dart';

/// Ekran do spłaty/rozliczania należności i zobowiązań — pozwala spłacić
/// nierozliczoną pozycję częściowo (zmniejszając pozostałą kwotę) lub w całości.
class UnpaidPaymentsScreen extends StatefulWidget {
  final AppDatabase db;
  const UnpaidPaymentsScreen({super.key, required this.db});

  @override
  State<UnpaidPaymentsScreen> createState() => _UnpaidPaymentsScreenState();
}

class _UnpaidPaymentsScreenState extends State<UnpaidPaymentsScreen> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;
    final color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Spłaty i rozliczenia')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Zobowiązania'),
                    icon: Icon(Icons.arrow_circle_up_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Należności'),
                    icon: Icon(Icons.arrow_circle_down_outlined, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: widget.db.transactionsDao.watchUnpaidByType(_type),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Wszystko rozliczone ✓',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: ResponsivePage(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 24.0;
                        final columnWidth =
                            (constraints.maxWidth - spacing) / 2;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: items
                              .map(
                                (t) => SizedBox(
                                  width: columnWidth,
                                  child: UnpaidPaymentTile(
                                    db: widget.db,
                                    transaction: t,
                                    color: color,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
