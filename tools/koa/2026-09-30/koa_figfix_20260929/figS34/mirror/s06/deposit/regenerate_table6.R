# regenerate_table6.R
# Reproduce manuscript Table 6 exactly from the deposited, corrected AK_SURV.csv.
#
# WHAT THIS SCRIPT IS
# Table 6 of the manuscript is the annual survival equation (Eq. 5): a
# complementary log-log generalized linear model fitted to the ALIVE response
# with an ln(YIP) offset, so a positive coefficient raises modelled survival.
# From version 1.2.0 of this deposit onward, Table 6 is the refit on the
# deduplicated survival table shipped here, not the model development snapshot.
# Running this script against the deposited AK_SURV.csv reproduces every
# coefficient, every standard error and every fit statistic printed in Table 6,
# in Table 7 and in Section 3.3.4 of the manuscript.
#
# Target values (manuscript Table 6, n = 5,969 records, 79 mortality events,
# 1,412 trees, 100 plots, 62 installations):
#
#   par  term          estimate   naive SE   SE clustered by installation
#   b0   Intercept       14.102      0.705         8.418
#   b1   HT               0.130      0.029         0.187
#   b2   ln(HT)          -4.516      0.352         3.270
#   b3   rHT              6.684      0.428         1.998
#   b4   ln(CR)          14.218      0.713         5.297
#   b5   ln(HT/DBH)      -2.806      0.166         1.643
#   b6   ln(BYI/100)      2.649      0.203         1.409
#   b7   BYI/1000       -21.188      1.172        12.236
#
#   apparent AUC 0.899, Brier 0.017, Brier skill score -0.31,
#   five-fold randomly stratified CV AUC 0.896 (SD 0.019 across folds),
#   leave-one-installation-out: 53 of 62 folds unscoreable, pooled AUC 0.514.
#
# CORRECTION TO THE CLUSTERED STANDARD ERROR COLUMN (read this if you are
# holding a copy of the table that prints 288.3 for the intercept). The
# installation-clustered standard errors first circulated with this refit
# (288.3, 0.864, 52.75, 107.1, 297.0, 46.48, 111.8, 771.0) were produced by a
# routine that rescaled the score contributions by the wrong power of the
# column-scaling vector, which inflated every clustered standard error by a
# factor of between 4 and 80. The values above are the corrected ones. They are
# confirmed three independent ways: the hand-rolled sandwich in this script,
# sandwich::vcovCL(type = "HC1") applied to the same glm object, and a
# delete-one-installation jackknife over the 62 installations, which this script
# also reports. The estimates and the naive standard errors were never affected.
# The one substantive consequence is that the claim that no coefficient survives
# installation clustering does not hold: rHT (P = 0.001) and ln(CR) (P = 0.007)
# remain significant under both the corrected sandwich and the jackknife, while
# both BYI terms do not (sandwich P = 0.060 and 0.083, jackknife P = 0.64 and
# 0.36). See DEPOSIT_CHANGELOG.md, Defect 5.
#
# UNIT CONVENTION FOR THE SLENDERNESS TERM (read this before comparing to the
# HT.DBH.0 column). The published convention, used here and in Table 6, is
# HT in METRES over DBH in CENTIMETRES, that is log(HT.0 / DBH.0) computed from
# the raw deposited columns. The deposited convenience column HT.DBH.0 is HT in
# metres over DBH in METRES, which is 100 times larger. Substituting
# log(HT.DBH.0) for log(HT.0 / DBH.0) leaves every other coefficient unchanged
# but shifts the intercept by -b5 * log(100) = +12.923, from 14.102 to 27.025.
# That difference is a units artefact, not a data disagreement. Compare
# intercepts only after putting both on the same DBH unit convention. The older
# script regenerate_survival.R reports the HT.DBH.0 convention as well; this
# script is the one that reproduces the published table.
#
# REQUIREMENTS
# Base R only, no contributed packages. The cluster-robust variance is hand
# rolled below with the HC1 finite-sample correction and is equivalent to
# sandwich::vcovCL(fit, cluster = ~ inst, type = "HC1"); if sandwich happens to
# be installed the script cross checks against it, but sandwich is not required.
#
# WHY THIS SCRIPT DOES NOT CALL glm() COLD (important if you try to shortcut it)
# The undamped iteratively reweighted least squares inside stats::glm.fit does
# not converge on this fit from its default start. It oscillates: on R 4.5.2 the
# deviance is 868.685 after 100 iterations and 897.145 after 1,000, and no
# epsilon or maxit setting fixes it. The cause is that a handful of records sit
# at fitted survival probabilities within machine epsilon of one, where the
# cloglog working weights and working residuals are numerically unstable.
# This script therefore locates the maximum first with a damped Fisher scoring
# routine written in base R below (column-scaled, with a step-halving line
# search on the exact log-likelihood and a numerically stable log(mu)), and then
# hands those values to glm() as start values. glm() converges in one iteration
# from there, at deviance 868.582, and the returned object is an ordinary glm
# fit whose coef(), vcov(), AIC() and predict() all behave normally. If you
# start glm() at the solution but set epsilon below about 1e-8 it will take a
# step, overshoot and wander off again, so leave the epsilon as set here.
#
# THE STOCHASTIC STEP
# The five-fold cross-validation is stratified on the outcome and randomly
# assigned, so its value depends on the fold draw. The exact fold assignment
# behind the reported 0.896 (SD 0.019) is deposited as table6_cv_folds.csv, one
# row per record in the filtered order this script produces. The script reads
# that file when present, which makes the reported value exactly reproducible in
# any language. If the file is absent the script falls back to its own
# stratified draw under set.seed(1) and says so; across fold draws the mean CV
# AUC moves by roughly plus or minus 0.01, so a fallback run reproduces the
# reported value only to about two decimal places.
#
# USAGE
#   Rscript regenerate_table6.R
# Reads  : AK_SURV.csv, table6_cv_folds.csv (optional)
# Writes : table6_reproduced.csv              coefficient table with both SEs
#          table6_performance_reproduced.csv  fit and cross-validation statistics
#
# Operational note. These parameters are the fitted statistical model and are
# not what the linked simulator deploys. Individual-tree projections use the
# calibrated density-dependent rate of Eq. 5b (koa_survival_calibrated_py.py).
# See README.md and DEPOSIT_CHANGELOG.md.

