import 'package:flutter/widgets.dart';
import '../../core/models/note_block_model.dart';
import '../../core/repositories/block_repository.dart';
import '../../core/repositories/note_repository.dart';
import 'package:drift/drift.dart' show Value;

class EditorController extends ChangeNotifier {
  final int noteId;
  final BlockRepository blockRepo;
  final NoteRepository noteRepo;
  final Map<int, TextEditingController> textControllers = {};
  int focusedBlockId = -1;

  // Call this when a block gains focus
  void onBlockFocused(int blockId) {
    focusedBlockId = blockId;
    notifyListeners();
  }

  // Call this when a block loses focus
  void onBlockUnfocused(int blockId) {
    if (focusedBlockId == blockId) {
      focusedBlockId = -1;
      notifyListeners();
    }
  }

  // Get or create a TextEditingController for a block
  TextEditingController controllerFor(NoteBlockModel block) {
    return textControllers.putIfAbsent(
      block.id!,
      () => TextEditingController(text: block.textContent),
    );
  }

  // Insert text at cursor in the focused block
  void insertAtCursor(String prefix, String suffix) {
    if (focusedBlockId == -1) return;
    final tc = textControllers[focusedBlockId];
    if (tc == null) return;

    final selection = tc.selection;
    final text = tc.text;

    if (!selection.isValid) {
      // No cursor position — just append
      tc.text = '$text$prefix$suffix';
      tc.selection = TextSelection.collapsed(
        offset: tc.text.length - suffix.length,
      );
      return;
    }

    final before = text.substring(0, selection.start);
    final selected = text.substring(selection.start, selection.end);
    final after = text.substring(selection.end);

    final newText = '$before$prefix$selected$suffix$after';
    tc.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: before.length + prefix.length + selected.length,
      ),
    );

    // Persist to DB
    final blockIndex = _blocks.indexWhere((b) => b.id == focusedBlockId);
    if (blockIndex != -1) {
      updateBlockText(blockIndex, tc.text);
    }
  }

  @override
  void dispose() {
    for (final tc in textControllers.values) {
      tc.dispose();
    }
    super.dispose();
  }

  final List<NoteBlockModel> _blocks = [];
  List<NoteBlockModel> get blocks => List.unmodifiable(_blocks);

  EditorController({
    required this.noteId,
    required this.blockRepo,
    required this.noteRepo,
  });

  // Load blocks from database
  Future<void> loadBlocks() async {
    final dbBlocks = await blockRepo.getByNote(noteId);
    _blocks.clear();

    for (final dbBlock in dbBlocks) {
      final type = BlockType.fromDb(dbBlock.type);
      List<BlockItemModel> items = [];

      if (type == BlockType.checklist ||
          type == BlockType.numberedList ||
          type == BlockType.bulletList) {
        final dbItems = await blockRepo.getItems(dbBlock.id);
        items = dbItems
            .map(
              (item) => BlockItemModel(
                id: item.id,
                content: item.content,
                isChecked: item.isChecked,
                position: item.position,
              ),
            )
            .toList();

        // Ensure at least one empty item
        if (items.isEmpty) {
          items = [BlockItemModel(content: '', position: 0)];
        }
      }

      _blocks.add(
        NoteBlockModel(
          id: dbBlock.id,
          noteId: noteId,
          type: type,
          position: dbBlock.position,
          textContent: NoteBlockModel.textFromJson(dbBlock.content),
          items: items,
        ),
      );
    }

    notifyListeners();
  }

  // Add a new block at the end
  Future<void> addBlock(BlockType type) async {
    final position = _blocks.length;
    final id = await blockRepo.createBlock(
      noteId: noteId,
      type: type.dbValue,
      position: position,
    );

    List<BlockItemModel> items = [];
    if (type == BlockType.checklist ||
        type == BlockType.numberedList ||
        type == BlockType.bulletList) {
      final itemId = await blockRepo.createItem(
        blockId: id,
        content: '',
        position: 0,
      );
      items = [BlockItemModel(id: itemId, content: '', position: 0)];
    }

    _blocks.add(
      NoteBlockModel(
        id: id,
        noteId: noteId,
        type: type,
        position: position,
        items: items,
      ),
    );

    notifyListeners();
  }

  // Update text content of a text/heading block
  Future<void> updateBlockText(int index, String text) async {
    final block = _blocks[index];
    final updated = block.copyWith(textContent: text);
    _blocks[index] = updated;

    final dbBlock = await _getDbBlock(block.id!);
    if (dbBlock != null) {
      await blockRepo.updateBlock(
        dbBlock.copyWith(content: Value(updated.toJson())),
      );
    }
    // No notifyListeners here — text field manages its own state
  }

  // Update a checklist/list item
  Future<void> updateItem(
    int blockIndex,
    int itemIndex,
    BlockItemModel updatedItem,
  ) async {
    final block = _blocks[blockIndex];
    final newItems = List<BlockItemModel>.from(block.items);
    newItems[itemIndex] = updatedItem;
    _blocks[blockIndex] = block.copyWith(items: newItems);

    if (updatedItem.id != null) {
      final dbItem = await _getDbItem(updatedItem.id!);
      if (dbItem != null) {
        await blockRepo.updateItem(
          dbItem.copyWith(
            content: updatedItem.content,
            isChecked: updatedItem.isChecked,
          ),
        );
      }
    }
    notifyListeners();
  }

  // Add an item to a list block
  Future<void> addItem(int blockIndex) async {
    final block = _blocks[blockIndex];
    final position = block.items.length;
    final itemId = await blockRepo.createItem(
      blockId: block.id!,
      content: '',
      position: position,
    );
    final newItems = List<BlockItemModel>.from(block.items)
      ..add(BlockItemModel(id: itemId, content: '', position: position));
    _blocks[blockIndex] = block.copyWith(items: newItems);
    notifyListeners();
  }

  // Remove an item from a list block
  Future<void> removeItem(int blockIndex, int itemIndex) async {
    final block = _blocks[blockIndex];
    if (block.items.length <= 1) return; // keep at least one item
    final item = block.items[itemIndex];
    if (item.id != null) await blockRepo.deleteItem(item.id!);
    final newItems = List<BlockItemModel>.from(block.items)
      ..removeAt(itemIndex);
    _blocks[blockIndex] = block.copyWith(items: newItems);
    notifyListeners();
  }

  // Delete a block
  Future<void> deleteBlock(int index) async {
    final block = _blocks[index];
    if (block.id != null) await blockRepo.deleteBlock(block.id!);
    _blocks.removeAt(index);
    notifyListeners();
  }

  // Reorder blocks
  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    final block = _blocks.removeAt(oldIndex);
    _blocks.insert(newIndex, block);
    // Update positions in DB
    final dbBlocks = await blockRepo.getByNote(noteId);
    final reordered = <dynamic>[];
    for (int i = 0; i < _blocks.length; i++) {
      final match = dbBlocks.where((b) => b.id == _blocks[i].id).firstOrNull;
      if (match != null) reordered.add(match);
    }
    await blockRepo.updatePositions(reordered.cast());
    notifyListeners();
  }

  // Helpers
  Future<dynamic> _getDbBlock(int id) async {
    final blocks = await blockRepo.getByNote(noteId);
    try {
      return blocks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _getDbItem(int id) async {
    // We need to search through all blocks
    final blocks = await blockRepo.getByNote(noteId);
    for (final block in blocks) {
      final items = await blockRepo.getItems(block.id);
      try {
        return items.firstWhere((i) => i.id == id);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
