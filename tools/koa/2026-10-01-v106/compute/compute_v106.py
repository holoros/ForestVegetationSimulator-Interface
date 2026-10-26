# compute_v106.py (koa v106 inputs, 2026-09-30). Tasks 1 to 6 and 9 of the v106 revision request.
# Reuses compute_pending_v103.py logic (st(), live = Status live & DBH > 0, annualized increments over YIP).
# No coordinate column is read anywhere in this script.
import json, numpy as np, pandas as pd, os, re, glob
J = '/home/aaron/jobs/koa_v103_20260930/'
O = J + 'a3/pending/v106/'
FR = J + 'frames/final/'
R = {}

def st(x, dec):
    x = pd.Series(x).dropna(); f = lambda v: f"{v:,.{dec}f}"
    return [f"{len(x):,}", f(x.mean()), f(x.std()), f(x.min()), f(x.median()), f(x.max())]

def q(x):
    x = pd.Series(x).dropna()
    return dict(n=int(len(x)), min=float(x.min()), median=float(x.median()), max=float(x.max()), mean=float(x.mean()))

# ---------------- Task 1
T = pd.read_csv(J + 'inputs/AK_TREE_v103.csv', low_memory=False)
live = T[(T.Status == 'live') & (T.DBH > 0)]
H = pd.read_csv(FR + 'AK_HCB_v103.csv'); H = H[(H.HT > 0) & H.HCB.notna()]; cr = ((H.HT - H.HCB) / H.HT).clip(0, 1)
dN = pd.read_csv(FR + 'dDBH_NO_v103_model.csv', low_memory=False)
hN = pd.read_csv(FR + 'dHT_NO_v103_model.csv', low_memory=False)
dC = dN[dN.Origin.notna()]; hC = hN[hN.Origin.notna()]
assert dC.Planted.notna().all() and hC.Planted.notna().all()
dd = (dC['DBH.1'] - dC['DBH.0']) / dC.YIP; dh = (hC['HT.1'] - hC['HT.0']) / hC.YIP
dd_all = (dN['DBH.1'] - dN['DBH.0']) / dN.YIP; dh_all = (hN['HT.1'] - hN['HT.0']) / hN.YIP
kual0 = (live.Data == 'Kualoa') & ~(live.EXPF > 0)
lvb = live[~kual0]
old = json.load(open(J + 'a3/pending/table2_v103.json'))['rows']
M2 = 'm^2^ ha^−1^'
rows = [['DBH (cm)'] + st(live.DBH, 1), ['Height (m)'] + st(live.HT[live.HT > 0], 1), ['Crown ratio'] + st(cr, 2),
        [f'BAPH ({M2})'] + st(lvb.BAPH, 1), [f'BAL ({M2})'] + st(lvb.BALl, 1),
        ['ΔDBH (cm yr^−1^)'] + st(dd, 2), ['ΔHT (m yr^−1^)'] + st(dh, 2)]
R['task1'] = dict(
    rows=rows,
    unchanged_DBH_HT_CR=[rows[i] == old[i] for i in range(3)],
    old_rows=old,
    n_dDBH_NO=len(dN), n_dDBH_origin=len(dC), n_dDBH_no_origin=int(dN.Origin.isna().sum()),
    n_dHT_NO=len(hN), n_dHT_origin=len(hC), n_dHT_no_origin=int(hN.Origin.isna().sum()),
    no_origin_by_source_dDBH=dN[dN.Origin.isna()].Data.value_counts().to_dict(),
    no_origin_by_source_dHT=hN[hN.Origin.isna()].Data.value_counts().to_dict(),
    dDBH_min_3dp=f"{dd.min():.3f}", dHT_min_3dp=f"{dh.min():.3f}",
    dDBH_below_0005=int((dd < 0.005).sum()), dHT_below_0005=int((dh < 0.005).sum()),
    dDBH_all_NO_check=st(dd_all, 2), dHT_all_NO_check=st(dh_all, 2),
    kualoa_live=int((live.Data == 'Kualoa').sum()), kualoa_live_expf0=int(kual0.sum()),
    kualoa_live_expf_values=live[live.Data == 'Kualoa'].EXPF.fillna(-1).value_counts().to_dict(),
    n_BAPH_BAL=len(lvb),
    BAPH_unrounded=q(lvb.BAPH), BAL_unrounded=q(lvb.BALl))
