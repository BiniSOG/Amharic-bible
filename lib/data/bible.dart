import 'dart:convert';

import '../core/books.dart';
import '../core/reference.dart';

/// An in-memory Bible translation in canonical 66-book order.
///
/// `books[b][c][v]` – 0-based indices. An empty string means the verse is
/// absent in this translation or merged into the previous verse
/// (e.g. Amharic "2-3").
class Bible {
  Bible({
    required this.id,
    required this.abbr,
    required this.name,
    required this.lang,
    required this.books,
    this.tagged,
  });

  final String id;
  final String abbr;
  final String name;
  final String lang;
  final List<List<List<String>>> books;

  /// Same shape as [books] but with Strong's tags (`word[G2532]`), for
  /// tagged versions such as "KJV with Strong's". [books] holds plain text.
  final List<List<List<String>>>? tagged;

  bool get hasStrongs => tagged != null;

  String taggedVerse(int book, int chapter, int verse) {
    final t = tagged;
    if (t == null) return this.verse(book, chapter, verse);
    if (book < 1 || book > t.length) return '';
    final b = t[book - 1];
    if (chapter < 1 || chapter > b.length) return '';
    final c = b[chapter - 1];
    return verse < 1 || verse > c.length ? '' : c[verse - 1];
  }

  bool get isEthiopic => lang == 'am' || lang == 'gez';

  List<String> chapter(int book, int chapter) {
    if (book < 1 || book > books.length) return const [];
    final b = books[book - 1];
    if (chapter < 1 || chapter > b.length) return const [];
    return b[chapter - 1];
  }

  String verse(int book, int chapter, int verse) {
    final c = this.chapter(book, chapter);
    if (verse < 1 || verse > c.length) return '';
    return c[verse - 1];
  }

  bool hasChapter(int book, int chapter) =>
      this.chapter(book, chapter).any((v) => v.isNotEmpty);

  /// Text for a verse, following a merged range backwards if needed, so that
  /// e.g. Amharic Genesis 7:3 returns the text of the combined 7:2-3.
  String verseOrMerged(int book, int chapter, int verse) {
    final c = this.chapter(book, chapter);
    if (c.isEmpty) return '';
    for (var v = verse.clamp(1, c.length); v >= 1; v--) {
      final t = c[v - 1];
      if (t.isNotEmpty) return t;
      if (verse - v > 4) break;
    }
    return '';
  }

  String passageText(Passage p) {
    final out = StringBuffer();
    for (final ch in p.chapters) {
      final c = chapter(p.book, ch);
      final from = (ch == p.chapter ? (p.fromVerse ?? 1) : 1);
      final to = (p.toChapter == null && p.toVerse != null)
          ? p.toVerse!
          : c.length;
      for (var v = from; v <= to && v <= c.length; v++) {
        final t = c[v - 1];
        if (t.isEmpty) continue;
        if (out.isNotEmpty) out.write(' ');
        out.write(t);
      }
    }
    return out.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'abbr': abbr,
    'name': name,
    'lang': lang,
    'books': tagged ?? books,
  };

  /// Fast path for the compact format we bundle/save.
  static Bible fromCompact(Map<String, dynamic> j) {
    final raw = [
      for (final b in (j['books'] as List))
        [
          for (final c in (b as List))
            [for (final v in (c as List)) v as String],
        ],
    ];
    final isTagged =
        raw.isNotEmpty &&
        raw.first.isNotEmpty &&
        raw.first.first.isNotEmpty &&
        kStrongsTag.hasMatch(raw.first.first.first);
    return Bible(
      id: j['id'] as String,
      abbr: j['abbr'] as String? ?? j['id'] as String,
      name: j['name'] as String? ?? j['id'] as String,
      lang: j['lang'] as String? ?? 'en',
      books: isTagged
          ? [
              for (final b in raw)
                [
                  for (final c in b) [for (final v in c) stripStrongs(v)],
                ],
            ]
          : raw,
      tagged: isTagged ? raw : null,
    );
  }
}

/// Matches a Strong's tag such as `[G2532]` or `[H1254]`.
final RegExp kStrongsTag = RegExp(r'\[([GH]\d+)\]');

