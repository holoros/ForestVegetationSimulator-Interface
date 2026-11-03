## gate_v105d_fit.R: after inc_v103.R all (KOA_DDBH_FORM K3c1, KOA_DHT_FORM K3c1h): dDBH_L_NO = v105c (K3c1) exactly; dHT_L_NO = the independent
## K3c1h reference fit (prep/fit_dht_k3c1.R, koa_rdcomp lib); dHT b3 = 0; signs and monotonicity (d ln g/dx = b4/(x+1) <= 0 iff b4 <= 0); frames md5 = v105c.
suppressPackageStartupMessages(library(nlme)); VD <- path.expand("~/jobs/koa_v105d_20261102"); VC <- path.expand("~/jobs/koa_v105c_20261102")
e <- new.env(); load(file.path(VD, "out/inc/fits_v103.rda"), e); R <- readRDS(file.path(VD, "prep/out/fit_dHT_K3c1h_ref.rds"))
cc <- read.csv(file.path(VC, "out/inc/coefficients_v103.csv")); cd <- read.csv(file.path(VD, "out/inc/coefficients_v103.csv"))
sc <- read.csv(file.path(VC, "out/inc/fit_stats_v103.csv")); sd_ <- read.csv(file.path(VD, "out/inc/fit_stats_v103.csv"))
dD <- max(abs(cd$estimate[cd$fit == "dDBH_L_NO"] - cc$estimate[cc$fit == "dDBH_L_NO"]))
cols <- c("cf_source_inst", "c_natural", "c_planted", "cal_natural", "cal_planted"); dS <- max(abs(unlist(sd_[sd_$fit == "dDBH_L_NO", cols]) - unlist(sc[sc$fit == "dDBH_L_NO", cols])))
mH <- e$FITS[["dHT_L_NO"]]; b <- nlme::fixef(mH); rb <- R$b[names(b)]; se <- summary(mH)$tTable[names(b), 2]; dz <- max(abs(b - rb) / se); dl <- as.numeric(logLik(mH)) - R$logLik
b10 <- setNames(cd$estimate[cd$fit == "dHT_L_NO"], cd$term[cd$fit == "dHT_L_NO"])
md5 <- function(f) unname(tools::md5sum(f)); fr <- c("dDBH_NO", "dDBH_CS", "dHT_NO", "dHT_CS")
fm <- sapply(fr, function(x) md5(file.path(VD, sprintf("frames/final/%s_v103_model.csv", x))) == md5(file.path(VC, sprintf("frames/final/%s_v103_model.csv", x))))
G <- data.frame(check = c("dDBH_L_NO estimates vs v105c (max abs diff)", "dDBH_L_NO CF, c, CAL vs v105c (max abs diff)", "dHT_L_NO fixef vs reference K3c1h (max abs diff)",
                          "dHT_L_NO fixef vs reference, max diff in SE units", "dHT_L_NO logLik minus reference", "dHT_L_NO b3 row (estimate)", "dHT signs b1 > 0, b4 < 0",
                          "dHT monotone in x = share RD (b4 <= 0, analytic)", "model frames md5 identical to v105c (4 frames)"),
  value = c(dD, dS, max(abs(b - rb)), dz, dl, b10[["b3"]], as.numeric(b10[["b1"]] > 0 && b10[["b4"]] < 0), b10[["b4"]], sum(fm)))
ok <- G$value[3] < 1e-6 || (dz < 1e-3 && abs(dl) < 1e-3)
G$pass <- c(dD < 1e-12, dS < 1e-12, ok, ok, ok, G$value[6] == 0, G$value[7] == 1, G$value[8] <= 0, G$value[9] == 4)
print(G, digits = 6); write.csv(G, file.path(VD, "v105d/out/gate_v105d_fit.csv"), row.names = FALSE); print(sd_[sd_$fit %in% c("dDBH_L_NO", "dHT_L_NO"), ])
cat("GATE_V105D_FIT", if (all(G$pass)) "PASS" else "FAIL", "\n")
