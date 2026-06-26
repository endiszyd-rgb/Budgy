import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'dao/transactions_dao.dart';
import 'dao/documents_dao.dart';
import 'dao/appointments_dao.dart';

part 'database.g.dart';

enum TransactionType { income, expense }

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get category => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get wzNumber => text().nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(true))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get icon => text().withDefault(const Constant('attach_money'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF2196F3))();
}

class ScannedDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imagePath => text()();
  TextColumn get wzNumber => text().nullable()();
  TextColumn get supplier => text().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get rawText => text().nullable()();
  IntColumn get transactionId =>
      integer().nullable().references(Transactions, #id)();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get clientName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get vehicle => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [Transactions, Categories, ScannedDocuments, Appointments],
  daos: [TransactionsDao, DocumentsDao, AppointmentsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(scannedDocuments);
      }
      if (from < 3) {
        await m.addColumn(transactions, transactions.isPaid);
      }
      if (from < 4) {
        await m.addColumn(transactions, transactions.paidAmount);
        // Wpisy już oznaczone jako zapłacone uznajemy za spłacone w całości.
        await customStatement(
          'UPDATE transactions SET paid_amount = amount WHERE is_paid = 1',
        );
      }
      if (from < 5) {
        await m.createTable(appointments);
      }
    },
  );

  Future<void> _insertDefaultCategories() async {
    final defaults = [
      CategoriesCompanion.insert(
        name: 'Materiały',
        type: TransactionType.expense,
        icon: const Value('build'),
        colorValue: const Value(0xFFE53935),
      ),
      CategoriesCompanion.insert(
        name: 'Narzędzia',
        type: TransactionType.expense,
        icon: const Value('hardware'),
        colorValue: const Value(0xFFE91E63),
      ),
      CategoriesCompanion.insert(
        name: 'Paliwo',
        type: TransactionType.expense,
        icon: const Value('local_gas_station'),
        colorValue: const Value(0xFFFF5722),
      ),
      CategoriesCompanion.insert(
        name: 'Wynajem',
        type: TransactionType.expense,
        icon: const Value('home'),
        colorValue: const Value(0xFF9C27B0),
      ),
      CategoriesCompanion.insert(
        name: 'Inne wydatki',
        type: TransactionType.expense,
        icon: const Value('more_horiz'),
        colorValue: const Value(0xFF607D8B),
      ),
      CategoriesCompanion.insert(
        name: 'Usługi',
        type: TransactionType.income,
        icon: const Value('car_repair'),
        colorValue: const Value(0xFF43A047),
      ),
      CategoriesCompanion.insert(
        name: 'Sprzedaż części',
        type: TransactionType.income,
        icon: const Value('sell'),
        colorValue: const Value(0xFF00897B),
      ),
      CategoriesCompanion.insert(
        name: 'Inne przychody',
        type: TransactionType.income,
        icon: const Value('payments'),
        colorValue: const Value(0xFF1E88E5),
      ),
    ];
    await batch((b) => b.insertAll(categories, defaults));
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'budzet_warsztatu');
  }
}
