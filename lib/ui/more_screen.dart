import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../state/settings_controller.dart';
import 'dictionary_screen.dart';
import 'language_picker.dart';
import 'kids/kids_screen.dart';
import 'library_screen.dart';
import 'my_library_screen.dart';
import 'reader/reader_sheets.dart';
import 'search_screen.dart';
import 'widgets/common.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = context.watch<SettingsController>();
    final cs = Theme.of(context).colorScheme;
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    Widget tile(
      IconData icon,
      Color color,
      String title,
      VoidCallback onTap, {
      String? subtitle,
    }) => ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l('more'))),
          SliverList.list(
            children: [
              SectionHeader(l('tools')),
              tile(
                Icons.child_care_outlined,
                const Color(0xFFD81B60),
                l('kidsTitle'),
                () => push(const KidsScreen()),
                subtitle: l('kidsSubtitle'),
              ),
              tile(
                Icons.quiz_outlined,
                const Color(0xFF1565C0),
                l('bibleQuiz'),
                () => context.read<AppNav>().setTab(3),
                subtitle: l('quizSubtitle'),
              ),
              tile(Icons.search, cs.primary, l('search'), () async {
                final r = await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
                if (r != null && context.mounted) {
                  context.read<AppNav>().openInBible(r);
                }
              }),
              tile(
                Icons.local_library_outlined,
                const Color(0xFF6D4C41),
                l('bibleDictionary'),
                () => push(const DictionaryScreen()),
                subtitle: '${l('glossary')} · ${l('easton')}',
              ),
              tile(
                Icons.collections_bookmark_outlined,
                const Color(0xFFC9962B),
                l('myLibrary'),
                () => push(const MyLibraryScreen()),
              ),
              tile(
                Icons.translate,
                const Color(0xFF6A1B9A),
                l('library'),
                () => push(const LibraryScreen()),
              ),
              SectionHeader(l('settings')),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l('uiLanguage')),
                subtitle: Text(appLanguage(s.uiLang).nativeName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLanguagePicker(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.emergency_outlined),
                title: Text(l('xrefMarkers')),
                value: s.showXrefMarkers,
                onChanged: (v) => s.showXrefMarkers = v,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: TextSettingsPanel(),
              ),
              SectionHeader(l('about')),
              tile(
                Icons.info_outline,
                cs.secondary,
                l('about'),
                () => push(const AboutScreen()),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    const credits = [
      (
        'መጽሐፍ ቅዱስ 1954 (Amharic)',
        'Text via open datasets: biniama/ethiopic-bible-data (ethiopicbible.com) and magna25/amharic-bible-json (wordproject.org, MIT).',
      ),
      ('Ge\'ez (partial)', 'biniama/ethiopic-bible-data (ethiopicbible.com).'),
      (
        'English versions',
        'Public-domain and free texts via scrollmapper/bible_databases; optional catalogue from bible.helloao.org.',
      ),
      ('Matthew Henry Complete Commentary', 'lyteword/mhenry-complete — CC0.'),
      (
        'Calvin, Scofield, Gaebelein, F. B. Meyer',
        'thefrenchpressed/pillar-commentary-data — public-domain text, MIT conversion.',
      ),
      (
        'JFB, Clarke, Gill, Keil & Delitzsch, Tyndale notes',
        'Free Use Bible API — bible.helloao.org.',
      ),
      (
        'Cross references',
        'Treasury of Scripture Knowledge via CrossReferences.org — CC BY 4.0.',
      ),
      (
        'Easton\'s Bible Dictionary (1897)',
        'Public domain; JSON by garydavenport73 (MIT).',
      ),
      (
        'Fonts',
        'Noto Serif Ethiopic, Noto Sans Ethiopic, Noto Serif — SIL Open Font License.',
      ),
      (
        "KJV with Strong's numbers",
        'Tags via kaiserlik/kjv (KJV text public domain).',
      ),
      (
        "Strong's Hebrew & Greek dictionaries (1890)",
        'Public domain; JSON by Open Scriptures — CC BY-SA.',
      ),
      (
        'Chinese Union Version, French Darby / Crampon / Synodale',
        'Public-domain texts via scrollmapper/bible_databases.',
      ),
      (
        'Kids stories, Bible quiz, glossary & plans',
        'Written for this app; free to use.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l('about'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 96,
                  height: 96,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'መጽሐፍ ቅዱስ · Amharic Bible',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                l('wordOfGod'),
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),
            for (final (t, d) in credits)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(d),
              ),
            const SizedBox(height: 12),
            Text(
              l('licenseNote'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showLicensePage(context: context),
              child: const Text('Open-source licenses'),
            ),
          ],
        ),
      ),
    );
  }
}