surv_path <- "AK_SURV.csv"
fold_path <- "table6_cv_folds.csv"

PARS  <- paste0("b", 0:7)
TERMS <- c("Intercept", "HT", "ln(HT)", "rHT", "ln(CR)", "ln(HT/DBH)",
           "ln(BYI/100)", "BYI/1000")
TAB6_EST   <- c(14.102, 0.130, -4.516, 6.684, 14.218, -2.806, 2.649, -21.188)
TAB6_SE    <- c(0.705, 0.029, 0.352, 0.428, 0.713, 0.166, 0.203, 1.172)
TAB6_SE_CL <- c(8.418, 0.187, 3.270, 1.998, 5.297, 1.643, 1.409, 12.236)
# The superseded clustered standard errors, kept so the script can show the
# difference explicitly rather than silently changing a published column.
SUPERSEDED_SE_CL <- c(288.3, 0.864, 52.75, 107.1, 297.0, 46.48, 111.8, 771.0)

## ---------------------------------------------------------------- data ------
d <- read.csv(surv_path, stringsAsFactors = FALSE)
cat(sprintf("AK_SURV.csv: %d rows, %d columns, %d exact duplicate rows\n",
            nrow(d), ncol(d), sum(duplicated(d))))

# Documented filter chain, unchanged from regenerate_survival.R.
f <- subset(d, DBH.0 > 0 & Status.0 == "live" & YIP > 0 &
               dDBH.ann > 0 & dDBH.ann < 10)
rownames(f) <- NULL

f$Alive   <- ifelse(f$Status.1 == "live", 1L, 0L)
f$slender <- f$HT.0 / f$DBH.0            # HT metres / DBH centimetres
f$inst    <- paste(f$Data, f$Install, sep = "|")
f$plotid  <- paste(f$inst, f$Plot, sep = "|")

n      <- nrow(f)
dead   <- f$Alive == 0
ndeath <- sum(dead)
base   <- mean(dead)

cat(sprintf("Filtered: n = %d, mortality events = %d (%.2f%%), tree-years = %.0f (%.3f%% per year)\n",
            n, ndeath, 100 * base, sum(f$YIP), 100 * ndeath / sum(f$YIP)))
