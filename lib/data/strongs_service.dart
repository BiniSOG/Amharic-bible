import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/reference.dart';
import 'bible.dart';
import 'bible_repository.dart';

/// One entry of Strong's Hebrew/Greek dictionary (1890, public domain;
/// JSON by Open Scriptures, CC BY-SA).
class StrongsEntry {
  const StrongsEntry({
    required this.number,
    required this.lemma,
    required this.translit,
    required this.pron,
    required this.derivation,
    required this.definition,
    required this.kjvUsage,
  });

  final String number;
  final String lemma;
  final String translit;
  final String pron;
  final String derivation;
  final String definition;
  final String kjvUsage;

  bool get isGreek => number.startsWith('G');
}

class StrongsService {
  StrongsService(this._repo);
  final BibleRepository _repo;

  Map<String, dynamic>? _greek;
  Map<String, dynamic>? _hebrew;
  Map<String, int>? _counts;

  static const taggedVersion = 'KJVS';

  /// Normalises user input such as "g2532", "G02532" or "H 1254".
  static String? normalize(String raw) {
    final m = RegExp(r'^\s*([GgHh])\s*0*(\d{1,5})\s*$').firstMatch(raw);
    if (m == null) return null;
    return '${m.group(1)!.toUpperCase()}${m.group(2)}';
  }

  Future<StrongsEntry?> lookup(String number) async {
    final n = normalize(number);
    if (n == null) return null;
    final isGreek = n.startsWith('G');
    if (isGreek) {
      _greek ??= await _load('assets/data/strongs_greek.json');
    } else {
      _hebrew ??= await _load('assets/data/strongs_hebrew.json');
    }
    final row = (isGreek ? _greek : _hebrew)![n] as List?;
    if (row == null) return null;
    return StrongsEntry(
      number: n,
      lemma: '${row[0]}',
      translit: '${row[1]}',
      pron: '${row[2]}',
      derivation: '${row[3]}'.trim(),
      definition: '${row[4]}'.trim(),
      kjvUsage: '${row[5]}'.trim(),
    );
  }

  static Future<Map<String, dynamic>> _load(String asset) async {
    final raw = await rootBundle.loadString(asset);
    return compute(_decode, raw);
  }

  Future<Bible> taggedBible() => _repo.load(taggedVersion);

  /// How many times each number occurs in the tagged KJV.
  Future<int> occurrences(String number) async {
    if (_counts == null) {
      final b = await taggedBible();
      _counts = await compute(_countTags, b.tagged ?? const []);
    }
    return _counts![normalize(number)] ?? 0;
  }

  /// All verses that contain [number].
  Future<List<SearchHit>> versesWith(String number, {int limit = 1000}) async {
    final n = normalize(number);
    if (n == null) return const [];
    final b = await taggedBible();
    return compute(_findTag, (b.tagged ?? const [], b.books, '[$n]', limit));
  }
}

Map<String, dynamic> _decode(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

Map<String, int> _countTags(List<List<List<String>>> books) {
  final out = <String, int>{};
  for (final b in books) {
    for (final c in b) {
      for (final v in c) {
        for (final m in kStrongsTag.allMatches(v)) {
          final k = m.group(1)!;
          out[k] = (out[k] ?? 0) + 1;
        }
      }
    }
  }
  return out;
}

List<SearchHit> _findTag(
  (List<List<List<String>>>, List<List<List<String>>>, String, int) a,
) {
  final (tagged, plain, tag, limit) = a;
  final hits = <SearchHit>[];
  for (var b = 0; b < tagged.length; b++) {
    for (var c = 0; c < tagged[b].length; c++) {
      for (var v = 0; v < tagged[b][c].length; v++) {
        if (tagged[b][c][v].contains(tag)) {
          hits.add(SearchHit(b + 1, c + 1, v + 1, plain[b][c][v]));
          if (hits.length >= limit) return hits;
        }
      }
    }
  }
  return hits;
}

/// Splits tagged text into (text, strongsNumbers) pieces for rendering.
List<(String, List<String>)> splitTagged(String tagged) {
  final out = <(String, List<String>)>[];
  final re = RegExp(r'([^\[]*?)((?:\[[GH]\d+\])+)');
  var last = 0;
  for (final m in re.allMatches(tagged)) {
    final nums = [
      for (final t in kStrongsTag.allMatches(m.group(2)!)) t.group(1)!,
    ];
    out.add((m.group(1)!, nums));
    last = m.end;
  }
  if (last < tagged.length) out.add((tagged.substring(last), const []));
  return out;
}

/// Verse reference helper for the "find all" list.
VerseRef hitRef(SearchHit h) => VerseRef(h.book, h.chapter, h.verse);
