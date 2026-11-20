import 'books.dart';

/// A single verse location (1-based book/chapter/verse).
class VerseRef implements Comparable<VerseRef> {
  const VerseRef(this.book, this.chapter, this.verse);

  final int book;
  final int chapter;
  final int verse;

  /// Compact key used for storage, e.g. "43.3.16".
  String get key => '$book.$chapter.$verse';
  String get chapterKey => '$book.$chapter';

  static VerseRef? tryParseKey(String key) {
    final p = key.split('.');
    if (p.length != 3) return null;
    final b = int.tryParse(p[0]);
    final c = int.tryParse(p[1]);
    final v = int.tryParse(p[2]);
    if (b == null || c == null || v == null || b < 1 || b > 66) return null;
    return VerseRef(b, c, v);
  }

  BibleBook get bookInfo => bookAt(book);

  String label({bool amharic = false, bool short = false}) {
    final b = bookInfo;
    final n = short ? b.short(amharic) : b.name(amharic);
    return '$n $chapter:$verse';
  }

  @override
  int compareTo(VerseRef o) {
    if (book != o.book) return book - o.book;
    if (chapter != o.chapter) return chapter - o.chapter;
    return verse - o.verse;
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);

  @override
  String toString() => key;
}

/// A passage: one chapter or a verse range inside it, or a range of chapters.
class Passage {
  const Passage(
    this.book,
    this.chapter, {
    this.fromVerse,
    this.toVerse,
    this.toChapter,
  });

  final int book;
  final int chapter;
  final int? fromVerse;
  final int? toVerse;

  /// When set, the passage spans [chapter]..[toChapter] (whole chapters).
  final int? toChapter;

  List<int> get chapters => [
    for (var c = chapter; c <= (toChapter ?? chapter); c++) c,
  ];

  String label({bool amharic = false}) {
    final b = bookAt(book).name(amharic);
    if (toChapter != null && toChapter != chapter) {
      return '$b $chapter–$toChapter';
    }
    if (fromVerse != null) {
      final end = (toVerse != null && toVerse != fromVerse) ? '–$toVerse' : '';
      return '$b $chapter:$fromVerse$end';
    }
    return '$b $chapter';
  }

  String encode() =>
      '$book.$chapter${fromVerse != null ? ':$fromVerse' : ''}${toVerse != null ? '-$toVerse' : ''}${toChapter != null ? '~$toChapter' : ''}';

  static Passage decode(String s) {
    var rest = s;
    int? toCh;
    if (rest.contains('~')) {
      final p = rest.split('~');
      rest = p[0];
      toCh = int.parse(p[1]);
    }
    int? fv, tv;
    if (rest.contains(':')) {
      final p = rest.split(':');
      rest = p[0];
      final vr = p[1].split('-');
      fv = int.parse(vr[0]);
      if (vr.length > 1) tv = int.parse(vr[1]);
    }
    final bc = rest.split('.');
    return Passage(
      int.parse(bc[0]),
      int.parse(bc[1]),
      fromVerse: fv,
      toVerse: tv,
      toChapter: toCh,
    );
  }
}

/// Parses a cross-reference token as stored in assets/data/crossrefs.json:
/// "43.3.16", "43.3.16-18" or "43.3.16-4.2".
Passage? parseRefToken(String token) {
  final dash = token.indexOf('-');
  final head = dash < 0 ? token : token.substring(0, dash);
  final start = VerseRef.tryParseKey(head);
  if (start == null) return null;
  if (dash < 0) {
    return Passage(
      start.book,
      start.chapter,
      fromVerse: start.verse,
      toVerse: start.verse,
    );
  }
  final tail = token.substring(dash + 1);
  if (tail.contains('.')) {
    // crosses a chapter boundary – show from start verse to the end chapter
    final p = tail.split('.');
    return Passage(
      start.book,
      start.chapter,
      fromVerse: start.verse,
      toChapter: int.tryParse(p[0]),
    );
  }
  return Passage(
    start.book,
    start.chapter,
    fromVerse: start.verse,
    toVerse: int.tryParse(tail) ?? start.verse,
  );
}

/// Parses free text like "John 3:16", "jn 3", "ዮሐ 3:16", "1 cor 13:4-7".
Passage? parseHumanReference(String input) {
  final s = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final m = RegExp(r'^(.+?)\s*(\d+)(?:\s*[:.]\s*(\d+)(?:\s*[-–]\s*(\d+))?)?$')
      .firstMatch(s);
  if (m == null) return null;
  final name = m.group(1)!.replaceAll('.', '').trim();
  final ch = int.parse(m.group(2)!);
  final fv = m.group(3) != null ? int.parse(m.group(3)!) : null;
  final tv = m.group(4) != null ? int.parse(m.group(4)!) : fv;
  final book = findBookByName(name);
  if (book == null || ch < 1 || ch > book.chapters) return null;
  return Passage(book.index, ch, fromVerse: fv, toVerse: tv);
}

BibleBook? findBookByName(String raw) {
  final n = _norm(raw);
  if (n.isEmpty) return null;
  for (final b in kBooks) {
    for (final cand in [b.nameEn, b.shortEn, b.usfm, b.nameAm, b.shortAm]) {
      if (_norm(cand) == n) return b;
    }
  }
  for (final b in kBooks) {
    if (_norm(b.nameEn).startsWith(n) || _norm(b.nameAm).contains(n)) {
      return b;
    }
  }
  return null;
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll('፩', '1')
    .replaceAll('፪', '2')
    .replaceAll('፫', '3')
    .replaceAll(RegExp(r'^(i{1,3})\s', caseSensitive: false), '')
    .replaceAll(RegExp(r'[\s.ኛ]'), '');

/// Converts a number to Ethiopic numerals (፩, ፪, ... ፻).
String toEthiopicNumeral(int n) {
  if (n <= 0) return '$n';
  const ones = ['', '፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱'];
  const tens = ['', '፲', '፳', '፴', '፵', '፶', '፷', '፸', '፹', '፺'];
  String below100(int x) => '${tens[x ~/ 10]}${ones[x % 10]}';
  if (n < 100) return below100(n);
  final hundreds = n ~/ 100;
  final rest = n % 100;
  final h = hundreds == 1 ? '' : below100(hundreds);
  return '$h፻${below100(rest)}';
}
