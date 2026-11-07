import sys, docx
sys.path.insert(0, '.')
from docedit import find_par, iter_all_pars, replace_in
d = docx.Document('/mnt/user-data/outputs/2026-11/koa_v125/koa_cover_letter_v125.docx')
P = lambda a: find_par(list(iter_all_pars(d)), a)
replace_in(P('With its key components refitted'), 'With its key components refitted', 'With the diameter growth equation and natural mortality level refitted', keep_format=True)
replace_in(P('with a 293-word abstract'), 'with a 293-word abstract', 'with a 297-word abstract', keep_format=True)
d.save('koa_cover_letter_v126.docx'); print('saved')
