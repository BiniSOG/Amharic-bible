import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../core/theme.dart';
import '../../data/bible.dart';
import '../../data/tts_service.dart';
import '../../state/user_data_controller.dart';
import '../widgets/common.dart';
import 'reader_sheets.dart';
import 'verse_image_screen.dart';

String versesText(
  Bible bible,
  int book,
  int chapter,
  List<int> verses, {
  bool withNumbers = true,
}) {
  final b = StringBuffer();
  for (final v in verses) {
    final t = bible.verseOrMerged(book, chapter, v);
    if (t.isEmpty) continue;
    if (b.isNotEmpty) b.write(withNumbers ? '\n' : ' ');
    b.write(withNumbers && verses.length > 1 ? '$v $t' : t);
  }
  return b.toString();
}

String shareText(Bible bible, int book, int chapter, List<int> verses) {
  final label = selectionLabel(book, chapter, verses, bible.isEthiopic);
  return '“${versesText(bible, book, chapter, verses)}”\n— $label (${bible.abbr})';
}

/// Shared implementation of all verse actions.
class VerseActions {
  VerseActions(
    this.context,
    this.bible,
    this.book,
    this.chapter,
    this.verses,
    this.onDone,
  );
  final BuildContext context;
  final Bible bible;
  final int book;
  final int chapter;
  final List<int> verses;
  final VoidCallback onDone;

  List<VerseRef> get refs => [
    for (final v in verses) VerseRef(book, chapter, v),
  ];
  L get l => L.read(context);

  Future<void> copy() async {
    await Clipboard.setData(
      ClipboardData(text: shareText(bible, book, chapter, verses)),
    );
    if (context.mounted) showSnack(context, l('copied'));
    onDone();
  }

  Future<void> share() async {
    await SharePlus.instance.share(
      ShareParams(text: shareText(bible, book, chapter, verses)),
    );
    onDone();
  }

  void highlight(int? color) {
    context.read<UserDataController>().setHighlight(refs, color);
    onDone();
  }

  void bookmark() {
    final u = context.read<UserDataController>();
    u.toggleBookmark(refs);
    showSnack(context, l(u.isBookmarked(refs.first) ? 'bookmarked' : 'remove'));
    onDone();
  }

  Future<void> note() async {
    await showNoteEditor(
      context,
      refs.first,
      quote: versesText(bible, book, chapter, verses),
    );
    onDone();
  }

  void study(StudyTab tab) {
    showStudySheet(
      context,
      bible: bible,
      book: book,
      chapter: chapter,
      verses: verses,
      initialTab: tab,
    );
  }

  Future<void> image() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerseImageScreen(
          text: versesText(bible, book, chapter, verses, withNumbers: false),
          reference:
              '${selectionLabel(book, chapter, verses, bible.isEthiopic)} · ${bible.abbr}',
          lang: bible.lang,
        ),
      ),
    );
    onDone();
  }

  Future<void> listen() async {
    final ok = await context.read<TtsService>().speak(
      versesText(bible, book, chapter, verses, withNumbers: false),
      bible.lang,
    );
    if (!ok && context.mounted) showSnack(context, l('ttsUnavailable'));
  }
}

/// Compact bar shown while verses are selected by tapping.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.visible,
    required this.bible,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.onClear,
    required this.onMore,
  });

  final bool visible;
  final Bible bible;
  final int book;
  final int chapter;
  final List<int> verses;
  final VoidCallback onClear;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = L.of(context);
    final a = VerseActions(context, bible, book, chapter, verses, onClear);
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.2),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: verses.isEmpty
                ? const SizedBox(height: 90)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectionLabel(book, chapter, verses, l.amharic),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close),
                            onPressed: onClear,
                          ),
                        ],
                      ),
                      HighlightRow(onPick: a.highlight),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _Chip(Icons.copy_rounded, l('copy'), a.copy),
                            _Chip(Icons.ios_share_rounded, l('share'), a.share),
                            _Chip(
                              Icons.menu_book_rounded,
                              l('commentary'),
                              () => a.study(StudyTab.commentary),
                            ),
                            _Chip(
                              Icons.sticky_note_2_outlined,
                              l('note'),
                              a.note,
                            ),
                            _Chip(
                              Icons.bookmark_add_outlined,
                              l('bookmark'),
                              a.bookmark,
                            ),
                            _Chip(Icons.more_horiz, l('more'), onMore),
                          ],
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

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    ),
  );
}

