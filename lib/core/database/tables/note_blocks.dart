import 'package:drift/drift.dart';
import 'notes.dart';

class NoteBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().references(Notes, #id)();
  TextColumn get type => text()();
  // v1:  'text', 'heading', 'checklist', 'numbered_list',
  //       'bullet_list', 'image', 'drawing', 'divider'
  // v2+: 'quote', 'code', 'table', 'callout', 'canvas'
  TextColumn get content => text().nullable()();
  IntColumn get position => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
