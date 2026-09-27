#!/usr/bin/env Rscript
## C_loso.R -- PREREG-KOA-01 variant C: leave-one-source-out test of the origin
## calibration multipliers, with installation-cluster bootstrap intervals.
## Anchored on the deployed v102 pipeline: track3/inc/loso_v102.R FRAME=V102,
## i.e. the V102 increment frames, the "V102 deployed_solution" nlme fits from
## track2/inc/inc_fits.rda, CFX dDBH 1.36869 / dHT 1.030, so k IS the engine multiplier.
## Nothing here reads or writes coordinates.
suppressPackageStartupMessages(library(nlme))
HOME <- Sys.getenv("HOME")
E2   <- file.path(HOME, "jobs/koa_v102_20260918/track2")
T3   <- file.path(HOME, "jobs/koa_v102_20260918/track3")
JOB  <- file.path(HOME, "jobs/koa_loso_origin_20260926")
OUT  <- file.path(JOB, "out"); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
SEED <- 20260926
NB   <- as.integer(Sys.getenv("NB", "5000"))
NBR  <- as.integer(Sys.getenv("NB_REFIT", "200"))
CORES<- as.integer(Sys.getenv("CORES", "7"))
set.seed(SEED)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
logm("START NB", NB, "NB_REFIT", NBR, "cores", CORES)

sl <- readLines(file.path(T3, "ref/origin_refit_REFERENCE_COPY.R"))
eval(parse(text = sl[grep("^gr.hat2 <- function", sl):(grep("^fit_inc <- function", sl) - 1)]))
ORIG <- read.csv(file.path(E2, "inc/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0,b1,b2,b3,b4,b5,b6,b7,b8,b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9*Planted, b1,b2,b3,b4,b5,b6,b7,b8, 0)
ctl  <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
CFX  <- c(dDBH = 1.36869, dHT = 1.030)
CAL_DEP <- list(dDBH = c(natural = 0.40548, planted = 1.43606),
                dHT  = c(natural = 0.51917, planted = 2.64739))
MC <- c("DBH.0","HT.0","BAL.0","BAL.1","CR.0","CR.1","BAPH.0","BAPH.1","Planted","BYI","YIP")
load(file.path(E2, "inc/inc_fits.rda"))   ## FITS

kof <- function(o, p, g) {
  r <- tapply(o, g, sum) / tapply(p, g, sum)
  c(natural = if ("natural" %in% names(r)) as.numeric(r[["natural"]]) else NA_real_,
    planted = if ("planted" %in% names(r)) as.numeric(r[["planted"]]) else NA_real_)
}
qs <- function(x) { x <- x[is.finite(x)]; if (!length(x)) c(NA_real_, NA_real_) else as.numeric(quantile(x, c(0.025, 0.975))) }

bootk <- function(o, p, g, cl, B, strata = NULL) {
  sp <- split(seq_along(cl), cl); ids <- names(sp)
  st <- if (is.null(strata)) NULL else vapply(sp, function(i) as.character(strata[i[1]]), "")
  ii <- if (is.null(st)) NULL else split(ids, st)
  res <- matrix(NA_real_, B, 2, dimnames = list(NULL, c("natural","planted")))
  for (b in seq_len(B)) {
    ss  <- if (is.null(st)) sample(ids, replace = TRUE) else unlist(lapply(ii, function(z) sample(z, replace = TRUE)), use.names = FALSE)
    idx <- unlist(sp[ss], use.names = FALSE)
    res[b, ] <- kof(o[idx], p[idx], g[idx])
  }
  res
}

summ_row <- function(resp, fold, variant, boot_label, k, bs, nclus, nrec) {
  rat <- bs[, "planted"] / bs[, "natural"]
  cn <- qs(bs[, "natural"]); cp <- qs(bs[, "planted"]); cr <- qs(rat)
  ov <- if (any(is.na(c(cn, cp)))) NA else (max(cn[1], cp[1]) <= min(cn[2], cp[2]))
  data.frame(resp = resp, held_source = fold, variant = variant, interval = boot_label,
    k_natural = k[["natural"]], nat_lo95 = cn[1], nat_hi95 = cn[2],
    k_planted = k[["planted"]], plt_lo95 = cp[1], plt_hi95 = cp[2],
    ratio_plt_nat = k[["planted"]] / k[["natural"]], ratio_lo95 = cr[1], ratio_hi95 = cr[2],
    p_ratio_le_1 = mean(rat[is.finite(rat)] <= 1),
    se_log_nat = sd(log(bs[, "natural"]), na.rm = TRUE), se_log_plt = sd(log(bs[, "planted"]), na.rm = TRUE),
    intervals_overlap = ov,
    n_clusters_nat = nclus[["natural"]], n_clusters_plt = nclus[["planted"]],
    n_rec_nat = nrec[["natural"]], n_rec_plt = nrec[["planted"]],
    boot_na_nat = mean(!is.finite(bs[, "natural"])), boot_na_plt = mean(!is.finite(bs[, "planted"])),
    B = nrow(bs), row.names = NULL)
}

DAT <- list(); RES <- list(); GATE <- list(); DIAG <- list()
for (resp in c("dDBH","dHT")) {
  dat <- read.csv(file.path(E2, sprintf("inc/frames/V102/%s.csv", resp)), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(dat)) %in% c("lat","lon","latitude","longitude","x","y")))
  d <- dat[complete.cases(dat[, c(resp, MC)]), ]
  isp <- d$Data == "PSP"; d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  m <- FITS[[paste(resp, "V102 deployed_solution")]]
  stopifnot(nrow(m$data) == nrow(d), all(abs(m$data[[resp]] - d[[resp]]) < 1e-9))
  obs <- d[[resp]] / d$YIP
  pa  <- fitted(m, level = 0) / d$YIP * CFX[[resp]]
  org <- ifelse(d$Planted == 1, "planted", "natural")
  src <- d$Data
  cl  <- paste(d$Data, d$Install)
  kf  <- kof(obs, pa, org)
  GATE[[resp]] <- data.frame(resp = resp, origin = c("natural","planted"),
    k_recomputed = as.numeric(kf[c("natural","planted")]), k_deployed = as.numeric(CAL_DEP[[resp]][c("natural","planted")]),
    abs_diff = abs(as.numeric(kf[c("natural","planted")]) - as.numeric(CAL_DEP[[resp]][c("natural","planted")])),
    match5 = round(as.numeric(kf[c("natural","planted")]), 5) == round(as.numeric(CAL_DEP[[resp]][c("natural","planted")]), 5))
  logm(resp, "gate k", sprintf("%.6f", kf[["natural"]]), sprintf("%.6f", kf[["planted"]]),
       "deployed", CAL_DEP[[resp]][["natural"]], CAL_DEP[[resp]][["planted"]])
  DAT[[resp]] <- list(d = d, obs = obs, pa = pa, org = org, src = src, cl = cl, kf = kf, m = m)
}
write.csv(do.call(rbind, GATE), file.path(OUT, "C0_reproduction_gate.csv"), row.names = FALSE)
print(do.call(rbind, GATE))

