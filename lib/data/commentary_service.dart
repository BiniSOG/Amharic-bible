import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../core/books.dart';
import 'file_store.dart';

enum CommentaryKind { chapterMarkdown, verseJson }

class CommentarySource {
  const CommentarySource({
    required this.id,
    required this.name,
    required this.author,
    required this.kind,
    required this.urlFor,
    this.year = '',
    this.coversBook,
    this.bundled = false,
  });

  /// Shipped with the app (works offline).
  final bool bundled;

  final String id;
  final String name;
  final String author;
  final String year;
  final CommentaryKind kind;
  final String Function(BibleBook book, int chapter) urlFor;
  final bool Function(BibleBook book)? coversBook;

  bool covers(BibleBook b) => coversBook?.call(b) ?? true;
}

/// One block of commentary covering verses [startVerse]..[endVerse].
class CommentaryBlock {
  const CommentaryBlock(this.startVerse, this.endVerse, this.title, this.body);
  final int startVerse;
  final int endVerse;
  final String title;

  /// Light markdown (headings, **bold**, *italic*, > quotes).
  final String body;

  bool covers(int verse) => verse >= startVerse && verse <= endVerse;
}

class CommentaryChapter {
  const CommentaryChapter(this.intro, this.blocks);
  final String intro;
  final List<CommentaryBlock> blocks;

  bool get isEmpty => intro.trim().isEmpty && blocks.isEmpty;

  /// Blocks relevant for [verse]: those whose range covers it, or the last
  /// block that starts before it (commentaries often comment on a section
  /// once, under its first verse).
  List<CommentaryBlock> forVerse(int verse) {
    final direct = blocks.where((b) => b.covers(verse)).toList();
    if (direct.isNotEmpty) return direct;
    CommentaryBlock? last;
    for (final b in blocks) {
      if (b.startVerse <= verse) last = b;
    }
    return last == null ? const [] : [last];
  }
}

const _pillar =
    'https://raw.githubusercontent.com/thefrenchpressed/pillar-commentary-data/main/c';
const _mh = 'https://raw.githubusercontent.com/lyteword/mhenry-complete/main';

final List<CommentarySource> kCommentarySources = [
  CommentarySource(
    id: 'mhc',
    name: 'Matthew Henry\'s Complete Commentary',
    author: 'Matthew Henry',
    year: '1706',
    kind: CommentaryKind.chapterMarkdown,
    urlFor: (b, c) => b.index == 19
        ? '$_mh/${b.mhVolume}/psalms/psalm-$c.md'
        : '$_mh/${b.mhVolume}/${b.mhSlug}/chapter-$c.md',
  ),
  CommentarySource(
    id: 'calvin',
    name: 'Calvin\'s Commentaries',
    author: 'John Calvin',
    year: '1550s',
    kind: CommentaryKind.verseJson,
    urlFor: (b, c) => '$_pillar/calvin/${b.usfm}/$c.json',
  ),
  CommentarySource(
    id: 'scofield',
    name: 'Scofield Reference Notes (offline)',
    author: 'C. I. Scofield',
    year: '1917',
    bundled: true,
    kind: CommentaryKind.verseJson,
    urlFor: (b, c) => '$_pillar/scofield/${b.usfm}/$c.json',
  ),
  CommentarySource(
    id: 'gaebelein',
    name: 'Gaebelein\'s Annotated Bible',
    author: 'Arno C. Gaebelein',
    year: '1913',
    kind: CommentaryKind.verseJson,
    urlFor: (b, c) => '$_pillar/gaebelein/${b.usfm}/$c.json',
  ),
  CommentarySource(
    id: 'fbmeyer',
    name: 'Through the Bible Day by Day',
    author: 'F. B. Meyer',
    year: '1914',
    kind: CommentaryKind.verseJson,
    urlFor: (b, c) => '$_pillar/fbmeyer/${b.usfm}/$c.json',
  ),
  for (final (id, name, author) in const [
    ('jamieson-fausset-brown', 'Jamieson-Fausset-Brown', 'JFB'),
    ('adam-clarke', 'Adam Clarke\'s Commentary', 'Adam Clarke'),
    ('john-gill', 'Gill\'s Exposition', 'John Gill'),
    ('keil-delitzsch', 'Keil & Delitzsch (OT)', 'Keil & Delitzsch'),
    ('tyndale', 'Tyndale Open Study Notes', 'Tyndale House'),
  ])
    CommentarySource(
      id: 'hao_$id',
      name: name,
      author: author,
      kind: CommentaryKind.verseJson,
      urlFor: (b, c) => 'https://bible.helloao.org/api/c/$id/${b.usfm}/$c.json',
      coversBook: id == 'keil-delitzsch' ? (b) => b.index < 40 : null,
    ),
];

/// Fetches commentary and keeps a copy on the device for offline reading.
class CommentaryService {
  final Map<String, CommentaryChapter> _mem = {};

  String _key(CommentarySource s, BibleBook b, int c) =>
      'commentary/${s.id}/${b.usfm}_$c.txt';

  Map<String, dynamic>? _scofield;

