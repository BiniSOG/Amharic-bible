import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/reference.dart';

class QuizQuestion {
  QuizQuestion(this.qEn, this.qAm, this.oEn, this.oAm, this.answer);
  final String qEn, qAm;
  final List<String> oEn, oAm;
  final int answer;
  String q(bool am) => am ? qAm : qEn;
  List<String> options(bool am) => am ? oAm : oEn;
}

class KidsStory {
  KidsStory({
    required this.id,
    required this.emoji,
    required this.color,
    required this.isNewTestament,
    required this.titleEn,
    required this.titleAm,
    required this.passage,
    required this.memoryVerse,
    required this.en,
    required this.am,
    required this.lessonEn,
    required this.lessonAm,
    required this.quiz,
    required this.prayerEn,
    required this.prayerAm,
  });

  final String id;
  final String emoji;
  final int color;
  final bool isNewTestament;
  final String titleEn, titleAm;
  final Passage passage;
  final VerseRef memoryVerse;
  final List<String> en, am;
  final String lessonEn, lessonAm;
  final List<QuizQuestion> quiz;
  final String prayerEn, prayerAm;

  String title(bool a) => a ? titleAm : titleEn;
  List<String> paragraphs(bool a) => a ? am : en;
  String lesson(bool a) => a ? lessonAm : lessonEn;
  String prayer(bool a) => a ? prayerAm : prayerEn;

  factory KidsStory.fromJson(Map<String, dynamic> j) => KidsStory(
    id: j['id'] as String,
    emoji: j['emoji'] as String,
    color: int.parse(j['color'] as String),
    isNewTestament: j['section'] == 'nt',
    titleEn: j['title_en'] as String,
    titleAm: j['title_am'] as String,
    passage: Passage.decode(j['passage'] as String),
    memoryVerse: VerseRef.tryParseKey(j['memory'] as String)!,
    en: (j['en'] as List).cast<String>(),
    am: (j['am'] as List).cast<String>(),
    lessonEn: j['lesson_en'] as String,
    lessonAm: j['lesson_am'] as String,
    quiz: [
      for (final q in j['quiz'] as List)
        QuizQuestion(
          q['q_en'] as String,
          q['q_am'] as String,
          (q['o_en'] as List).cast<String>(),
          (q['o_am'] as List).cast<String>(),
          q['a'] as int,
        ),
    ],
    prayerEn: j['prayer_en'] as String,
    prayerAm: j['prayer_am'] as String,
  );
}

class StoriesRepository {
  List<KidsStory>? _stories;

  Future<List<KidsStory>> all() async {
    if (_stories != null) return _stories!;
    final raw = await rootBundle.loadString('assets/data/stories.json');
    _stories = [
      for (final s in jsonDecode(raw) as List)
        KidsStory.fromJson(s as Map<String, dynamic>),
    ];
    return _stories!;
  }
}
