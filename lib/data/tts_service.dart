import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Read-aloud using the device's text-to-speech engine.
class TtsService extends ChangeNotifier {
  FlutterTts? _tts;
  bool _speaking = false;
  bool get speaking => _speaking;

  Future<FlutterTts> _engine() async {
    if (_tts != null) return _tts!;
    final t = FlutterTts();
    t.setCompletionHandler(() => _set(false));
    t.setCancelHandler(() => _set(false));
    t.setErrorHandler((_) => _set(false));
    await t.awaitSpeakCompletion(false);
    _tts = t;
    return t;
  }

  void _set(bool v) {
    _speaking = v;
    notifyListeners();
  }

  /// Returns false if no voice exists for the language.
  Future<bool> speak(String text, String lang) async {
    try {
      final t = await _engine();
      final code = switch (lang) {
        'am' || 'gez' => 'am-ET',
        _ => 'en-US',
      };
      final ok = await t.isLanguageAvailable(code);
      if (ok != true && code != 'en-US') return false;
      await t.setLanguage(code);
      await t.setSpeechRate(0.45);
      _set(true);
      await t.speak(text);
      return true;
    } catch (e) {
      debugPrint('tts: $e');
      _set(false);
      return false;
    }
  }

  Future<void> stop() async {
    await _tts?.stop();
    _set(false);
  }
}
