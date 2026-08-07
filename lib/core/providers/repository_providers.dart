import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../repositories/notebook_repository.dart';
import '../repositories/section_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/block_repository.dart';
import '../repositories/seiza_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return NotebookRepository(ref.watch(databaseProvider));
});

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  return SectionRepository(ref.watch(databaseProvider));
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(databaseProvider));
});

// Stream providers for reactive UI
final notebooksProvider = StreamProvider<List<Notebook>>((ref) {
  return ref.watch(notebookRepositoryProvider).watchAll();
});

final pinnedNotesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).watchPinned();
});

final recentNotesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).watchRecent();
});

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository(ref.watch(databaseProvider));
});

final seizaRepositoryProvider = Provider<SeizaRepository>((ref) {
  return SeizaRepository(ref.watch(databaseProvider));
});
