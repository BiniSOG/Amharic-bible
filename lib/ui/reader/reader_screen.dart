import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/books.dart';
import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../core/theme.dart';
import '../../data/bible.dart';
import '../../data/bible_repository.dart';
import '../../data/tts_service.dart';
import '../../state/settings_controller.dart';
import '../../state/user_data_controller.dart';
import '../search_screen.dart';
import '../widgets/common.dart';
import 'book_picker.dart';
import 'reader_sheets.dart';
import 'verse_actions.dart';

/// All 1189 chapters in canonical order, for paging.
final List<(int, int)> kAllChapters = [
  for (final b in kBooks)
    for (var c = 1; c <= b.chapters; c++) (b.index, c),
];

int chapterIndexOf(int book, int chapter) =>
    kAllChapters.indexWhere((e) => e.$1 == book && e.$2 == chapter);

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    this.initial,
    this.standalone = false,
    this.footerBuilder,
  });

  final VerseRef? initial;

  /// Pushed as its own route (plans, cross references…) – shows a back button
  /// and doesn't overwrite the "continue reading" position.
  final bool standalone;

  /// Optional widget at the end of each chapter (e.g. plan "mark complete").
  final Widget Function(BuildContext, int book, int chapter)? footerBuilder;

  @override
  State<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  late PageController _pages;
  late int _index;
  int? _targetVerse;
  final Set<int> _selected = {};
  AppNav? _nav;

  int get _book => kAllChapters[_index].$1;
  int get _chapter => kAllChapters[_index].$2;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>();
    final pending = widget.standalone
        ? null
        : context.read<AppNav?>()?.takePending();
    final start = widget.initial ?? pending ?? s.lastRef;
    _index = chapterIndexOf(
      start.book,
      start.chapter,
    ).clamp(0, kAllChapters.length - 1);
    _targetVerse = start.verse > 1 ? start.verse : null;
    _pages = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.standalone) {
      final nav = context.read<AppNav?>();
      if (nav != _nav) {
        _nav?.removeListener(_onNav);
        _nav = nav;
        _nav?.addListener(_onNav);
      }
    }
  }

  void _onNav() {
    final p = _nav?.pending;
    if (p != null && _nav!.tab == 1) {
      _nav!.takePending();
      jumpTo(p);
    }
  }

  @override
  void dispose() {
    _nav?.removeListener(_onNav);
    _pages.dispose();
    super.dispose();
  }

  void jumpTo(VerseRef r) {
    final i = chapterIndexOf(r.book, r.chapter);
    if (i < 0) return;
    setState(() {
      _selected.clear();
      _targetVerse = r.verse;
      _index = i;
    });
    if (_pages.hasClients) _pages.jumpToPage(i);
    _record();
  }

  void _record() {
    if (!mounted) return;
    context.read<UserDataController>().recordChapter(_book, _chapter);
    if (!widget.standalone) {
      context.read<SettingsController>().rememberPosition(
        VerseRef(_book, _chapter, _targetVerse ?? 1),
      );
    }
  }

  void _onPage(int i) {
    setState(() {
      _index = i;
      _selected.clear();
      _targetVerse = null;
    });
    context.read<TtsService>().stop();
    _record();
  }

  void _toggle(int v) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(v)) _selected.add(v);
    });
  }

  Future<void> _longPress(int v, Bible bible) async {
    HapticFeedback.mediumImpact();
    setState(() => _selected.add(v));
    await showVerseActionsSheet(
      context,
      bible: bible,
      book: _book,
      chapter: _chapter,
      verses: (_selected.toList()..sort()),
      onClearSelection: _clearSel,
    );
  }

  void _clearSel() {
    if (mounted) setState(_selected.clear);
  }

  Future<void> _openPicker() async {
    final r = await Navigator.of(context).push<VerseRef>(
      MaterialPageRoute(
        builder: (_) => BookPickerScreen(currentBook: _book),
        fullscreenDialog: true,
      ),
    );
    if (r != null) jumpTo(r);
  }

  void _go(int delta) {
    final n = (_index + delta).clamp(0, kAllChapters.length - 1);
    _pages.animateToPage(
      n,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final l = L.of(context);
    final repo = context.watch<BibleRepository>();
    final pInfo = repo.info(s.primary) ?? repo.installed.first;
    final secId = s.parallel;
    final book = bookAt(_book);

    return BibleBuilder(
      id: pInfo.id,
      builder: (context, primary) {
        final secondary = secId == null ? null : repo.cached(secId);
        if (secId != null && secondary == null) repo.load(secId);
        return PopScope(
          canPop: _selected.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _clearSel();
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: widget.standalone,
              titleSpacing: widget.standalone ? 0 : 16,
              title: Row(
                children: [
                  Flexible(
                    child: _Pill(
                      onTap: _openPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${book.name(primary.isEthiopic || l.amharic).runes.length > 7 ? book.short(primary.isEthiopic || l.amharic) : book.name(primary.isEthiopic || l.amharic)} ${s.number(_chapter)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.expand_more, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    onTap: () => showVersionPicker(context),
                    child: Text(
                      secondary != null
                          ? '${pInfo.abbr} | ${secondary.abbr}'
                          : pInfo.abbr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: l('search'),
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      )
                      .then((r) {
                        if (r is VerseRef) jumpTo(r);
                      }),
                ),
                IconButton(
                  tooltip: l('parallel'),
                  isSelected: secId != null,
                  icon: const Icon(Icons.vertical_split_outlined),
                  selectedIcon: const Icon(Icons.vertical_split),
                  onPressed: () => showVersionPicker(context, parallel: true),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'text':
                        showTextSettings(context);
                      case 'listen':
                        final tts = context.read<TtsService>();
                        if (tts.speaking) {
                          tts.stop();
                        } else {
                          final ok = await tts.speak(
                            primary.passageText(Passage(_book, _chapter)),
                            primary.lang,
                          );
                          if (!ok && context.mounted) {
                            showSnack(context, l('ttsUnavailable'));
                          }
                        }
                      case 'commentary':
                        showStudySheet(
                          context,
                          bible: primary,
                          book: _book,
                          chapter: _chapter,
                          verses: const [1],
                          initialTab: StudyTab.commentary,
                          wholeChapter: true,
                        );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'text',
                      child: ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text(l('fontSize')),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'listen',
                      child: ListTile(
                        leading: Icon(
                          context.read<TtsService>().speaking
                              ? Icons.stop_circle_outlined
                              : Icons.headphones_outlined,
                        ),
                        title: Text(
                          context.read<TtsService>().speaking
                              ? l('stop')
                              : l('listen'),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'commentary',
                      child: ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(l('fullChapter')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pages,
                  onPageChanged: _onPage,
                  itemCount: kAllChapters.length,
                  itemBuilder: (context, i) {
                    final (b, c) = kAllChapters[i];
                    return ChapterView(
                      key: ValueKey('$b.$c.${primary.id}.${secondary?.id}'),
                      book: b,
                      chapter: c,
                      primary: primary,
                      secondary: secondary,
                      selected: i == _index ? _selected : const {},
                      targetVerse: i == _index ? _targetVerse : null,
                      onTap: _toggle,
                      onLongPress: (v) => _longPress(v, primary),
                      footer: widget.footerBuilder?.call(context, b, c),
                      onPrev: i > 0 ? () => _go(-1) : null,
                      onNext: i < kAllChapters.length - 1 ? () => _go(1) : null,
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SelectionBar(
                    visible: _selected.isNotEmpty,
                    bible: primary,
                    book: _book,
                    chapter: _chapter,
                    verses: (_selected.toList()..sort()),
                    onClear: _clearSel,
                    onMore: () => _selected.isEmpty
                        ? null
                        : showVerseActionsSheet(
                            context,
                            bible: primary,
                            book: _book,
                            chapter: _chapter,
                            verses: (_selected.toList()..sort()),
                            onClearSelection: _clearSel,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: cs.onSurface, fontSize: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// One chapter of scripture.
class ChapterView extends StatefulWidget {
  const ChapterView({
    super.key,
    required this.book,
    required this.chapter,
    required this.primary,
    required this.secondary,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.targetVerse,
    this.footer,
    this.onPrev,
    this.onNext,
  });

  final int book;
  final int chapter;
  final Bible primary;
  final Bible? secondary;
  final Set<int> selected;
  final int? targetVerse;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onLongPress;
  final Widget? footer;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  State<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<ChapterView> {
  final _keys = <int, GlobalKey>{};
  final _scroll = ScrollController();
  int? _flash;
  final _recognizers = <GestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(covariant ChapterView old) {
    super.didUpdateWidget(old);
    if (widget.targetVerse != null && widget.targetVerse != old.targetVerse) {
      _scheduleScroll();
    }
  }

  void _scheduleScroll() {
    final t = widget.targetVerse;
    if (t == null || t <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Verses below the fold may not be built yet: nudge the list.
      for (var attempt = 0; attempt < 12 && mounted; attempt++) {
        final ctx = _keys[t]?.currentContext;
        if (ctx != null && ctx.mounted) {
          await Scrollable.ensureVisible(
            ctx,
            alignment: 0.15,
            duration: const Duration(milliseconds: 350),
          );
          if (mounted) setState(() => _flash = t);
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted) setState(() => _flash = null);
          });
          return;
        }
        final sc = _scroll;
        if (!sc.hasClients) break;
        sc.jumpTo((sc.offset + 900).clamp(0, sc.position.maxScrollExtent));
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    });
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final user = context.watch<UserDataController>();
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final p = widget.primary;
    final sec = widget.secondary;
    final verses = p.chapter(widget.book, widget.chapter);
    final secVerses = sec?.chapter(widget.book, widget.chapter) ?? const [];
    final count = verses.length > secVerses.length
        ? verses.length
        : secVerses.length;
    final baseSize = 18.0 * s.fontScale;
    final book = bookAt(widget.book);
    final amTitle = p.isEthiopic || l.amharic;

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final items = <Widget>[];
    items.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
        child: Column(
          children: [
            Text(
              book.name(amTitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: scriptureFont(p.lang),
                fontSize: 15,
                letterSpacing: 0.5,
                color: cs.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              s.number(widget.chapter),
              style: TextStyle(
                fontFamily: scriptureFont(p.lang),
                fontSize: 46,
                height: 1.2,
                fontWeight: FontWeight.w300,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );

    if (!p.hasChapter(widget.book, widget.chapter) &&
        (sec == null || !sec.hasChapter(widget.book, widget.chapter))) {
      items.add(
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l('notInVersion'),
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    } else if (s.paragraphMode && sec == null) {
      items.add(_paragraph(context, verses, baseSize, s, user, cs));
    } else {
      for (var v = 1; v <= count; v++) {
        final t = v <= verses.length ? verses[v - 1] : '';
        final t2 = v <= secVerses.length ? secVerses[v - 1] : '';
        if (t.isEmpty && t2.isEmpty) continue;
        var end = v;
        while (end < verses.length &&
            verses[end].isEmpty &&
            t.isNotEmpty &&
            (sec == null ||
                end >= secVerses.length ||
                secVerses[end].isEmpty)) {
          end++;
        }
        items.add(
          _VerseTile(
            key: _keys.putIfAbsent(v, () => GlobalKey()),
            label: end > v ? '${s.number(v)}-${s.number(end)}' : s.number(v),
            text: t,
            secondaryText: sec == null ? null : t2,
            lang: p.lang,
            secondaryLang: sec?.lang,
            fontSize: baseSize,
            lineHeight: s.lineHeight,
            showNumber: s.showVerseNumbers,
            highlight: user.highlightOf(
              VerseRef(widget.book, widget.chapter, v),
            ),
            hasNote:
                user.noteOf(VerseRef(widget.book, widget.chapter, v)) != null,
            bookmarked: user.isBookmarked(
              VerseRef(widget.book, widget.chapter, v),
            ),
            selected: widget.selected.contains(v),
            flash: _flash == v,
            onTap: () => widget.onTap(v),
            onLongPress: () => widget.onLongPress(v),
          ),
        );
      }
    }

    items.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            if (widget.onPrev != null)
              OutlinedButton.icon(
                onPressed: widget.onPrev,
                icon: const Icon(Icons.chevron_left),
                label: Text(l('prevChapter')),
              ),
            const Spacer(),
            if (widget.onNext != null)
              FilledButton.tonalIcon(
                onPressed: widget.onNext,
                icon: const Icon(Icons.chevron_right),
                iconAlignment: IconAlignment.end,
                label: Text(l('nextChapter')),
              ),
          ],
        ),
      ),
    );
    if (widget.footer != null) items.add(widget.footer!);
    items.add(const SizedBox(height: 120));

    return ListView(
      controller: _scroll,
      padding: EdgeInsets.zero,
      children: items,
    );
  }

  Widget _paragraph(
    BuildContext context,
    List<String> verses,
    double size,
    SettingsController s,
    UserDataController user,
    ColorScheme cs,
  ) {
    final spans = <InlineSpan>[];
    for (var v = 1; v <= verses.length; v++) {
      final t = verses[v - 1];
      if (t.isEmpty) continue;
      final ref = VerseRef(widget.book, widget.chapter, v);
      final hl = user.highlightOf(ref);
      final sel = widget.selected.contains(v);
      final rec = TapGestureRecognizer()..onTap = () => widget.onTap(v);
      final lp = LongPressGestureRecognizer()
        ..onLongPress = () => widget.onLongPress(v);
      _recognizers
        ..add(rec)
        ..add(lp);
      if (s.showVerseNumbers) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: const EdgeInsets.only(right: 3, left: 2),
              child: Text(
                s.number(v),
                key: _keys.putIfAbsent(v, () => GlobalKey()),
                style: TextStyle(
                  fontSize: size * 0.6,
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: '$t ',
          recognizer: rec,
          style: TextStyle(
            backgroundColor: hl != null
                ? kHighlightColors[hl].withValues(alpha: 0.45)
                : null,
            decoration: sel ? TextDecoration.underline : null,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: cs.primary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      child: Text.rich(
        TextSpan(children: spans),
        style: TextStyle(
          fontFamily: scriptureFont(widget.primary.lang),
          fontSize: size,
          height: s.lineHeight,
          color: cs.onSurface,
        ),
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({
    super.key,
    required this.label,
    required this.text,
    required this.secondaryText,
    required this.lang,
    required this.secondaryLang,
    required this.fontSize,
    required this.lineHeight,
    required this.showNumber,
    required this.highlight,
    required this.hasNote,
    required this.bookmarked,
    required this.selected,
    required this.flash,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final String text;
  final String? secondaryText;
  final String lang;
  final String? secondaryLang;
  final double fontSize;
  final double lineHeight;
  final bool showNumber;
  final int? highlight;
  final bool hasNote;
  final bool bookmarked;
  final bool selected;
  final bool flash;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hl = highlight != null
        ? kHighlightColors[highlight!].withValues(alpha: dark ? 0.32 : 0.5)
        : null;
    final bg = selected
        ? cs.primaryContainer.withValues(alpha: 0.55)
        : flash
        ? cs.tertiaryContainer.withValues(alpha: 0.6)
        : hl;

    final main = Text.rich(
      TextSpan(
        children: [
          if (showNumber)
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize * 0.62,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          TextSpan(text: text.isEmpty ? '—' : text),
          if (hasNote || bookmarked)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bookmarked)
                      Icon(
                        Icons.bookmark,
                        size: fontSize * 0.85,
                        color: Brand.red,
                      ),
                    if (hasNote)
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: fontSize * 0.85,
                        color: cs.secondary,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      style: TextStyle(
        fontFamily: scriptureFont(lang),
        fontSize: fontSize,
        height: lineHeight,
        color: cs.onSurface,
        decoration: selected ? TextDecoration.underline : null,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: cs.primary,
      ),
    );

    return Semantics(
      button: true,
      label: 'Verse $label',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: secondaryText == null
              ? main
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    main,
                    if (secondaryText!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: cs.secondary.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          secondaryText!,
                          style: TextStyle(
                            fontFamily: scriptureFont(secondaryLang ?? 'en'),
                            fontSize: fontSize * 0.88,
                            height: lineHeight * 0.95,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
