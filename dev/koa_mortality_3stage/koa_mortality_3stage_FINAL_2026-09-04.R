#!/usr/bin/env Rscript
# =============================================================================
# koa_mortality_3stage_FINAL_2026-09-04.R
# Three-stage mortality for Acacia koa FVS-HI, evaluated against the deployed
# density ramp (Eq. 5b of record).
#   Stage 1  plot-level occurrence of an irregular mortality event (logistic)
#   Stage 2  regular stand-level survival, Garcia (2009) dN/dH form fitted on the
#            survivor cohort (ingrowth excluded) of regular intervals, compared
#            with a cloglog(ln SDI) plot-pair GLM, a constant rate, and the ramp
#   Stage 3  within-plot ordering of deaths by relative size (c-index)
# Data: AK_TREE.csv and AK_PLT.csv (Zenodo deposit 1.4.0 copies). Base R only.
# Author: Claude for Aaron Weiskittel. Seed 20260904. Headless.
# Run:  Rscript koa_mortality_3stage_FINAL_2026-09-04.R  [B_boot]
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
B_BOOT <- if (length(args) >= 1) as.integer(args[1]) else 2000
set.seed(20260904)
OUT <- "output"; dir.create(OUT, showWarnings = FALSE)
elog <- file.path(OUT, "error_log.txt")
safely <- function(expr, label) tryCatch(expr, error = function(e) {
  cat(sprintf("[%s] %s: %s\n", format(Sys.time()), label, conditionMessage(e)), file = elog, append = TRUE); NULL })
IRREG_THRESHOLD <- 0.10   # annual cohort mortality fraction above which an interval is irregular
EQ_REGION_B0 <- 0.25; EQ_REGION_B1 <- 0.25   # region of equivalence, convention (Robinson and Froese 2004)

# ---- 1. Data and survivor-cohort pair table -----------------------------------
tree <- read.csv("AK_TREE.csv", stringsAsFactors = FALSE)
plt  <- read.csv("AK_PLT.csv",  stringsAsFactors = FALSE)
tree$key <- paste(tree$Data, tree$Install, tree$Plot, sep = "|")
plt$key  <- paste(plt$Data,  plt$Install,  plt$Plot,  sep = "|")
stopifnot(all(tree$SPP == "AK"))            # gate: koa only, N is koa density
# F5 magnitude gate: plausible tree count and plot count
stopifnot(nrow(tree) > 10000, nrow(tree) < 100000, length(unique(tree$key)) > 100)

