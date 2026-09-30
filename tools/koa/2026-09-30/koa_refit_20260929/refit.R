#!/usr/bin/env Rscript
## refit.R, job koa_refit_20260929 (firebreather). Koa increment refit under three BAL definitions on two fitting frames.
## Preregistered comparison, written 29 September 2026 before any fit was run.
##   BAL definitions (per tree visit, from inputs/AK_TREE_v102.csv, the deduplicated tree table of record):
##     d  deposited: the BAL column of AK_TREE_v102.csv itself, (1 - BA.perc) x BAPH with BA.perc over EVERY record of the plot-year (fitting definition of record; a recomputation is written as a check)
##     l  live list: the same percentile over live, positive-diameter records only (Python engine and HiGy 0.4.1)
##     c  conventional: basal area per hectare of live trees strictly larger than the subject (FVS, HiGy 0.4.0 on Midgard main)
##   Frames:
##     CS consecutive pairs, the frames of record (frames/dDBH_v102.csv, dHT_v102.csv; 4,790 and 3,857 rows), BAL columns replaced
##     AP all valid intervals: every ordered pair of live visits of a tree with DBH > 0 at both ends, YIP > 0, annual increment in (0, 10),
##        screened for a PSP thinning year strictly inside the interval, plus a flag for a > 30 percent BAPH drop at an intermediate visit
##   Model: Eq. 4 of record, gr.hat3 annual recursion (b0 + b9 x Planted level shift, b7 x Planted x size), nlme, varPower(0.2, ~DBH.0),
##        random b0 on Data/Install (CS) and Data/Install/Tree (AP). Start = v102 vector of record (deployed_solution optimum).
##   Calibration: origin constants c_o solved recursion-consistently (sum of period predictions with exp(lp) x c_o each step = sum observed),
##        CF = exp(0.5 (tau_source^2 + tau_inst^2)) reported and k_o = c_o / CF; ratio-of-sums k reported too.
##   Evaluation: every fit scored on BOTH frames; obs/pred ratio, bias, RMSE, R2 of annual increment by interval class, BAL quintile, origin;
##        end-of-period size error by interval class; installation-cluster bootstrap (1,000) equivalence test of observed on predicted
##        (intercept region +-25 percent of mean observed, slope region +-25 percent), smallest passing region reported.
##   Also: Eq. 3 HCB (engine HCB_P form) refit under d, l, c on frames/AK_HCB_v102_keydedup.csv; cohort BAL fraction
##        (koa_params.BAL_COHORT_LIN_B form, stems within 5 percent of QMD, plot-years with >= 5 positive-diameter stems) under d, l, c.
##   Selection rule (preregistered): the conventional definition is deployed unless the live-list definition beats it on the AP frame by
##        both calibrated RMSE (> 2 percent lower) and a top-BAL-quintile obs/pred ratio closer to 1; either way both are reported.
## No coordinate column exists in any input read here; asserted on every frame written.
suppressPackageStartupMessages(library(nlme))
set.seed(20260929)
t_start <- Sys.time()
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
IN <- file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918")
OUT <- "out"; dir.create(OUT, showWarnings = FALSE); dir.create("frames", showWarnings = FALSE)
nocoord <- function(d) stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
args <- commandArgs(trailingOnly = TRUE); PART <- if (length(args)) args[1] else "all"

