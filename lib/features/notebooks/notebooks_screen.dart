import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../theme/wasurenagusa_theme.dart';
import 'sections_screen.dart';

class NotebooksScreen extends ConsumerWidget {
  const NotebooksScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final nameController = TextEditingController();
    String selectedEmoji = '📓';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'New notebook',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji preview + picker button
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.accent, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        selectedEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await _showEmojiPicker(context, colors);
                        if (picked != null) {
                          setState(() => selectedEmoji = picked);
                        }
                      },
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: colors.accent,
                        size: 18,
                      ),
                      label: Text(
                        'Choose emoji',
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: colors.accent.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name field
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Notebook name',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  filled: true,
                  fillColor: colors.surfaceVariant,
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
            ],
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(notebookRepositoryProvider)
                    .create(name: name, icon: selectedEmoji);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(
                'Create',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showEmojiPicker(
    BuildContext context,
    WasurenagusaColorScheme colors,
  ) async {
    String? picked;
    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    'Choose emoji',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  picked = emoji.emoji;
                  Navigator.pop(ctx);
                },
                config: Config(
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: colors.surface,
                    emojiSizeMax: 28,
                    columns: 9,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: colors.surface,
                    iconColor: colors.onSurfaceVariant,
                    iconColorSelected: colors.accent,
                    indicatorColor: colors.accent,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: colors.surface,
                    buttonIconColor: colors.onSurfaceVariant,
                    hintText: 'Search emoji...',
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    enabled: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return picked;
  }

  void _showNotebookOptions(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
  ) {
    final colors = WasurenagusaTheme.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: colors.onSurface),
                  title: Text(
                    'Rename',
                    style: TextStyle(color: colors.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(context, ref, notebook);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colors.onSurface),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: colors.onSurface),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref
                        .read(notebookRepositoryProvider)
                        .delete(notebook.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
  ) {
    final colors = WasurenagusaTheme.of(context).colors;
    final controller = TextEditingController(text: notebook.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename notebook',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Notebook name',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            filled: true,
            fillColor: colors.surfaceVariant,
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
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await ref
                  .read(notebookRepositoryProvider)
                  .update(notebook.copyWith(name: name));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Rename',
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final notebooksAsync = ref.watch(notebooksProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Notebooks')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_notebooks',
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: notebooksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notebooks) {
          if (notebooks.isEmpty) {
            return _EmptyState(colors: colors);
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: notebooks.length,
            itemBuilder: (context, i) {
              final notebook = notebooks[i];
              return _NotebookCard(
                notebook: notebook,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SectionsScreen(notebook: notebook),
                  ),
                ),
                onLongPress: () => _showNotebookOptions(context, ref, notebook),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notebook card
// ─────────────────────────────────────────────
class _NotebookCard extends StatelessWidget {
  final Notebook notebook;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotebookCard({
    required this.notebook,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  notebook.icon ?? '📓',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notebook.name,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
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
class _EmptyState extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📓', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No notebooks yet',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first notebook',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
