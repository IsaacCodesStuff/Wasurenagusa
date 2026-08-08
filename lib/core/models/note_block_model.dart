import 'dart:convert';

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

class NoteBlockModel {
  final int? id;
  final int noteId;
  final BlockType type;
  final int position;
  final String textContent;
  final List<BlockItemModel> items;

  const NoteBlockModel({
    this.id,
    required this.noteId,
    required this.type,
    required this.position,
    this.textContent = '',
    this.items = const [],
  });

  NoteBlockModel copyWith({
    int? id,
    int? noteId,
    BlockType? type,
    int? position,
    String? textContent,
    List<BlockItemModel>? items,
  }) => NoteBlockModel(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    type: type ?? this.type,
    position: position ?? this.position,
    textContent: textContent ?? this.textContent,
    items: items ?? this.items,
  );

  String? toJson() {
    if (type.hasTextContent) {
      return jsonEncode({'text': textContent});
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
}
