"""koa v132 / s123 / title page v132 / cover letter v132, 2026-11-07.
Changes: (1) the deposit version cited moves from Zenodo 1.12.1 (10.5281/zenodo.24013562) to 1.12.2 (reserved DOI passed as argv[1]),
so the deposited supplement equals the submitted one. BLIND copies carry no deposit DOI. (2) F7: Section S3.2 reports the calibrated diameter ratio for the 88 intervals longer than 20 years."""
import sys, re, shutil, docx
from docedit import iter_all_pars
NEW = sys.argv[1]; assert re.fullmatch(r'\d{8}', NEW)
S = '../v131/'; T = '/mnt/attach/outputs/2026-11/koa_v131/upload/'
jobs = [(S+'koa_manuscript_v131_FINAL.docx', 'koa_manuscript_v132_FINAL.docx', 2),
        (S+'koa_supplemental_v122_FINAL.docx', 'koa_supplemental_v123_FINAL.docx', 1),
        (S+'koa_cover_letter_v131.docx', 'koa_cover_letter_v132.docx', 1),
        (T+'02_title_page_koa_v127.docx', 'koa_title_page_v132.docx', 1)]
for s, t, want in jobs:
    d = docx.Document(s); n = 0
    for p in iter_all_pars(d):
        if '24013562' not in p.text: continue
        for r in p.runs:
            if '24013562' in r.text: r.text = r.text.replace('24013562', NEW); n += 1
        for r in p.runs:
            if '1.12.1' in r.text: r.text = r.text.replace('1.12.1', '1.12.2')
        assert '1.12.1' not in p.text and NEW in p.text, (t, p.text[:120])
    assert n == want, (t, n)
    d.save(t); print(t, n)
shutil.copy(S+'koa_manuscript_v131_FINAL_BLIND.docx', 'koa_manuscript_v132_FINAL_BLIND.docx')
shutil.copy(S+'koa_supplemental_v122_FINAL_BLIND.docx', 'koa_supplemental_v123_FINAL_BLIND.docx')
# F7: the 88 calibration intervals longer than 20 years (4,971 - 4,883), from out/inc/evaluation_strata_v103.csv on firebreather
# (fit dDBH_L_NO, frame NO, stratum interval 21+: n 88, ratio 1.29102623365532; the four reported classes match that file to two decimals).
from docedit import replace_in
for t in ['koa_supplemental_v123_FINAL.docx', 'koa_supplemental_v123_FINAL_BLIND.docx']:
    d = docx.Document(t); h = [p for p in iter_all_pars(d) if 'and 0.24 on 32 of 11 to 20 years.' in p.text]; assert len(h) == 1, t
    replace_in(h[0], 'and 0.24 on 32 of 11 to 20 years.', '0.24 on 32 of 11 to 20 years, and 1.29 on 88 longer than 20 years.', keep_format=True)
    d.save(t); print('F7', t)
print('BLIND copies carried (no DOI inside)')