json.dump(dict(source='inputs/AK_TREE_v103.csv live DBH>0 (BAPH, BALl; Kualoa EXPF 0 excluded for BAPH/BAL); frames/final/AK_HCB_v103.csv; frames/final/d*_NO_v103_model.csv with Origin non-missing, annualized over YIP', rows=rows),
          open(O + 'table2_v106.json', 'w'), ensure_ascii=False, indent=1)

# ---------------- Task 2
I = pd.read_csv(J + 'inputs/AK.TREE.incr_v103.csv', low_memory=False)
I['YIP'] = I['t.1'] - I['t.0']
ll = (I['Status.0'] == 'live') & (I['Status.1'] == 'live')
lld = ll & (I['DBH.0'] > 0) & (I['DBH.1'] > 0) & (I.YIP > 0)
ann = I.dDBH / I.YIP
sD = lld & (ann > 0) & (ann < 10)
annh = I.dHT / I.YIP
sH = sD & (annh > 0) & (annh < 10)
dCS = pd.read_csv(FR + 'dDBH_CS_v103_model.csv', low_memory=False); hCS = pd.read_csv(FR + 'dHT_CS_v103_model.csv', low_memory=False)
R['task2'] = dict(
    incr_rows_all_consecutive_tree_intervals=len(I),
    live_live=int(ll.sum()), live_live_dbh_pos_yip_pos=int(lld.sum()),
    live_live_ht_pos_both=int((lld & (I['HT.0'] > 0) & (I['HT.1'] > 0)).sum()),
    after_dDBH_screen_before_geo_merge=int(sD.sum()), after_dHT_screen_before_geo_merge=int(sH.sum()),
    CS_dDBH=len(dCS), CS_dHT=len(hCS), CS_dDBH_by_source=dCS.Data.value_counts().to_dict(), CS_dHT_by_source=hCS.Data.value_counts().to_dict(),
    NO_dDBH=len(dN), NO_dHT=len(hN), NO_dDBH_firstlast=int((dN.consec == 0).sum()), NO_dHT_firstlast=int((hN.consec == 0).sum()),
    CAL_dDBH=len(dC), CAL_dHT=len(hC), CAL_dDBH_consec=int((dC.consec == 1).sum()), CAL_dHT_consec=int((hC.consec == 1).sum()),
    CAL_dDBH_firstlast=int((dC.consec == 0).sum()), CAL_dHT_firstlast=int((hC.consec == 0).sum()))
# v102 deposited frames
for f in ['frames/v102/dDBH_v102.csv', 'frames/v102/dHT_v102.csv']:
    if os.path.exists(J + f):
        R['task2'][f] = int(sum(1 for _ in open(J + f)) - 1)

