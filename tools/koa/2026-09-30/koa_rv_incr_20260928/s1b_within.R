## s1b_within.R (R1 c1b). Planted vs natural contrast WITHIN a data source, for dDBH and dHT.
## (i) Record counts by source x origin x installation x plot.
## (ii) Covariate-adjusted ratio contrast. Every record is predicted with the reference (deployed-start) Eq. 4 in population-average
##      form with Planted set to 0 (the natural form), so size, competition, crown and BYI are accounted for by the fitted equation.
##      R_o = sum(obs annual) / sum(natural-form annual prediction) within origin and source, and the contrast is R_planted / R_natural.
##      The same contrast implied by the deployed calibrated system is sum(pred(Planted = 1) x k_planted) / sum(pred(Planted = 0) x k_natural)
##      over the same planted records, divided by 1 (natural records are predicted by the natural form times k_natural).
##      Intervals: 2,000 tree-cluster bootstrap resamples within source, stratified by origin, percentile. With a single planted
##      installation in DOFAW (and a single natural installation in PSP) an installation-cluster interval cannot be formed, so these
##      intervals are conditional on the installations present.
## (iii) Offset refit on DOFAW only: b1 to b6 and b8 held at the reference, b0 and b9 (level shift) free, then b0, b7, b9 free,
##      random b0 ~ 1 | Install, same weights and control as the reference.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
REF <- load_ref(); set.seed(20260928)
CT <- list(); CNT <- list(); OFF <- list()
for (resp in c("dDBH", "dHT")) {
  m0 <- REF[[resp]]; b <- fixef(m0); d <- prep(resp)
  d$records <- 1; CNT[[resp]] <- aggregate(records ~ Data + Install + Plot + org, data = d, FUN = sum)
  CNT[[resp]]$resp <- resp
  d0 <- d; d0$Planted <- 0; d1 <- d; d1$Planted <- 1
  p_nat <- predict(m0, newdata = d0, level = 0) / d$YIP * CFX[[resp]]
  p_pl <- predict(m0, newdata = d1, level = 0) / d$YIP * CFX[[resp]]
  kdep <- c(dDBH = c(natural = 0.40548, planted = 1.43606), dHT = c(natural = 0.51917, planted = 2.64739))
  kn <- kdep[[paste0(resp, ".natural")]]; kp <- kdep[[paste0(resp, ".planted")]]
  for (s in c("DOFAW", "PSP")) {
    i <- which(d$Data == s); x <- d[i, ]; pn <- p_nat[i]; pp <- p_pl[i]
    stat <- function(j) { xo <- x$org[j]; a <- x$ann[j]
      Rp <- sum(a[xo == "planted"]) / sum(pn[j][xo == "planted"]); Rn <- sum(a[xo == "natural"]) / sum(pn[j][xo == "natural"])
      imp <- sum(pp[j][xo == "planted"] * kp) / sum(pn[j][xo == "planted"] * kn)
      c(R_planted = Rp, R_natural = Rn, contrast_obs = Rp / Rn, contrast_implied_deployed = imp, obs_over_implied = (Rp / Rn) / imp) }
    est <- stat(seq_len(nrow(x)))
    trs <- split(seq_len(nrow(x)), paste(x$org, x$TreeID))
    tp <- names(trs)[startsWith(names(trs), "planted")]; tn <- names(trs)[startsWith(names(trs), "natural")]
    bs <- t(replicate(2000, { j <- unlist(trs[c(sample(tp, replace = TRUE), sample(tn, replace = TRUE))], use.names = FALSE); stat(j) }))
    ci <- apply(bs, 2, quantile, c(0.025, 0.975))
    CT[[paste(resp, s)]] <- data.frame(resp = resp, source = s, quantity = names(est), estimate = est, lo95_treeboot = ci[1, ], hi95_treeboot = ci[2, ],
      n_planted = sum(x$org == "planted"), n_natural = sum(x$org == "natural"),
      inst_planted = length(unique(x$Install[x$org == "planted"])), inst_natural = length(unique(x$Install[x$org == "natural"])),
      trees_planted = length(tp), trees_natural = length(tn), row.names = NULL)
  }
  ## (iii) offset refits on DOFAW
  x <- d[d$Data == "DOFAW", ]; x$InstID <- factor(x$InstID)
  B <- b
  gfix <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b7, b9)
    gr.hat3(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, B[["b1"]], B[["b2"]], B[["b3"]], B[["b4"]], B[["b5"]], B[["b6"]], b7, B[["b8"]], b9)
  gfix9 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b9)
    gfix(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, B[["b7"]], b9)
  assign("gfix", gfix, envir = globalenv()); assign("gfix9", gfix9, envir = globalenv()); assign("B", B, envir = globalenv())
  sz <- sizevar(resp)
  f9 <- as.formula(sprintf("%s ~ gfix9(%s, BAL.0, BAL.1, CR.0, CR.1, BAPH.0, BAPH.1, Planted, BYI, YIP, b0, b9)", resp, sz))
  f79 <- as.formula(sprintf("%s ~ gfix(%s, BAL.0, BAL.1, CR.0, CR.1, BAPH.0, BAPH.1, Planted, BYI, YIP, b0, b7, b9)", resp, sz))
  for (lab in c("b0_b9_free", "b0_b7_b9_free")) {
    m <- tryCatch(if (lab == "b0_b9_free") nlme(f9, data = x, fixed = b0 + b9 ~ 1, random = b0 ~ 1 | InstID, start = c(b[["b0"]], b[["b9"]]),
                        weights = varPower(0.2, form = ~DBH.0), control = ctl)
                  else nlme(f79, data = x, fixed = b0 + b7 + b9 ~ 1, random = b0 ~ 1 | InstID, start = c(b[["b0"]], b[["b7"]], b[["b9"]]),
                        weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) { logm(resp, lab, "ERROR", conditionMessage(e)); NULL })
    if (is.null(m)) next
    tt <- summary(m)$tTable
    OFF[[paste(resp, lab)]] <- data.frame(resp = resp, fit = lab, term = rownames(tt), estimate = tt[, 1], se = tt[, 2], p = tt[, ncol(tt)],
      ref_estimate = b[rownames(tt)], logLik = as.numeric(logLik(m)), n = nrow(x), row.names = NULL)
    logm(resp, lab, paste(rownames(tt), sprintf("%.4f (%.4f)", tt[, 1], tt[, 2]), collapse = "; "))
  }
}
CT <- do.call(rbind, CT); print(CT); write.csv(CT, file.path(OUT, "within_source_contrast.csv"), row.names = FALSE)
CNT <- do.call(rbind, CNT); write.csv(CNT[CNT$Data %in% c("DOFAW", "PSP"), ], file.path(OUT, "within_source_counts.csv"), row.names = FALSE)
print(CNT[CNT$Data == "DOFAW", ]); print(subset(CNT, Data == "PSP" & org == "natural"))
if (length(OFF)) { OFF <- do.call(rbind, OFF); print(OFF); write.csv(OFF, file.path(OUT, "within_dofaw_offset_fits.csv"), row.names = FALSE) }
logm("WITHIN DONE")
