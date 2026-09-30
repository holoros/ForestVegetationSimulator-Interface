## BYI vs stocking (R1 c8a) and AGB scale check. Plot-visit stocking from HI_TREE live trees (all species,
## FIA DIA >= 1 in, TPA_UNADJ expansion). No coordinates are read.
suppressMessages(library(data.table))
set.seed(20260928); B <- 2000
tr <- fread("in/HI_TREE.csv", integer64 = "character", select = c("PLT_CN","INVYR","COUNTYCD","PLOT","SUBP","STATUSCD","DIA","HT","TPA_UNADJ","DRYBIO_AG","SPCD"))
tr <- tr[STATUSCD == 1 & !is.na(DIA) & !is.na(TPA_UNADJ)]
pv <- tr[, .(TPH = sum(TPA_UNADJ) * 2.47105, BA = sum(TPA_UNADJ * 0.005454154 * DIA^2) * 0.229568,
             QMD = sqrt(sum(TPA_UNADJ * DIA^2) / sum(TPA_UNADJ)) * 2.54,
             AGBplot = sum(as.numeric(DRYBIO_AG) * TPA_UNADJ, na.rm = TRUE) * 0.00112085), by = .(PLT_CN, INVYR, COUNTYCD, PLOT)]
pv[, SDI := TPH * (QMD / 25.4)^1.605]
pv[, RD_QR := TPH / exp(11.631 - 1.4265 * log(QMD))]      # tau 0.99 koa limiting line (koa_selfthin_qr_20260927)
pv[, RD_1453 := SDI / 1453]                                 # largest SDI on any koa plot-year
a <- fread("in/AGB.FIA.csv", integer64 = "character"); ad <- a[!duplicated(paste(PLT_CN, SUBP))]
## AGB scale check: subplot values in the Eq. 1 frame against plot-level per-hectare AGB of the same visit
sc <- merge(ad[, .(sub_mean = mean(AGB), nsub = .N), by = PLT_CN], pv[, .(PLT_CN = as.character(PLT_CN), AGBplot)], by = "PLT_CN")
sc4 <- sc[nsub == 4]
cat(sprintf("AGB scale: %d visits with 4 subplots in frame; median plot AGB %.1f Mg/ha; median mean-subplot frame AGB %.1f; median ratio plot/mean-subplot %.3f\n",
            nrow(sc4), median(sc4$AGBplot), median(sc4$sub_mean), median(sc4$AGBplot / sc4$sub_mean)))
## plot stocking over the visits that entered Eq. 1
vis <- unique(ad[, .(PLT_CN = as.character(PLT_CN), INVYR, COUNTYCD, PLOT)])
pv[, PLT_CN := as.character(PLT_CN)]
sv <- merge(vis, pv, by = c("PLT_CN", "INVYR", "COUNTYCD", "PLOT"), all.x = TRUE)
ps <- sv[, .(SDI = mean(SDI), RD_QR = mean(RD_QR), TPH = mean(TPH), BA = mean(BA), AGBobs = mean(AGBplot), nvis = .N,
             SDI1 = SDI[which.min(INVYR)], RD1 = RD_QR[which.min(INVYR)], TPH1 = TPH[which.min(INVYR)]), by = .(COUNTYCD, PLOT)]
H <- ad[, .(H40 = mean(H40.m)), by = .(COUNTYCD, PLOT)]
arch <- fread("in/Schmoldt_Index_by_plot.csv")
d <- merge(merge(arch, ps, by = c("COUNTYCD", "PLOT")), H, by = c("COUNTYCD", "PLOT"))
cat("plots with BYI and stocking:", nrow(d), "\n")
sp <- function(x, y) suppressWarnings(cor(x, y, method = "spearman", use = "complete.obs"))
bci <- function(x, y) { n <- length(x); b <- replicate(B, { i <- sample.int(n, n, TRUE); sp(x[i], y[i]) })
  c(est = sp(x, y), lo = unname(quantile(b, .025, na.rm = TRUE)), hi = unname(quantile(b, .975, na.rm = TRUE)), n = n) }
res <- list()
add <- function(set, var, x, y) res[[length(res) + 1]] <<- data.table(set = set, variable = var, t(bci(x, y)))
for (v in c("SDI", "RD_QR", "TPH", "BA", "AGBobs", "H40", "SDI1", "RD1", "TPH1")) add("Eq. 1 plots, all islands (BYI > 0)", v, d$Schmoldt_Index, d[[v]])
dh <- d[COUNTYCD == 1]
for (v in c("SDI", "RD_QR", "TPH")) add("Eq. 1 plots, Hawaii Island (BYI > 0)", v, dh$Schmoldt_Index, dh[[v]])
## all RF training locations, including the zero-filled ones (stocking 0 where no live tally)
fr <- readRDS("work_frames_RESTRICTED.rds")$k
lastv <- pv[order(-INVYR)][!duplicated(paste(COUNTYCD, PLOT))]
k <- merge(fr[, .(COUNTYCD, PLOT, SI)], lastv[, .(COUNTYCD, PLOT, SDI, RD_QR, TPH)], by = c("COUNTYCD", "PLOT"), all.x = TRUE)
cat(sprintf("RF training locations %d; zero BYI %d, of which with a live-tree tally in HI_TREE %d\n", nrow(k), sum(k$SI == 0), sum(k$SI == 0 & !is.na(k$TPH))))
cat(sprintf("zero-BYI locations with live tally: median TPH %.0f, median SDI %.0f\n", median(k[SI == 0 & !is.na(TPH)]$TPH), median(k[SI == 0 & !is.na(TPH)]$SDI)))
for (v in c("SDI", "RD_QR", "TPH")) k[is.na(get(v)), (v) := 0]
for (v in c("SDI", "RD_QR", "TPH")) add("RF training locations incl. zeros (latest visit)", v, k$SI, k[[v]])
kk <- k[SI > 0]; for (v in c("SDI", "RD_QR", "TPH")) add("RF training locations, BYI > 0 (latest visit)", v, kk$SI, kk[[v]])
R <- rbindlist(res); R[, c("est", "lo", "hi") := lapply(.SD, round, 3), .SDcols = c("est", "lo", "hi")]
print(R); fwrite(R, "out_T1_byi_stocking_spearman.csv")
## partial association: BYI on log observed AGB and log H40 (how much of BYI is current biomass)
f <- lm(log(Schmoldt_Index) ~ log(AGBobs + 1) + log(H40), data = d); cat(sprintf("log BYI ~ log AGBobs + log H40: R2 %.3f\n", summary(f)$r.squared))
print(round(coef(summary(f)), 3))
f2 <- lm(log(Schmoldt_Index) ~ log(SDI + 1), data = d); cat(sprintf("log BYI ~ log SDI: R2 %.3f\n", summary(f2)$r.squared))
qs <- d[, .(n = .N, BYI_med = median(Schmoldt_Index), SDI_med = median(SDI)), by = .(RDclass = cut(RD_QR, c(-Inf, .15, .3, .5, Inf)))][order(RDclass)]
print(qs); fwrite(qs, "out_T1b_byi_by_rd_class.csv")
saveRDS(list(pv = pv, d = d), "stocking_frames.rds")
cat("done\n")
