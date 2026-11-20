import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/quiz.dart';
import '../../state/settings_controller.dart';
import '../../state/user_data_controller.dart';
import '../reader/reader_screen.dart';
import '../widgets/common.dart';

const _levelColors = {
  QuizLevel.easy: Color(0xFF2E7D32),
  QuizLevel.medium: Color(0xFFC77C02),
  QuizLevel.hard: Color(0xFFB3261E),
  QuizLevel.mixed: Color(0xFF0E5A47),
};

const _levelIcons = {
  QuizLevel.easy: Icons.looks_one_rounded,
  QuizLevel.medium: Icons.looks_two_rounded,
  QuizLevel.hard: Icons.looks_3_rounded,
  QuizLevel.mixed: Icons.shuffle_rounded,
};

String levelLabel(L l, QuizLevel v) => switch (v) {
  QuizLevel.easy => l('easy'),
  QuizLevel.medium => l('medium'),
  QuizLevel.hard => l('hard'),
  QuizLevel.mixed => l('mixed'),
};

/// Home of the adult Bible quiz: pick a difficulty and round length.
class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  final _repo = QuizRepository();
  bool _timer = false;
  Map<QuizLevel, int> _counts = {};

  @override
  void initState() {
    super.initState();
    () async {
      final m = <QuizLevel, int>{};
      for (final v in QuizLevel.values) {
        m[v] = await _repo.count(v);
      }
      if (mounted) setState(() => _counts = m);
    }();
  }

  Future<void> _start(QuizLevel level, bool quick) async {
    final round = await _repo.round(level, size: quick ? 10 : null);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuizPlayScreen(level: level, items: round, timed: _timer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final cs = Theme.of(context).colorScheme;
    final acc = user.quizAnswered == 0
        ? 0
        : (user.quizCorrect * 100 / user.quizAnswered).round();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l('bibleQuiz'))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                Text(
                  l('quizSubtitle'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.task_alt_rounded,
                      value: '${user.quizAnswered}',
                      label: l('answered'),
                    ),
                    const SizedBox(width: 12),
                    _Stat(
                      icon: Icons.insights_rounded,
                      value: '$acc%',
                      label: l('accuracy'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.timer_outlined),
                  title: Text(l('timer')),
                  value: _timer,
                  onChanged: (v) => setState(() => _timer = v),
                ),
                const SizedBox(height: 4),
                for (final level in QuizLevel.values)
                  _LevelCard(
                    level: level,
                    count: _counts[level] ?? 0,
                    best: user.bestScore(level.name),
                    onQuick: () => _start(level, true),
                    onAll: () => _start(level, false),
                  ),
                SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.count,
    required this.best,
    required this.onQuick,
    required this.onAll,
  });
  final QuizLevel level;
  final int count;
  final int best;
  final VoidCallback onQuick;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = _levelColors[level]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_levelIcons[level], color: c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelLabel(l, level),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text('$count ${l('questions')}'),
                    ],
                  ),
                ),
                if (best >= 0)
                  Chip(
                    avatar: Icon(
                      Icons.emoji_events_outlined,
                      size: 18,
                      color: c,
                    ),
                    label: Text('${l('bestScore')} $best%'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: c,
                    ),
                    onPressed: onQuick,
                    child: Text(l('quickRound')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAll,
                    child: Text(l('fullRound')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Plays one round.
class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({
    super.key,
    required this.level,
    required this.items,
    this.timed = false,
  });
  final QuizLevel level;
  final List<QuizRoundItem> items;
  final bool timed;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  static const _seconds = 20;
  int _i = 0;
  final Map<int, int> _picked =
      {}; // question index -> option index (-1 timeout)
  Timer? _timer;
  int _left = _seconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!widget.timed) return;
    _left = _seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        setState(() => _picked[_i] = -1);
      }
    });
  }

  void _pick(int o) {
    if (_picked.containsKey(_i)) return;
    _timer?.cancel();
    final ok = o == widget.items[_i].correctIndex;
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() => _picked[_i] = o);
  }

  void _next() {
    if (_i + 1 >= widget.items.length) {
      final correct = _picked.entries
          .where((e) => e.value == widget.items[e.key].correctIndex)
          .length;
      context.read<UserDataController>().recordQuiz(
        widget.level.name,
        correct,
        widget.items.length,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            level: widget.level,
            items: widget.items,
            picked: Map.of(_picked),
            timed: widget.timed,
          ),
        ),
      );
      return;
    }
    setState(() => _i++);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final am = l.amharic;
    final cs = Theme.of(context).colorScheme;
    final item = widget.items[_i];
    final picked = _picked[_i];
    final answered = picked != null;
    final c = _levelColors[widget.level]!;
    final s = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${l('question')} ${_i + 1}/${widget.items.length}'),
        actions: [
          if (widget.timed && !answered)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '0:${_left.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: _left <= 5 ? cs.error : cs.onSurface,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_i + (answered ? 1 : 0)) / widget.items.length,
            color: c,
            backgroundColor: c.withValues(alpha: 0.15),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Icon(_levelIcons[widget.level], size: 18, color: c),
                      const SizedBox(width: 6),
                      Text(
                        levelLabel(l, widget.level),
                        style: TextStyle(color: c, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.item.q(am),
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var o = 0; o < 4; o++)
                    _OptionTile(
                      letter: String.fromCharCode(65 + o),
                      text: item.options(am)[o],
                      state: !answered
                          ? _OptState.idle
                          : o == item.correctIndex
                          ? _OptState.correct
                          : o == picked
                          ? _OptState.wrong
                          : _OptState.dim,
                      onTap: () => _pick(o),
                    ),
                  if (answered) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          picked == item.correctIndex
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: picked == item.correctIndex
                              ? Colors.green.shade600
                              : cs.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          picked == -1
                              ? l('timeUp')
                              : picked == item.correctIndex
                              ? l('correct')
                              : l('wrong'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _VerseExplanation(item: item.item, primary: s.primary),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: c,
                ),
                onPressed: answered ? _next : null,
                child: Text(
                  _i + 1 >= widget.items.length ? l('finish') : l('next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });
  final String letter;
  final String text;
  final _OptState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final green = Colors.green.shade600;
    final (bg, border, fg) = switch (state) {
      _OptState.idle => (cs.surfaceContainer, cs.outlineVariant, cs.onSurface),
      _OptState.correct => (green.withValues(alpha: 0.15), green, cs.onSurface),
      _OptState.wrong => (
        cs.error.withValues(alpha: 0.12),
        cs.error,
        cs.onSurface,
      ),
      _OptState.dim => (
        cs.surfaceContainer,
        cs.outlineVariant,
        cs.onSurface.withValues(alpha: 0.5),
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state == _OptState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: border.withValues(alpha: 0.2),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (state == _OptState.correct)
                  Icon(Icons.check_rounded, color: green),
                if (state == _OptState.wrong)
                  Icon(Icons.close_rounded, color: cs.error),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the Bible verse behind the answer.
class _VerseExplanation extends StatelessWidget {
  const _VerseExplanation({required this.item, required this.primary});
  final QuizItem item;
  final String primary;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final r = item.ref;
    return BibleBuilder(
      id: primary,
      builder: (context, bible) => Card(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReaderScreen(standalone: true, initial: r),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.label(amharic: bible.isEthiopic || l.amharic),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: cs.outline),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bible.verseOrMerged(r.book, r.chapter, r.verse),
                  style: TextStyle(
                    fontFamily: scriptureFont(bible.lang),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.level,
    required this.items,
    required this.picked,
    required this.timed,
  });
  final QuizLevel level;
  final List<QuizRoundItem> items;
  final Map<int, int> picked;
  final bool timed;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final am = l.amharic;
    final cs = Theme.of(context).colorScheme;
    final correct = [
      for (var i = 0; i < items.length; i++)
        if (picked[i] == items[i].correctIndex) i,
    ].length;
    final pct = items.isEmpty ? 0 : correct / items.length;
    final c = _levelColors[level]!;
    final msg = pct >= 0.8
        ? l('excellent')
        : pct >= 0.5
        ? l('goodJob')
        : l('keepLearning');

    return Scaffold(
      appBar: AppBar(title: Text(l('yourScore'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: pct.toDouble(),
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    color: c,
                    backgroundColor: c.withValues(alpha: 0.15),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$correct/${items.length}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: c,
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l('playAgain')),
                  onPressed: () async {
                    final round = await QuizRepository().round(
                      level,
                      size: items.length,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QuizPlayScreen(
                          level: level,
                          items: round,
                          timed: timed,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SectionHeader(l('review')),
          for (var i = 0; i < items.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  picked[i] == items[i].correctIndex
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: picked[i] == items[i].correctIndex
                      ? Colors.green.shade600
                      : cs.error,
                ),
                title: Text(items[i].item.q(am)),
                subtitle: Text(
                  '${l('correctAnswer')}: ${items[i].options(am)[items[i].correctIndex]} · '
                  '${items[i].item.ref.label(amharic: am, short: true)}',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      standalone: true,
                      initial: items[i].item.ref,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