## ---------------------------------------------------------------- Part A: BAL per tree visit
T <- read.csv(file.path(IN, "inputs/AK_TREE_v102.csv"), stringsAsFactors = FALSE); nocoord(T)
T$key <- paste(T$Data, T$Install, T$Plot, T$Measure, sep = "|"); T$tkey <- paste(T$key, T$Tree, sep = "|")
stopifnot(!any(duplicated(T$tkey)))
T$live <- T$Status == "live" & is.finite(T$DBH) & T$DBH > 0
T$BAd <- NA_real_; T$BALl <- NA_real_; T$BALc <- NA_real_; T$BALc_sum <- NA_real_; T$rebuild <- NA; T$nlive <- NA_integer_
for (g in split(seq_len(nrow(T)), T$key)) {
  x <- T[g, ]; n <- nrow(x)
  T$BAd[g] <- if (n > 1) (rank(x$DBH, ties.method = "min") - 1) / (n - 1) else 0
  L <- which(x$live); nL <- length(L); T$nlive[g] <- nL
  if (nL > 0) {
    dl <- x$DBH[L]; w <- x$EXPF[L]; w[!is.finite(w)] <- 0; wz <- all(w == 0); if (wz) w <- rep(1, nL)
    ba <- 0.00007854 * dl^2 * w
    larger <- sapply(dl, function(v) sum(ba[dl > v])); share <- larger / sum(ba)
    T$BALc[g[L]] <- share * x$BAPH[L]
    T$BALc_sum[g[L]] <- if (wz) NA else larger
    T$BALl[g[L]] <- (1 - (if (nL > 1) (rank(dl, ties.method = "min") - 1) / (nL - 1) else 0)) * x$BAPH[L]
    T$rebuild[g] <- if (wz) FALSE else abs(sum(ba) - x$BAPH[1]) <= 0.01 * max(x$BAPH[1], 1e-9)
  }
}
T$BALd_recomputed <- (1 - T$BAd) * T$BAPH
T$BALd <- T$BAL   # the deposited column itself is the fitting definition of record; the recomputation is a check only
logm("Part A: deposited BA.perc reproduced to 1e-6 on", round(mean(abs(T$BAd - T$BA.perc) < 1e-6, na.rm = TRUE) * 100, 2), "% of rows;",
     "live-list BAPH rebuild within 1% on", round(mean(T$rebuild, na.rm = TRUE) * 100, 1), "% of plot-years")
write.csv(T[, c("Data", "Install", "Plot", "Measure", "Tree", "Status", "DBH", "HT", "EXPF", "BAPH", "TPH", "QMD", "BA.perc", "BAL", "BALd_recomputed", "BALl", "BALc", "BALc_sum", "nlive", "rebuild")],
          file.path(OUT, "bal_treevisit.csv"), row.names = FALSE)

