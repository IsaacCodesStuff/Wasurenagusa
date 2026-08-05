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

  @override
  void initState() {
    super.initState();
    _controller = EditorController(
      noteId: widget.noteId,
      blockRepo: ref.read(blockRepositoryProvider),
      noteRepo: ref.read(noteRepositoryProvider),
    );
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await ref.read(noteRepositoryProvider).getById(widget.noteId);
    if (note != null) {
      _titleController.text = note.title;
    }
    await _controller.loadBlocks();

    // If launched with an initial block type, add it if no blocks exist
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
    final note = await ref.read(noteRepositoryProvider).getById(widget.noteId);
    if (note != null) {
      await ref
          .read(noteRepositoryProvider)
          .update(note.copyWith(title: _titleController.text));
    }
  }

  void _showAddBlockMenu() {
    final colors = WasurenagusaTheme.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Add block',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _AddBlockOption(
                icon: Icons.text_fields_rounded,
                label: 'Text',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  _controller.addBlock(BlockType.text);
                },
              ),
              _AddBlockOption(
                icon: Icons.title_rounded,
                label: 'Heading',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  _controller.addBlock(BlockType.heading);
                },
              ),
              _AddBlockOption(
                icon: Icons.check_box_outlined,
                label: 'Checklist',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  _controller.addBlock(BlockType.checklist);
                },
              ),
              _AddBlockOption(
                icon: Icons.format_list_numbered_rounded,
                label: 'Numbered list',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  _controller.addBlock(BlockType.numberedList);
                },
              ),
              _AddBlockOption(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Bullet list',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  _controller.addBlock(BlockType.bulletList);
                },
              ),
              _AddBlockOption(
                icon: Icons.horizontal_rule_rounded,
                label: 'Divider',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  _controller.addBlock(BlockType.divider);
                },
              ),
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
          onSubmitted: (_) => _saveTitle(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: colors.onSurface),
            onPressed: () {
              // TODO: note options (pin, color tag, delete)
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    Expanded(
                      child: _controller.blocks.isEmpty
                          ? _EmptyEditor(colors: colors)
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 96,
                              ),
                              itemCount: _controller.blocks.length,
                              onReorderItem: (oldIndex, newIndex) =>
                                  _controller.reorderBlocks(oldIndex, newIndex),
                              itemBuilder: (context, i) {
                                final block = _controller.blocks[i];
                                return _buildBlock(block, i, colors);
                              },
                            ),
                    ),
                    // Add block button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAddBlockMenu,
                            icon: Icon(
                              Icons.add_rounded,
                              color: colors.accent,
                              size: 18,
                            ),
                            label: Text(
                              'Add block',
                              style: TextStyle(color: colors.accent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildBlock(
    NoteBlockModel block,
    int index,
    WasurenagusaColorScheme colors,
  ) {
    switch (block.type) {
      case BlockType.text:
        return TextBlockWidget(
          key: ValueKey(block.id ?? index),
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.heading:
        return HeadingBlockWidget(
          key: ValueKey(block.id ?? index),
          block: block,
          colors: colors,
          onChanged: (text) => _controller.updateBlockText(index, text),
          onDelete: () => _controller.deleteBlock(index),
        );
      case BlockType.checklist:
        return ChecklistBlockWidget(
          key: ValueKey(block.id ?? index),
          block: block,
          colors: colors,
          controller: _controller,
          blockIndex: index,
        );
      case BlockType.numberedList:
      case BlockType.bulletList:
        return ListBlockWidget(
          key: ValueKey(block.id ?? index),
          block: block,
          colors: colors,
          controller: _controller,
          blockIndex: index,
        );
      case BlockType.divider:
        return DividerBlockWidget(
          key: ValueKey(block.id ?? index),
          block: block,
          colors: colors,
          onDelete: () => _controller.deleteBlock(index),
        );
    }
  }
}

class _EmptyEditor extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  const _EmptyEditor({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tap "Add block" to start writing',
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _AddBlockOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;

  const _AddBlockOption({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.accent, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
