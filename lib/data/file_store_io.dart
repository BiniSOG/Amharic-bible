import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_store.dart';

FileStore createStore() => _IoStore();

class _IoStore implements FileStore {
  Directory? _dir;

  Future<File> _file(String name) async {
    _dir ??= await getApplicationSupportDirectory();
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9_.\-/]'), '_');
    final f = File('${_dir!.path}/$safe');
    await f.parent.create(recursive: true);
    return f;
  }

  @override
  Future<String?> read(String name) async {
    final f = await _file(name);
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String name, String content) async {
    final f = await _file(name);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<bool> exists(String name) async => (await _file(name)).exists();
}
