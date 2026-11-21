# መጽሐፍ ቅዱስ · Amharic Bible

A modern, bilingual (Amharic / English) Bible app for **Android and iOS**, built with Flutter.

## Features

### Bible reader
- **Amharic 1954 (Haile Selassie) Bible** bundled — works fully offline, including merged-verse ranges (e.g. `2-3`)
- **KJV** and **Ge'ez (partial)** bundled; **23 more English versions** one tap away (BSB, ASV, NHEB/WEB, LEB, BBE, YLT, Darby, Webster, Geneva 1599, Douay-Rheims, CPDV, Tyndale, Wycliffe, AKJV, UKJV…)
- Online catalogue of extra free Amharic/English/Ge'ez versions (bible.helloao.org) + **add any version from a link** (for versions you hold a license for)
- **KJV with Strong's numbers** bundled: tap any `G`/`H` number for the Hebrew/Greek word, transliteration, pronunciation, derivation (linked), definition, KJV usage, occurrence count and every verse that uses it. Strong's is also available for any verse via the action menu, and searchable (type `G2532`)
- **Chinese Union Version** and **French** (Darby, Crampon, Synodale NT) downloads; the online catalogue adds free Oromo, Tigrinya, Somali, Afar, Arabic, French, Italian and Chinese Bibles when available
- **Parallel view** – any two versions verse-by-verse (e.g. Amharic + English), shown **line by line** or **side by side** in two columns
- Swipe between chapters, quick book → chapter → verse picker (grid or list, OT/NT tabs, type `ዮሐ 3:16` or `John 3:16`)
- Light / Sepia / Dark / System themes, text size, line spacing, paragraph mode, **Ethiopic numerals (፩ ፪ ፫)**
- Beautiful Noto Serif Ethiopic typography

### Tap & long-press verse actions
Tap verses to multi-select, **long-press** for the full action sheet:
- **Copy** & **Share** (with reference and version)
- **Highlight** in 6 colours (or remove)
- **Bookmark** and **Notes** (personal study notes per verse)
- **Commentary** – focused on the selected verse, with full-chapter view
- **Cross references** – 290,000+ Treasury of Scripture Knowledge links. A red `*` after a verse opens them right under the verse, with each passage's text
- **Compare** the verse across every installed version
- **Verse image** – make a shareable picture with 8 backgrounds
- **Listen** (device text-to-speech) and **Dictionary** lookup of each word

### Commentaries
| Source | Coverage | Availability |
| --- | --- | --- |
| Scofield Reference Notes (1917) | Whole Bible | **Offline (bundled)** |
| Matthew Henry's Complete Commentary | Whole Bible | Online, cached after first view |
| John Calvin's Commentaries | 47 books | Online, cached |
| Gaebelein's Annotated Bible, F. B. Meyer | Whole Bible | Online, cached |
| JFB, Adam Clarke, John Gill, Keil & Delitzsch, Tyndale notes | via HelloAO API | Online, cached |

### Reading plans
Bible in a Year (balanced OT + Psalms/Proverbs + NT), Genesis→Revelation, New Testament in 90 days, Four Gospels in 30 days, Psalms & Proverbs, Proverbs in a month, *First Steps with Jesus* (new believers), *Peace in Anxious Times*, *The Love of God*, *Learning to Pray*, *The Road to the Cross* (Hudade / Fasika).
Progress tracking, "days behind" indicator, mark-complete at the end of each reading, daily **streak** 🔥.

### Bible stories for children
26 illustrated, bilingual stories (Creation → Philip and the Ethiopian official) each with:
page-by-page storytelling, read-aloud, **"What we learn"**, a **memory verse** from the Bible, a **quiz**, a **prayer**, and stars ⭐ for finished stories.

### Bible quiz (adults)
120 bilingual questions in **Easy / Medium / Hard** (plus Mixed), 10-question rounds or all questions, optional 20-second timer, instant feedback with the Bible verse that answers it, score review, best scores and overall accuracy.

### Bible dictionary
- **Amharic glossary** of 54 key biblical terms (ጸጋ, ንስሐ, ኪዳን, መሲሕ…) with Amharic + English definitions and key verses
- **Easton's Bible Dictionary** (~4,000 entries) with tappable Scripture references
- Search folds Amharic homophone letters (ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ) so spelling differences don't matter — same for Bible search