## site table and helpers
GEO <- read.csv(file.path(IN, "inputs/PLT.GEO.V2_v102.csv"), stringsAsFactors = FALSE); nocoord(GEO)
GEO <- GEO[!duplicated(GEO[, c("Data", "Install", "Plot")]), c("Data", "Install", "Plot", "Origin", "OriginYR", "rain", "temp", "BYI")]
ORT <- read.csv(file.path(IN, "inputs/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORT$Install[ORT$Origin_new == "Planted"])
thin <- ORT[is.finite(ORT$Thin_Yr), c("Install", "Thin_Yr")]
koa.HCB <- function(HT, DBH, BAL, BAPH, rain, temp) {   # frame-builder crown function of record (build_frames_incr.R)
  b0 <- -0.507760; b1 <- -1.565361; b2 <- 0.434077; b3 <- 0.039878; b4 <- 0.295514; b5 <- 0.284263; b6 <- -0.379219
  slender <- log(pmax(HT / DBH, 0.01))
  HT / (1 + exp(b0 + b1 * sqrt(HT / 100) + b2 * slender + b3 * log(BAL * BAPH + 1) + b4 * log(BAPH + 1) + b5 * log(rain + 1) + b6 * log(temp + 1)))
}
add_cr <- function(d, bal0, bal1) {
  h0 <- koa.HCB(d$HT.0, d$DBH.0, bal0, d$BAPH.0, d$rain, d$temp); h1 <- koa.HCB(d$HT.1, d$DBH.1, bal1, d$BAPH.1, d$rain, d$temp)
  d$CR.0 <- (d$HT.0 - h0) / d$HT.0; d$CR.1 <- (d$HT.1 - h1) / d$HT.1; d
}
recode_planted <- function(d) { d$Planted <- ifelse(d$Origin != "Natural", 1L, 0L); isp <- d$Data == "PSP"
  d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted); d }

## ---------------------------------------------------------------- Part B: frames
## CS: frames of record with the three BAL definitions attached
CS <- list()
for (resp in c("dDBH", "dHT")) {
  d <- read.csv(file.path(IN, sprintf("frames/%s_v102.csv", resp)), stringsAsFactors = FALSE); nocoord(d)
  k0 <- paste(d$Data, d$Install, d$Plot, d$t.0, d$Tree, sep = "|"); k1 <- paste(d$Data, d$Install, d$Plot, d$t.1, d$Tree, sep = "|")
  i0 <- match(k0, T$tkey); i1 <- match(k1, T$tkey)
  logm("CS", resp, "rows", nrow(d), "unmatched keys t0", sum(is.na(i0)), "t1", sum(is.na(i1)))
  for (b in c("d", "l", "c")) { v <- paste0("BAL", b); d[[paste0(v, ".0")]] <- T[[v]][i0]; d[[paste0(v, ".1")]] <- T[[v]][i1] }
  d$consec <- 1L; d$frame <- "CS"; d$TreeID <- paste(d$Data, d$Install, d$Plot, d$Tree, sep = "|")
  d <- recode_planted(d)
  CS[[resp]] <- d
}
## AP: all valid intervals from the tree table
TT <- T[order(T$Data, T$Install, T$Plot, T$Tree, T$Measure), ]
TT <- merge(TT, GEO, by = c("Data", "Install", "Plot"), all.x = TRUE); TT <- TT[order(TT$Data, TT$Install, TT$Plot, TT$Tree, TT$Measure), ]
TT$TreeID <- paste(TT$Data, TT$Install, TT$Plot, TT$Tree, sep = "|")
rows <- list(); n_pairs_total <- 0; n_thin <- 0
for (g in split(seq_len(nrow(TT)), TT$TreeID)) {
  x <- TT[g, ]; if (nrow(x) < 2) next
  x <- x[order(x$Measure), ]; nv <- nrow(x); baph_seq <- x$BAPH
  for (i in 1:(nv - 1)) for (j in (i + 1):nv) {
    n_pairs_total <- n_pairs_total + 1
    if (!(x$live[i] && x$live[j])) next
    yip <- x$Measure[j] - x$Measure[i]; if (!is.finite(yip) || yip <= 0) next
    ty <- thin$Thin_Yr[match(as.character(x$Install[1]), as.character(thin$Install))]
    if (x$Data[1] == "PSP" && is.finite(ty) && ty > x$Measure[i] && ty < x$Measure[j]) { n_thin <- n_thin + 1; next }
    drop30 <- if (j > i + 1) any(baph_seq[(i + 1):j] < 0.7 * baph_seq[i:(j - 1)], na.rm = TRUE) else FALSE
    rows[[length(rows) + 1]] <- data.frame(Data = x$Data[1], Install = x$Install[1], Plot = x$Plot[1], Tree = x$Tree[1], TreeID = x$TreeID[1],
      t.0 = x$Measure[i], t.1 = x$Measure[j], YIP = yip, consec = as.integer(j == i + 1), n_between = j - i - 1,
      DBH.0 = x$DBH[i], DBH.1 = x$DBH[j], HT.0 = x$HT[i], HT.1 = x$HT[j], BAPH.0 = x$BAPH[i], BAPH.1 = x$BAPH[j],
      BAL.0 = x$BAL[i], BAL.1 = x$BAL[j], BALd.0 = x$BALd[i], BALd.1 = x$BALd[j], BALl.0 = x$BALl[i], BALl.1 = x$BALl[j],
      BALc.0 = x$BALc[i], BALc.1 = x$BALc[j], Origin = x$Origin[1], rain = x$rain[1], temp = x$temp[1], BYI = x$BYI[1],
      baph_drop30 = drop30, stringsAsFactors = FALSE)
  }
}
AP0 <- do.call(rbind, rows); rm(rows)
AP0$dDBH <- AP0$DBH.1 - AP0$DBH.0; AP0$dHT <- AP0$HT.1 - AP0$HT.0; AP0$dDBH.ann <- AP0$dDBH / AP0$YIP; AP0$dHT.ann <- AP0$dHT / AP0$YIP
AP0 <- recode_planted(AP0)
logm("AP: ordered pairs", n_pairs_total, "live-live pairs kept before increment screen", nrow(AP0), "dropped for a PSP thinning year inside the interval", n_thin)
selD <- with(AP0, DBH.0 > 0 & DBH.1 > 0 & YIP > 0 & dDBH.ann > 0 & dDBH.ann < 10)
AP <- list(dDBH = AP0[which(selD), ]); AP$dHT <- AP$dDBH[which(with(AP$dDBH, HT.0 > 0 & dHT.ann > 0 & dHT.ann < 10)), ]
for (resp in names(AP)) { AP[[resp]]$frame <- "AP"
  logm("AP", resp, "rows", nrow(AP[[resp]]), "trees", length(unique(AP[[resp]]$TreeID)), "consecutive", sum(AP[[resp]]$consec == 1),
       "with intermediate BAPH drop > 30%", sum(AP[[resp]]$baph_drop30), "; interval class counts:",
       paste(names(table(cut(AP[[resp]]$YIP, c(0, 2, 5, 10, 20, 100)))), table(cut(AP[[resp]]$YIP, c(0, 2, 5, 10, 20, 100))), collapse = " ")) }
## gate: consecutive subset of AP against the frame of record
for (resp in names(AP)) { a <- AP[[resp]][AP[[resp]]$consec == 1, ]; ka <- paste(a$TreeID, a$t.0, a$t.1); kc <- paste(CS[[resp]]$TreeID, CS[[resp]]$t.0, CS[[resp]]$t.1)
  logm("GATE", resp, "AP consecutive subset", nrow(a), "record CS", nrow(CS[[resp]]), "| in both", sum(ka %in% kc), "AP only", sum(!(ka %in% kc)), "CS only", sum(!(kc %in% ka))) }
## frames written with a CR for each BAL definition
FR <- list()
for (resp in c("dDBH", "dHT")) for (fr in c("CS", "AP")) {
  d <- if (fr == "CS") CS[[resp]] else AP[[resp]]
  for (b in c("d", "l", "c")) { e <- add_cr(d, d[[paste0("BAL", b, ".0")]], d[[paste0("BAL", b, ".1")]]); d[[paste0("CR", b, ".0")]] <- e$CR.0; d[[paste0("CR", b, ".1")]] <- e$CR.1 }
  d$icls <- cut(d$YIP, c(0, 2, 5, 10, 20, 100), labels = c("1-2", "3-5", "6-10", "11-20", "21+"))
  keep <- c("Data", "Install", "Plot", "Tree", "TreeID", "t.0", "t.1", "YIP", "consec", "icls", "DBH.0", "DBH.1", "HT.0", "HT.1", "BAPH.0", "BAPH.1",
            "BALd.0", "BALd.1", "BALl.0", "BALl.1", "BALc.0", "BALc.1", "CRd.0", "CRd.1", "CRl.0", "CRl.1", "CRc.0", "CRc.1", "Planted", "Origin", "BYI", "rain", "temp", "dDBH", "dHT", "frame")
  if (fr == "AP") keep <- c(keep, "baph_drop30")
  d <- d[, keep]; nocoord(d)
  FR[[paste(resp, fr)]] <- d
  write.csv(d, sprintf("frames/%s_%s.csv", resp, fr), row.names = FALSE)
}
if (PART == "frames") { logm("FRAMES DONE"); quit(save = "no") }

## ---------------------------------------------------------------- Part C: fits
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
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
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
  one <- function(idx, lab, lev) data.frame(fit = tag, eval_frame = d$frame[1], strat = lab, level = lev, n = length(idx),
    ratio = sum(ann_o[idx]) / sum(ann_p[idx]), bias_ann = mean(ann_p[idx] - ann_o[idx]), rmse_ann = rmse(ann_o[idx], ann_p[idx]), r2_ann = r2(ann_o[idx], ann_p[idx]),
    bias_period = mean(per[idx] - obs[idx]), rmse_period = rmse(obs[idx], per[idx]))
  out <- rbind(one(seq_along(obs), "all", "all"),
    do.call(rbind, lapply(levels(d$icls), function(l) { i <- which(d$icls == l); if (length(i) > 4) one(i, "interval", l) })),
    do.call(rbind, lapply(levels(q), function(l) { i <- which(q == l); one(i, "BALquintile", l) })),
    do.call(rbind, lapply(c("natural", "planted"), function(l) { i <- which(org == l); if (length(i) > 4) one(i, "origin", l) })),
    do.call(rbind, lapply(c(0, 1), function(l) { i <- which(d$consec == l); if (length(i) > 4) one(i, "consecutive", as.character(l)) })))
  eq <- eq_boot(ann_o, ann_p, paste(d$Data, d$Install))
  list(strata = out, equiv = data.frame(fit = tag, eval_frame = d$frame[1], t(eq)))
}
COEF <- list(); STAT <- list(); STRATA <- list(); EQUIV <- list(); FITS <- list(); CAL <- list()
for (resp in c("dDBH", "dHT")) for (b in c("d", "l", "c")) for (fr in c("CS", "AP")) {
  tag <- paste(resp, b, fr, sep = "_"); d <- model_cols(FR[[paste(resp, fr)]], b)
  logm("FIT", tag, "rows", nrow(d), "trees", length(unique(d$TreeID)), "installations", length(unique(paste(d$Data, d$Install))))
  t0 <- Sys.time()
  m <- tryCatch(fit_one(resp, d, fr), error = function(e) { logm("  FAILED", conditionMessage(e)); NULL })
  if (is.null(m)) next
  bb <- fixef(m); s <- summary(m)$tTable
  vc <- VarCorr(m); sds <- suppressWarnings(as.numeric(vc[, "StdDev"])); nm <- rownames(vc)
  tau <- sds[grep("^b0|\\(Intercept\\)", nm)]; tau <- tau[is.finite(tau)]   # one per grouping level, outer to inner
  cf_si <- exp(0.5 * sum(tau[1:2]^2)); cf_all <- exp(0.5 * sum(tau^2))
  cc <- solve_c(resp, d, bb)
  pa0 <- pa_pred(resp, d, bb); org <- ifelse(d$Planted == 1, "planted", "natural")
  k_ratio <- tapply(d[[resp]] / d$YIP, org, sum) / tapply(pa0 / d$YIP * cf_si, org, sum)
  logm("  done in", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min; logLik", round(as.numeric(logLik(m)), 2), "; fixef", paste(sprintf("%.6f", bb), collapse = " "),
       "; tau", paste(sprintf("%.4f", tau), collapse = " "), "; CF_source_inst", round(cf_si, 4), "; c_nat", round(cc[["natural"]], 4), "c_pl", round(cc[["planted"]], 4))
  COEF[[tag]] <- data.frame(fit = tag, resp = resp, bal = b, frame = fr, term = rownames(s), estimate = s[, 1], se = s[, 2], t = s[, 3], p = s[, 4], row.names = NULL)
  STAT[[tag]] <- data.frame(fit = tag, resp = resp, bal = b, frame = fr, n = nrow(d), n_trees = length(unique(d$TreeID)), n_inst = length(unique(paste(d$Data, d$Install))),
    n_planted = sum(d$Planted == 1), logLik = as.numeric(logLik(m)), aic = AIC(m), sigma = m$sigma, varpower = as.numeric(coef(m$modelStruct$varStruct, unconstrained = FALSE)),
    tau_source = tau[1], tau_inst = tau[2], tau_tree = if (length(tau) > 2) tau[3] else NA, cf_source_inst = cf_si, cf_all_levels = cf_all,
    c_natural = cc[["natural"]], c_planted = cc[["planted"]], k_natural = cc[["natural"]] / cf_si, k_planted = cc[["planted"]] / cf_si,
    k_ratio_natural = k_ratio[["natural"]], k_ratio_planted = k_ratio[["planted"]], r2_cond_period = r2(d[[resp]], fitted(m, level = length(tau))), r2_pa_period = r2(d[[resp]], fitted(m, level = 0)))
  CAL[[tag]] <- list(b = bb, cc = cc, resp = resp, bal = b, frame = fr)
  FITS[[tag]] <- m
  ## score on both frames (each frame carries every BAL definition)
  for (ef in c("CS", "AP")) { de <- model_cols(FR[[paste(resp, ef)]], b); sc <- score(resp, de, bb, cc, tag); STRATA[[paste(tag, ef)]] <- sc$strata; EQUIV[[paste(tag, ef)]] <- sc$equiv }
  save(FITS, CAL, file = file.path(OUT, "fits.rda"))
  write.csv(do.call(rbind, COEF), file.path(OUT, "coefficients.csv"), row.names = FALSE)
  write.csv(do.call(rbind, STAT), file.path(OUT, "fit_stats.csv"), row.names = FALSE)
  write.csv(do.call(rbind, STRATA), file.path(OUT, "evaluation_strata.csv"), row.names = FALSE)
  write.csv(do.call(rbind, EQUIV), file.path(OUT, "equivalence.csv"), row.names = FALSE)
  gc()
}
## reference: the v102 vector of record scored under its own (deposited) BAL on both frames, with the deployed constants (CF 1.36869 x k 0.40548 / 1.43606; dHT 1.030 x 0.519 / 2.648)
DEPC <- list(dDBH = c(natural = 1.36869 * 0.40548, planted = 1.36869 * 1.43606), dHT = c(natural = 1.030 * 0.51900, planted = 1.030 * 2.64800))
for (resp in c("dDBH", "dHT")) for (ef in c("CS", "AP")) { de <- model_cols(FR[[paste(resp, ef)]], "d"); sc <- score(resp, de, START[[resp]], DEPC[[resp]], paste0(resp, "_deployed_v102"))
  STRATA[[paste(resp, "dep", ef)]] <- sc$strata; EQUIV[[paste(resp, "dep", ef)]] <- sc$equiv }
