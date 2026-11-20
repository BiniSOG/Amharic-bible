import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/reference.dart';

class VerseNote {
  VerseNote(this.text, this.updated);
  final String text;
  final DateTime updated;

  Map<String, dynamic> toJson() => {
    't': text,
    'u': updated.millisecondsSinceEpoch,
  };
  factory VerseNote.fromJson(Map<String, dynamic> j) => VerseNote(
    j['t'] as String,
    DateTime.fromMillisecondsSinceEpoch(j['u'] as int),
  );
}

class PlanProgress {
  PlanProgress(this.start, this.done);
  final DateTime start;
  final Set<int> done;

  /// Zero-based index of the plan day matching today's date.
  int todayIndex(int length) {
    final now = DateTime.now();
    final d = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(start.year, start.month, start.day)).inDays;
    return d.clamp(0, length - 1);
  }

  /// First day not yet completed.
  int nextIndex(int length) {
    for (var i = 0; i < length; i++) {
      if (!done.contains(i)) return i;
    }
    return length - 1;
  }

  Map<String, dynamic> toJson() => {
    's': start.millisecondsSinceEpoch,
    'd': done.toList(),
  };
  factory PlanProgress.fromJson(Map<String, dynamic> j) => PlanProgress(
    DateTime.fromMillisecondsSinceEpoch(j['s'] as int),
    {for (final x in j['d'] as List) x as int},
  );
}

/// Highlights, bookmarks, notes, history, plans and reading streak.
/// Everything is stored locally on the device.
class UserDataController extends ChangeNotifier {
  UserDataController(this._p) {
    _highlights = _decodeMap(_p.getString('hl'))
        .map((k, v) => MapEntry(k, v as int));
    _bookmarks = _decodeMap(
      _p.getString('bm'),
    ).map((k, v) => MapEntry(k, DateTime.fromMillisecondsSinceEpoch(v as int)));
    _notes = _decodeMap(
      _p.getString('notes'),
    ).map((k, v) => MapEntry(k, VerseNote.fromJson(v as Map<String, dynamic>)));
    _plans = _decodeMap(_p.getString('plans')).map(
      (k, v) => MapEntry(k, PlanProgress.fromJson(v as Map<String, dynamic>)),
    );
    _history = (_p.getStringList('history') ?? []);
    _readDays = (_p.getStringList('readDays') ?? []).toSet();
    _storiesDone = (_p.getStringList('storiesDone') ?? []).toSet();
  }

  final SharedPreferences _p;
  late Map<String, int> _highlights;
  late Map<String, DateTime> _bookmarks;
  late Map<String, VerseNote> _notes;
  late Map<String, PlanProgress> _plans;
  late List<String> _history;
  late Set<String> _readDays;
  late Set<String> _storiesDone;

  static Map<String, dynamic> _decodeMap(String? s) {
    if (s == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {};
    }
  }

  // ---------- highlights ----------
  Map<String, int> get highlights => _highlights;
  int? highlightOf(VerseRef r) => _highlights[r.key];

  void setHighlight(Iterable<VerseRef> refs, int? color) {
    for (final r in refs) {
      if (color == null) {
        _highlights.remove(r.key);
      } else {
        _highlights[r.key] = color;
      }
    }
    _p.setString('hl', jsonEncode(_highlights));
    notifyListeners();
  }

  // ---------- bookmarks ----------
  Map<String, DateTime> get bookmarks => _bookmarks;
  bool isBookmarked(VerseRef r) => _bookmarks.containsKey(r.key);

  void toggleBookmark(Iterable<VerseRef> refs) {
    final all = refs.every(isBookmarked);
    for (final r in refs) {
      if (all) {
        _bookmarks.remove(r.key);
      } else {
        _bookmarks[r.key] = DateTime.now();
      }
    }
    _p.setString(
      'bm',
      jsonEncode(
        _bookmarks.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      ),
    );
    notifyListeners();
  }

  // ---------- notes ----------
  Map<String, VerseNote> get notes => _notes;
  VerseNote? noteOf(VerseRef r) => _notes[r.key];

  void setNote(VerseRef r, String text) {
    if (text.trim().isEmpty) {
      _notes.remove(r.key);
    } else {
      _notes[r.key] = VerseNote(text.trim(), DateTime.now());
    }
    _p.setString(
      'notes',
      jsonEncode(_notes.map((k, v) => MapEntry(k, v.toJson()))),
    );
    notifyListeners();
  }

  // ---------- history & streak ----------
  List<String> get history => _history;

  void recordChapter(int book, int chapter) {
    final key = '$book.$chapter';
    _history.remove(key);
    _history.insert(0, key);
    if (_history.length > 60) _history = _history.sublist(0, 60);
    _p.setStringList('history', _history);
    final today = _dayKey(DateTime.now());
    if (_readDays.add(today)) {
      _p.setStringList('readDays', _readDays.toList());
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    _p.setStringList('history', _history);
    notifyListeners();
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Consecutive days (ending today or yesterday) with some reading.
  int get streak {
    var d = DateTime.now();
    if (!_readDays.contains(_dayKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (_readDays.contains(_dayKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---------- plans ----------
  Map<String, PlanProgress> get plans => _plans;
  PlanProgress? planProgress(String id) => _plans[id];

  void startPlan(String id) {
    _plans[id] = PlanProgress(DateTime.now(), {});
    _savePlans();
  }

  void stopPlan(String id) {
    _plans.remove(id);
    _savePlans();
  }

  void setDayDone(String id, int day, bool done) {
    final p = _plans[id];
    if (p == null) return;
    if (done) {
      p.done.add(day);
      _readDays.add(_dayKey(DateTime.now()));
      _p.setStringList('readDays', _readDays.toList());
    } else {
      p.done.remove(day);
    }
    _savePlans();
  }

  void _savePlans() {
    _p.setString(
      'plans',
      jsonEncode(_plans.map((k, v) => MapEntry(k, v.toJson()))),
    );
    notifyListeners();
  }

  // ---------- kids ----------
  bool storyDone(String id) => _storiesDone.contains(id);
  void markStoryDone(String id) {
    if (_storiesDone.add(id)) {
      _p.setStringList('storiesDone', _storiesDone.toList());
      notifyListeners();
    }
  }

  int get storiesDoneCount => _storiesDone.length;
}
