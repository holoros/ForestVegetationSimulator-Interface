## loso_v102.R FRAME (track 3, 2026-09-18). loso.R of koa_origin_20260916 (leave one source out multiplier only and refit checks, source
## cluster bootstrap of k with 2,000 resamples, k by source within origin) with the same two changes as calib_v102.R. FRAME = RECORD reads the
## V3 fits of record (koa_origin_20260916/out/G_v3_fits.rda, read only), the record frames and CFX 1.48254 and is the gate against out/I_*.csv.
## FRAME = V102 takes the v102 vector of record from track2 inc/inc_fits.rda, starts every refit from it, and uses CFX dDBH 1.36869 so k is
## the engine multiplier. Outputs inc/out_<FRAME>/I_loso.csv, I_source_bootstrap.csv, I_k_by_source.csv.
suppressPackageStartupMessages(library(nlme))
set.seed(20260916)
FRAME <- commandArgs(trailingOnly = TRUE)[1]; stopifnot(FRAME %in% c("RECORD", "V102"))
T3 <- file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/track3"); E2 <- file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/track2")
source_lines <- readLines(file.path(T3, "ref/origin_refit_REFERENCE_COPY.R"))
eval(parse(text = source_lines[grep("^gr.hat2 <- function", source_lines):(grep("^fit_inc <- function", source_lines) - 1)]))
ORIG <- read.csv(file.path(E2, "inc/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
ctl <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
CFX <- if (FRAME == "RECORD") c(dDBH = 1.48254, dHT = 1.030) else c(dDBH = 1.36869, dHT = 1.030)
OUT <- file.path(Sys.getenv("HOME"), "jobs/koa_s20fix_20260927/out_repro"); dir.create(OUT, showWarnings = FALSE)
if (FRAME == "RECORD") load(file.path(Sys.getenv("HOME"), "jobs/koa_origin_20260916/out/G_v3_fits.rda")) else load(file.path(E2, "inc/inc_fits.rda"))
L <- list(); B <- list(); S <- list()
for (resp in c("dDBH", "dHT")) {
  e <- new.env(); load(file.path(E2, sprintf("inc/%s_BYI.rda", resp)), envir = e); b0 <- fixef(e[[ls(e)[1]]])
  dat <- read.csv(file.path(E2, sprintf("inc/frames/%s/%s.csv", FRAME, resp)), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(dat)) %in% c("lat", "lon", "latitude", "longitude")))
  keep <- complete.cases(dat[, c(resp, "DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")])
  d <- dat[keep, ]; isp <- d$Data == "PSP"; d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  m <- if (FRAME == "RECORD") (if (resp == "dDBH") dDBH.v3 else dHT.v3) else FITS[[paste(resp, "V102 deployed_solution")]]
  START <- if (FRAME == "RECORD") c(b0, b9 = 0) else fixef(m)
  stopifnot(nrow(m$data) == nrow(d), all(abs(m$data[[resp]] - d[[resp]]) < 1e-9))
  fit3 <- function(dd) nlme(f3, data = dd, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install,
                            start = START, weights = varPower(0.2, form = ~DBH.0), control = ctl)
  obs <- d[[resp]] / d$YIP; pa <- fitted(m, level = 0) / d$YIP * CFX[[resp]]
  org <- ifelse(d$Planted == 1, "planted", "natural"); src <- d$Data
  kf <- tapply(obs, org, sum) / tapply(pa, org, sum)
  S[[resp]] <- do.call(rbind, lapply(split(seq_along(obs), list(src, org), drop = TRUE), function(i)
    data.frame(resp = resp, source = src[i[1]], origin = org[i[1]], n = length(i), installations = length(unique(d$Install[i])),
               obs_mean = mean(obs[i]), k_within_source = sum(obs[i]) / sum(pa[i]), ratio_after_pooled_k = sum(obs[i]) / sum(pa[i] * kf[org[i[1]]]))))
  srcs <- unique(src)
  bs <- t(replicate(2000, { s <- sample(srcs, replace = TRUE); idx <- unlist(split(seq_along(src), src)[s], use.names = FALSE)
    kk <- tapply(obs[idx], org[idx], sum) / tapply(pa[idx], org[idx], sum); kk[c("natural", "planted")] }))
  B[[resp]] <- data.frame(resp = resp, origin = c("natural", "planted"), k = as.numeric(kf[c("natural", "planted")]),
                          src_lo95 = apply(bs, 2, quantile, 0.025, na.rm = TRUE), src_hi95 = apply(bs, 2, quantile, 0.975, na.rm = TRUE),
                          src_na_share = apply(is.na(bs), 2, mean), row.names = NULL)
  out <- parallel::mclapply(srcs, function(sh) {
    tr <- src != sh; te <- !tr
    ka <- tapply(obs[tr], org[tr], sum) / tapply(pa[tr], org[tr], sum)
    mm <- tryCatch(fit3(d[tr, ]), error = function(x) NULL)
    kb <- pb <- NULL
    if (!is.null(mm)) {
      ptr <- fitted(mm, level = 0) / d$YIP[tr] * CFX[[resp]]
      kb <- tapply(obs[tr], org[tr], sum) / tapply(ptr, org[tr], sum)
      pb <- predict(mm, newdata = d[te, ], level = 0) / d$YIP[te] * CFX[[resp]]
    }
    do.call(rbind, lapply(unique(org[te]), function(o) {
      j <- org[te] == o; ob <- obs[te][j]
      pa_te <- pa[te][j]
      data.frame(resp = resp, held_source = sh, origin = o, n = sum(j), obs_mean = mean(ob),
                 k_full = kf[[o]], k_train_a = if (o %in% names(ka)) ka[[o]] else NA,
                 bias_full_cal = mean(ob - pa_te * kf[[o]]),
                 bias_a = if (o %in% names(ka)) mean(ob - pa_te * ka[[o]]) else NA,
                 ratio_a = if (o %in% names(ka)) sum(ob) / sum(pa_te * ka[[o]]) else NA,
                 refit_ok = !is.null(mm),
                 k_train_b = if (!is.null(kb) && o %in% names(kb)) kb[[o]] else NA,
                 bias_b = if (!is.null(kb) && o %in% names(kb)) mean(ob - pb[j] * kb[[o]]) else NA,
                 ratio_b = if (!is.null(kb) && o %in% names(kb)) sum(ob) / sum(pb[j] * kb[[o]]) else NA,
                 train_n_origin = sum(org[tr] == o))
    }))
  }, mc.cores = 4)
  L[[resp]] <- do.call(rbind, out)
  print(S[[resp]]); print(B[[resp]]); print(L[[resp]]); gc()
}
write.csv(do.call(rbind, L), file.path(OUT, "I_loso.csv"), row.names = FALSE)
write.csv(do.call(rbind, B), file.path(OUT, "I_source_bootstrap.csv"), row.names = FALSE)
write.csv(do.call(rbind, S), file.path(OUT, "I_k_by_source.csv"), row.names = FALSE)
cat("LOSO DONE", FRAME, "\n")
