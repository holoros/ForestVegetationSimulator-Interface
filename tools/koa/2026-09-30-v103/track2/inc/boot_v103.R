#!/usr/bin/env Rscript
## boot_v103.R <resp> <B> <ncores>: installation-cluster coefficient bootstrap of the deployed v103 increment fit (boot_coef2.R pattern of
## koa_refit_20260929): installations resampled with replacement within data source, resampled installations are distinct clusters, nlme refit
## from the deployed vector with the deployed random structure, recursion-consistent origin constants re-solved on every draw.
suppressPackageStartupMessages({ library(nlme); library(parallel) })
a <- commandArgs(trailingOnly = TRUE); resp <- a[1]; B <- as.integer(a[2]); NC <- as.integer(a[3])
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
W <- path.expand("~/jobs/koa_v103_20260930"); OUT <- file.path(W, "out/inc")
ORT <- read.csv(file.path(W, "inputs/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE); psp_planted <- as.character(ORT$Install[ORT$Origin_new == "Planted"])
HCB_P <- c(b0 = 0.1684, b1 = 1.0146, b2 = -0.376, b3 = -0.0078, b4 = -0.3734, b5 = -0.221)
engine.HCB <- function(HT, DBH, BAL, BAPH, BYI) { p <- HCB_P
  eta <- p["b0"] + p["b1"] * sqrt(HT / 100) + p["b2"] * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + p["b3"] * sqrt(pmax(BAL * BAPH + 1, 0)) + p["b4"] * log(BAPH + 1) + p["b5"] * log(pmax(BYI, 1) / 100)
  HT / (1 + exp(-eta)) }
add_cr <- function(d, bal0, bal1) {
  h0 <- engine.HCB(d$HT.0, d$DBH.0, bal0, d$BAPH.0, d$BYI); h1 <- engine.HCB(d$HT.1, d$DBH.1, bal1, d$BAPH.1, d$BYI)
  d$CR.0 <- (d$HT.0 - h0) / d$HT.0; d$CR.1 <- (d$HT.1 - h1) / d$HT.1; d
}
recode_planted <- function(d) { d$Planted <- ifelse(d$Origin != "Natural", 1L, 0L); isp <- d$Data == "PSP"
  d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted); d }

gr.hat2 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, temp, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9) {
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + b3 * (bal.c^2 / log(pd.c + 5)) + b4 * log(bal.c + 1) + b5 * log(cr.c) +
                b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pd.c + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1
}
## R11: engine form. The planted size term uses min(size, GUARD) with GUARD = 45 cm (DDBH_PLANTED_GUARD_CM) or 20 m (DDBH_HT_TRUNCATION_M), as in koa_equations.
GUARD <- 45
gr.hat2g <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, temp, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9) {
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + b3 * (bal.c^2 / log(pd.c + 5)) + b4 * log(bal.c + 1) + b5 * log(cr.c) +
                b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pmin(pd.c, GUARD) + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1
}
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2g(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
START <- list(dDBH = c(b0 = -1.15094113584424, b1 = 0.337116783134352, b2 = -0.0143456480282451, b3 = -0.00177215268764851, b4 = -0.430651500423759,
                       b5 = 1.28093519885364, b6 = -0.0176012562326039, b7 = -0.0176237502487828, b8 = 0.304524534930187, b9 = 0.410353392826353),
              dHT = c(b0 = -3.6115368407385, b1 = 1.12068761908095, b2 = -0.115548851420972, b3 = -0.000912086786630362, b4 = -0.133088590048465,
                      b5 = -0.525311059029512, b6 = 0.0379860187025011, b7 = -0.124107167977264, b8 = 0.223216428520199, b9 = 1.06821987786012))
ctl <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2); rmse <- function(o, p) sqrt(mean((o - p)^2))
model_cols <- function(d, b) { d$BALx.0 <- d[[paste0("BAL", b, ".0")]]; d$BALx.1 <- d[[paste0("BAL", b, ".1")]]; d$CRx.0 <- d[[paste0("CR", b, ".0")]]; d$CRx.1 <- d[[paste0("CR", b, ".1")]]
  d <- d[complete.cases(d[, c("DBH.0", "HT.0", "BALx.0", "BALx.1", "CRx.0", "CRx.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")]) & d$BYI > 0 & d$CRx.0 > 0 & d$CRx.1 > 0, ]; d }
