import 'package:drift/drift.dart';
import 'note_blocks.dart';

class BlockItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId => integer().references(NoteBlocks, #id)();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
}
