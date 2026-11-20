import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/books.dart';
import '../core/l10n.dart';
import '../core/reference.dart';
import '../core/theme.dart';
import '../data/bible_repository.dart';
import '../state/settings_controller.dart';
import 'widgets/common.dart';

/// Full-text search. Pops with a [VerseRef] when a result is chosen.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  SearchScope _scope = SearchScope.all;
  late String _version = context.read<SettingsController>().primary;
  List<SearchHit>? _hits;
  bool _busy = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(q));
  }

  Future<void> _run(String q) async {
    _query = q.trim();
    if (_query.length < 2) {
      setState(() => _hits = null);
      return;
    }
    setState(() => _busy = true);
    final hits = await context.read<BibleRepository>().search(
      _version,
      _query,
      scope: _scope,
    );
    if (!mounted || q.trim() != _query) return;
    setState(() {
      _hits = hits;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final repo = context.watch<BibleRepository>();
    final ref = parseHumanReference(_ctrl.text);
    final lang = repo.info(_version)?.lang ?? 'am';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l('searchHint'),
            filled: false,
            border: InputBorder.none,
          ),
          onChanged: (v) {
            setState(() {});
            _onChanged(v);
          },
          onSubmitted: _run,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _hits = null);
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  DropdownButton<String>(
                    value: _version,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      for (final t in repo.installed)
                        DropdownMenuItem(value: t.id, child: Text(t.abbr)),
                    ],
                    onChanged: (v) {
                      setState(() => _version = v!);
                      _run(_ctrl.text);
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final (s, label) in [
                    (SearchScope.all, l('all')),
                    (SearchScope.oldTestament, l('oldTestament')),
                    (SearchScope.newTestament, l('newTestament')),
                    (SearchScope.gospels, l.amharic ? 'ወንጌላት' : 'Gospels'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _scope == s,
                        onSelected: (_) {
                          setState(() => _scope = s);
                          _run(_ctrl.text);
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (ref != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.arrow_forward),
                ),
                title: Text('${l('goTo')} ${ref.label(amharic: l.amharic)}'),
                onTap: () => Navigator.pop(
                  context,
                  VerseRef(ref.book, ref.chapter, ref.fromVerse ?? 1),
                ),
              ),
            if (_busy) const LinearProgressIndicator(),
            Expanded(child: _results(l, cs, lang)),
          ],
        ),
      ),
    );
  }

  Widget _results(L l, ColorScheme cs, String lang) {
    final hits = _hits;
    if (hits == null) {
      return EmptyState(icon: Icons.manage_search, text: l('searchHint'));
    }
    if (hits.isEmpty) {
      return EmptyState(icon: Icons.search_off, text: l('noResults'));
    }
    final terms = normalizeForSearch(_query)
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
    return ListView.separated(
      itemCount: hits.length + 1,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '${hits.length}${hits.length >= 500 ? '+' : ''} ${l('results')}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          );
        }
        final h = hits[i - 1];
        return ListTile(
          title: Text(
            '${bookAt(h.book).name(lang != 'en')} ${h.chapter}:${h.verse}',
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
          subtitle: Text.rich(
            _highlight(h.text, terms, cs),
            style: TextStyle(
              fontFamily: scriptureFont(lang),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          onTap: () =>
              Navigator.pop(context, VerseRef(h.book, h.chapter, h.verse)),
        );
      },
    );
  }

  TextSpan _highlight(String text, List<String> terms, ColorScheme cs) {
    if (terms.isEmpty) return TextSpan(text: text);
    // Highlight whole words containing a term (normalised comparison).
    final spans = <TextSpan>[];
    for (final word in text.split(' ')) {
      final n = normalizeForSearch(word);
      final hit = terms.any(n.contains);
      spans.add(
        TextSpan(
          text: '$word ',
          style: hit
              ? TextStyle(
                  backgroundColor: kHighlightColors[0].withValues(alpha: 0.6),
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                )
              : null,
        ),
      );
    }
    return TextSpan(children: spans);
  }
}
