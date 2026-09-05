import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/services/note_export_service.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../../widgets/note_options_sheet.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  List<NoteExportItem> _allNotes = [];
  final Set<int> _selectedNoteIds = {};
  bool _loading = true;
  bool _exporting = false;
  final _zipNameController = TextEditingController(text: 'wasurenagusa_export');

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _zipNameController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final service = NoteExportService(
      noteRepo: ref.read(noteRepositoryProvider),
      notebookRepo: ref.read(notebookRepositoryProvider),
      sectionRepo: ref.read(sectionRepositoryProvider),
      blockRepo: ref.read(blockRepositoryProvider),
    );
    final notes = await service.loadAllNotes();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _loading = false;
      });
    }
  }

  Future<void> _export() async {
    if (_selectedNoteIds.isEmpty) return;
    final selected = _allNotes
        .where((n) => _selectedNoteIds.contains(n.note.id))
        .toList();

    setState(() => _exporting = true);

    try {
      final service = NoteExportService(
        noteRepo: ref.read(noteRepositoryProvider),
        notebookRepo: ref.read(notebookRepositoryProvider),
        sectionRepo: ref.read(sectionRepositoryProvider),
        blockRepo: ref.read(blockRepositoryProvider),
      );
      final result = await service.exportNotes(
        items: selected,
        zipName: _zipNameController.text,
        context: context,
      );

      if (!mounted) return;

      switch (result.status) {
        case ExportStatus.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export saved successfully')),
          );
        case ExportStatus.cancelled:
          break; // user dismissed the picker, do nothing
        case ExportStatus.failure:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: ${result.errorMessage}')),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showZipNameDialog(WasurenagusaColorScheme colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ZIP file name',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _zipNameController,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'wasurenagusa_export',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            suffixText: '.zip',
            suffixStyle: TextStyle(color: colors.onSurfaceVariant),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
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
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Export notes'),
        actions: [
          if (_selectedNoteIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                if (_selectedNoteIds.length == _allNotes.length) {
                  _selectedNoteIds.clear();
                } else {
                  _selectedNoteIds.addAll(_allNotes.map((n) => n.note.id));
                }
              }),
              child: Text(
                _selectedNoteIds.length == _allNotes.length
                    ? 'Deselect all'
                    : 'Select all',
                style: TextStyle(color: colors.accent),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.note_outlined,
                    color: colors.onSurfaceVariant,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes to export',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 120),
              itemCount: _allNotes.length,
              itemBuilder: (context, i) {
                final item = _allNotes[i];
                final isSelected = _selectedNoteIds.contains(item.note.id);
                final tagColor = resolveColorTag(item.note.colorTag);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Material(
                    color: isSelected
                        ? colors.accent.withValues(alpha: 0.1)
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedNoteIds.remove(item.note.id);
                        } else {
                          _selectedNoteIds.add(item.note.id);
                        }
                      }),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            // Tag color + notebook emoji
                            if (tagColor != null)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              item.notebook.icon ?? '📓',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            // Note info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.note.title.isEmpty
                                        ? 'Untitled'
                                        : item.note.title,
                                    style: TextStyle(
                                      color: item.note.title.isEmpty
                                          ? colors.onSurfaceVariant
                                          : colors.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: item.note.title.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.notebook.name} — ${item.section.name}',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Checkbox
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => setState(() {
                                if (isSelected) {
                                  _selectedNoteIds.remove(item.note.id);
                                } else {
                                  _selectedNoteIds.add(item.note.id);
                                }
                              }),
                              activeColor: colors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _allNotes.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.divider, width: 1),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showZipNameDialog(colors),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      label: Text(
                        '${_zipNameController.text}.zip',
                        style: TextStyle(color: colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _selectedNoteIds.isEmpty || _exporting
                        ? null
                        : _export,
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_rounded, size: 18),
                    label: Text(
                      _exporting
                          ? 'Exporting...'
                          : 'Export ZIP'
                                '${_selectedNoteIds.isEmpty ? '' : ' (${_selectedNoteIds.length})'}',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedNoteIds.isEmpty
                          ? colors.onSurfaceVariant.withValues(alpha: 0.3)
                          : colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
