import 'file_store.dart';

FileStore createStore() => _MemoryStore();

class _MemoryStore implements FileStore {
  final _m = <String, String>{};
  @override
  Future<String?> read(String name) async => _m[name];
  @override
  Future<void> write(String name, String content) async => _m[name] = content;
  @override
  Future<void> delete(String name) async => _m.remove(name);
  @override
  Future<bool> exists(String name) async => _m.containsKey(name);
}