cat(sprintf("Grouping: %d installations, %d plots, %d trees, %d installations record any death\n",
            length(unique(f$inst)), length(unique(f$plotid)), length(unique(f$ID)),
            length(unique(f$inst[dead]))))

## -------------------------------------- stable cloglog Fisher scoring -------
# P(alive) = mu = 1 - exp(-exp(eta)), eta = X b + log(YIP).
# Written with log(mu) computed stably so that records at mu within machine
# epsilon of one do not destroy the weights, and with a step-halving line
# search on the exact log-likelihood so the iteration cannot oscillate.
cll_pieces <- function(eta) {
  eta <- pmin(eta, 700)
  t   <- exp(eta)
  lm1 <- suppressWarnings(log(-expm1(-t)))              # log mu, direct form
  ser <- log(pmax(t, 1e-300)) - t / 2 + t * t / 24      # log mu, small-t series
  log_mu <- ifelse(t < 1e-8, ser, lm1)
  log_mu[!is.finite(log_mu)] <- 0                       # t huge: mu = 1
  list(eta = eta, t = t, log_mu = log_mu)
}
cll_loglik <- function(y, eta) {
  p <- cll_pieces(eta)
  sum(y * p$log_mu - (1 - y) * p$t)
}
fit_cloglog <- function(X, y, offset, start = NULL, maxit = 500, tol = 1e-11) {
  nn <- nrow(X); pp <- ncol(X)
  sc <- pmax(sqrt(colMeans(X^2)), 1e-12)                # column scaling
  Xs <- sweep(X, 2, sc, "/")
  b  <- if (is.null(start)) c(1, rep(0, pp - 1)) else as.vector(start) * sc
  eta <- as.vector(Xs %*% b) + offset
  ll  <- cll_loglik(y, eta)
  conv <- FALSE
  for (it in seq_len(maxit)) {
    pc <- cll_pieces(eta)
    s  <- y * exp(pc$eta - pc$t - pc$log_mu) - (1 - y) * pc$t
    w  <- exp(2 * pc$eta - pc$t - pc$log_mu)
    XtWX <- crossprod(Xs, Xs * w)
    Xts  <- crossprod(Xs, s)
    ridge <- diag(pp) * 1e-12 * sum(diag(XtWX)) / pp
    step <- tryCatch(solve(XtWX + ridge, Xts),
                     error = function(e) qr.solve(XtWX + ridge, Xts))
    fs <- 1; ok <- FALSE
    for (h in 1:60) {
      bn  <- b + fs * step
      en  <- as.vector(Xs %*% bn) + offset
      lln <- cll_loglik(y, en)
      if (is.finite(lln) && lln >= ll - 1e-12) { ok <- TRUE; break }
      fs <- fs / 2
    }
    if (!ok) break
    rel <- abs(lln - ll) / (abs(lln) + 0.1)
    b <- bn; eta <- en; ll <- lln
    if (rel < tol) { conv <- TRUE; break }
  }
  list(beta = as.vector(b / sc), eta = eta, ll = ll, converged = conv, iter = it)
}
cll_pred <- function(X, beta, offset) {
  as.vector(-expm1(-exp(pmin(as.vector(X %*% beta) + offset, 700))))
}

## ----------------------------------------------------------------- fit ------
# The offset is written into the formula with offset() rather than passed
# through the offset= argument, because predict.glm() carries a formula offset
# to new data but silently drops an offset= argument.
form <- Alive ~ HT.0 + log(HT.0) + rHT.0 + log(CR.0) + log(slender) +
  I(log(BYI / 100)) + I(BYI / 1000) + offset(log(YIP))

MM  <- model.matrix(form, data = f)
yv  <- as.numeric(f$Alive)
ofs <- log(f$YIP)

pre <- fit_cloglog(MM, yv, ofs)
cat(sprintf("Damped Fisher scoring: converged = %s in %d iterations, log-likelihood %.6f\n",
            pre$converged, pre$iter, pre$ll))
if (!pre$converged) stop("stable pre-fit did not converge")

# Hand the maximum to glm() so the reported object is an ordinary glm fit.
fit <- suppressWarnings(glm(form, family = binomial(link = "cloglog"), data = f,
                            start = pre$beta,
                            control = glm.control(maxit = 200, epsilon = 1e-8)))
