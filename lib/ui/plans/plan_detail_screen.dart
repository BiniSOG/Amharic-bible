import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../core/theme.dart';
import '../../data/plans.dart';
import '../../state/settings_controller.dart';
import '../../state/user_data_controller.dart';
import '../reader/reader_screen.dart';
import '../widgets/common.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.plan});
  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final prog = user.planProgress(plan.id);
    final cs = Theme.of(context).colorScheme;
    final c = Color(plan.color);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (prog != null)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'stop') user.stopPlan(plan.id);
                    if (v == 'restart') user.startPlan(plan.id);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'restart',
                      child: Text(l('restartPlan')),
                    ),
                    PopupMenuItem(value: 'stop', child: Text(l('stopPlan'))),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                plan.title(l.amharic),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c, Color.lerp(c, Colors.black, 0.4)!],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(plan.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    plan.desc(l.amharic),
                    style: const TextStyle(fontSize: 15.5, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.length} ${l('days')}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  if (prog == null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(l('startPlan')),
                      onPressed: () => user.startPlan(plan.id),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: prog.done.length / plan.length,
                        minHeight: 10,
                        color: c,
                        backgroundColor: c.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l('progress')}: ${prog.done.length}/${plan.length}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: plan.length,
            itemBuilder: (_, i) {
              final done = prog?.done.contains(i) ?? false;
              final isToday = prog != null && prog.nextIndex(plan.length) == i;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: done
                      ? c
                      : (isToday
                            ? c.withValues(alpha: 0.2)
                            : cs.surfaceContainerHigh),
                  foregroundColor: done ? Colors.white : cs.onSurface,
                  child: done ? const Icon(Icons.check) : Text('${i + 1}'),
                ),
                title: Text(
                  '${l('day')} ${i + 1}',
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  plan.days[i]
                      .map((p) => p.label(amharic: l.amharic))
                      .join(' · '),
                ),
                trailing: prog == null
                    ? null
                    : Checkbox(
                        value: done,
                        activeColor: c,
                        onChanged: (v) =>
                            user.setDayDone(plan.id, i, v ?? false),
                      ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlanDayScreen(plan: plan, day: i),
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

/// Shows the passages for one plan day as a checklist; each opens the reader.
class PlanDayScreen extends StatelessWidget {
  const PlanDayScreen({super.key, required this.plan, required this.day});
  final ReadingPlan plan;
  final int day;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final s = context.read<SettingsController>();
    final prog = user.planProgress(plan.id);
    final done = prog?.done.contains(day) ?? false;
    final c = Color(plan.color);
    final cs = Theme.of(context).colorScheme;
    final passages = plan.days[day];

    return Scaffold(
      appBar: AppBar(
        title: Text('${plan.title(l.amharic)} · ${l('day')} ${day + 1}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in passages)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(Icons.menu_book_rounded, color: c),
                title: Text(
                  p.label(amharic: l.amharic),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                subtitle: Text('${p.chapters.length} ${l('chapters')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      standalone: true,
                      initial: VerseRef(p.book, p.chapter, p.fromVerse ?? 1),
                      footerBuilder: (ctx, b, ch) {
                        final last = p.chapters.last;
                        if (b != p.book || ch != last || prog == null) {
                          return const SizedBox.shrink();
                        }
                        return _CompleteButton(plan: plan, day: day);
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (prog == null)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c),
              onPressed: () => user.startPlan(plan.id),
              child: Text(l('startPlan')),
            )
          else
            _CompleteButton(plan: plan, day: day),
          if (done)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  '🎉 ${l('completed')}',
                  style: TextStyle(
                    fontSize: 18,
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            s.uiAmharic
                ? 'ምክር፦ በምዕራፉ መጨረሻ «ቀኑን እንደጨረሱ ምልክት ያድርጉ» ይጫኑ።'
                : 'Tip: tap “Mark day complete” at the end of the reading.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.plan, required this.day});
  final ReadingPlan plan;
  final int day;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final done = user.planProgress(plan.id)?.done.contains(day) ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: done ? Brand.gold : Color(plan.color),
        ),
        icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
        label: Text(done ? l('completed') : l('markComplete')),
        onPressed: () {
          user.setDayDone(plan.id, day, !done);
          if (!done) {
            showSnack(context, '🎉 ${l('completed')} — ${l('day')} ${day + 1}');
          }
        },
      ),
    );
  }
}
