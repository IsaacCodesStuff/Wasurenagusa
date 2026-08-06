import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../editor/note_editor_screen.dart';
import '../../core/models/note_block_model.dart';
import '../../widgets/note_options_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showNoteTypePicker(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                  child: Text(
                    'New note',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _NoteTypeOption(
                  icon: Icons.text_fields_rounded,
                  label: 'Text note',
                  description: 'Plain writing, headings, paragraphs',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    await _createAndOpen(context, ref, BlockType.text);
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.check_box_outlined,
                  label: 'Checklist',
                  description: 'Tasks, to-dos, shopping lists',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    await _createAndOpen(context, ref, BlockType.checklist);
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Numbered list',
                  description: 'Ordered steps or ranked items',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    await _createAndOpen(context, ref, BlockType.numberedList);
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Bullet list',
                  description: 'Unordered items',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    await _createAndOpen(context, ref, BlockType.bulletList);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createAndOpen(
    BuildContext context,
    WidgetRef ref,
    BlockType initialType,
  ) async {
    final noteId = await ref.read(noteRepositoryProvider).create();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              NoteEditorScreen(noteId: noteId, initialBlockType: initialType),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final pinnedAsync = ref.watch(pinnedNotesProvider);
    final recentAsync = ref.watch(recentNotesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Wasurenagusa')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_home',
        onPressed: () => _showNoteTypePicker(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Pinned ──────────────────────────────
          pinnedAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (pinned) {
              if (pinned.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(label: 'Pinned', colors: colors),
                    ...pinned.map(
                      (note) => _HomeNoteCard(
                        note: note,
                        colors: colors,
                        ref: ref,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NoteEditorScreen(noteId: note.id),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Recent ──────────────────────────────
          recentAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (recent) {
              if (recent.isEmpty) {
                return SliverFillRemaining(child: _EmptyHome(colors: colors));
              }
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(label: 'Recent', colors: colors),
                    ...recent.map(
                      (note) => _HomeNoteCard(
                        note: note,
                        colors: colors,
                        ref: ref,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NoteEditorScreen(noteId: note.id),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final WasurenagusaColorScheme colors;

  const _SectionHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Note card for home screen
// ─────────────────────────────────────────────
class _HomeNoteCard extends StatelessWidget {
  final Note note;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;
  final WidgetRef ref;

  const _HomeNoteCard({
    required this.note,
    required this.colors,
    required this.onTap,
    required this.ref,
  });

  Color? _tagColor() =>
      note.colorTag != null ? kColorTags[note.colorTag] : null;

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _tagColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => showNoteOptions(context, ref, note),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: tagColor != null
                  ? Border(left: BorderSide(color: tagColor, width: 6))
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: TextStyle(
                            color: note.title.isEmpty
                                ? colors.onSurfaceVariant
                                : colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontStyle: note.title.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(note.updatedAt),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin_rounded,
                      color: colors.accent,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────
class _EmptyHome extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  const _EmptyHome({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌸', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'have you forgotten about me?',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Note type option for FAB picker
// ─────────────────────────────────────────────
class _NoteTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;

  const _NoteTypeOption({
    required this.icon,
    required this.label,
    required this.description,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.accent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
