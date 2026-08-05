import 'package:drift/drift.dart';
import 'notebooks.dart';

class Sections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notebookId => integer().references(Notebooks, #id)();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
