import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/settings_controller.dart';
import 'i18n/translations.dart';

/// A language the app's interface can be shown in.
class AppLanguage {
  const AppLanguage(
    this.code,
    this.nativeName,
    this.englishName, {
    this.ethiopic = false,
    this.rtl = false,
    this.complete = true,
  });

  final String code;
  final String nativeName;
  final String englishName;

  /// Uses Ethiopic script: book names, stories and plans are shown in Amharic.
  final bool ethiopic;
  final bool rtl;

  /// False when only part of the interface is translated yet (the rest falls
  /// back to Amharic or English).
  final bool complete;
}

const List<AppLanguage> kAppLanguages = [
  AppLanguage('am', 'አማርኛ', 'Amharic', ethiopic: true),
  AppLanguage('en', 'English', 'English'),
  AppLanguage('om', 'Afaan Oromoo', 'Oromo'),
  AppLanguage('ti', 'ትግርኛ', 'Tigrinya', ethiopic: true),
  AppLanguage('sgw', 'ጉራጊኛ', 'Gurage', ethiopic: true, complete: false),
  AppLanguage('aa', 'Qafaraf', 'Afar', complete: false),
  AppLanguage('so', 'Soomaali', 'Somali'),
  AppLanguage('ar', 'العربية', 'Arabic', rtl: true),
  AppLanguage('fr', 'Français', 'French'),
  AppLanguage('it', 'Italiano', 'Italian'),
  AppLanguage('zh', '中文', 'Chinese'),
];

AppLanguage appLanguage(String code) => kAppLanguages.firstWhere(
  (l) => l.code == code,
  orElse: () => kAppLanguages.first,
);

/// Interface strings. English and Amharic are complete; other languages
/// override them and fall back to Amharic (Ethiopic-script languages) or
/// English for anything not yet translated.
class L {
  const L(this.lang);
  final String lang;

  /// True for Ethiopic-script interfaces (Amharic, Tigrinya, Gurage): book
  /// names and Amharic content (stories, plans, glossary) are used.
  bool get amharic => appLanguage(lang).ethiopic;
  bool get rtl => appLanguage(lang).rtl;

  static L of(BuildContext context) =>
      L(context.select<SettingsController, String>((s) => s.uiLang));

  /// Non-listening variant for callbacks.
  static L read(BuildContext context) =>
      L(context.read<SettingsController>().uiLang);

  String t(String key) {
    final v = kTranslations[lang]?[key];
    if (v != null) return v;
    final e = _strings[key];
    if (e == null) return key;
    return amharic ? e.$2 : e.$1;
  }

  String call(String key) => t(key);
}