h40 <- function(d) {                       # EXPF-weighted mean height of the 40 largest DBH per ha
  d <- d[d$Status == "live" & d$DBH > 0 & !is.na(d$HT) & d$HT > 0 & d$EXPF > 0, ]
  if (nrow(d) == 0) return(NA_real_)
  d <- d[order(-d$DBH), ]; ce <- cumsum(d$EXPF); w <- d$EXPF
  ov <- which(ce > 40)
  if (length(ov)) { i <- ov[1]; w[i] <- max(40 - (if (i > 1) ce[i - 1] else 0), 0); if (i < length(w)) w[(i + 1):length(w)] <- 0 }
  if (sum(w) == 0) return(NA_real_)
  sum(d$HT * w) / sum(w)
}
lastlive <- aggregate(Measure ~ key + Tree, data = tree[tree$Status == "live", ], FUN = max)
names(lastlive)[3] <- "lastlive"
rows <- list()
for (k in unique(tree$key)) {
  g <- tree[tree$key == k, ]; ms <- sort(unique(g$Measure)); if (length(ms) < 2) next
  ll <- lastlive[lastlive$key == k, ]
  for (j in seq_len(length(ms) - 1)) {
    m0 <- ms[j]; m1 <- ms[j + 1]
    g0 <- g[g$Measure == m0 & g$Status == "live" & g$DBH > 0 & g$EXPF > 0, ]
    if (nrow(g0) == 0) next
    g1 <- g[g$Measure == m1, ]
    st <- sapply(seq_len(nrow(g0)), function(i) {
      tr <- g0$Tree[i]; r1 <- g1[g1$Tree == tr, ]
      if (nrow(r1) == 0) return("absent")
      r1 <- r1[1, ]
      if (r1$Status == "live") return("live")
      if (r1$Status == "dead") {
        lv <- ll$lastlive[ll$Tree == tr]
        if (length(lv) && lv > m1) return("notfound")      # recorded dead then live again: not a death
        return(if (r1$DBH > 0) "dead_meas" else "dead_sent")
      }
      "other"
    })
    dead <- st %in% c("dead_meas", "dead_sent"); abs_ <- st == "absent"
    rows[[length(rows) + 1]] <- data.frame(
      key = k, Data = g0$Data[1], Install = g0$Install[1], Plot = g0$Plot[1], m0 = m0, m1 = m1, YIP = m1 - m0,
      ntree = sum(!abs_), N0 = sum(g0$EXPF[!abs_]), N1 = sum(g0$EXPF[!abs_ & !dead]),
      ndead = sum(dead), ndead_meas = sum(st == "dead_meas"), n_absent = sum(abs_),
      H40_0 = h40(g[g$Measure == m0, ]), H40_1 = h40(g[g$Measure == m1, ]), stringsAsFactors = FALSE)
  }
}
pairs <- do.call(rbind, rows)
p0 <- plt[, c("key", "Measure", "Origin", "SDI", "QMD", "BAPH")]; names(p0) <- c("key", "m0", "Origin", "SDI0", "QMD0", "BAPH0")
pairs <- merge(pairs, p0, by = c("key", "m0"), all.x = TRUE)
pairs$planted <- as.integer(pairs$Origin == "Planted")
pairs$mort_ann <- 1 - (pairs$N1 / pairs$N0)^(1 / pairs$YIP)
pairs$irreg <- pairs$mort_ann > IRREG_THRESHOLD
pairs$inst <- paste(pairs$Data, pairs$Install, sep = "|")
write.csv(pairs, file.path(OUT, "plot_interval_pairs_DATA.csv"), row.names = FALSE)
cat(sprintf("pairs %d, plots %d, deaths (reading A, absorbing) %d, irregular intervals %d carrying %d deaths (%.1f%%)\n",
            nrow(pairs), length(unique(pairs$key)), sum(pairs$ndead), sum(pairs$irreg),
            sum(pairs$ndead[pairs$irreg]), 100 * sum(pairs$ndead[pairs$irreg]) / sum(pairs$ndead)))

