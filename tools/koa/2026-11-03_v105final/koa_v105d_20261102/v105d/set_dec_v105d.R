## set_dec_v105d.R: deployed dDBH = dDBH_L_NO (K3c1, as v105c); deployed dHT = dHT_L_NO in the K3c1h form (v105d modeling choice), whatever the v103
## selection rule of inc_v103.R returns (its outcome is kept in the reasons column).
VD <- path.expand("~/jobs/koa_v105d_20261102"); f <- file.path(VD, "out/inc/fits_v103.rda"); load(f)
for (r in c("dDBH", "dHT")) { i <- which(DEC$resp == r); old <- DEC$deployed[i]
  DEC$reasons[i] <- paste0("v103 selection rule returned ", old, " (", DEC$rule[i], ": ", DEC$reasons[i], ")"); DEC$deployed[i] <- paste0(r, "_L_NO")
  DEC$rule[i] <- if (r == "dDBH") "v105c: K3c1 dDBH form adopted (PREREG_K3c); dDBH_L_NO deployed" else "v105d: K3c1h dHT form by modeling choice (declared deviation from koa_rdcomp_20261102 rule); dHT_L_NO deployed" }
save(FITS, CAL, DEC, file = f); write.csv(DEC, file.path(VD, "out/inc/decision_v103.csv"), row.names = FALSE); print(DEC)
