import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/reference.dart';
import '../../data/bible.dart';
import '../../data/bible_repository.dart';

/// Cross-tab navigation: lets any screen open a verse in the Bible tab.
class AppNav extends ChangeNotifier {
  int tab = 0;
  VerseRef? pending;

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void openInBible(VerseRef r) {
    pending = r;
    tab = 1;
    notifyListeners();
  }

  VerseRef? takePending() {
    final p = pending;
    pending = null;
    return p;
  }
}

/// Loads a Bible version and rebuilds when ready.
class BibleBuilder extends StatelessWidget {
  const BibleBuilder({super.key, required this.id, required this.builder});
  final String id;
  final Widget Function(BuildContext, Bible) builder;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<BibleRepository>();
    final b = repo.cached(id);
    if (b != null) return builder(context, b);
    return FutureBuilder<Bible>(
      future: repo.load(id),
      builder: (context, snap) {
        if (snap.hasData) return builder(context, snap.data!);
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

/// Very small markdown renderer for commentary text:
/// `#` headings, `>` quotes, `**bold**`, `*italic*`, blank-line paragraphs.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.data, {super.key, this.fontSize = 15});
  final String data;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final blocks = <Widget>[];
    final paras = data.replaceAll('\r', '').split(RegExp(r'\n\s*\n'));
    for (final raw in paras) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (p.startsWith('#')) {
        final level = RegExp(r'^#+').firstMatch(p)!.group(0)!.length;
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              p.replaceFirst(RegExp(r'^#+\s*'), ''),
              style:
                  (level <= 2
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleSmall)
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
            ),
          ),
        );
        continue;
      }
      if (p.startsWith('>')) {
        final text = p
            .split('\n')
            .map((l) => l.replaceFirst(RegExp(r'^>\s?'), '').trimRight())
            .join('\n');
        blocks.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              border: Border(left: BorderSide(color: cs.primary, width: 3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text.rich(_inline(text, fontSize - 1, cs, italicBase: true)),
          ),
        );
        continue;
      }
      blocks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text.rich(_inline(p.replaceAll('\n', ' '), fontSize, cs)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  static TextSpan _inline(
    String s,
    double size,
    ColorScheme cs, {
    bool italicBase = false,
  }) {
    final spans = <TextSpan>[];
    final re = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > i) spans.add(TextSpan(text: s.substring(i, m.start)));
      final t = m.group(0)!;
      if (t.startsWith('**')) {
        spans.add(
          TextSpan(
            text: t.substring(2, t.length - 2),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: t.substring(1, t.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      i = m.end;
    }
    if (i < s.length) spans.add(TextSpan(text: s.substring(i)));
    return TextSpan(
      style: TextStyle(
        fontSize: size,
        height: 1.55,
        fontStyle: italicBase ? FontStyle.italic : null,
      ),
      children: spans,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Formats "John 3:16–18" for a set of selected verses.
String selectionLabel(int book, int chapter, List<int> verses, bool amharic) {
  final r = VerseRef(book, chapter, verses.first);
  final name = r.bookInfo.name(amharic);
  if (verses.length == 1) return '$name $chapter:${verses.first}';
  final parts = <String>[];
  var start = verses.first;
  var prev = start;
  for (final v in verses.skip(1)) {
    if (v == prev + 1) {
      prev = v;
      continue;
    }
    parts.add(start == prev ? '$start' : '$start–$prev');
    start = prev = v;
  }
  parts.add(start == prev ? '$start' : '$start–$prev');
  return '$name $chapter:${parts.join(',')}';
}
