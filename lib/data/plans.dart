import '../core/books.dart';
import '../core/reference.dart';

/// A reading plan: a list of days, each with one or more passages.
class ReadingPlan {
  ReadingPlan({
    required this.id,
    required this.titleEn,
    required this.titleAm,
    required this.descEn,
    required this.descAm,
    required this.emoji,
    required this.color,
    required this.days,
    this.category = PlanCategory.wholeBible,
  });

  final String id;
  final String titleEn;
  final String titleAm;
  final String descEn;
  final String descAm;
  final String emoji;
  final int color;
  final List<List<Passage>> days;
  final PlanCategory category;

  String title(bool am) => am ? titleAm : titleEn;
  String desc(bool am) => am ? descAm : descEn;
  int get length => days.length;
}

enum PlanCategory { wholeBible, newTestament, topical, wisdom }

/// Splits a list of chapters into [days] near-equal daily portions.
List<List<Passage>> _spread(List<(int, int)> chapters, int days) {
  final out = <List<Passage>>[];
  for (var d = 0; d < days; d++) {
    final start = (chapters.length * d / days).floor();
    final end = (chapters.length * (d + 1) / days).floor();
    final slice = chapters.sublist(start, end);
    out.add(_merge(slice));
  }
  return out;
}

/// Merges consecutive chapters of the same book into one passage.
List<Passage> _merge(List<(int, int)> slice) {
  final res = <Passage>[];
  for (final (b, c) in slice) {
    if (res.isNotEmpty &&
        res.last.book == b &&
        (res.last.toChapter ?? res.last.chapter) == c - 1) {
      final last = res.removeLast();
      res.add(Passage(b, last.chapter, toChapter: c));
    } else {
      res.add(Passage(b, c));
    }
  }
  return res;
}

List<(int, int)> _chaptersOf(Iterable<int> books) => [
  for (final b in books)
    for (var c = 1; c <= bookAt(b).chapters; c++) (b, c),
];

Iterable<int> _range(int a, int b) sync* {
  for (var i = a; i <= b; i++) {
    yield i;
  }
}

List<Passage> _p(String s) => s.split(',').map((x) {
  final t = x.trim();
  return Passage.decode(t);
}).toList();

final List<ReadingPlan> kReadingPlans = _buildPlans();

