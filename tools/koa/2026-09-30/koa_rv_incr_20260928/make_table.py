# make_table.py. Assemble the supplement-ready sensitivity table (CSV and markdown) from out/sens_*_coef.csv, out/sens_*_stats.csv,
# out/s0_reference_gate.csv and out/boot_summary.csv (if present).
import pandas as pd, os, numpy as np
O = 'out'
SPECS = [('fixsrc', 'Source fixed'), ('treere', 'Tree RE'), ('nocr', 'No ln(CR)'), ('balconv', 'Conventional BAL'),
         ('lt3', 'Interval >= 3 yr'), ('wlen', 'Length weighted'), ('nonpos', 'Non-positive restored'), ('dofaw', 'DOFAW only')]
LAB = {'b0': 'b0 intercept', 'b1': 'b1 ln(size+1)', 'b2': 'b2 size', 'b3': 'b3 BAL^2/ln(size+5)', 'b4': 'b4 ln(BAL+1)', 'b5': 'b5 ln(CR)',
       'b6': 'b6 sqrt(BAPH x size)', 'b7': 'b7 Planted x size', 'b8': 'b8 ln(BYI)', 'b9': 'b9 Planted'}
def f(x, s):
    if pd.isna(x): return ''
    a = abs(x); d = 5 if a < 0.01 else (4 if a < 0.1 else 3)
    return f'{x:.{d}f} ({s:.{d}f})' if not pd.isna(s) else f'{x:.{d}f}'
rows = []; ref = None
for spec, lab in SPECS:
    p = f'{O}/sens_{spec}_coef.csv'
    if not os.path.exists(p): continue
    c = pd.read_csv(p); c['label'] = lab; rows.append(c)
C = pd.concat(rows)
boot = pd.read_csv(f'{O}/boot_summary.csv') if os.path.exists(f'{O}/boot_summary.csv') else None
out = []
for resp in ['dDBH', 'dHT']:
    base = C[(C.resp == resp) & C.term.isin(LAB)].drop_duplicates('term')[['term', 'ref_estimate', 'ref_se']]
    for _, b in base.sort_values('term').iterrows():
        r = {'response': resp, 'term': LAB[b.term], 'Reference (Wald SE)': f(b.ref_estimate, b.ref_se)}
        if boot is not None:
            bb = boot[(boot.resp == resp) & (boot.term == b.term)]
            if len(bb): bb = bb.iloc[0]; r['Bootstrap SE [95% percentile]'] = f"{bb.boot_se:.4g} [{bb.lo95:.4g}, {bb.hi95:.4g}]"; r['Boot/Wald SE'] = f"{bb.ratio:.2f}"
        for spec, lab in SPECS:
            x = C[(C.resp == resp) & (C.spec == spec) & (C.term == b.term)]
            r[lab] = '' if not len(x) else f(x.estimate.iloc[0], x.se.iloc[0]) + (f' [{x.dz_refSE.iloc[0]:+.1f}]' if not pd.isna(x.dz_refSE.iloc[0]) else '')
        out.append(r)
    for t in ['b0.DataFIA', 'b0.DataKMR PSP', 'b0.DataPSP']:
        x = C[(C.resp == resp) & (C.spec == 'fixsrc') & (C.term == t)]
        if len(x): out.append({'response': resp, 'term': 'source shift ' + t.replace('b0.Data', ''), 'Source fixed': f(x.estimate.iloc[0], x.se.iloc[0])})
T = pd.DataFrame(out).fillna('')
# statistics block
g = pd.read_csv(f'{O}/s0_reference_gate.csv')
S = []
for resp in ['dDBH', 'dHT']:
    gg = g[g.resp == resp].iloc[0]
    st = {'response': resp, 'fit': 'Reference', 'n': int(gg.n), 'logLik': round(gg.logLik, 1), 'AIC': round(pd.read_csv(f'{O}/sens_nocr_stats.csv').set_index('resp').loc[resp, 'ref_AIC'], 1), 'dAIC vs reference': 0.0,
          'R2 conditional (period)': round(gg.r2_cond, 3), 'R2 PA calibrated (annual)': round(gg.r2_pa_cal, 3), 'k natural': f"{gg.k_nat:.3f}", 'k planted': f"{gg.k_pl:.3f}"}
    S.append(st)
    for spec, lab in SPECS:
        p = f'{O}/sens_{spec}_stats.csv'
        if not os.path.exists(p): continue
        s = pd.read_csv(p); s = s[s.resp == resp]
        if not len(s): continue
        s = s.iloc[0]; same = spec in ('fixsrc', 'treere', 'nocr', 'balconv', 'wlen')
        S.append({'response': resp, 'fit': lab, 'n': int(s.n), 'logLik': round(s.logLik, 1), 'AIC': round(s.AIC, 1),
                  'dAIC vs reference': round(s.AIC - s.ref_AIC, 1) if same else 'not comparable (different records)',
                  'R2 conditional (period)': round(s.r2_cond_period, 3), 'R2 PA calibrated (annual)': round(s.r2_pa_ann_cal, 3),
                  'k natural': f"{s.k_nat:.3f} ({s.k_nat_lo:.3f} to {s.k_nat_hi:.3f})", 'k planted': (f"{s.k_pl:.3f} ({s.k_pl_lo:.3f} to {s.k_pl_hi:.3f})" if not pd.isna(s.k_pl) else ''),
                  'k on full v102 frame (nat, pl)': (f"{s.kfull_nat:.3f}, {s.kfull_pl:.3f}" if spec in ('lt3', 'dofaw') else ''),
                  'R2 PA calibrated on full frame': (round(s.r2_full_pa_ann_cal, 3) if spec in ('lt3', 'dofaw') else '')})
S = pd.DataFrame(S).fillna('')
T.to_csv(f'{O}/sensitivity_table_coefficients.csv', index=False); S.to_csv(f'{O}/sensitivity_table_fit.csv', index=False)
def md(df):
    cols = list(df.columns); s = '| ' + ' | '.join(cols) + ' |\n|' + '|'.join(['---'] * len(cols)) + '|\n'
    for _, r in df.iterrows(): s += '| ' + ' | '.join(str(r[c]) for c in cols) + ' |\n'
    return s
with open(f'{O}/sensitivity_table.md', 'w') as fh:
    fh.write('Table S-sens-a. Eq. 4 coefficients under each sensitivity fit, estimate (Wald SE) [change in reference SE units].\n\n' + md(T))
    fh.write('\nTable S-sens-b. Fit statistics and origin multipliers (k, CF convention of the deployed engine: 1.36869 for dDBH, 1.030 for dHT; 95% intervals from 2,000 installation-cluster bootstrap resamples of the calibration, coefficients held fixed).\n\n' + md(S))
print(md(S))
