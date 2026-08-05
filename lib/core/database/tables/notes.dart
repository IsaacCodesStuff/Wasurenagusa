import 'package:drift/drift.dart';
import 'sections.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sectionId => integer().nullable().references(Sections, #id)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get colorTag => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
