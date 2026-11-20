import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/books.dart';
import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../core/theme.dart';
import '../../data/bible.dart';
import '../../data/bible_repository.dart';
import '../../data/commentary_service.dart';
import '../../data/translation_catalog.dart';
import '../../data/study_data.dart';
import '../../state/settings_controller.dart';
import '../../state/user_data_controller.dart';
import '../dictionary_screen.dart';
import '../library_screen.dart';
import '../strongs_screen.dart';
import '../../data/strongs_service.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';

enum StudyTab { commentary, crossRefs, strongs, compare, words }

// ---------------------------------------------------------------------------
// Version picker
// ---------------------------------------------------------------------------

Future<void> showVersionPicker(BuildContext context, {bool parallel = false}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final l = L.of(ctx);
      final s = ctx.watch<SettingsController>();
      final repo = ctx.watch<BibleRepository>();
      final current = parallel ? s.parallel : s.primary;
      final groups = <String, List<TranslationInfo>>{};
      for (final t in repo.installed) {
        if (parallel && t.id == s.primary) continue;
        groups.putIfAbsent(t.lang, () => []).add(t);
      }
      final langs = groups.keys.toList()
        ..sort((a, b) => langOrder(a).compareTo(langOrder(b)));
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                parallel ? l('secondVersion') : l('chooseVersion'),
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (parallel)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: ParallelLayoutSelector(),
              ),
            if (parallel)
              _VersionTile(
                selected: current == null,
                title: l('parallelOff'),
                subtitle: '',
                onTap: () {
                  s.parallel = null;
                  Navigator.pop(ctx);
                },
              ),
            for (final lang in langs)
              if (groups[lang] != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Text(
                    bibleLangName(lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ),
                for (final t in groups[lang]!)
                  _VersionTile(
                    selected: current == t.id,
                    title: t.name,
                    subtitle: t.abbr,
                    onTap: () {
                      if (parallel) {
                        s.parallel = t.id;
                        repo.load(t.id);
                      } else {
                        s.primary = t.id;
                      }
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: Text(l('library')),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? cs.primary : cs.outline,
      ),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      onTap: onTap,
    );
  }
}

/// Choose how a second version is shown: line by line or in two columns.
class ParallelLayoutSelector extends StatelessWidget {
  const ParallelLayoutSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final l = L.of(context);
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.view_agenda_outlined),
          label: Text(l('layoutStacked')),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.view_column_outlined),
          label: Text(l('layoutColumns')),
        ),
      ],
      selected: {s.sideBySide},
      onSelectionChanged: (v) => s.sideBySide = v.first,
    );
  }
}

// ---------------------------------------------------------------------------
// Text settings
// ---------------------------------------------------------------------------

Future<void> showTextSettings(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.paddingOf(ctx).bottom,
      ),
      child: const SingleChildScrollView(child: TextSettingsPanel()),
    ),
  );
}

