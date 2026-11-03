#!/usr/bin/env python3
"""patch_consumers_v105c.py: consumers of the dDBH fit that need the K3c1 form explicitly (everything that sources the inc_v103.R machinery
inherits the K3c1 switch and the b3 = 0 fixef padding without edits).
- a4/joint_draws_v104.R, a5/pairmc/joint_draws_pairmc.R: the K3c1 fit has 9 fixed effects; its vcov is padded with a zero row/column for b3 and every
  drawn b3 is set to exactly 0 (b3 is fixed, not estimated).
- a4/sens/sens_v104.py (open-grown tree, BAPH 0): sdi = 0 passed (RD 0, x 0; same no-competition meaning as BAL 0, BAPH 0).
- a4/sens/years_grid_v104.py: sdi passed; BAPH 0 -> SDI 0; BAPH 10 -> SDI of a stand with that BAPH at QMD = the target initial QMD (stated assumption,
  K3c1 needs an SDI the v104 grid does not define); the SDI used is written to the output."""
import os, subprocess
W = os.path.expanduser("~/jobs/koa_v105c_20261102")
def backup(*ps): subprocess.run(["bash", f"{W}/v105c/backup_c.sh", *ps], check=True)
PAD = ('B0 <- list(dDBH = fixef(mD), dHT = fixef(mH)); VV <- list(dDBH = vcov(mD), dHT = vcov(mH))\n'
       'if (!("b3" %in% colnames(VV$dDBH))) { v9 <- VV$dDBH; nm <- names(B0$dDBH); V10 <- matrix(0, length(nm), length(nm), dimnames = list(nm, nm)); V10[colnames(v9), colnames(v9)] <- v9; VV$dDBH <- V10 }   # v105c: K3c1 has b3 fixed at 0')
for f in ("a4/joint_draws_v104.R", "a5/pairmc/joint_draws_pairmc.R"):
    p = f"{W}/{f}"; backup(p); t = open(p).read()
    old = 'B0 <- list(dDBH = fixef(mD), dHT = fixef(mH)); VV <- list(dDBH = vcov(mD), dHT = vcov(mH))'; assert t.count(old) == 1, f; t = t.replace(old, PAD)
    old = '  bd <- mvrnorm(4, B0$dDBH, VV$dDBH); bh <- mvrnorm(4, B0$dHT, VV$dHT)'; assert t.count(old) == 1, f
    t = t.replace(old, old + '\n  if (all(VV$dDBH["b3", ] == 0)) bd[, "b3"] <- 0   # v105c: b3 fixed at 0 (K3c1)'); open(p, "w").write(t); print("patched", f)
p = f"{W}/a4/sens/sens_v104.py"; backup(p); t = open(p).read()
old = "KE.LineageA.dDBH(np.array([dbh]), 0.0, np.array([0.0]), np.array([0.9]), byi, planted)[0]"; assert t.count(old) == 1
t = t.replace(old, "KE.LineageA.dDBH(np.array([dbh]), 0.0, np.array([0.0]), np.array([0.9]), byi, planted, sdi=0.0)[0]"); open(p, "w").write(t); print("patched sens")
p = f"{W}/a4/sens/years_grid_v104.py"; backup(p); t = open(p).read()
old = "                    dbh=2.5; n=0\n"; assert t.count(old) == 1
t = t.replace(old, "                    dbh=2.5; n=0; sdi=0.0 if baph<=0 else float((baph/(0.00007854*target**2))*(target/KP.INDEX_DIAMETER_CM)**KP.SDI_OF_EXPONENT)   # v105c: SDI at QMD = target\n")
old = "KE.LineageA.dDBH(np.array([dbh]),baph,np.array([bal]),np.array([cr]),byi,planted)[0]"; assert t.count(old) == 1
t = t.replace(old, "KE.LineageA.dDBH(np.array([dbh]),baph,np.array([bal]),np.array([cr]),byi,planted,sdi=sdi)[0]")
old = "rows.append(dict(origin='planted' if planted else 'natural',target_cm=target,byi=byi,cr=cr,bal=bal,baph=baph,years=n))"; assert t.count(old) == 1
t = t.replace(old, "rows.append(dict(origin='planted' if planted else 'natural',target_cm=target,byi=byi,cr=cr,bal=bal,baph=baph,sdi_engine=sdi,years=n))"); open(p, "w").write(t); print("patched years_grid")
