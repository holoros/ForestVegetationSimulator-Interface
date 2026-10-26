# -*- coding: utf-8 -*-
"""Build koa_manuscript_v106_DRAFT.docx from v105 by anchored edits. Every anchor must match one paragraph."""
import sys, copy, re, datetime, json
sys.path.insert(0, '/tmp/k6/work')
import docx
from docx.oxml.ns import qn
from lxml import etree
import docedit as E
from ms_text_v106 import SET, SUB, POST

SRC = '/tmp/k6/src/koa_manuscript_v105_DRAFT.docx'
OUT = sys.argv[1] if len(sys.argv) > 1 else '/tmp/k6/out/koa_manuscript_v106_DRAFT.docx'
FIG4 = '/mnt/user-data/uploads/Documents/MAINE/DOCS/MINE/Manuscripts/2026/Koa/figures_v106/Fig4_projections.png'
FIG5 = '/mnt/user-data/uploads/Documents/MAINE/DOCS/MINE/Manuscripts/2026/Koa/figures_v106/Fig5_longterm.png'

d = docx.Document(SRC)
P = d.paragraphs
log = []

def plain(s):
    return E.expand(s).replace('^', '').replace('~', '').replace('**', '')

# 1. whole-paragraph rewrites
for anchor, markup in SET.items():
    p = E.find_par(P, anchor, startswith=True)
    E.set_par(p, markup)
    log.append(('SET', anchor[:50]))

# 2. substitutions
for anchor, old, new in SUB:
    p = E.find_par(P, plain(anchor) if '{' in anchor else anchor, startswith=True)
    E.replace_in(p, plain(old), new)
    log.append(('SUB', anchor[:40], plain(old)[:40]))

for anchor, old, new in POST:
    p = E.find_par(P, anchor, startswith=True)
    E.replace_in(p, plain(old), new)
    log.append(('POST', anchor[:40], plain(old)[:40]))

# 3. Word comments for items Aaron must verify
# version DOI 10.5281/zenodo.22997704 reserved by draft 22997704 (zenodo_dois.json, October 1, 2026)

# 4. reference: Crookston and Dixon 2005, after Chojnacky
ref = E.find_par(P, 'Chojnacky, D.C., Heath, L.S., Jenkins, J.C., 2014.', startswith=True)
newp = copy.deepcopy(ref._p)
ref._p.addnext(newp)
from docx.text.paragraph import Paragraph
np_ = Paragraph(newp, ref._parent)
E.set_par(np_, 'Crookston, N.L., Dixon, G.E., 2005. The forest vegetation simulator: a review of its structure, content, and applications. Comput. Electron. Agric. 49, 60–80. https://doi.org/10.1016/j.compag.2005.02.003')

# 5. tables
T1, T2, T3, T4, T5 = d.tables[:5]
def setc(t, r, c, s):
    E.set_par(t.rows[r].cells[c].paragraphs[0], s)
# Table 1: Med. int. on the consecutive diameter frame, n/a for single-visit sources; total BYI record-weighted mean
hdr = [c.text for c in T1.rows[0].cells]
assert hdr[-1].startswith('Med. int.') and hdr[-2] == 'Mean BYI', hdr
rows = {T1.rows[i].cells[0].text: i for i in range(1, len(T1.rows))}
medint = {'DOFAW Historical': '5', 'Plantation PSPs': '1', 'FIA Plots': '9', 'Kahikinui': 'n/a', 'KMR CAR': 'n/a',
          'KMR PSP': '1', 'Kualoa': 'n/a', 'Mauka upland': 'n/a', 'Kap': 'n/a', 'Total': '1'}
for k, v in medint.items():
    setc(T1, rows[k], 7, v)
setc(T1, rows['Total'], 6, '318')
# widths: fixed layout, widen Installations and Origin
W = [1550, 1350, 1000, 1200, 1400, 1100, 880, 880]
tblPr = T1._tbl.find(qn('w:tblPr'))
lay = tblPr.find(qn('w:tblLayout')); lay.set(qn('w:type'), 'fixed')
g = T1._tbl.find(qn('w:tblGrid'))
for gc, w in zip(g, W):
    gc.set(qn('w:w'), str(w))
for row in T1.rows:
    for cell, w in zip(row.cells, W):
        tcPr = cell._tc.get_or_add_tcPr()
        tcW = tcPr.find(qn('w:tcW'))
        if tcW is None:
            tcW = etree.SubElement(tcPr, qn('w:tcW'))
        tcW.set(qn('w:w'), str(w)); tcW.set(qn('w:type'), 'dxa')
# Table 2 rows (a3/pending/v106/table2_v106.json)
r2 = {T2.rows[i].cells[0].text: i for i in range(1, len(T2.rows))}
new2 = {
 'BAPH (m2 ha−1)': ['9,053', '19.5', '16.1', '0.0', '16.5', '164.2'],
 'BAL (m2 ha−1)': ['9,053', '10.1', '12.0', '0.0', '6.0', '164.2'],
 'ΔDBH (cm yr−1)': ['4,971', '1.71', '1.61', '0.00', '1.20', '9.90'],
 'ΔHT (m yr−1)': ['4,033', '1.43', '1.25', '0.01', '1.10', '9.20'],
}
for k, vals in new2.items():
    i = r2[k]
    for j, v in enumerate(vals, start=1):
        setc(T2, i, j, v)

# 6. figures 4 and 5
for p in P:
    bl = p._p.xpath('.//a:blip')
    if not bl:
        continue
    rid = bl[0].get(qn('r:embed'))
    nxt = p._p.getnext()
    cap = ''.join(x.text or '' for x in nxt.iter(qn('w:t')))
    if cap.startswith('Fig. 4.'):
        d.part.related_parts[rid]._blob = open(FIG4, 'rb').read(); log.append(('FIG', 'Fig4'))
    if cap.startswith('Fig. 5.'):
        d.part.related_parts[rid]._blob = open(FIG5, 'rb').read(); log.append(('FIG', 'Fig5'))

# 7. superscript sweep outside the reference list
inrefs = False
nfix = 0
for p in P:
    if p.text.strip() == 'References':
        inrefs = True
    if p.text.strip() == 'Figures':
        inrefs = False
    if not inrefs:
        try:
            nfix += E.fix_superscripts(p)
        except ValueError:
            pass
for t in d.tables:
    for row in t.rows:
        for c in row.cells:
            for p in c.paragraphs:
                try:
                    nfix += E.fix_superscripts(p)
                except ValueError as e:
                    log.append(('SKIP', str(e)[:60]))
log.append(('SUPFIX', nfix))

cp = d.core_properties
cp.modified = datetime.datetime(2026, 10, 1, 9, 0, 0)
cp.revision = (cp.revision or 0) + 1
d.save(OUT)
json.dump(log, open(OUT.replace('.docx', '_buildlog.json'), 'w'), indent=0, ensure_ascii=False)
print('ok', len(log), 'edits; superscripts fixed', nfix)
