import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/l10n.dart';
import '../core/reference.dart';
import '../core/theme.dart';
import '../state/settings_controller.dart';
import '../state/user_data_controller.dart';
import 'reader/reader_screen.dart';
import 'reader/verse_actions.dart';
import 'widgets/common.dart';

/// Highlights, bookmarks, notes and history in one place.
class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  int? _colorFilter;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = context.watch<UserDataController>();
    final s = context.watch<SettingsController>();

    List<VerseRef> sortedKeys(Iterable<String> keys) =>
        keys.map(VerseRef.tryParseKey).whereType<VerseRef>().toList()..sort();

    void open(VerseRef r) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(standalone: true, initial: r),
      ),
    );

    final hl = sortedKeys(user.highlights.keys)
        .where(
          (r) => _colorFilter == null || user.highlightOf(r) == _colorFilter,
        )
        .toList();
    final bm = user.bookmarks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final notes = user.notes.entries.toList()
      ..sort((a, b) => b.value.updated.compareTo(a.value.updated));

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l('myLibrary')),
          actions: [
            IconButton(
              tooltip: l('share'),
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _export(context, user, l),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '${l('highlights')} (${user.highlights.length})'),
              Tab(text: '${l('bookmarks')} (${user.bookmarks.length})'),
              Tab(text: '${l('notes')} (${user.notes.length})'),
              Tab(text: l('history')),
            ],
          ),
        ),
        body: BibleBuilder(
          id: s.primary,
          builder: (context, bible) => TabBarView(
            children: [
              // Highlights
              Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(l('all')),
                            selected: _colorFilter == null,
                            onSelected: (_) =>
                                setState(() => _colorFilter = null),
                          ),
                        ),
                        for (var i = 0; i < kHighlightColors.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: CircleAvatar(
                                backgroundColor: kHighlightColors[i],
                              ),
                              label: Text(
                                '${user.highlights.values.where((c) => c == i).length}',
                              ),
                              selected: _colorFilter == i,
                              onSelected: (_) =>
                                  setState(() => _colorFilter = i),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: hl.isEmpty
                        ? EmptyState(
                            icon: Icons.border_color_outlined,
                            text: l('nothingYet'),
                          )
                        : ListView.builder(
                            itemCount: hl.length,
                            itemBuilder: (_, i) {
                              final r = hl[i];
                              return ListTile(
                                leading: Container(
                                  width: 8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        kHighlightColors[user.highlightOf(r)!],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                title: Text(
                                  r.label(amharic: bible.isEthiopic),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  bible.verseOrMerged(
                                    r.book,
                                    r.chapter,
                                    r.verse,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: scriptureFont(bible.lang),
                                  ),
                                ),
                                onTap: () => open(r),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => user.setHighlight([r], null),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Bookmarks
              bm.isEmpty
                  ? EmptyState(
                      icon: Icons.bookmark_border,
                      text: l('nothingYet'),
                    )
                  : ListView.builder(
                      itemCount: bm.length,
                      itemBuilder: (_, i) {
                        final r = VerseRef.tryParseKey(bm[i].key)!;
                        return ListTile(
                          leading: const Icon(Icons.bookmark, color: Brand.red),
                          title: Text(
                            r.label(amharic: bible.isEthiopic),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            bible.verseOrMerged(r.book, r.chapter, r.verse),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: scriptureFont(bible.lang),
                            ),
                          ),
                          onTap: () => open(r),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => user.toggleBookmark([r]),
                          ),
                        );
                      },
                    ),
              // Notes
              notes.isEmpty
                  ? EmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      text: l('nothingYet'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notes.length,
                      itemBuilder: (_, i) {
                        final r = VerseRef.tryParseKey(notes[i].key)!;
                        final n = notes[i].value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => open(r),
                            onLongPress: () => showNoteEditor(context, r),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.label(amharic: bible.isEthiopic),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            showNoteEditor(context, r),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    bible.verseOrMerged(
                                      r.book,
                                      r.chapter,
                                      r.verse,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontFamily: scriptureFont(bible.lang),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    n.text,
                                    style: const TextStyle(fontSize: 15.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    MaterialLocalizations.of(context)
                                        .formatShortDate(n.updated),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              // History
              user.history.isEmpty
                  ? EmptyState(icon: Icons.history, text: l('nothingYet'))
                  : ListView(
                      children: [
                        for (final k in user.history)
                          Builder(
                            builder: (_) {
                              final p = k.split('.');
                              final r = VerseRef(
                                int.parse(p[0]),
                                int.parse(p[1]),
                                1,
                              );
                              return ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(
                                  '${r.bookInfo.name(l.amharic)} ${r.chapter}',
                                ),
                                onTap: () => open(r),
                              );
                            },
                          ),
                        TextButton(
                          onPressed: user.clearHistory,
                          child: Text(l('clear')),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    UserDataController user,
    L l,
  ) async {
    final b = StringBuffer('${l('myLibrary')}\n\n');
    final notes = user.notes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in notes) {
      final r = VerseRef.tryParseKey(e.key)!;
      b.writeln('📝 ${r.label(amharic: l.amharic)}\n${e.value.text}\n');
    }
    if (user.highlights.isNotEmpty) {
      b.writeln(
        '🖍 ${l('highlights')}: ${(user.highlights.keys.map(VerseRef.tryParseKey).whereType<VerseRef>().toList()..sort()).map((r) => r.label(amharic: l.amharic, short: true)).join(', ')}',
      );
    }
    await SharePlus.instance.share(ShareParams(text: b.toString()));
  }
}
