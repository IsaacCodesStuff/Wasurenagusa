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
  final Map<int, TextSelection> _savedSelections = {};
  int focusedBlockId = -1;

  void saveSelection(int blockId, TextSelection selection) {
    _savedSelections[blockId] = selection;
  }

  void onBlockFocused(int blockId) {
    focusedBlockId = blockId;
    notifyListeners();
  }

  void onBlockUnfocused(int blockId) {
    if (focusedBlockId == blockId) {
      focusedBlockId = -1;
      notifyListeners();
    }
  }

  TextEditingController controllerFor(NoteBlockModel block) {
    return textControllers.putIfAbsent(
      block.id!,
      () => TextEditingController(text: block.textContent),
    );
  }

  void insertAtCursor(String prefix, String suffix) {
    // On desktop, focus is lost when toolbar is clicked so focusedBlockId
    // may be -1. Fall back to the last block that had a saved selection.
    int targetId = focusedBlockId;
    if (targetId == -1 && _savedSelections.isNotEmpty) {
      targetId = _savedSelections.keys.last;
    }
    if (targetId == -1) return;

    final tc = textControllers[targetId];
    if (tc == null) return;

    // Use live selection if valid, otherwise fall back to saved selection.
    TextSelection selection = tc.selection;
    if (!selection.isValid || selection.start == -1) {
      selection =
          _savedSelections[targetId] ??
          TextSelection.collapsed(offset: tc.text.length);
    }

    final text = tc.text;
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

    final blockIndex = _blocks.indexWhere((b) => b.id == targetId);
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

  Future<void> loadBlocks() async {
    final dbBlocks = await blockRepo.getByNote(noteId);
    _blocks.clear();

    for (final dbBlock in dbBlocks) {
      final type = BlockType.fromDb(dbBlock.type);

      // Silently skip legacy divider blocks — deprecated since 0.3.0,
      // removed from UI since 0.5.0. The DB row is left untouched until
      // the note is next saved, at which point it simply won't be written back.
      if (type == BlockType.divider) continue;

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
          drawingData: type == BlockType.drawing
              ? NoteBlockModel.drawingFromJson(dbBlock.content)
              : null,
          tableData: type == BlockType.table
              ? NoteBlockModel.tableFromJson(dbBlock.content)
              : null,
        ),
      );
    }

    notifyListeners();
  }

  Future<void> addBlock(BlockType type, {TableData? initialTableData}) async {
    final position = _blocks.length;

    // Serialize initial content for table blocks
    String? initialContent;
    if (type == BlockType.table) {
      final data = initialTableData ?? TableData.empty();
      initialContent = NoteBlockModel(
        noteId: noteId,
        type: type,
        position: position,
        tableData: data,
      ).toJson();
    }

    final id = await blockRepo.createBlock(
      noteId: noteId,
      type: type.dbValue,
      position: position,
      content: initialContent,
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
        drawingData: type == BlockType.drawing ? DrawingData.empty() : null,
        tableData: type == BlockType.table
            ? (initialTableData ?? TableData.empty())
            : null,
      ),
    );

    notifyListeners();
  }

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
  }

  Future<void> updateDrawingData(int index, DrawingData data) async {
    final block = _blocks[index];
    final updated = block.copyWith(drawingData: data);
    _blocks[index] = updated;

    final dbBlock = await _getDbBlock(block.id!);
    if (dbBlock != null) {
      await blockRepo.updateBlock(
        dbBlock.copyWith(content: Value(updated.toJson())),
      );
    }
    notifyListeners();
  }

  Future<void> updateTableData(int index, TableData data) async {
    final block = _blocks[index];
    final updated = block.copyWith(tableData: data);
    _blocks[index] = updated;

    final dbBlock = await _getDbBlock(block.id!);
    if (dbBlock != null) {
      await blockRepo.updateBlock(
        dbBlock.copyWith(content: Value(updated.toJson())),
      );
    }
    notifyListeners();
  }

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

  Future<void> removeItem(int blockIndex, int itemIndex) async {
    final block = _blocks[blockIndex];
    if (block.items.length <= 1) return;
    final item = block.items[itemIndex];
    if (item.id != null) await blockRepo.deleteItem(item.id!);
    final newItems = List<BlockItemModel>.from(block.items)
      ..removeAt(itemIndex);
    _blocks[blockIndex] = block.copyWith(items: newItems);
    notifyListeners();
  }

  Future<void> deleteBlock(int index) async {
    final block = _blocks[index];
    if (block.id != null) await blockRepo.deleteBlock(block.id!);
    _blocks.removeAt(index);
    notifyListeners();
  }

  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    final block = _blocks.removeAt(oldIndex);
    _blocks.insert(newIndex, block);
    final dbBlocks = await blockRepo.getByNote(noteId);
    final reordered = <dynamic>[];
    for (int i = 0; i < _blocks.length; i++) {
      final match = dbBlocks.where((b) => b.id == _blocks[i].id).firstOrNull;
      if (match != null) reordered.add(match);
    }
    await blockRepo.updatePositions(reordered.cast());
    notifyListeners();
  }

  Future<dynamic> _getDbBlock(int id) async {
    final blocks = await blockRepo.getByNote(noteId);
    try {
      return blocks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _getDbItem(int id) async {
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
