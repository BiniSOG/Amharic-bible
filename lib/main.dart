import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'data/bible_repository.dart';
import 'data/commentary_service.dart';
import 'data/stories.dart';
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
        Provider(create: (_) => CrossRefService()..warmUp()),
        Provider(create: (_) => DictionaryService()),
        Provider(create: (_) => StoriesRepository()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, s, _) => MaterialApp(
          title: 'Amharic Bible · መጽሐፍ ቅዱስ',
          debugShowCheckedModeBanner: false,
          themeMode: s.themeMode,
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