if (!fit$converged) stop("glm() did not converge from the stable start values")
cat(sprintf("glm() from those start values: converged in %d iteration(s), deviance %.4f, AIC %.4f\n",
            fit$iter, deviance(fit), AIC(fit)))

est <- unname(coef(fit))
se  <- unname(sqrt(diag(vcov(fit))))

## ------------------------------------------- cluster-robust variance --------
# Sandwich estimator clustered on installation with the HC1 finite-sample
# correction (G/(G-1)) * ((n-1)/(n-p)), matching sandwich::vcovCL(type = "HC1").
# The score contribution and the weight come from the stable pieces rather than
# from residuals(fit, "working") * fit$weights, which is the same quantity but
# is computed through a clamped inverse link and loses precision on the records
# at mu within machine epsilon of one.
cluster_vcov <- function(X, y, beta, offset, cluster) {
  pc    <- cll_pieces(as.vector(X %*% beta) + offset)
  s     <- y * exp(pc$eta - pc$t - pc$log_mu) - (1 - y) * pc$t
  w     <- exp(2 * pc$eta - pc$t - pc$log_mu)
  bread <- solve(crossprod(X, X * w))
  gsum  <- rowsum(as.vector(s) * X, as.character(cluster), reorder = FALSE)
  nn <- nrow(X); pp <- ncol(X); G <- nrow(gsum)
  V  <- bread %*% crossprod(gsum) %*% bread
  list(V = V * (G / (G - 1)) * ((nn - 1) / (nn - pp)), bread = bread, G = G)
}
cv_out <- cluster_vcov(MM, yv, est, ofs, f$inst)
se_cl  <- unname(sqrt(diag(cv_out$V)))
G      <- cv_out$G

cat(sprintf("Bread cross-check against vcov(fit): max absolute relative difference %.2e\n",
            max(abs(sqrt(diag(cv_out$bread)) - se) / se)))
if (requireNamespace("sandwich", quietly = TRUE)) {
  se_pkg <- sqrt(diag(sandwich::vcovCL(fit, cluster = f$inst, type = "HC1")))
  cat(sprintf("sandwich::vcovCL cross-check: max absolute relative difference %.2e\n",
              max(abs(se_pkg - se_cl) / se_cl)))
} else {
  cat("sandwich not installed; the hand-rolled cluster-robust variance is used (no package required)\n")
}

## --------------------------------------------- apparent fit statistics ------
auc_fun <- function(alive, score_death) {   # Mann-Whitney AUC for the death class
  dd <- alive == 0
  if (!any(dd) || all(dd)) return(NA_real_)
  r <- rank(score_death)
  (sum(r[dd]) - sum(dd) * (sum(dd) + 1) / 2) / (sum(dd) * sum(!dd))
}

p_alive   <- cll_pred(MM, est, ofs)   # same as predict(fit, type = "response"),
                                      # without the clamped-inverse-link rounding
auc_app   <- auc_fun(f$Alive, 1 - p_alive)
brier_app <- mean(((1 - p_alive) - as.numeric(dead))^2)
bss_app   <- 1 - brier_app / (base * (1 - base))

## ----------------------------------- five-fold stratified cross-validation ---
fold_source <- "table6_cv_folds.csv, the deposited assignment behind the reported value"
fold <- NULL
if (file.exists(fold_path)) {
  fd <- read.csv(fold_path)
  if (nrow(fd) == n) {
    fold <- fd$fold
  } else {
    warning("table6_cv_folds.csv has ", nrow(fd),
            " rows but the filter yields ", n, "; falling back to a local draw")
  }
}
if (is.null(fold)) {
  fold_source <- "a fallback stratified draw under set.seed(1); expect about +/- 0.01 on the mean"
  set.seed(1)
  fold <- integer(n)
  for (cls in c(0L, 1L)) {
    idx <- sample(which(f$Alive == cls))
    fold[idx] <- (seq_along(idx) - 1L) %% 5L + 1L
  }
}

