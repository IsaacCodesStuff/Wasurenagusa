import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../theme/wasurenagusa_theme.dart';
import 'notes_list_screen.dart';
import '../seiza/seiza_screen.dart';

final _sectionsProvider = StreamProvider.family<List<Section>, int>(
  (ref, notebookId) =>
      ref.watch(sectionRepositoryProvider).watchByNotebook(notebookId),
);

class SectionsScreen extends ConsumerWidget {
  final Notebook notebook;
  const SectionsScreen({super.key, required this.notebook});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final colors = WasurenagusaTheme.of(context).colors;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'New section',
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
            hintText: 'Section name',
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
                  .read(sectionRepositoryProvider)
                  .create(notebookId: notebook.id, name: name);
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
    );
  }

  void _showSectionOptions(
    BuildContext context,
    WidgetRef ref,
    Section section,
  ) {
    final colors = WasurenagusaTheme.of(context).colors;
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
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: colors.onSurface),
                title: Text(
                  'Rename',
                  style: TextStyle(color: colors.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, ref, section);
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
                  await ref.read(sectionRepositoryProvider).delete(section.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Section section) {
    final colors = WasurenagusaTheme.of(context).colors;
    final controller = TextEditingController(text: section.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename section',
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
            hintText: 'Section name',
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
                  .read(sectionRepositoryProvider)
                  .update(section.copyWith(name: name));
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
    final sectionsAsync = ref.watch(_sectionsProvider(notebook.id));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notebook.icon ?? '📓'),
            const SizedBox(width: 8),
            Text(notebook.name),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.hub_outlined, color: colors.onSurface),
            tooltip: 'Seiza',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeizaScreen(notebook: notebook),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_sections',
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sections) {
          if (sections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🗂️', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No sections yet',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a section',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: sections.length,
            itemBuilder: (context, i) {
              final section = sections[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Material(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotesListScreen(
                          section: section,
                          notebook: notebook,
                        ),
                      ),
                    ),
                    onLongPress: () =>
                        _showSectionOptions(context, ref, section),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: colors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              section.name,
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
            },
          );
        },
      ),
    );
  }
}
