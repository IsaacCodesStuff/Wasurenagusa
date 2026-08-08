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
import '../../widgets/note_options_sheet.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/note_repository.dart';

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
  Note? _note;
  late NoteRepository _noteRepo;

  // Tracks which block is focused for the formatting toolbar
  int? _focusedBlockIndex;
  final Map<int, FocusNode> _focusNodes = {};

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
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final note = await _noteRepo.getById(widget.noteId);
    if (note != null) {
      await _noteRepo.update(note.copyWith(title: _titleController.text));
    }
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
                      _controller.addBlock(BlockType.table);
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
            onPressed: () => setState(() => _reorderMode = !_reorderMode),
          ),
        ],
      ),
      floatingActionButton: _reorderMode
          ? null
          : FloatingActionButton(
              heroTag: 'fab_editor',
              onPressed: _showBlockPicker,
              child: const Icon(Icons.add_rounded),
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
                        left: 24,
                        right: 24,
                        child: _FormattingToolbar(
                          colors: colors,
                          enabled:
                              _focusedBlockIndex != null &&
                              _controller.blocks.isNotEmpty &&
                              _controller
                                  .blocks[_focusedBlockIndex!]
                                  .type
                                  .hasTextContent,
                          onBold: () => _insertFormat('**', '**'),
                          onItalic: () => _insertFormat('*', '*'),
                          onCode: () => _insertFormat('`', '`'),
                          onStrikethrough: () => _insertFormat('~~', '~~'),
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
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: _controller.blocks.length,
      itemBuilder: (context, i) {
        final block = _controller.blocks[i];
        return _buildBlock(block, i, colors, reorderMode: false);
      },
    );
  }

  // ── Reorder list (card backgrounds + drag handles) ───────
  Widget _buildReorderList(WasurenagusaColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text(
            'Drag a block to reorganize',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 96),
            itemCount: _controller.blocks.length,
            onReorderItem: _controller.reorderBlocks,
            itemBuilder: (context, i) {
              final block = _controller.blocks[i];
              return _ReorderCard(
                key: ValueKey(block.id ?? i),
                colors: colors,
                child: _buildBlock(block, i, colors, reorderMode: true),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Format insertion ──────────────────────
  void _insertFormat(String prefix, String suffix) {
    final index = _focusedBlockIndex;
    if (index == null) return;
    final block = _controller.blocks[index];
    if (!block.type.hasTextContent) return;
    final current = block.textContent;
    _controller.updateBlockText(index, '$current$prefix$suffix');
    setState(() {});
  }

  Widget _buildBlock(
    NoteBlockModel block,
    int index,
    WasurenagusaColorScheme colors, {
    required bool reorderMode,
  }) {
    final key = ValueKey(block.id ?? index);

    switch (block.type) {
      case BlockType.text:
        return TextBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.heading:
        return HeadingBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.checklist:
        return ChecklistBlockWidget(
          key: key,
          block: block,
          colors: colors,
          controller: _controller,
          blockIndex: index,
        );
      case BlockType.numberedList:
      case BlockType.bulletList:
        return ListBlockWidget(
          key: key,
          block: block,
          colors: colors,
          controller: _controller,
          blockIndex: index,
        );
      case BlockType.divider:
        return DividerBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.quote:
        return QuoteBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.code:
        return CodeBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.drawing:
        return DrawingBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.table:
        return TableBlockWidget(
          key: key,
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
        );
    }
  }
}

// ─────────────────────────────────────────────
// Reorder card wrapper
// ─────────────────────────────────────────────

class _ReorderCard extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  final Widget child;

  const _ReorderCard({super.key, required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: child,
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

  const _FormattingToolbar({
    required this.colors,
    required this.enabled,
    required this.onBold,
    required this.onItalic,
    required this.onCode,
    required this.onStrikethrough,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        ],
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
