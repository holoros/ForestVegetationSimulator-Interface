"""s118 coverage rounding: 13/17 = 0.7647 -> 0.76 (Table S26 and S6.3 prose); S6.3 QMD Clopper-Pearson upper 0.9854 -> 0.99 to match Table S26."""
import sys, docx; sys.path.insert(0,'.')
from docedit import iter_all_pars, replace_in
E=[('0.77 (0.50 to 0.93)','0.77 (0.50 to 0.93)','0.76 (0.50 to 0.93)'),
   ('0.77 for cohort survival (0.50 to 0.93)','0.77 for cohort survival','0.76 for cohort survival'),
   ('exact 95% interval 0.64 to 0.98','exact 95% interval 0.64 to 0.98','exact 95% interval 0.64 to 0.99')]
for f in ['koa_supplemental_v118_FINAL.docx','koa_supplemental_v118_FINAL_BLIND.docx']:
    d=docx.Document(f); P=list(iter_all_pars(d))
    for a,o,n in E:
        h=[p for p in P if a in p.text]; assert len(h)==1,(f,a,len(h)); replace_in(h[0],o,n,keep_format=True)
    d.save(f); print('ok',f)
