import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/providers/repository_providers.dart';
import '../theme/wasurenagusa_theme.dart';

// Shows a two-step navigable dialog:
//   Step 1 — pick a notebook
//   Step 2 — pick or create a section within that notebook
//
// Returns the selected Section, or null if dismissed.
Future<Section?> showSectionPicker(BuildContext context, WidgetRef ref) async {
  return showDialog<Section>(
    context: context,
    builder: (context) => _SectionPickerDialog(ref: ref),
  );
}

class _SectionPickerDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _SectionPickerDialog({required this.ref});

  @override
  ConsumerState<_SectionPickerDialog> createState() =>
      _SectionPickerDialogState();
}

class _SectionPickerDialogState extends ConsumerState<_SectionPickerDialog> {
  Notebook? _selectedNotebook;
  List<Notebook> _notebooks = [];
  List<Section> _sections = [];
  bool _loadingNotebooks = true;
  bool _loadingSections = false;
  bool _showAddSection = false;
  final _sectionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    super.dispose();
  }

  Future<void> _loadNotebooks() async {
    final notebooks = await ref
        .read(notebookRepositoryProvider)
        .watchAll()
        .first;
    if (mounted) {
      setState(() {
        _notebooks = notebooks;
        _loadingNotebooks = false;
      });
    }
  }

  Future<void> _selectNotebook(Notebook notebook) async {
    setState(() {
      _selectedNotebook = notebook;
      _loadingSections = true;
      _showAddSection = false;
      _sectionNameController.clear();
    });
    final sections = await ref
        .read(sectionRepositoryProvider)
        .getSectionsByNotebook(notebook.id);
    if (mounted) {
      setState(() {
        _sections = sections;
        _loadingSections = false;
      });
    }
  }

  Future<void> _createSection() async {
    final name = _sectionNameController.text.trim();
    if (name.isEmpty) return;
    if (_selectedNotebook == null) return;

    final sectionId = await ref
        .read(sectionRepositoryProvider)
        .create(notebookId: _selectedNotebook!.id, name: name);

    // Reload sections so the new one appears in the list
    final sections = await ref
        .read(sectionRepositoryProvider)
        .getSectionsByNotebook(_selectedNotebook!.id);

    if (mounted) {
      setState(() {
        _sections = sections;
        _showAddSection = false;
        _sectionNameController.clear();
      });

      // Find the newly created section by id and return it
      final created = sections.where((s) => s.id == sectionId).firstOrNull;
      if (created != null) {
        // Don't auto-select — let user tap it explicitly per the design decision
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (_selectedNotebook != null)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colors.onSurface,
                      ),
                      onPressed: () => setState(() {
                        _selectedNotebook = null;
                        _sections = [];
                        _showAddSection = false;
                        _sectionNameController.clear();
                      }),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      _selectedNotebook == null
                          ? 'Select notebook'
                          : _selectedNotebook!.name,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),

            // ── Body ─────────────────────────────
            Expanded(
              child: _selectedNotebook == null
                  ? _buildNotebookList(colors)
                  : _buildSectionList(colors),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notebook list ─────────────────────────
  Widget _buildNotebookList(WasurenagusaColorScheme colors) {
    if (_loadingNotebooks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notebooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No notebooks yet. Create one first.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notebooks.length,
      itemBuilder: (context, i) {
        final notebook = _notebooks[i];
        return ListTile(
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
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurfaceVariant,
          ),
          onTap: () => _selectNotebook(notebook),
        );
      },
    );
  }

  // ── Section list ──────────────────────────
  Widget _buildSectionList(WasurenagusaColorScheme colors) {
    if (_loadingSections) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: _sections.isEmpty && !_showAddSection
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No sections yet. Add one below.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _sections.length,
                  itemBuilder: (context, i) {
                    final section = _sections[i];
                    return ListTile(
                      leading: Icon(
                        Icons.folder_outlined,
                        color: colors.accent,
                        size: 22,
                      ),
                      title: Text(
                        section.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, section),
                    );
                  },
                ),
        ),

        // ── Add section area ──────────────────
        Divider(height: 1, color: colors.divider),
        if (_showAddSection)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sectionNameController,
                    autofocus: true,
                    style: TextStyle(color: colors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Section name',
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _createSection(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: _createSection,
                  child: const Text('Add'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() {
                    _showAddSection = false;
                    _sectionNameController.clear();
                  }),
                ),
              ],
            ),
          )
        else
          ListTile(
            leading: Icon(Icons.add_rounded, color: colors.accent, size: 22),
            title: Text(
              'Add section',
              style: TextStyle(
                color: colors.accent,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => setState(() => _showAddSection = true),
          ),
      ],
    );
  }
}
