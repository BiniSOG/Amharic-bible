"""Builds the compact JSON assets bundled with the Flutter app.

Usage:  python3 -I tool/build_assets.py <download_dir> <repo_dir>

<download_dir> must contain clones of these open datasets:
  sm/                           github.com/scrollmapper/bible_databases (formats/json/KJV.json)
  ethiopic-bible-data/          github.com/biniama/ethiopic-bible-data   (Amharic 1954 + Ge'ez)
  amharic-bible-json/           github.com/magna25/amharic-bible-json    (fallback Amharic, MIT)
  bible-cross-references/       github.com/CrossReferences-org/bible-cross-references (CC BY 4.0)
  eastons-bible-dictionary-json/ github.com/garydavenport73/eastons-bible-dictionary-json (MIT)
  pc/                           github.com/thefrenchpressed/pillar-commentary-data (Scofield notes)

Outputs (assets/):
  bibles/am1954.json, bibles/geez.json, bibles/kjv.json  – {id, abbr, name, lang, books:[[[verse]]]}
  data/crossrefs.json   – {"b.c.v": "b.c.v;b.c.v-v;..."}
  data/eastons.json     – [[term, definition], ...]
  data/scofield.json    – {"USFM.chapter": [[verse, note], ...]}
"""
import json, glob, re, sys, os, collections
D, R = sys.argv[1], sys.argv[2]
OUT = os.path.join(R, 'assets')
os.makedirs(OUT + '/bibles', exist_ok=True)
os.makedirs(OUT + '/data', exist_ok=True)

kjv = json.load(open(D + '/sm/formats/json/KJV.json'))
kjv_counts = [[len(c['verses']) for c in b['chapters']] for b in kjv['books']]