class HighlightRow extends StatelessWidget {
  const HighlightRow({super.key, required this.onPick, this.size = 34});
  final ValueChanged<int?> onPick;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < kHighlightColors.length; i++)
          Semantics(
            label: 'Highlight ${kHighlightNamesEn[i]}',
            button: true,
            child: InkResponse(
              onTap: () => onPick(i),
              radius: size * 0.7,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: kHighlightColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
            ),
          ),
        Semantics(
          label: 'Remove highlight',
          button: true,
          child: InkResponse(
            onTap: () => onPick(null),
            radius: size * 0.7,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outline),
              ),
              child: Icon(
                Icons.format_color_reset_outlined,
                size: size * 0.55,
                color: cs.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The long-press sheet with every verse feature.
Future<void> showVerseActionsSheet(
  BuildContext context, {
  required Bible bible,
  required int book,
  required int chapter,
  required List<int> verses,
  required VoidCallback onClearSelection,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetCtx) {
      final l = L.of(sheetCtx);
      final cs = Theme.of(sheetCtx).colorScheme;
      void close() => Navigator.of(sheetCtx).pop();
      final a = VerseActions(
        context,
        bible,
        book,
        chapter,
        verses,
        onClearSelection,
      );
      final user = context.read<UserDataController>();
      final marked = user.isBookmarked(VerseRef(book, chapter, verses.first));

      final actions = <(IconData, String, VoidCallback)>[
        (
          Icons.copy_rounded,
          l('copy'),
          () {
            close();
            a.copy();
          },
        ),
        (
          Icons.ios_share_rounded,
          l('share'),
          () {
            close();
            a.share();
          },
        ),
        (
          Icons.image_outlined,
          l('image'),
          () {
            close();
            a.image();
          },
        ),
        (
          marked ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
          l('bookmark'),
          () {
            close();
            a.bookmark();
          },
        ),
        (
          Icons.sticky_note_2_outlined,
          l('note'),
          () {
            close();
            a.note();
          },
        ),
        (
          Icons.menu_book_rounded,
          l('commentary'),
          () {
            close();
            a.study(StudyTab.commentary);
          },
        ),
        (
          Icons.link_rounded,
          l('crossRefs'),
          () {
            close();
            a.study(StudyTab.crossRefs);
          },
        ),
        (
          Icons.compare_arrows_rounded,
          l('compare'),
          () {
            close();
            a.study(StudyTab.compare);
          },
        ),
        (
          Icons.translate_rounded,
          l('dictionary'),
          () {
            close();
            a.study(StudyTab.words);
          },
        ),
        (
          Icons.headphones_outlined,
          l('listen'),
          () {
            close();
            a.listen();
          },
        ),
      ];

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              selectionLabel(book, chapter, verses, l.amharic),
              style: Theme.of(sheetCtx).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 110),
              child: SingleChildScrollView(
                child: Text(
                  versesText(bible, book, chapter, verses, withNumbers: false),
                  style: TextStyle(
                    fontFamily: scriptureFont(bible.lang),
                    fontSize: 15,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l('highlight'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            HighlightRow(
              onPick: (c) {
                close();
                a.highlight(c);
              },
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              childAspectRatio: 0.82,
              children: [
                for (final (icon, label, onTap) in actions)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: cs.onSecondaryContainer),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showNoteEditor(
  BuildContext context,
  VerseRef ref, {
  String? quote,
}) {
  final user = context.read<UserDataController>();
  final ctrl = TextEditingController(text: user.noteOf(ref)?.text ?? '');
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final l = L.of(ctx);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l('note')} · ${ref.label(amharic: l.amharic)}',
              style: Theme.of(ctx).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (quote != null) ...[
              const SizedBox(height: 6),
              Text(
                quote,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              decoration: InputDecoration(hintText: l('notePlaceholder')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (user.noteOf(ref) != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l('delete')),
                    onPressed: () {
                      user.setNote(ref, '');
                      Navigator.pop(ctx);
                    },
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l('cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    user.setNote(ref, ctrl.text);
                    Navigator.pop(ctx);
                  },
                  child: Text(l('save')),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