# ---------------- Task 3
tj = pd.read_csv(FR + 'tree_join_v103.csv', low_memory=False)
lv = tj[(tj.status == 'live') & (tj.dbh > 0)]
pl = lv.groupby(['source', 'inst', 'plot']).byi.first()
G = pd.read_csv(J + 'engine_v103/AK_PLT_GEO.csv')
assert not any(c.lower() in ('lat', 'lon', 'long', 'latitude', 'longitude', 'x', 'y') for c in G.columns)
Gs = G.groupby('Data').agg(rows=('Plot', 'size'), with_byi=('BYI', 'count'), byi0=('BYI', lambda s: int((s == 0).sum())))
lvb_ = lv[lv.byi.notna()]
t3 = dict(
    live_records=len(lv), live_with_byi=int(lv.byi.notna().sum()), live_byi0=int((lv.byi == 0).sum()),
    live_byi0_by_plot=lv[lv.byi == 0].groupby(['source', 'inst', 'plot']).size().reset_index().astype(str).values.tolist(),
    live_plots=int(len(pl)), live_plots_with_byi=int(pl.notna().sum()), live_plots_byi0=int((pl == 0).sum()),
    live_plot_byi=q(pl), live_plots_by_source=lv.groupby('source').apply(lambda d: d.groupby(['inst', 'plot']).ngroups).to_dict(),
    live_plots_with_byi_by_source=pl.dropna().groupby(level=0).size().to_dict(),
    geo_table_rows=len(G), geo_by_source=Gs.to_dict(orient='index'), geo_byi=q(G.BYI), geo_byi0=int((G.BYI == 0).sum()),
    geo_plots_not_in_live=int(len(set(map(tuple, G[['Data', 'Install', 'Plot']].astype(str).values)) - set(map(tuple, pd.DataFrame(list(pl.index)).astype(str).values)))),
    record_weighted=q(lvb_.byi),
    by_source_record_mean={k: round(float(v), 1) for k, v in lv.groupby('source').byi.mean().items()},
    by_source_records_with_byi=lv.groupby('source').byi.count().to_dict(),
    by_source_records_missing_byi=lv.groupby('source').byi.apply(lambda s: int(s.isna().sum())).to_dict(),
    cal_dDBH_byi=q(dC.BYI), cal_dHT_byi=q(hC.BYI), cal_dDBH_byi0=int((dC.BYI == 0).sum()), cal_dHT_byi0=int((hC.BYI == 0).sum()),
    cs_dDBH_byi=q(dCS.BYI), cs_dHT_byi=q(hCS.BYI))
# static height fit: track3_rt/02_height_refit.R line 16: live & ht>0 & finite byi & finite baph from tree_join
hf = lv[np.isfinite(lv.ht) & (lv.ht > 0) & np.isfinite(lv.byi) & np.isfinite(lv.baph)]
t3['height_fit_rows'] = len(hf); t3['height_fit_byi0'] = int((hf.byi == 0).sum())
t3['height_fit_byi0_plots'] = hf[hf.byi == 0].groupby(['source', 'inst', 'plot']).size().reset_index().astype(str).values.tolist()
Hh = pd.read_csv(FR + 'AK_HCB_v103.csv'); Hf = Hh[np.isfinite(Hh.HCB) & np.isfinite(Hh.HT) & (Hh.HT > 0) & np.isfinite(Hh.BYI)]
t3['hcb_fit_rows'] = len(Hf); t3['hcb_fit_byi0'] = int((Hf.BYI == 0).sum()); t3['hcb_byi'] = q(Hf.BYI)
SH = pd.read_csv(FR + 'static_height_frame_v103.csv', low_memory=False)
t3['static_height_frame_rows'] = len(SH)
R['task3'] = t3

# ---------------- Task 4
ys = dCS.groupby('Data').YIP.agg(['count', 'median', 'min', 'max'])
Tm = T.copy()
my = Tm.groupby(['Data', 'Install']).Measure.nunique()
myp = Tm.groupby(['Data', 'Install', 'Plot']).Measure.nunique()
mylive = live.groupby(['Data', 'Install']).Measure.nunique()
yrs = Tm.groupby('Data').Measure.apply(lambda s: sorted(pd.unique(s.dropna()).tolist()))
# plot level consecutive visit gaps from the tree table (all records)
def gaps(d):
    out = []
    for _, g in d.groupby(['Install', 'Plot']):
        y = np.sort(pd.unique(g.Measure.dropna())); out += list(np.diff(y))
    return out
pg = {s: gaps(d) for s, d in Tm.groupby('Data')}
R['task4'] = dict(
    cs_dDBH_yip_by_source=ys.reset_index().to_dict(orient='records'),
    cs_dDBH_yip_all=q(dCS.YIP), cs_dHT_yip_all=q(hCS.YIP),
    cs_dDBH_installations=int(dCS.groupby(['Data', 'Install']).ngroups),
    measurement_years_by_source={k: [int(x) if float(x).is_integer() else x for x in v] for k, v in yrs.items()},
    plot_visit_gap_by_source={s: (dict(n=len(v), median=float(np.median(v)), min=float(min(v)), max=float(max(v))) if v else 'single measurement year') for s, v in pg.items()},
    installations_total=int(len(my)), installations_ge2_years_all_records=int((my >= 2).sum()),
    installations_ge2_years_live_records=int((mylive >= 2).sum()),
    installations_ge2_by_source=(my >= 2).groupby(level=0).sum().astype(int).to_dict(),
    installations_by_source=my.groupby(level=0).size().to_dict(),
    plots_ge2_years=int((myp >= 2).sum()))
