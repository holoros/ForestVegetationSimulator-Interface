# 83c_ratio_heightforms.R  koa v142 cheap set, parts C and D. No identifier printed.
# (D) red team B: the abstract's site ratio (diameter growth at the 90th against the 10th percentile of BYI) is a partial effect at fixed RD, and RD
#     contains BYI through S1. Recompute it at fixed SDI: ratio = (B90/B10)^b4 x exp(b3 r SDI (1/SM90 - 1/SM10)), r = BAL/BA, for r = 0.25, 0.5, 0.75 and SDI
#     at the median plot SDI of each origin, with 95% intervals from the joint plot-cluster bootstrap of 22t; and under the single-742 system of script 20.
# (C) red team A4: basal-area-weighted height and volume of the six scenarios at 100 and 200 years under height increment forms J1 (record), A1 and B2
#     (script 44, section 3b).
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121")
f <- readRDS("frames/frames.rds"); tr <- as.data.table(f$tr); FT <- readRDS("out/rdbyi2_fits.rds"); BT <- readRDS("out/rdbyi2_boot.rds"); K <- BT$K
bs <- FT$bs; bg <- FT$bg; s1p <- function(b, lb, pl) exp(b[[1]] + b[[2]] * lb + b[[3]] * pl)
u <- unique(tr[, .(pid, planted, BYI)]); bq <- u[, .(b10 = quantile(BYI, .1), b90 = quantile(BYI, .9)), by = planted]
sdi <- unique(as.data.table(f$df)[, .(pid, Measure, planted, SDI_koa)])[, .(sdi50 = median(SDI_koa, na.rm = TRUE)), by = planted]   # koa SDI of record, one value per plot visit
cat("BYI 10th and 90th percentiles and median plot SDI by origin:\n"); print(merge(bq, sdi, by = "planted"))
iS <- 1:3; iG <- 4:9
rat <- function(s, g, b10, b90, pl, r, S) (b90 / b10)^g[5] * exp(g[4] * r * S * (1 / s1p(s, log(b90), pl) - 1 / s1p(s, log(b10), pl)))
D <- rbindlist(lapply(0:1, function(pl) { q <- bq[planted == pl]; S <- sdi[planted == pl, sdi50]
  rbindlist(lapply(c(0.25, 0.5, 0.75), function(r) { bt <- apply(K, 1, function(k) rat(k[iS], k[iG], q$b10, q$b90, pl, r, S)); fr <- apply(K, 1, function(k) (q$b90 / q$b10)^k[iG][5])
    data.table(planted = pl, r = r, SDI = round(S), at_fixed_RD = (q$b90 / q$b10)^bg[[5]], fixed_RD_lo = quantile(fr, .025), fixed_RD_hi = quantile(fr, .975),
      at_fixed_SDI = rat(bs, bg, q$b10, q$b90, pl, r, S), fixed_SDI_lo = quantile(bt, .025), fixed_SDI_hi = quantile(bt, .975)) })) }))
Z <- readRDS("out/sdimax_byi.rds"); b742 <- Z$RF$pop742$bg; D[, single742 := mapply(function(pl) (bq[planted == pl, b90] / bq[planted == pl, b10])^b742[["lbyi"]], planted)]
cat("\n(D) diameter growth ratio, 90th against 10th percentile BYI (point and 95% bootstrap interval); single-742 system has ln(BYI) coefficient", round(b742[["lbyi"]], 3), "(script 20 refit, no interval)\n"); print(D, digits = 3); fwrite(D, "out/growth_ratio_fixed_sdi_83c.csv")
H <- readRDS("out/height_increment_44.rds")$SH; keep <- intersect(c("year", "form", "planted", "level", "HT", "VOL", "BA"), names(H))
HV <- H[form %in% c("J1", "A1", "B2") & year %in% c(100, 200), ..keep]; fwrite(HV, "out/height_forms_100_200_83c.csv")
cat("\n(C) scenario height (and volume where recorded) at 100 and 200 years by height increment form\n"); print(dcast(HV, planted + level ~ form + year, value.var = intersect(c("HT", "VOL"), names(HV)), fun.aggregate = function(v) round(v[1], 1)))
cat("83c done\n")
