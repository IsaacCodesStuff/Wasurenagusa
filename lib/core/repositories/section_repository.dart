import 'package:drift/drift.dart';
import '../database/app_database.dart';

class SectionRepository {
  final AppDatabase _db;
  SectionRepository(this._db);

  // Watch all sections in a notebook
  Stream<List<Section>> watchByNotebook(int notebookId) =>
      (_db.select(_db.sections)
            ..where((s) => s.notebookId.equals(notebookId))
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .watch();

  // Create section
  Future<int> create({required int notebookId, required String name}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.sections)
        .insert(
          SectionsCompanion.insert(
            notebookId: notebookId,
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  // Update section
  Future<bool> update(Section section) => _db
      .update(_db.sections)
      .replace(
        section.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch),
      );

  // Delete section
  Future<int> delete(int id) =>
      (_db.delete(_db.sections)..where((s) => s.id.equals(id))).go();

  Future<List<Section>> getSectionsByNotebook(int notebookId) =>
      (_db.select(_db.sections)
            ..where((s) => s.notebookId.equals(notebookId))
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .get();
}
