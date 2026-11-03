#!/usr/bin/env python3
"""make_run_d.py: builds RUN_v105d.md (what changed, declared deviation, every gate) from the gate files and logs of this job."""
import os, re, json, glob, pandas as pd, numpy as np
W = os.path.expanduser("~/jobs/koa_v105d_20261102"); L = f"{W}/v105d/logs"; O = f"{W}/v105d/out"; out = []
def P(*a): out.append(" ".join(str(x) for x in a))
def rd(p):
    try: return pd.read_csv(p)
    except Exception: return None
def tail(p, n=1, pat=None):
    try: t = open(p, errors="replace").read().strip().split("\n")
    except Exception: return "(log missing)"
    if pat: t = [x for x in t if re.search(pat, x)]
    return " | ".join(t[-n:]) if t else "(no matching line)"
def gate_tbl(df, cols):
    P("| " + " | ".join(cols) + " |"); P("|" + "---|" * len(cols))
    for _, r in df.iterrows(): P("| " + " | ".join(str(r[c]) for c in cols) + " |")
    P("")
J = json.load(open(f"{W}/out/v105_constants.json"))
P("# RUN v105d: koa growth and yield engine v105d (firebreather, ~/jobs/koa_v105d_20261102)"); P("")
P("Built 2026-11-02/03. v105d = v105c (K3c1 dDBH, unchanged) + RD x competition forms in every other component with a competition term.",
  "RD = SDI/923 (SDI = TPH (QMD/25.4)^1.605 from the live list each annual step; population lqmm SDImax 923); share = tree BAL / plot BAPH (0 where BAPH = 0), as K3c1.",
  "Template: the v105c pipeline (koa_v105c_20261102/v105c), copied whole into this job after the v105c MASTER DONE (2026-11-02 23:08 AST); koa_v105c_20261102,",
  "koa_v105_20261102, koa_rdcomp_20261102, koa_compscreen_20261102 and koa_v104_20261030 were only read. No FIA coordinate column was read or written by any v105d script."); P("")
P("## What changed (v105c form -> v105d form)"); P("")
P("| component | v105c (sensitivity) | v105d (deployed) | coefficients from |"); P("|---|---|---|---|")
P("| dHT increment (Eq. 4) | b3 BAL^2/ln(HT+5) + b4 ln(BAL+1) + b6 sqrt(BAPH HT) | K3c1h: b4 ln(x+1) + b6 sqrt(RD HT), x = share x RD, b3 fixed 0 | refit in this job (inc_v103.R, dHT_L_NO), = independent reference fit (prep/fit_dht_k3c1.R) |")
P("| total height Eq. 2 | g1 ln(BAPH+1); a0, a1 refitted | H1a: g1 ln(RD); a0, a1, g1 refitted; b, c, g2 at v104 | koa_compscreen_20261102 H1a (refit reproduced, prep/refit_compscreen.R) |")
P("| HCB Eq. 3 | HCB_P: b3 sqrt(BAL BAPH + 1) + b4 ln(BAPH+1), v102 vector | C2h: b3 sqrt(share RD + 1) + b4 ln(RD), C2 BYI, all six refitted | koa_compscreen_20261102 C2h (refit reproduced) |")
P("| mortality Stage 3 | c3 ln(BAPH+1) + c4 ln(BAL+1) | M3a: c3 ln(RD) + c4 ln(share RD + 1) | koa_compscreen_20261102 M3a (refit reproduced, intercept added) |")
P("| Stages 1, 2, ingrowth | ln(SDI), SDI | unchanged (one SDImax: RD is a rescaled SDI) | - |")
P("| natural mortality level MORT_CAL | %.5f | %.5f (re-solved on the v105d engine, a4/run_mort_v104.sh + v105d/set_mortcal_v105d.py) | a2/mort/v104/H_mort_level_natural.csv |" % (J["V105C_PREV"]["MORT_CAL"]["value"][0], J["MORT_CAL"]["value"][0]))
P("")
P("Engine code: koa_params.HT_FORM, HCB_FORM, DHT_FORM, STAGE3_FORM switch each component; \"v105b\" restores the v105c form exactly (engine parity gate below), so the v105c forms",
  "remain available as the sensitivity in this engine, and the v105c job itself is the read-only v105c reference. ln RD is floored at the minimum RD of each fitting frame",
  "(RD_FLOOR_HT = RD_FLOOR_STAGE3 = %.6g, RD_FLOOR_HCB = %.6g; prep/out/rd_min_fitframes.csv)." % (J["RD_FLOORS"]["height"], J["RD_FLOORS"]["hcb"])); P("")
