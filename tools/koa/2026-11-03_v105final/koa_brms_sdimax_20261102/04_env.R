## 04_env.R: gbm of plot SDImax (fit-of-record posterior mean; Hawaii Island FIA only) on Hawaii environment. True FIA locations read inside R only
## (restricted PLT.GEO_FIA.csv); no coordinate, block id or per-plot predictor row is written or printed.
suppressPackageStartupMessages({library(data.table); library(gbm)})
## terra/sf fail to load on firebreather (GEOS symbol error), so point values come from GDAL gdallocationinfo -wgs84 with the
## locations passed on stdin (in memory, never written); 20 km blocks from gdaltransform the same way.
pin <- function(lon, lat) sprintf("%.7f %.7f", lon, lat)
gval <- function(f, lon, lat) { o <- system2("gdallocationinfo", c("-valonly", "-wgs84", shQuote(f)), input = pin(lon, lat), stdout = TRUE, stderr = FALSE)
  stopifnot(length(o) == length(lon)); v <- suppressWarnings(as.numeric(o))
  nd <- sub(".*NoData Value=", "", grep("NoData Value=", system2("gdalinfo", shQuote(f), stdout = TRUE), value = TRUE))
  if (length(nd)) v[v == as.numeric(nd[1])] <- NA; v }
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); setwd(J)
## AMENDMENT 2: optional args <plot csv> <SDImax column> <suffix>; LQMM run: out/plot_sdimax_lqmm.csv SDImax _lqmm
aa <- commandArgs(TRUE); PF <- if (length(aa) >= 1) aa[1] else "out/plot_sdimax.csv"; VC <- if (length(aa) >= 2) aa[2] else "SDImax_mean"; SUF <- if (length(aa) >= 3) aa[3] else ""
P <- fread(PF)[source == "FIA" & COUNTYCD == 1]; P[, SDImax_mean := get(VC)]   # AMENDMENT 1: Hawaii Island (COUNTYCD 1) FIA plots only; SDImax_mean is the fit of record
g <- fread(path.expand("~/jobs/koa_rv_byi_20260928/in/PLT.GEO_FIA.csv"), select = c("STATECD", "UNITCD", "COUNTYCD", "PLOT", "LAT", "LON"))
g <- g[, .(LAT = LAT[1], LON = LON[1]), by = .(STATECD, UNITCD, COUNTYCD, PLOT)]
g[, ID := paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "-")]
X <- merge(P[, .(ID, SDImax_mean, COUNTYCD)], g[, .(ID, LAT, LON)], by = "ID")
cat("FIA fitted plots", nrow(P), "| with restricted location", nrow(X), "| islands (COUNTYCD) with locations:", paste(unique(X$COUNTYCD), collapse = ","), "\n")
Lr <- fread(path.expand("~/jobs/koa_byipred_20261102/LAYERS.csv"))
keep <- c("rainfall_mm_annual.tif", "rainfall_mm_cv12.tif", "rainfall_mm_minmonth.tif", "AET_mm_month_ascii_annual.tif", "AET_mm_month_ascii_minmonth.tif",
          "Penman_ET0_mm_month_ascii_annual.tif", "SolarRadiation_month_ascii_annual.tif", "CloudFreq_month_ascii_annual.tif",
          "SoilMoisture_month_ascii_annual.tif", "SoilMoisture_month_ascii_minmonth.tif", "Tair_month_ascii_annual.tif", "Tmax_month_ascii_annual.tif",
          "Tmin_month_ascii_annual.tif", "RH_month_ascii_annual.tif", "VPD_month_ascii_annual.tif", "WindSpeed_ann_hr_ascii_mean_of_24_hourly.tif",
          "geo_AGE_GROUP_30m_utm4n.tif", "dem30_utm4n.tif", "slope30_utm4n.tif", "aspect30_utm4n.tif", "TPI30_utm4n.tif", "TRI30_utm4n.tif",
          as.vector(outer(c("bdod", "cec", "cfvo", "clay", "nitrogen", "ocd", "phh2o", "sand", "silt", "soc"), c("0-5cm", "15-30cm"), function(a, b) paste0(a, "_", b, "_mean_HI.tif"))))
