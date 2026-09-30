## (1) What BYI the FIA growth plots carry in AK_PLT_GEO; (2) what the 347 zero-BYI RF training locations are;
## (3) transfer test of the deposited surface BYI_all.tif to the Eq. 1 plots of Oahu, Maui and Kauai (no training
## data there) and Hawaii Island, using the public FIA plot coordinates in HI_PLOT.csv (perturbed by FIA, up to
## about 1.6 km), read with gdallocationinfo on firebreather. Coordinates are never written out.
suppressMessages({library(data.table); library(ranger)})
set.seed(20260928); B <- 2000
arch <- fread("in/Schmoldt_Index_by_plot.csv")
g <- fread("../koa_zenodo_180/stage_v190/AK_PLT_GEO.csv")[Data == "FIA"]
g[, c("s", "u", "COUNTYCD", "PLOT") := tstrsplit(Install, "-", type.convert = TRUE)]
gp <- unique(g[, .(COUNTYCD, PLOT, BYI)])
cat("AK_PLT_GEO FIA installations", uniqueN(g$Install), " distinct BYI per installation max", g[, uniqueN(BYI), by = Install][, max(V1)], "\n")
fr <- readRDS("work_frames_RESTRICTED.rds"); k <- fr$k
mk <- readRDS("in/BYI_srf_fit.RDS"); D <- as.data.frame(k[, mk$ranger.arguments$predictor.variable.names, with = FALSE]); D$PTYPE <- factor(D$PTYPE)
k$pred_in <- predict(mk, data = D)$predictions
x <- merge(merge(gp, arch, by = c("COUNTYCD", "PLOT"), all.x = TRUE), k[, .(COUNTYCD, PLOT, pred_in)], by = c("COUNTYCD", "PLOT"), all.x = TRUE)
cat(sprintf("FIA growth plots %d: with Eq. 1 estimate %d, equal to it (|d|<0.5) %d; with Kona in-sample prediction %d, equal to it %d\n",
    nrow(x), sum(!is.na(x$Schmoldt_Index)), sum(abs(x$BYI - x$Schmoldt_Index) < 0.5, na.rm = TRUE), sum(!is.na(x$pred_in)), sum(abs(x$BYI - x$pred_in) < 0.5, na.rm = TRUE)))
cat(sprintf("   median AK_PLT_GEO BYI %.1f; median Eq. 1 estimate on the same plots %.1f; Spearman %.3f\n", median(x$BYI), median(x$Schmoldt_Index, na.rm = TRUE),
    cor(x$BYI, x$Schmoldt_Index, method = "spearman", use = "complete.obs")))
## zero-BYI locations
pl <- fread("in/HI_PLOT.csv", integer64 = "character", select = c("INVYR", "COUNTYCD", "PLOT", "PLOT_STATUS_CD", "PLOT_NONSAMPLE_REASN_CD", "LAT", "LON"))
last <- pl[order(-INVYR)][!duplicated(paste(COUNTYCD, PLOT))]
ever_forest <- pl[, .(ever_forest = any(PLOT_STATUS_CD == 1)), by = .(COUNTYCD, PLOT)]
z <- merge(k[SI == 0, .(COUNTYCD, PLOT)], merge(last[, .(COUNTYCD, PLOT, PLOT_STATUS_CD, PLOT_NONSAMPLE_REASN_CD)], ever_forest, by = c("COUNTYCD", "PLOT")), by = c("COUNTYCD", "PLOT"), all.x = TRUE)
cat("zero-BYI locations by latest PLOT_STATUS_CD (1 forest, 2 nonforest, 3 nonsampled; NA not in HI_PLOT):\n"); print(z[, .N, by = PLOT_STATUS_CD][order(PLOT_STATUS_CD)])
cat("   ever sampled as forest:", sum(z$ever_forest, na.rm = TRUE), " of", nrow(z), "\n")
cat("   nonsample reason among status 3:"); print(z[PLOT_STATUS_CD == 3, .N, by = PLOT_NONSAMPLE_REASN_CD])
nzk <- merge(k[SI > 0, .(COUNTYCD, PLOT)], last[, .(COUNTYCD, PLOT, PLOT_STATUS_CD)], by = c("COUNTYCD", "PLOT"), all.x = TRUE)
cat("nonzero RF locations by latest PLOT_STATUS_CD:"); print(nzk[, .N, by = PLOT_STATUS_CD])
## surface transfer
loc <- merge(arch, last[, .(COUNTYCD, PLOT, LAT, LON)], by = c("COUNTYCD", "PLOT"))
tf <- tempfile(); fwrite(loc[, .(LON, LAT)], tf, sep = " ", col.names = FALSE)
v <- system(sprintf("gdallocationinfo -valonly -wgs84 ../koa_zenodo_180/stage_v190/BYI_all.tif < %s", tf), intern = TRUE); unlink(tf)
loc$surf <- suppressWarnings(as.numeric(v)); loc$LAT <- NULL; loc$LON <- NULL
loc[, island := fcase(COUNTYCD == 1, "Hawaii", COUNTYCD == 3, "Oahu", COUNTYCD == 7, "Kauai", COUNTYCD == 9, "Maui County")]
met <- function(o, p) c(R2 = 1 - sum((o - p)^2) / sum((o - mean(o))^2), RMSE = sqrt(mean((o - p)^2)), bias = mean(p - o), spear = cor(o, p, method = "spearman"),
                        med_obs = median(o), med_surf = median(p))
res <- list()
for (s in c("Hawaii", "Oahu", "Maui County", "Kauai", "Other islands pooled")) {
  d <- if (s == "Other islands pooled") loc[island != "Hawaii" & !is.na(surf)] else loc[island == s & !is.na(surf)]
  if (nrow(d) < 5) next
  e <- met(d$Schmoldt_Index, d$surf); bt <- t(replicate(B, { i <- sample.int(nrow(d), nrow(d), TRUE); met(d$Schmoldt_Index[i], d$surf[i]) }))
  res[[s]] <- data.table(set = s, n = nrow(d), n_surface_NA = if (s == "Other islands pooled") sum(loc[island != "Hawaii"]$surf %in% NA) else sum(is.na(loc[island == s]$surf)),
                         stat = names(e), est = e, lo95 = apply(bt, 2, quantile, .025), hi95 = apply(bt, 2, quantile, .975)) }
R <- rbindlist(res); num <- c("est", "lo95", "hi95"); R[, (num) := lapply(.SD, round, 3), .SDcols = num]
options(width = 200); print(R); fwrite(R, "out_T5_surface_transfer.csv")
cat("done\n")