pa_pred <- function(resp, d, b) {   # population-average period prediction, b a named coefficient vector
  size <- if (resp == "dDBH") d$DBH.0 else d$HT.0
  gr.hat3(size, d$BALx.0, d$BALx.1, d$CRx.0, d$CRx.1, d$BAPH.0, d$BAPH.1, d$Planted, d$BYI, d$YIP, b["b0"], b["b1"], b["b2"], b["b3"], b["b4"], b["b5"], b["b6"], b["b7"], b["b8"], b["b9"]) }
solve_c <- function(resp, d, b) {   # recursion-consistent origin constants: exp(lp) x c each step reproduces the observed period sum by origin
  sapply(c(natural = 0, planted = 1), function(pl) { dd <- d[d$Planted == pl, ]; if (nrow(dd) == 0) return(NA_real_)
    f <- function(lc) { bb <- b; bb["b0"] <- b["b0"] + lc; sum(pa_pred(resp, dd, bb)) - sum(dd[[resp]]) }
    exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) }) }
fit_one <- function(resp, d, fr) {
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  rnd <- if (fr == "CS") b0 ~ 1 | Data/Install else b0 ~ 1 | Data/Install/TreeID
  nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = rnd, start = START[[resp]], weights = varPower(0.2, form = ~DBH.0), control = ctl)
}
eq_boot <- function(o, p, cl, B = 1000) {   # installation-cluster bootstrap equivalence test, observed on predicted (Robinson et al. 2005 regression form)
  ids <- unique(cl); sp <- split(seq_along(o), cl); mo <- mean(o)
  bs <- t(replicate(B, { idx <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE); coef(lm(o[idx] ~ p[idx])) }))
  ci <- apply(bs, 2, quantile, c(0.025, 0.975)); a <- coef(lm(o ~ p))
  # smallest region (fraction) at which each component passes: intercept |CI| <= r * mean(o); slope CI within 1 +- r
  r_int <- max(abs(ci[, 1])) / mo; r_slp <- max(abs(ci[, 2] - 1))
  c(int = a[[1]], int_lo = ci[1, 1], int_hi = ci[2, 1], slope = a[[2]], slope_lo = ci[1, 2], slope_hi = ci[2, 2],
    pass_int_25 = as.numeric(r_int <= 0.25), pass_slope_25 = as.numeric(r_slp <= 0.25), min_region_int = r_int, min_region_slope = r_slp) }
score <- function(resp, d, b, cc, tag) {   # score a coefficient vector b with origin constants cc on frame d (already model_cols'd for the fit's BAL)
  per <- pa_pred(resp, d, b) * cc[ifelse(d$Planted == 1, "planted", "natural")]; obs <- d[[resp]]
  ann_o <- obs / d$YIP; ann_p <- per / d$YIP; org <- ifelse(d$Planted == 1, "planted", "natural")
  q <- cut(d$BALx.0, quantile(d$BALx.0, 0:5 / 5), include.lowest = TRUE, labels = paste0("Q", 1:5))
  sz <- if (resp == "dDBH") cut(d$DBH.0, c(0, 5, 10, 20, 30, 40, 60, 300), labels = c("0-5", "5-10", "10-20", "20-30", "30-40", "40-60", "60+")) else cut(d$HT.0, c(0, 5, 10, 15, 20, 30, 100), labels = c("0-5", "5-10", "10-15", "15-20", "20-30", "30+"))
  one <- function(idx, lab, lev) data.frame(fit = tag, eval_frame = d$frame[1], strat = lab, level = lev, n = length(idx),
    ratio = sum(ann_o[idx]) / sum(ann_p[idx]), bias_ann = mean(ann_p[idx] - ann_o[idx]), rmse_ann = rmse(ann_o[idx], ann_p[idx]), r2_ann = r2(ann_o[idx], ann_p[idx]),
    bias_period = mean(per[idx] - obs[idx]), rmse_period = rmse(obs[idx], per[idx]))
  out <- rbind(one(seq_along(obs), "all", "all"),
    do.call(rbind, lapply(levels(d$icls), function(l) { i <- which(d$icls == l); if (length(i) > 4) one(i, "interval", l) })),
    do.call(rbind, lapply(levels(q), function(l) { i <- which(q == l); one(i, "BALquintile", l) })),
    do.call(rbind, lapply(levels(sz), function(l) { i <- which(sz == l); if (length(i) > 4) one(i, "size", l) })),
    do.call(rbind, lapply(unique(d$Data), function(l) { i <- which(d$Data == l); if (length(i) > 4) one(i, "source", l) })),
    do.call(rbind, lapply(c("natural", "planted"), function(l) { i <- which(org == l); if (length(i) > 4) one(i, "origin", l) })),
    do.call(rbind, lapply(c(0, 1), function(l) { i <- which(d$consec == l); if (length(i) > 4) one(i, "consecutive", as.character(l)) })))
  eq <- eq_boot(ann_o, ann_p, paste(d$Data, d$Install))
  list(strata = out, equiv = data.frame(fit = tag, eval_frame = d$frame[1], t(eq)))
}

