#!/usr/bin/env Rscript
## S2_multistart_S20.R -- koa_s20fix_20260927.
## Recomputes the REFIT columns of Supplemental Table S20 ("Multiplier, refit" = k_train_b and
## "Ratio, refit" = ratio_b of loso_v102.R) from the best-logLik solution of four starts per fold.
## Definitions are copied verbatim from the S20 producer (track3/inc/loso_v102.R, FRAME = V102):
##   obs = y / YIP; pa = fitted(full fit, level 0) / YIP * CFX
##   k_train_b = sum(obs[train, origin]) / sum(fitted(fold fit, level 0)/YIP*CFX [train, origin])
##   ratio_b   = sum(obs[held-out, origin]) / sum(predict(fold fit, held-out, level 0)/YIP*CFX * k_train_b)
##   bias_b    = mean(obs - pb * k_train_b) on held-out records of that origin
## The four starts are those of D_multistart.R (koa_loso_origin_20260926). No random numbers are used;
## the seed is set only for the record.
suppressPackageStartupMessages(library(nlme))
HOME <- Sys.getenv("HOME")
E2 <- file.path(HOME, "jobs/koa_v102_20260918/track2"); T3 <- file.path(HOME, "jobs/koa_v102_20260918/track3")
OUT <- file.path(HOME, "jobs/koa_s20fix_20260927/out")
SEED <- 20260926; set.seed(SEED)
CORES <- as.integer(Sys.getenv("CORES", "7"))
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
sl <- readLines(file.path(T3, "ref/origin_refit_REFERENCE_COPY.R"))
eval(parse(text = sl[grep("^gr.hat2 <- function", sl):(grep("^fit_inc <- function", sl) - 1)]))
ORIG <- read.csv(file.path(E2, "inc/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
ctl <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
CFX <- c(dDBH = 1.36869, dHT = 1.030)
load(file.path(E2, "inc/inc_fits.rda"))
DEPV <- list(dDBH = c(b0=-2.0972488, b1=0.3105931, b2=-0.0085285, b3=-0.0019684, b4=-0.2899832, b5=-0.2599003, b6=-0.0105114, b7=-0.0258191, b8=0.3108402, b9=0.4018344),
             dHT  = c(b0=-4.0426171, b1=0.9238575, b2=-0.1099897, b3=-0.0012181, b4=-0.0358816, b5=-1.5423408, b6=0.0486628, b7=-0.1196098, b8=0.2471449, b9=1.0236256))
ROWS <- list()
for (resp in c("dDBH", "dHT")) {
  e <- new.env(); load(file.path(E2, sprintf("inc/%s_BYI.rda", resp)), envir = e); pub <- c(fixef(e[[ls(e)[1]]]), b9 = 0)
  dat <- read.csv(file.path(E2, sprintf("inc/frames/V102/%s.csv", resp)), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(dat)) %in% c("lat", "lon", "latitude", "longitude")))
  keep <- complete.cases(dat[, c(resp, "DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")])
  d <- dat[keep, ]; isp <- d$Data == "PSP"; d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  m <- FITS[[paste(resp, "V102 deployed_solution")]]
  stopifnot(nrow(m$data) == nrow(d), all(abs(m$data[[resp]] - d[[resp]]) < 1e-9))
  STA <- list(published_record_DEP = DEPV[[resp]], published_b9zero = pub,
              deployed_fit_fixef = fixef(m),                                  # the S20 producer's single start
              record_fit_fixef = fixef(FITS[[paste(resp, "V102 record")]]))
  obs <- d[[resp]] / d$YIP; pa <- fitted(m, level = 0) / d$YIP * CFX[[resp]]
  org <- ifelse(d$Planted == 1, "planted", "natural"); src <- d$Data
  kf <- tapply(obs, org, sum) / tapply(pa, org, sum)
  jobs <- expand.grid(sh = unique(src), s = names(STA), stringsAsFactors = FALSE)
  res <- parallel::mclapply(seq_len(nrow(jobs)), function(r) {
    sh <- jobs$sh[r]; s <- jobs$s[r]; tr <- src != sh; te <- !tr
    mm <- tryCatch(nlme(f3, data = d[tr, ], fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install,
                        start = STA[[s]], weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(x) NULL)
    if (is.null(mm)) return(data.frame(resp = resp, held_source = sh, start = s, origin = NA, refit_ok = FALSE))
    ptr <- fitted(mm, level = 0) / d$YIP[tr] * CFX[[resp]]
    kb <- tapply(obs[tr], org[tr], sum) / tapply(ptr, org[tr], sum)
    pb <- predict(mm, newdata = d[te, ], level = 0) / d$YIP[te] * CFX[[resp]]
    do.call(rbind, lapply(unique(org[te]), function(o) {
      j <- org[te] == o; ob <- obs[te][j]
      data.frame(resp = resp, held_source = sh, start = s, origin = o, refit_ok = TRUE, n = sum(j), obs_mean = mean(ob),
                 logLik = as.numeric(logLik(mm)), numIter = mm$numIter,
                 k_train_b = if (o %in% names(kb)) kb[[o]] else NA,
                 bias_b = if (o %in% names(kb)) mean(ob - pb[j] * kb[[o]]) else NA,
                 ratio_b = if (o %in% names(kb)) sum(ob) / sum(pb[j] * kb[[o]]) else NA)
    }))
  }, mc.cores = CORES)
  ROWS[[resp]] <- do.call(rbind, res)
  logm("S2", resp, "done")
}
A <- do.call(rbind, ROWS)
A <- A[order(A$resp, A$held_source, A$origin, -A$logLik), ]
write.csv(A, file.path(OUT, "S2_all_starts.csv"), row.names = FALSE)
best <- do.call(rbind, lapply(split(A, list(A$resp, A$held_source, A$origin), drop = TRUE), function(x) {
  b <- x[which.max(x$logLik), ]
  b$logLik_spread <- max(x$logLik) - min(x$logLik)
  p <- x[x$start == "deployed_fit_fixef", ]
  b$producer_start_logLik <- p$logLik; b$producer_k_train_b <- p$k_train_b; b$producer_ratio_b <- p$ratio_b
  b }))
names(best)[names(best) == "start"] <- "best_start"
write.csv(best, file.path(OUT, "S2_S20_refit_best.csv"), row.names = FALSE)
print(best[, c("resp","held_source","origin","best_start","logLik","logLik_spread","k_train_b","ratio_b","producer_k_train_b","producer_ratio_b")], digits = 6)
logm("S2 DONE")