## ---- Stage A: multiplier-only LOSO, full fit held fixed -----------------------
logm("STAGE A")
for (resp in c("dDBH","dHT")) {
  z <- DAT[[resp]]
  folds <- c("NONE", sort(unique(z$src)))
  for (fold in folds) {
    tr <- if (fold == "NONE") rep(TRUE, length(z$obs)) else z$src != fold
    o <- z$obs[tr]; p <- z$pa[tr]; g <- z$org[tr]; c2 <- z$cl[tr]; s2 <- z$src[tr]
    k <- kof(o, p, g)
    ncl <- c(natural = length(unique(c2[g == "natural"])), planted = length(unique(c2[g == "planted"])))
    nre <- c(natural = sum(g == "natural"), planted = sum(g == "planted"))
    set.seed(SEED)
    b1 <- bootk(o, p, g, c2, NB, NULL)
    set.seed(SEED)
    b2 <- bootk(o, p, g, c2, NB, s2)
    RES[[paste(resp, fold, "A", "u")]] <- summ_row(resp, fold, "A_multiplier_only", "installation cluster, unstratified", k, b1, ncl, nre)
    RES[[paste(resp, fold, "A", "s")]] <- summ_row(resp, fold, "A_multiplier_only", "installation cluster, stratified by source", k, b2, ncl, nre)
    logm("A", resp, fold, sprintf("k_nat %.4f [%.4f, %.4f]  k_plt %.4f [%.4f, %.4f]", k[["natural"]], qs(b1[,"natural"])[1], qs(b1[,"natural"])[2], k[["planted"]], qs(b1[,"planted"])[1], qs(b1[,"planted"])[2]))
  }
}
write.csv(do.call(rbind, RES), file.path(OUT, "C1_loso_multipliers.csv"), row.names = FALSE)
logm("STAGE A WRITTEN")