# all remeasured tree intervals (incr table, live-live) interval range
R['task4']['incr_live_live_yip'] = q(I.loc[lld, 'YIP'])
R['task4']['incr_live_live_yip_by_source'] = I.loc[lld].groupby('Data.0').YIP.median().to_dict()

# ---------------- Task 5
K = T[T.Data == 'Kualoa']
R['task5'] = dict(
    kualoa_installations=int(K.Install.nunique()), kualoa_plots=int(K.groupby(['Install', 'Plot']).ngroups),
    kualoa_years=sorted(pd.unique(K.Measure).tolist()), kualoa_rows=len(K),
    geo_table='engine_v103/AK_PLT_GEO.csv (columns: ' + ','.join(G.columns) + '; no coordinate columns)',
    geo_rows_by_source=G.Data.value_counts().to_dict(), geo_rows=len(G),
    geo_FIA_installations=int(G[G.Data == 'FIA'].Install.nunique()), geo_FIA_rows=int((G.Data == 'FIA').sum()),
    tree_plots_by_source=T.groupby('Data').apply(lambda d: d.groupby(['Install', 'Plot']).ngroups).to_dict(),
    tree_installations_by_source=T.groupby('Data').Install.nunique().to_dict(),
    live_plots_by_source=live.groupby('Data').apply(lambda d: d.groupby(['Install', 'Plot']).ngroups).to_dict(),
    live_installations_by_source=live.groupby('Data').Install.nunique().to_dict(),
    live_FIA_installations=int(live[live.Data == 'FIA'].Install.nunique()), live_FIA_subplots=int(live[live.Data == 'FIA'].groupby(['Install', 'Plot']).ngroups))
P2 = pd.read_csv(J + 'inputs/PLT.GEO.V2_v102.csv', usecols=['Data', 'Install', 'Plot'])
R['task5']['pltgeo_v2_rows_by_source'] = P2.Data.value_counts().to_dict()

# ---------------- Task 6
S = pd.read_csv(J + 'out/repair/plotyear_stand_before_after.csv', low_memory=False)
PL = pd.read_csv(J + 'inputs/AK_PLT_v103.csv', low_memory=False)
org = PL.drop_duplicates(['Data', 'Install', 'Plot'])[['Data', 'Install', 'Plot', 'Origin']]
for c in ['Install', 'Plot']: org[c] = org[c].astype(str); S[c] = S[c].astype(str)
S = S.merge(org, on=['Data', 'Install', 'Plot'], how='left')
ORT = pd.read_csv(J + 'inputs/psp_origin_thinning_2026-09-16_DATA.csv')
psp_pl = set(ORT.Install[ORT.Origin_new == 'Planted'].astype(str))
S['Origin_recode'] = np.where((S.Data == 'PSP'), np.where(S.Install.isin(psp_pl), 'Planted', 'Natural'), S.Origin)
t6 = dict(rows=len(S), origin_missing=int(S.Origin.isna().sum()))
def top(df, col, n=5):
    return df.sort_values(col, ascending=False).head(n)[['Data', 'Install', 'Plot', 'Measure', col, 'BAPH', 'QMD', 'SDI', 'TPH', 'nlive_all', 'nlive_koa', 'n_live_dbh', 'Origin', 'Origin_recode', col.replace('_dep', '') + '_dep' if not col.endswith('_dep') else col]].to_dict(orient='records')
for oc in ['Origin', 'Origin_recode']:
    for nc in ['nlive_all', 'n_live_dbh']:
        nat = S[(S[oc] == 'Natural') & (S[nc] >= 5)]
        t6[f'{oc}|{nc}>=5'] = dict(n_plotyears=len(nat), top_QMD=top(nat, 'QMD'), top_BAPH=top(nat, 'BAPH'),
                                   top_SDI_DOFAW=top(nat[nat.Data == 'DOFAW'], 'SDI'))
