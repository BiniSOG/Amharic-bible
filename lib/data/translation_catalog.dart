/// Describes a Bible version the app can show.
class TranslationInfo {
  const TranslationInfo({
    required this.id,
    required this.abbr,
    required this.name,
    required this.lang,
    this.asset,
    this.url,
    this.description = '',
    this.license = 'Public domain',
    this.scope = TranslationScope.full,
    this.custom = false,
  });

  final String id;
  final String abbr;
  final String name;

  /// 'am', 'en' or 'gez'.
  final String lang;

  /// Bundled asset path (always available offline).
  final String? asset;

  /// Remote JSON (downloaded once and stored on the device).
  final String? url;
  final String description;
  final String license;
  final TranslationScope scope;

  /// Added by the user from a link.
  final bool custom;

  bool get bundled => asset != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'abbr': abbr,
    'name': name,
    'lang': lang,
    'url': url,
    'description': description,
    'license': license,
    'scope': scope.name,
    'custom': custom,
  };

  factory TranslationInfo.fromJson(Map<String, dynamic> j) => TranslationInfo(
    id: j['id'] as String,
    abbr: j['abbr'] as String? ?? j['id'] as String,
    name: j['name'] as String? ?? j['id'] as String,
    lang: j['lang'] as String? ?? 'en',
    url: j['url'] as String?,
    description: j['description'] as String? ?? '',
    license: j['license'] as String? ?? '',
    scope: TranslationScope.values.firstWhere(
      (s) => s.name == j['scope'],
      orElse: () => TranslationScope.full,
    ),
    custom: j['custom'] as bool? ?? false,
  );
}

enum TranslationScope { full, newTestament, partial }

const _sm =
    'https://raw.githubusercontent.com/scrollmapper/bible_databases/master/formats/json/';

/// Versions that ship inside the app.
const List<TranslationInfo> kBundledTranslations = [
  TranslationInfo(
    id: 'AM1954',
    abbr: 'አማ1954',
    name: 'መጽሐፍ ቅዱስ — 1954 (ቀዳማዊ ኃይለ ሥላሴ)',
    lang: 'am',
    asset: 'assets/bibles/am1954.json',
    description:
        'The classic Amharic Bible (1954 E.C. / 1962 G.C.), widely used by the '
        'Ethiopian Orthodox and Evangelical churches.',
    license:
        'Widely distributed text; sources: ethiopicbible.com, '
        'wordproject.org (via open datasets).',
  ),
  TranslationInfo(
    id: 'KJV',
    abbr: 'KJV',
    name: 'King James Version (1769)',
    lang: 'en',
    asset: 'assets/bibles/kjv.json',
    description: 'The Authorized Version, Oxford 1769 edition.',
  ),
  TranslationInfo(
    id: 'GEEZ',
    abbr: 'ግዕዝ',
    name: 'ግዕዝ — Ge\'ez (partial)',
    lang: 'gez',
    asset: 'assets/bibles/geez.json',
    scope: TranslationScope.partial,
    description:
        'Classical Ge\'ez text for Genesis–Ruth, Samuel, Kings and '
        'Psalms.',
    license: 'Source: ethiopicbible.com (via open dataset).',
  ),
];