## ---- Stage B: refit per fold, k recomputed on the refit -----------------------
logm("STAGE B")
FITB <- list()
for (resp in c("dDBH","dHT")) {
  z <- DAT[[resp]]; d <- z$d
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  START <- fixef(z$m)
  folds <- c("NONE", sort(unique(z$src)))
  for (fold in folds) {
    tr <- if (fold == "NONE") rep(TRUE, nrow(d)) else z$src != fold
    dd <- d[tr, ]
    t0 <- Sys.time()
    mm <- tryCatch(nlme(f3, data = dd, fixed = b0+b1+b2+b3+b4+b5+b6+b7+b8+b9 ~ 1, random = b0 ~ 1 | Data/Install,
                        start = START, weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) NULL)
    if (is.null(mm)) { logm("B", resp, fold, "REFIT FAILED"); next }
    o <- dd[[resp]] / dd$YIP; p <- fitted(mm, level = 0) / dd$YIP * CFX[[resp]]
    g <- ifelse(dd$Planted == 1, "planted", "natural"); c2 <- paste(dd$Data, dd$Install)
    k <- kof(o, p, g)
    ncl <- c(natural = length(unique(c2[g == "natural"])), planted = length(unique(c2[g == "planted"])))
    nre <- c(natural = sum(g == "natural"), planted = sum(g == "planted"))
    set.seed(SEED); b1 <- bootk(o, p, g, c2, NB, NULL)
    RES[[paste(resp, fold, "B", "u")]] <- summ_row(resp, fold, "B_refit_conditional", "installation cluster, unstratified, fold refit held fixed", k, b1, ncl, nre)
    DIAG[[paste(resp, fold)]] <- data.frame(resp = resp, held_source = fold, n = nrow(dd),
      numIter = if (!is.null(mm$numIter)) mm$numIter else NA_integer_, maxIter = 200,
      hit_maxIter = !is.null(mm$numIter) && mm$numIter >= 200,
      logLik = as.numeric(logLik(mm)),
      max_abs_fixef_move_from_start = max(abs(fixef(mm) - START)),
      k_nat_refit = k[["natural"]], k_plt_refit = k[["planted"]], row.names = NULL)
    FITB[[paste(resp, fold)]] <- list(f3 = f3, START = START, dd = dd, resp = resp)
    logm("B", resp, fold, round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s;",
         sprintf("k_nat %.4f  k_plt %.4f", k[["natural"]], k[["planted"]]))
    write.csv(do.call(rbind, RES), file.path(OUT, "C1_loso_multipliers.csv"), row.names = FALSE)
  }
}
write.csv(do.call(rbind, DIAG), file.path(OUT, "C3_refit_diagnostics.csv"), row.names = FALSE)
print(do.call(rbind, DIAG))
logm("STAGE B WRITTEN")

## ---- Stage C: full bootstrap, refit inside each resample ----------------------
logm("STAGE C nboot", NBR)
for (nm in names(FITB)) {
  fb <- FITB[[nm]]; dd <- fb$dd; resp <- fb$resp
  cl <- paste(dd$Data, dd$Install); sp <- split(seq_along(cl), cl); ids <- names(sp)
  t0 <- Sys.time()
  rr <- parallel::mclapply(seq_len(NBR), function(b) {
    set.seed(20260000L %% 100000L + as.integer(b) * 7919L)
    ss <- sample(ids, replace = TRUE)
    idx <- unlist(sp[ss], use.names = FALSE)
    e <- dd[idx, ]
    e$Install <- paste0(as.character(e$Install), "#", rep(seq_along(ss), lengths(sp[ss])))
    mm <- tryCatch(nlme(fb$f3, data = e, fixed = b0+b1+b2+b3+b4+b5+b6+b7+b8+b9 ~ 1, random = b0 ~ 1 | Data/Install,
                        start = fb$START, weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(x) NULL)
    if (is.null(mm)) return(c(natural = NA_real_, planted = NA_real_))
    p <- fitted(mm, level = 0) / e$YIP * CFX[[resp]]
    kof(e[[resp]] / e$YIP, p, ifelse(e$Planted == 1, "planted", "natural"))
  }, mc.cores = CORES)
  bs <- do.call(rbind, lapply(rr, function(x) if (is.numeric(x) && length(x) == 2) x else c(natural = NA_real_, planted = NA_real_)))
  parts <- strsplit(nm, " ", fixed = TRUE)[[1]]
  fold <- paste(parts[-1], collapse = " ")
  g <- ifelse(dd$Planted == 1, "planted", "natural"); c2 <- cl
  k <- RES[[paste(resp, fold, "B", "u")]][1, c("k_natural","k_planted")]
  kk <- c(natural = k$k_natural, planted = k$k_planted)
  ncl <- c(natural = length(unique(c2[g == "natural"])), planted = length(unique(c2[g == "planted"])))
  nre <- c(natural = sum(g == "natural"), planted = sum(g == "planted"))
  RES[[paste(resp, fold, "C", "u")]] <- summ_row(resp, fold, "C_refit_in_bootstrap", "installation cluster, unstratified, nlme refit inside each resample", kk, bs, ncl, nre)
  logm("C", resp, fold, round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s; ok", sum(is.finite(bs[,"natural"])), "/", NBR,
       sprintf("nat [%.4f, %.4f] plt [%.4f, %.4f]", qs(bs[,"natural"])[1], qs(bs[,"natural"])[2], qs(bs[,"planted"])[1], qs(bs[,"planted"])[2]))
  write.csv(do.call(rbind, RES), file.path(OUT, "C1_loso_multipliers.csv"), row.names = FALSE)
  saveRDS(bs, file.path(OUT, sprintf("C2_bootdraws_%s.rds", gsub("[^A-Za-z0-9]", "_", nm))))
}
write.csv(do.call(rbind, RES), file.path(OUT, "C1_loso_multipliers.csv"), row.names = FALSE)
logm("ALL DONE")
