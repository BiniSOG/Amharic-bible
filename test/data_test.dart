import 'dart:convert';
import 'dart:io';

import 'package:amharic_bible/core/books.dart';
import 'package:amharic_bible/data/bible.dart';
import 'package:flutter_test/flutter_test.dart';

Bible _load(String path, String id, String lang) => parseAnyBible({
  'body': File(path).readAsStringSync(),
  'id': id,
  'lang': lang,
});

void main() {
  test('bundled Amharic 1954 is complete', () {
    final am = _load('assets/bibles/am1954.json', 'AM1954', 'am');
    expect(am.books.length, 66);
    for (final b in kBooks) {
      expect(am.books[b.index - 1].length, b.chapters, reason: b.nameEn);
    }
    expect(am.verse(43, 3, 16), contains('ዓለሙን'));
    expect(am.verse(1, 1, 1), startsWith('በመጀመሪያ'));
    final verses = am.books.expand((b) => b).expand((c) => c);
    expect(verses.where((v) => v.isNotEmpty).length, greaterThan(30000));
  });

  test('bundled KJV', () {
    final kjv = _load('assets/bibles/kjv.json', 'KJV', 'en');
    expect(kjv.verse(43, 3, 16), startsWith('For God so loved the world'));
    expect(kjv.books.expand((b) => b).expand((c) => c).length, 31102);
  });

  test('cross references and dictionary assets decode', () {
    final x = jsonDecode(
      File('assets/data/crossrefs.json').readAsStringSync(),
    ) as Map;
    expect(x['43.3.16'], isNotEmpty);
    final e =
        jsonDecode(File('assets/data/eastons.json').readAsStringSync()) as List;
    expect(e.length, greaterThan(3000));
    final s =
        jsonDecode(File('assets/data/stories.json').readAsStringSync()) as List;
    expect(s.length, greaterThanOrEqualTo(20));
  });

  test('HelloAO-shaped complete.json parses', () {
    final body = jsonEncode({
      'translation': {'id': 'x'},
      'books': [
        {
          'id': 'JHN',
          'name': 'John',
          'chapters': [
            {
              'chapter': {
                'number': 3,
                'content': [
                  {
                    'type': 'heading',
                    'content': ['Nicodemus'],
                  },
                  {
                    'type': 'verse',
                    'number': 16,
                    'content': [
                      'For God so loved',
                      {'noteId': 1},
                      'the world.',
                    ],
                  },
                ],
              },
            },
          ],
        },
      ],
    });
    final b = parseAnyBible({'body': body, 'id': 'T', 'lang': 'en'});
    expect(b.verse(43, 3, 16), 'For God so loved the world.');
  });
}
