import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../data/plans.dart';
import '../../state/user_data_controller.dart';
import '../widgets/common.dart';
import 'plan_detail_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final mine = kReadingPlans
        .where((p) => user.planProgress(p.id) != null)
        .toList();
    final others = kReadingPlans
        .where((p) => user.planProgress(p.id) == null)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l('readingPlans'))),
          if (mine.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeader(l('myPlans'))),
            SliverList.list(
              children: [for (final p in mine) _ActivePlanCard(plan: p)],
            ),
          ],
          SliverToBoxAdapter(child: SectionHeader(l('discoverPlans'))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PlanCard(plan: others[i]),
                childCount: others.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = Color(plan.color);
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      color: c.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 86,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c, Color.lerp(c, Colors.black, 0.3)!],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(plan.icon, size: 44, color: Colors.white),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title(l.amharic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        plan.desc(l.amharic),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${plan.length} ${l('days')}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: c),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.plan});
  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final prog = user.planProgress(plan.id)!;
    final next = prog.nextIndex(plan.length);
    final today = prog.todayIndex(plan.length);
    final behind = (today - prog.done.where((d) => d <= today).length + 1)
        .clamp(0, plan.length);
    final pct = prog.done.length / plan.length;
    final c = Color(plan.color);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
          ),
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
                      child: Icon(plan.icon, color: c),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title(l.amharic),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            behind > 1
                                ? '${behind - 1} ${l('behind')}'
                                : l('onTrack'),
                            style: TextStyle(
                              fontSize: 12,
                              color: behind > 1
                                  ? Theme.of(context).colorScheme.error
                                  : c,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: TextStyle(fontWeight: FontWeight.w800, color: c),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    color: c,
                    backgroundColor: c.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: c,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('${l('day')} ${next + 1} · ${l('read')}'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlanDayScreen(plan: plan, day: next),
                    ),
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
