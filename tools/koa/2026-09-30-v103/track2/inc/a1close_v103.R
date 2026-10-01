#!/usr/bin/env Rscript
## a1close_v103.R (koa v103 Stage A1 close-out, 2026-09-30). Aaron's decision: deploy the v102 dDBH vector with its origin constants re-solved
## on the v103 frame. Gate first: the vector must score as reported under an ENGINE-COMPUTABLE BAL definition (l live list percentile, which is
## what the engine's "percentile" path computes on a live simulated list, or c conventional), not only under d (dead-inclusive percentile).
## Eligibility is the preregistered one (signs, equivalence on CS and NO at 0.25, NO size max |obs/pred - 1| <= 0.25 to 60 cm).
## Then: 400 resample installation-cluster bootstrap (within source) of the re-solved constants c_natural, c_planted on the deploy frame
## (vector fixed, constants re-solved each draw), SE of log c. Writes out/inc/a1close_*.csv. No coordinates read.
suppressPackageStartupMessages({ library(parallel); library(nlme) })
set.seed(20260930)
W <- path.expand("~/jobs/koa_v103_20260930"); OUT <- file.path(W, "out/inc")
src <- readLines(file.path(W, "track2/inc/inc_v103.R"))
i0 <- grep("^HCB_P <- c\\(", src)[1]; i1 <- grep("^taus <- function", src)[1]
e <- new.env(); eval(parse(text = src[i0:i1]), envir = e)   # engine HCB, recursion, solve_c, score, eq_boot, START
attach(e, warn.conflicts = FALSE)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
rd <- function(resp, fr) { d <- read.csv(file.path(W, sprintf("frames/final/%s_%s_v103_model.csv", resp, fr)), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
  d$icls <- factor(d$icls, levels = c("1-2", "3-5", "6-10", "11-20", "21+")); d }
FR <- list(); for (resp in c("dDBH", "dHT")) for (fr in c("CS", "NO")) FR[[paste(resp, fr)]] <- rd(resp, fr)
SIGN <- list(dDBH = function(b) all(b[["b1"]] > 0, b[["b4"]] < 0, b[["b5"]] > 0, b[["b6"]] < 0), dHT = function(b) all(b[["b1"]] > 0, b[["b4"]] < 0))
rows <- list(); strata <- list(); CC <- list()
for (resp in c("dDBH", "dHT")) for (b in c("d", "l", "c")) {
  assign("GUARD", if (resp == "dDBH") 45 else 20, envir = e)
  vec <- START[[resp]]; eqs <- list(); ev <- list(); ccs <- list()
  for (fr in c("CS", "NO")) { de <- model_cols(FR[[paste(resp, fr)]], b); cc <- solve_c(resp, de, vec); ccs[[fr]] <- cc
    sc <- score(resp, de, vec, cc, sprintf("%s_V102recal_%s_%s", resp, b, fr)); eqs[[fr]] <- sc$equiv; ev[[fr]] <- sc$strata; strata[[paste(resp, b, fr)]] <- sc$strata }
  szlev <- if (resp == "dDBH") c("0-5", "5-10", "10-20", "20-30", "30-40", "40-60") else c("0-5", "5-10", "10-15", "15-20", "20-30")
  szr <- ev$NO[ev$NO$strat == "size" & ev$NO$level %in% szlev, ]
  r <- data.frame(resp = resp, bal = b, sign_pass = SIGN[[resp]](vec),
    eq_int_CS = eqs$CS$min_region_int, eq_slope_CS = eqs$CS$min_region_slope, eq_int_NO = eqs$NO$min_region_int, eq_slope_NO = eqs$NO$min_region_slope,
    slope_CS = eqs$CS$slope, slope_NO = eqs$NO$slope,
    size_max_dev_NO = max(abs(szr$ratio - 1)), size_worst = szr$level[which.max(abs(szr$ratio - 1))], size_ratios_NO = paste(sprintf("%s:%.3f", szr$level, szr$ratio), collapse = " "),
    rmse_CS = ev$CS$rmse_ann[ev$CS$strat == "all"], rmse_NO = ev$NO$rmse_ann[ev$NO$strat == "all"], n_NO = ev$NO$n[ev$NO$strat == "all"],
    c_nat_CS = ccs$CS[["natural"]], c_pl_CS = ccs$CS[["planted"]], c_nat_NO = ccs$NO[["natural"]], c_pl_NO = ccs$NO[["planted"]])
  r$equiv_pass_both <- max(r$eq_int_CS, r$eq_slope_CS, r$eq_int_NO, r$eq_slope_NO) <= 0.25
  r$eligible <- r$sign_pass & r$equiv_pass_both & r$size_max_dev_NO <= 0.25
  rows[[paste(resp, b)]] <- r; CC[[paste(resp, b)]] <- ccs
  logm("SCORE", resp, "v102 vector under BAL", b, "| eq CS", round(r$eq_int_CS, 4), round(r$eq_slope_CS, 4), "NO", round(r$eq_int_NO, 4), round(r$eq_slope_NO, 4),
       "| size max", round(r$size_max_dev_NO, 3), r$size_worst, "| RMSE NO", round(r$rmse_NO, 4), "| c NO", round(r$c_nat_NO, 4), round(r$c_pl_NO, 4), "| eligible", r$eligible)
}
S <- do.call(rbind, rows); write.csv(S, file.path(OUT, "a1close_v102vector_by_bal.csv"), row.names = FALSE)
write.csv(do.call(rbind, strata), file.path(OUT, "a1close_v102vector_strata.csv"), row.names = FALSE)
## reproduction of the reported d benchmark (STAGE1_REPORT: CS 0.1807/0.1318, NO 0.1811/0.1390, NO size max 0.184 at 40-60)
dd <- S[S$resp == "dDBH" & S$bal == "d", ]
logm("REPRO d benchmark: eq NO int", round(dd$eq_int_NO, 4), "(reported 0.1811) slope", round(dd$eq_slope_NO, 4), "(0.1390); size max", round(dd$size_max_dev_NO, 3), "(0.184)")
## GATE: engine-computable definition
okl <- S$eligible[S$resp == "dDBH" & S$bal == "l"]; okc <- S$eligible[S$resp == "dDBH" & S$bal == "c"]
logm("GATE engine-computable BAL for the v102 dDBH vector: l", okl, "c", okc)
if (!okl && !okc) { logm("STOP: v102 dDBH vector passes only under the dead-inclusive percentile"); quit(save = "no", status = 4) }
BD <- if (okl) "l" else "c"
cat(BD, file = file.path(OUT, "a1close_bal_choice.txt"))
logm("deploy BAL definition", BD, if (BD == "l") "(consistent with dHT_L_NO)" else "(INCONSISTENT with dHT_L_NO, report)")
## ---- bootstrap of the re-solved constants, NO frame (the deploy frame of dHT_L_NO), vector fixed
B <- 400; NC <- 4
boot_c <- function(resp, b, vec) {
  assign("GUARD", if (resp == "dDBH") 45 else 20, envir = e)
  d <- model_cols(FR[[paste(resp, "NO")]], b); d$inst <- paste(d$Data, d$Install)
  sp <- split(seq_len(nrow(d)), d$inst); src_of <- tapply(d$Data, d$inst, function(x) x[1]); ids_by_src <- split(names(sp), src_of[names(sp)])
  one <- function(i) { set.seed(20260930 + i); assign("GUARD", if (resp == "dDBH") 45 else 20, envir = e)
    ids <- unlist(lapply(ids_by_src, function(v) sample(v, length(v), replace = TRUE)), use.names = FALSE)
    dd <- d[unlist(lapply(ids, function(k) sp[[k]]), use.names = FALSE), ]
    cc <- tryCatch(solve_c(resp, dd, vec), error = function(err) c(natural = NA, planted = NA))
    data.frame(draw = i, c_natural = cc[["natural"]], c_planted = cc[["planted"]]) }
  do.call(rbind, mclapply(seq_len(B), one, mc.cores = NC)) }
t0 <- Sys.time(); BT <- boot_c("dDBH", BD, START$dDBH); BT$fit <- paste0("dDBH_V102recal_", BD, "_NO")
write.csv(BT, file.path(OUT, "boot_v103_dDBH_v102recal.csv"), row.names = FALSE)
est <- CC[[paste("dDBH", BD)]]$NO
SUM <- data.frame(fit = BT$fit[1], term = c("c_natural", "c_planted"), estimate = c(est[["natural"]], est[["planted"]]),
  boot_se = c(sd(BT$c_natural, na.rm = TRUE), sd(BT$c_planted, na.rm = TRUE)),
  lo95 = c(quantile(BT$c_natural, 0.025, na.rm = TRUE), quantile(BT$c_planted, 0.025, na.rm = TRUE)),
  hi95 = c(quantile(BT$c_natural, 0.975, na.rm = TRUE), quantile(BT$c_planted, 0.975, na.rm = TRUE)),
  se_log = c(sd(log(BT$c_natural), na.rm = TRUE), sd(log(BT$c_planted), na.rm = TRUE)),
  n_ok = c(sum(is.finite(BT$c_natural)), sum(is.finite(BT$c_planted))), B = B)
write.csv(SUM, file.path(OUT, "boot_v103_dDBH_summary.csv"), row.names = FALSE); print(SUM)
logm("BOOT dDBH v102recal done", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
## dHT: the deployed dHT_L_NO bootstrap refit the vector (boot_v103_dHT_summary.csv); also re-solve-only SE for comparability
BH <- boot_c("dHT", "l", { load(file.path(OUT, "fits_v103.rda")); CAL[["dHT_L_NO"]]$b }); write.csv(BH, file.path(OUT, "boot_v103_dHT_resolveonly.csv"), row.names = FALSE)
logm("dHT re-solve-only SE log c:", round(sd(log(BH$c_natural), na.rm = TRUE), 4), round(sd(log(BH$c_planted), na.rm = TRUE), 4))
logm("A1CLOSE DONE")
