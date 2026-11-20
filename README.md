# መጽሐፍ ቅዱስ · Amharic Bible

A modern, bilingual (Amharic / English) Bible app for **Android and iOS**, built with Flutter.

## Features

### 📖 Bible reader
- **Amharic 1954 (Haile Selassie) Bible** bundled — works fully offline, including merged-verse ranges (e.g. `2-3`)
- **KJV** and **Ge'ez (partial)** bundled; **23 more English versions** one tap away (BSB, ASV, NHEB/WEB, LEB, BBE, YLT, Darby, Webster, Geneva 1599, Douay-Rheims, CPDV, Tyndale, Wycliffe, AKJV, UKJV…)
- Online catalogue of extra free Amharic/English/Ge'ez versions (bible.helloao.org) + **add any version from a link** (for versions you hold a license for)
- **Parallel view** – any two versions verse-by-verse (e.g. Amharic + English)
- Swipe between chapters, quick book → chapter → verse picker (grid or list, OT/NT tabs, type `ዮሐ 3:16` or `John 3:16`)
- Light / Sepia / Dark / System themes, text size, line spacing, paragraph mode, **Ethiopic numerals (፩ ፪ ፫)**
- Beautiful Noto Serif Ethiopic typography

### ✋ Tap & long-press verse actions
Tap verses to multi-select, **long-press** for the full action sheet:
- **Copy** & **Share** (with reference and version)
- **Highlight** in 6 colours (or remove)
- **Bookmark** and **Notes** (personal study notes per verse)
- **Commentary** – focused on the selected verse, with full-chapter view
- **Cross references** – 290,000+ Treasury of Scripture Knowledge links, tap to open
- **Compare** the verse across every installed version
- **Verse image** – make a shareable picture with 8 backgrounds
- **Listen** (device text-to-speech) and **Dictionary** lookup of each word

### 📚 Commentaries
| Source | Coverage | Availability |
| --- | --- | --- |
| Scofield Reference Notes (1917) | Whole Bible | **Offline (bundled)** |
| Matthew Henry's Complete Commentary | Whole Bible | Online, cached after first view |
| John Calvin's Commentaries | 47 books | Online, cached |
| Gaebelein's Annotated Bible, F. B. Meyer | Whole Bible | Online, cached |
| JFB, Adam Clarke, John Gill, Keil & Delitzsch, Tyndale notes | via HelloAO API | Online, cached |

### 🗓️ Reading plans
Bible in a Year (balanced OT + Psalms/Proverbs + NT), Genesis→Revelation, New Testament in 90 days, Four Gospels in 30 days, Psalms & Proverbs, Proverbs in a month, *First Steps with Jesus* (new believers), *Peace in Anxious Times*, *The Love of God*, *Learning to Pray*, *The Road to the Cross* (Hudade / Fasika).
Progress tracking, "days behind" indicator, mark-complete at the end of each reading, daily **streak** 🔥.

### 🧒 Bible stories for children
26 illustrated, bilingual stories (Creation → Philip and the Ethiopian official) each with:
page-by-page storytelling, read-aloud, **"What we learn"**, a **memory verse** from the Bible, a **quiz**, a **prayer**, and stars ⭐ for finished stories.

### 📕 Bible dictionary
- **Amharic glossary** of 54 key biblical terms (ጸጋ, ንስሐ, ኪዳን, መሲሕ…) with Amharic + English definitions and key verses
- **Easton's Bible Dictionary** (~4,000 entries) with tappable Scripture references
- Search folds Amharic homophone letters (ሀ/ሐ/ኀ, ሰ/ሠ, አ/ዐ, ጸ/ፀ) so spelling differences don't matter — same for Bible search

### More
Verse of the Day, continue reading, history, "My notes & highlights" (filter by colour, export/share), full-text search with scope filters, Amharic or English interface.

## Build & run

```bash
flutter pub get
flutter run            # Android device / emulator or iOS simulator
flutter build apk      # Android
flutter build ipa      # iOS (on macOS with Xcode)
flutter test
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
