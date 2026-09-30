"""check_observed_repair.py (2026-09-30). Do the 23 plot validation and the mortality level calibration read the deposited plot-year BAPH / TPH?
Both compute observed stand values from the live tree list with EXPF (koa_longterm_validation.validate lines 121 to 125 and 142 to 145,
calib_mort.py lines 48 to 53); the deposited BAPH / TPH columns of AK_TREE.csv are never read. This script shows, for the 29 repaired
plot-years, the deposited, repaired (out/plotyear_repair_log.csv) and engine live-list values, and lists the affected intervals.
Writes out/observed_repair_check.csv and out/observed_repair_intervals.csv."""
import pandas as pd, numpy as np
R = pd.read_csv("out/plotyear_repair_log.csv"); keys = set(R.key)
t = pd.read_csv("engine_refit2/AK_TREE.csv", low_memory=False)
for k in ("Data", "Install", "Plot"): t[k] = t[k].astype(str)
t["pid"] = t.Data + "|" + t.Install + "|" + t.Plot; t["key"] = t.pid + "|" + t.Measure.astype(str)
rows = []
for _, r in R.iterrows():
    g = t[t.key == r.key]; live = g[(g.Status.astype(str).str.lower() == "live") & (pd.to_numeric(g.DBH, errors="coerce") > 0)]
    e = pd.to_numeric(live.EXPF, errors="coerce").fillna(0); d = pd.to_numeric(live.DBH, errors="coerce")
    rows.append(dict(key=r.key, n_live=len(live), TPH_deposited=r.TPH_deposited, TPH_repaired=r.TPH_livelist, TPH_engine_livelist=e.sum(),
                     BAPH_deposited=r.BAPH_deposited, BAPH_repaired=r.BAPH_livelist, BAPH_engine_livelist=(d ** 2 * 0.00007854 * e).sum(), deposited_column_in_AK_TREE=float(g.BAPH.iloc[0])))
X = pd.DataFrame(rows); X["engine_equals_repaired"] = (np.abs(X.TPH_engine_livelist - X.TPH_repaired) < 1e-6) & (np.abs(X.BAPH_engine_livelist - X.BAPH_repaired) < 1e-6)
X.to_csv("out/observed_repair_check.csv", index=False)
REM = {'101': [2018, 2019], '102': [2018, 2019], '103': [2018, 2019], '104': [2018, 2019], '105': [2018], '106': [2018], '107': [2018], '108': [2018], '109': [2018], '110': [2018], '111': [2018], '112': [2018], '113': [2018], '114': [2018], '115': [2018], '116': [2018], '117': [2018], '118': [2018], '119': [2018, 2021], '120': [2018, 2021], '121': [2018, 2021], '122': [2018, 2021], '201': [2020], '202': [2020], '203': [2020], '204': [2020], '205': [2020], '206': [2020], '207': [2020], '208': [2020]}
V = pd.read_csv("out/val_refit2.csv"); iv = []
for pid in V.pid:
    meas = sorted(t[t.pid == pid].Measure.dropna().unique()); t0, t1 = meas[0], meas[-1]
    rm = REM.get(pid.split("|")[1]) if pid.startswith("PSP|") else None
    if rm: t1 = [m for m in meas if m < min(rm)][-1]
    hit = [f"{pid}|{int(m)}" for m in (t0, t1) if f"{pid}|{int(m)}" in keys]
    if hit: iv.append(dict(use="validation", pid=pid, m_from=t0, m_to=t1, repaired_plotyear=";".join(hit)))
IV = pd.read_csv("mort/refit2/plot_intervals_origin.csv"); IV = IV[(IV.planted == 0) & (~IV.removal.astype(bool))]
for _, r in IV.iterrows():
    hit = [f"{r.Data}|{r.Install}|{r.Plot}|{int(x)}" for x in (r.m_from, r.m_to) if f"{r.Data}|{r.Install}|{r.Plot}|{int(x)}" in keys]
    if hit: iv.append(dict(use="calibration", pid=f"{r.Data}|{r.Install}|{r.Plot}", m_from=r.m_from, m_to=r.m_to, repaired_plotyear=";".join(hit)))
I = pd.DataFrame(iv); I.to_csv("out/observed_repair_intervals.csv", index=False)
print("all 29 engine live-list values equal the repaired values:", bool(X.engine_equals_repaired.all()))
print("deposited / repaired TPH ratio range", (X.TPH_deposited / X.TPH_repaired).min().round(3), (X.TPH_deposited / X.TPH_repaired).max().round(3))
print(I.to_string())
