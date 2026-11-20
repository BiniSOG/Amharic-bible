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
  String _lang = 'all';

  @override
  void initState() {
    super.initState();
    context.read<BibleRepository>().refreshOnlineCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final repo = context.watch<BibleRepository>();
    final s = context.watch<SettingsController>();
    final cs = Theme.of(context).colorScheme;
    bool keep(TranslationInfo t) => _lang == 'all' || t.lang == _lang;
    final installed = repo.installed.where(keep).toList();
    final available = repo.downloadable.where(keep).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l('library'))),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_link),
        label: Text(l('addFromUrl')),
        onPressed: () => _addCustom(context),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: [
                  for (final (k, label) in [
                    ('all', l('all')),
                    ('am', l('amharic')),
                    ('en', l('english')),
                    ('gez', l('geez')),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _lang == k,
                        onSelected: (_) => setState(() => _lang = k),
                      ),
                    ),
                ],
              ),
            ),
            SectionHeader(l('installed')),
            for (final t in installed)
              ListTile(
                leading: _LangBadge(t.lang),
                title: Text(t.name),
                subtitle: Text(
                  [
                    t.abbr,
                    if (t.scope == TranslationScope.newTestament) 'NT',
                    if (t.scope == TranslationScope.partial) '•',
                    t.license,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: t.bundled
                    ? (s.primary == t.id
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : null)
                    : IconButton(
                        tooltip: l('remove'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          if (s.primary == t.id) s.primary = 'AM1954';
                          if (s.parallel == t.id) s.parallel = null;
                          repo.remove(t.id);
                        },
                      ),
                onTap: () {
                  s.primary = t.id;
                  showSnack(context, t.name);
                },
              ),
            SectionHeader(l('available')),
            for (final t in available)
              ListTile(
                leading: _LangBadge(t.lang),
                title: Text(t.name),
                subtitle: Text(
                  [
                    if (t.description.isNotEmpty) t.description,
                    if (t.scope == TranslationScope.newTestament)
                      l('newTestament'),
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
                    icon: Icon(Icons.error_outline, color: cs.error),
                    onPressed: () => repo.download(t),
                  ),
                  _ => IconButton.filledTonal(
                    tooltip: l('download'),
                    icon: const Icon(Icons.download),
                    onPressed: () => repo.download(t),
                  ),
                },
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l('licenseNote'),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustom(BuildContext context) async {
    final l = L.read(context);
    final url = TextEditingController();
    final name = TextEditingController();
    var lang = 'am';
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
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'am', label: Text(l('amharic'))),
                  ButtonSegment(value: 'en', label: Text(l('english'))),
                ],
                selected: {lang},
                onSelectionChanged: (v) => setD(() => lang = v.first),
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
      _ => ('EN', cs.secondary),
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
