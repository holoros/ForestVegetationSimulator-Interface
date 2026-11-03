## set_dec_v105c.R: the deployed dDBH fit is dDBH_L_NO in the K3c1 form, adopted under koa_rdcomp_20261102/constrained/PREREG_K3c.md, whatever the v103
## candidate-selection rule of inc_v103.R now returns (its outcome is kept in the reasons column and in selection_v103.csv). dHT is left as selected.
VC <- path.expand("~/jobs/koa_v105c_20261102"); f <- file.path(VC, "out/inc/fits_v103.rda"); load(f)
old <- DEC$deployed[DEC$resp == "dDBH"]; i <- which(DEC$resp == "dDBH")
DEC$reasons[i] <- paste0("v103 selection rule returned ", old, " (", DEC$rule[i], ": ", DEC$reasons[i], ")")
DEC$deployed[i] <- "dDBH_L_NO"; DEC$rule[i] <- "v105c: K3c1 dDBH form adopted (koa_rdcomp_20261102/constrained/PREREG_K3c.md); dDBH_L_NO deployed"
save(FITS, CAL, DEC, file = f); write.csv(DEC, file.path(VC, "out/inc/decision_v103.csv"), row.names = FALSE); print(DEC)