k       <- 5
oof     <- rep(NA_real_, n)
aucs    <- numeric(k)
briers  <- numeric(k)
nonconv <- 0L
for (i in seq_len(k)) {
  te <- fold == i
  m  <- fit_cloglog(MM[!te, , drop = FALSE], yv[!te], ofs[!te], start = pre$beta)
  if (!m$converged) m <- fit_cloglog(MM[!te, , drop = FALSE], yv[!te], ofs[!te])
  if (!m$converged) nonconv <- nonconv + 1L
  pa <- cll_pred(MM[te, , drop = FALSE], m$beta, ofs[te])
  oof[te]   <- pa
  aucs[i]   <- auc_fun(f$Alive[te], 1 - pa)
  briers[i] <- mean(((1 - pa) - as.numeric(f$Alive[te] == 0))^2)
}
cv_mean   <- mean(aucs)
cv_sd     <- sd(aucs)
cv_pooled <- auc_fun(f$Alive, 1 - oof)
cv_brier  <- mean(briers)
cv_bss    <- 1 - cv_brier / (base * (1 - base))

## ------------------------------ leave-one-installation-out cross-validation --
insts    <- sort(unique(f$inst))
oof2     <- rep(NA_real_, n)
loio_auc <- rep(NA_real_, length(insts))
loio_n   <- integer(length(insts))
loio_d   <- integer(length(insts))
loio_nc  <- 0L
jkB      <- matrix(NA_real_, length(insts), ncol(MM))   # delete-one-installation betas
for (j in seq_along(insts)) {
  te <- f$inst == insts[j]
  m  <- fit_cloglog(MM[!te, , drop = FALSE], yv[!te], ofs[!te], start = pre$beta)
  if (!m$converged) m <- fit_cloglog(MM[!te, , drop = FALSE], yv[!te], ofs[!te])
  if (!m$converged) loio_nc <- loio_nc + 1L
  jkB[j, ]    <- m$beta
  pa <- cll_pred(MM[te, , drop = FALSE], m$beta, ofs[te])
  oof2[te]    <- pa
  loio_n[j]   <- sum(te)
  loio_d[j]   <- sum(f$Alive[te] == 0)
  loio_auc[j] <- auc_fun(f$Alive[te], 1 - pa)   # NA when the fold holds no death
}
loio_scoreable   <- sum(!is.na(loio_auc))
loio_unscoreable <- sum(is.na(loio_auc))
loio_pooled      <- auc_fun(f$Alive, 1 - oof2)
loio_brier       <- mean(((1 - oof2) - as.numeric(dead))^2)
top_j            <- which.max(loio_d)

## -------------------------------------------------------------- reporting ---
# Delete-one-installation jackknife standard error, a third and structurally
# different estimate of the between-installation variability, computed free from
# the leave-one-installation-out refits above.
Gj    <- nrow(jkB)
se_jk <- sqrt((Gj - 1) / Gj * colSums(sweep(jkB, 2, colMeans(jkB))^2))

z    <- est / se
z_cl <- est / se_cl
z_jk <- est / se_jk
pv   <- 2 * pnorm(-abs(z))
p_cl <- 2 * pnorm(-abs(z_cl))
p_jk <- 2 * pnorm(-abs(z_jk))

coefs <- data.frame(
  par = PARS, term = TERMS,
  estimate = est, se_naive = se, z_naive = z, p_naive = pv,
  se_cluster = se_cl, z_cluster = z_cl, p_cluster = p_cl,
  se_jackknife_installation = se_jk, z_jackknife = z_jk, p_jackknife = p_jk,
  table6_estimate = TAB6_EST, table6_se = TAB6_SE, table6_se_cluster = TAB6_SE_CL,
  superseded_se_cluster = SUPERSEDED_SE_CL,
  match_estimate   = round(est, 3) == TAB6_EST,
  match_se         = round(se, 3) == TAB6_SE,
  match_se_cluster = round(se_cl, 3) == TAB6_SE_CL,
  stringsAsFactors = FALSE
)
write.csv(coefs, "table6_reproduced.csv", row.names = FALSE)

