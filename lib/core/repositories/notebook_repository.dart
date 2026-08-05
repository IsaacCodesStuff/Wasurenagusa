import 'package:drift/drift.dart';
import '../database/app_database.dart';

class NotebookRepository {
  final AppDatabase _db;
  NotebookRepository(this._db);

  // Watch all notebooks, ordered by name
  Stream<List<Notebook>> watchAll() => (_db.select(
    _db.notebooks,
  )..orderBy([(n) => OrderingTerm.asc(n.name)])).watch();

  // Get single notebook
  Future<Notebook?> getById(int id) => (_db.select(
    _db.notebooks,
  )..where((n) => n.id.equals(id))).getSingleOrNull();

  // Create notebook
  Future<int> create({required String name, String? icon, String? color}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.notebooks)
        .insert(
          NotebooksCompanion.insert(
            name: name,
            icon: Value(icon),
            color: Value(color),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  // Update notebook
  Future<bool> update(Notebook notebook) => _db
      .update(_db.notebooks)
      .replace(
        notebook.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch),
      );

  // Delete notebook
  Future<int> delete(int id) =>
      (_db.delete(_db.notebooks)..where((n) => n.id.equals(id))).go();
}
