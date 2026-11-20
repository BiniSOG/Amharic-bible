import 'package:material_ui/material_ui.dart';

/// Brand palette inspired by Ethiopian manuscript art: deep green, gold and
/// a warm red accent on parchment.
class Brand {
  static const seed = Color(0xFF0E5A47);
  static const gold = Color(0xFFC9962B);
  static const red = Color(0xFFB3261E);
  static const parchment = Color(0xFFF6EEDC);
  static const sepiaText = Color(0xFF3B2F22);
}

enum ReaderTheme { system, light, sepia, dark }

/// Highlight colours (stored by index).
const List<Color> kHighlightColors = [
  Color(0xFFFFE066), // yellow
  Color(0xFF9BE59B), // green
  Color(0xFF8EC9FF), // blue
  Color(0xFFFFA8C5), // pink
  Color(0xFFFFC078), // orange
  Color(0xFFC9A7FF), // purple
];

const List<String> kHighlightNamesEn = [
  'Yellow',
  'Green',
  'Blue',
  'Pink',
  'Orange',
  'Purple',
];

/// Fonts bundled in pubspec.yaml.
const String kSerifEthiopic = 'NotoSerifEthiopic';
const String kSansEthiopic = 'NotoSansEthiopic';
const String kSerifLatin = 'NotoSerif';

ThemeData buildTheme(Brightness brightness, {bool sepia = false}) {
  var scheme = ColorScheme.fromSeed(
    seedColor: Brand.seed,
    brightness: brightness,
    secondary: Brand.gold,
    tertiary: Brand.red,
  );
  if (sepia) {
    scheme = scheme.copyWith(
      surface: Brand.parchment,
      onSurface: Brand.sepiaText,
      surfaceContainerLowest: const Color(0xFFFBF5E8),
      surfaceContainerLow: const Color(0xFFF2E7D0),
      surfaceContainer: const Color(0xFFEDE0C4),
      surfaceContainerHigh: const Color(0xFFE7D8B9),
      surfaceContainerHighest: const Color(0xFFE1D0AE),
    );
  }
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: kSansEthiopic,
    fontFamilyFallback: const [kSansEthiopic, kSerifEthiopic],
    scaffoldBackgroundColor: scheme.surface,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 68,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Font family to use for scripture text depending on language.
String scriptureFont(String lang) =>
    (lang == 'am' || lang == 'gez') ? kSerifEthiopic : kSerifLatin;
