import 'package:drift/drift.dart';
import '../database/app_database.dart';

class BlockRepository {
  final AppDatabase _db;
  BlockRepository(this._db);

  // Watch all blocks in a note, ordered by position
  Stream<List<NoteBlock>> watchByNote(int noteId) =>
      (_db.select(_db.noteBlocks)
            ..where((b) => b.noteId.equals(noteId))
            ..orderBy([(b) => OrderingTerm.asc(b.position)]))
          .watch();

  // Get all blocks in a note
  Future<List<NoteBlock>> getByNote(int noteId) =>
      (_db.select(_db.noteBlocks)
            ..where((b) => b.noteId.equals(noteId))
            ..orderBy([(b) => OrderingTerm.asc(b.position)]))
          .get();

  // Get all items in a block
  Future<List<BlockItem>> getItems(int blockId) =>
      (_db.select(_db.blockItems)
            ..where((i) => i.blockId.equals(blockId))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .get();

  // Watch items in a block
  Stream<List<BlockItem>> watchItems(int blockId) =>
      (_db.select(_db.blockItems)
            ..where((i) => i.blockId.equals(blockId))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .watch();

  // Create a block
  Future<int> createBlock({
    required int noteId,
    required String type,
    String? content,
    required int position,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.noteBlocks)
        .insert(
          NoteBlocksCompanion.insert(
            noteId: noteId,
            type: type,
            content: Value(content),
            position: position,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  // Update block content
  Future<bool> updateBlock(NoteBlock block) => _db
      .update(_db.noteBlocks)
      .replace(
        block.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch),
      );

  // Update block positions (for reordering)
  Future<void> updatePositions(List<NoteBlock> blocks) async {
    await _db.transaction(() async {
      for (int i = 0; i < blocks.length; i++) {
        await _db
            .update(_db.noteBlocks)
            .replace(blocks[i].copyWith(position: i));
      }
    });
  }

  // Delete a block
  Future<int> deleteBlock(int id) =>
      (_db.delete(_db.noteBlocks)..where((b) => b.id.equals(id))).go();

  // Create a block item (checklist/list item)
  Future<int> createItem({
    required int blockId,
    required String content,
    required int position,
    bool isChecked = false,
  }) => _db
      .into(_db.blockItems)
      .insert(
        BlockItemsCompanion.insert(
          blockId: blockId,
          content: Value(content),
          position: position,
          isChecked: Value(isChecked),
        ),
      );

  // Update a block item
  Future<bool> updateItem(BlockItem item) =>
      _db.update(_db.blockItems).replace(item);

  // Delete a block item
  Future<int> deleteItem(int id) =>
      (_db.delete(_db.blockItems)..where((i) => i.id.equals(id))).go();

  // Delete all items in a block
  Future<int> deleteAllItems(int blockId) => (_db.delete(
    _db.blockItems,
  )..where((i) => i.blockId.equals(blockId))).go();
}
