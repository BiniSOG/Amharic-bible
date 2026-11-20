import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/reference.dart';
import '../core/theme.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._p) {
    _theme =
        ReaderTheme.values[(_p.getInt('theme') ?? 0).clamp(
          0,
          ReaderTheme.values.length - 1,
        )];
    _fontScale = _p.getDouble('fontScale') ?? 1.0;
    _lineHeight = _p.getDouble('lineHeight') ?? 1.7;
    _uiAmharic = _p.getBool('uiAmharic') ?? true;
    _primary = _p.getString('primary') ?? 'AM1954';
    _parallel = _p.getString('parallel');
    _showVerseNumbers = _p.getBool('verseNumbers') ?? true;
    _paragraphMode = _p.getBool('paragraphMode') ?? false;
    _ethiopicNumerals = _p.getBool('ethiopicNumerals') ?? false;
    _commentarySource = _p.getString('commentarySource') ?? 'mhc';
    _sideBySide = _p.getBool('sideBySide') ?? false;
    final last = _p.getString('lastRef');
    _last =
        (last != null ? VerseRef.tryParseKey(last) : null) ??
        const VerseRef(43, 1, 1);
  }

  final SharedPreferences _p;

  late ReaderTheme _theme;
  late double _fontScale;
  late double _lineHeight;
  late bool _uiAmharic;
  late String _primary;
  String? _parallel;
  late bool _showVerseNumbers;
  late bool _paragraphMode;
  late bool _ethiopicNumerals;
  late String _commentarySource;
  late bool _sideBySide;
  late VerseRef _last;

  ReaderTheme get theme => _theme;
  double get fontScale => _fontScale;
  double get lineHeight => _lineHeight;
  bool get uiAmharic => _uiAmharic;
  String get primary => _primary;
  String? get parallel => _parallel;
  bool get showVerseNumbers => _showVerseNumbers;
  bool get paragraphMode => _paragraphMode;
  bool get ethiopicNumerals => _ethiopicNumerals;
  String get commentarySource => _commentarySource;

  /// Parallel layout: false = stacked (line by line), true = two columns.
  bool get sideBySide => _sideBySide;
  set sideBySide(bool v) {
    _sideBySide = v;
    _p.setBool('sideBySide', v);
    notifyListeners();
  }

  VerseRef get lastRef => _last;

  ThemeMode get themeMode => switch (_theme) {
    ReaderTheme.system => ThemeMode.system,
    ReaderTheme.dark => ThemeMode.dark,
    _ => ThemeMode.light,
  };

  set theme(ReaderTheme v) {
    _theme = v;
    _p.setInt('theme', v.index);
    notifyListeners();
  }

  set fontScale(double v) {
    _fontScale = v.clamp(0.7, 2.2);
    _p.setDouble('fontScale', _fontScale);
    notifyListeners();
  }

  set lineHeight(double v) {
    _lineHeight = v.clamp(1.2, 2.4);
    _p.setDouble('lineHeight', _lineHeight);
    notifyListeners();
  }

  set uiAmharic(bool v) {
    _uiAmharic = v;
    _p.setBool('uiAmharic', v);
    notifyListeners();
  }

  set primary(String id) {
    _primary = id;
    if (_parallel == id) _parallel = null;
    _p.setString('primary', id);
    notifyListeners();
  }

  set parallel(String? id) {
    _parallel = id == _primary ? null : id;
    if (_parallel == null) {
      _p.remove('parallel');
    } else {
      _p.setString('parallel', _parallel!);
    }
    notifyListeners();
  }

  set showVerseNumbers(bool v) {
    _showVerseNumbers = v;
    _p.setBool('verseNumbers', v);
    notifyListeners();
  }

  set paragraphMode(bool v) {
    _paragraphMode = v;
    _p.setBool('paragraphMode', v);
    notifyListeners();
  }

  set ethiopicNumerals(bool v) {
    _ethiopicNumerals = v;
    _p.setBool('ethiopicNumerals', v);
    notifyListeners();
  }

  set commentarySource(String v) {
    _commentarySource = v;
    _p.setString('commentarySource', v);
    notifyListeners();
  }

  /// Saved without notifying (called while scrolling / paging).
  void rememberPosition(VerseRef r) {
    _last = r;
    _p.setString('lastRef', r.key);
  }

  String number(int n) =>
      _ethiopicNumerals ? toEthiopicNumeral(n) : n.toString();
}