class TextSettingsPanel extends StatelessWidget {
  const TextSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    Widget themeDot(ReaderTheme t, Color bg, Color fg, String label) {
      final sel = s.theme == t;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => s.theme = t,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? cs.primary : cs.outlineVariant,
                width: sel ? 2.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Aa አ',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
                Text(label, style: TextStyle(color: fg, fontSize: 11)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l('theme'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            themeDot(
              ReaderTheme.light,
              Colors.white,
              Colors.black87,
              l('light'),
            ),
            themeDot(
              ReaderTheme.sepia,
              Brand.parchment,
              Brand.sepiaText,
              l('sepia'),
            ),
            themeDot(
              ReaderTheme.dark,
              const Color(0xFF1B1B1F),
              Colors.white,
              l('dark'),
            ),
            themeDot(
              ReaderTheme.system,
              cs.surfaceContainerHigh,
              cs.onSurface,
              l('system'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              l('fontSize'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text('${(s.fontScale * 100).round()}%'),
          ],
        ),
        Row(
          children: [
            const Text('A', style: TextStyle(fontSize: 14)),
            Expanded(
              child: Slider(
                value: s.fontScale,
                min: 0.7,
                max: 2.2,
                divisions: 15,
                onChanged: (v) => s.fontScale = v,
              ),
            ),
            const Text('A', style: TextStyle(fontSize: 26)),
          ],
        ),
        Text(
          l('lineHeight'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: s.lineHeight,
          min: 1.2,
          max: 2.4,
          divisions: 12,
          onChanged: (v) => s.lineHeight = v,
        ),
        Text(
          l('parallelLayout'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const ParallelLayoutSelector(),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l('verseNumbers')),
          value: s.showVerseNumbers,
          onChanged: (v) => s.showVerseNumbers = v,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l('redLetters')),
          value: s.paragraphMode,
          onChanged: (v) => s.paragraphMode = v,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l('ethiopicNumerals')),
          subtitle: const Text('፩ ፪ ፫ ፬ ፭'),
          value: s.ethiopicNumerals,
          onChanged: (v) => s.ethiopicNumerals = v,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Study sheet
// ---------------------------------------------------------------------------

Future<void> showStudySheet(
  BuildContext context, {
  required Bible bible,
  required int book,
  required int chapter,
  required List<int> verses,
  StudyTab initialTab = StudyTab.commentary,
  bool wholeChapter = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, sc) => StudySheet(
        bible: bible,
        book: book,
        chapter: chapter,
        verses: verses,
        initialTab: initialTab,
        wholeChapter: wholeChapter,
        scrollController: sc,
      ),
    ),
  );
}

class StudySheet extends StatefulWidget {
  const StudySheet({
    super.key,
    required this.bible,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.initialTab,
    required this.scrollController,
    this.wholeChapter = false,
  });

  final Bible bible;
  final int book;
  final int chapter;
  final List<int> verses;
  final StudyTab initialTab;
  final bool wholeChapter;
  final ScrollController scrollController;

  @override
  State<StudySheet> createState() => _StudySheetState();
}

class _StudySheetState extends State<StudySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: StudyTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final ref = VerseRef(widget.book, widget.chapter, widget.verses.first);
    final title = widget.wholeChapter
        ? '${bookAt(widget.book).name(l.amharic)} ${widget.chapter}'
        : selectionLabel(widget.book, widget.chapter, widget.verses, l.amharic);
    final body = switch (StudyTab.values[_tabs.index]) {
      StudyTab.commentary => _CommentaryTab(
        book: widget.book,
        chapter: widget.chapter,
        verse: ref.verse,
        wholeChapter: widget.wholeChapter,
      ),
      StudyTab.crossRefs => _CrossRefsTab(ref: ref, bible: widget.bible),
      StudyTab.strongs => _StrongsTab(
        book: widget.book,
        chapter: widget.chapter,
        verses: widget.verses,
      ),
      StudyTab.compare => _CompareTab(
        book: widget.book,
        chapter: widget.chapter,
        verses: widget.verses,
      ),
      StudyTab.words => _WordsTab(
        text: widget.verses
            .map(
              (v) => widget.bible.verseOrMerged(widget.book, widget.chapter, v),
            )
            .join(' '),
      ),
    };
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeaderDelegate(
            height: 104,
            child: Material(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: l('commentary')),
                      Tab(text: l('crossRefs')),

                      Tab(text: l('strongs')),
                      Tab(text: l('compare')),
                      Tab(text: l('dictionary')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            40 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(child: body),
        ),
      ],
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: height, child: child);
  @override
  bool shouldRebuild(covariant _HeaderDelegate old) => old.child != child;
}

// ----- Commentary -----

class _CommentaryTab extends StatefulWidget {
  const _CommentaryTab({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.wholeChapter,
  });
  final int book;
  final int chapter;
  final int verse;
  final bool wholeChapter;

  @override
  State<_CommentaryTab> createState() => _CommentaryTabState();
}

class _CommentaryTabState extends State<_CommentaryTab> {
  late String _sourceId = context.read<SettingsController>().commentarySource;
  Future<CommentaryChapter>? _future;
  bool _showAll = false;

  CommentarySource get _source => kCommentarySources.firstWhere(
    (s) => s.id == _sourceId,
    orElse: () => kCommentarySources.first,
  );

  @override
  void initState() {
    super.initState();
    _showAll = widget.wholeChapter;
    _load();
  }

  void _load() {
    final svc = context.read<CommentaryService>();
    _future = svc.fetch(_source, bookAt(widget.book), widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<UserDataController>();
    final note = user.noteOf(
      VerseRef(widget.book, widget.chapter, widget.verse),
    );
    final book = bookAt(widget.book);
    final sources = kCommentarySources.where((s) => s.covers(book)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (note != null && !widget.wholeChapter) ...[
          Card(
            color: cs.secondaryContainer.withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: cs.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l('myNote'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(note.text),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in sources)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.author),
                    selected: s.id == _source.id,
                    onSelected: (_) {
                      setState(() {
                        _sourceId = s.id;
                        context.read<SettingsController>().commentarySource =
                            s.id;
                        _load();
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_source.name}${_source.year.isNotEmpty ? ' (${_source.year})' : ''}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 8),
        FutureBuilder<CommentaryChapter>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.cloud_off, size: 42, color: cs.outline),
                  const SizedBox(height: 10),
                  Text(l('commentaryOffline'), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () => setState(_load),
                    child: Text(l('retry')),
                  ),
                ],
              );
            }
            final c = snap.data!;
            if (c.isEmpty) return Text(l('noCommentary'));
            final focused = c.forVerse(widget.verse);
            final widgets = <Widget>[];
            if (!_showAll && focused.isNotEmpty) {
              widgets.add(
                Text(
                  '${l('onThisVerse')} (${widget.verse})',
                  style: TextStyle(
                    color: cs.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
              for (final b in focused) {
                widgets.add(_block(b, cs));
              }
              widgets.add(const SizedBox(height: 8));
              widgets.add(
                OutlinedButton.icon(
                  icon: const Icon(Icons.unfold_more),
                  label: Text(l('fullChapter')),
                  onPressed: () => setState(() => _showAll = true),
                ),
              );
            } else {
              if (c.intro.isNotEmpty) widgets.add(MarkdownText(c.intro));
              for (final b in c.blocks) {
                widgets.add(
                  _block(
                    b,
                    cs,
                    highlight: b.covers(widget.verse) && !widget.wholeChapter,
                  ),
                );
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widgets,
            );
          },
        ),
      ],
    );
  }

