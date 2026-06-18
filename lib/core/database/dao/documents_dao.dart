import 'package:drift/drift.dart';
import '../database.dart';

part 'documents_dao.g.dart';

@DriftAccessor(tables: [ScannedDocuments])
class DocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.db);

  Stream<List<ScannedDocument>> watchAllDocuments() =>
      (select(scannedDocuments)
            ..orderBy([(d) => OrderingTerm.desc(d.scannedAt)]))
          .watch();

  Future<int> insertDocument(ScannedDocumentsCompanion entry) =>
      into(scannedDocuments).insert(entry);

  Future<void> linkTransaction(int documentId, int transactionId) =>
      (update(scannedDocuments)..where((d) => d.id.equals(documentId)))
          .write(ScannedDocumentsCompanion(
        transactionId: Value(transactionId),
      ));

  Future<int> deleteDocument(int id) =>
      (delete(scannedDocuments)..where((d) => d.id.equals(id))).go();
}
