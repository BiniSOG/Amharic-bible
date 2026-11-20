import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../data/stories.dart';
import '../../state/settings_controller.dart';
import '../../state/user_data_controller.dart';
import 'story_screen.dart';

class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key});

  @override
  State<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends State<KidsScreen> {
  late final Future<List<KidsStory>> _future = context
      .read<StoriesRepository>()
      .all();
  int _filter = 0; // 0 all, 1 OT, 2 NT

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final s = context.watch<SettingsController>();
    return Scaffold(
      body: FutureBuilder<List<KidsStory>>(
        future: _future,
        builder: (context, snap) {
          final all = snap.data ?? const <KidsStory>[];
          final stories = all
              .where(
                (x) => _filter == 0 || (x.isNewTestament == (_filter == 2)),
              )
              .toList();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 190,
                pinned: true,
                actions: [
                  TextButton(
                    onPressed: () => s.uiAmharic = !s.uiAmharic,
                    child: Text(
                      s.uiAmharic ? 'EN' : 'አማ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 14,
                  ),
                  title: Text(
                    l('kidsTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0E5A47),
                          Color(0xFF1B8A6B),
                          Color(0xFF2E9E7E),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l('kidsSubtitle'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFD54F),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user.storiesDoneCount}/${all.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text(l('all'))),
                      ButtonSegment(value: 1, label: Text(l('oldTestament'))),
                      ButtonSegment(value: 2, label: Text(l('newTestament'))),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (v) =>
                        setState(() => _filter = v.first),
                  ),
                ),
              ),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _StoryCard(
                      story: stories[i],
                      number: all.indexOf(stories[i]) + 1,
                      done: user.storyDone(stories[i].id),
                    ),
                    childCount: stories.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.number,
    required this.done,
  });
  final KidsStory story;
  final int number;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = Color(story.color);
    return Material(
      color: c.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => StoryScreen(story: story))),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.withValues(alpha: 0.85), c],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Hero(
                      tag: 'story-${story.id}',
                      child: Icon(story.icon, size: 56, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title(l.amharic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          story.passage.label(amharic: l.amharic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 10,
              top: 10,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: c,
                  ),
                ),
              ),
            ),
            if (done)
              const Positioned(
                right: 10,
                top: 8,
                child: Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: Color(0xFFFFD54F),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