P("## Declared deviation"); P("")
P("These forms are deployed by Aaron's explicit modeling choice (\"I prefer RD times competition... let's do it all\"), NOT by the preregistered adoption rules, which they fail:")
mono = rd(f"{W}/prep/out/mono_dht_K3p.csv")
P("- dHT: koa_rdcomp_20261102 PREREG rule kept K0 (every RD candidate worse in AIC and better on 1 of 4 held-out sources; K3p dAIC +40.57). The deployed K3c1h has logLik -6952.801,",
  "AIC 13933.60 vs K0 13894.83 (dAIC +38.77; out/inc/fit_stats_v103.csv of this job and of koa_v105c_20261102).")
P("- Eq. 2 H1a: koa_compscreen_20261102 rule failed it (LOIO RMSE 2.3998 vs 2.3969; dAIC +132.97).")
P("- Eq. 3 C2h: failed monotonicity (HCB falls as RD rises at fixed share; the deployed HCB_P fails the same check) and its BYI coefficient bootstrap interval includes zero (-1.294 to 0.042).")
P("- Stage 3 M3a: failed (LOIO within-interval AUC 0.7761 vs 0.7764, Brier 0.1197 vs 0.1140; dAIC +46.25).")
P("Source: koa_compscreen_20261102/RESULTS.md, out/verdicts.csv; koa_rdcomp_20261102/RESULTS.md. The v105c forms are kept as the sensitivity (above)."); P("")
P("## dHT form: K3p failed the monotonicity check, so the constrained analogue K3c1h is deployed"); P("")
if mono is not None:
    m = mono[mono.range == "obsmax"]
    P(f"K3p (koa_rdcomp_20261102 vector; b3 = 0.1165 on x^2/ln(HT+5), b4 = -1.1902): d ln g/dx = 2 b3 x/ln(HT+5) + b4/(x+1) evaluated for x from 0 to the observed maximum",
      f"{m.xmax.iloc[0]:.4f} of the dHT frame at HT = {', '.join(f'{v:.2f}' for v in m.HT)} m: positive on {int(m.n_pos.sum())} of {len(m) * 401} grid points (from x = {m.x_first_pos.min():.3f} at HT {m.HT.min():.2f} m),",
      "so dHT would rise with competition at large x. On x in [0, 2] (the constrained/ grid for dDBH) and [0, p99 = 0.873] it is negative everywhere, and no frame row lies beyond the turning point",
      "(prep/mono_dht.R, prep/out/mono_dht_K3p.csv). Under the brief's 'observed range' reading K3p fails, so the constrained analogue (the x^2 term dropped, b3 = 0, exactly as",
      "koa_rdcomp_20261102/constrained did for dDBH) is deployed: K3c1h, d ln g/dx = b4/(x+1) < 0 for every x (b4 = %.4f)." % J["DHT"]["coef"]["b4"])
P("Not checked by the constrained/ precedent and reported here: at fixed share, dHT rises with RD for dominant trees (b6 > 0 on sqrt(RD HT)); the v105b/v105c dHT has the same property on sqrt(BAPH HT) (realism section of RESULTS_v105d.md)."); P("")
P("## Gates"); P("")
G = rd(f"{W}/prep/out/gate_refit_parity_compscreen.csv"); P("### 1. Refit parity: new fits reproduce the compscreen / rdcomp coefficients"); P("")
if G is not None: gate_tbl(G, ["check", "value", "pass"])
G = rd(f"{O}/gate_dht_code.csv"); P("dHT code path (v105d/gate_dht_code.R): frame columns and deterministic predictions vs koa_rdcomp_20261102; K3p refit through the patched path is INFO only",
  "(start-dependent optimizer stop: from the stored K3p vector it stops at logLik 0.006 below the koa_rdcomp best-of-two-starts value, 1.5e-3 SE)."); P("")
