import 'package:drift/drift.dart';
import '../database.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<Transaction>> watchAllTransactions() => (select(
    transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Stream<List<Transaction>> watchTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction entry) =>
      update(transactions).replace(entry);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Stream<List<Transaction>> watchUnpaidByType(TransactionType type) =>
      (select(transactions)
            ..where((t) => t.isPaid.equals(false) & t.type.equalsValue(type))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();

  Future<void> setPaidStatus(int id, bool isPaid) async {
    if (isPaid) {
      final tx = await (select(
        transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      await (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          isPaid: const Value(true),
          paidAmount: Value(tx.amount),
        ),
      );
    } else {
      await (update(transactions)..where((t) => t.id.equals(id))).write(
        const TransactionsCompanion(isPaid: Value(false), paidAmount: Value(0)),
      );
    }
  }

  /// Dodaje częściową spłatę do nierozliczonej transakcji, zmniejszając
  /// pozostałą kwotę. Po pokryciu całej kwoty pozycja staje się rozliczona.
  Future<void> addPartialPayment(int id, double amount) async {
    final tx = await (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingle();
    final newPaidAmount = (tx.paidAmount + amount)
        .clamp(0.0, tx.amount)
        .toDouble();
    final isFullyPaid = newPaidAmount >= tx.amount - 0.005;
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        paidAmount: Value(isFullyPaid ? tx.amount : newPaidAmount),
        isPaid: Value(isFullyPaid),
      ),
    );
  }

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<List<Category>> getCategoriesByType(TransactionType type) =>
      (select(categories)..where((c) => c.type.equalsValue(type))).get();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(Category category) =>
      update(categories).replace(category);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Future<Map<String, double>> getSumByCategory(
    int year,
    int month,
    TransactionType type,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final rows =
        await (select(transactions)..where(
              (t) =>
                  t.date.isBetweenValues(start, end) & t.type.equalsValue(type),
            ))
            .get();
    final Map<String, double> result = {};
    for (final t in rows) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }
}
