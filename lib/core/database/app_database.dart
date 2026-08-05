import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/notebooks.dart';
import 'tables/sections.dart';
import 'tables/notes.dart';
import 'tables/note_blocks.dart';
import 'tables/block_items.dart';
import 'tables/tags.dart';
import 'tables/note_links.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Notebooks,
    Sections,
    Notes,
    NoteBlocks,
    BlockItems,
    Tags,
    NoteTags,
    NoteLinks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Future migrations go here
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wasurenagusa.db'));
    return NativeDatabase.createInBackground(file);
  });
}
