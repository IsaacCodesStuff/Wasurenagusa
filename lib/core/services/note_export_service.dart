import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';
import '../repositories/block_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/notebook_repository.dart';
import '../repositories/section_repository.dart';
import '../models/note_block_model.dart';

const int _exportSchemaVersion = 1;
const String _exportFormat = 'wasurenagusa';

// ─────────────────────────────────────────────
// Export service
// ─────────────────────────────────────────────

class NoteExportService {
  final NoteRepository noteRepo;
  final NotebookRepository notebookRepo;
  final SectionRepository sectionRepo;
  final BlockRepository blockRepo;

  NoteExportService({
    required this.noteRepo,
    required this.notebookRepo,
    required this.sectionRepo,
    required this.blockRepo,
  });

  // Loads all notes with their notebook/section context for display
  Future<List<NoteExportItem>> loadAllNotes() async {
    final notebooks = await notebookRepo.watchAll().first;
    final items = <NoteExportItem>[];

    for (final notebook in notebooks) {
      final sections = await sectionRepo.getSectionsByNotebook(notebook.id);
      for (final section in sections) {
        final notes = await noteRepo.watchBySection(section.id).first;
        for (final note in notes) {
          items.add(
            NoteExportItem(note: note, notebook: notebook, section: section),
          );
        }
      }
    }

    return items;
  }

  // Serializes a single note to a JSON map
  Future<Map<String, dynamic>> _serializeNote(NoteExportItem item) async {
    final blocks = await blockRepo.getByNote(item.note.id);
    final serializedBlocks = <Map<String, dynamic>>[];

    for (final block in blocks) {
      final type = BlockType.fromDb(block.type);

      // Skip deprecated divider blocks
      if (type == BlockType.divider) continue;

      final blockMap = await _serializeBlock(block, type);
      if (blockMap != null) serializedBlocks.add(blockMap);
    }

    return {
      'format': _exportFormat,
      'schemaVersion': _exportSchemaVersion,
      'appVersion': '0.6.0',
      'notebook': {
        'name': item.notebook.name,
        'emoji': item.notebook.icon ?? '📓',
      },
      'section': {'name': item.section.name},
      'note': {
        'title': item.note.title,
        'colorTag': item.note.colorTag,
        'blocks': serializedBlocks,
      },
    };
  }

  Future<Map<String, dynamic>?> _serializeBlock(
    NoteBlock block,
    BlockType type,
  ) async {
    switch (type) {
      case BlockType.text:
      case BlockType.heading:
      case BlockType.quote:
      case BlockType.code:
        return {
          'type': type.dbValue,
          'text': NoteBlockModel.textFromJson(block.content),
        };

      case BlockType.checklist:
      case BlockType.numberedList:
      case BlockType.bulletList:
        final items = await blockRepo.getItems(block.id);
        return {
          'type': type.dbValue,
          'items': items
              .map((i) => {'content': i.content, 'checked': i.isChecked})
              .toList(),
        };

      case BlockType.drawing:
        final data = NoteBlockModel.drawingFromJson(block.content);
        return {
          'type': 'drawing',
          'version': data.version,
          'strokes': data.strokes
              .map(
                (s) => {
                  'color': s.color.toARGB32(),
                  'width': s.width,
                  'points': s.points.map((p) => [p.dx, p.dy]).toList(),
                },
              )
              .toList(),
        };

      case BlockType.table:
        final data = NoteBlockModel.tableFromJson(block.content);
        return {
          'type': 'table',
          'rows': data.rows,
          'cols': data.cols,
          'cells': data.cells,
        };

      case BlockType.divider:
        return null; // silently skip
    }
  }

  // Exports selected notes as a ZIP file and triggers share sheet
  Future<void> exportNotes({
    required List<NoteExportItem> items,
    required String zipName,
    required BuildContext context,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final archive = Archive();

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final json = await _serializeNote(item);
      final jsonBytes = utf8.encode(jsonEncode(json));
      final safeName = _safeFilename(item.note.title, i);
      archive.addFile(
        ArchiveFile('$safeName.json', jsonBytes.length, jsonBytes),
      );
    }

    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);

    final safeZipName = zipName.trim().isEmpty
        ? 'wasurenagusa_export'
        : zipName.trim();
    final zipFile = File('${tempDir.path}/$safeZipName.zip');
    await zipFile.writeAsBytes(zipBytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(zipFile.path)], text: 'Wasurenagusa export'),
    );
  }

  String _safeFilename(String title, int index) {
    final safe = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return safe.isEmpty ? 'note_$index' : '${safe}_$index';
  }
}

// ─────────────────────────────────────────────
// Import service
// ─────────────────────────────────────────────

class NoteImportService {
  final NoteRepository noteRepo;
  final NotebookRepository notebookRepo;
  final SectionRepository sectionRepo;
  final BlockRepository blockRepo;

  NoteImportService({
    required this.noteRepo,
    required this.notebookRepo,
    required this.sectionRepo,
    required this.blockRepo,
  });

  // Opens file picker and reads ZIP contents
  Future<NoteImportBundle?> pickAndReadZip() async {
    // 1. Use the new static method for single file picking
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (file == null) return null;

    // 2. Read bytes directly using the new PlatformFile method
    final bytes = await file.readAsBytes();
    final zipName = file.name;

    final archive = ZipDecoder().decodeBytes(bytes);
    final notes = <NoteImportEntry>[];

    for (final archiveFile in archive) {
      if (!archiveFile.name.endsWith('.json')) continue;
      final content = utf8.decode(archiveFile.content as List<int>);
      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        final entry = _parseEntry(json, archiveFile.name);
        if (entry != null) notes.add(entry);
      } catch (_) {
        // Skip malformed files silently
      }
    }

