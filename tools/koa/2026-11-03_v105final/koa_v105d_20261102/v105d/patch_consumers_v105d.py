#!/usr/bin/env python3
"""patch_consumers_v105d.py (after deploy): consumers that carry the replaced fits outside the engine.
- a4/joint_draws_v104.R, a5/pairmc/joint_draws_pairmc.R: dHT K3c1h has 9 fixed effects; vcov padded with a zero b3 row/column and every drawn b3 set to 0 (as v105c did for dDBH).
- track2/out/height_coefficients.csv (frame "v103" rows) and track2/height/height_vcov_v103.csv: the deployed Eq. 2 vector and vcov the joint draws read -> H1a
  (a0, a1, g1 with their nlme vcov; b, c, g2 fixed at v104, zero variance). The joint draws gate the mean against out/v105_constants.json HT_P.
Backups *_PREV_20261102d."""
import os, csv, subprocess
W = os.path.expanduser("~/jobs/koa_v105d_20261102")
def backup(*ps): subprocess.run(["bash", f"{W}/v105d/backup_d.sh", *ps], check=True)
PAD = ('if (!("b3" %in% colnames(VV$dHT))) { v9 <- VV$dHT; nm <- names(B0$dHT); V10 <- matrix(0, length(nm), length(nm), dimnames = list(nm, nm)); V10[colnames(v9), colnames(v9)] <- v9; VV$dHT <- V10 }   # v105d: K3c1h has b3 fixed at 0')
for f in ("a4/joint_draws_v104.R", "a5/pairmc/joint_draws_pairmc.R"):
    p = f"{W}/{f}"; backup(p); t = open(p).read()
    old = "   # v105c: K3c1 has b3 fixed at 0\n"; assert t.count(old) == 1, f; t = t.replace(old, old + PAD + "\n")
    old = '  if (all(VV$dDBH["b3", ] == 0)) bd[, "b3"] <- 0   # v105c: b3 fixed at 0 (K3c1)'; assert t.count(old) == 1, f
    t = t.replace(old, old + '\n  if (all(VV$dHT["b3", ] == 0)) bh[, "b3"] <- 0   # v105d: b3 fixed at 0 (K3c1h)'); open(p, "w").write(t); print("patched", f)
H = list(csv.DictReader(open(f"{W}/prep/out/height_coefficients_H1a.csv")))
p = f"{W}/track2/out/height_coefficients.csv"; backup(p); R = list(csv.DictReader(open(p))); fn = list(R[0].keys())
est = {r["parameter"]: r for r in H}; out = []
for r in R:
    if r["frame"] == "v103":
        h = est[r["parameter"]]; r = dict(r, estimate=h["estimate"], se=h["se"], fixed_at_v104=h["fixed"].upper())
    out.append(r)
with open(p, "w", newline="") as fh: w = csv.DictWriter(fh, fieldnames=fn, quoting=csv.QUOTE_NONNUMERIC); w.writeheader(); w.writerows(out)
p = f"{W}/track2/height/height_vcov_v103.csv"; backup(p); open(p, "w").write(open(f"{W}/prep/out/height_vcov_H1a.csv").read())
print("height coefficients (frame v103 rows) and vcov -> H1a")
