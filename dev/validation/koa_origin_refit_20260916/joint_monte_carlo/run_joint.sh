#!/usr/bin/env bash
# run_joint.sh (2026-09-16, v99): engine_joint = engine_mort2 + joint, source-level Monte Carlo rows. Point projections
# must match engine_mort2 exactly; only the intervals change. Revised after red team: Stage 1 acceptance, mortality factor
# rescaling, 500 rows, overflow and state checks. Reference for before/after = engine_mort2 (v98).
set -u
cd "$(dirname "$0")"; J=$PWD; O=$J/output/joint; mkdir -p "$O"
RT=$HOME/jobs/koa_redteam_20260916
log() { echo "$*" >> "$O/run.log"; }
log "== joint $(date)"
Rscript joint_draws.R > runK_joint.log 2>&1 || { log "FAILED: joint_draws.R"; log "JOINT DONE"; exit 1; }
log "draws done $(date)"
rm -rf output/engine_joint
mkdir -p output/engine_joint && (cd output/engine_mort2 && tar cf - --exclude=out_m1 --exclude='out_proto_*' --exclude=__pycache__ --exclude=.mpl --exclude=figS45.log --exclude="driver.*" --exclude=s45.log .) | (cd output/engine_joint && tar xf -) && mkdir -p output/engine_joint/out_m1
python3 patch_jointmc.py output/engine_joint . > "$O/patch_joint.log" 2>&1 || { log "FAILED: patch_jointmc"; log "JOINT DONE"; exit 1; }
python3 joint_diag.py output/engine_joint "$O/K_reference_spread.csv" > "$O/joint_diag.log" 2>&1 || log "FAILED: joint_diag"
cd "$J/output/engine_joint"
MPLCONFIGDIR=$PWD/.mpl python3 regen_m1.py > driver.log 2>&1 && python3 "$RT/patch/make_traj.py" . >> driver.log 2>&1; echo $? > driver.exit
log "driver exit $(cat driver.exit) $(date)"
(MPLCONFIGDIR=$PWD/.mpl python3 regen_figS4S5.py > figS45.log 2>&1; echo "figS45 exit $?" >> "$O/run.log") &
python3 "$J/clip_shares.py" out_m1 "$O/J_clip_ceiling_shares.csv" >> "$O/run.log" 2>&1
python3 - "$J/output/engine_mort2/out_m1" "$J/output/engine_joint/out_m1" "$O" >> "$O/run.log" 2>&1 <<'PY'
import sys, pandas as pd, numpy as np
a, b, o = sys.argv[1:4]
out = []
for f in ("table8_evenaged_M1.csv", "uneven_aged_table8_M1.csv"):
    A = pd.read_csv(f"{a}/{f}"); B = pd.read_csv(f"{b}/{f}")
    pts = [c for c in A.columns if c + "_lo" in A.columns]
    d = max((float(np.nanmax(np.abs(A[c].to_numpy(float) - B[c].to_numpy(float)))) for c in pts), default=float("nan"))
    print(f, "POINT GATE max abs diff", d, "PASS" if d == 0 else "FAIL")
    for c in pts:
        wa = A[c + "_hi"] - A[c + "_lo"]; wb = B[c + "_hi"] - B[c + "_lo"]
        t = A.iloc[:, :3].copy(); t["var"] = c; t["point"] = A[c]; t["lo_v98"] = A[c + "_lo"]; t["hi_v98"] = A[c + "_hi"]
        t["lo_joint"] = B[c + "_lo"]; t["hi_joint"] = B[c + "_hi"]; t["width_ratio"] = wb / wa.replace(0, np.nan); t["file"] = f
        out.append(t)
W = pd.concat(out); W.to_csv(f"{o}/K_interval_widths.csv", index=False)
print(W.groupby(["file", "var"]).width_ratio.describe())
PY
export KOA_OUT="$O" KOA_CAP_PLANTED=69.7 KOA_NBOOT=5000
export KOA_TRAJ_REF="$J/output/engine_mort2/out_m1/trajectories.csv"
export KOA_TRAJ="$J/output/engine_joint/out_m1/trajectories.csv" KOA_VALID="$J/output/engine_joint/out_m1/validation_23.csv"
cd "$RT"
for s in 05_trajectory_metrics 07_validation_equivalence; do
  log "== $s $(date)"; Rscript "$s.R" >> "$O/run.log" 2>&1 || log "STAGE FAILED: $s"
done
bash "$J/run_valid_origin.sh" "$J/output/engine_joint/out_m1" "$J/output/valid_origin_joint" >> "$O/run.log" 2>&1
wait
cd "$J" && gzip -kf output/engine_joint/out_m1/trajectories.csv && tar czf output/joint/bundle_joint.tgz --exclude='reps_*' --exclude='uneven_aged_reps*' \
  --exclude='output/engine_joint/out_m1/trajectories.csv' output/joint/*.csv output/joint/*.log output/engine_joint/out_m1 output/engine_joint/out_joint \
  output/engine_joint/koa_params.py output/engine_joint/koa_equations.py output/engine_joint/threestage.py output/engine_joint/regen_m1.py \
  output/engine_joint/PATCH_REPORT_JOINT.md output/engine_joint/driver.log output/engine_joint/figS45.log \
  output/valid_origin_joint joint_draws.R patch_jointmc.py clip_shares.py joint_diag.py run_joint.sh runK_joint.log 2>> "$O/run.log"
log "JOINT DONE $(date)"
