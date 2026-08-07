import 'package:drift/drift.dart';
import '../database/app_database.dart';

class SeizaRepository {
  final AppDatabase db;

  SeizaRepository(this.db);

  // Get all notes in a notebook that have a seiza node entry,
  // plus their positions. Returns a joined result.
  Future<List<SeizaNodeWithNote>> getNodesForNotebook(int notebookId) async {
    final query = db.select(db.seizaNodes).join([
      innerJoin(db.notes, db.notes.id.equalsExp(db.seizaNodes.noteId)),
      innerJoin(db.sections, db.sections.id.equalsExp(db.notes.sectionId)),
    ])..where(db.seizaNodes.notebookId.equals(notebookId));

    final rows = await query.get();
    return rows.map((row) {
      return SeizaNodeWithNote(
        node: row.readTable(db.seizaNodes),
        note: row.readTable(db.notes),
      );
    }).toList();
  }

  // Get all notes in a notebook that don't yet have a seiza node —
  // used to auto-place new notes when opening Seiza for the first time.
  Future<List<Note>> getUnplacedNotes(int notebookId) async {
    final placedNoteIds =
        await (db.selectOnly(db.seizaNodes)
              ..addColumns([db.seizaNodes.noteId])
              ..where(db.seizaNodes.notebookId.equals(notebookId)))
            .map((row) => row.read(db.seizaNodes.noteId)!)
            .get();

    final query = db.select(db.notes).join([
      innerJoin(db.sections, db.sections.id.equalsExp(db.notes.sectionId)),
    ])..where(db.sections.notebookId.equals(notebookId));

    if (placedNoteIds.isNotEmpty) {
      query.where(db.notes.id.isNotIn(placedNoteIds));
    }

    final rows = await query.get();
    return rows.map((row) => row.readTable(db.notes)).toList();
  }

  // Upsert a node position — creates if not exists, updates if it does.
  Future<void> upsertNode({
    required int noteId,
    required int notebookId,
    required double x,
    required double y,
  }) async {
    final existing =
        await (db.select(db.seizaNodes)..where(
              (n) => n.noteId.equals(noteId) & n.notebookId.equals(notebookId),
            ))
            .getSingleOrNull();

    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing == null) {
      await db
          .into(db.seizaNodes)
          .insert(
            SeizaNodesCompanion.insert(
              noteId: noteId,
              notebookId: notebookId,
              x: Value(x),
              y: Value(y),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (db.update(
        db.seizaNodes,
      )..where((n) => n.id.equals(existing.id))).write(
        SeizaNodesCompanion(x: Value(x), y: Value(y), updatedAt: Value(now)),
      );
    }
  }

  // Toggle pinned state
  Future<void> togglePinned(int nodeId, bool isPinned) async {
    await (db.update(db.seizaNodes)..where((n) => n.id.equals(nodeId))).write(
      SeizaNodesCompanion(isPinned: Value(isPinned)),
    );
  }

  // Get all edges where either endpoint is in this notebook
  Future<List<NoteLink>> getEdgesForNotebook(int notebookId) async {
    final noteIdsQuery = db.select(db.notes).join([
      innerJoin(db.sections, db.sections.id.equalsExp(db.notes.sectionId)),
    ])..where(db.sections.notebookId.equals(notebookId));

    final noteIds = await noteIdsQuery
        .map((row) => row.readTable(db.notes).id)
        .get();

    if (noteIds.isEmpty) return [];

    return (db.select(db.noteLinks)..where(
          (l) => l.sourceNoteId.isIn(noteIds) & l.targetNoteId.isIn(noteIds),
        ))
        .get();
  }

  // Create an edge between two notes
  Future<void> createEdge({
    required int sourceNoteId,
    required int targetNoteId,
    String? label,
  }) async {
    // Prevent duplicate edges
    final existing =
        await (db.select(db.noteLinks)..where(
              (l) =>
                  l.sourceNoteId.equals(sourceNoteId) &
                  l.targetNoteId.equals(targetNoteId),
            ))
            .getSingleOrNull();

    if (existing != null) return;

    await db
        .into(db.noteLinks)
        .insert(
          NoteLinksCompanion.insert(
            sourceNoteId: sourceNoteId,
            targetNoteId: targetNoteId,
            label: Value(label),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  // Delete an edge
  Future<void> deleteEdge(int edgeid) async {
    await (db.delete(db.noteLinks)..where((l) => l.id.equals(edgeid))).go();
  }

  Future<void> autoPlaceUnpositioned(int notebookId) async {
    final unplaced = await getUnplacedNotes(notebookId);
    if (unplaced.isEmpty) return;

    // Find how many nodes already exist to offset the grid correctly
    final existing = await getNodesForNotebook(notebookId);
    final startIndex = existing.length;

    const columns = 3;
    const spacingX = 200.0;
    const spacingY = 120.0;

    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < unplaced.length; i++) {
      final note = unplaced[i];
      final index = startIndex + i;
      final col = index % columns;
      final row = index ~/ columns;

      await db
          .into(db.seizaNodes)
          .insert(
            SeizaNodesCompanion.insert(
              noteId: note.id,
              notebookId: notebookId,
              x: Value(300.0 + col * spacingX),
              y: Value(300.0 + row * spacingY),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }
}

// Joined result model
class SeizaNodeWithNote {
  final SeizaNode node;
  final Note note;

  SeizaNodeWithNote({required this.node, required this.note});
}
