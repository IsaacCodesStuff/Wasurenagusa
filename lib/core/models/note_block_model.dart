import 'dart:convert';
import 'dart:ui';

enum BlockType {
  text,
  heading,
  checklist,
  numberedList,
  bulletList,
  divider,
  quote,
  code,
  drawing,
  table,
  voice,
  image;

  String get dbValue => switch (this) {
    BlockType.text => 'text',
    BlockType.heading => 'heading',
    BlockType.checklist => 'checklist',
    BlockType.numberedList => 'numbered_list',
    BlockType.bulletList => 'bullet_list',
    BlockType.divider => 'divider',
    BlockType.quote => 'quote',
    BlockType.code => 'code',
    BlockType.drawing => 'drawing',
    BlockType.table => 'table',
    BlockType.voice => 'voice',
    BlockType.image => 'image',
  };

  static BlockType fromDb(String value) => switch (value) {
    'text' => BlockType.text,
    'heading' => BlockType.heading,
    'checklist' => BlockType.checklist,
    'numbered_list' => BlockType.numberedList,
    'bullet_list' => BlockType.bulletList,
    'divider' => BlockType.divider,
    'quote' => BlockType.quote,
    'code' => BlockType.code,
    'drawing' => BlockType.drawing,
    'table' => BlockType.table,
    'voice' => BlockType.voice,
    'image' => BlockType.image,
    _ => BlockType.text,
  };

  bool get hasTextContent => switch (this) {
    BlockType.text => true,
    BlockType.heading => true,
    BlockType.quote => true,
    BlockType.code => true,
    _ => false,
  };
}

// ─────────────────────────────────────────────
// Drawing data model
// ─────────────────────────────────────────────

class DrawingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  const DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });

  Map<String, dynamic> toMap() => {
    'color': color.toARGB32(),
    'width': width,
    'points': points.map((p) => [p.dx, p.dy]).toList(),
  };

  factory DrawingStroke.fromMap(Map<String, dynamic> map) => DrawingStroke(
    color: Color(map['color'] as int),
    width: (map['width'] as num).toDouble(),
    points: (map['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
  );
}

class DrawingData {
  static const int currentVersion = 1;

  final int version;
  final List<DrawingStroke> strokes;

  const DrawingData({this.version = currentVersion, required this.strokes});

  DrawingData copyWith({List<DrawingStroke>? strokes}) =>
      DrawingData(version: version, strokes: strokes ?? this.strokes);

  bool get isEmpty => strokes.isEmpty;

  Map<String, dynamic> toMap() => {
    'version': version,
    'strokes': strokes.map((s) => s.toMap()).toList(),
  };

  factory DrawingData.fromMap(Map<String, dynamic> map) => DrawingData(
    version: map['version'] as int? ?? 1,
    strokes: (map['strokes'] as List? ?? [])
        .map((s) => DrawingStroke.fromMap(s as Map<String, dynamic>))
        .toList(),
  );

  static DrawingData empty() => const DrawingData(strokes: []);
}

// ─────────────────────────────────────────────
// Table data model
// ─────────────────────────────────────────────

class TableData {
  final int rows;
  final int cols;
  final List<List<String>> cells;

  const TableData({
    required this.rows,
    required this.cols,
    required this.cells,
  });

  factory TableData.empty({int rows = 3, int cols = 3}) => TableData(
    rows: rows,
    cols: cols,
    cells: List.generate(rows, (_) => List.generate(cols, (_) => '')),
  );

  TableData copyWith({int? rows, int? cols, List<List<String>>? cells}) =>
      TableData(
        rows: rows ?? this.rows,
        cols: cols ?? this.cols,
        cells: cells ?? this.cells,
      );

  TableData withCell(int row, int col, String value) {
    final newCells = cells.map((r) => List<String>.from(r)).toList();
    newCells[row][col] = value;
    return copyWith(cells: newCells);
  }

  TableData addRow() {
    final newCells = cells.map((r) => List<String>.from(r)).toList()
      ..add(List.generate(cols, (_) => ''));
    return copyWith(rows: rows + 1, cells: newCells);
  }

  TableData addCol() {
    final newCells = cells.map((r) => List<String>.from(r)..add('')).toList();
    return copyWith(cols: cols + 1, cells: newCells);
  }

  TableData removeRow() {
    if (rows <= 1) return this;
    final newCells = cells.map((r) => List<String>.from(r)).toList()
      ..removeLast();
    return copyWith(rows: rows - 1, cells: newCells);
  }

  TableData removeCol() {
    if (cols <= 1) return this;
    final newCells = cells
        .map((r) => List<String>.from(r)..removeLast())
        .toList();
    return copyWith(cols: cols - 1, cells: newCells);
  }

  Map<String, dynamic> toMap() => {'rows': rows, 'cols': cols, 'cells': cells};

  factory TableData.fromMap(Map<String, dynamic> map) {
    final rows = map['rows'] as int;
    final cols = map['cols'] as int;
    final rawCells = map['cells'] as List;
    final cells = rawCells
        .map((row) => (row as List).map((c) => c as String).toList())
        .toList();
    return TableData(rows: rows, cols: cols, cells: cells);
  }
}

// ─────────────────────────────────────────────
// Voice data model
// ─────────────────────────────────────────────

class VoiceData {
  /// Filename only (e.g. "abc123.m4a") — resolved at runtime via MediaService.
  final String filename;

  /// Duration in milliseconds, recorded after the file is saved.
  final int? durationMs;

  const VoiceData({required this.filename, this.durationMs});

  Map<String, dynamic> toMap() => {
    'filePath': filename,
    if (durationMs != null) 'durationMs': durationMs,
  };

  factory VoiceData.fromMap(Map<String, dynamic> map) => VoiceData(
    filename: map['filePath'] as String,
    durationMs: map['durationMs'] as int?,
  );

  String get displayDuration {
    if (durationMs == null) return '';
    final total = durationMs! ~/ 1000;
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────
// Image data model
// ─────────────────────────────────────────────

class ImageData {
  /// Filename only (e.g. "abc123.jpg") — resolved at runtime via MediaService.
  final String filename;

  const ImageData({required this.filename});

  Map<String, dynamic> toMap() => {'filePath': filename};

  factory ImageData.fromMap(Map<String, dynamic> map) =>
      ImageData(filename: map['filePath'] as String);
}

// ─────────────────────────────────────────────
// Block item model
// ─────────────────────────────────────────────

class BlockItemModel {
  final int? id;
  final String content;
  final bool isChecked;
  final int position;

  const BlockItemModel({
    this.id,
    required this.content,
    this.isChecked = false,
    required this.position,
  });

  BlockItemModel copyWith({
    int? id,
    String? content,
    bool? isChecked,
    int? position,
  }) => BlockItemModel(
    id: id ?? this.id,
    content: content ?? this.content,
    isChecked: isChecked ?? this.isChecked,
    position: position ?? this.position,
  );
}

// ─────────────────────────────────────────────
// Note block model
// ─────────────────────────────────────────────

class NoteBlockModel {
  final int? id;
  final int noteId;
  final BlockType type;
  final int position;
  final String textContent;
  final List<BlockItemModel> items;
  final DrawingData? drawingData;
  final TableData? tableData;
  final VoiceData? voiceData;
  final ImageData? imageData;

  const NoteBlockModel({
    this.id,
    required this.noteId,
    required this.type,
    required this.position,
    this.textContent = '',
    this.items = const [],
    this.drawingData,
    this.tableData,
    this.voiceData,
    this.imageData,
  });

  NoteBlockModel copyWith({
    int? id,
    int? noteId,
    BlockType? type,
    int? position,
    String? textContent,
    List<BlockItemModel>? items,
    DrawingData? drawingData,
    TableData? tableData,
    VoiceData? voiceData,
    ImageData? imageData,
  }) => NoteBlockModel(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    type: type ?? this.type,
    position: position ?? this.position,
    textContent: textContent ?? this.textContent,
    items: items ?? this.items,
    drawingData: drawingData ?? this.drawingData,
    tableData: tableData ?? this.tableData,
    voiceData: voiceData ?? this.voiceData,
    imageData: imageData ?? this.imageData,
  );

  String? toJson() {
    if (type.hasTextContent) {
      return jsonEncode({'text': textContent});
    }
    if (type == BlockType.drawing) {
      return jsonEncode((drawingData ?? DrawingData.empty()).toMap());
    }
    if (type == BlockType.table) {
      return jsonEncode((tableData ?? TableData.empty()).toMap());
    }
    if (type == BlockType.voice && voiceData != null) {
      return jsonEncode(voiceData!.toMap());
    }
    if (type == BlockType.image && imageData != null) {
      return jsonEncode(imageData!.toMap());
    }
    return null;
  }

  static String textFromJson(String? json) {
    if (json == null) return '';
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['text'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  static DrawingData drawingFromJson(String? json) {
    if (json == null) return DrawingData.empty();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (!map.containsKey('strokes')) return DrawingData.empty();
      return DrawingData.fromMap(map);
    } catch (_) {
      return DrawingData.empty();
    }
  }

  static TableData tableFromJson(String? json) {
    if (json == null) return TableData.empty();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (!map.containsKey('cells')) return TableData.empty();
      return TableData.fromMap(map);
    } catch (_) {
      return TableData.empty();
    }
  }

  static VoiceData? voiceFromJson(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (!map.containsKey('filePath')) return null;
      return VoiceData.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static ImageData? imageFromJson(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (!map.containsKey('filePath')) return null;
      return ImageData.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}