    return NoteImportBundle(zipName: zipName, entries: notes);
  }

  NoteImportEntry? _parseEntry(Map<String, dynamic> json, String filename) {
    if (json['format'] != _exportFormat) return null;

    final notebookMap = json['notebook'] as Map<String, dynamic>?;
    final sectionMap = json['section'] as Map<String, dynamic>?;
    final noteMap = json['note'] as Map<String, dynamic>?;

    if (notebookMap == null || sectionMap == null || noteMap == null) {
      return null;
    }

    return NoteImportEntry(
      filename: filename,
      notebookName: notebookMap['name'] as String? ?? 'Untitled notebook',
      notebookEmoji: notebookMap['emoji'] as String? ?? '📓',
      sectionName: sectionMap['name'] as String? ?? 'Untitled section',
      noteTitle: noteMap['title'] as String? ?? '',
      colorTag: noteMap['colorTag'] as String?,
      blocks: (noteMap['blocks'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
  }

  // Imports selected entries into the database
  Future<void> importEntries(List<NoteImportEntry> entries) async {
    for (final entry in entries) {
      // Find or create notebook
      final notebooks = await notebookRepo.watchAll().first;
      Notebook? notebook = notebooks
          .where((n) => n.name == entry.notebookName)
          .firstOrNull;

      if (notebook == null) {
        final id = await notebookRepo.create(
          name: entry.notebookName,
          icon: entry.notebookEmoji,
        );
        final updated = await notebookRepo.getById(id);
        if (updated == null) continue;
        notebook = updated;
      }

      // Find or create section
      final sections = await sectionRepo.getSectionsByNotebook(notebook.id);
      Section? section = sections
          .where((s) => s.name == entry.sectionName)
          .firstOrNull;

      if (section == null) {
        final id = await sectionRepo.create(
          notebookId: notebook.id,
          name: entry.sectionName,
        );
        final allSections = await sectionRepo.getSectionsByNotebook(
          notebook.id,
        );
        section = allSections.where((s) => s.id == id).firstOrNull;
        if (section == null) continue;
      }

      // Create note
      final noteId = await noteRepo.create(
        sectionId: section.id,
        title: entry.noteTitle,
        colorTag: entry.colorTag,
      );

      // Create blocks in order
      for (int i = 0; i < entry.blocks.length; i++) {
        await _importBlock(noteId, entry.blocks[i], i);
      }
    }
  }

  Future<void> _importBlock(
    int noteId,
    Map<String, dynamic> blockMap,
    int position,
  ) async {
    final typeStr = blockMap['type'] as String?;
    if (typeStr == null) return;

    // Skip legacy divider blocks in imported files
    if (typeStr == 'divider') return;

    final type = BlockType.fromDb(typeStr);

    switch (type) {
      case BlockType.text:
      case BlockType.heading:
      case BlockType.quote:
      case BlockType.code:
        final text = blockMap['text'] as String? ?? '';
        final content = jsonEncode({'text': text});
        await blockRepo.createBlock(
          noteId: noteId,
          type: type.dbValue,
          position: position,
          content: content,
        );
        break;

      case BlockType.checklist:
      case BlockType.numberedList:
      case BlockType.bulletList:
        final blockId = await blockRepo.createBlock(
          noteId: noteId,
          type: type.dbValue,
          position: position,
        );
        final items = (blockMap['items'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        for (int i = 0; i < items.length; i++) {
          await blockRepo.createItem(
            blockId: blockId,
            content: items[i]['content'] as String? ?? '',
            position: i,
            isChecked: items[i]['checked'] as bool? ?? false,
          );
        }
        break;

      case BlockType.drawing:
        final strokes = (blockMap['strokes'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final drawingMap = {
          'version': blockMap['version'] ?? 1,
          'strokes': strokes,
        };
        await blockRepo.createBlock(
          noteId: noteId,
          type: 'drawing',
          position: position,
          content: jsonEncode(drawingMap),
        );
        break;

      case BlockType.table:
        final tableMap = {
          'rows': blockMap['rows'],
          'cols': blockMap['cols'],
          'cells': blockMap['cells'],
        };
        await blockRepo.createBlock(
          noteId: noteId,
          type: 'table',
          position: position,
          content: jsonEncode(tableMap),
        );
        break;

      case BlockType.divider:
        break; // skip
    }
  }
}

// ─────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────

class NoteExportItem {
  final Note note;
  final Notebook notebook;
  final Section section;

  const NoteExportItem({
    required this.note,
    required this.notebook,
    required this.section,
  });
}

class NoteImportBundle {
  final String zipName;
  final List<NoteImportEntry> entries;

  const NoteImportBundle({required this.zipName, required this.entries});
}

class NoteImportEntry {
  final String filename;
  final String notebookName;
  final String notebookEmoji;
  final String sectionName;
  final String noteTitle;
  final String? colorTag;
  final List<Map<String, dynamic>> blocks;

  const NoteImportEntry({
    required this.filename,
    required this.notebookName,
    required this.notebookEmoji,
    required this.sectionName,
    required this.noteTitle,
    required this.colorTag,
    required this.blocks,
  });
}
