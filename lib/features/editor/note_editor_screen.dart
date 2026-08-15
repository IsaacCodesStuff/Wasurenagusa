import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/note_block_model.dart';
import '../../core/providers/repository_providers.dart';
import '../../theme/wasurenagusa_theme.dart';
import 'editor_controller.dart';
import 'blocks/text_block_widget.dart';
import 'blocks/heading_block_widget.dart';
import 'blocks/checklist_block_widget.dart';
import 'blocks/list_block_widget.dart';
import 'blocks/divider_block_widget.dart';
import 'blocks/quote_block_widget.dart';
import 'blocks/code_block_widget.dart';
import 'blocks/drawing_block_widget.dart';
import 'blocks/table_block_widget.dart';
import '../../core/repositories/note_repository.dart';
import '../../widgets/note_options_sheet.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/database/app_database.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int noteId;
  final BlockType? initialBlockType;

  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.initialBlockType,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late EditorController _controller;
  final _titleController = TextEditingController();
  bool _loading = true;
  bool _reorderMode = false;
  late NoteRepository _noteRepo;
  final Map<int, GlobalKey> _blockKeys = {};
  int? _draggingIndex;
  int? _targetIndex;
  double _dragY = 0;
  Note? _note;

  GlobalKey _keyFor(int index) {
    return _blockKeys.putIfAbsent(index, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _noteRepo = ref.read(noteRepositoryProvider);
    _controller = EditorController(
      noteId: widget.noteId,
      blockRepo: ref.read(blockRepositoryProvider),
      noteRepo: _noteRepo,
    );
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await _noteRepo.getById(widget.noteId);
    if (note != null) {
      _titleController.text = note.title;
      _note = note;
    }
    await _controller.loadBlocks();

    if (widget.initialBlockType != null && _controller.blocks.isEmpty) {
      await _controller.addBlock(widget.initialBlockType!);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _saveTitle();
    _titleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final note = await _noteRepo.getById(widget.noteId);
    if (note != null) {
      await _noteRepo.update(note.copyWith(title: _titleController.text));
    }
  }

  void _showColorTagPicker() {
    final colors = WasurenagusaTheme.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tag color',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // No color option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final note = await _noteRepo.getById(widget.noteId);
                      if (note != null) {
                        await _noteRepo.update(
                          note.copyWith(colorTag: const Value(null)),
                        );
                        if (mounted) {
                          setState(
                            () => _note = note.copyWith(
                              colorTag: const Value(null),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.onSurfaceVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                  ),
                  ...kColorTags.entries.map((entry) {
                    final isSelected = _note?.colorTag == entry.key;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final note = await _noteRepo.getById(widget.noteId);
                        if (note != null) {
                          await _noteRepo.update(
                            note.copyWith(colorTag: Value(entry.key)),
                          );
                          if (mounted) {
                            setState(
                              () => _note = note.copyWith(
                                colorTag: Value(entry.key),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: colors.onSurface, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTableSizePicker() {
    final colors = WasurenagusaTheme.of(context).colors;
    int selectedRow = 0;
    int selectedCol = 0;
    const maxR = 6;
    const maxC = 9;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table size',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedRow + 1} rows × ${selectedCol + 1} columns  •  row 1 is the header',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int r = 0; r < maxR; r++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int c = 0; c < maxC; c++)
                            GestureDetector(
                              onTap: () => setSheet(() {
                                selectedRow = r;
                                selectedCol = c;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: r <= selectedRow && c <= selectedCol
                                      ? colors.accent.withValues(alpha: 0.2)
                                      : colors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: r <= selectedRow && c <= selectedCol
                                        ? colors.accent
                                        : colors.divider,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final rows = selectedRow + 1;
                      final cols = selectedCol + 1;
                      Navigator.pop(ctx);
                      _controller.addBlock(
                        BlockType.table,
                        initialTableData: TableData.empty(
                          rows: rows,
                          cols: cols,
                        ),
                      );
                    },
                    child: Text(
                      'Create ${selectedRow + 1} × ${selectedCol + 1} table  (1 header + $selectedRow data rows)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB grid popup ────────────────────────
  void _showBlockPicker() {
    final colors = WasurenagusaTheme.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Add block',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _BlockPickerItem(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.text);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.title_rounded,
                    label: 'Heading',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.heading);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.check_box_outlined,
                    label: 'Checklist',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.checklist);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Numbered',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.numberedList);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Bullet',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.bulletList);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.format_quote_rounded,
                    label: 'Quote',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.quote);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.code_rounded,
                    label: 'Code',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.code);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.draw_outlined,
                    label: 'Drawing',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _controller.addBlock(BlockType.drawing);
                    },
                  ),
                  _BlockPickerItem(
                    icon: Icons.table_chart_outlined,
                    label: 'Table',
                    colors: colors,
                    onTap: () {
                      Navigator.pop(context);
                      _showTableSizePicker();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _saveTitle(),
        ),
        actions: [
          // Reorder mode toggle
          IconButton(
            icon: Icon(
              _reorderMode ? Icons.check_rounded : Icons.menu_rounded,
              color: _reorderMode ? colors.accent : colors.onSurface,
            ),
            tooltip: _reorderMode ? 'Done reordering' : 'Reorder blocks',
            onPressed: () {
              setState(() {
                _reorderMode = !_reorderMode;
                _blockKeys.clear();
                _draggingIndex = null;
                _targetIndex = null;
              });
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _reorderMode
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FloatingActionButton(
                heroTag: 'fab_editor',
                onPressed: _showBlockPicker,
                child: const Icon(Icons.add_rounded),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: _controller.blocks.isEmpty
                              ? _EmptyEditor(colors: colors)
                              : _reorderMode
                              ? _buildReorderList(colors)
                              : _buildNormalList(colors),
                        ),
                      ],
                    ),
                    if (!_reorderMode)
                      Positioned(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _FormattingToolbar(
                            colors: colors,
                            enabled:
                                _controller.focusedBlockId != -1 &&
                                _controller.blocks.any(
                                  (b) =>
                                      b.id == _controller.focusedBlockId ||
                                      -b.id! == _controller.focusedBlockId,
                                ),
                            onBold: () => _insertFormat('**', '**'),
                            onItalic: () => _insertFormat('*', '*'),
                            onCode: () => _insertFormat('`', '`'),
                            onStrikethrough: () => _insertFormat('~~', '~~'),
                            currentColorTag: _note?.colorTag, // add
                            onColorTag: _showColorTagPicker, // add
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  // ── Normal list (no drag handles, no card backgrounds) ───
  Widget _buildNormalList(WasurenagusaColorScheme colors) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        itemCount: _controller.blocks.length,
        itemBuilder: (context, i) {
          final block = _controller.blocks[i];
          return _buildBlock(block, i, colors, reorderMode: false);
        },
      ),
    );
  }

  // ── Reorder list (card backgrounds + drag handles) ───────
  Widget _buildReorderList(WasurenagusaColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text(
            'Hold a block to drag and reorganize',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 96),
            itemCount: _controller.blocks.length,
            itemBuilder: (context, i) {
              final block = _controller.blocks[i];
              final isDragging = _draggingIndex == i;
              final isTarget = _targetIndex == i && _draggingIndex != i;

              return _DragCard(
                key: _keyFor(i),
                colors: colors,
                isDragging: isDragging,
                isTarget: isTarget,
                onDragStart: (details) => _onDragStart(i, details),
                onDragUpdate: (details) => _onDragUpdate(details),
                onDragEnd: (_) => _onDragEnd(),
                child: _buildBlockWidget(block, i, colors),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onDragStart(int index, LongPressStartDetails details) {
    setState(() {
      _draggingIndex = index;
      _targetIndex = index;
      _dragY = details.globalPosition.dy;
    });
  }

  void _onDragUpdate(LongPressMoveUpdateDetails details) {
    _dragY = details.globalPosition.dy;
    final newTarget = _findTargetIndex(_dragY);
    if (newTarget != _targetIndex) {
      setState(() => _targetIndex = newTarget);
    }
  }

  void _onDragEnd() {
    if (_draggingIndex != null &&
        _targetIndex != null &&
        _draggingIndex != _targetIndex) {
      _controller.reorderBlocks(_draggingIndex!, _targetIndex!);
      // Remap keys after reorder
      _blockKeys.clear();
    }
    setState(() {
      _draggingIndex = null;
      _targetIndex = null;
    });
  }

  int _findTargetIndex(double globalY) {
    int best = _draggingIndex ?? 0;
    double bestDist = double.infinity;

    for (int i = 0; i < _controller.blocks.length; i++) {
      final key = _blockKeys[i];
      if (key == null) continue;
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      final center = pos.dy + box.size.height / 2;
      final dist = (globalY - center).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  // ── Format insertion ──────────────────────
  void _insertFormat(String prefix, String suffix) {
    _controller.insertAtCursor(prefix, suffix);
  }

  Widget _buildBlock(
    NoteBlockModel block,
    int index,
    WasurenagusaColorScheme colors, {
    required bool reorderMode,
  }) {
    final key = ValueKey(block.id ?? index);
    final blockWidget = _buildBlockWidget(block, index, colors);
    return KeyedSubtree(key: key, child: blockWidget);
  }

  Widget _buildBlockWidget(
    NoteBlockModel block,
    int index,
    WasurenagusaColorScheme colors,
  ) {
    switch (block.type) {
      case BlockType.text:
        return TextBlockWidget(
          block: block,
          colors: colors,
          textController: _controller.controllerFor(block),
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
          onFocused: () => _controller.onBlockFocused(block.id!),
          onUnfocused: () => _controller.onBlockUnfocused(block.id!),
        );
      case BlockType.heading:
        return HeadingBlockWidget(
          block: block,
          colors: colors,
          textController: _controller.controllerFor(block),
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
          onFocused: () => _controller.onBlockFocused(block.id!),
          onUnfocused: () => _controller.onBlockUnfocused(block.id!),
        );
      case BlockType.checklist:
        return ChecklistBlockWidget(
          block: block,
          colors: colors,
          controller: _controller,
          blockIndex: index,
          onItemFocusGained: (tc) {
            _controller.textControllers[-block.id!] = tc;
            _controller.onBlockFocused(-block.id!);
          },
          onItemFocusLost: () {
            _controller.textControllers.remove(-block.id!);
            _controller.onBlockUnfocused(-block.id!);
          },
        );
      case BlockType.numberedList:
      case BlockType.bulletList:
        return ListBlockWidget(
          block: block,
          colors: colors,
          controller: _controller,
          blockIndex: index,
          onItemFocusGained: (tc) {
            _controller.textControllers[-block.id!] = tc;
            _controller.onBlockFocused(-block.id!);
          },
          onItemFocusLost: () {
            _controller.textControllers.remove(-block.id!);
            _controller.onBlockUnfocused(-block.id!);
          },
        );
      case BlockType.divider:
        return DividerBlockWidget(
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.quote:
        return QuoteBlockWidget(
          block: block,
          colors: colors,
          textController: _controller.controllerFor(block),
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
          onFocused: () => _controller.onBlockFocused(block.id!),
          onUnfocused: () => _controller.onBlockUnfocused(block.id!),
        );
      case BlockType.code:
        return CodeBlockWidget(
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.drawing:
        return DrawingBlockWidget(
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
          onSave: (data) => _controller.updateDrawingData(index, data),
        );
      case BlockType.table:
        return TableBlockWidget(
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
          onSave: (data) => _controller.updateTableData(index, data),
        );
    }
  }
}

// ─────────────────────────────────────────────
// Reorder card wrapper
// ─────────────────────────────────────────────

class _DragCard extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  final bool isDragging;
  final bool isTarget;
  final void Function(LongPressStartDetails) onDragStart;
  final void Function(LongPressMoveUpdateDetails) onDragUpdate;
  final void Function(LongPressEndDetails) onDragEnd;
  final Widget child;

  const _DragCard({
    super.key,
    required this.colors,
    required this.isDragging,
    required this.isTarget,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onDragStart,
      onLongPressMoveUpdate: onDragUpdate,
      onLongPressEnd: onDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDragging
              ? colors.accent.withValues(alpha: 0.08)
              : isTarget
              ? colors.accent.withValues(alpha: 0.18)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDragging
                ? colors.accent.withValues(alpha: 0.3)
                : isTarget
                ? colors.accent
                : colors.divider,
            width: isTarget ? 2 : 1,
          ),
        ),
        child: AbsorbPointer(absorbing: true, child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Block picker item
// ─────────────────────────────────────────────

class _BlockPickerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;

  const _BlockPickerItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.accent, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Formatting toolbar
// ─────────────────────────────────────────────

class _FormattingToolbar extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  final bool enabled;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onCode;
  final VoidCallback onStrikethrough;
  final String? currentColorTag;
  final VoidCallback onColorTag;

  const _FormattingToolbar({
    required this.colors,
    required this.enabled,
    required this.onBold,
    required this.onItalic,
    required this.onCode,
    required this.onStrikethrough,
    required this.currentColorTag,
    required this.onColorTag,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarButton(
              label: 'B',
              bold: true,
              colors: colors,
              enabled: enabled,
              onTap: onBold,
            ),
            _ToolbarButton(
              label: 'I',
              italic: true,
              colors: colors,
              enabled: enabled,
              onTap: onItalic,
            ),
            _ToolbarButton(
              label: 'S̶',
              colors: colors,
              enabled: enabled,
              onTap: onStrikethrough,
            ),
            _ToolbarButton(
              label: '</>',
              mono: true,
              colors: colors,
              enabled: enabled,
              onTap: onCode,
            ),
            // Divider
            Container(width: 1, height: 24, color: colors.divider),
            // Color tag button
            GestureDetector(
              onTap: onColorTag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: currentColorTag != null
                        ? kColorTags[currentColorTag]
                        : colors.onSurfaceVariant.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentColorTag != null
                          ? kColorTags[currentColorTag]!
                          : colors.onSurfaceVariant,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String label;
  final bool bold;
  final bool italic;
  final bool mono;
  final WasurenagusaColorScheme colors;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.label,
    this.bold = false,
    this.italic = false,
    this.mono = false,
    required this.colors,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 52,
        height: 48,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? colors.onSurface : colors.onSurfaceVariant,
              fontSize: 15,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty editor state
// ─────────────────────────────────────────────

class _EmptyEditor extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  const _EmptyEditor({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: colors.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap + to add a block',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
