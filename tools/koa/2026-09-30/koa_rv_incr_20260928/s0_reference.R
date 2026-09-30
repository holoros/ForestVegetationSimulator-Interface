## s0_reference.R. Gate: reproduce the v102 vector of record for dDBH and dHT from the deployed start with the track2 fit path,
## compare with inc_fits.rda, and reproduce the engine multipliers (0.40548, 1.43606, 0.51917, 2.64739).
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
REF <- load_ref()
DEP <- list(dDBH = c(b0 = -2.0972488, b1 = 0.3105931, b2 = -0.0085285, b3 = -0.0019684, b4 = -0.2899832, b5 = -0.2599003, b6 = -0.0105114, b7 = -0.0258191, b8 = 0.3108402, b9 = 0.4018344),
            dHT = c(b0 = -4.0426171, b1 = 0.9238575, b2 = -0.1099897, b3 = -0.0012181, b4 = -0.0358816, b5 = -1.5423408, b6 = 0.0486628, b7 = -0.1196098, b8 = 0.2471449, b9 = 1.0236256))
out <- list()
for (resp in c("dDBH", "dHT")) {
  d <- prep(resp); t0 <- Sys.time()
  m <- fit_ref(resp, d, DEP[[resp]])
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  md <- max(abs(fixef(m) - fixef(REF[[resp]])))
  km <- kmult(d, fitted(m, level = 0), resp)
  logm(resp, "n", nrow(d), "refit s", round(el), "logLik", round(as.numeric(logLik(m)), 3), "max|dfixef| vs inc_fits.rda", signif(md, 3),
       "k", round(km$k, 5), "CI", round(km$lo, 3), round(km$hi, 3), "R2 cond", round(r2(d[[resp]], fitted(m)), 4), "R2 pa cal", round(km$r2_cal, 4))
  out[[resp]] <- data.frame(resp = resp, n = nrow(d), secs = el, logLik = as.numeric(logLik(m)), max_abs_diff_fixef = md,
    k_nat = km$k[["natural"]], k_pl = km$k[["planted"]], r2_cond = r2(d[[resp]], fitted(m)), r2_pa_cal = km$r2_cal)
}
print(do.call(rbind, out)); write.csv(do.call(rbind, out), file.path(OUT, "s0_reference_gate.csv"), row.names = FALSE)
logm("S0 DONE")
