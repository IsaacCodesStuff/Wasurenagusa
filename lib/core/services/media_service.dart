import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  static MediaService? _instance;
  static MediaService get instance => _instance ??= MediaService._();
  MediaService._();

  Directory? _mediaDir;

  /// Returns the app media directory, creating it if it doesn't exist.
  Future<Directory> get mediaDirectory async {
    if (_mediaDir != null) return _mediaDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _mediaDir = dir;
    return dir;
  }

  /// Resolves a stored filename to its full filesystem path.
  Future<String> resolve(String filename) async {
    final dir = await mediaDirectory;
    return p.join(dir.path, filename);
  }

  /// Returns a File for the given stored filename.
  Future<File> fileFor(String filename) async {
    return File(await resolve(filename));
  }

  /// Copies [sourceFile] into the media directory with [filename].
  /// Returns the filename (not the full path).
  Future<String> copyInto(File sourceFile, String filename) async {
    final dir = await mediaDirectory;
    final dest = File(p.join(dir.path, filename));
    await sourceFile.copy(dest.path);
    return filename;
  }

  /// Deletes the media file with [filename] if it exists.
  Future<void> delete(String filename) async {
    final file = await fileFor(filename);
    if (await file.exists()) await file.delete();
  }
}
