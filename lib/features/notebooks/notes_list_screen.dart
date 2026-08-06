import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/note_repository.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../editor/note_editor_screen.dart';
import '../../widgets/note_options_sheet.dart';
import '../../core/providers/sort_preference_provider.dart';

final _notesInSectionProvider =
    StreamProvider.family<List<Note>, (int, NoteSortOrder)>(
      (ref, args) => ref
          .watch(noteRepositoryProvider)
          .watchBySectionSorted(args.$1, args.$2),
    );

class NotesListScreen extends ConsumerStatefulWidget {
  final Section section;
  final Notebook notebook;

  const NotesListScreen({
    super.key,
    required this.section,
    required this.notebook,
  });

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  NoteSortOrder _currentSort(WidgetRef ref) => ref.watch(
    sortPreferenceProvider.select(
      (map) => map[widget.section.id] ?? NoteSortOrder.lastEdited,
    ),
  );

  void _setSortOrder(WidgetRef ref, NoteSortOrder order) {
    ref
        .read(sortPreferenceProvider.notifier)
        .setSortOrder(widget.section.id, order);
  }

  void _showSortPicker(WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final currentSort = _currentSort(ref);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...NoteSortOrder.values.map((order) {
                final selected = order == currentSort;
                return ListTile(
                  leading: Icon(
                    _sortIcon(order),
                    color: selected ? colors.accent : colors.onSurfaceVariant,
                    size: 22,
                  ),
                  title: Text(
                    _sortLabel(order),
                    style: TextStyle(
                      color: selected ? colors.accent : colors.onSurface,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: colors.accent,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    _setSortOrder(ref, order);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _sortIcon(NoteSortOrder order) {
    switch (order) {
      case NoteSortOrder.lastEdited:
        return Icons.access_time_rounded;
      case NoteSortOrder.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case NoteSortOrder.nameZA:
        return Icons.sort_by_alpha_rounded;
      case NoteSortOrder.dateCreated:
        return Icons.calendar_today_rounded;
      case NoteSortOrder.colorTag:
        return Icons.circle_rounded;
    }
  }

  String _sortLabel(NoteSortOrder order) {
    switch (order) {
      case NoteSortOrder.lastEdited:
        return 'Last edited';
      case NoteSortOrder.nameAZ:
        return 'Name A → Z';
      case NoteSortOrder.nameZA:
        return 'Name Z → A';
      case NoteSortOrder.dateCreated:
        return 'Date created';
      case NoteSortOrder.colorTag:
        return 'Color tag';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    final sortOrder = _currentSort(ref);
    final notesAsync = ref.watch(
      _notesInSectionProvider((widget.section.id, sortOrder)),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(widget.section.name),
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded, color: colors.onSurface),
            onPressed: () => _showSortPicker(ref),
            tooltip: 'Sort',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_notes_list',
        onPressed: () async {
          final noteId = await ref
              .read(noteRepositoryProvider)
              .create(sectionId: widget.section.id);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NoteEditorScreen(noteId: noteId),
              ),
            );
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'have you forgotten about me?',
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
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final note = notes[i];
              return _NoteCard(note: note, colors: colors, ref: ref);
            },
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final WasurenagusaColorScheme colors;
  final WidgetRef ref;

  const _NoteCard({
    required this.note,
    required this.colors,
    required this.ref,
  });

  Color? _tagColor() =>
      note.colorTag != null ? kColorTags[note.colorTag] : null;

  @override
  Widget build(BuildContext context) {
    final tagColor = _tagColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: note.id),
            ),
          ),
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

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
