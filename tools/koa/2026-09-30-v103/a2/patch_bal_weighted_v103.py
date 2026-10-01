"""patch_bal_weighted_v103.py (2026-09-30, red team A1A2 finding 1). The engine's exact BAL path ranked every record of the projected list
unweighted, and projected records are never removed (expf decays to a 1e-5 floor), so dead weight stayed in the rank and the survivors' BAL
fraction collapsed from about 0.5 to 0.1 to 0.3 over long projections, while the deployed constants were solved under the live list
percentile (l). Fix: the percentile is weighted by expf, fraction_i = (weight of other records with DBH >= DBH_i) / (total weight - w_i),
the minimum tie rule analogue; with equal expf it equals the unweighted rule of record exactly. Switch KP.BAL_PERCENTILE_WEIGHTED (True in
v103). Call sites pass expf. The cohort path is unchanged (its fraction is fitted, v103/l row)."""
import os, sys
E = os.path.abspath(sys.argv[1])
def sub1(t, o, n):
    assert t.count(o) == 1, (o[:70], t.count(o)); return t.replace(o, n)
p = f"{E}/koa_params.py"; t = open(p).read()
t = sub1(t, 'PSP_BAL_MODES = ("percentile", "cumsum")\nPSP_BAL_MODE = "percentile"\n',
 'PSP_BAL_MODES = ("percentile", "cumsum")\nPSP_BAL_MODE = "percentile"\n# 30 September 2026 (v103, red team A1A2 finding 1): the exact path percentile is weighted by expf so\n# that decayed records do not stay in the rank; with equal expf it equals the unweighted rule of record.\n# False reproduces engine_v102 and the pre-fix engine_v103 exactly.\nBAL_PERCENTILE_WEIGHTED = True\n')
open(p, "w").write(t)
p = f"{E}/koa_equations.py"; t = open(p).read()
t = sub1(t, "def stand_bal(baph, dbh=None, qmd=None, tph=None):", '''def bal_percentile_fraction_weighted(dbh, expf):
    """expf-weighted live list analogue of bal_percentile_fraction (v103, 2026-09-30): share of the OTHER
    stems (by expf) with DBH >= DBH_i, i.e. (W_ge_i - w_i) / (W - w_i). Equal expf gives (r_ge - 1)/(n - 1),
    identical to 1 - (r_min - 1)/(n - 1) of the rule of record."""
    d = np.asarray(dbh, float); w = np.clip(np.asarray(expf, float), 0.0, None); n = d.size
    if n < 2:
        return np.zeros(n)
    W = w.sum()
    if W <= 0:
        return np.zeros(n)
    o = np.argsort(d, kind="mergesort"); sd = d[o]; sw = w[o]
    cw = np.concatenate([[0.0], np.cumsum(sw)])
    first = np.searchsorted(sd, sd, side="left")
    ge = W - cw[first]
    fr = np.clip((ge - sw) / np.maximum(W - sw, 1e-12), 0.0, 1.0)
    out = np.empty(n); out[o] = fr
    return out


def stand_bal(baph, dbh=None, qmd=None, tph=None, expf=None):''')
t = sub1(t, "        return np.asarray(baph, float) * bal_percentile_fraction(dbh)\n",
 "        if getattr(KP, \"BAL_PERCENTILE_WEIGHTED\", False) and expf is not None:   # v103, 2026-09-30\n            return np.asarray(baph, float) * bal_percentile_fraction_weighted(dbh, expf)\n        return np.asarray(baph, float) * bal_percentile_fraction(dbh)\n")
open(p, "w").write(t)
for f, o, n in ((f"{E}/koa_projector.py", "            bal = stand_bal(baph=(ba.sum()), dbh=dbh)\n", "            bal = stand_bal(baph=(ba.sum()), dbh=dbh, expf=expf)   # weighted percentile, v103\n"),
                (f"{E}/run_candidates.py", 'else stand_bal(baph=ba.sum(), dbh=dbh)\n', 'else stand_bal(baph=ba.sum(), dbh=dbh, expf=expf)   # weighted percentile, v103\n'),
                (f"{E}/regen_figS4S5.py", 'else stand_bal(baph=ba.sum(), dbh=dbh)\n', 'else stand_bal(baph=ba.sum(), dbh=dbh, expf=expf)   # weighted percentile, v103\n')):
    t = open(f).read(); t = sub1(t, o, n); open(f, "w").write(t)
print("weighted BAL patched in", E)
