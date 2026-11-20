import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../core/theme.dart';
import '../../data/stories.dart';
import '../../data/tts_service.dart';
import '../../state/settings_controller.dart';
import '../../state/user_data_controller.dart';
import '../reader/reader_screen.dart';
import '../widgets/common.dart';

/// A children's story told page by page, then lesson, memory verse, quiz and
/// prayer.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key, required this.story});
  final KidsStory story;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final story = widget.story;
    final am = l.amharic;
    final c = Color(story.color);
    final paras = story.paragraphs(am);
    final total = paras.length + 2; // story pages + lesson/verse + quiz/prayer
    final tts = context.watch<TtsService>();

    return Scaffold(
      backgroundColor: Color.alphaBlend(
        c.withValues(alpha: 0.08),
        Theme.of(context).colorScheme.surface,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(story.title(am), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l('readAloud'),
            icon: Icon(
              tts.speaking ? Icons.stop_circle : Icons.volume_up_rounded,
            ),
            onPressed: () async {
              if (tts.speaking) {
                tts.stop();
                return;
              }
              final text = _page < paras.length
                  ? paras[_page]
                  : story.lesson(am);
              final ok = await tts.speak(text, am ? 'am' : 'en');
              if (!ok && context.mounted) {
                // Fall back to English voice when Amharic TTS is missing.
                if (am) {
                  await tts.speak(
                    _page < story.en.length ? story.en[_page] : story.lessonEn,
                    'en',
                  );
                } else {
                  showSnack(context, l('ttsUnavailable'));
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (var i = 0; i < total; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _page ? c : c.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) {
                context.read<TtsService>().stop();
                setState(() => _page = i);
                if (i == total - 1) {
                  context.read<UserDataController>().markStoryDone(story.id);
                }
              },
              children: [
                for (var i = 0; i < paras.length; i++)
                  _StoryPage(
                    emoji: story.emoji,
                    heroTag: i == 0 ? 'story-${story.id}' : null,
                    color: c,
                    text: paras[i],
                  ),
                _LessonPage(story: story),
                _QuizPage(story: story),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton.filledTonal(
                      iconSize: 30,
                      onPressed: () => _pages.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  const Spacer(),
                  if (_page < total - 1)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => _pages.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      iconAlignment: IconAlignment.end,
                      label: Text(am ? 'ቀጥል' : 'Next'),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            standalone: true,
                            initial: VerseRef(
                              story.passage.book,
                              story.passage.chapter,
                              story.passage.fromVerse ?? 1,
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(l('readInBible')),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.emoji,
    required this.color,
    required this.text,
    this.heroTag,
  });
  final String emoji;
  final Color color;
  final String text;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final emojiWidget = Text(emoji, style: const TextStyle(fontSize: 96));
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          alignment: Alignment.center,
          child: heroTag != null
              ? Hero(tag: heroTag!, child: emojiWidget)
              : emojiWidget,
        ),
        const SizedBox(height: 28),
        Text(
          text,
          style: TextStyle(
            fontFamily: s.uiAmharic ? kSansEthiopic : null,
            fontSize: 22 * s.fontScale.clamp(0.9, 1.4),
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LessonPage extends StatelessWidget {
  const _LessonPage({required this.story});
  final KidsStory story;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = Color(story.color);
    final s = context.watch<SettingsController>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Bubble(
          color: c,
          icon: '💡',
          title: l('lesson'),
          child: Text(
            story.lesson(l.amharic),
            style: const TextStyle(
              fontSize: 20,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Bubble(
          color: Brand.gold,
          icon: '📖',
          title: l('memoryVerse'),
          child: BibleBuilder(
            id: l.amharic ? 'AM1954' : 'KJV',
            builder: (context, bible) {
              final r = story.memoryVerse;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“${bible.verseOrMerged(r.book, r.chapter, r.verse)}”',
                    style: TextStyle(
                      fontFamily: scriptureFont(bible.lang),
                      fontSize: 19 * s.fontScale.clamp(0.9, 1.3),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.label(amharic: l.amharic),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuizPage extends StatefulWidget {
  const _QuizPage({required this.story});
  final KidsStory story;

  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  final Map<int, int> _answers = {};

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final am = l.amharic;
    final c = Color(widget.story.color);
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '🧩 ${l('quiz')}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (var qi = 0; qi < widget.story.quiz.length; qi++) ...[
          Text(
            widget.story.quiz[qi].q(am),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (var oi = 0; oi < widget.story.quiz[qi].options(am).length; oi++)
            Builder(
              builder: (_) {
                final q = widget.story.quiz[qi];
                final picked = _answers[qi];
                final isPicked = picked == oi;
                final correct = q.answer == oi;
                final color = picked == null
                    ? cs.surfaceContainerHigh
                    : isPicked
                    ? (correct ? Colors.green.shade400 : Colors.red.shade300)
                    : (correct && picked != q.answer
                          ? cs.surfaceContainerHigh
                          : cs.surfaceContainerHigh);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _answers[qi] = oi),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                q.options(am)[oi],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isPicked)
                              Text(
                                correct ? '✅' : '❌',
                                style: const TextStyle(fontSize: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_answers[qi] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _answers[qi] == widget.story.quiz[qi].answer
                    ? '🎉 ${l('correct')}'
                    : '🤔 ${l('tryAgain')}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: c,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        _Bubble(
          color: const Color(0xFF7E57C2),
          icon: '🙏',
          title: l('prayer'),
          child: Text(
            widget.story.prayer(am),
            style: const TextStyle(
              fontSize: 19,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
  });
  final Color color;
  final String icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$icon  $title',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
