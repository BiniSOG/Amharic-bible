import 'file_store_memory.dart'
    if (dart.library.io) 'file_store_io.dart'
    as impl;

/// Small key → text file store used for downloaded Bibles and cached
/// commentary. Uses the app support directory on Android/iOS and memory on
/// the web preview.
abstract class FileStore {
  static final FileStore instance = impl.createStore();

  Future<String?> read(String name);
  Future<void> write(String name, String content);
  Future<void> delete(String name);
  Future<bool> exists(String name);
}
