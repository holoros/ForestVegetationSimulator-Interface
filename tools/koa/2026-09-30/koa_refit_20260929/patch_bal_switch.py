"""patch_bal_switch.py (2026-09-29). Add the BAL_DEFINITION switch ("percentile" = the v102 concept of record,
"conventional" = expansion-weighted basal area of strictly larger live trees) to engine_refit. Under "percentile" every
number is byte-identical to engine_v102 (rerun of the gate confirms). Usage: python3 patch_bal_switch.py <engine_dir>."""
import os, sys
E = os.path.abspath(sys.argv[1])
def sub1(txt, old, new):
    assert txt.count(old) == 1, (old[:70], txt.count(old)); return txt.replace(old, new)
# ---- koa_params.py: the switch and the conventional cohort fraction
p = os.path.join(E, "koa_params.py"); t = open(p).read()
t = sub1(t, 'PSP_BAL_MODES = ("percentile", "cumsum")\nPSP_BAL_MODE = "percentile"\n',
'''PSP_BAL_MODES = ("percentile", "cumsum")
PSP_BAL_MODE = "percentile"

# -----------------------------------------------------------------------------
# BAL DEFINITION SWITCH. Added 29 September 2026 (koa_refit_20260929). Selects the
# CONCEPT of basal area in larger trees that the increment equations were fitted on.
#   "percentile"   : the 8 September 2026 concept above, BAL = (1 - BA.perc) * BAPH on
#                    the exact path and BAL_COHORT_LIN_B on the cohort path. Reproduces
#                    engine_v102 exactly.
#   "conventional" : BAL_i = sum over live trees j with DBH_j > DBH_i of
#                    (pi / 40000) * DBH_j^2 * EXPF_j, m2 ha-1, on the exact path (ties
#                    receive nothing from equal diameters), and the fraction
#                    a0 + a1 ln(QMD) of BAL_COHORT_LIN_B_CONVENTIONAL on the cohort path.
#                    This is the definition the 29 September 2026 refit of Eq. 4 (dDBH and
#                    dHT, all valid remeasurement intervals) was fitted on, and it is the
#                    definition HiGy.R calc_bal and Midgard HiGy 0.4.0 carry.
# The HCB equation (HCB_P) is NOT refit and keeps its coefficients under both settings
# (decision of the lead, 29 September 2026; its crown BAL term is small).
# -----------------------------------------------------------------------------
BAL_DEFINITIONS = ("percentile", "conventional")
BAL_DEFINITION = "percentile"
BAL_COHORT_LIN_B_CONVENTIONAL = (0.773485460160129, -0.0570969153432526)
# fraction = a0 + a1 * ln(QMD) of conventional BAL / BAPH carried by stems within five
# percent of the stand quadratic mean diameter, ordinary least squares on 410 complete
# plot-years over 118 plots (out/cohort_bal_fraction.csv, row bal == c, 29 September
# 2026). Plot-clustered standard errors a0 0.02870, a1 0.01155; in-sample R2 0.11776,
# residual sd 0.11292, mean fraction 0.62208. Read only when BAL_DEFINITION is
# "conventional".
''')
open(p, "w").write(t)
# ---- koa_equations.py: conventional exact path and cohort coefficients
p = os.path.join(E, "koa_equations.py"); t = open(p).read()
t = sub1(t, '''    a0, a1 = KP.BAL_COHORT_LIN_B
    return np.clip(a0 + a1 * lq, lo, hi)
''', '''    a0, a1 = (KP.BAL_COHORT_LIN_B_CONVENTIONAL if getattr(KP, "BAL_DEFINITION", "percentile") == "conventional"
              else KP.BAL_COHORT_LIN_B)   # BAL_DEFINITION switch, 2026-09-29
    return np.clip(a0 + a1 * lq, lo, hi)


def bal_conventional(dbh, expf):
    """Conventional basal area in larger trees, m2 ha-1, for a live tree list.

    BAL_i = sum over j with DBH_j > DBH_i of (pi / 40000) * DBH_j^2 * EXPF_j. Strict
    inequality: stems of equal diameter contribute nothing to each other. Added
    29 September 2026 for BAL_DEFINITION = "conventional".
    """
    d = np.asarray(dbh, float); e = np.asarray(expf, float)
    if d.size == 0:
        return np.zeros(0)
    ba = (np.pi / 40000.0) * d ** 2 * e
    u, inv = np.unique(d, return_inverse=True)            # ascending distinct diameters
    ba_u = np.bincount(inv, weights=ba, minlength=u.size)
    tail = np.cumsum(ba_u[::-1])[::-1]                    # sum of ba over diameters >= u[k]
    return (tail - ba_u)[inv]
''')
t = sub1(t, '''def stand_bal(baph, dbh=None, qmd=None, tph=None):''', '''def stand_bal(baph, dbh=None, qmd=None, tph=None, expf=None):''')
t = sub1(t, '''        if KP.PSP_BAL_MODE == "cumsum":
            raise RuntimeError("PSP_BAL_MODE='cumsum' is the pre-correction path and is "
                               "reproduced in project_psp, not here.")
        return np.asarray(baph, float) * bal_percentile_fraction(dbh)
''', '''        if KP.PSP_BAL_MODE == "cumsum":
            raise RuntimeError("PSP_BAL_MODE='cumsum' is the pre-correction path and is "
                               "reproduced in project_psp, not here.")
        if getattr(KP, "BAL_DEFINITION", "percentile") == "conventional":   # 2026-09-29
            if expf is None:
                raise ValueError('BAL_DEFINITION="conventional" needs expf on the exact path')
            return bal_conventional(dbh, expf)
        return np.asarray(baph, float) * bal_percentile_fraction(dbh)
''')
open(p, "w").write(t)
# ---- call sites of the exact path: pass expf so the conventional arm can be taken
for f, old, new in ((os.path.join(E, "koa_projector.py"), "            bal = stand_bal(baph=(ba.sum()), dbh=dbh)\n", "            bal = stand_bal(baph=(ba.sum()), dbh=dbh, expf=expf)   # BAL_DEFINITION switch, 2026-09-29\n"),
                    (os.path.join(E, "run_candidates.py"), '        bal = (np.cumsum(ba) - ba) if P.PSP_BAL_MODE == "cumsum" else stand_bal(baph=ba.sum(), dbh=dbh)\n', '        bal = (np.cumsum(ba) - ba) if P.PSP_BAL_MODE == "cumsum" else stand_bal(baph=ba.sum(), dbh=dbh, expf=expf)   # BAL_DEFINITION switch, 2026-09-29\n'),
                    (os.path.join(E, "regen_figS4S5.py"), '        bal = (np.cumsum(ba) - ba) if P.PSP_BAL_MODE == "cumsum" else stand_bal(baph=ba.sum(), dbh=dbh)\n', '        bal = (np.cumsum(ba) - ba) if P.PSP_BAL_MODE == "cumsum" else stand_bal(baph=ba.sum(), dbh=dbh, expf=expf)   # BAL_DEFINITION switch, 2026-09-29\n')):
    t = open(f).read(); t = sub1(t, old, new); open(f, "w").write(t)
print("BAL switch patched in", E)
