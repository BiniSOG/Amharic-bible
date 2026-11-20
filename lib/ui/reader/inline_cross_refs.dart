import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../core/theme.dart';
import '../../data/bible.dart';
import '../../data/study_data.dart';
import '../../state/settings_controller.dart';
import 'reader_screen.dart';

/// Cross references shown in place, right under the verse whose `*` was
/// tapped: a coloured card with a header and each referenced passage in full.
class InlineCrossRefs extends StatefulWidget {
  const InlineCrossRefs({
    super.key,
    required this.ref,
    required this.bible,
    required this.onClose,
  });

  final VerseRef ref;
  final Bible bible;
  final VoidCallback onClose;

  @override
  State<InlineCrossRefs> createState() => _InlineCrossRefsState();
}

class _InlineCrossRefsState extends State<InlineCrossRefs> {
  static const _initial = 6;
  late final Future<List<Passage>> _future = context
      .read<CrossRefService>()
      .forVerse(widget.ref);
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = context.watch<SettingsController>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bodyBg = dark ? const Color(0xFF3A3420) : const Color(0xFFFFF4BD);
    final headBg = dark ? const Color(0xFF4A4224) : const Color(0xFFF2DF7E);
    final fg = dark ? const Color(0xFFF3EBCF) : const Color(0xFF2B2416);
    final linkColor = dark ? const Color(0xFFFF8A80) : Brand.red;
    final am = widget.bible.isEthiopic || l.amharic;
    final size = 16.0 * s.fontScale;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bodyBg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: headBg,
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l('crossRefs')} – ${widget.ref.label(amharic: am)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  color: fg,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          FutureBuilder<List<Passage>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l('noCrossRefs'), style: TextStyle(color: fg)),
                );
              }
              final shown = _all ? list : list.take(_initial).toList();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in shown)
                      _PassageBlock(
                        passage: p,
                        bible: widget.bible,
                        amharic: am,
                        color: fg,
                        linkColor: linkColor,
                        size: size,
                      ),
                    if (!_all && list.length > _initial)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: linkColor,
                          ),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: Text('${l('showAll')} (${list.length})'),
                          onPressed: () => setState(() => _all = true),
                        ),
                      ),
                    Text(
                      'Treasury of Scripture Knowledge',
                      style: TextStyle(
                        fontSize: 11,
                        color: fg.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PassageBlock extends StatelessWidget {
  const _PassageBlock({
    required this.passage,
    required this.bible,
    required this.amharic,
    required this.color,
    required this.linkColor,
    required this.size,
  });

  final Passage passage;
  final Bible bible;
  final bool amharic;
  final Color color;
  final Color linkColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = passage;
    final c = bible.chapter(p.book, p.chapter);
    final from = (p.fromVerse ?? 1).clamp(1, c.isEmpty ? 1 : c.length);
    final to = p.toChapter != null
        ? (from + 2).clamp(from, c.length)
        : (p.toVerse ?? from).clamp(from, c.isEmpty ? from : c.length);
    final spans = <InlineSpan>[];
    for (var v = from; v <= to && v <= c.length; v++) {
      final t = c[v - 1];
      if (t.isEmpty) continue;
      spans.add(
        TextSpan(
          text: '$v ',
          style: TextStyle(
            fontSize: size * 0.8,
            fontFamily: kSerifLatin,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      );
      spans.add(TextSpan(text: '$t  '));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  standalone: true,
                  initial: VerseRef(p.book, p.chapter, from),
                ),
              ),
            ),
            child: Text(
              p.label(amharic: amharic),
              style: TextStyle(
                color: linkColor,
                fontSize: size * 1.05,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (spans.isEmpty)
            Text('—', style: TextStyle(color: color))
          else
            Text.rich(
              TextSpan(children: spans),
              style: TextStyle(
                fontFamily: scriptureFont(bible.lang),
                fontSize: size,
                height: 1.55,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
