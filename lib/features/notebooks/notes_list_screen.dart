import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../editor/note_editor_screen.dart';

final _notesInSectionProvider = StreamProvider.family<List<Note>, int>(
  (ref, sectionId) =>
      ref.watch(noteRepositoryProvider).watchBySection(sectionId),
);

class NotesListScreen extends ConsumerWidget {
  final Section section;
  final Notebook notebook;

  const NotesListScreen({
    super.key,
    required this.section,
    required this.notebook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final notesAsync = ref.watch(_notesInSectionProvider(section.id));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(section.name)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_notes_list',
        onPressed: () async {
          final noteId = await ref
              .read(noteRepositoryProvider)
              .create(sectionId: section.id);
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

  Color? _tagColor() {
    if (note.colorTag == null) return null;
    const tagColors = {
      'red': Color(0xFFCF6679),
      'orange': Color(0xFFD4845A),
      'yellow': Color(0xFFD4C05A),
      'green': Color(0xFF5AAD7A),
      'blue': Color(0xFF5A8AD4),
      'purple': Color(0xFF9B5AD4),
      'teal': Color(0xFF5AC4C4),
    };
    return tagColors[note.colorTag];
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: note.id),
            ),
          ),
          onLongPress: () {
            // TODO: note options
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Color tag strip
              if (tagColor != null)
                Container(
                  width: 4,
                  height: 72,
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tagColor != null ? 16 : 20,
                    14,
                    20,
                    14,
                  ),
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
            ],
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