/// Openly-licensed versions available for download.
const List<TranslationInfo> kRemoteTranslations = [
  TranslationInfo(
    id: 'BSB',
    abbr: 'BSB',
    name: 'Berean Standard Bible',
    lang: 'en',
    url: '${_sm}BSB.json',
    description: 'Modern, accurate and readable (2023, public domain).',
  ),
  TranslationInfo(
    id: 'ASV',
    abbr: 'ASV',
    name: 'American Standard Version (1901)',
    lang: 'en',
    url: '${_sm}ASV.json',
  ),
  TranslationInfo(
    id: 'NHEB',
    abbr: 'NHEB',
    name: 'New Heart English Bible',
    lang: 'en',
    url: '${_sm}NHEB.json',
    description: 'Based on the World English Bible.',
  ),
  TranslationInfo(
    id: 'LEB',
    abbr: 'LEB',
    name: 'Lexham English Bible',
    lang: 'en',
    url: '${_sm}LEB.json',
    license: 'Free with attribution — Faithlife/Logos.',
  ),
  TranslationInfo(
    id: 'BBE',
    abbr: 'BBE',
    name: 'Bible in Basic English',
    lang: 'en',
    url: '${_sm}BBE.json',
    description: 'Simple English, great for learners and children.',
  ),
  TranslationInfo(
    id: 'OEB',
    abbr: 'OEB',
    name: 'Open English Bible',
    lang: 'en',
    url: '${_sm}OEB.json',
    license: 'CC0',
    scope: TranslationScope.partial,
  ),
  TranslationInfo(
    id: 'YLT',
    abbr: 'YLT',
    name: 'Young\'s Literal Translation',
    lang: 'en',
    url: '${_sm}YLT.json',
  ),
  TranslationInfo(
    id: 'DARBY',
    abbr: 'DBY',
    name: 'Darby Bible (1889)',
    lang: 'en',
    url: '${_sm}Darby.json',
  ),
  TranslationInfo(
    id: 'WBT',
    abbr: 'WBT',
    name: 'Webster Bible (1833)',
    lang: 'en',
    url: '${_sm}Webster.json',
  ),
  TranslationInfo(
    id: 'RWEBSTER',
    abbr: 'RWV',
    name: 'Revised Webster (1833)',
    lang: 'en',
    url: '${_sm}RWebster.json',
  ),
  TranslationInfo(
    id: 'AKJV',
    abbr: 'AKJV',
    name: 'American King James Version',
    lang: 'en',
    url: '${_sm}AKJV.json',
  ),
  TranslationInfo(
    id: 'UKJV',
    abbr: 'UKJV',
    name: 'Updated King James Version',
    lang: 'en',
    url: '${_sm}UKJV.json',
  ),
  TranslationInfo(
    id: 'ACV',
    abbr: 'ACV',
    name: 'A Conservative Version',
    lang: 'en',
    url: '${_sm}ACV.json',
  ),
  TranslationInfo(
    id: 'GENEVA',
    abbr: 'GNV',
    name: 'Geneva Bible (1599)',
    lang: 'en',
    url: '${_sm}Geneva1599.json',
  ),
  TranslationInfo(
    id: 'DRC',
    abbr: 'DRA',
    name: 'Douay-Rheims (Challoner)',
    lang: 'en',
    url: '${_sm}DRC.json',
    description: 'Catholic English Bible.',
  ),
  TranslationInfo(
    id: 'CPDV',
    abbr: 'CPDV',
    name: 'Catholic Public Domain Version',
    lang: 'en',
    url: '${_sm}CPDV.json',
  ),
  TranslationInfo(
    id: 'ROTHERHAM',
    abbr: 'EBR',
    name: 'Rotherham Emphasized Bible',
    lang: 'en',
    url: '${_sm}Rotherham.json',
  ),
  TranslationInfo(
    id: 'NOYES',
    abbr: 'NOY',
    name: 'Noyes Translation (1869)',
    lang: 'en',
    url: '${_sm}Noyes.json',
    scope: TranslationScope.partial,
  ),
  TranslationInfo(
    id: 'TYNDALE',
    abbr: 'TYN',
    name: 'Tyndale Bible (1525/1530)',
    lang: 'en',
    url: '${_sm}Tyndale.json',
    scope: TranslationScope.partial,
  ),
  TranslationInfo(
    id: 'WYCLIFFE',
    abbr: 'WYC',
    name: 'Wycliffe Bible (c.1395)',
    lang: 'en',
    url: '${_sm}Wycliffe.json',
  ),
  TranslationInfo(
    id: 'TWENTY',
    abbr: 'TCNT',
    name: 'Twentieth Century New Testament',
    lang: 'en',
    url: '${_sm}Twenty.json',
    scope: TranslationScope.newTestament,
  ),
  TranslationInfo(
    id: 'ANDERSON',
    abbr: 'AND',
    name: 'Anderson New Testament (1864)',
    lang: 'en',
    url: '${_sm}Anderson.json',
    scope: TranslationScope.newTestament,
  ),
  TranslationInfo(
    id: 'HAWEIS',
    abbr: 'HAW',
    name: 'Haweis New Testament (1795)',
    lang: 'en',
    url: '${_sm}Haweis.json',
    scope: TranslationScope.newTestament,
  ),
];

/// Online catalogue of free-to-use translations (HelloAO). Amharic / English /
/// Ge'ez entries from it are offered in the library in addition to the list
/// above.
const String kHelloAoTranslations =
    'https://bible.helloao.org/api/available_translations.json';
String helloAoComplete(String id) =>
    'https://bible.helloao.org/api/$id/complete.json';