write.csv(do.call(rbind, STRATA), file.path(OUT, "evaluation_strata.csv"), row.names = FALSE)
write.csv(do.call(rbind, EQUIV), file.path(OUT, "equivalence.csv"), row.names = FALSE)
logm("Part C fits done")

## ---------------------------------------------------------------- Part D: Eq. 3 HCB (engine HCB_P form) under d, l, c
H <- read.csv(file.path(IN, "frames/AK_HCB_v102_keydedup.csv"), stringsAsFactors = FALSE); nocoord(H)
ih <- match(paste(H$Data, H$Install, H$Plot, H$Measure, H$Tree, sep = "|"), T$tkey)
logm("HCB rows", nrow(H), "unmatched to tree table", sum(is.na(ih)))
for (b in c("d", "l", "c")) H[[paste0("BAL", b)]] <- T[[paste0("BAL", b)]][ih]
HCB_P <- c(b0 = 0.1684, b1 = 1.0146, b2 = -0.376, b3 = -0.0078, b4 = -0.3734, b5 = -0.221)
HC <- list()
for (b in c("d", "l", "c")) {
  d <- H[is.finite(H[[paste0("BAL", b)]]) & H$HT > 0 & H$DBH > 0 & H$HCB >= 0 & H$BYI > 0, ]; d$BALx <- d[[paste0("BAL", b)]]; d$inst <- factor(paste(d$Data, d$Install))
  form <- HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / DBH, 0.5)) + b3 * sqrt(BALx * BAPH + 1) + b4 * log(BAPH + 1) + b5 * log(pmax(BYI, 1) / 100))))
  m0 <- tryCatch(nls(form, data = d, start = as.list(HCB_P), control = nls.control(maxiter = 500, warnOnly = TRUE)), error = function(e) NULL)
  st <- if (!is.null(m0)) coef(m0) else HCB_P
  m1 <- tryCatch(nlme(form, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 ~ 1, random = b0 ~ 1 | inst, start = st, control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)), error = function(e) NULL)
  for (nm in c("nls", "nlme")) { m <- if (nm == "nls") m0 else m1; if (is.null(m)) next
    cf <- if (nm == "nls") summary(m)$coefficients else summary(m)$tTable; f0 <- if (nm == "nls") fitted(m) else fitted(m, level = 0)
    HC[[paste(b, nm)]] <- data.frame(bal = b, method = nm, n = nrow(d), term = rownames(cf), estimate = cf[, 1], se = cf[, 2], rmse_pa = rmse(d$HCB, f0), r2_pa = r2(d$HCB, f0),
      tau_inst = if (nm == "nlme") as.numeric(VarCorr(m)[1, "StdDev"]) else NA, aic = AIC(m), row.names = NULL) }
  logm("HCB", b, "n", nrow(d), "nls", !is.null(m0), "nlme", !is.null(m1))
}
write.csv(do.call(rbind, HC), file.path(OUT, "hcb_refit.csv"), row.names = FALSE)

