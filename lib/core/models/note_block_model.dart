import 'dart:convert';

// Block types supported in v1
enum BlockType {
  text,
  heading,
  checklist,
  numberedList,
  bulletList,
  divider;

  String get dbValue => switch (this) {
    BlockType.text => 'text',
    BlockType.heading => 'heading',
    BlockType.checklist => 'checklist',
    BlockType.numberedList => 'numbered_list',
    BlockType.bulletList => 'bullet_list',
    BlockType.divider => 'divider',
  };

  static BlockType fromDb(String value) => switch (value) {
    'text' => BlockType.text,
    'heading' => BlockType.heading,
    'checklist' => BlockType.checklist,
    'numbered_list' => BlockType.numberedList,
    'bullet_list' => BlockType.bulletList,
    'divider' => BlockType.divider,
    _ => BlockType.text,
  };
}

// A checklist/list item
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

// The full block model used in the editor
class NoteBlockModel {
  final int? id;
  final int noteId;
  final BlockType type;
  final int position;

  // For text and heading blocks
  final String textContent;

  // For checklist, numbered list, bullet list
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

  // Serialize text content to JSON for storage
  String? toJson() {
    switch (type) {
      case BlockType.text:
      case BlockType.heading:
        return jsonEncode({'text': textContent});
      case BlockType.divider:
        return null;
      default:
        return null; // items stored in block_items table
    }
  }

  // Deserialize text content from JSON
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