const Map<String, (String, String)> _strings = {
  'today': ('Today', 'ዛሬ'),
  'bible': ('Bible', 'መጽሐፍ ቅዱስ'),
  'plans': ('Plans', 'የንባብ እቅድ'),
  'kids': ('Kids', 'ልጆች'),
  'more': ('More', 'ተጨማሪ'),
  'verseOfDay': ('Verse of the Day', 'የዕለቱ ጥቅስ'),
  'continueReading': ('Continue reading', 'ንባብዎን ይቀጥሉ'),
  'goodMorning': ('Good morning', 'እንደምን አደሩ'),
  'goodAfternoon': ('Good afternoon', 'እንደምን ዋሉ'),
  'goodEvening': ('Good evening', 'እንደምን አመሹ'),
  'search': ('Search', 'ፈልግ'),
  'searchHint': (
    'Search words or a reference (John 3:16)',
    'ቃል ወይም ጥቅስ ይፈልጉ (ዮሐ 3:16)',
  ),
  'all': ('All', 'ሁሉም'),
  'oldTestament': ('Old Testament', 'ብሉይ ኪዳን'),
  'newTestament': ('New Testament', 'ሐዲስ ኪዳን'),
  'results': ('results', 'ውጤቶች'),
  'noResults': ('No results', 'ምንም አልተገኘም'),
  'books': ('Books', 'መጻሕፍት'),
  'chapters': ('Chapters', 'ምዕራፎች'),
  'verse': ('Verse', 'ቁጥር'),
  'copy': ('Copy', 'ቅዳ'),
  'copied': ('Copied to clipboard', 'ተቀድቷል'),
  'share': ('Share', 'አጋራ'),
  'highlight': ('Highlight', 'አድምቅ'),
  'bookmark': ('Bookmark', 'ምልክት'),
  'bookmarked': ('Bookmarked', 'ምልክት ተደርጓል'),
  'note': ('Note', 'ማስታወሻ'),
  'notes': ('Notes', 'ማስታወሻዎች'),
  'notePlaceholder': (
    'Write your thoughts, prayer or insight…',
    'ሀሳብዎን፣ ጸሎትዎን ወይም ማስተዋልዎን ይጻፉ…',
  ),
  'save': ('Save', 'አስቀምጥ'),
  'cancel': ('Cancel', 'ሰርዝ'),
  'delete': ('Delete', 'አጥፋ'),
  'commentary': ('Commentary', 'ማብራሪያ'),
  'crossRefs': ('Cross references', 'ተዛማጅ ጥቅሶች'),
  'compare': ('Compare', 'አወዳድር'),
  'image': ('Verse image', 'የጥቅስ ምስል'),
  'listen': ('Listen', 'አድምጥ'),
  'stop': ('Stop', 'አቁም'),
  'dictionary': ('Dictionary', 'መዝገበ ቃላት'),
  'bibleDictionary': ('Bible Dictionary', 'የመጽሐፍ ቅዱስ መዝገበ ቃላት'),
  'dictionaryHint': ('Look up a word…', 'ቃል ይፈልጉ…'),
  'clear': ('Clear', 'አጽዳ'),
  'parallel': ('Parallel', 'ጎን ለጎን'),
  'parallelOff': ('Single version', 'አንድ ትርጉም'),
  'layoutStacked': ('Line by line', 'በመስመር'),
  'layoutColumns': ('Side by side', 'ጎን ለጎን'),
  'parallelLayout': ('Parallel layout', 'የሁለት ትርጉም አቀማመጥ'),
  'quiz2': ('Quiz', 'ጥያቄ'),
  'bibleQuiz': ('Bible Quiz', 'የመጽሐፍ ቅዱስ ጥያቄዎች'),
  'quizSubtitle': (
    'Test and grow your Bible knowledge',
    'የመጽሐፍ ቅዱስ እውቀትዎን ይፈትኑ፤ ያሳድጉ',
  ),
  'easy': ('Easy', 'ቀላል'),
  'medium': ('Medium', 'መካከለኛ'),
  'hard': ('Hard', 'ከባድ'),
  'mixed': ('Mixed', 'የተቀላቀለ'),
  'questions': ('questions', 'ጥያቄዎች'),
  'bestScore': ('Best', 'ከፍተኛ'),
  'quickRound': ('10 questions', '10 ጥያቄዎች'),
  'fullRound': ('All questions', 'ሁሉም ጥያቄዎች'),
  'question': ('Question', 'ጥያቄ'),
  'next': ('Next', 'ቀጣይ'),
  'finish': ('Finish', 'ጨርስ'),
  'yourScore': ('Your score', 'ውጤትዎ'),
  'review': ('Review answers', 'መልሶችን ይገምግሙ'),
  'playAgain': ('Play again', 'እንደገና ይጫወቱ'),
  'correctAnswer': ('Correct answer', 'ትክክለኛው መልስ'),
  'wrong': ('Not quite', 'ልክ አይደለም'),
  'answered': ('Answered', 'የተመለሱ'),
  'accuracy': ('Accuracy', 'ትክክለኛነት'),
  'excellent': ('Excellent!', 'እጅግ በጣም ጥሩ!'),
  'goodJob': ('Good job!', 'ጥሩ ነው!'),
  'keepLearning': ('Keep learning!', 'መማርዎን ይቀጥሉ!'),
  'timer': ('Timer (20 s)', 'ሰዓት ቆጣሪ (20 ሰ)'),
  'timeUp': ('Time is up', 'ጊዜው አልቋል'),
  'chooseVerse': (
    'Long-press a chapter to pick a verse',
    'ቁጥር ለመምረጥ ምዕራፉን ተጭነው ይያዙ',
  ),
  'chooseVersion': ('Choose version', 'ትርጉም ይምረጡ'),
  'secondVersion': ('Second version', 'ሁለተኛ ትርጉም'),
  'versions': ('Versions', 'ትርጉሞች'),
  'library': ('Bible versions', 'የመጽሐፍ ቅዱስ ትርጉሞች'),
  'installed': ('On this device', 'በዚህ ስልክ ላይ'),
  'available': ('Available to download', 'ለማውረድ ዝግጁ'),
  'download': ('Download', 'አውርድ'),
  'remove': ('Remove', 'አስወግድ'),
  'amharic': ('Amharic', 'አማርኛ'),
  'english': ('English', 'እንግሊዝኛ'),
  'geez': ('Ge\'ez', 'ግዕዝ'),
  'addFromUrl': ('Add from link', 'ከሊንክ ያክሉ'),
  'myLibrary': ('My notes & highlights', 'የእኔ ማስታወሻዎችና ማድመቂያዎች'),
  'highlights': ('Highlights', 'ማድመቂያዎች'),
  'bookmarks': ('Bookmarks', 'ምልክቶች'),
  'history': ('History', 'ታሪክ'),
  'nothingYet': ('Nothing here yet', 'እስካሁን ምንም የለም'),
  'settings': ('Settings', 'ማስተካከያ'),
  'theme': ('Theme', 'ገጽታ'),
  'light': ('Light', 'ብሩህ'),
  'sepia': ('Sepia', 'ሴፒያ'),
  'dark': ('Dark', 'ጨለማ'),
  'system': ('System', 'እንደ ስልኩ'),
  'fontSize': ('Text size', 'የፊደል መጠን'),
  'lineHeight': ('Line spacing', 'የመስመር ክፍተት'),
  'uiLanguage': ('App language', 'የመተግበሪያ ቋንቋ'),
  'verseNumbers': ('Show verse numbers', 'የቁጥር ምልክቶችን አሳይ'),
  'redLetters': ('Paragraph mode', 'በአንቀጽ አሳይ'),
  'ethiopicNumerals': ('Ethiopic numerals', 'የግዕዝ ቁጥሮች'),
  'about': ('About & licenses', 'ስለ መተግበሪያው'),
  'readingPlans': ('Reading Plans', 'የንባብ እቅዶች'),
  'myPlans': ('My plans', 'የእኔ እቅዶች'),
  'discoverPlans': ('Discover plans', 'እቅዶችን ያግኙ'),
  'startPlan': ('Start plan', 'እቅዱን ጀምር'),
  'stopPlan': ('Stop plan', 'እቅዱን አቁም'),
  'restartPlan': ('Restart', 'እንደገና ጀምር'),
  'day': ('Day', 'ቀን'),
  'days': ('days', 'ቀናት'),
  'markComplete': ('Mark day complete', 'ቀኑን እንደጨረሱ ምልክት ያድርጉ'),
  'completed': ('Completed', 'ተጠናቋል'),
  'todaysReading': ('Today\'s reading', 'የዛሬ ንባብ'),
  'progress': ('Progress', 'ሂደት'),
  'behind': ('days behind', 'ቀናት ወደኋላ'),
  'onTrack': ('On track', 'በትክክለኛው መንገድ'),
  'read': ('Read', 'አንብብ'),
  'kidsTitle': ('Bible Stories for Kids', 'የልጆች የመጽሐፍ ቅዱስ ታሪኮች'),
  'kidsSubtitle': (
    'Learn God\'s Word through stories',
    'የእግዚአብሔርን ቃል በታሪክ ይማሩ',
  ),
  'lesson': ('What we learn', 'የምንማረው'),
  'memoryVerse': ('Memory verse', 'የሚጠና ጥቅስ'),
  'quiz': ('Quiz time!', 'የጥያቄ ጊዜ!'),
  'prayer': ('Let\'s pray', 'እንጸልይ'),
  'readInBible': ('Read it in the Bible', 'በመጽሐፍ ቅዱስ አንብብ'),
  'correct': ('Correct! Well done!', 'ትክክል! ጎበዝ!'),
  'tryAgain': ('Try again', 'እንደገና ሞክር'),
  'readAloud': ('Read aloud', 'ጮክ ብለህ አንብብ'),
  'commentaryOffline': (
    'Commentary needs an internet connection the first time. '
        'It is saved for offline use afterwards.',
    'ማብራሪያው ለመጀመሪያ ጊዜ ኢንተርኔት ይፈልጋል። ከዚያ በኋላ ያለ ኢንተርኔት ይሰራል።',
  ),
  'retry': ('Retry', 'እንደገና ሞክር'),
  'fullChapter': ('Full chapter commentary', 'የምዕራፉ ሙሉ ማብራሪያ'),
  'onThisVerse': ('On this verse', 'በዚህ ቁጥር ላይ'),
  'noCommentary': (
    'No commentary on this passage from this source.',
    'ከዚህ ምንጭ ለዚህ ክፍል ማብራሪያ የለም።',
  ),
  'noCrossRefs': (
    'No cross references for this verse.',
    'ለዚህ ቁጥር ተዛማጅ ጥቅስ የለም።',
  ),
  'myNote': ('My note', 'የእኔ ማስታወሻ'),
  'notInVersion': (
    'This passage is not available in this version.',
    'ይህ ክፍል በዚህ ትርጉም ውስጥ የለም።',
  ),
  'background': ('Background', 'ዳራ'),
  'shareImage': ('Share image', 'ምስሉን አጋራ'),
  'ttsUnavailable': (
    'Text-to-speech is not available for this language on '
        'your device.',
    'በስልክዎ ላይ ለዚህ ቋንቋ የድምጽ ንባብ አልተገኘም።',
  ),
  'prevChapter': ('Previous chapter', 'ቀዳሚ ምዕራፍ'),
  'nextChapter': ('Next chapter', 'ቀጣይ ምዕራፍ'),
  'tools': ('Study tools', 'የጥናት መሳሪያዎች'),
  'goTo': ('Go to', 'ሂድ'),
  'pasteLink': ('Paste a link to a Bible JSON file', 'የJSON ፋይል ሊንክ ያስገቡ'),
  'versionName': ('Version name', 'የትርጉሙ ስም'),
  'add': ('Add', 'ጨምር'),
  'licenseNote': (
    'Only openly licensed texts are included. Copyrighted '
        'versions (e.g. NIV, ESV, Amharic 2000 Standard) can be added from a '
        'link once you have permission to use them.',
    'በነጻ ፈቃድ የተሰጡ ትርጉሞች ብቻ ተካተዋል። የቅጂ መብት ያላቸው ትርጉሞችን ፈቃድ ካገኙ በኋላ በሊንክ ማከል ይችላሉ።',
  ),
  'streak': ('day streak', 'ተከታታይ ቀናት'),
  'quickAccess': ('Quick access', 'ፈጣን መዳረሻ'),
  'wordOfGod': ('Read God\'s Word daily', 'የእግዚአብሔርን ቃል በየቀኑ ያንብቡ'),
  'version': ('Version', 'ትርጉም'),
  'glossary': ('Amharic glossary', 'የአማርኛ መዝገበ ቃላት'),
  'easton': ('Easton\'s Dictionary', 'የኢስተን መዝገበ ቃላት'),
  'relatedVerses': ('Key verses', 'ዋና ጥቅሶች'),
  'downloadFailed': (
    'Download failed. Check your connection.',
    'ማውረድ አልተሳካም። ኢንተርኔትዎን ያረጋግጡ።',
  ),
  'strongs': ("Strong's", 'ስትሮንግ'),
  'strongsTitle': ("Strong's Dictionary", 'የስትሮንግ መዝገበ ቃላት'),
  'strongsHint': (
    'Tap a number to see the original Hebrew or Greek word',
    'የመጀመሪያውን የዕብራይስጥ ወይም የግሪክ ቃል ለማየት ቁጥሩን ይንኩ',
  ),
  'greek': ('Greek', 'ግሪክ'),
  'hebrew': ('Hebrew', 'ዕብራይስጥ'),
  'transliteration': ('Transliteration', 'አጻጻፍ በላቲን'),
  'pronunciation': ('Pronunciation', 'አነባበብ'),
  'derivation': ('Derivation', 'ምንጭ'),
  'definition': ('Definition', 'ትርጉም'),
  'kjvUsage': ('KJV usage', 'በKJV የተተረጎመበት'),
  'occursTimes': ('Occurrences in KJV', 'በKJV ውስጥ የተገኘበት ብዛት'),
  'findAllVerses': ('Find all verses', 'ሁሉንም ጥቅሶች ፈልግ'),
  'showAll': ('Show all', 'ሁሉንም አሳይ'),
  'xrefMarkers': ('Cross-reference markers (*)', 'የተዛማጅ ጥቅስ ምልክቶች (*)'),
  'updateAvailable': ('Update available', 'አዲስ ዝማኔ አለ'),
  'updateRequired': ('Update required', 'ማዘመን ያስፈልጋል'),
  'updateRequiredBody': (
    'This version is no longer supported. Please install the latest version to continue.',
    'ይህ ስሪት ከአሁን በኋላ አይደገፍም። ለመቀጠል እባክዎ አዲሱን ስሪት ይጫኑ።',
  ),
  'updateNow': ('Update now', 'አሁን አዘምን'),
  'later': ('Later', 'በኋላ'),
  'language': ('Language', 'ቋንቋ'),
  'chooseLanguage': ('Choose language', 'ቋንቋ ይምረጡ'),
  'searchVersions': ('Search versions or languages', 'ትርጉም ወይም ቋንቋ ይፈልጉ'),
  'builtIn': ('Built in', 'አብሮ የተካተተ'),
  'noFreeVersion': (
    'No free version is available to download yet. If you have permission to use one, add it from a link.',
    'እስካሁን በነጻ ሊወርድ የሚችል ትርጉም የለም። ለመጠቀም ፈቃድ ያለዎት ትርጉም ካለ በሊንክ ያክሉት።',
  ),
};