dn = S[(S.Data == 'DOFAW') & (S.Origin == 'Natural')]
t6['DOFAW_natural_plotyears_SDIdep_600_950'] = dn[(dn.SDI_dep >= 600) & (dn.SDI_dep <= 950)][['Install', 'Plot', 'Measure', 'SDI_dep', 'SDI', 'BAPH_dep', 'BAPH', 'nlive_all']].to_dict(orient='records')
t6['DOFAW_natural_plotyears_SDI_600_950'] = dn[(dn.SDI >= 600) & (dn.SDI <= 950)][['Install', 'Plot', 'Measure', 'SDI_dep', 'SDI', 'BAPH_dep', 'BAPH', 'nlive_all']].to_dict(orient='records')
t6['DOFAW_natural_plot_max_SDI'] = dn.groupby(['Install', 'Plot']).agg(SDI_max=('SDI', 'max'), SDI_dep_max=('SDI_dep', 'max'), n=('SDI', 'size')).reset_index().sort_values('SDI_max', ascending=False).to_dict(orient='records')
t6['all_max_BAPH_dep'] = S.sort_values('BAPH_dep', ascending=False).head(3)[['Data', 'Install', 'Plot', 'Measure', 'BAPH_dep', 'BAPH', 'SDI_dep', 'SDI', 'Origin']].to_dict(orient='records')
# projections
tr = pd.read_csv(J + 'engine_v103/out_m1/traj_M1.csv'); ut = pd.read_csv(J + 'engine_v103/out_m1/uneven_aged_traj_M1.csv')
pk = {}
for (o, b), g in tr.groupby(['origin', 'byi']):
    g = g[g.year <= 100]; pk[f'even|{o}|{b}'] = dict(SDI=float(g.SDI.max()), SDI_age=int(g.year[g.SDI.idxmax()]), BAPH=float(g.BAPH.max()), BAPH_age=int(g.year[g.BAPH.idxmax()]), QMD100=float(g.QMD.max()), years=int(g.year.max()))
for b, g in ut.groupby('BYI'):
    g = g[g.age <= 100]; pk[f'uneven|nat|{b}'] = dict(SDI=float(g.SDI.max()), SDI_age=int(g.age[g.SDI.idxmax()]), BAPH=float(g.BAPH.max()), BAPH_age=int(g.age[g.BAPH.idxmax()]), QMD100=float(g.QMD.max()), years=int(g.age.max()))
t6['projection_peaks_age_le_100'] = pk
t6['traj_columns'] = list(tr.columns); t6['uneven_traj_columns'] = list(ut.columns)
t6['tree_level_output_in_out_m1'] = sorted(os.listdir(J + 'engine_v103/out_m1'))
R['task6'] = t6

# ---------------- Task 9
g = ut[(ut.BYI == 100) & (ut.age >= 11) & (ut.age <= 100)]
sl = np.polyfit(np.log(g.QMD), np.log(g.TPH), 1)[0]
g2 = ut[(ut.BYI == 100) & (ut.age >= 10) & (ut.age <= 100)]
R['task9'] = dict(
    a_reineke_uneven_low_11_100_slope_lnTPH_on_lnQMD=float(sl),
    a_variant_10_100=float(np.polyfit(np.log(g2.QMD), np.log(g2.TPH), 1)[0]),
    a_bakuzis_slopes_M1=pd.read_csv(J + 'engine_v103/out_m1/bakuzis_slopes_M1.csv').to_dict(orient='records'),
    b_CF=float(np.exp(0.5 * (0.586222 ** 2 + 0.533222 ** 2))),
    c_pct_below=float(100 * (1 - 0.7833 / 0.8203)))
json.dump(R, open(O + 'compute_v106.json', 'w'), indent=1, default=str, ensure_ascii=False)
print(json.dumps(R, indent=1, default=str, ensure_ascii=False))
