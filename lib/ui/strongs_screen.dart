import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/reference.dart';
import '../core/theme.dart';
import '../data/bible_repository.dart';
import '../data/strongs_service.dart';
import 'reader/reader_screen.dart';
import 'widgets/common.dart';

/// Renders a Strong's-tagged verse (`word[G2532]`) with small tappable
/// numbers after each word.
class StrongsVerseText extends StatefulWidget {
  const StrongsVerseText(
    this.tagged, {
    super.key,
    this.fontSize = 17,
    this.height = 1.6,
    this.color,
    this.prefix,
    this.suffix,
  });

  final String tagged;
  final double fontSize;
  final double height;
  final Color? color;

  /// Spans placed before the verse (e.g. the verse number).
  final List<InlineSpan>? prefix;
  final List<InlineSpan>? suffix;

  @override
  State<StrongsVerseText> createState() => _StrongsVerseTextState();
}

class _StrongsVerseTextState extends State<StrongsVerseText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final cs = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[...?widget.prefix];
    for (final (text, nums) in splitTagged(widget.tagged)) {
      spans.add(TextSpan(text: text));
      for (final n in nums) {
        spans.add(const TextSpan(text: '\u2009'));
        final r = TapGestureRecognizer()
          ..onTap = () => showStrongsSheet(context, n);
        _recognizers.add(r);
        spans.add(
          TextSpan(
            text: n,
            recognizer: r,
            style: TextStyle(
              fontSize: widget.fontSize * 0.68,
              fontWeight: FontWeight.w700,
              color: Brand.red,
              letterSpacing: 0.2,
            ),
          ),
        );
      }
    }
    spans.addAll(widget.suffix ?? const []);
    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontFamily: kSerifLatin,
        fontSize: widget.fontSize,
        height: widget.height,
        color: widget.color ?? cs.onSurface,
      ),
    );
  }
}

Future<void> showStrongsSheet(BuildContext context, String number) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, sc) => _StrongsSheet(number: number, controller: sc),
    ),
  );
}

class _StrongsSheet extends StatefulWidget {
  const _StrongsSheet({required this.number, required this.controller});
  final String number;
  final ScrollController controller;

  @override
  State<_StrongsSheet> createState() => _StrongsSheetState();
}

class _StrongsSheetState extends State<_StrongsSheet> {
  late final List<String> _stack = [widget.number];

  @override
  Widget build(BuildContext context) {
    final svc = context.read<StrongsService>();
    final number = _stack.last;
    return FutureBuilder<StrongsEntry?>(
      key: ValueKey(number),
      future: svc.lookup(number),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final e = snap.data;
        return ListView(
          controller: widget.controller,
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            if (_stack.length > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(_stack[_stack.length - 2]),
                  onPressed: () => setState(_stack.removeLast),
                ),
              ),
            if (e == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$number — ${L.of(context)('noResults')}'),
              )
            else
              StrongsEntryCard(
                entry: e,
                onOpen: (n) => setState(() => _stack.add(n)),
              ),
          ],
        );
      },
    );
  }
}

/// The dictionary card (as in the reference design): number, original word,
/// transliteration, pronunciation, definition and KJV usage.
class StrongsEntryCard extends StatefulWidget {
  const StrongsEntryCard({super.key, required this.entry, this.onOpen});
  final StrongsEntry entry;
  final ValueChanged<String>? onOpen;

  @override
  State<StrongsEntryCard> createState() => _StrongsEntryCardState();
}

class _StrongsEntryCardState extends State<StrongsEntryCard> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  /// Turns "from G25 (ἀγαπάω)" into text with tappable G25.
  TextSpan _linked(String text, ColorScheme cs) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in RegExp(r'\b([GH]\d{1,5})\b').allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final n = m.group(1)!;
      final r = TapGestureRecognizer()..onTap = () => widget.onOpen?.call(n);
      _recognizers.add(r);
      spans.add(
        TextSpan(
          text: n,
          recognizer: widget.onOpen == null ? null : r,
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final e = widget.entry;
    final label = TextStyle(color: Brand.red, fontWeight: FontWeight.w700);
    Widget row(String title, InlineSpan value) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$title: ', style: label),
            value,
          ],
        ),
        style: const TextStyle(fontSize: 16, height: 1.55),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l('strongsTitle'),
            style: TextStyle(
              color: Brand.red,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            e.number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 4),
          row(
            e.isGreek ? l('greek') : l('hebrew'),
            TextSpan(
              text: e.lemma,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          if (e.translit.isNotEmpty)
            row(l('transliteration'), TextSpan(text: e.translit)),
          if (e.pron.isNotEmpty)
            row(l('pronunciation'), TextSpan(text: e.pron)),
          if (e.derivation.isNotEmpty)
            row(l('derivation'), _linked(e.derivation, cs)),
          if (e.definition.isNotEmpty)
            row(l('definition'), _linked(e.definition, cs)),
          if (e.kjvUsage.isNotEmpty)
            row(l('kjvUsage'), TextSpan(text: e.kjvUsage)),
          FutureBuilder<int>(
            future: context.read<StrongsService>().occurrences(e.number),
            builder: (context, snap) => snap.hasData
                ? row(l('occursTimes'), TextSpan(text: '${snap.data}×'))
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(l('findAllVerses').toUpperCase()),
              style: TextButton.styleFrom(foregroundColor: Brand.red),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StrongsVersesScreen(number: e.number),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every verse in the KJV that uses a given Strong's number.
class StrongsVersesScreen extends StatelessWidget {
  const StrongsVersesScreen({super.key, required this.number});
  final String number;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text("$number · ${l('strongs')}")),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<SearchHit>>(
          future: context.read<StrongsService>().versesWith(number),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final hits = snap.data!;
            if (hits.isEmpty) {
              return EmptyState(icon: Icons.search_off, text: l('noResults'));
            }
            return ListView.separated(
              itemCount: hits.length + 1,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Text(
                      '${hits.length} ${l('results')}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                final h = hits[i - 1];
                final r = hitRef(h);
                return ListTile(
                  title: Text(
                    r.label(amharic: l.amharic),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  subtitle: Text(
                    h.text,
                    style: const TextStyle(
                      fontFamily: kSerifLatin,
                      height: 1.4,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ReaderScreen(standalone: true, initial: r),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Opens a Strong's entry from a typed query; returns false if not a number.
bool openStrongsFromQuery(BuildContext context, String q) {
  final n = StrongsService.normalize(q);
  if (n == null) return false;
  showStrongsSheet(context, n);
  return true;
}

/// Convenience: a reference label for a hit.
String hitLabel(SearchHit h, bool am) =>
    VerseRef(h.book, h.chapter, h.verse).label(amharic: am);