fit_one <- function(resp, d, fr, start = START[[resp]]) {
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  rnd <- if (fr == "CS") b0 ~ 1 | Data/Install else b0 ~ 1 | Data/Install/TreeID
  nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = rnd, start = start, weights = varPower(0.2, form = ~DBH.0), control = ctl)
}
taus <- function(m) { vc <- VarCorr(m); sds <- suppressWarnings(as.numeric(vc[, "StdDev"])); nm <- rownames(vc); tau <- sds[grep("^b0|\\(Intercept\\)", nm)]; tau[is.finite(tau)] }

load(file.path(OUT, "fits_v103.rda")); tag <- DEC$deployed[DEC$resp == resp]; cal <- CAL[[tag]]; GUARD <- if (resp == "dDBH") 45 else 20
d <- read.csv(file.path(W, sprintf("frames/final/%s_%s_v103_model.csv", resp, cal$frame)), stringsAsFactors = FALSE); d <- model_cols(d, cal$bal); d$inst <- paste(d$Data, d$Install)
logm("boot", resp, tag, "frame", cal$frame, "bal", cal$bal, "B", B, "cores", NC, "rows", nrow(d), "installations", length(unique(d$inst)))
sp <- split(seq_len(nrow(d)), d$inst); src_of <- tapply(d$Data, d$inst, function(x) x[1]); ids_by_src <- split(names(sp), src_of[names(sp)])
one <- function(i) { set.seed(20260930 + i)
  ids <- unlist(lapply(ids_by_src, function(v) sample(v, length(v), replace = TRUE)), use.names = FALSE)
  idx <- unlist(lapply(ids, function(k) sp[[k]]), use.names = FALSE)
  dd <- d[idx, ]; dd$Install <- paste(dd$Install, rep(seq_along(ids), lengths(sp[ids])), sep = "_r"); dd$TreeID <- paste(dd$TreeID, dd$Install)
  m <- tryCatch(fit_one(resp, dd, cal$frame, start = cal$b), error = function(e) NULL)
  if (is.null(m)) return(data.frame(draw = i, ok = FALSE))
  b <- fixef(m); cc <- tryCatch(solve_c(resp, dd, b), error = function(e) c(natural = NA, planted = NA)); tau <- taus(m)
  cbind(data.frame(draw = i, ok = TRUE), as.data.frame(t(b)), data.frame(c_natural = cc[["natural"]], c_planted = cc[["planted"]], tau_source = tau[1], tau_inst = tau[2], tau_tree = if (length(tau) > 2) tau[3] else NA)) }
res <- mclapply(seq_len(B), one, mc.cores = NC)
okr <- res[sapply(res, function(x) isTRUE(x$ok))]; allc <- names(okr[[1]])
res <- do.call(rbind, lapply(res, function(x) { for (v in setdiff(allc, names(x))) x[[v]] <- NA; x[, allc] }))
res$cf <- exp(0.5 * (res$tau_source^2 + res$tau_inst^2)); res$cal_natural <- res$c_natural / res$cf; res$cal_planted <- res$c_planted / res$cf
write.csv(res, file.path(OUT, sprintf("boot_v103_%s.csv", resp)), row.names = FALSE)
ok <- res[res$ok %in% TRUE, ]; terms <- c(paste0("b", 0:9), "c_natural", "c_planted", "cal_natural", "cal_planted", "cf")
est <- c(cal$b, cal$cc, cal$cc / cal$cf, cal$cf)
S <- data.frame(fit = tag, term = terms, estimate = est, boot_se = sapply(terms, function(v) sd(ok[[v]], na.rm = TRUE)), lo95 = sapply(terms, function(v) quantile(ok[[v]], 0.025, na.rm = TRUE)),
  hi95 = sapply(terms, function(v) quantile(ok[[v]], 0.975, na.rm = TRUE)), se_log = sapply(terms, function(v) if (v %in% c("c_natural", "c_planted", "cal_natural", "cal_planted", "cf")) sd(log(ok[[v]]), na.rm = TRUE) else NA),
  n_ok = nrow(ok), B = B, row.names = NULL)
write.csv(S, file.path(OUT, sprintf("boot_v103_%s_summary.csv", resp)), row.names = FALSE); print(S)
logm("BOOT DONE", resp, "converged", nrow(ok), "of", B)
