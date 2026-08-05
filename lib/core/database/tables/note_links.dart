import 'package:drift/drift.dart';
import 'notes.dart';

class NoteLinks extends Table {
  IntColumn get id => integer().autoIncrement()();

  @ReferenceName('outgoingLinks')
  IntColumn get sourceNoteId => integer().references(Notes, #id)();

  @ReferenceName('incomingLinks')
  IntColumn get targetNoteId => integer().references(Notes, #id)();

  TextColumn get label => text().nullable()();
  IntColumn get createdAt => integer()();
}
