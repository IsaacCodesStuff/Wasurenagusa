import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/services/note_export_service.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../../widgets/note_options_sheet.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  NoteImportBundle? _bundle;
  final Set<int> _selectedIndices = {};
  bool _picking = false;
  bool _importing = false;

  Future<void> _pickZip() async {
    setState(() => _picking = true);
    try {
      final service = NoteImportService(
        noteRepo: ref.read(noteRepositoryProvider),
        notebookRepo: ref.read(notebookRepositoryProvider),
        sectionRepo: ref.read(sectionRepositoryProvider),
        blockRepo: ref.read(blockRepositoryProvider),
      );
      final bundle = await service.pickAndReadZip();
      if (!mounted) return;

      if (bundle != null && bundle.isInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That file isn\'t a valid Wasurenagusa export.'),
          ),
        );
        return;
      }

      setState(() {
        _bundle = bundle;
        _selectedIndices.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to read ZIP: $e')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _import() async {
    if (_bundle == null || _selectedIndices.isEmpty) return;
    final selected = _selectedIndices.map((i) => _bundle!.entries[i]).toList();

    setState(() => _importing = true);
    try {
      final service = NoteImportService(
        noteRepo: ref.read(noteRepositoryProvider),
        notebookRepo: ref.read(notebookRepositoryProvider),
        sectionRepo: ref.read(sectionRepositoryProvider),
        blockRepo: ref.read(blockRepositoryProvider),
      );
      await service.importEntries(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${selected.length} note${selected.length == 1 ? '' : 's'} successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    final bundle = _bundle;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Import notes'),
        actions: [
          if (bundle != null && bundle.entries.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                if (_selectedIndices.length == bundle.entries.length) {
                  _selectedIndices.clear();
                } else {
                  _selectedIndices.addAll(
                    List.generate(bundle.entries.length, (i) => i),
                  );
                }
              }),
              child: Text(
                _selectedIndices.length == bundle.entries.length
                    ? 'Deselect all'
                    : 'Select all',
                style: TextStyle(color: colors.accent),
              ),
            ),
        ],
      ),
      body: bundle == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_zip_outlined,
                    color: colors.onSurfaceVariant,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ZIP file selected',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap below to pick a Wasurenagusa export ZIP',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _picking ? null : _pickZip,
                    icon: _picking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(_picking ? 'Opening...' : 'Choose ZIP file'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ZIP name header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_zip_outlined,
                        color: colors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bundle.zipName,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _picking ? null : _pickZip,
                        child: Text(
                          'Change',
                          style: TextStyle(color: colors.accent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                // Notes list
                Expanded(
                  child: bundle.entries.isEmpty
                      ? Center(
                          child: Text(
                            'No notes found in this ZIP',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 120),
                          itemCount: bundle.entries.length,
                          itemBuilder: (context, i) {
                            final entry = bundle.entries[i];
                            final isSelected = _selectedIndices.contains(i);
                            final tagColor = resolveColorTag(entry.colorTag);

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
                                      _selectedIndices.remove(i);
                                    } else {
                                      _selectedIndices.add(i);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      14,
                                    ),
                                    child: Row(
                                      children: [
                                        if (tagColor != null)
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tagColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Text(
                                          entry.notebookEmoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.noteTitle.isEmpty
                                                    ? 'Untitled'
                                                    : entry.noteTitle,
                                                style: TextStyle(
                                                  color: entry.noteTitle.isEmpty
                                                      ? colors.onSurfaceVariant
                                                      : colors.onSurface,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      entry.noteTitle.isEmpty
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${entry.notebookName} — ${entry.sectionName}',
                                                style: TextStyle(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => setState(() {
                                            if (isSelected) {
                                              _selectedIndices.remove(i);
                                            } else {
                                              _selectedIndices.add(i);
                                            }
                                          }),
                                          activeColor: colors.accent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: bundle == null || bundle.entries.isEmpty
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
              child: FilledButton.icon(
                onPressed: _selectedIndices.isEmpty || _importing
                    ? null
                    : _import,
                icon: _importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  _importing
                      ? 'Importing...'
                      : 'Import selected notes'
                            '${_selectedIndices.isEmpty ? '' : ' (${_selectedIndices.length})'}',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedIndices.isEmpty
                      ? colors.onSurfaceVariant.withValues(alpha: 0.3)
                      : colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ),
    );
  }
}
