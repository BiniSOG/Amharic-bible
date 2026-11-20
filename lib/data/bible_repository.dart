import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/books.dart';
import 'bible.dart';
import 'file_store.dart';
import 'translation_catalog.dart';

enum DownloadState { idle, downloading, failed }

/// Loads, downloads and searches Bible versions.
class BibleRepository extends ChangeNotifier {
  BibleRepository(this._prefs) {
    _restoreInstalled();
  }

  final SharedPreferences _prefs;
  static const _kInstalled = 'installed_translations_v1';

  final Map<String, Bible> _cache = {};
  final Map<String, Future<Bible>> _loading = {};
  final List<TranslationInfo> _downloaded = [];
  final Map<String, DownloadState> downloadState = {};
  final Map<String, double?> downloadProgress = {};
  List<TranslationInfo> _onlineExtra = [];

  /// Everything the user can read right now.
  List<TranslationInfo> get installed => [
    ...kBundledTranslations,
    ..._downloaded,
  ];

  /// Things that can be downloaded and are not yet installed.
  List<TranslationInfo> get downloadable {
    final have = installed.map((t) => t.id).toSet();
    return [
      ...kRemoteTranslations,
      ..._onlineExtra,
    ].where((t) => !have.contains(t.id)).toList();
  }

  TranslationInfo? info(String id) {
    for (final t in [...installed, ...kRemoteTranslations, ..._onlineExtra]) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool isInstalled(String id) => installed.any((t) => t.id == id);

  Bible? cached(String id) => _cache[id];

  void _restoreInstalled() {
    final raw = _prefs.getString(_kInstalled);
    if (raw == null) return;
    try {
      for (final j in jsonDecode(raw) as List) {
        _downloaded.add(TranslationInfo.fromJson(j as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  Future<void> _persistInstalled() => _prefs.setString(
    _kInstalled,
    jsonEncode(_downloaded.map((t) => t.toJson()).toList()),
  );

  /// Loads a version (bundled or downloaded). Falls back to the Amharic Bible.
  Future<Bible> load(String id) {
    final c = _cache[id];
    if (c != null) return SynchronousFuture(c);
    return _loading[id] ??= _load(id).then(
      (b) {
        _cache[id] = b;
        _loading.remove(id);
        notifyListeners();
        return b;
      },
      onError: (Object e) {
        _loading.remove(id);
        if (id != 'AM1954') return load('AM1954');
        throw e;
      },
    );
  }

  Future<Bible> _load(String id) async {
    final t = info(id);
    if (t == null) throw StateError('Unknown version $id');
    String? body;
    if (t.asset != null) {
      body = await rootBundle.loadString(t.asset!);
    } else {
      body = await FileStore.instance.read(_fileName(id));
      if (body == null) throw StateError('Version $id is not downloaded');
    }
    return compute(parseAnyBible, {
      'body': body,
      'id': t.id,
      'abbr': t.abbr,
      'name': t.name,
      'lang': t.lang,
    });
  }

  String _fileName(String id) => 'bibles/$id.json';

  Future<void> download(TranslationInfo t) async {
    if (t.url == null) return;
    downloadState[t.id] = DownloadState.downloading;
    downloadProgress[t.id] = null;
    notifyListeners();
    try {
      final req = http.Request('GET', Uri.parse(t.url!));
      final resp = await http.Client().send(req);
      if (resp.statusCode != 200) {
        throw http.ClientException('HTTP ${resp.statusCode}');
      }
      final total = resp.contentLength;
      final bytes = <int>[];
      await for (final chunk in resp.stream) {
        bytes.addAll(chunk);
        if (total != null && total > 0) {
          downloadProgress[t.id] = bytes.length / total;
          notifyListeners();
        }
      }
      final body = utf8.decode(bytes, allowMalformed: true);
      final bible = await compute(parseAnyBible, {
        'body': body,
        'id': t.id,
        'abbr': t.abbr,
        'name': t.name,
        'lang': t.lang,
      });
      await FileStore.instance.write(
        _fileName(t.id),
        jsonEncode(bible.toJson()),
      );
      _cache[t.id] = bible;
      _downloaded.removeWhere((x) => x.id == t.id);
      _downloaded.add(t);
      await _persistInstalled();
      downloadState[t.id] = DownloadState.idle;
    } catch (e) {
      debugPrint('download ${t.id} failed: $e');
      downloadState[t.id] = DownloadState.failed;
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (kBundledTranslations.any((t) => t.id == id)) return;
    _downloaded.removeWhere((t) => t.id == id);
    _cache.remove(id);
    await FileStore.instance.delete(_fileName(id));
    await _persistInstalled();
    notifyListeners();
  }

  /// Adds a user supplied link (e.g. a licensed version the user may use).
  Future<bool> addCustom(String url, String name, String lang) async {
    final id = 'CUSTOM_${url.hashCode.toUnsigned(32).toRadixString(36)}';
    final t = TranslationInfo(
      id: id,
      abbr: name.length <= 6 ? name : name.substring(0, 6),
      name: name,
      lang: lang,
      url: url,
      license: 'Added by you',
      custom: true,
    );
    await download(t);
    return isInstalled(id);
  }

  /// Fetches additional free versions (Ethiopian languages, English, Arabic,
  /// French, Italian, Chinese) from the
  /// HelloAO catalogue. Silently ignored when offline.
  Future<void> refreshOnlineCatalog() async {
    try {
      final r = await http
          .get(Uri.parse(kHelloAoTranslations))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final known = {
        ...kRemoteTranslations.map((t) => t.name.toLowerCase()),
        ...kBundledTranslations.map((t) => t.id.toLowerCase()),
      };
      final out = <TranslationInfo>[];
      for (final t in (j['translations'] as List? ?? const [])) {
        if (t is! Map) continue;
        final code = _helloAoLang['${t['language']}'];
        if (code == null) continue;
        final id = '${t['id']}';
        final name = '${t['englishName'] ?? t['name'] ?? id}';
        if (known.contains(name.toLowerCase())) continue;
        out.add(
          TranslationInfo(
            id: 'HAO_$id',
            abbr: '${t['shortName'] ?? id}',
            name: '${t['name'] ?? name}',
            lang: code,
            url: helloAoComplete(id),
            description: name,
            license: 'See ${t['licenseUrl'] ?? t['website'] ?? 'helloao.org'}',
          ),
        );
      }
      out.sort(
        (a, b) => a.lang == b.lang
            ? a.name.compareTo(b.name)
            : langOrder(a.lang).compareTo(langOrder(b.lang)),
      );
      _onlineExtra = out;
      notifyListeners();
    } catch (_) {}
  }

  /// Full-text search across one version.
  Future<List<SearchHit>> search(
    String id,
    String query, {
    SearchScope scope = SearchScope.all,
    int limit = 500,
  }) async {
    final bible = await load(id);
    if (query.trim().length < 2) return const [];
    return compute(
      _searchIsolate,
      _SearchArgs(bible.books, query, scope, limit),
    );
  }
}

enum SearchScope { all, oldTestament, newTestament, gospels, currentBook }

class SearchHit {
  const SearchHit(this.book, this.chapter, this.verse, this.text);
  final int book;
  final int chapter;
  final int verse;
  final String text;
}

class _SearchArgs {
  _SearchArgs(this.books, this.query, this.scope, this.limit);
  final List<List<List<String>>> books;
  final String query;
  final SearchScope scope;
  final int limit;
}

List<SearchHit> _searchIsolate(_SearchArgs a) {
  final terms = normalizeForSearch(a.query)
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();
  final hits = <SearchHit>[];
  for (var b = 0; b < a.books.length; b++) {
    final bookNo = b + 1;
    switch (a.scope) {
      case SearchScope.oldTestament:
        if (bookNo >= 40) continue;
      case SearchScope.newTestament:
        if (bookNo < 40) continue;
      case SearchScope.gospels:
        if (bookNo < 40 || bookNo > 43) continue;
      case SearchScope.currentBook:
      case SearchScope.all:
        break;
    }
    final chapters = a.books[b];
    for (var c = 0; c < chapters.length; c++) {
      final verses = chapters[c];
      for (var v = 0; v < verses.length; v++) {
        final t = verses[v];
        if (t.isEmpty) continue;
        final n = normalizeForSearch(t);
        if (terms.every(n.contains)) {
          hits.add(SearchHit(bookNo, c + 1, v + 1, t));
          if (hits.length >= a.limit) return hits;
        }
      }
    }
  }
  return hits;
}

/// Lower-cases, removes punctuation and folds Amharic homophone letters
/// (ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ) so that searches match regardless of spelling.
String normalizeForSearch(String s) {
  final out = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    var c = r;
    final row = c & ~0x7;
    final col = c & 0x7;
    if (row == 0x1210 || row == 0x1280) {
      c = 0x1200 + col; // ሐ ኀ → ሀ
    } else if (row == 0x1220) {
      c = 0x1230 + col; // ሠ → ሰ
    } else if (row == 0x12D0) {
      c = 0x12A0 + col; // ዐ → አ
    } else if (row == 0x1340) {
      c = 0x1338 + col; // ፀ → ጸ
    }
    // punctuation (Latin + Ethiopic word space/full stop etc.)
    if ((c >= 0x1360 && c <= 0x1368) ||
        const [
          0x2c,
          0x2e,
          0x3b,
          0x3a,
          0x21,
          0x3f,
          0x27,
          0x22,
          0x28,
          0x29,
        ].contains(c)) {
      out.write(' ');
      continue;
    }
    out.writeCharCode(c);
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Book ranges for UI grouping.
List<BibleBook> booksIn(SearchScope s) => switch (s) {
  SearchScope.oldTestament => kBooks.where((b) => b.index < 40).toList(),
  SearchScope.newTestament => kBooks.where((b) => b.index >= 40).toList(),
  SearchScope.gospels =>
    kBooks.where((b) => b.index >= 40 && b.index <= 43).toList(),
  _ => kBooks,
};

/// ISO 639-3 codes used by the HelloAO catalogue → codes used in this app.
const Map<String, String> _helloAoLang = {
  'amh': 'am',
  'gez': 'gez',
  'eng': 'en',
  'orm': 'om',
  'gaz': 'om',
  'hae': 'om',
  'tir': 'ti',
  'som': 'so',
  'aar': 'aa',
  'sgw': 'sgw',
  'arb': 'ar',
  'ara': 'ar',
  'fra': 'fr',
  'ita': 'it',
  'cmn': 'zh',
  'zho': 'zh',
};

/// Display order of Bible languages.
const List<String> kBibleLangOrder = [
  'am',
  'gez',
  'en',
  'om',
  'ti',
  'sgw',
  'aa',
  'so',
  'ar',
  'fr',
  'it',
  'zh',
];

int langOrder(String code) {
  final i = kBibleLangOrder.indexOf(code);
  return i < 0 ? 99 : i;
}

/// Name of a Bible language in its own script.
String bibleLangName(String code) => switch (code) {
  'am' => 'አማርኛ',
  'gez' => 'ግዕዝ',
  'en' => 'English',
  'om' => 'Afaan Oromoo',
  'ti' => 'ትግርኛ',
  'sgw' => 'ጉራጊኛ',
  'aa' => 'Qafaraf',
  'so' => 'Soomaali',
  'ar' => 'العربية',
  'fr' => 'Français',
  'it' => 'Italiano',
  'zh' => '中文',
  _ => code,
};

/// English name of a Bible language.
String bibleLangEnglishName(String code) => switch (code) {
  'am' => 'Amharic',
  'gez' => "Ge'ez",
  'en' => 'English',
  'om' => 'Oromo',
  'ti' => 'Tigrinya',
  'sgw' => 'Gurage',
  'aa' => 'Afar',
  'so' => 'Somali',
  'ar' => 'Arabic',
  'fr' => 'French',
  'it' => 'Italian',
  'zh' => 'Chinese',
  _ => code,
};