String stripStrongs(String s) =>
    s.replaceAll(kStrongsTag, '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Parses Bible JSON in any of the supported shapes:
///  * compact  `{books: [[["v1", ...], ...], ...]}` (this app)
///  * scrollmapper `{books:[{name, chapters:[{chapter, verses:[{verse,text}]}]}]}`
///  * thiagobodruk `[{abbrev, chapters:[["v1",...]]}]`
///  * HelloAO complete `{books:[{id:'GEN', chapters:[{chapter:{number, content:[...]}}]}]}`
///  * flat verse list `[{book|book_id, chapter, verse, text}]`
/// Runs inside an isolate (see `compute`).
Bible parseAnyBible(Map<String, String> args) {
  final raw = args['body']!;
  final id = args['id']!;
  final abbr = args['abbr'] ?? id;
  final name = args['name'] ?? id;
  final lang = args['lang'] ?? 'en';
  final decoded = jsonDecode(raw);

  final books = List.generate(
    66,
    (i) => List.generate(kBooks[i].chapters, (_) => <String>[]),
  );

  void put(int b, int c, int v, String text) {
    if (b < 1 || b > 66 || c < 1 || v < 1) return;
    final bk = books[b - 1];
    while (bk.length < c) {
      bk.add(<String>[]);
    }
    final ch = bk[c - 1];
    while (ch.length < v) {
      ch.add('');
    }
    ch[v - 1] = _cleanVerse(text);
  }

  if (decoded is Map && decoded['books'] is List) {
    final list = decoded['books'] as List;
    if (list.isNotEmpty && list.first is List) {
      return Bible.fromCompact({
        ...Map<String, dynamic>.from(decoded),
        'id': id,
        'abbr': abbr,
        'name': name,
        'lang': lang,
      });
    }
    var order = 0;
    for (final bk in list) {
      order++;
      if (bk is! Map) continue;
      final bi = _bookIndexFor(bk, order);
      if (bi == null) continue;
      final chapters = bk['chapters'] as List? ?? const [];
      var cOrder = 0;
      for (final ch in chapters) {
        cOrder++;
        if (ch is List) {
          // [ "v1", "v2" ]
          for (var v = 0; v < ch.length; v++) {
            put(bi, cOrder, v + 1, '${ch[v]}');
          }
        } else if (ch is Map && ch['verses'] is List) {
          final cn = _int(ch['chapter']) ?? cOrder;
          var vOrder = 0;
          for (final v in ch['verses'] as List) {
            vOrder++;
            if (v is Map) {
              put(bi, cn, _int(v['verse']) ?? vOrder, '${v['text'] ?? ''}');
            } else {
              put(bi, cn, vOrder, '$v');
            }
          }
        } else if (ch is Map && ch['chapter'] is Map) {
          // HelloAO
          final inner = ch['chapter'] as Map;
          final cn = _int(inner['number']) ?? cOrder;
          for (final item in (inner['content'] as List? ?? const [])) {
            if (item is Map && item['type'] == 'verse') {
              put(
                bi,
                cn,
                _int(item['number']) ?? 0,
                _flattenHelloAo(item['content']),
              );
            }
          }
        }
      }
    }
  } else if (decoded is List) {
    var order = 0;
    for (final bk in decoded) {
      order++;
      if (bk is Map && bk['chapters'] is List) {
        final bi = _bookIndexFor(bk, order);
        if (bi == null) continue;
        final chs = bk['chapters'] as List;
        for (var c = 0; c < chs.length; c++) {
          final vs = chs[c] as List;
          for (var v = 0; v < vs.length; v++) {
            put(bi, c + 1, v + 1, '${vs[v]}');
          }
        }
      } else if (bk is Map && bk['text'] != null) {
        final b =
            _int(bk['book_id'] ?? bk['book']) ??
            findBookByName('${bk['book_name'] ?? bk['book']}')?.index;
        if (b == null) continue;
        put(
          b,
          _int(bk['chapter']) ?? 0,
          _int(bk['verse']) ?? 0,
          '${bk['text']}',
        );
      }
    }
  } else {
    throw const FormatException('Unrecognised Bible format');
  }

  // trim trailing empty chapters/verses
  final nonEmpty = books.fold<int>(
    0,
    (s, b) =>
        s + b.fold<int>(0, (t, c) => t + c.where((v) => v.isNotEmpty).length),
  );
  if (nonEmpty == 0) throw const FormatException('No verses found');
  return Bible(id: id, abbr: abbr, name: name, lang: lang, books: books);
}

int? _int(Object? o) => o is int ? o : int.tryParse('$o');

int? _bookIndexFor(Map bk, int order) {
  final idField = bk['id'] ?? bk['usfm'];
  if (idField is String) {
    final i = kBooks.indexWhere((b) => b.usfm == idField.toUpperCase());
    if (i >= 0) return i + 1;
  }
  final name = bk['name'] ?? bk['commonName'] ?? bk['book'] ?? bk['abbrev'];
  if (name is String) {
    var n = name;
    if (n == 'Revelation of John') n = 'Revelation';
    final roman = RegExp(r'^(I{1,3}) ').firstMatch(n);
    if (roman != null) {
      n = '${roman.group(1)!.length} ${n.substring(roman.end)}';
    }
    final found = findBookByName(n);
    if (found != null) return found.index;
  }
  // 66-book lists without recognisable names: trust the order.
  return order <= 66 && name == null ? order : null;
}

String _flattenHelloAo(Object? content) {
  final b = StringBuffer();
  void walk(Object? o) {
    if (o is String) {
      if (b.isNotEmpty && !b.toString().endsWith(' ')) b.write(' ');
      b.write(o);
    } else if (o is List) {
      o.forEach(walk);
    } else if (o is Map) {
      if (o['text'] != null) walk(o['text']);
      if (o['content'] != null) walk(o['content']);
    }
  }

  walk(content);
  return b.toString();
}

final _tagRe = RegExp(r'<[^>]*>');
final _wsRe = RegExp(r'\s+');
final _strongsRe = RegExp(r'\{[^}]*\}');

final _cjkGap = RegExp(
  r'(?<=[\u3000-\u303f\u4e00-\u9fff\uff00-\uffef])\s+(?=[\u3000-\u303f\u4e00-\u9fff\uff00-\uffef])',
);

String _cleanVerse(String s) => _cleanVerseRaw(s).replaceAll(_cjkGap, '');

String _cleanVerseRaw(String s) => s
    .replaceAll(_tagRe, '')
    .replaceAll(_strongsRe, '')
    .replaceAll('¶', '')
    .replaceAll(_wsRe, ' ')
    .trim();