# ---- 2. Stage 1: occurrence of an irregular event ------------------------------
pairs$lnSDI <- log(pairs$SDI0); pairs$lnYIP <- log(pairs$YIP)
s1 <- safely(glm(irreg ~ lnSDI + planted + lnYIP, data = pairs, family = binomial()), "stage1 glm")
s1_any <- safely(glm(I(ndead > 0) ~ lnSDI + planted + lnYIP, data = pairs, family = binomial()), "stage1 any-death glm")
auc <- function(y, p) { r <- rank(p); n1 <- sum(y == 1); n0 <- sum(y == 0); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
cat("\nStage 1 irregular-event occurrence:\n"); print(round(summary(s1)$coefficients, 3))
cat(sprintf("in-sample AUC irregular %.3f, any-death %.3f, base rate irregular %.3f\n",
            auc(as.integer(pairs$irreg), fitted(s1)), auc(as.integer(pairs$ndead > 0), fitted(s1_any)), mean(pairs$irreg)))
ir <- pairs[pairs$irreg, ]; fr <- ir$ndead / ir$ntree
cat(sprintf("irregular magnitude: median cohort fraction %.2f (IQR %.2f to %.2f), n = %d\n", median(fr), quantile(fr, .25), quantile(fr, .75), nrow(ir)))

# ---- 3. Stage 2: regular stand-level survival ----------------------------------
reg <- pairs[!pairs$irreg & !is.na(pairs$H40_0) & !is.na(pairs$H40_1) & pairs$H40_0 > 0 & pairs$H40_1 > 0 & !is.na(pairs$SDI0), ]
reg$S0 <- 100 / sqrt(reg$N0); reg$S1 <- 100 / sqrt(reg$N1); reg$lnS1 <- log(reg$S1)
reg$ty <- reg$ntree * reg$YIP; reg$w <- sqrt(reg$ntree)
cat(sprintf("\nregular set: %d pairs, %d plots, %d deaths, %d tree-years, pooled %.4f yr-1\n",
            nrow(reg), length(unique(reg$key)), sum(reg$ndead), sum(reg$ty), sum(reg$ndead) / sum(reg$ty)))

garcia_lnS2 <- function(par, S1, H1, H2) {   # par = c(alpha, beta, gamma); Garcia (2009) Eq. 10
  a <- par[1]; b <- par[2]; g <- par[3]; H2 <- pmax(H2, H1)
  inner <- pmax(S1^a - (b * H1)^g + (b * H2)^g, 1e-9); log(inner) / a }
fit_garcia <- function(d, fix_ratio = NA) {
  obj <- function(lp) { p <- exp(lp); if (!is.na(fix_ratio)) p <- c(p[1], p[2], p[1] * fix_ratio)
    sum((d$w * (d$lnS1 - garcia_lnS2(p, d$S0, d$H40_0, d$H40_1)))^2) }
  best <- NULL
  for (a in c(1.5, 3, 6)) for (b in c(0.05, 0.1, 0.3)) for (g in (if (is.na(fix_ratio)) c(1.5, 3, 8) else a * fix_ratio)) {
    lp0 <- if (is.na(fix_ratio)) log(c(a, b, g)) else log(c(a, b))
    lo <- if (is.na(fix_ratio)) log(c(0.05, 1e-4, 0.05)) else log(c(0.05, 1e-4))
    hi <- if (is.na(fix_ratio)) log(c(60, 5, 60)) else log(c(60, 5))
    o <- tryCatch(optim(lp0, obj, method = "L-BFGS-B", lower = lo, upper = hi), error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o }
  p <- exp(best$par); if (!is.na(fix_ratio)) p <- c(p[1], p[2], p[1] * fix_ratio)
  names(p) <- c("alpha", "beta", "gamma"); attr(p, "sse") <- best$value; p }
pred_garcia <- function(p, d) 10000 / exp(garcia_lnS2(p, d$S0, d$H40_0, d$H40_1))^2
ramp_rate <- function(sdi, planted, onset = 200, full = 850, lift = 0.15, bn = 0.003, bp = 0.006)
  ifelse(planted == 1, bp, bn) + lift * pmin(pmax((sdi - onset) / (full - onset), 0), 1)
pred_ramp <- function(p, d) d$N0 * (1 - ramp_rate(d$SDI0, d$planted))^d$YIP
fit_cloglog <- function(d) coef(glm(cbind(ndead, ntree - ndead) ~ log(SDI0) + planted, offset = log(YIP),
                                     data = d, family = binomial(link = "cloglog")))
pred_cloglog <- function(b, d) d$N0 * exp(-exp(b[1] + b[2] * log(d$SDI0) + b[3] * d$planted) * d$YIP)
fit_const <- function(d) 1 - (1 - sum(d$ndead) / sum(d$ntree))^(1 / weighted.mean(d$YIP, d$ntree))
pred_const <- function(m, d) d$N0 * (1 - m)^d$YIP
models <- list(garcia_free = list(fit = function(d) fit_garcia(d), pred = pred_garcia),
               garcia_ratio1 = list(fit = function(d) fit_garcia(d, 1), pred = pred_garcia),
               garcia_ratio2 = list(fit = function(d) fit_garcia(d, 2), pred = pred_garcia),
               cloglog_lnSDI = list(fit = fit_cloglog, pred = pred_cloglog),
               const_rate = list(fit = fit_const, pred = pred_const),
               ramp_record = list(fit = function(d) NULL, pred = pred_ramp))
ann <- function(pred, d) 1 - (pmax(pred, 1e-9) / d$N0)^(1 / d$YIP)
metrics <- function(d, pred) { e <- pred - d$N1; ea <- ann(pred, d) - ann(d$N1, d)
  c(n = nrow(d), bias_N = mean(e), rmse_N = sqrt(mean(e^2)),
    pbias_deaths = 100 * (sum(d$N0 - pred) - sum(d$N0 - d$N1)) / sum(d$N0 - d$N1),
    bias_ann = weighted.mean(ea, d$ty), rmse_ann = sqrt(weighted.mean(ea^2, d$ty))) }
fits <- list(); ins <- list(); loio <- list()
for (nm in names(models)) {
  p <- safely(models[[nm]]$fit(reg), paste("fit", nm)); fits[[nm]] <- p
  reg[[paste0("pred_", nm)]] <- models[[nm]]$pred(p, reg); ins[[nm]] <- metrics(reg, reg[[paste0("pred_", nm)]])
  lp <- rep(NA_real_, nrow(reg))
  for (i in unique(reg$inst)) { te <- reg$inst == i
    pp <- safely(models[[nm]]$fit(reg[!te, ]), paste("loio", nm, i)); if (!is.null(pp) || nm == "ramp_record") lp[te] <- models[[nm]]$pred(pp, reg[te, ]) }
  reg[[paste0("loio_", nm)]] <- lp; ok <- !is.na(lp); loio[[nm]] <- metrics(reg[ok, ], lp[ok])
}
cat("\nStage 2 fitted parameters:\n"); print(lapply(fits, function(x) if (is.null(x)) "ramp of record (onset 200, full 850, lift 0.15, base 0.003/0.006)" else round(x, 4)))
cat("\nIn-sample:\n"); print(round(do.call(rbind, ins), 4))
cat("\nLeave-one-installation-out:\n"); print(round(do.call(rbind, loio), 4))
write.csv(cbind(model = names(ins), do.call(rbind, ins)), file.path(OUT, "stage2_insample_metrics.csv"), row.names = FALSE)
write.csv(cbind(model = names(loio), do.call(rbind, loio)), file.path(OUT, "stage2_loio_metrics.csv"), row.names = FALSE)
# stratified LOIO annual mortality
reg$sdibin <- cut(reg$SDI0, c(0, 200, 350, 500, 850, 5000)); reg$yipbin <- cut(reg$YIP, c(0, 1, 3, 6, 30))
strat <- function(v) { do.call(rbind, lapply(split(reg, reg[[v]]), function(d) {
  r <- data.frame(stratum = as.character(d[[v]][1]), pairs = nrow(d), deaths = sum(d$ndead), treeyears = sum(d$ty),
                  obs = weighted.mean(ann(d$N1, d), d$ty))
  for (nm in names(models)) { ok <- !is.na(d[[paste0("loio_", nm)]]); r[[nm]] <- weighted.mean(ann(d[[paste0("loio_", nm)]][ok], d[ok, ]), d$ty[ok]) }
  r })) }
for (v in c("sdibin", "yipbin", "Origin", "Data")) { s <- strat(v); cat("\nLOIO annual mortality by", v, "\n"); print(s, digits = 3)
  write.csv(s, file.path(OUT, paste0("stage2_loio_by_", v, ".csv")), row.names = FALSE) }

# ---- 4. Cluster (plot) bootstrap: parameter CIs, annual bias CIs, equivalence --
plots <- unique(reg$key); idx <- split(seq_len(nrow(reg)), reg$key)
bo <- list(); pars <- matrix(NA, B_BOOT, 3); pars1 <- matrix(NA, B_BOOT, 2)
for (nm in c("garcia_free", "garcia_ratio1", "cloglog_lnSDI", "ramp_record")) bo[[nm]] <- matrix(NA, B_BOOT, 3)
for (b in seq_len(B_BOOT)) {
  d <- reg[unlist(idx[sample(plots, length(plots), replace = TRUE)]), ]
  pg <- safely(fit_garcia(d), "boot garcia"); pg1 <- safely(fit_garcia(d, 1), "boot garcia r1"); pc <- safely(fit_cloglog(d), "boot cloglog")
  if (is.null(pg) || is.null(pc) || is.null(pg1)) next
  pars[b, ] <- pg; pars1[b, ] <- pg1[1:2]
  for (nm in names(bo)) {
    pred <- switch(nm, garcia_free = pred_garcia(pg, d), garcia_ratio1 = pred_garcia(pg1, d), cloglog_lnSDI = pred_cloglog(pc, d), ramp_record = pred_ramp(NULL, d))
    cf <- coef(lm(d$N1 ~ pred)); bo[[nm]][b, ] <- c(cf[1], cf[2], weighted.mean(ann(pred, d) - ann(d$N1, d), d$ty)) }
}
ci <- function(x) quantile(x, c(.025, .975), na.rm = TRUE)
cat(sprintf("\nGarcia free cluster-bootstrap 95%% CI (B = %d): alpha %s, beta %s, gamma %s, gamma/alpha %s\n", sum(!is.na(pars[, 1])),
            paste(round(ci(pars[, 1]), 3), collapse = " to "), paste(round(ci(pars[, 2]), 4), collapse = " to "),
            paste(round(ci(pars[, 3]), 3), collapse = " to "), paste(round(ci(pars[, 3] / pars[, 1]), 3), collapse = " to ")))
cat(sprintf("Garcia ratio1 CI: alpha %s, beta %s\n", paste(round(ci(pars1[, 1]), 3), collapse = " to "), paste(round(ci(pars1[, 2]), 4), collapse = " to ")))
eq <- do.call(rbind, lapply(names(bo), function(nm) data.frame(model = nm,
  int_lo = ci(bo[[nm]][, 1])[1], int_hi = ci(bo[[nm]][, 1])[2], int_region = EQ_REGION_B0 * mean(reg$N1),
  slope_lo = ci(bo[[nm]][, 2])[1], slope_hi = ci(bo[[nm]][, 2])[2], slope_region_lo = 1 - EQ_REGION_B1, slope_region_hi = 1 + EQ_REGION_B1,
  annbias_lo = ci(bo[[nm]][, 3])[1], annbias_hi = ci(bo[[nm]][, 3])[2])))
eq$int_pass <- abs(eq$int_lo) < eq$int_region & abs(eq$int_hi) < eq$int_region
eq$slope_pass <- eq$slope_lo > eq$slope_region_lo & eq$slope_hi < eq$slope_region_hi
eq$annbias_excludes_zero <- eq$annbias_lo > 0 | eq$annbias_hi < 0
cat("\nEquivalence (obs N1 on pred N1, plot-cluster bootstrap) and annual-bias CIs:\n"); print(eq, digits = 4)
write.csv(eq, file.path(OUT, "stage2_equivalence_bootstrap.csv"), row.names = FALSE)

# ---- 5. Self-thinning consistency of the Garcia limit ---------------------------
al <- lm(log(QMD0) ~ log(H40_0), data = reg[reg$QMD0 > 0, ]); kHD <- coef(al)[2]
for (nm in c("garcia_free", "garcia_ratio1")) { p <- fits[[nm]]; ga <- p["gamma"] / p["alpha"]
  viol <- mean(reg$S0 < (p["beta"] * reg$H40_0)^ga)
  cat(sprintf("%s: gamma/alpha %.3f, limit line log N + %.2f log H = const, ln QMD on ln H40 slope %.3f, implied Reineke slope %.2f, share of observations beyond the limit %.3f\n",
              nm, ga, 2 * ga, kHD, -2 * ga / kHD, viol)) }

# ---- 6. Stage 3: within-plot ordering of deaths by relative size ----------------
cidx <- function(pr_sub, var, sign) { num <- 0; den <- 0
  for (i in seq_len(nrow(pr_sub))) { p <- pr_sub[i, ]; g <- tree[tree$key == p$key, ]
    g0 <- g[g$Measure == p$m0 & g$Status == "live" & g$DBH > 0 & g$EXPF > 0, ]; g1 <- g[g$Measure == p$m1, ]
    ll <- lastlive[lastlive$key == p$key, ]
    dead <- sapply(g0$Tree, function(tr) { r1 <- g1[g1$Tree == tr, ]; if (nrow(r1) == 0) return(NA)
      lv <- ll$lastlive[ll$Tree == tr]; r1$Status[1] == "dead" && !(length(lv) && lv > p$m1) })
    x <- sign * g0[[var]][which(dead %in% TRUE)]; y <- sign * g0[[var]][which(dead %in% FALSE)]
    if (length(x) == 0 || length(y) == 0) next
    num <- num + sum(outer(x, y, ">")) + 0.5 * sum(outer(x, y, "==")); den <- den + length(x) * length(y) }
  num / den }
cat("\nStage 3 within-plot c-index of death ordering:\n")
for (v in list(c("rDBH", -1), c("rHT", -1), c("BAL", 1)))
  cat(sprintf("  regular %s: %.3f   irregular %s: %.3f\n", v[1], cidx(reg, v[1], as.numeric(v[2])), v[1], cidx(pairs[pairs$irreg, ], v[1], as.numeric(v[2]))))

# ---- 7. Figures (headless, 300 dpi) --------------------------------------------
pf <- fits$garcia_ratio1; pfree <- fits$garcia_free
png(file.path(OUT, "fig1_garcia_NH_plane.png"), width = 2400, height = 1200, res = 300)
par(mfrow = c(1, 2), mar = c(4.2, 4.5, 2, 1))
for (o in c("Natural", "Planted")) { d <- reg[reg$Origin == o, ]
  plot(d$H40_0, d$N0, log = "y", pch = 16, cex = .5, col = adjustcolor("grey30", .5), xlab = "Top height H40 (m)", ylab = expression(Trees~ha^-1), main = o, xlim = c(0, 30), ylim = c(50, 10000))
  segments(d$H40_0, d$N0, d$H40_1, d$N1, col = adjustcolor("grey30", .35))
  H <- seq(1, 30, by = .5)
  for (N0 in c(8000, 4000, 2000, 1000, 500)) { S <- (( (100 / sqrt(N0))^pf["alpha"] - (pf["beta"] * 2)^pf["gamma"] + (pf["beta"] * H)^pf["gamma"]))^(1 / pf["alpha"]); lines(H, 10000 / S^2, col = "firebrick", lwd = 1.5) }
  lines(H, 10000 / ((pf["beta"] * H)^(pf["gamma"] / pf["alpha"]))^2, col = "firebrick", lty = 2, lwd = 2)
  legend("topright", c("observed intervals", "Garcia trajectories (gamma/alpha = 1)", "limiting line"), col = c("grey30", "firebrick", "firebrick"), lty = c(1, 1, 2), pch = c(16, NA, NA), bty = "n", cex = .7) }
dev.off()
s <- strat("sdibin")
png(file.path(OUT, "fig2_loio_mortality_by_SDI.png"), width = 1800, height = 1400, res = 300)
par(mar = c(4.5, 4.5, 1, 1)); x <- seq_len(nrow(s))
plot(x, s$obs, type = "b", pch = 16, ylim = c(0, max(s$ramp_record, s$obs) * 1.15), xaxt = "n", xlab = "Initial stand density index class", ylab = expression(Annual~mortality~(yr^-1)))
axis(1, x, s$stratum, cex.axis = .75)
se <- sqrt(s$obs * (1 - s$obs) / s$treeyears); arrows(x, s$obs - 1.96 * se, x, s$obs + 1.96 * se, angle = 90, code = 3, length = .03)
lines(x, s$ramp_record, type = "b", pch = 17, col = "firebrick"); lines(x, s$garcia_ratio1, type = "b", pch = 15, col = "steelblue"); lines(x, s$cloglog_lnSDI, type = "b", pch = 18, col = "darkgreen")
legend("topleft", c("observed (binomial 95% CI)", "ramp of record (Eq. 5b)", "Garcia gamma/alpha = 1 (LOIO)", "cloglog ln SDI (LOIO)"), col = c("black", "firebrick", "steelblue", "darkgreen"), pch = c(16, 17, 15, 18), lty = 1, bty = "n", cex = .75)
dev.off()
png(file.path(OUT, "fig3_regular_vs_irregular.png"), width = 1800, height = 1400, res = 300)
par(mar = c(4.5, 4.5, 1, 1)); plot(pairs$SDI0, pairs$mort_ann, log = "x", pch = ifelse(pairs$irreg, 17, 16), col = ifelse(pairs$irreg, "firebrick", adjustcolor("grey30", .6)), cex = .7, xlab = "Initial stand density index", ylab = expression(Observed~annual~mortality~(yr^-1)))
abline(h = IRREG_THRESHOLD, lty = 2); legend("topleft", c("regular interval", "irregular interval (> 0.10 yr-1)"), pch = c(16, 17), col = c("grey30", "firebrick"), bty = "n", cex = .8)
dev.off()
png(file.path(OUT, "fig4_equivalence_obs_pred.png"), width = 2400, height = 900, res = 300)
par(mfrow = c(1, 3), mar = c(4.5, 4.5, 2, 1))
for (nm in c("garcia_ratio1", "cloglog_lnSDI", "ramp_record")) { pr_ <- reg[[paste0("pred_", nm)]]; lim <- c(0, max(reg$N1, pr_))
  plot(pr_, reg$N1, pch = 16, cex = .5, col = adjustcolor("grey30", .5), xlim = lim, ylim = lim, xlab = expression(Predicted~N[1]~(trees~ha^-1)), ylab = expression(Observed~N[1]~(trees~ha^-1)), main = nm)
  abline(0, 1, lty = 2); cf <- coef(lm(reg$N1 ~ pr_)); abline(cf, col = "firebrick")
  e <- eq[eq$model == nm, ]; legend("topleft", sprintf("slope %.3f (%.3f to %.3f)\nintercept %.0f (%.0f to %.0f)", cf[2], e$slope_lo, e$slope_hi, cf[1], e$int_lo, e$int_hi), bty = "n", cex = .7) }
dev.off()
saveRDS(list(fits = fits, insample = ins, loio = loio, equivalence = eq, boot_pars = pars, boot_pars_ratio1 = pars1, stage1 = s1, n_reg = nrow(reg)), file.path(OUT, "koa_mortality_3stage_results.rds"))
cat("\ndone\n")
