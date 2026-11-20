import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'data/bible_repository.dart';
import 'data/commentary_service.dart';
import 'data/stories.dart';
import 'data/strongs_service.dart';
import 'data/study_data.dart';
import 'data/tts_service.dart';
import 'state/settings_controller.dart';
import 'state/user_data_controller.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(AmharicBibleApp(prefs: prefs));
}

class AmharicBibleApp extends StatelessWidget {
  const AmharicBibleApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
        ChangeNotifierProvider(create: (_) => UserDataController(prefs)),
        ChangeNotifierProvider(create: (_) => BibleRepository(prefs)),
        ChangeNotifierProvider(create: (_) => TtsService()),
        Provider(create: (_) => CommentaryService()),
        ChangeNotifierProvider(create: (_) => CrossRefService()..warmUp()),
        Provider(create: (c) => StrongsService(c.read<BibleRepository>())),
        Provider(create: (_) => DictionaryService()),
        Provider(create: (_) => StoriesRepository()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, s, _) => MaterialApp(
          title: 'Amharic Bible · መጽሐፍ ቅዱስ',
          debugShowCheckedModeBanner: false,
          themeMode: s.themeMode,
          locale: _materialLocale(s.uiLang),
          supportedLocales: const [
            Locale('en'),
            Locale('am'),
            Locale('ar'),
            Locale('fr'),
            Locale('it'),
            Locale('zh'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => Directionality(
            textDirection: appLanguage(s.uiLang).rtl
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child!,
          ),
          theme: buildTheme(
            Brightness.light,
            sepia: s.theme == ReaderTheme.sepia,
          ),
          darkTheme: buildTheme(Brightness.dark),
          home: const HomeShell(),
        ),
      ),
    );
  }
}

/// Material's built-in strings exist for these languages; others use English
/// for system widgets while the app's own text follows [L].
Locale _materialLocale(String code) =>
    const {'am', 'ar', 'fr', 'it', 'zh'}.contains(code)
    ? Locale(code)
    : const Locale('en');
