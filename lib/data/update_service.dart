import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the app looks for release information. The file lives at the root
/// of the repository's default branch (see `version.json`).
const String kVersionUrl =
    'https://raw.githubusercontent.com/BiniSOG/Amharic-bible/HEAD/version.json';

enum UpdateKind { none, optional, required }

class UpdateInfo {
  const UpdateInfo({
    required this.kind,
    required this.latestVersion,
    required this.url,
    required this.notesEn,
    required this.notesAm,
    required this.latestBuild,
  });

  final UpdateKind kind;
  final String latestVersion;
  final int latestBuild;
  final String url;
  final String notesEn;
  final String notesAm;
}

/// Checks [kVersionUrl] on start-up.
///
/// * `min_build` higher than the installed build number → the user must
///   update before continuing (force update).
/// * `latest_build` higher → a dismissible "update available" prompt, shown
///   once per release.
class UpdateService {
  static const _kDismissed = 'update_dismissed_build';

  static Future<UpdateInfo?> check() async {
    if (kIsWeb) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final r = await http
          .get(Uri.parse(kVersionUrl))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return evaluate(j, current, defaultTargetPlatform);
    } catch (e) {
      debugPrint('update check failed: $e');
      return null;
    }
  }

  @visibleForTesting
  static UpdateInfo evaluate(
    Map<String, dynamic> j,
    int currentBuild,
    TargetPlatform platform,
  ) {
    final latest = (j['latest_build'] as num?)?.toInt() ?? 0;
    final min = (j['min_build'] as num?)?.toInt() ?? 0;
    final url = platform == TargetPlatform.iOS
        ? '${j['ios_url'] ?? j['android_url'] ?? ''}'
        : '${j['android_url'] ?? ''}';
    final kind = currentBuild < min
        ? UpdateKind.required
        : currentBuild < latest
        ? UpdateKind.optional
        : UpdateKind.none;
    return UpdateInfo(
      kind: kind,
      latestVersion: '${j['latest_version'] ?? ''}',
      latestBuild: latest,
      url: url,
      notesEn: '${j['notes_en'] ?? ''}',
      notesAm: '${j['notes_am'] ?? ''}',
    );
  }

  static Future<bool> wasDismissed(int build) async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kDismissed) ?? 0) >= build;
  }

  static Future<void> dismiss(int build) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDismissed, build);
  }
}
