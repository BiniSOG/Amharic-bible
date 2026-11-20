"""Builds assets/bibles/kjv_strongs.json (KJV text with [G1234]/[H1234] tags)
and assets/data/strongs_{greek,hebrew}.json from kaiserlik/kjv + openscriptures/strongs."""
import json, os, re, subprocess, sys
KK, OUT = sys.argv[1], sys.argv[2]
books = [list(b.values())[0] for b in json.load(open(KK + '/books.json'))['books']]
assert len(books) == 66, len(books)
kjv = json.load(open(OUT + '/bibles/kjv.json'))
out = []
for bi, code in enumerate(books):
    f = KK + f'/{code}.json'
    subprocess.run(['git', '-C', KK, 'checkout', '-q', 'HEAD', '--', f'{code}.json'], check=True)
    txt = open(f, encoding='utf-8').read()
    d = {}
    for m in re.finditer(r'"([^"|]+)\|(\d+)\|(\d+)"\s*:\s*\{\s*"en"\s*:\s*"((?:[^"\\]|\\.)*)"', txt):
        d.setdefault(f'{code}|{m.group(2)}', {})[f'{code}|{m.group(2)}|{m.group(3)}'] = {'en': json.loads('"' + m.group(4) + '"')}
    nch = len(kjv['books'][bi])
    chs = []
    for c in range(1, nch + 1):
        ch = d.get(f'{code}|{c}', {})
        nv = len(kjv['books'][bi][c - 1])
        vs = []
        for v in range(1, nv + 1):
            t = ch.get(f'{code}|{c}|{v}', {}).get('en', '')
            t = re.sub(r'</?em>', '', t)
            t = re.sub(r'\s+', ' ', t).strip()
            vs.append(t)
        chs.append(vs)
    out.append(chs)
    os.remove(f); print(code, end=' ', flush=True)
p = OUT + '/bibles/kjv_strongs.json'
json.dump({'id': 'KJVS', 'abbr': 'KJV+', 'lang': 'en', 'name': "KJV with Strong's numbers", 'books': out},
          open(p, 'w'), ensure_ascii=False, separators=(',', ':'))
print(p, os.path.getsize(p) // 1024, 'KB')

# Afterwards, fill verse endings the source dropped (words without tags) from
# the plain KJV, and convert Strong's dictionaries:
#   python3 -I tool/build_strongs_fix.py