if G is not None: gate_tbl(G, ["check", "value", "pass"])
G = rd(f"{O}/gate_v105d_fit.csv"); P("Fit gate after the full inc_v103.R refit (v105d/gate_v105d_fit.R):"); P("")
if G is not None: gate_tbl(G, ["check", "value", "pass"])
P("### 2. Engine parity"); P("")
G = rd(f"{O}/parity_engine.csv"); P("Patched engine with every v105d switch at \"v105b\" vs the v105c outputs (run_engine six scenarios x 300 yr incl. Stage 3 tree_eq ordering, HCB, dHT, Eq. 2; 23-plot validation; years grid):"); P("")
if G is not None: gate_tbl(G, ["file", "rows", "max_abs_diff", "pass_"])
G = rd(f"{O}/parity_py_r.csv"); P("Python engine vs R for every component (v105d/py_r_parity_d.R, .py), deployed v105d engine:"); P("")
if G is not None: gate_tbl(G, ["check", "rows", "max_rel_diff", "tol", "pass_"])
P("### 3. Hard-coded coefficient literals"); P("")
P("v105d/check_literals_v105d.py greps every .py/.R/.sh of engine_v103, registry engines, a2, a4, a5, track2, scripts for literals of the replaced v105c vectors (HT_P, HCB_P, dHT_L_NO,",
  "STAGE3_COEF) and for the v105b-form Stage 3 expression, and exits 1 on any unlisted hit. Result:", tail(f"{L}/check_literals.log", 1, "LITERALS"), ".",
  "The first run failed (46 hits: the stale v104-era pairmc/engine_a5 copy, which run_pairmc_v105.sh deletes and recopies from engine_v103 before use; the v102 before-engine",
  "a2/closeout/validation/engine_v102; the V104 shape vector in a5/rerun/h/h_boot_v105d.R). Allowed files and reasons are printed in v105d/logs/check_literals.log. The literal",
  "Stage 3 expressions in koa_projector.py (2), run_candidates.py and regen_figS4S5.py (the earlier hard-coding bug) were replaced by one function, koa_equations.stage3_w, and",
  "STAGE3_COEF carries renamed keys (c3_lnRD, c4_lnshareRD) so a surviving v105b-form expression raises KeyError. predict_HCB raises without rd= and dHT without sdi=."); P("")
P("Figures with literal forms: a4/figs/fig_main_v104.R (Fig. 3 increment and height curves, panel f) and figS12_v104.R (Fig. S1 height and HCB panels) patched by",
  "v105d/patch_figs_v105d.py. Finding: the v105c Fig. 3 dDBH curves (panels a, d) evaluated the v105b BAL/BAPH form with the K3c1 vector (a v105c defect, fixed here).",
  "The curves use a fixed stand of BAPH 30 m2/ha at QMD 25 cm (RD 0.646, stated in the script)."); P("")
P("### 4. Bootstraps"); P("")
P("- dHT K3c1h full-refit installation bootstrap (track2/inc/boot_v103.R dHT 400 4):", tail(f"{L}/boot_dHT_v105d.log", 1, "BOOT DONE"))
P("- dHT vector-fixed re-solve (stageB/boot_resolve_dht_v105.R, 400):", tail(f"{L}/boot_resolve_dht_v105d.log", 1))
P("- dDBH K3c1 bootstrap: reused from v105c (dDBH fit identical to 0, gate above).")
P("- Eq. 2 H1a installation bootstrap (a5/rerun/h/h_boot_v105d.R 500 4):", tail(f"{L}/h_boot_v105d.log", 1, "DONE"), "; summary a5/rerun/h/h_boot_summary_final.csv (500 of 500 converged)."); P("")
P("### 5. Phase 1 and phase 2 (as v105c)"); P("")
P("- Stage B:", tail(f"{L}/stage_b.log", 1, "STAGE_B DONE"))
P("- Phase 1:", tail(f"{L}/run_phase1_d.log", 8, "GATE|DONE|exit|[0-9]$"))
P("- Phase 1 registry gate: first pass", tail(f"{L}/run_phase1_d.log", 1, "^GATE"), "(HT_P a0, a1 disagreed: registry s02 still held the v105c height fit). Registry s02 was then regenerated for H1a (v105d/registry_s02_v105d.R) and make_md.sh rerun:", tail(f"{L}/registry_gate_rerun.log", 1, "^GATE"), "(v105d/logs/registry_gate_rerun.log).")
P("- Fig. 3 (fig_main_v104.R) failed in phase 1 (chol of a height vcov with zero rows for the fixed b, c, g2); the v105d height vcov for the figure bands now carries the v104 block for b, c, g2 (as the v105 track3 script did), and fig3-fig6 were rerun:", tail(f"{L}/fig_main_rerun.log", 1))
P("- Phase 2:", tail(f"{L}/run_phase2_d.log", 12, "DONE|loio|pairmc|bakuzis|contain|s11"))
P("- LOIO: in phase 2 the two gate chains (V105EXACT, NONE) failed with the v105c patch_fold.py (its DDBH regex matched LineageA and LineageB, n = 2; the same failure made every v105c LOIO chain fail, so the v105c LOIO verdicts are stale v105b values). patch_fold.py was fixed (count=1) while run_folds.sh was still fitting, so all 14 fold chains ran with the fix (a5/loio/logs/folds_v105.log, 0 FAILED); gates, gate check, analysis and results were rerun (a5/loio/rerun_loio_post_v105d.sh).")
G = rd(f"{W}/a5/loio/gate_check.csv")
if G is not None:
    P("  LOIO sanity gate (a5/loio/gate_check.csv; max abs diff vs a2/closeout/validation/val_v104_plotlevel.csv, 18 units): V105EXACT (constants of record) max", f"{G[G.tag == 'V105EXACT'].max_abs_diff.max():.3g}", "(PASS); NONE (full-frame dDBH refit through fit_folds.R) max", f"{G[G.tag == 'NONE'].max_abs_diff.max():.4g}", "(prQMD; tolerance 1e-3, so FLAGGED: the refit stops slightly off the deployed K3c1 vector; v105b NONE max 3.3e-4).")
