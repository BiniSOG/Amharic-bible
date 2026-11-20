import 'aa.dart';
import 'ar.dart';
import 'fr.dart';
import 'it.dart';
import 'om.dart';
import 'sgw.dart';
import 'so.dart';
import 'ti.dart';
import 'zh.dart';

/// Interface translations beyond the built-in English/Amharic table
/// (see `l10n.dart`). Missing keys fall back automatically.
const Map<String, Map<String, String>> kTranslations = {
  'om': kOm,
  'ti': kTi,
  'sgw': kSgw,
  'aa': kAa,
  'so': kSo,
  'ar': kAr,
  'fr': kFr,
  'it': kIt,
  'zh': kZh,
};