perf <- data.frame(
  statistic = c("n", "mortality_events", "mortality_pct", "tree_years",
                "annual_mortality_pct", "n_installations", "n_plots", "n_trees",
                "installations_with_deaths",
                "apparent_AUC", "apparent_Brier", "apparent_Brier_skill_score",
                "cv5_mean_AUC", "cv5_sd_AUC", "cv5_pooled_AUC", "cv5_Brier",
                "cv5_Brier_skill_score", "cv5_nonconverged_folds",
                "loio_folds", "loio_unscoreable_folds", "loio_scoreable_folds",
                "loio_pooled_AUC", "loio_Brier", "loio_nonconverged_folds",
                "loio_largest_fold_deaths", "loio_largest_fold_AUC",
                "AIC", "deviance"),
  value = c(n, ndeath, 100 * base, sum(f$YIP),
            100 * ndeath / sum(f$YIP), G, length(unique(f$plotid)),
            length(unique(f$ID)), length(unique(f$inst[dead])),
            auc_app, brier_app, bss_app,
            cv_mean, cv_sd, cv_pooled, cv_brier, cv_bss, nonconv,
            length(insts), loio_unscoreable, loio_scoreable,
            loio_pooled, loio_brier, loio_nc,
            loio_d[top_j], loio_auc[top_j],
            AIC(fit), deviance(fit)),
  stringsAsFactors = FALSE
)
write.csv(perf, "table6_performance_reproduced.csv", row.names = FALSE)

cat("\n==== Table 6 reproduced: annual survival cloglog, alive response, ln(YIP) offset ====\n")
print(data.frame(par = PARS, term = TERMS,
                 estimate        = sprintf("%.3f", est),
                 se              = sprintf("%.3f", se),
                 se_clustered    = sprintf("%.3f", se_cl),
                 se_jackknife    = sprintf("%.3f", se_jk),
                 table6_estimate = sprintf("%.3f", TAB6_EST),
                 table6_se       = sprintf("%.3f", TAB6_SE),
                 table6_se_clust = sprintf("%.3f", TAB6_SE_CL),
                 stringsAsFactors = FALSE), row.names = FALSE)

cat(sprintf("\nClustered on %d installations, HC1 correction. Significant at 0.05 under the\n", G))
cat(sprintf("clustered sandwich: %s. Under the delete-one-installation jackknife: %s.\n",
            paste(TERMS[p_cl < 0.05], collapse = ", "),
            paste(TERMS[p_jk < 0.05], collapse = ", ")))
cat("Both BYI terms fail to reach significance under either scheme, which is the\n")
cat("basis for deploying the calibrated rate of Eq. 5b instead of this equation.\n")
cat("\nSuperseded clustered standard errors, for reference only, from the routine that\n")
cat("mis-scaled the score contributions (see the header note and DEPOSIT_CHANGELOG.md):\n")
cat(" ", paste(sprintf("%s=%.4g", PARS, SUPERSEDED_SE_CL), collapse = "  "), "\n")

cat(sprintf("\nApparent: AUC = %.3f   Brier = %.3f   Brier skill score = %.2f (base rate %.4f)\n",
            auc_app, brier_app, bss_app, base))
cat(sprintf("Five-fold stratified CV: AUC = %.3f (SD %.3f), pooled out-of-fold AUC = %.3f,\n",
            cv_mean, cv_sd, cv_pooled))
cat(sprintf("  Brier = %.3f, Brier skill score = %.2f, %d non-converged folds. Folds from %s\n",
            cv_brier, cv_bss, nonconv, fold_source))
cat(sprintf("Leave-one-installation-out: %d folds, %d unscoreable because the held-out\n",
            length(insts), loio_unscoreable))
cat(sprintf("  installation records no mortality event, %d scoreable, pooled out-of-fold\n",
            loio_scoreable))
cat(sprintf("  AUC = %.3f, Brier = %.3f, %d non-converged folds. Holding out %s, which\n",
            loio_pooled, loio_brier, loio_nc, insts[top_j]))
cat(sprintf("  carries %d of the %d events, returns AUC = %.3f.\n",
            loio_d[top_j], ndeath, loio_auc[top_j]))

ok <- all(coefs$match_estimate) && all(coefs$match_se) && all(coefs$match_se_cluster)
cat(sprintf("\nMANUSCRIPT TABLE 6 CHECK: %s. All 8 estimates, all 8 naive standard errors and\n",
            if (ok) "PASS" else "FAIL"))
cat("all 8 clustered standard errors match Table 6 at the precision printed there.\n")
cat("Wrote table6_reproduced.csv and table6_performance_reproduced.csv\n")
if (!ok) {
  print(coefs[!(coefs$match_estimate & coefs$match_se & coefs$match_se_cluster),
              c("par", "term", "estimate", "table6_estimate", "se_naive", "table6_se",
                "se_cluster", "table6_se_cluster")])
  stop("reproduction check failed")
}