def clean(t):
    t = t or ''
    t = re.sub(r'<[^>]*>', '', t)
    t = re.sub(r'class="?searchHighlight"?', '', t)
    t = re.sub(r'\s+[a-z]\s*$', '', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

def dump(path, obj):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, separators=(',', ':'))
    print(path, os.path.getsize(path) // 1024, 'KB')

# ---------- Amharic 1954 + Ge'ez ----------
EN = ['Genesis','Exodus','Leviticus','Numbers','Deuteronomy','Joshua','Judges','Ruth','1 Samuel','2 Samuel','1 Kings','2 Kings','1 Chronicles','2 Chronicles','Ezra','Nehemiah','Esther','Job','Psalms','Proverbs','Ecclesiastes','Song of Solomon','Isaiah','Jeremiah','Lamentations','Ezekiel','Daniel','Hosea','Joel','Amos','Obadiah','Jonah','Micah','Nahum','Habakkuk','Zephaniah','Haggai','Zechariah','Malachi','Matthew','Mark','Luke','John','Acts','Romans','1 Corinthians','2 Corinthians','Galatians','Ephesians','Philippians','Colossians','1 Thessalonians','2 Thessalonians','1 Timothy','2 Timothy','Titus','Philemon','Hebrews','James','1 Peter','2 Peter','1 John','2 John','3 John','Jude','Revelation']
_byname = {json.load(open(f))['book_name_en']: f for f in glob.glob(D + '/ethiopic-bible-data/data/*/*.json')}
fs = [_byname[n] for n in EN]
magna = json.load(open(D + '/amharic-bible-json/amharic_bible.json'))
am_books, gez_books, src_stats = [], [], collections.Counter()
for bi, f in enumerate(fs):
    d = json.load(open(f))
    bch = {c['chapter']: c for c in d['chapters']}
    nch = len(kjv_counts[bi])
    am_ch, gez_ch = [], []
    for ci in range(1, nch + 1):
        c = bch.get(ci)
        verses = {}
        gez = {}
        if c:
            seen_merge = set()
            for v in c['verses']:
                n = v['verse']
                txt = clean(v['text'].get('am'))
                mw = (v.get('mergedWith') or {}).get('am')
                if mw:
                    key = tuple(mw)
                    if key in seen_merge:
                        txt = ''
                    seen_merge.add(key)
                verses[n] = txt
                g = clean(v['text'].get('gez'))
                if g: gez[n] = g
        maxv = max(verses) if verses else 0
        b_list = [verses.get(i, '') for i in range(1, maxv + 1)]
        # fallback to magna25 when this chapter looks incomplete
        m_list = []
        if ci - 1 < len(magna['books'][bi]['chapters']):
            m_list = [clean(x) for x in magna['books'][bi]['chapters'][ci - 1]['verses']]
            # magna stores merged text on the LAST verse: move it to the first of the run
            fixed = list(m_list)
            i = 0
            while i < len(fixed):
                if fixed[i] == '':
                    j = i
                    while j < len(fixed) and fixed[j] == '': j += 1
                    if j < len(fixed):
                        fixed[i], fixed[j] = fixed[j], ''
                    i = j + 1
                else:
                    i += 1
            m_list = fixed
        bn = sum(1 for x in b_list if x)
        mn = sum(1 for x in m_list if x)
        if bn < 0.8 * mn:
            src_stats['magna'] += 1
            am_ch.append(m_list)
        else:
            src_stats['biniama'] += 1
            am_ch.append(b_list)
        gmax = max(gez) if gez else 0
        gez_ch.append([gez.get(i, '') for i in range(1, gmax + 1)])
    am_books.append(am_ch)
    gez_books.append(gez_ch)
print('chapter sources', src_stats)
dump(OUT + '/bibles/am1954.json', {
    'id': 'AM1954', 'abbr': 'አማ 1954', 'lang': 'am',
    'name': 'መጽሐፍ ቅዱስ (1954 ዓ.ም. ትርጉም)',
    'books': am_books})
dump(OUT + '/bibles/geez.json', {
    'id': 'GEEZ', 'abbr': 'ግዕዝ', 'lang': 'gez',
    'name': 'ግዕዝ (ከፊል) — Ge\'ez (partial)',
    'books': gez_books})

# ---------- KJV ----------
dump(OUT + '/bibles/kjv.json', {
    'id': 'KJV', 'abbr': 'KJV', 'lang': 'en', 'name': 'King James Version (1769)',
    'books': [[[clean(v['text']) for v in c['verses']] for c in b['chapters']] for b in kjv['books']]})

# ---------- Cross references (TSK, CC BY 4.0) ----------
X = D + '/bible-cross-references/json/'
verses = json.load(open(X + 'bible_verses.json'))
vid = {v['id']: (v['book_id'], v['kjv_ch'], v['kjv_vs']) for v in verses if v.get('kjv_ch')}
xr = json.load(open(X + 'cross_references.json'))
out = collections.defaultdict(list)
for row in xr:
    src = vid.get(row['verse_id'])
    if not src: continue
    key = '%d.%d.%d' % src
    for grp in row['refs']:
        a = vid.get(grp[0]); b = vid.get(grp[-1])
        if not a: continue
        s = '%d.%d.%d' % a
        if b and b != a and b[0] == a[0]:
            s += '-%d' % b[2] if b[1] == a[1] else '-%d.%d' % (b[1], b[2])
        if s not in out[key]:
            out[key].append(s)
compact = {k: ';'.join(v[:24]) for k, v in out.items()}
dump(OUT + '/data/crossrefs.json', compact)

# ---------- Easton's Bible Dictionary ----------
e = json.load(open(D + '/eastons-bible-dictionary-json/eastons.json'))
entries = []
for term, defs in e.items():
    txt = '\n\n'.join(clean(x['definition']) if isinstance(x, dict) else clean(str(x)) for x in defs)
    entries.append([term, txt])
entries.sort(key=lambda x: x[0].lower())
dump(OUT + '/data/eastons.json', entries)

# ---------- Scofield Reference Notes (public domain) ----------
def _flat(x):
    if isinstance(x, str): return x
    if isinstance(x, list): return '\n\n'.join(_flat(y) for y in x)
    if isinstance(x, dict): return _flat(x.get('text') or x.get('content') or '')
    return ''

sco = {}
for f in glob.glob(D + '/pc/c/scofield/*/*.json'):
    usfm, ch = f.split('/')[-2], f.split('/')[-1][:-5]
    if not ch.isdigit(): continue
    items = [[it['number'], _flat(it.get('content')).strip()]
             for it in json.load(open(f)).get('chapter', {}).get('content', [])
             if it.get('type') == 'verse']
    items = [i for i in items if i[1]]
    if items: sco[usfm + '.' + ch] = items
if sco:
    dump(OUT + '/data/scofield.json', sco)
