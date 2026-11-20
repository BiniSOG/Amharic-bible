import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/reference.dart';
import '../data/study_data.dart';
import 'reader/reader_screen.dart';
import 'widgets/common.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  late final _ctrl = TextEditingController(text: widget.initialQuery ?? '');
  DictionarySource? _only;
  Future<List<DictionaryEntry>>? _future;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search() {
    _future = context.read<DictionaryService>().search(_ctrl.text, only: _only);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l('bibleDictionary')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _ctrl,
                  autofocus: widget.initialQuery == null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l('dictionaryHint'),
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 250),
                      () => setState(_search),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (src, label) in [
                      (null, l('all')),
                      (DictionarySource.glossary, l('glossary')),
                      (DictionarySource.easton, l('easton')),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _only == src,
                          onSelected: (_) => setState(() {
                            _only = src;
                            _search();
                          }),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<DictionaryEntry>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return EmptyState(icon: Icons.search_off, text: l('noResults'));
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final first = e.definition.split('\n').first;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.source == DictionarySource.glossary
                        ? cs.secondaryContainer
                        : cs.primaryContainer,
                    child: Text(
                      e.term.characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(
                    e.termAlt != null ? '${e.term} · ${e.termAlt}' : e.term,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DictionaryEntryScreen(entry: e),
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

class DictionaryEntryScreen extends StatelessWidget {
  const DictionaryEntryScreen({super.key, required this.entry});
  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final refRe = RegExp(
      r'\b((?:[123]\s)?[A-Z][a-z]{1,6}\.?)\s(\d{1,3}):(\d{1,3})',
    );
    return Scaffold(
      appBar: AppBar(title: Text(entry.term)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              entry.term,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
            ),
            if (entry.termAlt != null)
              Text(
                entry.termAlt!,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: cs.secondary),
              ),
            const SizedBox(height: 4),
            Text(
              entry.source == DictionarySource.easton
                  ? 'Easton\'s Bible Dictionary (1897)'
                  : l('glossary'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SelectableText(
              entry.definition,
              style: const TextStyle(fontSize: 16.5, height: 1.6),
            ),
            const SizedBox(height: 20),
            if (entry.refs.isNotEmpty || refRe.hasMatch(entry.definition)) ...[
              Text(
                l('relatedVerses'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final k in entry.refs)
                    if (VerseRef.tryParseKey(k) case final r?)
                      ActionChip(
                        avatar: const Icon(Icons.menu_book, size: 16),
                        label: Text(r.label(amharic: l.amharic, short: true)),
                        onPressed: () => _open(context, r),
                      ),
                  for (final m in refRe.allMatches(entry.definition).take(16))
                    if (parseHumanReference(
                          '${m.group(1)} ${m.group(2)}:${m.group(3)}',
                        )
                        case final p?)
                      ActionChip(
                        avatar: const Icon(Icons.menu_book, size: 16),
                        label: Text(p.label(amharic: l.amharic)),
                        onPressed: () => _open(
                          context,
                          VerseRef(p.book, p.chapter, p.fromVerse ?? 1),
                        ),
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, VerseRef r) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ReaderScreen(standalone: true, initial: r),
    ),
  );
}