## ---------------------------------------------------------------- Part E: cohort BAL fraction (koa_params.BAL_COHORT_LIN_B form) under d, l, c
py <- split(seq_len(nrow(T)), T$key); CO <- list()
for (b in c("d", "l", "c")) { v <- paste0("BAL", b)
  rr <- lapply(py, function(g) { x <- T[g, ]; L <- x$live & is.finite(x[[v]]); if (sum(x$DBH > 0, na.rm = TRUE) < 5 || sum(L) == 0) return(NULL)
    q <- x$QMD[1]; if (!is.finite(q) || q <= 0 || !is.finite(x$BAPH[1]) || x$BAPH[1] <= 0) return(NULL)
    near <- L & abs(x$DBH - q) <= 0.05 * q; if (!any(near)) return(NULL)
    data.frame(key = x$key[1], plot = paste(x$Data[1], x$Install[1], x$Plot[1]), QMD = q, TPH = x$TPH[1], frac = mean(x[[v]][near] / x$BAPH[near])) })
  cf <- do.call(rbind, rr); cf <- cf[is.finite(cf$frac), ]
  m <- lm(frac ~ log(QMD), data = cf)
  ## plot-clustered standard errors
  X <- model.matrix(m); e <- resid(m); XtXi <- solve(crossprod(X)); meat <- Reduce(`+`, lapply(split(seq_len(nrow(X)), cf$plot), function(i) { u <- crossprod(X[i, , drop = FALSE], e[i]); u %*% t(u) }))
  V <- XtXi %*% meat %*% XtXi
  CO[[b]] <- data.frame(bal = b, n_plotyears = nrow(cf), n_plots = length(unique(cf$plot)), a0 = coef(m)[1], a1 = coef(m)[2], se_a0_cluster = sqrt(V[1, 1]), se_a1_cluster = sqrt(V[2, 2]),
    r2 = summary(m)$r.squared, resid_sd = summary(m)$sigma, mean_frac = mean(cf$frac), qmd_lo = min(cf$QMD), qmd_hi = max(cf$QMD), row.names = NULL)
  logm("cohort fraction", b, "plot-years", nrow(cf), "a0", round(coef(m)[1], 5), "a1", round(coef(m)[2], 5), "mean", round(mean(cf$frac), 4))
}
write.csv(do.call(rbind, CO), file.path(OUT, "cohort_bal_fraction.csv"), row.names = FALSE)
logm("ALL DONE in", round(as.numeric(difftime(Sys.time(), t_start, units = "mins")), 1), "min")
cat("done\n")
