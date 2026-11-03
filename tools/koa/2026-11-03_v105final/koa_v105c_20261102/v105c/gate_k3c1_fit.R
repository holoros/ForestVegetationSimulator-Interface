## gate_k3c1_fit.R: after inc_v103.R all (K3c1): deployed dDBH_L_NO = screen K3c1 (koa_rdcomp_20261102/constrained/out/fit_K3c1.rds); dHT_L_NO = v105b.
suppressPackageStartupMessages(library(nlme)); VC <- path.expand("~/jobs/koa_v105c_20261102"); V5 <- path.expand("~/jobs/koa_v105_20261102")
e <- new.env(); load(file.path(VC, "out/inc/fits_v103.rda"), e); K <- readRDS(path.expand("~/jobs/koa_rdcomp_20261102/constrained/out/fit_K3c1.rds"))
b <- nlme::fixef(e$FITS[["dDBH_L_NO"]]); kb <- K$b[names(b)]
c5 <- read.csv(file.path(V5, "out/inc/coefficients_v103.csv")); cc <- read.csv(file.path(VC, "out/inc/coefficients_v103.csv"))
h5 <- c5[c5$fit == "dHT_L_NO", ]; hc <- cc[cc$fit == "dHT_L_NO", ]; s5 <- read.csv(file.path(V5, "out/inc/fit_stats_v103.csv")); sc <- read.csv(file.path(VC, "out/inc/fit_stats_v103.csv"))
G <- data.frame(check = c("dDBH_L_NO fixef vs screen K3c1 (max abs diff)", "dDBH_L_NO logLik minus screen", "dDBH_L_NO c natural, planted minus screen (max abs)",
                          "dDBH_L_NO b3 row (estimate, se)", "dHT_L_NO estimates vs v105b (max abs diff)", "dHT_L_NO fit stats (CF, c, CAL) vs v105b (max abs diff)"),
  value = c(max(abs(b - kb)), as.numeric(logLik(e$FITS[["dDBH_L_NO"]])) - K$logLik, max(abs(e$CAL[["dDBH_L_NO"]]$cc - K$cc)),
            sum(abs(unlist(cc[cc$fit == "dDBH_L_NO" & cc$term == "b3", c("estimate", "se")]))), max(abs(hc$estimate - h5$estimate)),
            max(abs(unlist(sc[sc$fit == "dHT_L_NO", c("cf_source_inst", "c_natural", "c_planted", "cal_natural", "cal_planted")]) - unlist(s5[s5$fit == "dHT_L_NO", c("cf_source_inst", "c_natural", "c_planted", "cal_natural", "cal_planted")])))))
se <- summary(e$FITS[["dDBH_L_NO"]])$tTable[names(b), 2]; dz <- max(abs(b - kb) / se)
G <- rbind(G, data.frame(check = "dDBH_L_NO fixef vs screen K3c1, max diff in SE units", value = dz))
## rule (as inc_v103.R gate R1): identical to 1e-6, or within 1e-3 SE with logLik within 1e-3 (the screen fit used the in-memory frame of koa_rdcomp, this one the
## frame rebuilt in inc_v103.R; the K3c1 columns differ by 1.2e-14, see parity_frames.csv, and nlme stops at a slightly different point of the same optimum)
ok1 <- G$value[1] < 1e-6 || (dz < 1e-3 && abs(G$value[2]) < 1e-3)
G$pass <- c(ok1, ok1, ok1 || G$value[3] < 1e-3, G$value[4] == 0, G$value[5] == 0, G$value[6] == 0, ok1)
print(G, digits = 6); write.csv(G, file.path(VC, "v105c/out/gate_k3c1_fit.csv"), row.names = FALSE)
print(sc[sc$fit == "dDBH_L_NO", ]); cat("GATE_K3C1_FIT", if (all(G$pass)) "PASS" else "FAIL", "\n")
