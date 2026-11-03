## lib.R: shared helpers (koa_compscreen_20261102). Read-only inputs; writes only to this job's out/.
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
W <- path.expand("~/jobs/koa_v105_20261102"); JB <- path.expand("~/jobs/koa_compscreen_20261102"); OUT <- file.path(JB, "out")
POP <- 923; SEED <- 20261102L; NB <- as.integer(Sys.getenv("NB", "1000"))
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
nocoord <- function(d) stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y", "lat_true", "lon_true")))
rmse <- function(o, p) sqrt(mean((o - p)^2))
auc <- function(y, s) { r <- rank(s); n1 <- sum(y == 1); n0 <- sum(y == 0); if (n1 == 0 || n0 == 0) return(NA_real_); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
auc_within <- function(y, s, g) { num <- 0; den <- 0
  for (idx in split(seq_along(y), g)) { yy <- y[idx]; n1 <- sum(yy == 1); n0 <- sum(yy == 0); if (n1 == 0 || n0 == 0) next
    r <- rank(s[idx]); num <- num + (sum(r[yy == 1]) - n1 * (n1 + 1) / 2); den <- den + n1 * n0 }
  if (den == 0) NA_real_ else num / den }
S <- fread(path.expand("~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot"))); nocoord(S)
SK <- paste(S$Data, S$Install, S$Plot, S$Measure)
C2T <- fread(file.path(W, "repair_v105b/out/c2imp_pltgeo_all.csv"), colClasses = list(character = c("Install", "Plot"))); nocoord(C2T)
c2_of <- function(src, inst, plot) C2T$C2V105B[match(paste(src, inst, plot), paste(C2T$Data, C2T$Install, C2T$Plot))]
sdi_of <- function(src, inst, plot, yr) S$SDI_qmd[match(paste(src, inst, plot, yr), SK)]
qboot <- function(v) c(lo = unname(quantile(v, 0.025, na.rm = TRUE)), hi = unname(quantile(v, 0.975, na.rm = TRUE)), n_ok = sum(is.finite(v)))
