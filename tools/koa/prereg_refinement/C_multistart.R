#!/usr/bin/env Rscript
## D_multistart.R -- PREREG-KOA-01 variant C, addendum.
## The v102 dDBH increment fit has TWO local optima (inc_stats.csv: logLik -9450.63 from the
## deployed-solution start, -9453.74 from the record start) whose origin multipliers differ by
## a factor of ~2 in the ratio. loso_v102.R (the Supplemental Table S20 producer) restarts every
## fold refit from ONE of them, so its refit column can compare optima rather than folds.
## This stage refits each leave-one-source-out fold from THREE starts and keeps the best logLik,
## then bootstraps k at the installation-cluster level conditional on that best fit.
suppressPackageStartupMessages(library(nlme))
HOME <- Sys.getenv("HOME")
E2 <- file.path(HOME, "jobs/koa_v102_20260918/track2"); T3 <- file.path(HOME, "jobs/koa_v102_20260918/track3")
OUT <- file.path(HOME, "jobs/koa_loso_origin_20260926/out")
SEED <- 20260926; NB <- as.integer(Sys.getenv("NB", "5000")); CORES <- as.integer(Sys.getenv("CORES", "6"))
set.seed(SEED)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
sl <- readLines(file.path(T3, "ref/origin_refit_REFERENCE_COPY.R"))
eval(parse(text = sl[grep("^gr.hat2 <- function", sl):(grep("^fit_inc <- function", sl) - 1)]))
ORIG <- read.csv(file.path(E2, "inc/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0,b1,b2,b3,b4,b5,b6,b7,b8,b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9*Planted, b1,b2,b3,b4,b5,b6,b7,b8, 0)
ctl <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
CFX <- c(dDBH = 1.36869, dHT = 1.030)
MC <- c("DBH.0","HT.0","BAL.0","BAL.1","CR.0","CR.1","BAPH.0","BAPH.1","Planted","BYI","YIP")
load(file.path(E2, "inc/inc_fits.rda"))
kof <- function(o, p, g) { r <- tapply(o, g, sum)/tapply(p, g, sum)
  c(natural = if ("natural" %in% names(r)) as.numeric(r[["natural"]]) else NA_real_,
    planted = if ("planted" %in% names(r)) as.numeric(r[["planted"]]) else NA_real_) }
qs <- function(x) { x <- x[is.finite(x)]; if (!length(x)) c(NA_real_, NA_real_) else as.numeric(quantile(x, c(0.025, 0.975))) }
bootk <- function(o, p, g, cl, B) { sp <- split(seq_along(cl), cl); ids <- names(sp)
  res <- matrix(NA_real_, B, 2, dimnames = list(NULL, c("natural","planted")))
  for (b in seq_len(B)) { idx <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE); res[b, ] <- kof(o[idx], p[idx], g[idx]) }; res }

DEPV <- list(dDBH = c(b0=-2.0972488, b1=0.3105931, b2=-0.0085285, b3=-0.0019684, b4=-0.2899832, b5=-0.2599003, b6=-0.0105114, b7=-0.0258191, b8=0.3108402, b9=0.4018344),
             dHT  = c(b0=-4.0426171, b1=0.9238575, b2=-0.1099897, b3=-0.0012181, b4=-0.0358816, b5=-1.5423408, b6=0.0486628, b7=-0.1196098, b8=0.2471449, b9=1.0236256))
ALL <- list(); STARTS_TAB <- list()
for (resp in c("dDBH","dHT")) {
  dat <- read.csv(file.path(E2, sprintf("inc/frames/V102/%s.csv", resp)), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(dat)) %in% c("lat","lon","latitude","longitude")))
  d <- dat[complete.cases(dat[, c(resp, MC)]), ]
  isp <- d$Data == "PSP"; d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  e <- new.env(); load(file.path(E2, sprintf("inc/%s_BYI.rda", resp)), envir = e); pub <- c(fixef(e[[ls(e)[1]]]), b9 = 0)
  STA <- list(published_record_DEP = DEPV[[resp]],
              published_b9zero     = pub,
              deployed_fit_fixef   = fixef(FITS[[paste(resp, "V102 deployed_solution")]]),
              record_fit_fixef     = fixef(FITS[[paste(resp, "V102 record")]]))
  folds <- c("NONE", sort(unique(d$Data)))
  for (fold in folds) {
    tr <- if (fold == "NONE") rep(TRUE, nrow(d)) else d$Data != fold
    dd <- d[tr, ]
    fits <- parallel::mclapply(names(STA), function(s) {
      mm <- tryCatch(nlme(f3, data = dd, fixed = b0+b1+b2+b3+b4+b5+b6+b7+b8+b9 ~ 1, random = b0 ~ 1 | Data/Install,
                          start = STA[[s]], weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(x) NULL)
      if (is.null(mm)) return(NULL)
      o <- dd[[resp]]/dd$YIP; p <- fitted(mm, level = 0)/dd$YIP * CFX[[resp]]
      g <- ifelse(dd$Planted == 1, "planted", "natural")
      list(start = s, logLik = as.numeric(logLik(mm)), k = kof(o, p, g), p = p, g = g, numIter = mm$numIter)
    }, mc.cores = min(4, CORES))
    ok <- Filter(Negate(is.null), fits)
    if (!length(ok)) { logm("D", resp, fold, "ALL STARTS FAILED"); next }
    for (f in ok) STARTS_TAB[[paste(resp, fold, f$start)]] <- data.frame(resp = resp, held_source = fold, start = f$start,
      logLik = f$logLik, numIter = f$numIter, k_natural = f$k[["natural"]], k_planted = f$k[["planted"]],
      ratio = f$k[["planted"]]/f$k[["natural"]], row.names = NULL)
    best <- ok[[which.max(vapply(ok, function(f) f$logLik, 0))]]
    o <- dd[[resp]]/dd$YIP; cl <- paste(dd$Data, dd$Install)
    set.seed(SEED); bs <- bootk(o, best$p, best$g, cl, NB)
    rat <- bs[,"planted"]/bs[,"natural"]; cn <- qs(bs[,"natural"]); cp <- qs(bs[,"planted"]); cr <- qs(rat)
    ALL[[paste(resp, fold)]] <- data.frame(resp = resp, held_source = fold, variant = "D_multistart_refit",
      interval = "installation cluster, unstratified, best-logLik fold refit held fixed",
      best_start = best$start, logLik = best$logLik,
      logLik_spread_across_starts = max(vapply(ok, function(f) f$logLik, 0)) - min(vapply(ok, function(f) f$logLik, 0)),
      k_natural = best$k[["natural"]], nat_lo95 = cn[1], nat_hi95 = cn[2],
      k_planted = best$k[["planted"]], plt_lo95 = cp[1], plt_hi95 = cp[2],
      ratio_plt_nat = best$k[["planted"]]/best$k[["natural"]], ratio_lo95 = cr[1], ratio_hi95 = cr[2],
      p_ratio_le_1 = mean(rat[is.finite(rat)] <= 1),
      intervals_overlap = if (any(is.na(c(cn, cp)))) NA else (max(cn[1], cp[1]) <= min(cn[2], cp[2])),
      n_clusters_nat = length(unique(cl[best$g == "natural"])), n_clusters_plt = length(unique(cl[best$g == "planted"])),
      n_rec_nat = sum(best$g == "natural"), n_rec_plt = sum(best$g == "planted"), B = NB, row.names = NULL)
    logm("D", resp, fold, "best", best$start, sprintf("logLik %.2f k_nat %.4f [%.4f, %.4f] k_plt %.4f [%.4f, %.4f] ratio %.2f [%.2f, %.2f]",
      best$logLik, best$k[["natural"]], cn[1], cn[2], best$k[["planted"]], cp[1], cp[2], best$k[["planted"]]/best$k[["natural"]], cr[1], cr[2]))
    write.csv(do.call(rbind, ALL), file.path(OUT, "C4_loso_multistart.csv"), row.names = FALSE)
    write.csv(do.call(rbind, STARTS_TAB), file.path(OUT, "C5_start_sensitivity.csv"), row.names = FALSE)
  }
}
write.csv(do.call(rbind, ALL), file.path(OUT, "C4_loso_multistart.csv"), row.names = FALSE)
write.csv(do.call(rbind, STARTS_TAB), file.path(OUT, "C5_start_sensitivity.csv"), row.names = FALSE)
logm("D DONE")
