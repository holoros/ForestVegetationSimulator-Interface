import sys, docx
sys.path.insert(0, '.')
from docedit import set_par, find_par, iter_all_pars, replace_in
d = docx.Document('/mnt/user-data/uploads/Koa/submission/koa_cover_letter_v124.docx')
P = lambda a, sw=False: find_par(list(iter_all_pars(d)), a, startswith=sw)
set_par(P('November 3, 2026', True), 'November 7, 2026')
set_par(P('Three contributions should interest the readership', True),
 "Three contributions should interest the readership of the journal. The first is ecological. At equal tree size and competition, "
 "koa diameter growth is about 36% faster on high than on low productivity sites, whereas height responds little. The second is a "
 "site productivity index, the Biomass Yield Index, that needs no stand age and so can serve the many tropical and restoration forests "
 "where ages are unknown. The third is a mortality structure showing that crowding raises the chance that a young plantation loses "
 "trees but not detectably how many it loses, whereas per-tree mortality in natural stands rises steeply with crowding. With its key "
 "components refitted without each installation in turn, the system reproduced average survival, tree size, and basal area on 17 "
 "long-term plots, and its projections describe the average stand at each productivity level. The supplement sets out the "
 "evidence and recommended domain of use for each component within the 52-year span of the data.")
replace_in(P('with a 293-word abstract'), 'with a 293-word abstract', 'with a 293-word abstract', keep_format=True)
d.save('koa_cover_letter_v125.docx'); print('saved')
