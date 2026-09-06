import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../repositories/block_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/notebook_repository.dart';
import '../repositories/section_repository.dart';
import '../models/note_block_model.dart';
import '../services/media_service.dart';

const int _exportSchemaVersion = 2;
const String _exportFormat = 'wasurenagusa';
const String _appVersion = '0.7.0';
const _uuid = Uuid();

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

  Future<Map<String, dynamic>> _serializeNote(
    NoteExportItem item,
    List<_MediaEntry> mediaCollector,
  ) async {
    final blocks = await blockRepo.getByNote(item.note.id);
    final serializedBlocks = <Map<String, dynamic>>[];

    for (final block in blocks) {
      final type = BlockType.fromDb(block.type);
      if (type == BlockType.divider) continue;

      final blockMap = await _serializeBlock(block, type, mediaCollector);
      if (blockMap != null) serializedBlocks.add(blockMap);
    }

    return {
      'id': _uuid.v4(),
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
    List<_MediaEntry> mediaCollector,
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

      case BlockType.voice:
        final voiceData = NoteBlockModel.voiceFromJson(block.content);
        if (voiceData == null) return null;
        final mediaId = _uuid.v4();
        final filePath = await MediaService.instance.resolve(
          voiceData.filename,
        );
        mediaCollector.add(
          _MediaEntry(filePath: filePath, mediaId: mediaId, extension: 'm4a'),
        );
        return {
          'type': 'voice',
          'mediaId': mediaId,
          'originalFilename': voiceData.filename,
          'mimeType': 'audio/m4a',
          if (voiceData.durationMs != null) 'durationMs': voiceData.durationMs,
        };

      case BlockType.image:
        final imageData = NoteBlockModel.imageFromJson(block.content);
        if (imageData == null) return null;
        final mediaId = _uuid.v4();
        final filePath = await MediaService.instance.resolve(
          imageData.filename,
        );
        final ext = imageData.filename.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        mediaCollector.add(
          _MediaEntry(filePath: filePath, mediaId: mediaId, extension: ext),
        );
        return {
          'type': 'image',
          'mediaId': mediaId,
          'originalFilename': imageData.filename,
          'mimeType': mimeType,
        };

      case BlockType.divider:
        return null;
    }
  }

  Future<ExportResult> exportNotes({
    required List<NoteExportItem> items,
    required String zipName,
    required BuildContext context,
  }) async {
    final mediaCollector = <_MediaEntry>[];
    final archive = Archive();

    // 1. Serialize notes into notes/<uuid>.json
    for (final item in items) {
      final noteMap = await _serializeNote(item, mediaCollector);
      final noteBytes = utf8.encode(jsonEncode(noteMap));
      final noteId = noteMap['id'] as String;
      archive.addFile(
        ArchiveFile('notes/$noteId.json', noteBytes.length, noteBytes),
      );
    }

    // 2. Bundle media files into media/<uuid>.<ext>
    for (final entry in mediaCollector) {
      final file = File(entry.filePath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(
          'media/${entry.mediaId}.${entry.extension}',
          bytes.length,
          bytes,
        ),
      );
    }

    // 3. Build manifest.json
    final manifest = {
      'format': _exportFormat,
      'schemaVersion': _exportSchemaVersion,
      'appVersion': _appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'noteCount': items.length,
      'mediaCount': mediaCollector.length,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    // 4. Encode ZIP in memory
    final zipBytes = ZipEncoder().encode(archive);

    // 5. SAF save picker — user chooses destination
    final safeZipName = zipName.trim().isEmpty
        ? 'wasurenagusa_export'
        : zipName.trim().replaceAll(RegExp(r'[^\w\s\-]'), '').trim();

    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Save Wasurenagusa export',
      fileName: '$safeZipName.zip',
      bytes: Uint8List.fromList(zipBytes),
    );

    if (savePath == null) return ExportResult.cancelled();

    final String destPath;
    if (Platform.isAndroid) {
      destPath = savePath.toString();
    } else {
      destPath = savePath.toFilePath();
      final dest = File(destPath);
      if (!await dest.exists() || await dest.length() == 0) {
        await dest.writeAsBytes(zipBytes);
      }
    }

    return ExportResult.success(destPath);
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

  Future<NoteImportBundle?> pickAndReadZip() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final zipName = file.name;

    late Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return NoteImportBundle.invalid(zipName: zipName);
    }

    // ── Determine schema version via manifest.json ────────────────────
    final manifestFile = archive.findFile('manifest.json');
    int schemaVersion = 1;

    if (manifestFile != null) {
      try {
        final manifestJson =
            jsonDecode(utf8.decode(manifestFile.content as List<int>))
                as Map<String, dynamic>;

        if (manifestJson['format'] != _exportFormat) {
          return NoteImportBundle.invalid(zipName: zipName);
        }

        schemaVersion = manifestJson['schemaVersion'] as int? ?? 1;

        final manifestNoteCount = manifestJson['noteCount'] as int?;
        final manifestMediaCount = manifestJson['mediaCount'] as int?;
        final actualNoteCount = archive.files
            .where((f) => f.name.startsWith('notes/'))
            .length;
        final actualMediaCount = archive.files
            .where((f) => f.name.startsWith('media/'))
            .length;

        if (manifestNoteCount != null && manifestNoteCount != actualNoteCount) {
          debugPrint(
            '[Import] Note count mismatch: manifest=$manifestNoteCount, actual=$actualNoteCount',
          );
        }
        if (manifestMediaCount != null &&
            manifestMediaCount != actualMediaCount) {
          debugPrint(
            '[Import] Media count mismatch: manifest=$manifestMediaCount, actual=$actualMediaCount',
          );
        }
      } catch (_) {
        return NoteImportBundle.invalid(zipName: zipName);
      }
    }

    // ── Parse notes ───────────────────────────────────────────────────
    final notes = <NoteImportEntry>[];

    if (schemaVersion >= 2) {
      for (final archiveFile in archive.files) {
        if (!archiveFile.name.startsWith('notes/') ||
            !archiveFile.name.endsWith('.json')) {
          continue;
        }
        try {
          final content = utf8.decode(archiveFile.content as List<int>);
          final json = jsonDecode(content) as Map<String, dynamic>;
          final entry = _parseEntryV2(json, archiveFile.name);
          if (entry != null) notes.add(entry);
        } catch (_) {}
      }
    } else {
      for (final archiveFile in archive.files) {
        if (archiveFile.isFile != true) continue;
        if (!archiveFile.name.endsWith('.json')) continue;
        if (archiveFile.name.contains('/')) continue;
        try {
          final content = utf8.decode(archiveFile.content as List<int>);
          final json = jsonDecode(content) as Map<String, dynamic>;
          final entry = _parseEntryV1(json, archiveFile.name);
          if (entry != null) notes.add(entry);
        } catch (_) {}
      }
    }

    // ── Extract media files into temp dir keyed by mediaId ────────────
    final mediaTempPaths = <String, String>{};

    if (schemaVersion >= 2) {
      final tempDir = await getTemporaryDirectory();
      for (final archiveFile in archive.files) {
        if (!archiveFile.name.startsWith('media/')) continue;
        final filename = archiveFile.name.split('/').last;
        // filename is <mediaId>.<ext>
        final dotIndex = filename.lastIndexOf('.');
        if (dotIndex == -1) continue;
        final mediaId = filename.substring(0, dotIndex);
        final tempPath = '${tempDir.path}/$filename';
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(archiveFile.content as List<int>);
        mediaTempPaths[mediaId] = tempPath;
      }
    }

    return NoteImportBundle(
      zipName: zipName,
      entries: notes,
      schemaVersion: schemaVersion,
      mediaTempPaths: mediaTempPaths,
    );
  }

  NoteImportEntry? _parseEntryV2(Map<String, dynamic> json, String filename) {
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

  NoteImportEntry? _parseEntryV1(Map<String, dynamic> json, String filename) {
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

  Future<void> importEntries(
    List<NoteImportEntry> entries, {
    Map<String, String> mediaTempPaths = const {},
  }) async {
    for (final entry in entries) {
      final notebooks = await notebookRepo.watchAll().first;
      Notebook? notebook = notebooks
          .where((n) => n.name == entry.notebookName)
          .firstOrNull;

      if (notebook == null) {
        final id = await notebookRepo.create(
          name: entry.notebookName,
          icon: entry.notebookEmoji,
        );
        notebook = await notebookRepo.getById(id);
        if (notebook == null) continue;
      }

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

      final noteId = await noteRepo.create(
        sectionId: section.id,
        title: entry.noteTitle,
        colorTag: entry.colorTag,
      );

      for (int i = 0; i < entry.blocks.length; i++) {
        await _importBlock(
          noteId,
          entry.blocks[i],
          i,
          mediaTempPaths: mediaTempPaths,
        );
      }
    }
  }

  Future<void> _importBlock(
    int noteId,
    Map<String, dynamic> blockMap,
    int position, {
    Map<String, String> mediaTempPaths = const {},
  }) async {
    final typeStr = blockMap['type'] as String?;
    if (typeStr == null) return;
    if (typeStr == 'divider') return;

    final type = BlockType.fromDb(typeStr);

    switch (type) {
      case BlockType.text:
      case BlockType.heading:
      case BlockType.quote:
      case BlockType.code:
        await blockRepo.createBlock(
          noteId: noteId,
          type: type.dbValue,
          position: position,
          content: jsonEncode({'text': blockMap['text'] as String? ?? ''}),
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
        await blockRepo.createBlock(
          noteId: noteId,
          type: 'drawing',
          position: position,
          content: jsonEncode({
            'version': blockMap['version'] ?? 1,
            'strokes': strokes,
          }),
        );
        break;

      case BlockType.table:
        await blockRepo.createBlock(
          noteId: noteId,
          type: 'table',
          position: position,
          content: jsonEncode({
            'rows': blockMap['rows'],
            'cols': blockMap['cols'],
            'cells': blockMap['cells'],
          }),
        );
        break;

      case BlockType.voice:
        final mediaId = blockMap['mediaId'] as String?;
        if (mediaId == null) break;
        final tempPath = mediaTempPaths[mediaId];
        if (tempPath == null) break;

        final filename = '${_uuid.v4()}.m4a';
        await MediaService.instance.copyInto(File(tempPath), filename);

        // Clean up temp file
        final tf = File(tempPath);
        if (await tf.exists()) await tf.delete();

        await blockRepo.createBlock(
          noteId: noteId,
          type: 'voice',
          position: position,
          content: jsonEncode({
            'filePath': filename,
            if (blockMap['durationMs'] != null)
              'durationMs': blockMap['durationMs'],
          }),
        );
        break;

      case BlockType.image:
        final mediaId = blockMap['mediaId'] as String?;
        if (mediaId == null) break;
        final tempPath = mediaTempPaths[mediaId];
        if (tempPath == null) break;

        final mimeType = blockMap['mimeType'] as String? ?? 'image/jpeg';
        final ext = mimeType == 'image/png' ? 'png' : 'jpg';
        final filename = '${_uuid.v4()}.$ext';
        await MediaService.instance.copyInto(File(tempPath), filename);

        // Clean up temp file
        final tf = File(tempPath);
        if (await tf.exists()) await tf.delete();

        await blockRepo.createBlock(
          noteId: noteId,
          type: 'image',
          position: position,
          content: jsonEncode({'filePath': filename}),
        );
        break;

      case BlockType.divider:
        break;
    }
  }
}

// ─────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────

class _MediaEntry {
  final String filePath;
  final String mediaId;
  final String extension;

  const _MediaEntry({
    required this.filePath,
    required this.mediaId,
    required this.extension,
  });
}

// ─────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────

enum ExportStatus { success, cancelled, failure }

class ExportResult {
  final ExportStatus status;
  final String? path;
  final String? errorMessage;

  const ExportResult._({required this.status, this.path, this.errorMessage});

  factory ExportResult.success(String path) =>
      ExportResult._(status: ExportStatus.success, path: path);

  factory ExportResult.cancelled() =>
      ExportResult._(status: ExportStatus.cancelled);

  factory ExportResult.failure(String message) =>
      ExportResult._(status: ExportStatus.failure, errorMessage: message);
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
  final int schemaVersion;
  final bool isInvalid;
  final Map<String, String> mediaTempPaths;

  const NoteImportBundle({
    required this.zipName,
    required this.entries,
    required this.schemaVersion,
    this.isInvalid = false,
    this.mediaTempPaths = const {},
  });

  factory NoteImportBundle.invalid({required String zipName}) =>
      NoteImportBundle(
        zipName: zipName,
        entries: [],
        schemaVersion: 0,
        isInvalid: true,
      );
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
