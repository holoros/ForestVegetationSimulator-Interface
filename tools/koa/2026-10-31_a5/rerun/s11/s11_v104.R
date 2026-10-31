## a5/rerun/s11/s11_v104.R: Table S11 on the final frames and v104 system. Logic copied from koa_rv_incr_20260928/s1b_within.R
## (part ii, DOFAW and PSP) and s1c_kulani.R (Kulani 12 vs 23): every record predicted by Eq. 4 in population-average natural form
## (Planted = 0); R_o = sum(obs annual) / sum(natural-form annual prediction) within origin; observed contrast R_planted / R_natural;
## implied contrast of the applied system over the same planted records; 2,000 tree-cluster resamples stratified by origin, seed 20260928.
## Changes vs preliminary (inputs only): frames/final/<resp>_NO_v103_model.csv with live-list BAL (model_cols "l"), the deployed v104
## vectors dDBH_L_NO and dHT_L_NO (out/v104_constants.json), and the v104 origin constants, applied as in the v104 system
## (recursion-consistent: b0 + ln c_origin inside the annual recursion; inc_v103.R solve_c) in place of the v102 k x CF multiplier.
suppressPackageStartupMessages({ library(nlme); library(jsonlite) })
src <- readLines(path.expand("~/jobs/koa_v104_20261030/track2/inc/inc_v103.R")); commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112]))
K <- fromJSON(file.path(W, "out/v104_constants.json")); O <- file.path(W, "a5/rerun/s11")
res <- list(); set.seed(20260928)
for (resp in c("dDBH", "dHT")) {
  GUARD <- if (resp == "dDBH") 45 else 20; KK <- K[[toupper(resp)]]; b <- unlist(KK$coef)[paste0("b", 0:9)]
  cn <- KK$c_natural; cp <- KK$c_planted
  d <- model_cols(read.csv(file.path(FRD, sprintf("%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE), "l")
  ## gate: the constants re-solve on this frame (solve_c) to the deployed c
  cc <- solve_c(resp, d, b); logm(resp, "frame rows", nrow(d), "re-solved c", paste(round(cc, 6), collapse = " "), "deployed", round(cn, 6), round(cp, 6))
  d$org <- ifelse(d$Planted == 1, "planted", "natural"); d$ann <- d[[resp]] / d$YIP
  d0 <- d; d0$Planted <- 0; d1 <- d; d1$Planted <- 1
  bn <- b; bn["b0"] <- b["b0"] + log(cn); bp <- b; bp["b0"] <- b["b0"] + log(cp)
  pn <- pa_pred(resp, d0, b) / d$YIP                       # natural form, uncalibrated (CF and constants cancel in the ratio)
  pn_cal <- pa_pred(resp, d0, bn) / d$YIP; pp_cal <- pa_pred(resp, d1, bp) / d$YIP
  cmp <- list(DOFAW = which(d$Data == "DOFAW"), PSP = which(d$Data == "PSP"), `Kulani plot 12 against plot 23` = which(d$Data == "DOFAW" & d$Install == "Kulani"))
  for (s in names(cmp)) { i <- cmp[[s]]; x <- d[i, ]; a_pn <- pn[i]; a_nc <- pn_cal[i]; a_pc <- pp_cal[i]
    stat <- function(j) { xo <- x$org[j]; a <- x$ann[j]
      Rp <- sum(a[xo == "planted"]) / sum(a_pn[j][xo == "planted"]); Rn <- sum(a[xo == "natural"]) / sum(a_pn[j][xo == "natural"])
      imp <- sum(a_pc[j][xo == "planted"]) / sum(a_nc[j][xo == "planted"])
      c(R_planted = Rp, R_natural = Rn, contrast_obs = Rp / Rn, contrast_implied_v104 = imp, obs_over_implied = (Rp / Rn) / imp) }
    est <- stat(seq_len(nrow(x)))
    trs <- split(seq_len(nrow(x)), paste(x$org, x$TreeID)); tp <- names(trs)[startsWith(names(trs), "planted")]; tn <- names(trs)[startsWith(names(trs), "natural")]
    bs <- t(replicate(2000, stat(unlist(trs[c(sample(tp, replace = TRUE), sample(tn, replace = TRUE))], use.names = FALSE))))
    ci <- apply(bs, 2, quantile, c(0.025, 0.975), na.rm = TRUE)
    res[[paste(resp, s)]] <- data.frame(resp = resp, comparison = s, quantity = names(est), estimate = est, lo95_treeboot = ci[1, ], hi95_treeboot = ci[2, ],
      n_planted = sum(x$org == "planted"), n_natural = sum(x$org == "natural"), trees_planted = length(tp), trees_natural = length(tn),
      inst_planted = length(unique(x$Install[x$org == "planted"])), inst_natural = length(unique(x$Install[x$org == "natural"])), row.names = NULL)
    logm(resp, s, "obs", round(est[["contrast_obs"]], 3), "implied", round(est[["contrast_implied_v104"]], 3)) }
}
R <- do.call(rbind, res); write.csv(R, file.path(O, "tableS11_within_source_v104.csv"), row.names = FALSE); print(R, digits = 4); logm("S11 DONE")
