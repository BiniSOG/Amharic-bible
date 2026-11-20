import 'dart:io';

import 'package:amharic_bible/core/i18n/translations.dart';
import 'package:amharic_bible/core/l10n.dart';
import 'package:amharic_bible/data/bible.dart';
import 'package:amharic_bible/data/strongs_service.dart';
import 'package:amharic_bible/data/update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('force update', () {
    final j = {
      'latest_build': 5,
      'min_build': 3,
      'android_url': 'a',
      'ios_url': 'i',
    };
    test('below minimum is required', () {
      expect(
        UpdateService.evaluate(j, 2, TargetPlatform.android).kind,
        UpdateKind.required,
      );
    });
    test('between minimum and latest is optional', () {
      final u = UpdateService.evaluate(j, 4, TargetPlatform.iOS);
      expect(u.kind, UpdateKind.optional);
      expect(u.url, 'i');
    });
    test('latest needs nothing', () {
      expect(
        UpdateService.evaluate(j, 5, TargetPlatform.android).kind,
        UpdateKind.none,
      );
    });
  });

  test("Strong's numbers normalise and split", () {
    expect(StrongsService.normalize('g02532'), 'G2532');
    expect(StrongsService.normalize(' H 1254 '), 'H1254');
    expect(StrongsService.normalize('John'), isNull);
    final parts = splitTagged('whereon[G1909][G3739] never[G3762] man sat.');
    expect(parts[0].$1, 'whereon');
    expect(parts[0].$2, ['G1909', 'G3739']);
    expect(parts[1].$2, ['G3762']);
    expect(parts.last.$1, ' man sat.');
  });

  test("KJV with Strong's loads as a tagged Bible", () {
    final b = parseAnyBible({
      'body': File('assets/bibles/kjv_strongs.json').readAsStringSync(),
      'id': 'KJVS',
      'lang': 'en',
    });
    expect(b.hasStrongs, isTrue);
    expect(b.verse(43, 3, 16), startsWith('For God so loved the world'));
    expect(b.taggedVerse(43, 3, 16), contains('[G25]'));
  });

  test('Chinese text loses alignment spaces', () {
    final b = parseAnyBible({
      'body': '[{"book_id":43,"chapter":3,"verse":16,"text":"「 神 愛 世人，甚至"}]',
      'id': 'T',
      'lang': 'zh',
    });
    expect(b.verse(43, 3, 16), '「神愛世人，甚至');
  });

  test('complete translations cover every key', () {
    final en = const L('en');
    for (final lang in kAppLanguages.where((l) => l.complete)) {
      if (lang.code == 'en' || lang.code == 'am') continue;
      final map = kTranslations[lang.code]!;
      final missing = [
        for (final k in kTranslations['fr']!.keys)
          if (!map.containsKey(k)) k,
      ];
      expect(missing, isEmpty, reason: lang.code);
    }
    expect(en('today'), 'Today');
    expect(const L('ti')('today'), 'ሎሚ');
    // Gurage falls back to Amharic, Afar to English.
    expect(const L('sgw')('today'), 'ዛሬ');
    expect(const L('aa')('today'), 'Today');
  });
}
