"""beta_anchor_v103.py: GARCIA_BETA_ANCHORED = 100 / sqrt(z99), z99 the 99th percentile of N x H_QMD^2, H_QMD = exp((ln QMD - A) / K_HD).
Gate: the record form (KeyDupFlag 0, every record of the plot-measure, >= 5 records, N = sum EXPF, QMD from the same records; which counts dead
stems) reproduces z99 389696.30682452 and n 471 on AK_TREE_record.csv. v103 deployed form: repaired live all species TPH and QMD of every plot-year
with >= 5 live stems (DBH > 0, EXPF > 0), with the v103 allometry."""
import pandas as pd, numpy as np, json
al = pd.read_csv("track2/stage1/garcia_allometry_v103.csv", index_col=0)
def z(tab, A, K): v = tab.N * np.exp((np.log(tab.Q) - A) / K) ** 2; return float(np.quantile(v, 0.99)), len(v)
def recform(t, A, K):
    t = t[t.KeyDupFlag == 0].copy(); t["key"] = t.Data + "|" + t.Install.astype(str) + "|" + t.Plot.astype(str) + "|" + t.Measure.astype(str)
    g = t.groupby("key").filter(lambda x: len(x) >= 5).groupby("key"); N = g.EXPF.sum(); Q = np.sqrt(g.apply(lambda x: (x.EXPF * x.DBH ** 2).sum()) / N)
    tab = pd.DataFrame(dict(N=N, Q=Q)).query("N > 0 and Q > 0"); return z(tab, A, K)
rec = pd.read_csv("/home/aaron/jobs/koa_v102_20260918/inputs/AK_TREE_record.csv", low_memory=False)
zr, nr = recform(rec, al.loc["record", "A"], al.loc["record", "K_HD"])
ok = abs(zr - 389696.30682452075) < 1e-4 and nr == 471
print("GATE beta anchor record form reproduced: z99", zr, "n", nr, "beta", 100 / np.sqrt(zr), "PASS" if ok else "FAIL")
t3 = pd.read_csv("inputs/AK_TREE_v103.csv", low_memory=False)
A3, K3 = al.loc["v103", "A"], al.loc["v103", "K_HD"]
z3r, n3r = recform(t3, A3, K3)
st = pd.read_csv("out/repair/plotyear_stand_before_after.csv")
st = st[(st.nlive_all >= 5) & (st.TPH > 0) & (st.QMD > 0)]
z3, n3 = z(pd.DataFrame(dict(N=st.TPH, Q=st.QMD)), A3, K3)
lk = t3[(t3.Status == "live") & (t3.DBH > 0) & (t3.EXPF > 0)].copy(); lk["key"] = lk.Data + "|" + lk.Install.astype(str) + "|" + lk.Plot.astype(str) + "|" + lk.Measure.astype(str)
g = lk.groupby("key").filter(lambda x: len(x) >= 5).groupby("key"); N = g.EXPF.sum(); Q = np.sqrt(g.apply(lambda x: (x.EXPF * x.DBH ** 2).sum()) / N)
z3k, n3k = z(pd.DataFrame(dict(N=N, Q=Q)), A3, K3)
res = dict(gate_record_reproduced=ok, record=dict(z99=zr, n=nr, beta=100 / np.sqrt(zr)),
           v103_record_form=dict(z99=z3r, n=n3r, beta=100 / np.sqrt(z3r), note="record form (all records incl. dead, KeyDupFlag 0) on the v103 koa list, v103 allometry"),
           v103_deployed=dict(z99=z3, n=n3, beta=100 / np.sqrt(z3), note="repaired live all species TPH and QMD, plot-years with >= 5 live stems, v103 allometry"),
           v103_koa_live=dict(z99=z3k, n=n3k, beta=100 / np.sqrt(z3k), note="live koa stems only, >= 5, v103 allometry"),
           allometry=dict(A=A3, K_HD=K3))
print(json.dumps(res, indent=1)); json.dump(res, open("track2/stage1/beta_anchor_v103.json", "w"), indent=1)
