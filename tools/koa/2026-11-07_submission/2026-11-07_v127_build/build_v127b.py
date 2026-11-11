"""koa v127 abstract: Aaron's v126 BLIND abstract edits (2026-11-07 07:01) carried as the floor, except 'significantly' (no test supports it: Table 3 b9 = 0.083, SE 0.261; Kulani ratio 1.07, 0.76 to 1.39), plus two trims to meet the 300 word limit."""
import sys, docx
sys.path.insert(0, '.')
from docedit import iter_all_pars, replace_in
A = 'Acacia koa A. Gray (koa), a nitrogen'
E = [
 ('an age-free measure of the biomass a site can support.', 'an age-free measure of the biomass a site can support for a given top height and relative density.'),
 ('restoration and timber programs', 'restoration and forest management programs'),
 ('The age-free approach may', 'The age-free site productivity approach may'),
 ('records of what kills trees,', 'refined records of tree mortality,'),
 ('which rules out the site index that conventional growth models rely on.', 'which rules out conventional site index.'),
 ('Equations for height, crown, growth, and survival are joined in a simulator that reports its uncertainty.', 'Its height, crown, growth, and survival equations feed a simulator that reports uncertainty.'),
]
for f in ['koa_manuscript_v127_FINAL.docx', 'koa_manuscript_v127_FINAL_BLIND.docx']:
    d = docx.Document(f); h = [p for p in iter_all_pars(d) if p.text.startswith(A)]
    assert len(h) == 1
    for o, n in E:
        assert o in h[0].text, o
        replace_in(h[0], o, n, keep_format=True)
    d.save(f); print(f, len(h[0].text.split()))