List<ReadingPlan> _buildPlans() {
  // Old Testament (minus Psalms/Proverbs) + Psalms/Proverbs + New Testament
  // in parallel tracks – a balanced "through the Bible in a year" plan.
  final ot = _chaptersOf(_range(1, 39).where((b) => b != 19 && b != 20));
  final wisdom = _chaptersOf([19, 20]);
  final nt = _chaptersOf(_range(40, 66));
  final otDays = _spread(ot, 365);
  final wDays = _spread(wisdom, 365);
  final ntDays = _spread(nt, 365);
  final balanced = [
    for (var d = 0; d < 365; d++) [...otDays[d], ...wDays[d], ...ntDays[d]],
  ];

  return [
    ReadingPlan(
      id: 'year-balanced',
      titleEn: 'Bible in a Year',
      titleAm: 'መጽሐፍ ቅዱስን በአንድ ዓመት',
      descEn:
          'Read the whole Bible in 365 days: Old Testament, Psalms or '
          'Proverbs, and New Testament every day.',
      descAm:
          'በ365 ቀናት መጽሐፍ ቅዱስን በሙሉ ያንብቡ፤ በየቀኑ ከብሉይ ኪዳን፣ ከመዝሙር ወይም ከምሳሌ፣ '
          'እና ከሐዲስ ኪዳን።',
      emoji: '📖',
      color: 0xFF0E5A47,
      days: balanced,
    ),
    ReadingPlan(
      id: 'year-sequential',
      titleEn: 'Genesis to Revelation',
      titleAm: 'ከዘፍጥረት እስከ ራእይ',
      descEn:
          'Read straight through the Bible in one year, about 3–4 '
          'chapters a day.',
      descAm: 'በአንድ ዓመት ውስጥ መጽሐፍ ቅዱስን ከመጀመሪያ እስከ መጨረሻ፤ በቀን 3–4 ምዕራፎች።',
      emoji: '🗓️',
      color: 0xFF5D4037,
      days: _spread(_chaptersOf(_range(1, 66)), 365),
    ),
    ReadingPlan(
      id: 'nt-90',
      titleEn: 'New Testament in 90 Days',
      titleAm: 'ሐዲስ ኪዳንን በ90 ቀናት',
      descEn: 'Read all 260 chapters of the New Testament in three months.',
      descAm: 'የሐዲስ ኪዳንን 260 ምዕራፎች በሦስት ወር ያንብቡ።',
      emoji: '✝️',
      color: 0xFF1565C0,
      category: PlanCategory.newTestament,
      days: _spread(nt, 90),
    ),
    ReadingPlan(
      id: 'gospels-30',
      titleEn: 'The Four Gospels in 30 Days',
      titleAm: 'አራቱ ወንጌላት በ30 ቀናት',
      descEn: 'Walk with Jesus through Matthew, Mark, Luke and John.',
      descAm: 'በማቴዎስ፣ በማርቆስ፣ በሉቃስና በዮሐንስ ወንጌል ከኢየሱስ ጋር ይጓዙ።',
      emoji: '🕊️',
      color: 0xFF6A1B9A,
      category: PlanCategory.newTestament,
      days: _spread(_chaptersOf(_range(40, 43)), 30),
    ),
    ReadingPlan(
      id: 'psalms-proverbs',
      titleEn: 'Psalms & Proverbs in 60 Days',
      titleAm: 'መዝሙረ ዳዊትና ምሳሌ በ60 ቀናት',
      descEn: 'Prayer, praise and wisdom for everyday life.',
      descAm: 'ለዕለት ተዕለት ሕይወት ጸሎት፣ ምስጋናና ጥበብ።',
      emoji: '🎵',
      color: 0xFFC9962B,
      category: PlanCategory.wisdom,
      days: [
        for (var d = 0; d < 60; d++)
          [
            ..._spread(_chaptersOf([19]), 60)[d],
            if (d < 31) Passage(20, d + 1),
          ],
      ],
    ),
    ReadingPlan(
      id: 'proverbs-month',
      titleEn: 'Proverbs in a Month',
      titleAm: 'ምሳሌን በአንድ ወር',
      descEn: 'One chapter of wisdom for each day of the month.',
      descAm: 'ለወሩ እያንዳንዱ ቀን አንድ የጥበብ ምዕራፍ።',
      emoji: '💡',
      color: 0xFFEF6C00,
      category: PlanCategory.wisdom,
      days: [
        for (var c = 1; c <= 31; c++) [Passage(20, c)],
      ],
    ),
    ReadingPlan(
      id: 'new-believer',
      titleEn: 'First Steps with Jesus',
      titleAm: 'ከኢየሱስ ጋር የመጀመሪያ እርምጃዎች',
      descEn:
          'A 21-day foundation for new believers: who Jesus is, '
          'salvation, prayer, the Holy Spirit and the church.',
      descAm:
          'ለአዲስ አማኞች የ21 ቀን መሠረት፦ ኢየሱስ ማን ነው፣ ድኅነት፣ ጸሎት፣ መንፈስ ቅዱስና '
          'ቤተ ክርስቲያን።',
      emoji: '🌱',
      color: 0xFF2E7D32,
      category: PlanCategory.topical,
      days: [
        for (final d in const [
          '43.1',
          '43.3',
          '45.3',
          '45.5',
          '45.8',
          '49.2',
          '42.15',
          '40.5',
          '40.6',
          '40.7',
          '43.14',
          '43.15',
          '44.2',
          '46.13',
          '48.5',
          '58.11',
          '59.1',
          '62.1',
          '50.4',
          '19.23',
          '66.21',
        ])
          _p(d),
      ],
    ),
    ReadingPlan(
      id: 'peace-anxiety',
      titleEn: 'Peace in Anxious Times',
      titleAm: 'በጭንቀት ጊዜ ሰላም',
      descEn: 'Seven days of God\'s promises for worried hearts.',
      descAm: 'ለተጨነቀ ልብ የሰባት ቀን የእግዚአብሔር ተስፋዎች።',
      emoji: '🌤️',
      color: 0xFF00838F,
      category: PlanCategory.topical,
      days: [
        _p('50.4:4-9, 60.5:6-11'),
        _p('40.6:25-34'),
        _p('19.23, 19.46'),
        _p('23.41:10-13, 23.43:1-3'),
        _p('43.14:1-27'),
        _p('45.8:28-39'),
        _p('19.121, 19.91'),
      ],
    ),
    ReadingPlan(
      id: 'love',
      titleEn: 'The Love of God',
      titleAm: 'የእግዚአብሔር ፍቅር',
      descEn:
          'Ten days exploring how deeply God loves us — and how we can '
          'love others.',
      descAm:
          'እግዚአብሔር ምን ያህል እንደሚወደንና እኛም ሌሎችን እንዴት መውደድ እንደምንችል የሚያሳይ '
          'የአሥር ቀን ጥናት።',
      emoji: '❤️',
      color: 0xFFC62828,
      category: PlanCategory.topical,
      days: [
        _p('43.3:1-21'),
        _p('62.4:7-21'),
        _p('46.13'),
        _p('45.5:1-11'),
        _p('49.3:14-21'),
        _p('42.15'),
        _p('43.13:1-17, 43.13:34-35'),
        _p('40.22:34-40'),
        _p('22.8:6-7, 25.3:21-26'),
        _p('45.8:31-39'),
      ],
    ),
    ReadingPlan(
      id: 'prayer',
      titleEn: 'Learning to Pray',
      titleAm: 'መጸለይን መማር',
      descEn: 'Learn from Jesus and the great prayers of the Bible.',
      descAm: 'ከኢየሱስና በመጽሐፍ ቅዱስ ካሉ ታላላቅ ጸሎቶች ይማሩ።',
      emoji: '🙏',
      color: 0xFF4527A0,
      category: PlanCategory.topical,
      days: [
        _p('40.6:5-15'),
        _p('42.11:1-13'),
        _p('43.17'),
        _p('19.51'),
        _p('27.9:1-19'),
        _p('16.1'),
        _p('49.3:14-21, 51.1:9-14'),
        _p('59.5:13-18'),
        _p('9.1:9-28'),
        _p('42.18:1-14'),
      ],
    ),
    ReadingPlan(
      id: 'lent-easter',
      titleEn: 'The Road to the Cross',
      titleAm: 'ወደ መስቀሉ የሚወስደው መንገድ',
      descEn:
          'Fourteen days through the last week of Jesus — ideal for '
          'Hudade / Lent and Easter (Fasika).',
      descAm: 'በኢየሱስ የመጨረሻ ሳምንት የ14 ቀን ጉዞ — ለሁዳዴ ጾምና ለፋሲካ ተስማሚ።',
      emoji: '🌿',
      color: 0xFF6D4C41,
      category: PlanCategory.topical,
      days: [
        _p('23.53'),
        _p('40.21:1-17'),
        _p('43.12:12-36'),
        _p('40.26:1-30'),
        _p('43.13'),
        _p('43.14'),
        _p('43.17'),
        _p('40.26:36-75'),
        _p('40.27:1-31'),
        _p('42.23:26-56'),
        _p('43.19'),
        _p('42.24:1-35'),
        _p('43.20'),
        _p('46.15:1-28'),
      ],
    ),
  ];
}

/// Rough number of chapters/sections in a day (for UI).
int dayWeight(List<Passage> day) =>
    day.fold(0, (s, p) => s + p.chapters.length);
