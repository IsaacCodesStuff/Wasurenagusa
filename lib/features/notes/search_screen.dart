import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../../widgets/note_options_sheet.dart';
import '../editor/note_editor_screen.dart';
import '../../app_shell.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<Note> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    final results = await ref.read(noteRepositoryProvider).search(trimmed);
    setState(() {
      _results = results;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(shellIndexProvider.notifier).setIndex(0);
          },
        ),
        title: TextField(
          controller: _controller,
          autofocus: false,
          style: TextStyle(color: colors.onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search notes...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: _search,
        ),
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(WasurenagusaColorScheme colors) {
    // Initial state — nothing searched yet
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              color: colors.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Search your notes',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Results will appear as you type',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // No results
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No notes found',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Results
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final note = _results[i];
        return _SearchResultCard(
          note: note,
          colors: colors,
          ref: ref,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: note.id),
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Note note;
  final WasurenagusaColorScheme colors;
  final WidgetRef ref;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.note,
    required this.colors,
    required this.ref,
    required this.onTap,
  });

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
    final tagColor = note.colorTag != null ? kColorTags[note.colorTag] : null;

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
