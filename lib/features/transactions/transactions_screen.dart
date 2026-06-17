import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../shared/widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  final AppDatabase db;
  const TransactionsScreen({super.key, required this.db});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filterType;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia transakcji'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Szukaj...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TransactionType?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('Wszystkie')),
                    ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Przychody'),
                        icon: Icon(Icons.arrow_upward, size: 16)),
                    ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Wydatki'),
                        icon: Icon(Icons.arrow_downward, size: 16)),
                  ],
                  selected: {_filterType},
                  onSelectionChanged: (s) =>
                      setState(() => _filterType = s.first),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: widget.db.transactionsDao.watchAllTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var txList = snapshot.data!;
          if (_filterType != null) {
            txList = txList.where((t) => t.type == _filterType).toList();
          }
          if (_searchQuery.isNotEmpty) {
            txList = txList
                .where((t) =>
                    t.title.toLowerCase().contains(_searchQuery) ||
                    t.category.toLowerCase().contains(_searchQuery) ||
                    (t.wzNumber?.toLowerCase().contains(_searchQuery) ?? false))
                .toList();
          }
          if (txList.isEmpty) {
            return const Center(
              child: Text('Brak transakcji',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }
          // Grupowanie po dacie
          final grouped = <String, List<Transaction>>{};
          final df = DateFormat('EEEE, dd MMMM yyyy', 'pl_PL');
          for (final t in txList) {
            final key = df.format(t.date);
            grouped.putIfAbsent(key, () => []).add(t);
          }
          return ListView.builder(
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final key = grouped.keys.elementAt(i);
              final items = grouped[key]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(key,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 13)),
                  ),
                  ...items.map((t) => TransactionTile(
                        transaction: t,
                        onDelete: () => widget.db.transactionsDao
                            .deleteTransaction(t.id),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
