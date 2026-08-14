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
  table;

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
    'color': color.value,
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

  const NoteBlockModel({
    this.id,
    required this.noteId,
    required this.type,
    required this.position,
    this.textContent = '',
    this.items = const [],
    this.drawingData,
  });

  NoteBlockModel copyWith({
    int? id,
    int? noteId,
    BlockType? type,
    int? position,
    String? textContent,
    List<BlockItemModel>? items,
    DrawingData? drawingData,
  }) => NoteBlockModel(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    type: type ?? this.type,
    position: position ?? this.position,
    textContent: textContent ?? this.textContent,
    items: items ?? this.items,
    drawingData: drawingData ?? this.drawingData,
  );

  String? toJson() {
    if (type.hasTextContent) {
      return jsonEncode({'text': textContent});
    }
    if (type == BlockType.drawing) {
      return jsonEncode((drawingData ?? DrawingData.empty()).toMap());
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
      // Guard: only parse if it looks like drawing data
      if (!map.containsKey('strokes')) return DrawingData.empty();
      return DrawingData.fromMap(map);
    } catch (_) {
      return DrawingData.empty();
    }
  }
}