  Widget _block(CommentaryBlock b, ColorScheme cs, {bool highlight = false}) {
    final range = b.startVerse <= 0
        ? ''
        : b.endVerse > b.startVerse
        ? 'v. ${b.startVerse}–${b.endVerse}'
        : 'v. ${b.startVerse}';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (b.title.isNotEmpty || range.isNotEmpty)
            Text(
              [b.title, range].where((e) => e.isNotEmpty).join(' · '),
              style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary),
            ),
          MarkdownText(b.body, fontSize: 15),
        ],
      ),
    );
  }
}

// ----- Cross references -----

class _CrossRefsTab extends StatelessWidget {
  const _CrossRefsTab({required this.ref, required this.bible});
  final VerseRef ref;
  final Bible bible;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<Passage>>(
      future: context.read<CrossRefService>().forVerse(ref),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snap.data!;
        if (list.isEmpty) return Text(l('noCrossRefs'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Treasury of Scripture Knowledge · ${list.length}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            for (final p in list)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(
                        standalone: true,
                        initial: VerseRef(p.book, p.chapter, p.fromVerse ?? 1),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.label(amharic: bible.isEthiopic || l.amharic),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: cs.outline,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _preview(bible, p),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: scriptureFont(bible.lang),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _preview(Bible b, Passage p) {
    if (p.toChapter != null) {
      return b.verseOrMerged(p.book, p.chapter, p.fromVerse ?? 1);
    }
    return b.passageText(p);
  }
}

// ----- Compare -----

class _CompareTab extends StatelessWidget {
  const _CompareTab({
    required this.book,
    required this.chapter,
    required this.verses,
  });
  final int book;
  final int chapter;
  final List<int> verses;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<BibleRepository>();
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in repo.installed)
          FutureBuilder<Bible>(
            future: repo.load(t.id),
            builder: (context, snap) {
              final b = snap.data;
              final text = b == null
                  ? '…'
                  : verses
                        .map((v) => b.verseOrMerged(book, chapter, v))
                        .where((e) => e.isNotEmpty)
                        .toSet()
                        .join(' ');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.abbr} · ${t.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text.isEmpty ? l('notInVersion') : text,
                        style: TextStyle(
                          fontFamily: scriptureFont(t.lang),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l('library')),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LibraryScreen())),
        ),
      ],
    );
  }
}

// ----- Words / dictionary -----

class _WordsTab extends StatelessWidget {
  const _WordsTab({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final words = <String>{};
    for (final w in text.split(RegExp(r'[\s፡።፣፤፥፦፧፨,.;:!?“”"()\[\]]+'))) {
      final t = w.trim();
      if (t.runes.length >= 3) words.add(t);
    }
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l('dictionaryHint'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in words)
              ActionChip(
                label: Text(w),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DictionaryScreen(initialQuery: w),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.local_library_outlined),
          label: Text(l('bibleDictionary')),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DictionaryScreen())),
        ),
      ],
    );
  }
}

// ----- Strong's -----

class _StrongsTab extends StatelessWidget {
  const _StrongsTab({
    required this.book,
    required this.chapter,
    required this.verses,
  });
  final int book;
  final int chapter;
  final List<int> verses;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<Bible>(
      future: context.read<StrongsService>().taggedBible(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final b = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: cs.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l('strongsHint'),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF3A3420) : const Color(0xFFFFF4BD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "KJV · Strong's",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final v in verses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StrongsVerseText(
                        b.taggedVerse(book, chapter, v),
                        fontSize: 18,
                        prefix: [
                          TextSpan(
                            text: '$v ',
                            style: const TextStyle(
                              color: Brand.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
