import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/books.dart';
import '../../core/l10n.dart';
import '../../core/reference.dart';
import '../../data/bible_repository.dart';
import '../../state/settings_controller.dart';

Color categoryColor(BookCategory c) => switch (c) {
  BookCategory.law => const Color(0xFF8D6E63),
  BookCategory.history => const Color(0xFF5C8D3E),
  BookCategory.poetry => const Color(0xFFC9962B),
  BookCategory.majorProphets => const Color(0xFFB3541E),
  BookCategory.minorProphets => const Color(0xFFD07A3A),
  BookCategory.gospels => const Color(0xFF1E6FB8),
  BookCategory.paul => const Color(0xFF6A4FB3),
  BookCategory.general => const Color(0xFF2B8C8C),
  BookCategory.prophecy => const Color(0xFFB3261E),
};

/// Full-screen picker: books → chapters → verses. Returns a [VerseRef].
class BookPickerScreen extends StatefulWidget {
  const BookPickerScreen({super.key, this.currentBook});
  final int? currentBook;

  @override
  State<BookPickerScreen> createState() => _BookPickerScreenState();
}

class _BookPickerScreenState extends State<BookPickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: (widget.currentBook ?? 1) >= 40 ? 1 : 0,
  );
  String _filter = '';
  bool _grid = true;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final am = l.amharic;
    final match = _filter.isEmpty
        ? null
        : kBooks.where((b) {
            final f = _filter.toLowerCase();
            return b.nameEn.toLowerCase().contains(f) ||
                b.nameAm.contains(_filter) ||
                b.shortAm.contains(_filter) ||
                b.shortEn.toLowerCase().startsWith(f);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l('books')),
        actions: [
          IconButton(
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l('searchHint'),
                  ),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                  onSubmitted: (v) {
                    final p = parseHumanReference(v);
                    if (p != null) {
                      Navigator.pop(
                        context,
                        VerseRef(p.book, p.chapter, p.fromVerse ?? 1),
                      );
                    }
                  },
                ),
              ),
              if (match == null)
                TabBar(
                  controller: _tabs,
                  tabs: [
                    Tab(text: l('oldTestament')),
                    Tab(text: l('newTestament')),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: match != null
          ? _BookList(
              books: match,
              am: am,
              grid: _grid,
              current: widget.currentBook,
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _BookList(
                  books: kBooks.where((b) => b.index < 40).toList(),
                  am: am,
                  grid: _grid,
                  current: widget.currentBook,
                ),
                _BookList(
                  books: kBooks.where((b) => b.index >= 40).toList(),
                  am: am,
                  grid: _grid,
                  current: widget.currentBook,
                ),
              ],
            ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({
    required this.books,
    required this.am,
    required this.grid,
    this.current,
  });
  final List<BibleBook> books;
  final bool am;
  final bool grid;
  final int? current;

  Future<void> _pick(BuildContext context, BibleBook b) async {
    final r = await Navigator.of(context).push<VerseRef>(
      MaterialPageRoute(builder: (_) => ChapterPickerScreen(book: b)),
    );
    if (r != null && context.mounted) Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!grid) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: books.length,
        itemBuilder: (_, i) {
          final b = books[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: categoryColor(b.category)
                  .withValues(alpha: 0.18),
              child: Text(
                b.short(am),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: categoryColor(b.category),
                ),
              ),
            ),
            title: Text(
              b.name(am),
              style: TextStyle(
                fontWeight: b.index == current ? FontWeight.w800 : null,
              ),
            ),
            subtitle: Text(am ? b.nameEn : b.nameAm),
            trailing: Text(
              '${b.chapters}',
              style: TextStyle(color: cs.outline),
            ),
            onTap: () => _pick(context, b),
          );
        },
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.25,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final b = books[i];
        final c = categoryColor(b.category);
        final isCur = b.index == current;
        return Material(
          color: c.withValues(alpha: isCur ? 0.32 : 0.13),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pick(context, b),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    b.short(am),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: c,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.name(am),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChapterPickerScreen extends StatelessWidget {
  const ChapterPickerScreen({super.key, required this.book});
  final BibleBook book;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = context.watch<SettingsController>();
    final cs = Theme.of(context).colorScheme;
    final color = categoryColor(book.category);
    return Scaffold(
      appBar: AppBar(title: Text(book.name(l.amharic))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 72,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: book.chapters,
        itemBuilder: (_, i) => Material(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context, VerseRef(book.index, i + 1, 1)),
            onLongPress: () async {
              final v = await Navigator.of(context).push<int>(
                MaterialPageRoute(
                  builder: (_) => VersePickerScreen(book: book, chapter: i + 1),
                ),
              );
              if (v != null && context.mounted) {
                Navigator.pop(context, VerseRef(book.index, i + 1, v));
              }
            },
            child: Center(
              child: Text(
                s.number(i + 1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VersePickerScreen extends StatelessWidget {
  const VersePickerScreen({
    super.key,
    required this.book,
    required this.chapter,
  });
  final BibleBook book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = context.watch<SettingsController>();
    final repo = context.read<BibleRepository>();
    final bible = repo.cached(s.primary);
    final n = bible?.chapter(book.index, chapter).length ?? 30;
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name(l.amharic)} $chapter · ${l('verse')}'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 64,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: n,
        itemBuilder: (_, i) => OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context, i + 1),
          child: Text(s.number(i + 1)),
        ),
      ),
    );
  }
}
