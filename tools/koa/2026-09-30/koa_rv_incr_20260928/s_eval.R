## s_eval.R. Prediction-level diagnostics that hold fitted coefficients fixed (intervals: 2,000 installation-cluster bootstrap
## resamples of the evaluation records, percentile, conditional on the fitted coefficients).
## A (R1 c5) BAL mismatch. Reference Eq. 4 evaluated with the deposited BAL (what it was fitted on), with the simulator's live-list
##   percentile BAL, and with conventional BAL; the conventional-BAL refit (sens_balconv) evaluated with conventional BAL. All in
##   population-average form x CFX x origin multiplier (deployed multipliers for the reference, refit multipliers for the refit).
##   Reported overall and by quintile of the simulator's live-list BAL at the start of the interval.
## B (R1 c4) Reference calibrated system scored by interval length class and origin (obs / pred ratio of summed annual increment).
## C (R1 c4) Multipliers the reference equation would carry if the non-positive increments the builder drops were counted.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
REF <- load_ref(); e <- new.env(); load(file.path(OUT, "sens_balconv_fits.rda"), envir = e); NEW <- e$FITS
KDEP <- list(dDBH = c(natural = 0.40548, planted = 1.43606), dHT = c(natural = 0.51917, planted = 2.64739))
set.seed(20260928)
bootr <- function(num, den, cl, B = 2000) { ids <- unique(cl); sp <- split(seq_along(cl), cl)
  est <- sum(num) / sum(den); bs <- replicate(B, { i <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE); sum(num[i]) / sum(den[i]) })
  c(est = est, lo = unname(quantile(bs, 0.025)), hi = unname(quantile(bs, 0.975))) }
A <- list(); Bt <- list(); Ct <- list()
for (resp in c("dDBH", "dHT")) {
  m0 <- REF[[resp]]; m1 <- NEW[[resp]]; d <- prep(resp)
  b <- read.csv(file.path(OUT, sprintf("bal_%s.csv", resp))); stopifnot(all(b$TreeID == d$TreeID))
  pr <- function(m, bal0, bal1) { x <- d; x$BAL.0 <- bal0; x$BAL.1 <- bal1; predict(m, newdata = x, level = 0) / d$YIP * CFX[[resp]] }
  kd <- KDEP[[resp]][d$org]
  pA <- pr(m0, d$BAL.0, d$BAL.1) * kd; pB <- pr(m0, b$BALl.0, b$BALl.1) * kd; pC <- pr(m0, b$BALc.0, b$BALc.1) * kd
  pN0 <- pr(m1, b$BALc.0, b$BALc.1); kn <- tapply(d$ann, d$org, sum) / tapply(pN0, d$org, sum); pN <- pN0 * kn[d$org]
  q <- cut(b$BALl.0, unique(quantile(b$BALl.0, 0:5 / 5)), include.lowest = TRUE, labels = FALSE)
  grp <- list(all = rep("all", nrow(d)), quintile = paste0("Q", q), origin = d$org)
  for (g in names(grp)) for (lv in sort(unique(grp[[g]]))) {
    i <- which(grp[[g]] == lv); cl <- d$InstID[i]
    row <- function(lab, num, den) { r <- bootr(num[i], den[i], cl); data.frame(resp = resp, group = g, level = lv, n = length(i),
      mean_BAL_dep = mean(d$BAL.0[i]), mean_BAL_live = mean(b$BALl.0[i]), mean_BAL_conv = mean(b$BALc.0[i]),
      quantity = lab, estimate = r[["est"]], lo95 = r[["lo"]], hi95 = r[["hi"]]) }
    A[[paste(resp, g, lv)]] <- rbind(
      row("obs / deployed eq with deposited BAL (fitting condition)", d$ann, pA),
      row("obs / deployed eq with live-list BAL (simulator tree-list path)", d$ann, pB),
      row("obs / deployed eq with conventional BAL (reuser)", d$ann, pC),
      row("obs / conventional-BAL refit with conventional BAL", d$ann, pN),
      row("deployed live-list / deployed deposited (prediction shift)", pB, pA),
      row("new conventional / deployed live-list (predicted increment ratio)", pN, pB))
  }
  ## B: by interval length
  ic <- cut(d$YIP, c(0, 1, 2, 5, 10, 60), labels = c("1 yr", "2 yr", "3-5 yr", "6-10 yr", ">10 yr"))
  for (o in c("natural", "planted")) for (lv in levels(ic)) { i <- which(d$org == o & ic == lv); if (length(i) < 5) next
    r <- bootr(d$ann[i], pA[i], d$InstID[i]); Bt[[paste(resp, o, lv)]] <- data.frame(resp = resp, origin = o, interval = lv, n = length(i),
      n_inst = length(unique(d$InstID[i])), obs_mean = mean(d$ann[i]), ratio_obs_pred = r[["est"]], lo95 = r[["lo"]], hi95 = r[["hi"]]) }
  ## C: non-positive restored
  FRAME_TAG <<- "nonpos"; dn <- prep(resp); FRAME_TAG <<- "v102"
  pn <- predict(m0, newdata = dn, level = 0) / dn$YIP * CFX[[resp]]
  for (o in c("natural", "planted")) { i <- which(dn$org == o)
    r_all <- bootr(dn$ann[i], pn[i], dn$InstID[i]); j <- i[dn$restored[i] == 0]; r_ret <- bootr(dn$ann[j], pn[j], dn$InstID[j])
    Ct[[paste(resp, o)]] <- data.frame(resp = resp, origin = o, n_frame = length(j), n_restored = sum(dn$restored[i] == 1),
      n_restored_nonpos = sum(dn$restored[i] == 1 & dn$ann[i] <= 0), k_frame = r_ret[["est"]], k_with_restored = r_all[["est"]],
      k_with_restored_lo = r_all[["lo"]], k_with_restored_hi = r_all[["hi"]], ratio = r_all[["est"]] / r_ret[["est"]]) }
}
A <- do.call(rbind, A); Bt <- do.call(rbind, Bt); Ct <- do.call(rbind, Ct)
write.csv(A, file.path(OUT, "eval_bal.csv"), row.names = FALSE); write.csv(Bt, file.path(OUT, "eval_interval.csv"), row.names = FALSE)
write.csv(Ct, file.path(OUT, "eval_nonpos_k.csv"), row.names = FALSE)
options(width = 220); print(A[, c(1:4, 7:11)], digits = 3); print(Bt, digits = 3); print(Ct, digits = 4)
logm("EVAL DONE")
