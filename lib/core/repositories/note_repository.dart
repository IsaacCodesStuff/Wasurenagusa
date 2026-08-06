import 'package:drift/drift.dart';
import '../database/app_database.dart';

enum NoteSortOrder { lastEdited, nameAZ, nameZA, dateCreated, colorTag }

class NoteRepository {
  final AppDatabase _db;
  NoteRepository(this._db);

  // Watch all notes in a section
  Stream<List<Note>> watchBySection(int sectionId) =>
      (_db.select(_db.notes)
            ..where((n) => n.sectionId.equals(sectionId))
            ..orderBy([
              (n) => OrderingTerm.desc(n.isPinned),
              (n) => OrderingTerm.desc(n.updatedAt),
            ]))
          .watch();

  Stream<List<Note>> watchBySectionSorted(int sectionId, NoteSortOrder sort) {
    final query = _db.select(_db.notes)
      ..where((n) => n.sectionId.equals(sectionId));

    switch (sort) {
      case NoteSortOrder.lastEdited:
        query.orderBy([
          (n) => OrderingTerm.desc(n.isPinned),
          (n) => OrderingTerm.desc(n.updatedAt),
        ]);
      case NoteSortOrder.nameAZ:
        query.orderBy([
          (n) => OrderingTerm.desc(n.isPinned),
          (n) => OrderingTerm.asc(n.title),
        ]);
      case NoteSortOrder.nameZA:
        query.orderBy([
          (n) => OrderingTerm.desc(n.isPinned),
          (n) => OrderingTerm.desc(n.title),
        ]);
      case NoteSortOrder.dateCreated:
        query.orderBy([
          (n) => OrderingTerm.desc(n.isPinned),
          (n) => OrderingTerm.desc(n.createdAt),
        ]);
      case NoteSortOrder.colorTag:
        query.orderBy([
          (n) => OrderingTerm.desc(n.isPinned),
          (n) => OrderingTerm.asc(n.colorTag),
          (n) => OrderingTerm.desc(n.updatedAt),
        ]);
    }

    return query.watch();
  }

  // Watch pinned notes (for home screen)
  Stream<List<Note>> watchPinned() =>
      (_db.select(_db.notes)
            ..where((n) => n.isPinned.equals(true))
            ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
          .watch();

  // Watch recent notes (for home screen)
  Stream<List<Note>> watchRecent({int limit = 20}) =>
      (_db.select(_db.notes)
            ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])
            ..limit(limit))
          .watch();

  // Get single note
  Future<Note?> getById(int id) =>
      (_db.select(_db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  // Create note
  Future<int> create({int? sectionId, String title = '', String? colorTag}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            sectionId: Value(sectionId),
            title: Value(title),
            colorTag: Value(colorTag),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  // Update note
  Future<bool> update(Note note) => _db
      .update(_db.notes)
      .replace(note.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch));

  // Toggle pin
  Future<bool> togglePin(Note note) =>
      _db.update(_db.notes).replace(note.copyWith(isPinned: !note.isPinned));

  // Toggle favorite
  Future<bool> toggleFavorite(Note note) => _db
      .update(_db.notes)
      .replace(note.copyWith(isFavorite: !note.isFavorite));

  // Delete note
  Future<int> delete(int id) =>
      (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();

  // Search notes by title
  Future<List<Note>> search(String query) =>
      (_db.select(_db.notes)
            ..where((n) => n.title.like('%$query%'))
            ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
          .get();
}
