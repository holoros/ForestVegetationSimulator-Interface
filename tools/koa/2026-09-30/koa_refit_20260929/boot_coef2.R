#!/usr/bin/env Rscript
## boot_coef2.R (second pass: NO frame, conventional BAL, engine form with planted guards; adapted from boot_coef.R)
## boot_coef.R, job koa_refit_20260929. Installation-cluster bootstrap of the deployed increment fits (dDBH_c_NO, dHT_c_AP):
## resample installations with replacement within data source, refit the nlme (random b0 | Data/Install/TreeID, varPower(0.2, ~DBH.0)) from the
## deployed vector, record fixef and the recursion-consistent origin constants. Usage: Rscript boot_coef.R <resp> <B> <ncores>.
## Percentile intervals on B = 400 rest on 10 draws per tail, so the bootstrap SE (normal interval) is the quantity carried into the Monte Carlo.
suppressPackageStartupMessages({ library(nlme); library(parallel) })
args <- commandArgs(trailingOnly = TRUE); resp <- args[1]; B <- as.integer(args[2]); NC <- as.integer(args[3])
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
load("out/fits2.rda"); tag <- paste0(resp, "_c_NO"); cal <- CAL[[tag]]; GUARD <- if (resp == "dDBH") 45 else 20
gr.hat2 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, temp, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9) {
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + b3 * (bal.c^2 / log(pd.c + 5)) + b4 * log(bal.c + 1) + b5 * log(cr.c) + b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pmin(pd.c, GUARD) + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1
}
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
d <- read.csv(sprintf("frames2/%s_NO.csv", resp), stringsAsFactors = FALSE)
d$BALx.0 <- d$BALc.0; d$BALx.1 <- d$BALc.1; d$CRx.0 <- d$CRc.0; d$CRx.1 <- d$CRc.1
d <- d[complete.cases(d[, c("DBH.0", "HT.0", "BALx.0", "BALx.1", "CRx.0", "CRx.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")]) & d$BYI > 0 & d$CRx.0 > 0 & d$CRx.1 > 0, ]
d$inst <- paste(d$Data, d$Install)
size <- if (resp == "dDBH") "DBH.0" else "HT.0"
f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
ctl <- nlmeControl(maxIter = 100, pnlsMaxIter = 10, msMaxIter = 100, minScale = 1e-10, returnObject = TRUE)
pa_pred <- function(dd, b) gr.hat3(dd[[size]], dd$BALx.0, dd$BALx.1, dd$CRx.0, dd$CRx.1, dd$BAPH.0, dd$BAPH.1, dd$Planted, dd$BYI, dd$YIP, b["b0"], b["b1"], b["b2"], b["b3"], b["b4"], b["b5"], b["b6"], b["b7"], b["b8"], b["b9"])
solve_c1 <- function(dd, b) { f <- function(lc) { bb <- b; bb["b0"] <- b["b0"] + lc; sum(pa_pred(dd, bb)) - sum(dd[[resp]]) }; exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) }
sp <- split(seq_len(nrow(d)), d$inst); src_of <- tapply(d$Data, d$inst, function(x) x[1]); ids_by_src <- split(names(sp), src_of)
one <- function(i) {
  set.seed(20260929 + i)
  ids <- unlist(lapply(ids_by_src, function(v) sample(v, replace = TRUE)), use.names = FALSE)
  idx <- unlist(lapply(seq_along(ids), function(j) sp[[ids[j]]]), use.names = FALSE)
  dd <- d[idx, ]; dd$Install <- paste(dd$Install, rep(seq_along(ids), lengths(sp[ids])), sep = "_r")   # resampled installations are distinct clusters
  dd$TreeID <- paste(dd$TreeID, dd$Install)
  m <- tryCatch(nlme(f3, data = dd, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = cal$b, weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) NULL)
  if (is.null(m)) return(data.frame(draw = i, ok = FALSE))
  b <- fixef(m); cn <- tryCatch(solve_c1(dd[dd$Planted == 0, ], b), error = function(e) NA); cp <- tryCatch(solve_c1(dd[dd$Planted == 1, ], b), error = function(e) NA)
  vc <- VarCorr(m); tau <- suppressWarnings(as.numeric(vc[grep("^b0", rownames(vc)), "StdDev"]))
  cbind(data.frame(draw = i, ok = TRUE), as.data.frame(t(b)), data.frame(c_natural = cn, c_planted = cp, tau_source = tau[1], tau_inst = tau[2], tau_tree = tau[3]))
}
logm("boot", resp, "B", B, "cores", NC, "rows", nrow(d), "installations", length(sp))
res <- mclapply(seq_len(B), one, mc.cores = NC)
res <- do.call(rbind, lapply(res, function(x) { if (!isTRUE(x$ok)) x[setdiff(names(res[[which(sapply(res, function(z) isTRUE(z$ok)))[1]]]), names(x))] <- NA; x }))
write.csv(res, sprintf("out/boot_coef2_%s.csv", resp), row.names = FALSE)
ok <- res[res$ok %in% TRUE, ]
S <- data.frame(term = c(paste0("b", 0:9), "c_natural", "c_planted"), estimate = c(cal$b, cal$cc), boot_se = sapply(c(paste0("b", 0:9), "c_natural", "c_planted"), function(v) sd(ok[[v]], na.rm = TRUE)),
  lo95 = sapply(c(paste0("b", 0:9), "c_natural", "c_planted"), function(v) quantile(ok[[v]], 0.025, na.rm = TRUE)), hi95 = sapply(c(paste0("b", 0:9), "c_natural", "c_planted"), function(v) quantile(ok[[v]], 0.975, na.rm = TRUE)), n_ok = nrow(ok), B = B)
write.csv(S, sprintf("out/boot_coef2_%s_summary.csv", resp), row.names = FALSE); print(S)
logm("BOOT DONE", resp, "converged", nrow(ok), "of", B)
