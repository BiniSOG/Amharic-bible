import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

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
  final int color;
  final bool isNewTestament;
  final String titleEn, titleAm;
  final Passage passage;
  final VerseRef memoryVerse;
  final List<String> en, am;
  final String lessonEn, lessonAm;
  final List<QuizQuestion> quiz;
  final String prayerEn, prayerAm;

  /// Illustration icon for the story card.
  IconData get icon => _storyIcons[id] ?? Icons.auto_stories_rounded;

  String title(bool a) => a ? titleAm : titleEn;
  List<String> paragraphs(bool a) => a ? am : en;
  String lesson(bool a) => a ? lessonAm : lessonEn;
  String prayer(bool a) => a ? prayerAm : prayerEn;

  factory KidsStory.fromJson(Map<String, dynamic> j) => KidsStory(
    id: j['id'] as String,
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

const Map<String, IconData> _storyIcons = {
  'creation': Icons.public_rounded,
  'eden': Icons.park_rounded,
  'noah': Icons.sailing_rounded,
  'abraham': Icons.auto_awesome_rounded,
  'joseph': Icons.checkroom_rounded,
  'moses-baby': Icons.shopping_basket_rounded,
  'red-sea': Icons.waves_rounded,
  'ten-commandments': Icons.gavel_rounded,
  'jericho': Icons.campaign_rounded,
  'samuel': Icons.hearing_rounded,
  'david-goliath': Icons.shield_rounded,
  'daniel': Icons.pets_rounded,
  'jonah': Icons.phishing_rounded,
  'esther': Icons.diamond_rounded,
  'jesus-born': Icons.star_rounded,
  'boy-jesus': Icons.account_balance_rounded,
  'fishermen': Icons.set_meal_rounded,
  'storm': Icons.thunderstorm_rounded,
  'loaves': Icons.bakery_dining_rounded,
  'good-samaritan': Icons.healing_rounded,
  'lost-son': Icons.home_rounded,
  'zacchaeus': Icons.forest_rounded,
  'children': Icons.family_restroom_rounded,
  'easter': Icons.wb_twilight_rounded,
  'pentecost': Icons.local_fire_department_rounded,
  'ethiopian': Icons.water_drop_rounded,
};
