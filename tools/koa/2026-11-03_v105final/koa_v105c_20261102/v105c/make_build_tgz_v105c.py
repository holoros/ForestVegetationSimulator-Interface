#!/usr/bin/env python3
"""v105c/make_build_tgz_v105c.py (copy of repair_v105b/make_build_tgz_v105b.py for v105c; same tarball name, layout and manifest; freshness cut = v105c Stage B start
(env KOA_T0, epoch seconds; files were copied from the v105 job with their mtimes, so a v105b file is never counted as regenerated). Original: repair_v105b/make_build_tgz_v105b.py: files reused unchanged from v105 because their inputs are md5 identical are listed in REUSED and included with that status).
Original: make_build_tgz.py: v105_build_inputs.tgz with the relative paths of the v104 a5_build_inputs.tgz (report/v104_build_list.txt), taken from this job, plus the
v105-specific files. A listed file that was NOT regenerated in v105 (mtime before the v105 job start, 2026-11-02 11:30 AST) is left out of the tarball and named in
report/v105_build_manifest.csv, so no v104 value travels under a v105 label."""
import os, tarfile, time, csv, hashlib, datetime
W = os.path.expanduser("~/jobs/koa_v105c_20261102"); os.chdir(W)
T0 = float(os.environ["KOA_T0"])
L = [l.strip() for l in open("report/v104_build_list.txt") if l.strip()]
EXTRA = ["out/v105_constants.json", "stageA/PREREG_A.md", "stageA/RESULTS_A.md", "stageA/out/stageA_table.csv", "stageA/out/stageA_verdict.csv",
         "stageB/PREREG_B.md", "stageB/out/levels_v105.csv", "stageB/out/c2p0_repro_growthplots.csv", "stageB/out/substitution_md5.tsv", "stageB/out/gate_G1.csv",
         "track2/out/height_coefficients.csv", "track2/out/height_stats.csv", "track2/out/surv_coefficients.csv", "track2/out/surv_stats.csv",
         "a5/rerun/h/h_boot_summary_final.csv", "a5/rerun/s11/tableS11_within_source_v104.csv", "a5/rerun/qr/containment_v104.csv",
         "a4/bakuzis/bakuzis_checks_v104_v105.csv", "a4/bakuzis/bakuzis_compare_v104_v105.csv", "a4/bakuzis/bakuzis_counts_v104_v105.csv", "a4/bakuzis/koa_v105_vs_v104_bakuzis_matrix.png",
         "a4/bakuzis/observed_envelope_v105.csv", "a5/pairmc/byi_v105/byi_blocked_resid_summary.csv", "a5/pairmc/byi_v105/gate_blocked_cv.csv",
         "out/inc/boot_v103_dHT_summary.csv", "out/inc/boot_v103_dDBH_summary.csv", "a2/registry/numbers_v105.json", "a2/registry/build/gate_v104.csv",
         "report/compare_v104_v105.csv", "report/compare_v104_v105.md", "RUN_v105.md", "RESULTS_v105.md",
         "repair_v105b/PREREG_C.md", "repair_v105b/PREREG_C_written_at.txt", "repair_v105b/out/impute_fit.csv", "repair_v105b/out/impute_counts_by_source.csv",
         "repair_v105b/out/imputed_value_ranges.csv", "repair_v105b/out/substitution_md5_v105b.tsv", "repair_v105b/out/height_full_attempt/height_coefficients.csv",
         "repair_v105b/out/height_full_attempt/height_stats.csv", "repair_v105b/out/compare/compare_v104_v105_v105b.csv", "repair_v105b/out/compare/compare_v104_v105_v105b.md",
         "repair_v105b/out/raster_search_summary.csv", "RUN_v105c.md", "RESULTS_v105c.md", "v105c/out/gate_k3c1_fit.csv", "v105c/out/parity_frames.csv",
         "v105c/out/parity_engine.csv", "v105c/out/compare_v105b_v105c.csv", "v105c/out/compare_v105b_v105c.md", "v105c/out/bakuzis_flags_v105b_v105c.csv", "v105c/out/realism_summary.csv"]
REUSED = ["out/inc/boot_v103_dHT_summary.csv", "out/inc/boot_v103_dHT.csv", "stageA/PREREG_A.md", "stageA/RESULTS_A.md", "stageA/out/stageA_table.csv", "stageA/out/stageA_verdict.csv",
          "stageB/PREREG_B.md", "stageB/out/levels_v105.csv", "stageB/out/c2p0_repro_growthplots.csv", "stageB/out/substitution_md5.tsv", "stageB/out/gate_G1.csv",
          "a4/sens/years_grid_v104.py", "a4/sens/sens_v104.py", "a4/bakuzis/sc_summary_v104.csv", "a4/bakuzis/bakuzis_v104_vs_v103.R", "a4/figs/FigS4_survival_deployability.tiff",
          "a4/figs/FigS3_survival_recovery.png", "a4/figs/FigS4_survival_deployability.png", "a4/figs/FigS3_survival_recovery.tiff", "a4/figs/figS_v104.R", "a4/figs/fig_main_v104.R",
          "a5/stage3fix/run_a5.sh", "a5/pairmc/byi_v105/byi_blocked_resid_summary.csv", "a5/pairmc/byi_v105/gate_blocked_cv.csv", "out/inc/boot_v103_dHT.csv", "a5/rerun/h/h_boot_summary_final.csv", "track2/out/height_coefficients.csv", "track2/out/height_stats.csv",
          "track2/out/surv_coefficients.csv", "track2/out/surv_stats.csv", "RUN_v105.md", "RESULTS_v105.md", "repair_v105b/PREREG_C.md", "repair_v105b/PREREG_C_written_at.txt",
          "repair_v105b/out/impute_fit.csv", "repair_v105b/out/impute_counts_by_source.csv", "repair_v105b/out/imputed_value_ranges.csv", "repair_v105b/out/substitution_md5_v105b.tsv",
          "repair_v105b/out/height_full_attempt/height_coefficients.csv", "repair_v105b/out/height_full_attempt/height_stats.csv", "repair_v105b/out/raster_search_summary.csv"]   # v105c: dHT, height, survival, imputation and v105b records are unchanged inputs   # scripts and survival-only figure copies included in v105, not affected by the repair
rows = []; keep = []
for p in L + [e for e in EXTRA if e not in L]:
    if not os.path.isfile(p): rows.append(dict(path=p, status="missing in v105c job", md5="")); continue
    fresh = os.path.getmtime(p) >= T0
    if fresh: keep.append(p); rows.append(dict(path=p, status="included (v105c)", md5=hashlib.md5(open(p, "rb").read()).hexdigest()))
    elif p in REUSED: keep.append(p); rows.append(dict(path=p, status="included (v105b file reused unchanged in v105c: not affected by the dDBH form)", md5=hashlib.md5(open(p, "rb").read()).hexdigest()))
    elif p in EXTRA: keep.append(p); rows.append(dict(path=p, status="included (not regenerated in v105c; check)", md5=hashlib.md5(open(p, "rb").read()).hexdigest()))
    else: rows.append(dict(path=p, status="NOT regenerated in v105c, left out", md5=""))
with tarfile.open("v105_build_inputs.tgz", "w:gz") as tf:
    for p in keep: tf.add(p)
with open("report/v105_build_manifest.csv", "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["path", "status", "md5"]); w.writeheader(); w.writerows(rows)
from collections import Counter; print(Counter(r["status"] for r in rows))
