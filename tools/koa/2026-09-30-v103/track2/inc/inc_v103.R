#!/usr/bin/env Rscript
## inc_v103.R (koa v103, 2026-09-30). Eq. 4 increment refits on the v103 frames with the refit2.R machinery (engine form recursion: HCB_P crown
## ratio under the candidate BAL, planted guards 45 cm and 20 m, removal screen, NO frame, solve_c, installation-cluster equivalence bootstrap),
## and the preregistered selection rule of RUN.md. Part R runs the reproduction gates first:
##   R1 refit2.R code path on refit2's own frames2 NO frames reproduces dDBH_c_NO and dHT_c_NO of coefficients2.csv to 1e-6;
##   R2 the v102 track2 inc_refit.R path (gr.hat2 unguarded, frame CR, deposited BAL, random b0 | Data/Install) on frames/dDBH_v102.csv and dHT_v102.csv
##      from the deployed start reproduces the v102 vector of record (inc_coefficients.csv, V102 deployed_solution) to 1e-6.
## No coordinate column exists in any input read here; asserted on every frame written.
suppressPackageStartupMessages(library(nlme))
set.seed(20260930)
t_start <- Sys.time()
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
W <- path.expand("~/jobs/koa_v103_20260930"); J <- path.expand("~/jobs/koa_v102_20260918"); R2D <- path.expand("~/jobs/koa_refit_20260929")
OUT <- file.path(W, "out/inc"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE); FRD <- file.path(W, "frames/final")
nocoord <- function(d) stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
args <- commandArgs(trailingOnly = TRUE); PART <- if (length(args)) args[1] else "all"
ORT <- read.csv(file.path(W, "inputs/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORT$Install[ORT$Origin_new == "Planted"])
rem <- do.call(rbind, lapply(seq_len(nrow(ORT)), function(i) { y <- c(ORT$Thin_Yr[i], suppressWarnings(as.numeric(unlist(strsplit(as.character(ORT$removal_t1_years[i]), ";")))))
  y <- unique(y[is.finite(y)]); if (!length(y)) NULL else data.frame(Install = as.character(ORT$Install[i]), year = y) }))
spans_removal <- function(Data, Install, t0, t1) { if (Data != "PSP") return(FALSE); y <- rem$year[rem$Install == as.character(Install)]; any(y > t0 & y < t1) }
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
## ================================================================ Part R: reproduction gates
REPRO <- list()
if (PART %in% c("all", "repro")) {
  C2 <- read.csv(file.path(R2D, "out/coefficients2.csv"), stringsAsFactors = FALSE)
  for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20
    d <- read.csv(file.path(R2D, sprintf("frames2/%s_NO.csv", resp)), stringsAsFactors = FALSE); d <- model_cols(d, "c")
    t0 <- Sys.time(); m <- fit_one(resp, d, "NO"); ref <- C2[C2$fit == paste0(resp, "_c_NO"), ]
    dd <- max(abs(fixef(m)[ref$term] - ref$estimate)); dz <- max(abs(fixef(m)[ref$term] - ref$estimate) / ref$se)
    ll <- read.csv(file.path(R2D, "out/fit_stats2.csv")); ll <- ll$logLik[ll$fit == paste0(resp, "_c_NO")]; dll <- abs(as.numeric(logLik(m)) - ll)
    ok <- dd < 1e-6 || (dz < 1e-3 && dll < 1e-3)
    logm("REPRO R1", resp, "_c_NO on refit2 frames2 (read back from CSV): rows", nrow(d), "max abs fixef diff", signif(dd, 3), "max diff in SE units", signif(dz, 3), "logLik diff", signif(dll, 3), if (ok) "PASS" else "FAIL", "(", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s)")
    REPRO[[paste("R1", resp)]] <- data.frame(gate = "R1 refit2 code on refit2 frames2", resp = resp, max_abs_diff = dd, max_diff_se = dz, loglik_diff = dll, pass = ok) }
  ## R2: v102 vector of record through the v102 track2 path
  rsrc <- readLines(file.path(J, "track2/inc/origin_refit_REFERENCE_COPY.R")); e2 <- new.env()
  eval(parse(text = rsrc[grep("^gr.hat2 <- function", rsrc):(grep("^fit_inc <- function", rsrc) - 1)]), envir = e2)
  gr.hat3v <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
    e2$gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
  DEP <- list(dDBH = c(b0 = -2.0972488, b1 = 0.3105931, b2 = -0.0085285, b3 = -0.0019684, b4 = -0.2899832, b5 = -0.2599003, b6 = -0.0105114, b7 = -0.0258191, b8 = 0.3108402, b9 = 0.4018344),
              dHT = c(b0 = -4.0426171, b1 = 0.9238575, b2 = -0.1099897, b3 = -0.0012181, b4 = -0.0358816, b5 = -1.5423408, b6 = 0.0486628, b7 = -0.1196098, b8 = 0.2471449, b9 = 1.0236256))
  IC <- read.csv(file.path(J, "track2/out/inc_coefficients.csv"), stringsAsFactors = FALSE)
  MC <- c("DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")
  for (resp in c("dDBH", "dHT")) {
    d <- read.csv(file.path(J, sprintf("frames/%s_v102.csv", resp)), stringsAsFactors = FALSE); d <- d[complete.cases(d[, c(resp, MC)]), ]
    isp <- d$Data == "PSP"; d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
    size <- if (resp == "dDBH") "DBH.0" else "HT.0"
    f3 <- as.formula(sprintf("%s ~ gr.hat3v(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
    t0 <- Sys.time(); m <- nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install, start = DEP[[resp]], weights = varPower(0.2, form = ~DBH.0), control = ctl)
    ref <- IC[IC$resp == resp & IC$frame == "V102" & IC$start == "deployed_solution", ]; dd <- max(abs(fixef(m)[ref$term] - ref$estimate)); dz <- max(abs(fixef(m)[ref$term] - ref$estimate) / ref$se)
    ok <- dd < 1e-6 || dz < 1e-3
    logm("REPRO R2", resp, "v102 vector on frames/", resp, "_v102.csv rows", nrow(d), "max abs fixef diff", signif(dd, 3), "max diff in SE units", signif(dz, 3), if (ok) "PASS" else "FAIL", "(", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s)")
    REPRO[[paste("R2", resp)]] <- data.frame(gate = "R2 v102 track2 path on v102 frame", resp = resp, max_abs_diff = dd, max_diff_se = dz, loglik_diff = NA, pass = ok) }
  write.csv(do.call(rbind, REPRO), file.path(OUT, "reproduction_gates.csv"), row.names = FALSE)
  if (!all(do.call(rbind, REPRO)$pass)) { logm("REPRODUCTION GATE FAILED, stopping"); quit(save = "no", status = 3) }
  if (PART == "repro") quit(save = "no")
}
## ================================================================ Part A/B: v103 frames
T <- read.csv(file.path(W, "inputs/AK_TREE_v103.csv"), stringsAsFactors = FALSE); nocoord(T)
T$key <- paste(T$Data, T$Install, T$Plot, T$Measure, sep = "|"); T$tkey <- paste(T$key, T$Tree, sep = "|"); stopifnot(!any(duplicated(T$tkey)))
T$live <- T$Status == "live" & is.finite(T$DBH) & T$DBH > 0
GEO <- read.csv(file.path(W, "inputs/PLT.GEO.V2_v102.csv"), stringsAsFactors = FALSE); nocoord(GEO)
GEO <- GEO[!duplicated(GEO[, c("Data", "Install", "Plot")]), c("Data", "Install", "Plot", "Origin", "OriginYR", "rain", "temp", "BYI")]
CS <- list()
for (resp in c("dDBH", "dHT")) {
  d <- read.csv(file.path(FRD, sprintf("%s_CS_v103.csv", resp)), stringsAsFactors = FALSE); nocoord(d)
  d$TreeID <- paste(d$Data, d$Install, d$Plot, d$Tree, sep = "|"); d$consec <- 1L; d$frame <- "CS"; d <- recode_planted(d)
  CS[[resp]] <- d; logm("CS", resp, "rows", nrow(d))
}
TT <- T[order(T$Data, T$Install, T$Plot, T$Tree, T$Measure), ]
TT <- merge(TT, GEO, by = c("Data", "Install", "Plot"), all.x = TRUE); TT <- TT[order(TT$Data, TT$Install, TT$Plot, TT$Tree, TT$Measure), ]
TT$TreeID <- paste(TT$Data, TT$Install, TT$Plot, TT$Tree, sep = "|")
rows <- list(); n_thin <- 0
for (g in split(seq_len(nrow(TT)), TT$TreeID)) {
  x <- TT[g, ]; if (nrow(x) < 2) next
  x <- x[order(x$Measure), ]; nv <- nrow(x)
  for (i in 1:(nv - 1)) for (j in (i + 1):nv) {
    if (!(j == i + 1 || (i == 1 && j == nv))) next     # NO frame only: consecutive pairs plus first-to-last
    if (!(x$live[i] && x$live[j])) next
    yip <- x$Measure[j] - x$Measure[i]; if (!is.finite(yip) || yip <= 0) next
    if (spans_removal(x$Data[1], x$Install[1], x$Measure[i], x$Measure[j])) { n_thin <- n_thin + 1; next }
    rows[[length(rows) + 1]] <- data.frame(Data = x$Data[1], Install = x$Install[1], Plot = x$Plot[1], Tree = x$Tree[1], TreeID = x$TreeID[1],
      t.0 = x$Measure[i], t.1 = x$Measure[j], YIP = yip, consec = as.integer(j == i + 1), firstlast = as.integer(i == 1 && j == nv),
      DBH.0 = x$DBH[i], DBH.1 = x$DBH[j], HT.0 = x$HT[i], HT.1 = x$HT[j], BAPH.0 = x$BAPH[i], BAPH.1 = x$BAPH[j], BAPH_dep.0 = x$BAPH_depcol[i], BAPH_dep.1 = x$BAPH_depcol[j],
      BALd.0 = x$BALd[i], BALd.1 = x$BALd[j], BALl.0 = x$BALl[i], BALl.1 = x$BALl[j], BALc.0 = x$BALc[i], BALc.1 = x$BALc[j], BAL_dep.0 = x$BAL_dep[i], BAL_dep.1 = x$BAL_dep[j],
      Origin = x$Origin[1], rain = x$rain[1], temp = x$temp[1], BYI = x$BYI[1], stringsAsFactors = FALSE)
  }
}
NO0 <- do.call(rbind, rows); rm(rows)
NO0$dDBH <- NO0$DBH.1 - NO0$DBH.0; NO0$dHT <- NO0$HT.1 - NO0$HT.0; NO0$dDBH.ann <- NO0$dDBH / NO0$YIP; NO0$dHT.ann <- NO0$dHT / NO0$YIP; NO0 <- recode_planted(NO0)
selD <- with(NO0, DBH.0 > 0 & DBH.1 > 0 & YIP > 0 & dDBH.ann > 0 & dDBH.ann < 10)
NO <- list(dDBH = NO0[which(selD), ]); NO$dHT <- NO$dDBH[which(with(NO$dDBH, HT.0 > 0 & dHT.ann > 0 & dHT.ann < 10)), ]
logm("NO: live-live candidate pairs", nrow(NO0), "| dropped for a PSP removal year strictly inside", n_thin)
for (resp in names(NO)) { NO[[resp]]$frame <- "NO"; a <- NO[[resp]]
  ka <- paste(a$TreeID, a$t.0, a$t.1)[a$consec == 1]; kc <- paste(CS[[resp]]$TreeID, CS[[resp]]$t.0, CS[[resp]]$t.1)
  logm("NO", resp, "rows", nrow(a), "first-to-last non consecutive", sum(a$consec == 0), "| GATE consecutive subset vs CS: in both", sum(ka %in% kc), "NO only", sum(!(ka %in% kc)), "CS only", sum(!(kc %in% ka)),
       "| GATE unique (TreeID, t.0, t.1):", if (any(duplicated(paste(a$TreeID, a$t.0, a$t.1)))) "FAIL" else "PASS") }
FR <- list()
for (resp in c("dDBH", "dHT")) for (fr in c("CS", "NO")) {
  d <- if (fr == "CS") CS[[resp]] else NO[[resp]]
  for (b in c("d", "l", "c")) { e <- add_cr(d, d[[paste0("BAL", b, ".0")]], d[[paste0("BAL", b, ".1")]]); d[[paste0("CR", b, ".0")]] <- e$CR.0; d[[paste0("CR", b, ".1")]] <- e$CR.1 }
  d$icls <- cut(d$YIP, c(0, 2, 5, 10, 20, 100), labels = c("1-2", "3-5", "6-10", "11-20", "21+"))
  keep <- c("Data", "Install", "Plot", "Tree", "TreeID", "t.0", "t.1", "YIP", "consec", "icls", "DBH.0", "DBH.1", "HT.0", "HT.1", "BAPH.0", "BAPH.1",
            "BALd.0", "BALd.1", "BALl.0", "BALl.1", "BALc.0", "BALc.1", "CRd.0", "CRd.1", "CRl.0", "CRl.1", "CRc.0", "CRc.1", "Planted", "Origin", "BYI", "rain", "temp", "dDBH", "dHT", "frame")
  if (fr == "NO") keep <- c(keep, "firstlast", "BAPH_dep.0", "BAPH_dep.1") else keep <- c(keep, "BAPH_depcol.0", "BAPH_depcol.1")
  d <- d[, keep]; nocoord(d); FR[[paste(resp, fr)]] <- d
  write.csv(d, file.path(FRD, sprintf("%s_%s_v103_model.csv", resp, fr)), row.names = FALSE)
}
if (PART == "frames") { logm("FRAMES DONE"); quit(save = "no") }
## ================================================================ Part C: candidates
CANDS <- data.frame(tag = c("P_CS", "C_CS", "C_NO", "L_CS", "L_NO"), bal = c("d", "c", "c", "l", "l"), frame = c("CS", "CS", "NO", "CS", "NO"), stringsAsFactors = FALSE)
SIGN <- list(dDBH = function(b) c(b1_pos = b[["b1"]] > 0, b4_neg = b[["b4"]] < 0, b5_pos = b[["b5"]] > 0, b6_neg = b[["b6"]] < 0), dHT = function(b) c(b1_pos = b[["b1"]] > 0, b4_neg = b[["b4"]] < 0))
COEF <- list(); STAT <- list(); STRATA <- list(); EQUIV <- list(); FITS <- list(); CAL <- list(); SG <- list()
for (resp in c("dDBH", "dHT")) for (ci in seq_len(nrow(CANDS))) {
  GUARD <- if (resp == "dDBH") 45 else 20
  b <- CANDS$bal[ci]; fr <- CANDS$frame[ci]; tag <- paste(resp, CANDS$tag[ci], sep = "_"); d <- model_cols(FR[[paste(resp, fr)]], b)
  logm("FIT", tag, "rows", nrow(d), "trees", length(unique(d$TreeID)), "installations", length(unique(paste(d$Data, d$Install))))
  t0 <- Sys.time(); m <- tryCatch(fit_one(resp, d, fr), error = function(e) { logm("  FAILED", conditionMessage(e)); NULL }); if (is.null(m)) next
  bb <- fixef(m); s <- summary(m)$tTable; tau <- taus(m); cf_si <- exp(0.5 * sum(tau[1:2]^2)); cc <- solve_c(resp, d, bb)
  logm("  done in", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min; logLik", round(as.numeric(logLik(m)), 2), "; fixef", paste(sprintf("%.6f", bb), collapse = " "),
       "; tau", paste(sprintf("%.4f", tau), collapse = " "), "; CF", round(cf_si, 4), "; c_nat", round(cc[["natural"]], 4), "c_pl", round(cc[["planted"]], 4))
  COEF[[tag]] <- data.frame(fit = tag, resp = resp, bal = b, frame = fr, term = rownames(s), estimate = s[, 1], se = s[, 2], t = s[, 3], p = s[, 4], row.names = NULL)
  STAT[[tag]] <- data.frame(fit = tag, resp = resp, bal = b, frame = fr, n = nrow(d), n_trees = length(unique(d$TreeID)), n_inst = length(unique(paste(d$Data, d$Install))), n_planted = sum(d$Planted == 1),
    logLik = as.numeric(logLik(m)), aic = AIC(m), sigma = m$sigma, varpower = as.numeric(coef(m$modelStruct$varStruct, unconstrained = FALSE)),
    tau_source = tau[1], tau_inst = tau[2], tau_tree = if (length(tau) > 2) tau[3] else NA, cf_source_inst = cf_si, c_natural = cc[["natural"]], c_planted = cc[["planted"]],
    cal_natural = cc[["natural"]] / cf_si, cal_planted = cc[["planted"]] / cf_si, r2_cond_period = r2(d[[resp]], fitted(m, level = length(tau))), r2_pa_period = r2(d[[resp]], fitted(m, level = 0)))
  CAL[[tag]] <- list(b = bb, cc = cc, resp = resp, bal = b, frame = fr, cf = cf_si, tau = tau); FITS[[tag]] <- m
  sg <- SIGN[[resp]](bb); SG[[tag]] <- data.frame(fit = tag, check = names(sg), value = bb[sub("_.*", "", names(sg))], pass = as.logical(sg), row.names = NULL)
  logm("  sign checks", paste(names(sg), sprintf("%.4f", bb[sub("_.*", "", names(sg))]), ifelse(sg, "PASS", "FAIL"), collapse = " "))
  for (ef in c("CS", "NO")) { GUARD <- if (resp == "dDBH") 45 else 20; de <- model_cols(FR[[paste(resp, ef)]], b); sc <- score(resp, de, bb, cc, tag); STRATA[[paste(tag, ef)]] <- sc$strata; EQUIV[[paste(tag, ef)]] <- sc$equiv }
  save(FITS, CAL, file = file.path(OUT, "fits_v103.rda"))
  write.csv(do.call(rbind, COEF), file.path(OUT, "coefficients_v103.csv"), row.names = FALSE); write.csv(do.call(rbind, STAT), file.path(OUT, "fit_stats_v103.csv"), row.names = FALSE)
  write.csv(do.call(rbind, SG), file.path(OUT, "sign_checks_v103.csv"), row.names = FALSE)
  write.csv(do.call(rbind, STRATA), file.path(OUT, "evaluation_strata_v103.csv"), row.names = FALSE); write.csv(do.call(rbind, EQUIV), file.path(OUT, "equivalence_v103.csv"), row.names = FALSE)
  gc()
}
## benchmark: the v102 vector of record with its origin constants re-solved on each v103 frame (deposited form BAL d, engine form)
for (resp in c("dDBH", "dHT")) for (ef in c("CS", "NO")) { GUARD <- if (resp == "dDBH") 45 else 20; de <- model_cols(FR[[paste(resp, ef)]], "d")
  cc <- solve_c(resp, de, START[[resp]]); sc <- score(resp, de, START[[resp]], cc, paste0(resp, "_V102recal_", ef)); STRATA[[paste(resp, "v102", ef)]] <- sc$strata; EQUIV[[paste(resp, "v102", ef)]] <- sc$equiv
  logm("benchmark v102 vector recalibrated on", ef, resp, "c_nat", round(cc[["natural"]], 4), "c_pl", round(cc[["planted"]], 4)) }
write.csv(do.call(rbind, STRATA), file.path(OUT, "evaluation_strata_v103.csv"), row.names = FALSE); write.csv(do.call(rbind, EQUIV), file.path(OUT, "equivalence_v103.csv"), row.names = FALSE)
## ================================================================ selection (RUN.md rule)
EV <- do.call(rbind, STRATA); EQ <- do.call(rbind, EQUIV); SGd <- do.call(rbind, SG); STd <- do.call(rbind, STAT)
sel <- list()
for (tag in STd$fit) { resp <- STd$resp[STd$fit == tag]
  e_cs <- EQ[EQ$fit == tag & EQ$eval_frame == "CS", ]; e_no <- EQ[EQ$fit == tag & EQ$eval_frame == "NO", ]
  ev_no <- EV[EV$fit == tag & EV$eval_frame == "NO", ]; ev_cs <- EV[EV$fit == tag & EV$eval_frame == "CS", ]
  szlev <- if (resp == "dDBH") c("0-5", "5-10", "10-20", "20-30", "30-40", "40-60") else c("0-5", "5-10", "10-15", "15-20", "20-30")
  szr <- ev_no[ev_no$strat == "size" & ev_no$level %in% szlev, ]
  sel[[tag]] <- data.frame(fit = tag, resp = resp, sign_pass = all(SGd$pass[SGd$fit == tag]), sign_fail = paste(SGd$check[SGd$fit == tag & !SGd$pass], collapse = ";"),
    eq_int_CS = e_cs$min_region_int, eq_slope_CS = e_cs$min_region_slope, eq_int_NO = e_no$min_region_int, eq_slope_NO = e_no$min_region_slope,
    equiv_pass_both = all(c(e_cs$pass_int_25, e_cs$pass_slope_25, e_no$pass_int_25, e_no$pass_slope_25) == 1),
    max_eq_region = max(e_cs$min_region_int, e_cs$min_region_slope, e_no$min_region_int, e_no$min_region_slope),
    size_max_dev_NO = max(abs(szr$ratio - 1)), size_worst_class = szr$level[which.max(abs(szr$ratio - 1))], size_ratios_NO = paste(sprintf("%s:%.2f", szr$level, szr$ratio), collapse = " "),
    rmse_CS = ev_cs$rmse_ann[ev_cs$strat == "all"], rmse_NO = ev_no$rmse_ann[ev_no$strat == "all"], slope_CS = e_cs$slope, slope_NO = e_no$slope, row.names = NULL) }
sel <- do.call(rbind, sel); sel$eligible <- sel$sign_pass & sel$equiv_pass_both & sel$size_max_dev_NO <= 0.25
write.csv(sel, file.path(OUT, "selection_v103.csv"), row.names = FALSE); print(sel)
DEC <- list()
for (resp in c("dDBH", "dHT")) { s <- sel[sel$resp == resp, ]; el <- s[s$eligible, ]; inc <- s[s$fit == paste0(resp, "_P_CS"), ]; why <- character()
  if (nrow(el)) { cc_ <- el[el$fit %in% paste0(resp, c("_C_CS", "_C_NO")), ]
    if (nrow(cc_)) { ch <- cc_[which.min(cc_$rmse_NO), ]; why <- c(why, sprintf("conventional preferred: %s (NO RMSE %.4f)", ch$fit, ch$rmse_NO))
      oth <- el[!(el$fit %in% cc_$fit) & el$rmse_NO < 0.98 * ch$rmse_NO, ]
      if (nrow(oth)) { ch <- oth[which.min(oth$rmse_NO), ]; why <- c(why, sprintf("but %s has NO RMSE more than 2 percent lower (%.4f)", ch$fit, ch$rmse_NO)) } }
    else { ch <- el[which.min(el$rmse_NO), ]; why <- c(why, sprintf("no conventional candidate eligible; lowest NO RMSE eligible %s", ch$fit)) }
    rule <- "eligible" } else { ch <- s[which.min(s$max_eq_region), ]; rule <- "DEVIATION: no candidate eligible, smallest maximum equivalence region"; why <- c(why, sprintf("no eligible candidate; %s has the smallest max region %.3f", ch$fit, ch$max_eq_region)) }
  if (ch$fit != inc$fit && inc$rmse_CS < 0.99 * ch$rmse_CS && inc$rmse_NO < 0.99 * ch$rmse_NO) { why <- c(why, sprintf("P_CS beats %s by more than 1 percent RMSE on both frames (%.4f vs %.4f CS, %.4f vs %.4f NO): P_CS deployed", ch$fit, inc$rmse_CS, ch$rmse_CS, inc$rmse_NO, ch$rmse_NO)); ch <- inc }
  else why <- c(why, sprintf("benchmark P_CS RMSE CS %.4f NO %.4f vs chosen CS %.4f NO %.4f", inc$rmse_CS, ch$rmse_CS, inc$rmse_NO, ch$rmse_NO))
  DEC[[resp]] <- data.frame(resp = resp, deployed = ch$fit, rule = rule, reasons = paste(why, collapse = " | "))
  logm("SELECTION", resp, ch$fit, "|", rule, "|", paste(why, collapse = " | ")) }
DEC <- do.call(rbind, DEC); write.csv(DEC, file.path(OUT, "decision_v103.csv"), row.names = FALSE)
save(FITS, CAL, DEC, file = file.path(OUT, "fits_v103.rda"))
logm("ALL DONE in", round(as.numeric(difftime(Sys.time(), t_start, units = "mins")), 1), "min")
