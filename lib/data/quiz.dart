import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../core/reference.dart';

enum QuizLevel { easy, medium, hard, mixed }

class QuizItem {
  QuizItem(this.level, this.qEn, this.qAm, this.oEn, this.oAm, this.ref);

  /// 1 easy, 2 medium, 3 hard.
  final int level;
  final String qEn, qAm;

  /// Options with the correct answer first (shuffled when played).
  final List<String> oEn, oAm;
  final VerseRef ref;

  String q(bool am) => am ? qAm : qEn;
}

/// A question as presented: options in random order.
class QuizRoundItem {
  QuizRoundItem(this.item, this.order);
  final QuizItem item;

  /// order[i] = index into the original options (0 = correct).
  final List<int> order;

  int get correctIndex => order.indexOf(0);
  List<String> options(bool am) => [
    for (final i in order) (am ? item.oAm : item.oEn)[i],
  ];
}

class QuizRepository {
  List<QuizItem>? _items;

  Future<List<QuizItem>> all() async {
    if (_items != null) return _items!;
    final raw = await rootBundle.loadString('assets/data/quiz.json');
    _items = [
      for (final r in jsonDecode(raw) as List)
        QuizItem(
          r[0] as int,
          r[1] as String,
          r[2] as String,
          (r[3] as List).cast<String>(),
          (r[4] as List).cast<String>(),
          VerseRef.tryParseKey(r[5] as String)!,
        ),
    ];
    return _items!;
  }

  Future<int> count(QuizLevel level) async =>
      (await all()).where((q) => _matches(q, level)).length;

  static bool _matches(QuizItem q, QuizLevel l) =>
      l == QuizLevel.mixed || q.level == l.index + 1;

  Future<List<QuizRoundItem>> round(QuizLevel level, {int? size}) async {
    final rnd = Random();
    final pool = (await all()).where((q) => _matches(q, level)).toList()
      ..shuffle(rnd);
    final picked = size == null ? pool : pool.take(size).toList();
    return [
      for (final q in picked) QuizRoundItem(q, [0, 1, 2, 3]..shuffle(rnd)),
    ];
  }
}
