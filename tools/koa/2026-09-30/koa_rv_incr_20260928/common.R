## common.R (koa_rv_incr_20260928). Shared setup for the R1 sensitivity analyses of the v102 increment equations (Eq. 4).
## Reuses, verbatim, the v102 fitting path of ~/jobs/koa_v102_20260918/track2/inc_refit.R and track3/inc/calib_v102.R:
## gr.hat2 body from origin_refit_REFERENCE_COPY.R, gr.hat3 (b9 = Planted level shift, rain/1000 term off), PSP Planted recoded from
## psp_origin_thinning_2026-09-16_DATA.csv, complete cases on the twelve model columns, random b0 ~ 1 | Data/Install,
## varPower(0.2, ~DBH.0), the same nlmeControl, and the deployed-start optimum (inc_fits.rda "V102 deployed_solution") as reference.
## Multipliers follow track3 calib_v102.R: k_o = sum(obs annual) / sum(level-0 annual prediction x CFX) within origin,
## CFX = 1.36869 (dDBH, v102 Duan factor) and 1.030 (dHT), so k is directly comparable to the engine CAL constants.
suppressPackageStartupMessages(library(nlme))
JOB <- file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928")
IN <- file.path(JOB, "inputs"); OUT <- file.path(JOB, "out")
src <- readLines(file.path(IN, "origin_refit_REFERENCE_COPY.R"))
eval(parse(text = src[grep("^gr.hat2 <- function", src):(grep("^fit_inc <- function", src) - 1)]))
ORIG <- read.csv(file.path(IN, "psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
## no-crown variant (item 5): b5 fixed at zero
gr.hat3nc <- function(d1, bal1, bal2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, 1, 1, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, 0, b6, b7, b8, 0)
ctl <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
CFX <- c(dDBH = 1.36869, dHT = 1.030)
MC <- c("DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")
TERMS <- paste0("b", 0:9)
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2)
rmse <- function(o, p) sqrt(mean((o - p)^2))
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
prep <- function(resp) {
  dat <- read.csv(file.path(IN, sprintf("%s_%s.csv", resp, get0("FRAME_TAG", ifnotfound = "v102"))), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(dat)) %in% c("lat", "lon", "latitude", "longitude")))
  keep <- complete.cases(dat[, c(resp, MC)])
  d <- dat[keep, ]; isp <- d$Data == "PSP"; d$Planted_deposit <- d$Planted
  d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  d$InstID <- paste(d$Data, d$Install, sep = "/"); d$TreeID <- paste(d$Data, d$Install, d$Plot, d$Tree, sep = "/")
  d$Data <- factor(d$Data); d$ann <- d[[resp]] / d$YIP; d$org <- ifelse(d$Planted == 1, "planted", "natural")
  d
}
sizevar <- function(resp) if (resp == "dDBH") "DBH.0" else "HT.0"
form3 <- function(resp, nocr = FALSE) {
  if (!nocr) as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, sizevar(resp)))
  else as.formula(sprintf("%s ~ gr.hat3nc(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b6, b7, b8, b9)", resp, sizevar(resp)))
}
## the reference fit, exactly as track2 fit3()
fit_ref <- function(resp, d, start) nlme(form3(resp), data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1,
  random = b0 ~ 1 | Data/Install, start = start, weights = varPower(0.2, form = ~DBH.0), control = ctl)
load_ref <- function() { e <- new.env(); load(file.path(IN, "inc_fits.rda"), envir = e)
  list(dDBH = e$FITS[["dDBH V102 deployed_solution"]], dHT = e$FITS[["dHT V102 deployed_solution"]],
       dDBH_recstart = e$FITS[["dDBH V102 record"]]) }
rec_start <- function(resp) { e <- new.env(); load(file.path(IN, sprintf("%s_BYI.rda", resp)), envir = e); c(fixef(e[[ls(e)[1]]]), b9 = 0) }
## multipliers, CF convention of track3 (CFX fixed), with installation cluster bootstrap (2,000, percentile) for the interval
kmult <- function(d, p0, resp, B = 2000, seed = 20260928) {
  pa <- p0 / d$YIP * CFX[[resp]]; org <- d$org
  k <- tapply(d$ann, org, sum) / tapply(pa, org, sum)
  set.seed(seed); cl <- d$InstID; ids <- unique(cl); sp <- split(seq_along(cl), cl)
  bs <- t(replicate(B, { s <- sample(ids, replace = TRUE); i <- unlist(sp[s], use.names = FALSE)
    x <- tapply(d$ann[i], org[i], sum) / tapply(pa[i], org[i], sum); x[names(k)] }))
  if (is.null(dim(bs))) bs <- matrix(bs, ncol = 1, dimnames = list(NULL, names(k)))
  ci <- apply(bs, 2, quantile, c(0.025, 0.975), na.rm = TRUE)
  cal <- pa * k[org]
  list(k = k, lo = ci[1, ], hi = ci[2, ], cal = cal, pa = pa, r2_cal = r2(d$ann, cal), rmse_cal = rmse(d$ann, cal))
}
vc_taus <- function(m) { vc <- VarCorr(m); v <- suppressWarnings(as.numeric(vc[grep("^b0$|\\(Intercept\\)", rownames(vc)), 1])); sqrt(v[is.finite(v)]) }