### Languages
Interface in **Amharic, English, Afaan Oromoo, Tigrinya, Somali, Arabic (right-to-left), French, Italian and Chinese** — change it from the language button on the home screen or *More → App language*. **Gurage and Afar** are selectable but not translated yet (they fall back to Amharic / English); add strings in `lib/core/i18n/sgw.dart` and `aa.dart`.

### More
Verse of the Day, continue reading, history, "My notes & highlights" (filter by colour, export/share), full-text search with scope filters, Amharic or English interface.

## Releasing updates & force update

The app reads [`version.json`](version.json) from the repository's default branch on every launch:

| Field | Meaning |
| --- | --- |
| `latest_build` | Newest build number. Older apps see a dismissible *Update available* dialog (once per release). |
| `min_build` | Oldest build still allowed. Older apps show a blocking *Update required* screen. |
| `android_url` / `ios_url` | Where the Update button goes (GitHub Releases now; Play Store / App Store later). |
| `notes_en` / `notes_am` | Release notes shown in the dialog. |

To ship a release: bump `version:` in `pubspec.yaml` (e.g. `1.2.0+3`), push a tag `v1.2.0` — the workflow builds the APKs and publishes them as a GitHub Release — then update `version.json` (`latest_build: 3`, and raise `min_build` only when old versions must stop working).

## iOS

Every push also builds an **unsigned iOS app** on a macOS runner (artifact `amharic-bible-ios-unsigned-ipa`). Apple only lets signed apps run on an iPhone, so:

* **Quick testing on your own iPhone:** sign and install the unsigned `.ipa` with a sideloading tool such as AltStore or Sideloadly using your Apple ID (free accounts must re-sign every 7 days).
* **TestFlight / App Store:** join the Apple Developer Program, create the app with bundle ID `com.binisog.amharicBible`, then either archive in Xcode on a Mac (`flutter build ipa`) or add your signing certificate and provisioning profile to GitHub secrets so CI can produce a signed `.ipa`.

## Google Play (.aab)

Every push also builds `app-release.aab` (artifact `amharic-bible-aab`). Before uploading to Google Play, configure a release signing key (`android/key.properties` + keystore, or Play App Signing with an upload key); the current build uses the debug key.

## Download the APK

Every push builds an Android APK with GitHub Actions (`.github/workflows/build-apk.yml`).
Open the repository's **Actions** tab → latest *Build Android APK* run → **Artifacts** → `amharic-bible-apk`.

## Build & run

```bash
flutter pub get
flutter run            # Android device / emulator or iOS simulator
flutter build apk      # Android
flutter build ipa      # iOS (on macOS with Xcode)
flutter test
dart run flutter_launcher_icons   # regenerate app icons from assets/icon/
```

Requires Flutter 3.50+ (uses the `material_ui` package).

## Project structure

```
lib/
  core/      books (66 books, Amharic & English names), references, theme, l10n
  data/      Bible parsing/repository, commentary, cross-refs, dictionary, plans, stories, TTS
  state/     settings & user data (highlights, bookmarks, notes, plans, streak)
  ui/        today, reader (+ picker, verse actions, study sheet, verse image),
             plans, kids, search, dictionary, versions library, my library, more
assets/
  bibles/    am1954.json, kjv.json, geez.json
  data/      crossrefs, eastons, scofield, glossary, stories
  fonts/     Noto Serif/Sans Ethiopic, Noto Serif (OFL)
tool/build_assets.py   regenerates the bundled data from the open datasets
```

## Licensing of texts

Only public-domain or openly licensed texts are included or offered for download (see *More → About & licenses* in the app).
Copyrighted translations — e.g. NIV, ESV, NKJV, NLT, or the Amharic *Addis Mestagerem* (2001) / Amharic Standard Version — **cannot be shipped without permission** from their publishers (Bible Society of Ethiopia, Biblica, Crossway, …). Once you have a license, publish the text as JSON and add it in the app via **Bible versions → Add from link**; the parser accepts several common Bible JSON layouts.
