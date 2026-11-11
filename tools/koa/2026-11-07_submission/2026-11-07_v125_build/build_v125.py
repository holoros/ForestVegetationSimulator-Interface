"""koa v125 build, 2026-11-07: replace the abstract (Aaron: hard to read, irrelevant detail; must state the work,
its importance, and future work with broader implications for an international audience). Floor: Aaron's edited
koa_manuscript_v124_FINAL.docx (md5 a6327d2f). BLIND gets the same abstract. No other text changes."""
import sys, docx
sys.path.insert(0, '.')
from docedit import set_par, find_par, iter_all_pars
ABS = open('../abs/abstract_v125.txt', encoding='utf-8').read().strip()
ABS_MK = ABS.replace('Acacia koa A. Gray', '*Acacia koa* A. Gray').replace('m³ ha⁻¹', '{m3ha}').replace('Mg C ha⁻¹', '{MgCha}')
U = '/mnt/user-data/uploads/Koa/submission/'
for src, dst in [(U + 'koa_manuscript_v124_FINAL.docx', 'koa_manuscript_v125_FINAL.docx'),
                 ('blind_v124.docx', 'koa_manuscript_v125_FINAL_BLIND.docx')]:
    d = docx.Document(src)
    pars = list(iter_all_pars(d))
    p = find_par(pars, 'Acacia koa A. Gray (koa), a nitrogen-fixing tree and Hawaii', startswith=True)
    set_par(p, ABS_MK)
    d.save(dst); print('saved', dst)

# GY was defined only in the old abstract; define it at first use in the Introduction (both files).
from docedit import replace_in
for f in ['koa_manuscript_v125_FINAL.docx', 'koa_manuscript_v125_FINAL_BLIND.docx']:
    d = docx.Document(f)
    p = find_par(list(iter_all_pars(d)), 'requires reliable GY projections over decadal time scales')
    replace_in(p, 'requires reliable GY projections', 'requires reliable growth and yield (GY) projections', keep_format=True)
    d.save(f); print('GY defined in', f)
