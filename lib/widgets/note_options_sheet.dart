import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../core/database/app_database.dart';
import '../core/providers/repository_providers.dart';
import '../theme/wasurenagusa_theme.dart';
import 'package:drift/drift.dart' show Value;

// Legacy named color tags — kept for backwards compatibility with existing notes
const Map<String, Color> kColorTags = {
  'red': Color(0xFFCF6679),
  'orange': Color(0xFFD4845A),
  'yellow': Color(0xFFD4C05A),
  'green': Color(0xFF5AAD7A),
  'blue': Color(0xFF5A8AD4),
  'purple': Color(0xFF9B5AD4),
  'teal': Color(0xFF5AC4C4),
};

// Resolves a colorTag string to a Color.
// Handles both legacy named keys and new hex strings.
Color? resolveColorTag(String? tag) {
  if (tag == null) return null;
  if (kColorTags.containsKey(tag)) return kColorTags[tag];
  try {
    final hex = tag.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return null;
  }
}

// Converts a Color to a hex string for storage.
String colorToTag(Color color) {
  final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${hex.substring(2)}'; // strip alpha, keep RGB
}

Future<void> showNoteOptions(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final colors = WasurenagusaTheme.of(context).colors;

  await showModalBottomSheet(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        _NoteOptionsSheet(note: note, colors: colors, ref: ref),
  );
}

class _NoteOptionsSheet extends ConsumerStatefulWidget {
  final Note note;
  final WasurenagusaColorScheme colors;
  final WidgetRef ref;

  const _NoteOptionsSheet({
    required this.note,
    required this.colors,
    required this.ref,
  });

  @override
  ConsumerState<_NoteOptionsSheet> createState() => _NoteOptionsSheetState();
}

class _NoteOptionsSheetState extends ConsumerState<_NoteOptionsSheet> {
  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  // ── Pin ─────────────────────────────────────
  Future<void> _togglePin() async {
    await ref.read(noteRepositoryProvider).togglePin(_note);
    if (mounted) Navigator.pop(context);
  }

  // ── Rename ──────────────────────────────────
  void _showRenameDialog() {
    final noteRepo = ref.read(noteRepositoryProvider);
    Navigator.pop(context);

    final controller = TextEditingController(text: _note.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename note',
          style: TextStyle(
            color: widget.colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: widget.colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Note title',
            hintStyle: TextStyle(color: widget.colors.onSurfaceVariant),
            filled: true,
            fillColor: widget.colors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await noteRepo.update(_note.copyWith(title: name));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Rename',
              style: TextStyle(
                color: widget.colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Color tag ───────────────────────────────
  void _showColorTagPicker() {
    final colors = widget.colors;
    final currentColor = resolveColorTag(_note.colorTag) ?? colors.accent;
    Color pickerColor = currentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Color tag',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Remove color button
                      if (_note.colorTag != null)
                        TextButton.icon(
                          onPressed: () async {
                            await ref
                                .read(noteRepositoryProvider)
                                .update(
                                  _note.copyWith(colorTag: const Value(null)),
                                );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              Navigator.pop(ctx);
                            }
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          label: Text(
                            'Remove',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HueRingPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) =>
                        setSheet(() => pickerColor = color),
                    enableAlpha: false,
                    displayThumbColor: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: pickerColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final tag = colorToTag(pickerColor);
                        await ref
                            .read(noteRepositoryProvider)
                            .update(_note.copyWith(colorTag: Value(tag)));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        'Apply color',
                        style: TextStyle(
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
      ),
    );
  }

  // ── Move to section ─────────────────────────
  void _showMoveToSection() {
    final colors = widget.colors;
    final notebooksAsync = ref.read(notebooksProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Move to section',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: notebooksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (notebooks) => ListView.builder(
                  controller: scrollController,
                  itemCount: notebooks.length,
                  itemBuilder: (context, i) {
                    final notebook = notebooks[i];
                    return _NotebookExpansionTile(
                      notebook: notebook,
                      colors: colors,
                      note: _note,
                      ref: ref,
                      onMoved: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Duplicate ───────────────────────────────
  Future<void> _duplicate() async {
    await ref
        .read(noteRepositoryProvider)
        .create(
          sectionId: _note.sectionId,
          title: _note.title.isEmpty ? 'Copy' : '${_note.title} (copy)',
          colorTag: _note.colorTag,
        );
    if (mounted) Navigator.pop(context);
  }

  // ── Delete ──────────────────────────────────
  void _showDeleteConfirm() {
    final colors = widget.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete note?',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete "${_note.title.isEmpty ? 'Untitled' : _note.title}" and all its content.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(noteRepositoryProvider).delete(_note.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: const Color(0xFFCF6679),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final tagColor = resolveColorTag(_note.colorTag);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    if (tagColor != null)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _note.title.isEmpty ? 'Untitled' : _note.title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 8),
              _OptionTile(
                icon: _note.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                label: _note.isPinned ? 'Unpin' : 'Pin',
                colors: colors,
                onTap: _togglePin,
              ),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: 'Rename',
                colors: colors,
                onTap: _showRenameDialog,
              ),
              _OptionTile(
                icon: Icons.circle_outlined,
                label: 'Color tag',
                colors: colors,
                trailing: tagColor != null
                    ? Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: _showColorTagPicker,
              ),
              _OptionTile(
                icon: Icons.drive_file_move_outlined,
                label: 'Move to section',
                colors: colors,
                onTap: _showMoveToSection,
              ),
              _OptionTile(
                icon: Icons.copy_outlined,
                label: 'Duplicate',
                colors: colors,
                onTap: _duplicate,
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                colors: colors,
                isDestructive: true,
                onTap: _showDeleteConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Option tile
// ─────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFCF6679) : colors.onSurface;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}

// ─────────────────────────────────────────────
// Notebook expansion tile for Move to section
// ─────────────────────────────────────────────
class _NotebookExpansionTile extends ConsumerWidget {
  final Notebook notebook;
  final WasurenagusaColorScheme colors;
  final Note note;
  final WidgetRef ref;
  final VoidCallback onMoved;

  const _NotebookExpansionTile({
    required this.notebook,
    required this.colors,
    required this.note,
    required this.ref,
    required this.onMoved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(
      StreamProvider.family<List<Section>, int>(
        (ref, id) => ref.watch(sectionRepositoryProvider).watchByNotebook(id),
      )(notebook.id),
    );

    return ExpansionTile(
      leading: Text(
        notebook.icon ?? '📓',
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(
        notebook.name,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: colors.onSurfaceVariant,
      collapsedIconColor: colors.onSurfaceVariant,
      children: sectionsAsync.when(
        loading: () => [
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ],
        error: (e, _) => [],
        data: (sections) => sections
            .map(
              (section) => ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                leading: Icon(
                  Icons.folder_outlined,
                  color: colors.accent,
                  size: 20,
                ),
                title: Text(
                  section.name,
                  style: TextStyle(color: colors.onSurface, fontSize: 14),
                ),
                onTap: () async {
                  await ref
                      .read(noteRepositoryProvider)
                      .update(note.copyWith(sectionId: Value(section.id)));
                  onMoved();
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
