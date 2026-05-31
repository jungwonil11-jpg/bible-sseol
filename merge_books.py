#!/usr/bin/env python3
# books_src/*.js (권별 책 객체 literal) 들을 books.js에 삽입.
# 파일번호로 구약/신약/제2경전 구분:
#   NN < 40  → BIBLE.old (구약)
#   40~66    → BIBLE.new (신약)
#   67+      → BIBLE.deut (제2경전 — 천주교/정교회)
# 멱등(idempotent): 각 배열의 마커 사이를 매번 통째로 재생성.
import re, glob, os

BASE = os.path.dirname(os.path.abspath(__file__))

with open(f'{BASE}/books.js', encoding='utf-8') as f:
    src = f.read()

# books_src/ 안의 파일을 파일명 순으로 (01_xx.js ...) — _로 시작하는 메타파일 제외
files = sorted(p for p in glob.glob(f'{BASE}/books_src/*.js')
               if not os.path.basename(p).startswith('_'))

def booknum(p):
    return int(os.path.basename(p).split('_')[0])

def read_blocks(paths):
    out = []
    for fp in paths:
        with open(fp, encoding='utf-8') as f:
            out.append(f.read().strip().rstrip(','))
    return out

def splice(text, start, end, blocks, lead_comma):
    if blocks:
        gen = (',\n' if lead_comma else '\n') + ',\n'.join(blocks) + '\n'
    else:
        gen = ''
    region = start + gen + end
    return re.sub(re.escape(start) + r'.*?' + re.escape(end), lambda m: region, text, flags=re.S)

old_files  = [p for p in files if booknum(p) < 40]
new_files  = [p for p in files if 40 <= booknum(p) < 67]
deut_files = [p for p in files if booknum(p) >= 67]

src = splice(src, '/* __GEN_START__ */',      '/* __GEN_END__ */',      read_blocks(old_files),  lead_comma=False)
src = splice(src, '/* __GEN_NEW_START__ */',  '/* __GEN_NEW_END__ */',  read_blocks(new_files),  lead_comma=False)
src = splice(src, '/* __GEN_DEUT_START__ */', '/* __GEN_DEUT_END__ */', read_blocks(deut_files), lead_comma=False)

with open(f'{BASE}/books.js', 'w', encoding='utf-8') as f:
    f.write(src)

print(f"merged: old={len(old_files)}권, new={len(new_files)}권, deut={len(deut_files)}권")
for fp in old_files + new_files + deut_files:
    print("  -", os.path.basename(fp))
