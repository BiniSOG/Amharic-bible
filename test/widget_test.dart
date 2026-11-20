import 'package:amharic_bible/core/reference.dart';
import 'package:amharic_bible/data/bible_repository.dart';
import 'package:amharic_bible/data/commentary_service.dart';
import 'package:amharic_bible/data/plans.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses human references in English and Amharic', () {
    final p = parseHumanReference('John 3:16')!;
    expect((p.book, p.chapter, p.fromVerse), (43, 3, 16));
    final a = parseHumanReference('ዮሐ 3:16')!;
    expect(a.book, 43);
    final c = parseHumanReference('1 cor 13:4-7')!;
    expect((c.book, c.chapter, c.fromVerse, c.toVerse), (46, 13, 4, 7));
    expect(parseHumanReference('Ps 23')!.book, 19);
  });

  test('cross reference tokens', () {
    final p = parseRefToken('43.3.16-18')!;
    expect((p.book, p.chapter, p.fromVerse, p.toVerse), (43, 3, 16, 18));
  });

  test('ethiopic numerals', () {
    expect(toEthiopicNumeral(1), '፩');
    expect(toEthiopicNumeral(23), '፳፫');
    expect(toEthiopicNumeral(150), '፻፶');
  });

  test('amharic homophones fold for search', () {
    expect(normalizeForSearch('ሐዋርያ'), normalizeForSearch('ሀዋርያ'));
    expect(normalizeForSearch('ፀሐይ'), normalizeForSearch('ጸሀይ'));
    expect(normalizeForSearch('ዐይን'), normalizeForSearch('አይን'));
  });

  test('reading plans cover the Bible', () {
    final year = kReadingPlans.firstWhere((p) => p.id == 'year-balanced');
    expect(year.length, 365);
    final chapters = year.days
        .expand((d) => d)
        .fold<int>(0, (s, p) => s + p.chapters.length);
    expect(chapters, 1189);
    for (final plan in kReadingPlans) {
      expect(plan.days.every((d) => d.isNotEmpty), isTrue, reason: plan.id);
    }
  });

  test('matthew henry markdown sections map to verses', () {
    const md =
        '---\ntitle: x\n---\n# John 3\nIntro text.\n\n'
        '## Christ and Nicodemus\n\n> **¹** There was a man\n> **¹⁶** For God so loved\n\nComment.\n\n'
        '## John Baptist\n\n> **²²** After these things\n\nMore.';
    final c = parseMatthewHenryMarkdown(md);
    expect(c.intro, 'Intro text.');
    expect(c.blocks.length, 2);
    expect(c.forVerse(16).first.title, 'Christ and Nicodemus');
    expect(c.forVerse(30).first.title, 'John Baptist');
  });
}
