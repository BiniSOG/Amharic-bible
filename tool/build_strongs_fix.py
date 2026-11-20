"""Post-processing for assets/bibles/kjv_strongs.json and Strong's dictionaries.

1. Some verses in the source lose their final untagged words; append them
   from assets/bibles/kjv.json by aligning the last tagged words.
2. Convert openscriptures/strongs JS dictionaries (CC BY-SA) to compact JSON:
   {"G2532": [lemma, translit, pron, derivation, strongs_def, kjv_def]}.

Usage: python3 -I tool/build_strongs_fix.py <dir with strongs-*-dictionary.js>
"""
import json, re, sys

def fix_tails():
    p = 'assets/bibles/kjv_strongs.json'
    s = json.load(open(p)); k = json.load(open('assets/bibles/kjv.json'))
    strip = lambda t: re.sub(r'\[[GH]\d+\]', '', t)
    nt = lambda w: re.sub(r'[^a-z]', '', w.lower())
    for b in range(66):
        for c, ch in enumerate(s['books'][b]):
            for v, t in enumerate(ch):
                a = [x for x in (nt(w) for w in strip(t).split()) if x]
                kt = k['books'][b][c][v].split(); kn = [nt(w) for w in kt]
                if len(a) >= len([x for x in kn if x]) or not a: continue
                last, pos = a[-3:], None
                for i in range(len(kn)):
                    if not kn[i]: continue
                    if [x for x in kn[:i + 1] if x][-len(last):] == last:
                        pos = i + 1
                        if abs(len([x for x in kn[:i + 1] if x]) - len(a)) <= 3: break
                if pos is not None and pos < len(kt):
                    ch[v] = t.rstrip() + ' ' + ' '.join(kt[pos:])
    json.dump(s, open(p, 'w'), ensure_ascii=False, separators=(',', ':'))

def dictionaries(src):
    for lang in ('greek', 'hebrew'):
        t = open(f'{src}/strongs-{lang}-dictionary.js', encoding='utf-8').read()
        d = json.loads(t[t.index('{', t.index('=')):t.rindex('}') + 1])
        out = {k: [v.get('lemma', ''), v.get('xlit') or v.get('translit', ''), v.get('pron', ''),
                   v.get('derivation', ''), v.get('strongs_def', ''), v.get('kjv_def', '')]
               for k, v in d.items()}
        json.dump(out, open(f'assets/data/strongs_{lang}.json', 'w'),
                  ensure_ascii=False, separators=(',', ':'))

if __name__ == '__main__':
    fix_tails()
    if len(sys.argv) > 1: dictionaries(sys.argv[1])
