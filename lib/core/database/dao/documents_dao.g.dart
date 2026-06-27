// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $ScannedDocumentsTable get scannedDocuments =>
      attachedDatabase.scannedDocuments;
  DocumentsDaoManager get managers => DocumentsDaoManager(this);
}

class DocumentsDaoManager {
  final _$DocumentsDaoMixin _db;
  DocumentsDaoManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$ScannedDocumentsTableTableManager get scannedDocuments =>
      $$ScannedDocumentsTableTableManager(
        _db.attachedDatabase,
        _db.scannedDocuments,
      );
}
