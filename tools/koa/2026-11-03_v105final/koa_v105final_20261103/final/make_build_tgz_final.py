#!/usr/bin/env python3
"""final/make_build_tgz_final.py: copy of v105d/make_build_tgz_v105d.py for v105final (tarball v105final_build_inputs.tgz, manifest report/v105final_build_manifest.csv).
Freshness cut T0 = 2026-11-03 06:31:00 AST (KOA_T0 overrides). Original docstring follows."""
"""v105d/make_build_tgz_v105d.py (copy of v105c/make_build_tgz_v105c.py for v105d; tarball v105final_build_inputs.tgz, manifest report/v105final_build_manifest.csv; freshness cut = v105d Stage B start
(env KOA_T0, epoch seconds; files were copied from the v105 job with their mtimes, so a v105b file is never counted as regenerated). Original: repair_v105b/make_build_tgz_v105b.py: files reused unchanged from v105 because their inputs are md5 identical are listed in REUSED and included with that status).
Original: make_build_tgz.py: v105_build_inputs.tgz with the relative paths of the v104 a5_build_inputs.tgz (report/v104_build_list.txt), taken from this job, plus the
v105-specific files. A listed file that was NOT regenerated in v105 (mtime before the v105 job start, 2026-11-02 11:30 AST) is left out of the tarball and named in
report/v105_build_manifest.csv, so no v104 value travels under a v105 label."""
import os, tarfile, time, csv, hashlib, datetime
W = os.path.expanduser("~/jobs/koa_v105final_20261103"); os.chdir(W)
T0 = float(os.environ.get("KOA_T0", "1793701860"))   # default 2026-11-03 06:31:00 AST: start of the koa_v105attr_20261103 refits whose outputs this job carries
L = [l.strip() for l in open("report/v104_build_list.txt") if l.strip()]
EXTRA = ["out/v105_constants.json", "track2/out/height_coefficients.csv", "track2/out/height_stats.csv", "track2/out/surv_coefficients.csv", "track2/out/surv_stats.csv",
         "track2/height/height_vcov_v103.csv", "track3_s02/v105/02_height_fit.rds", "track3_s02/v105/02_height_coefficients.csv", "track3_s02/v105/02_height_equivalence.csv",
         "a5/rerun/h/h_boot_summary_final.csv", "a5/rerun/h/h_boot_final.csv", "a5/rerun/h/h_ref_final.csv", "a5/rerun/s11/tableS11_within_source_v104.csv", "a5/rerun/qr/containment_v104.csv",
         "a5/rerun/cov/tableS26_coverage_v104.csv", "a5/rerun/cov/tableS26_unit_intervals_anon_v104.csv",
         "a4/bakuzis/bakuzis_checks_v104_v105.csv", "a4/bakuzis/bakuzis_compare_v104_v105.csv", "a4/bakuzis/bakuzis_counts_v104_v105.csv", "a4/bakuzis/koa_v105_vs_v104_bakuzis_matrix.png",
         "a4/bakuzis/observed_envelope_v105.csv", "a4/culmination_mc_v104.json", "a5/loio/loio_metrics.csv", "a5/loio/gate_check.csv", "a5/loio/loio_folds.csv", "a5/loio/RESULTS.md",
         "a5/pairmc/out_a5/prob_ordering.csv", "out/inc/boot_v103_dHT_summary.csv", "out/inc/boot_v103_dDBH_summary.csv", "out/inc/boot_v103_dDBH.csv", "out/inc/boot_v103_dHT.csv",
         "out/inc/boot_v103_dDBH_L_NO.csv", "out/inc/boot_v103_dDBH_L_NO_summary.csv", "out/inc/boot_v103_dHT_resolveonly.csv", "out/inc/coefficients_v103.csv", "out/inc/fit_stats_v103.csv",
         "a2/registry/numbers_v105.json", "a2/registry/build/gate_v104.csv", "a2/mort/v104/H_mort_level_natural.csv", "a2/mort/v104/H_mort_boot_natural.csv",
         "v105d/out/realism_v105final.csv", "final/out/compare_final_long.csv", "final/out/compare_final_wide.csv", "final/out/compare_final.md", "final/attr/sdimax_pop.csv",
         "final/attr/height_coefficients_H1a_742.csv", "final/attr/hcb_coefficients_C2h_742.csv", "final/attr/stage3_coefficients_M3a_742.csv", "final/attr/rd_min_fitframes_742.csv",
         "final/attr/metrics_long.csv", "final/attr/attribution.csv", "final/attr/eichhorn_exact.csv", "logs/check_literals.log",
         "FINAL_ENGINE.md", "RUN.md", "RESULTS.md", "engine_v103/koa_params.py", "engine_v103/koa_equations.py", "engine_v103/koa_projector.py", "engine_v103/run_candidates.py",
         "engine_v103/regen_figS4S5.py", "track2/inc/inc_v103.R"]
REUSED = ["track2/out/height_coefficients.csv", "track2/out/height_stats.csv", "track2/height/height_vcov_v103.csv", "track3_s02/v105/02_height_fit.rds",
          "track3_s02/v105/02_height_coefficients.csv", "track3_s02/v105/02_height_equivalence.csv", "a5/rerun/h/h_boot_summary_final.csv", "a5/rerun/h/h_boot_final.csv",
          "a5/rerun/h/h_ref_final.csv", "track2/out/surv_coefficients.csv", "track2/out/surv_stats.csv", "a4/figs/FigS4_survival_deployability.tiff", "a4/figs/FigS3_survival_recovery.png",
          "a4/figs/FigS4_survival_deployability.png", "a4/figs/FigS3_survival_recovery.tiff", "a4/sens/years_grid_v104.py", "a4/sens/sens_v104.py", "a4/figs/figS_v104.R"]   # v105final: Eq. 2 and Eq. 3 at the v105c form (v105c height fit, vcov, bootstrap draws; frames unchanged)
rows = []; keep = []
for p in L + [e for e in EXTRA if e not in L]:
    if not os.path.isfile(p): rows.append(dict(path=p, status="missing in v105final job", md5="")); continue
    fresh = os.path.getmtime(p) >= T0
    if fresh: keep.append(p); rows.append(dict(path=p, status="included (regenerated for v105final, attribution or final chain)", md5=hashlib.md5(open(p, "rb").read()).hexdigest()))
    elif p in REUSED: keep.append(p); rows.append(dict(path=p, status="included (reused unchanged: v105c Eq. 2 / survival inputs, not affected by the v105final forms)", md5=hashlib.md5(open(p, "rb").read()).hexdigest()))
    elif p in EXTRA: keep.append(p); rows.append(dict(path=p, status="included (not regenerated since 2026-11-03 06:31; check)", md5=hashlib.md5(open(p, "rb").read()).hexdigest()))
    else: rows.append(dict(path=p, status="NOT regenerated for v105final, left out", md5=""))
with tarfile.open("v105final_build_inputs.tgz", "w:gz") as tf:
    for p in keep: tf.add(p)
with open("report/v105final_build_manifest.csv", "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["path", "status", "md5"]); w.writeheader(); w.writerows(rows)
from collections import Counter; print(Counter(r["status"] for r in rows))
