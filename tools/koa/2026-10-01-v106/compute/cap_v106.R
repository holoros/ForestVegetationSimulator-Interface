## cap_v106.R (koa v106, 2026-09-30). Task 8: share of dHT calibration-frame records at or above the 2 m/yr deployed cap.
## Deployed dHT vector and constants from out/v103_constants.json (DHT block, dHT_L_NO, live list percentile BAL).
## Covariates and prediction form copied from track2/inc/inc_v103.R (model_cols(d, "l"), gr.hat2g with GUARD 20 m, b9 folded into b0 for planted).
## Calibrated prediction = exp(lp) x c_origin, c = CF x CAL (koa_equations.LineageA.dHT: exp(lp) * CF_DHT * CAL_DHT[origin]).
suppressPackageStartupMessages(library(jsonlite))
W <- path.expand("~/jobs/koa_v103_20260930"); O <- file.path(W, "a3/pending/v106")
K <- fromJSON(file.path(W, "out/v103_constants.json"))$DHT
b <- unlist(K$coef); cc <- c(natural = K$c_natural, planted = K$c_planted); CAP <- 2.0; GUARD <- 20
stopifnot(abs(K$CF * K$CAL[1] - K$c_natural) < 1e-4, abs(K$CF * K$CAL[2] - K$c_planted) < 1e-4)
d <- read.csv(file.path(W, "frames/final/dHT_NO_v103_model.csv"), stringsAsFactors = FALSE)
n_no <- nrow(d); d <- d[!is.na(d$Origin), ]; n_cal <- nrow(d)
d$BALx.0 <- d$BALl.0; d$BALx.1 <- d$BALl.1; d$CRx.0 <- d$CRl.0; d$CRx.1 <- d$CRl.1
d <- d[complete.cases(d[, c("DBH.0", "HT.0", "BALx.0", "BALx.1", "CRx.0", "CRx.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")]) & d$BYI > 0 & d$CRx.0 > 0 & d$CRx.1 > 0, ]
n_used <- nrow(d)
lp <- function(ht, bal, cr, baph, pl, byi) b["b0"] + b["b9"] * pl + b["b1"] * log(ht + 1) + b["b2"] * ht + b["b3"] * bal^2 / log(ht + 5) + b["b4"] * log(bal + 1) +
  b["b5"] * log(cr) + b["b6"] * sqrt(baph * ht) + b["b7"] * pl * pmin(ht, GUARD) + b["b8"] * log(byi)
cm <- ifelse(d$Planted == 1, cc["planted"], cc["natural"])
## (i) first-year annual prediction at the t0 covariates
p0 <- exp(lp(d$HT.0, d$BALx.0, d$CRx.0, d$BAPH.0, d$Planted, d$BYI)) * cm
## (ii) period recursion of inc_v103.R (uncapped, as fitted and calibrated): every annual step, and the period mean
rec <- function() { n <- d$YIP; pd <- d$HT.0; bal <- d$BALx.0; ba <- d$BAPH.0; cr <- d$CRx.0; mx <- rep(0, nrow(d)); nstep <- rep(0, nrow(d)); ncap <- rep(0, nrow(d))
  for (i in 1:max(n)) { g <- exp(lp(pd, bal, cr, ba, d$Planted, d$BYI)) * cm; act <- i <= n
    mx <- ifelse(act, pmax(mx, g), mx); nstep <- nstep + act; ncap <- ncap + (act & g >= CAP)
    pd <- pd + ifelse(act, g, 0); bal <- bal + (d$BALx.1 - d$BALx.0) / n; cr <- cr + (d$CRx.1 - d$CRx.0) / n; ba <- ba + (d$BAPH.1 - d$BAPH.0) / n }
  list(per = pd - d$HT.0, mx = mx, nstep = nstep, ncap = ncap) }
r <- rec(); pm <- r$per / d$YIP
obs <- d$dHT / d$YIP
chk <- tapply(r$per, d$Planted, sum) / tapply(d$dHT, d$Planted, sum)   # solve_c identity: should be 1 on the frame c was solved on
org <- ifelse(d$Planted == 1, "planted", "natural")
sh <- function(x) tapply(x, org, function(v) c(n = length(v), n_at_cap = sum(v), share = mean(v)))
res <- list(source = "frames/final/dHT_NO_v103_model.csv, Origin non-missing; out/v103_constants.json DHT", n_NO = n_no, n_calibration = n_cal, n_used = n_used,
  n_by_origin = as.list(table(org)), coef = as.list(b), c = as.list(cc), CF = K$CF, CAL = K$CAL, cap = CAP,
  solve_c_check_sum_pred_over_sum_obs = as.list(chk),
  first_year_t0_ge_cap = lapply(sh(p0 >= CAP), as.list),
  period_mean_annual_ge_cap = lapply(sh(pm >= CAP), as.list),
  any_recursion_step_ge_cap = lapply(sh(r$mx >= CAP), as.list),
  recursion_tree_years_ge_cap = lapply(split(data.frame(s = r$nstep, c = r$ncap), org), function(z) list(tree_years = sum(z$s), at_cap = sum(z$c), share = sum(z$c) / sum(z$s))),
  observed_annual_ge_cap = lapply(sh(obs >= CAP), as.list),
  first_year_pred_quantiles = lapply(split(p0, org), function(v) as.list(quantile(v, c(0, .5, .9, .99, 1)))))
write_json(res, file.path(O, "cap_v106.json"), auto_unbox = TRUE, digits = 8, pretty = TRUE)
cat(toJSON(res, auto_unbox = TRUE, digits = 6, pretty = TRUE), "\n")