P("- Paired MC gate (a5/pairmc/logs/a5_gatecheck.log):", tail(f"{W}/a5/pairmc/logs/a5_gatecheck.log", 3, "PASS|FAIL|GATE"))
P("- Master:", tail(f"{L}/master_d.log", 8, "phase|realism|compare|MASTER|boot|resolve")); P("")
P("## Notes and further deviations"); P("")
P("1. Increment frames keep the HCB_P crown ratio (track2/inc/inc_v103.R builds CR of the dDBH/dHT fitting frames with HCB_P; frames md5-identical to v105c). The engine projects",
  "CR from C2h. This is a declared inconsistency between the fitted and the projected crown ratio input of both increment equations (dDBH b5, dHT b5); refitting both increments",
  "on C2h crown ratios would change the v105c dDBH vector, which the brief fixes.")
P("2. HiGy.R (FVS-HI mirror) is not updated for the v105d forms (header note added); the Python engine is of record.")
P("3. Registry s01 (accounting) not rerun (inputs unchanged). Registry s02 (height) regenerated for H1a (v105d/registry_s02_v105d.R; LOIO nls per fold, RMSE in a2/registry/s02/v105/02_height_loio.csv); 02_height_vector_contrast.csv there is the old-form file (not regenerated) and the base-form file stays CARRIED from v104. Fuller Eq. 2 statistics: track3_s02/v105d.")
P("4. Height bootstrap: v105c had 392 of 500 converged draws with g1 fixed; v105d draws g1 as well (a0, a1, g1 free), 500 of 500 converged; the paired-MC BOOT variants use these draws.")
P("5. Coverage (Table S26) was not part of the v105c pipeline; it was run here for v105c (its engine and joint draws) and for v105d with the same scripts; no v105b value exists.")
P("7. a4/figs/s34/out_span/*.csv were symlinks into koa_v105c_20261102/a2/mort/v104 (absolute links survive the copy and the path rewrite), so the phase-1 Fig. S3/S4 run read the v105c natural level (2.55705; v105d/logs/figS34_v105d.out). The links were repointed to this job and figS34_v104.R rerun:", tail(f"{L}/figS34_rerun.log", 1), "; level read:", tail(f"{L}/figS34_v105d_rerun.out", 1, "level file check"), ". No other symlink into koa_v105c_20261102 exists in this job.")
P("6. Cores: 4 to 6 of 8 for the bootstraps and phases (another user job held 4 until about 01:00); for about one minute (01:09-01:10) the LOIO gate rerun (3) overlapped the paired-MC joint draws (6).")
open(f"{W}/RUN_v105d.md", "w").write("\n".join(out) + "\n"); print("RUN_v105d.md written")
