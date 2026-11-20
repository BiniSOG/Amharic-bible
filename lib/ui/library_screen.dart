import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../data/bible_repository.dart';
import '../data/translation_catalog.dart';
import '../state/settings_controller.dart';
import 'widgets/common.dart';

/// Manage Bible versions: bundled, downloaded and available.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  final Set<String> _open = {};
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    context.read<BibleRepository>().refreshOnlineCatalog();
  }

  bool _matches(TranslationInfo t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.name.toLowerCase().contains(q) ||
        t.abbr.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q) ||
        bibleLangName(t.lang).toLowerCase().contains(q) ||
        bibleLangEnglishName(t.lang).toLowerCase().contains(q);
  }

  /// Languages in display order, then any others found in the catalogue.
  List<String> _languages(Iterable<TranslationInfo> all) {
    final extra = all.map((t) => t.lang).toSet()..removeAll(kBibleLangOrder);
    return [...kBibleLangOrder, ...extra.toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final repo = context.watch<BibleRepository>();
    final s = context.watch<SettingsController>();
    if (!_initialised) {
      // Open the reader's own language groups first.
      _open.addAll({'am', if (!l.amharic) s.uiLang});
      _initialised = true;
    }
    final installed = repo.installed.where(_matches).toList();
    final available = repo.downloadable.where(_matches).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l('library')),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(118),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l('searchVersions'),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: '${l('installed')} (${repo.installed.length})'),
                    Tab(text: '${l('download')} (${repo.downloadable.length})'),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add_link),
          label: Text(l('addFromUrl')),
          onPressed: () => _addCustom(context),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _installedTab(context, installed, s, repo, l),
              _downloadTab(context, available, repo, l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _installedTab(
    BuildContext context,
    List<TranslationInfo> list,
    SettingsController s,
    BibleRepository repo,
    L l,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (list.isEmpty) {
      return EmptyState(icon: Icons.search_off, text: l('noResults'));
    }
    final langs = _languages(list).where((c) => list.any((t) => t.lang == c));
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        for (final code in langs) ...[
          _LangHeader(
            code: code,
            count: list.where((t) => t.lang == code).length,
          ),
          for (final t in list.where((t) => t.lang == code))
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
              title: Text(
                t.name,
                style: TextStyle(
                  fontWeight: s.primary == t.id ? FontWeight.w800 : null,
                ),
              ),
              subtitle: Text(
                [
                  t.abbr,
                  if (t.scope == TranslationScope.newTestament)
                    l('newTestament'),
                  if (t.bundled) l('builtIn'),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: s.primary == t.id
                  ? Icon(Icons.check_circle, color: cs.primary)
                  : t.bundled
                  ? null
                  : IconButton(
                      tooltip: l('remove'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        if (s.parallel == t.id) s.parallel = null;
                        repo.remove(t.id);
                      },
                    ),
              onTap: () {
                s.primary = t.id;
                showSnack(context, t.name);
              },
            ),
        ],
      ],
    );
  }

  Widget _downloadTab(
    BuildContext context,
    List<TranslationInfo> list,
    BibleRepository repo,
    L l,
  ) {
    final cs = Theme.of(context).colorScheme;
    final searching = _query.isNotEmpty;
    final all = _languages(list)
        .where((c) => !searching || list.any((t) => t.lang == c))
        .toList();
    // Languages with something to download first, empty ones last.
    final langs = [
      ...all.where((c) => list.any((t) => t.lang == c)),
      ...all.where((c) => !list.any((t) => t.lang == c)),
    ];
    if (langs.isEmpty) {
      return EmptyState(icon: Icons.search_off, text: l('noResults'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        for (final code in langs)
          Builder(
            builder: (context) {
              final items = list.where((t) => t.lang == code).toList();
              final open = searching || _open.contains(code);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                color: items.isEmpty ? cs.surfaceContainerLowest : null,
                child: Column(
                  children: [
                    ListTile(
                      leading: _LangBadge(code),
                      title: Text(
                        bibleLangName(code),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${bibleLangEnglishName(code)} · '
                        '${items.length} ${l('versions').toLowerCase()}',
                      ),
                      trailing: Icon(
                        open ? Icons.expand_less : Icons.expand_more,
                      ),
                      onTap: () => setState(
                        () => open ? _open.remove(code) : _open.add(code),
                      ),
                    ),
                    if (open && items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l('noFreeVersion'),
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add_link),
                              label: Text(l('addFromUrl')),
                              onPressed: () =>
                                  _addCustom(context, presetLang: code),
                            ),
                          ],
                        ),
                      ),
                    if (open)
                      for (final t in items) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _DownloadTile(t: t, repo: repo, l: l),
                      ],
                  ],
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            l('licenseNote'),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Future<void> _addCustom(BuildContext context, {String? presetLang}) async {
    final l = L.read(context);
    final url = TextEditingController();
    final name = TextEditingController();
    var lang = presetLang ?? 'am';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(l('addFromUrl')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(hintText: l('pasteLink')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: name,
                decoration: InputDecoration(hintText: l('versionName')),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: lang,
                decoration: InputDecoration(labelText: l('language')),
                items: [
                  for (final code in kBibleLangOrder)
                    DropdownMenuItem(
                      value: code,
                      child: Text(
                        '${bibleLangName(code)} · ${bibleLangEnglishName(code)}',
                      ),
                    ),
                ],
                onChanged: (v) => setD(() => lang = v ?? lang),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l('add')),
            ),
          ],
        ),
      ),
    );
    if (ok != true || url.text.trim().isEmpty || !context.mounted) return;
    final repo = context.read<BibleRepository>();
    final success = await repo.addCustom(
      url.text.trim(),
      name.text.trim().isEmpty ? 'Custom' : name.text.trim(),
      lang,
    );
    if (context.mounted && !success) showSnack(context, l('downloadFailed'));
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge(this.lang);
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (lang) {
      'am' => ('አማ', cs.primary),
      'gez' => ('ግዕ', cs.tertiary),
      'ti' => ('ትግ', cs.primary),
      'sgw' => ('ጉራ', cs.primary),
      _ => (lang.toUpperCase(), cs.secondary),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LangHeader extends StatelessWidget {
  const _LangHeader({required this.code, required this.count});
  final String code;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Row(
        children: [
          _LangBadge(code),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bibleLangName(code),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  bibleLangEnglishName(code),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('$count', style: TextStyle(color: cs.outline)),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.t, required this.repo, required this.l});
  final TranslationInfo t;
  final BibleRepository repo;
  final L l;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(t.name),
      subtitle: Text(
        [
          t.abbr,
          if (t.description.isNotEmpty) t.description,
          if (t.scope == TranslationScope.newTestament) l('newTestament'),
          t.license,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: switch (repo.downloadState[t.id]) {
        DownloadState.downloading => SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            value: repo.downloadProgress[t.id],
            strokeWidth: 3,
          ),
        ),
        DownloadState.failed => IconButton(
          tooltip: l('retry'),
          icon: Icon(Icons.refresh_rounded, color: cs.error),
          onPressed: () => repo.download(t),
        ),
        _ => IconButton.filledTonal(
          tooltip: l('download'),
          icon: const Icon(Icons.download),
          onPressed: () => repo.download(t),
        ),
      },
    );
  }
}