Lr <- Lr[file %in% keep]; stopifnot(nrow(Lr) == length(keep))
E <- data.table(row = seq_len(nrow(X)))
for (i in seq_len(nrow(Lr))) {
  v <- gval(Lr$local_path[i], X$LON, X$LAT)
  nm <- sub("\\.tif$", "", Lr$file[i]); E[, (nm) := v]
}
E[, row := NULL]
E[, aspect_cos := cos(aspect30_utm4n * pi / 180)]; E[, aspect30_utm4n := NULL]
E[, geo_AGE_GROUP := factor(geo_AGE_GROUP_30m_utm4n)]; E[, geo_AGE_GROUP_30m_utm4n := NULL]
cat("predictors", ncol(E), "| share missing by predictor (max):", round(max(sapply(E, function(z) mean(is.na(z)))), 3), "\n")
## 20 km blocks in UTM 4N (kept in memory only)
xy <- system2("gdaltransform", c("-s_srs", "EPSG:4269", "-t_srs", "EPSG:32604"), input = pin(X$LON, X$LAT), stdout = TRUE)
xy <- matrix(as.numeric(unlist(strsplit(trimws(xy), " +"))), ncol = 3, byrow = TRUE); stopifnot(nrow(xy) == nrow(X))
blk <- paste(floor(xy[, 1] / 20000), floor(xy[, 2] / 20000)); rm(xy); X[, c("LAT", "LON") := NULL]
y <- X$SDImax_mean; dat <- cbind(data.table(y = y), E)
cat("plots in model", nrow(dat), "| 20 km blocks", uniqueN(blk), "\n")
fitgbm <- function(d) { m <- gbm(y ~ ., data = d, distribution = "gaussian", n.trees = 3000, interaction.depth = 3, shrinkage = 0.005,
                               bag.fraction = 0.5, n.minobsinnode = 5, cv.folds = 5, n.cores = 1, keep.data = FALSE)
                         list(m = m, nt = gbm.perf(m, method = "cv", plot.it = FALSE)) }
cvrun <- function(fold) { pr <- rep(NA_real_, nrow(dat)); for (k in sort(unique(fold))) { tr <- fold != k
  f <- fitgbm(dat[tr]); pr[!tr] <- predict(f$m, dat[!tr], n.trees = f$nt) }; pr }
set.seed(20261102); f_rand <- sample(rep(1:10, length.out = nrow(dat)))
ub <- unique(blk); set.seed(20261102); bf <- setNames(sample(rep(1:10, length.out = length(ub))), ub); f_blk <- bf[blk]
r2 <- function(p) 1 - sum((y - p)^2) / sum((y - mean(y))^2)
p_r <- cvrun(f_rand); p_b <- cvrun(f_blk)
full <- fitgbm(dat); p_in <- predict(full$m, dat, n.trees = full$nt)
res <- data.table(metric = c("n_plots", "n_blocks_20km", "R2_10fold_random", "RMSE_10fold_random", "R2_20km_block_10fold", "RMSE_20km_block_10fold",
                             "R2_insample", "var_pred_over_var_obs_insample (CONUS form)", "n_trees_full", "mean_SDImax_obs", "sd_SDImax_obs"),
                  value = c(nrow(dat), uniqueN(blk), r2(p_r), sqrt(mean((y - p_r)^2)), r2(p_b), sqrt(mean((y - p_b)^2)),
                            r2(p_in), var(p_in) / var(y), full$nt, mean(y), sd(y)))
print(res); fwrite(res, paste0("out/env_gbm_cv", SUF, ".csv"))
ri <- as.data.table(summary(full$m, n.trees = full$nt, plotit = FALSE)); print(head(ri, 12)); fwrite(ri, paste0("out/env_gbm_relinf", SUF, ".csv"))
saveRDS(list(model = full$m, n.trees = full$nt, predictors = names(E), layers = Lr$local_path), paste0("fits/sdimax_env_gbm", SUF, ".rds"))