  Future<CommentaryChapter> _bundled(BibleBook b, int chapter) async {
    _scofield ??= await compute(
      (String raw) => jsonDecode(raw) as Map<String, dynamic>,
      await rootBundle.loadString('assets/data/scofield.json'),
    );
    final items = (_scofield!['${b.usfm}.$chapter'] as List?) ?? const [];
    final blocks = <CommentaryBlock>[];
    for (var i = 0; i < items.length; i++) {
      final start = (items[i] as List)[0] as int;
      final end = i + 1 < items.length
          ? (((items[i + 1] as List)[0] as int) - 1).clamp(start, 999)
          : start;
      blocks.add(CommentaryBlock(start, end, '', '${(items[i] as List)[1]}'));
    }
    return CommentaryChapter('', blocks);
  }

  Future<CommentaryChapter> fetch(
    CommentarySource s,
    BibleBook b,
    int chapter,
  ) async {
    final key = _key(s, b, chapter);
    final m = _mem[key];
    if (m != null) return m;
    if (s.bundled) return _mem[key] = await _bundled(b, chapter);
    var body = await FileStore.instance.read(key);
    if (body == null) {
      final r = await http
          .get(Uri.parse(s.urlFor(b, chapter)))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 404) {
        body = '';
      } else if (r.statusCode != 200) {
        throw http.ClientException('HTTP ${r.statusCode}');
      } else {
        body = utf8.decode(r.bodyBytes, allowMalformed: true);
      }
      await FileStore.instance.write(key, body);
    }
    final parsed = body.isEmpty
        ? const CommentaryChapter('', [])
        : s.kind == CommentaryKind.chapterMarkdown
        ? await compute(parseMatthewHenryMarkdown, body)
        : await compute(parseVerseJsonCommentary, body);
    _mem[key] = parsed;
    return parsed;
  }
}

const _sup = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
};

/// Splits a Matthew Henry chapter into sections at `##` headings and works out
/// which verses each section covers from the quoted Scripture (`> **¹⁶** …`)
/// and references like "v. 16" / "Joh 3:1-21".
CommentaryChapter parseMatthewHenryMarkdown(String md) {
  var text = md.replaceAll('\r', '');
  if (text.startsWith('---')) {
    final end = text.indexOf('\n---', 3);
    if (end > 0) text = text.substring(end + 4);
  }
  final lines = text.split('\n');
  final intro = StringBuffer();
  final blocks = <CommentaryBlock>[];
  String? title;
  final body = StringBuffer();
  final verseRe = RegExp(r'\*\*([⁰¹²³⁴⁵⁶⁷⁸⁹]+)\*\*');

  void flush() {
    if (title == null) return;
    final content = body.toString().trim();
    final nums = verseRe
        .allMatches(content)
        .map((m) => int.parse(m.group(1)!.split('').map((c) => _sup[c]).join()))
        .toList();
    var start = nums.isEmpty ? 0 : nums.reduce((a, b) => a < b ? a : b);
    var end = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    if (nums.isEmpty) {
      final r = RegExp(r'[vV]\.\s?(\d+)(?:[-–](\d+))?').firstMatch(content);
      if (r != null) {
        start = int.parse(r.group(1)!);
        end = int.tryParse(r.group(2) ?? '') ?? start;
      } else if (blocks.isNotEmpty) {
        start = blocks.last.endVerse;
        end = start;
      }
    }
    blocks.add(CommentaryBlock(start, end, title, content));
    body.clear();
  }

  for (final line in lines) {
    if (line.startsWith('# ') &&
        title == null &&
        intro.toString().trim().isEmpty) {
      continue;
    }
    if (line.startsWith('## ')) {
      flush();
      title = line.substring(3).trim();
      continue;
    }
    if (title == null) {
      intro.writeln(line);
    } else {
      body.writeln(line);
    }
  }
  flush();
  return CommentaryChapter(intro.toString().trim(), blocks);
}

/// Parses `{chapter:{content:[{type:'verse', number, content:[...]}]}}`
/// (Pillar / HelloAO commentary schema).
CommentaryChapter parseVerseJsonCommentary(String body) {
  final j = jsonDecode(body);
  final ch = (j is Map ? j['chapter'] : null) as Map? ?? const {};
  final intro = '${ch['introduction'] ?? ''}';
  final items = ch['content'] as List? ?? const [];
  final blocks = <CommentaryBlock>[];
  final verses = <int>[];
  final texts = <String>[];
  for (final it in items) {
    if (it is! Map || it['type'] != 'verse') continue;
    final n = it['number'] is int
        ? it['number'] as int
        : int.tryParse('${it['number']}') ?? 0;
    final t = _flatten(it['content']).trim();
    if (t.isEmpty) continue;
    verses.add(n);
    texts.add(t);
  }
  for (var i = 0; i < verses.length; i++) {
    final start = verses[i];
    final end = i + 1 < verses.length
        ? (verses[i + 1] - 1).clamp(start, 999)
        : start;
    blocks.add(CommentaryBlock(start, end, '', texts[i]));
  }
  return CommentaryChapter(intro, blocks);
}

String _flatten(Object? o) {
  final b = StringBuffer();
  void walk(Object? x) {
    if (x is String) {
      if (b.isNotEmpty) b.write('\n\n');
      b.write(x);
    } else if (x is List) {
      x.forEach(walk);
    } else if (x is Map) {
      if (x['text'] != null) walk(x['text']);
      if (x['content'] != null) walk(x['content']);
    }
  }

  walk(o);
  return b.toString();
}
