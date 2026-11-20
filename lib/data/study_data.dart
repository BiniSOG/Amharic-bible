import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/reference.dart';
import 'bible_repository.dart' show normalizeForSearch;

/// Treasury of Scripture Knowledge cross references (CC BY 4.0,
/// CrossReferences.org), keyed in KJV versification.
class CrossRefService extends ChangeNotifier {
  Map<String, String>? _map;
  Future<void>? _loading;

  Future<void> _ensure() => _loading ??= () async {
    final raw = await rootBundle.loadString('assets/data/crossrefs.json');
    _map = await compute(_decodeMap, raw);
    notifyListeners();
  }();

  bool get loaded => _map != null;

  Future<List<Passage>> forVerse(VerseRef r) async {
    await _ensure();
    final s = _map![r.key];
    if (s == null || s.isEmpty) return const [];
    return s.split(';').map(parseRefToken).whereType<Passage>().toList();
  }

  /// Number of references (0 if not loaded yet) – used for badges.
  int countFor(VerseRef r) {
    final s = _map?[r.key];
    if (s == null || s.isEmpty) return 0;
    return ';'.allMatches(s).length + 1;
  }

  void warmUp() => _ensure();
}

Map<String, String> _decodeMap(String raw) =>
    (jsonDecode(raw) as Map).cast<String, String>();

class DictionaryEntry {
  const DictionaryEntry(
    this.term,
    this.definition, {
    this.source = DictionarySource.easton,
    this.termAlt,
    this.refs = const [],
  });
  final String term;
  final String? termAlt;
  final String definition;
  final DictionarySource source;
  final List<String> refs;
}

enum DictionarySource { glossary, easton }

/// Easton's Bible Dictionary (public domain) + an Amharic/English glossary of
/// key biblical terms written for this app.
class DictionaryService {
  List<DictionaryEntry>? _entries;
  Future<void>? _loading;

  Future<List<DictionaryEntry>> all() async {
    await (_loading ??= _load());
    return _entries!;
  }

  Future<void> _load() async {
    final eastonRaw = await rootBundle.loadString('assets/data/eastons.json');
    final glossaryRaw = await rootBundle.loadString(
      'assets/data/glossary.json',
    );
    final easton = await compute(_decodeEaston, eastonRaw);
    final glossary = <DictionaryEntry>[
      for (final g in jsonDecode(glossaryRaw) as List)
        DictionaryEntry(
          '${g['am']}',
          '${g['def_am']}\n\n${g['def_en']}',
          termAlt: '${g['en']}',
          source: DictionarySource.glossary,
          refs: [for (final r in (g['refs'] as List? ?? const [])) '$r'],
        ),
    ];
    _entries = [...glossary, ...easton];
  }

  Future<List<DictionaryEntry>> search(
    String q, {
    DictionarySource? only,
  }) async {
    final list = await all();
    final query = normalizeForSearch(q.trim());
    Iterable<DictionaryEntry> src = only == null
        ? list
        : list.where((e) => e.source == only);
    if (query.isEmpty) return src.take(400).toList();
    final starts = <DictionaryEntry>[];
    final contains = <DictionaryEntry>[];
    final inDef = <DictionaryEntry>[];
    for (final e in src) {
      final t = normalizeForSearch(e.term);
      final a = normalizeForSearch(e.termAlt ?? '');
      if (t.startsWith(query) || a.startsWith(query)) {
        starts.add(e);
      } else if (t.contains(query) || a.contains(query)) {
        contains.add(e);
      } else if (query.length > 3 &&
          inDef.length < 60 &&
          normalizeForSearch(e.definition).contains(query)) {
        inDef.add(e);
      }
    }
    return [...starts, ...contains, ...inDef].take(300).toList();
  }

  /// Best match for a single word (used from the verse action sheet).
  Future<DictionaryEntry?> lookup(String word) async {
    final r = await search(word);
    return r.isEmpty ? null : r.first;
  }
}

List<DictionaryEntry> _decodeEaston(String raw) => [
  for (final e in jsonDecode(raw) as List)
    DictionaryEntry('${e[0]}', '${e[1]}'),
];
