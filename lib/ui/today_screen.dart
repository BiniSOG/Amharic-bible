import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/books.dart';
import '../core/l10n.dart';
import '../core/reference.dart';
import '../core/theme.dart';
import '../data/bible.dart';
import '../data/bible_repository.dart';
import '../data/plans.dart';
import '../state/settings_controller.dart';
import '../state/user_data_controller.dart';
import 'dictionary_screen.dart';
import 'library_screen.dart';
import 'my_library_screen.dart';
import 'plans/plan_detail_screen.dart';
import 'reader/verse_image_screen.dart';
import 'search_screen.dart';
import 'widgets/common.dart';

/// Hand-picked verses for "Verse of the Day" (cycled by day of year).
const _votd = [
  '43.3.16',
  '24.29.11',
  '50.4.13',
  '45.8.28',
  '20.3.5',
  '23.41.10',
  '19.23.1',
  '40.11.28',
  '6.1.9',
  '50.4.6',
  '19.46.1',
  '45.12.2',
  '48.2.20',
  '58.11.1',
  '62.4.19',
  '46.13.4',
  '40.6.33',
  '43.14.6',
  '19.119.105',
  '23.40.31',
  '60.5.7',
  '49.2.8',
  '25.3.22',
  '19.37.4',
  '47.5.17',
  '43.16.33',
  '19.27.1',
  '33.6.8',
  '45.15.13',
  '51.3.23',
  '40.5.14',
  '19.91.1',
  '55.1.7',
  '20.18.10',
  '43.10.10',
  '45.5.8',
  '62.1.9',
  '58.13.5',
  '19.34.8',
  '43.8.12',
  '23.26.3',
  '47.12.9',
  '19.139.14',
  '40.28.20',
  '44.1.8',
  '49.6.10',
  '27.6.22',
  '19.121.1',
  '43.15.13',
  '52.5.16',
  '5.31.6',
  '50.4.19',
  '20.16.3',
  '45.10.9',
  '43.1.1',
  '19.103.12',
  '66.21.4',
  '23.53.5',
  '59.1.5',
  '19.100.4',
];

VerseRef verseOfTheDay([DateTime? d]) {
  final now = d ?? DateTime.now();
  final day = now.difference(DateTime(now.year)).inDays;
  return VerseRef.tryParseKey(_votd[(day + now.year) % _votd.length])!;
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = context.watch<SettingsController>();
    final user = context.watch<UserDataController>();
    final cs = Theme.of(context).colorScheme;
    final nav = context.read<AppNav>();
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? l('goodMorning')
        : hour < 18
        ? l('goodAfternoon')
        : l('goodEvening');
    final activePlans = kReadingPlans
        .where((p) => user.planProgress(p.id) != null)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(greet),
            actions: [
              if (user.streak > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: l('streak'),
                    child: Chip(
                      avatar: const Text('🔥'),
                      label: Text('${user.streak}'),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final r = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                  if (r is VerseRef) nav.openInBible(r);
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                BibleBuilder(
                  id: s.primary,
                  builder: (context, bible) =>
                      _VerseOfDayCard(bible: bible, ref: verseOfTheDay()),
                ),
                const SizedBox(height: 14),
                _ContinueCard(
                  ref: s.lastRef,
                  onTap: () => nav.openInBible(s.lastRef),
                ),
                if (activePlans.isNotEmpty) ...[
                  SectionHeader(l('todaysReading')),
                  for (final p in activePlans) _PlanTodayTile(plan: p),
                ],
                SectionHeader(l('quickAccess')),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _Tool(
                      Icons.local_library_outlined,
                      l('dictionary'),
                      cs.primary,
                      () => _push(context, const DictionaryScreen()),
                    ),
                    _Tool(
                      Icons.border_color_outlined,
                      l('highlights'),
                      Brand.gold,
                      () =>
                          _push(context, const MyLibraryScreen(initialTab: 0)),
                    ),
                    _Tool(
                      Icons.sticky_note_2_outlined,
                      l('notes'),
                      cs.tertiary,
                      () =>
                          _push(context, const MyLibraryScreen(initialTab: 2)),
                    ),
                    _Tool(
                      Icons.event_note_outlined,
                      l('plans'),
                      const Color(0xFF1565C0),
                      () => nav.setTab(2),
                    ),
                    _Tool(
                      Icons.child_care,
                      l('kids'),
                      const Color(0xFFE91E63),
                      () => nav.setTab(3),
                    ),
                    _Tool(
                      Icons.translate,
                      l('versions'),
                      const Color(0xFF6A1B9A),
                      () => _push(context, const LibraryScreen()),
                    ),
                  ],
                ),
                if (user.history.isNotEmpty) ...[
                  SectionHeader(l('history')),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final k in user.history.take(12))
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(() {
                                final p = k.split('.');
                                return '${bookAt(int.parse(p[0])).short(l.amharic)} ${p[1]}';
                              }()),
                              onPressed: () {
                                final p = k.split('.');
                                nav.openInBible(
                                  VerseRef(int.parse(p[0]), int.parse(p[1]), 1),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _push(BuildContext context, Widget w) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
}

class _VerseOfDayCard extends StatelessWidget {
  const _VerseOfDayCard({required this.bible, required this.ref});
  final Bible bible;
  final VerseRef ref;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final repo = context.watch<BibleRepository>();
    final text = bible.verseOrMerged(ref.book, ref.chapter, ref.verse);
    final kjv = bible.lang != 'en' ? repo.cached('KJV') : null;
    if (bible.lang != 'en' && kjv == null) repo.load('KJV');
    final label = '${ref.label(amharic: bible.isEthiopic)} · ${bible.abbr}';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E5A47), Color(0xFF14785F), Color(0xFF0A3D30)],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.read<AppNav>().openInBible(ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Brand.gold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l('verseOfDay'),
                      style: const TextStyle(
                        color: Brand.gold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: scriptureFont(bible.lang),
                    fontSize: 20,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                if (kjv != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    kjv.verse(ref.book, ref.chapter, ref.verse),
                    style: const TextStyle(
                      fontFamily: kSerifLatin,
                      fontSize: 14.5,
                      height: 1.45,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l('copy'),
                      color: Colors.white,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: '“$text”\n— $label'),
                        );
                        showSnack(context, l('copied'));
                      },
                    ),
                    IconButton(
                      tooltip: l('image'),
                      color: Colors.white,
                      icon: const Icon(Icons.image_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VerseImageScreen(
                            text: text,
                            reference: label,
                            lang: bible.lang,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l('share'),
                      color: Colors.white,
                      icon: const Icon(Icons.ios_share_rounded),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: '“$text”\n— $label'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.ref, required this.onTap});
  final VerseRef ref;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final b = bookAt(ref.book);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.auto_stories, color: cs.onPrimaryContainer),
        ),
        title: Text(
          l('continueReading'),
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        subtitle: Text(
          '${b.name(l.amharic)} ${ref.chapter}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _PlanTodayTile extends StatelessWidget {
  const _PlanTodayTile({required this.plan});
  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final prog = user.planProgress(plan.id)!;
    final day = prog.nextIndex(plan.length);
    final done = prog.done.length / plan.length;
    final passages = plan.days[day]
        .map((p) => p.label(amharic: l.amharic))
        .join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        leading: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: done,
                strokeWidth: 4,
                color: Color(plan.color),
              ),
              Text(plan.emoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
        title: Text(
          plan.title(l.amharic),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${l('day')} ${day + 1}: $passages',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.play_circle_fill),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlanDayScreen(plan: plan, day: day),
          ),
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
