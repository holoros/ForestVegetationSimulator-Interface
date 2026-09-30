## garcia_rs.R, 2026-09-27. Garcia (2009) relative spacing limiting line refit on the koa v102 plot interval frame,
## comparing the height state variable: observed top height H40 against the allometric QMD height equivalent H_QMD
## the engine deploys (garcia_qmd_anchored). EQUATION LEVEL ONLY; full model behavior runs only through customRun_fvsRunHi.R.
## Model: S^alpha - (beta H)^gamma = const, S = 100/sqrt(N). S1 = (S0^a - (b H0)^g + (b H1)^g)^(1/a).
## Fits by least squares on ln S1 over regular intervals (irreg == FALSE, H1 > H0), gamma/alpha fixed at 1 (record
## specification) and free; pooled beta and origin specific beta. Scored on ln S1 and on annual mortality rate, in
## sample and leave one installation out, with an installation cluster bootstrap for beta. Seed 20260927.
set.seed(20260927)
P <- read.csv("inc/plot_interval_pairs_DATA_v102.csv", stringsAsFactors = FALSE)
TR <- read.csv("inc/AK_TREE_v102.csv", stringsAsFactors = FALSE)
stopifnot(!any(tolower(names(TR)) %in% c("lat", "lon", "latitude", "longitude")))
lv <- TR[TR$Status == "live" & is.finite(TR$DBH) & TR$DBH > 0 & is.finite(TR$EXPF) & TR$EXPF > 0, ]
lv$key <- paste(lv$Data, lv$Install, lv$Plot, sep = "|")
qm <- aggregate(cbind(w = EXPF * DBH^2, n = EXPF) ~ key + Measure, data = lv, FUN = sum); qm$QMD <- sqrt(qm$w / qm$n)
P$QMD0c <- qm$QMD[match(paste(P$key, P$m0), paste(qm$key, qm$Measure))]
P$QMD1c <- qm$QMD[match(paste(P$key, P$m1), paste(qm$key, qm$Measure))]
cat("pairs", nrow(P), "QMD0 from tree table vs frame QMD0, median abs diff", median(abs(P$QMD0c - P$QMD0), na.rm = TRUE), "\n")
R <- P[!P$irreg & is.finite(P$H40_0) & is.finite(P$H40_1) & P$H40_1 > P$H40_0 & is.finite(P$QMD0c) & is.finite(P$QMD1c) & P$N1 > 0, ]
cat("regular intervals", nrow(R), "plots", length(unique(R$key)), "installations", length(unique(R$inst)), "planted", sum(R$planted == 1), "\n")
## allometry ln QMD = a + k ln H40, deployed (a, k) and refit on v102 regular interval starts
AK_DEP <- c(a = -0.16863070512157105, k = 1.1719473700506686)
al <- lm(log(QMD0c) ~ log(H40_0), data = R); AK_V102 <- setNames(coef(al), c("a", "k"))
cat("allometry v102: a", AK_V102[1], "k", AK_V102[2], "R2", summary(al)$r.squared, "\n")
hq <- function(q, ak) exp((log(q) - ak[["a"]]) / ak[["k"]])
STATES <- list(H40 = list(h0 = R$H40_0, h1 = R$H40_1),
               HQMD_dep = list(h0 = hq(R$QMD0c, AK_DEP), h1 = hq(R$QMD1c, AK_DEP)),
               HQMD_v102 = list(h0 = hq(R$QMD0c, AK_V102), h1 = hq(R$QMD1c, AK_V102)))
S0 <- 100 / sqrt(R$N0); S1 <- 100 / sqrt(R$N1); pl <- R$planted == 1
predS1 <- function(par, h0, h1, s0, pl, ratio1, byorigin) {
  a <- par[1]; g <- if (ratio1) a else par[2]; b <- if (byorigin) ifelse(pl, par[length(par)], par[length(par) - 1]) else par[length(par)]
  inner <- s0^a - (b * h0)^g + (b * h1)^g; inner[inner <= 0] <- NA; inner^(1 / a)
}
sse <- function(par, ...) { r <- log(S1x) - log(predS1(par, ...)); r[!is.finite(r)] <- 3; sum(r^2) }
fitG <- function(h0, h1, s0, s1, pl, ratio1, byorigin) {
  S1x <<- s1; best <- NULL
  for (a0 in c(1.5, 3, 6)) for (b0 in c(0.05, 0.1, 0.2, 0.4)) {
    st <- c(a0, if (!ratio1) a0, rep(b0, if (byorigin) 2 else 1))
    lo <- c(0.3, if (!ratio1) 0.3, rep(1e-3, if (byorigin) 2 else 1)); hi <- c(30, if (!ratio1) 30, rep(3, if (byorigin) 2 else 1))
    o <- tryCatch(optim(st, sse, h0 = h0, h1 = h1, s0 = s0, pl = pl, ratio1 = ratio1, byorigin = byorigin, method = "L-BFGS-B", lower = lo, upper = hi), error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o
  }
  best$bound <- any(abs(best$par - c(lo)) < 1e-3 * pmax(abs(lo), 1e-3) | abs(best$par - hi) < 1e-3 * hi); best
}
mrate <- function(s1pred, n0, yip) { n1 <- pmin(10000 / s1pred^2, n0); 1 - (n1 / n0)^(1 / yip) }
floor_ <- ifelse(pl, 0.006, 0.003)
obs_m <- R$mort_ann
score <- function(s1p, idx = seq_len(nrow(R))) {
  m <- mrate(s1p[idx], R$N0[idx], R$YIP[idx]); mf <- pmax(m, floor_[idx]); o <- obs_m[idx]; ok <- is.finite(m)
  c(n = sum(ok), rmse_lnS1 = sqrt(mean((log(S1[idx]) - log(s1p[idx]))[ok]^2)), obs_mort = mean(o[ok]),
    pred_mort = mean(m[ok]), bias_mort = mean((o - m)[ok]), rmse_mort = sqrt(mean((o - m)[ok]^2)),
    pred_mort_floor = mean(mf[ok]), bias_mort_floor = mean((o - mf)[ok]), rmse_mort_floor = sqrt(mean((o - mf)[ok]^2)),
    cor_mort = suppressWarnings(cor(o[ok], m[ok])), frac_line_binding = mean((m > floor_[idx])[ok]))
}
RES <- list(); PAR <- list()
for (sv in names(STATES)) for (r1 in c(TRUE, FALSE)) for (bo in c(FALSE, TRUE)) {
  st <- STATES[[sv]]; lab <- paste(sv, if (r1) "ratio1" else "ratiofree", if (bo) "beta_by_origin" else "beta_pooled", sep = "|")
  f <- fitG(st$h0, st$h1, S0, S1, pl, r1, bo); s1p <- predS1(f$par, st$h0, st$h1, S0, pl, r1, bo)
  ## leave one installation out
  s1cv <- rep(NA_real_, nrow(R))
  for (i in unique(R$inst)) { te <- R$inst == i; if (bo && (sum(pl[!te]) < 5 || sum(!pl[!te]) < 5)) next
    fi <- fitG(st$h0[!te], st$h1[!te], S0[!te], S1[!te], pl[!te], r1, bo); s1cv[te] <- predS1(fi$par, st$h0[te], st$h1[te], S0[te], pl[te], r1, bo) }
  ## installation cluster bootstrap, 300 resamples, beta and alpha
  ids <- unique(R$inst); sp <- split(seq_len(nrow(R)), R$inst)
  bs <- t(replicate(300, { ix <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE)
    fb <- fitG(st$h0[ix], st$h1[ix], S0[ix], S1[ix], pl[ix], r1, bo); fb$par }))
  ci <- apply(bs, 2, quantile, c(0.025, 0.975))
  ## envelope: anchored beta = 100 / sqrt(q99 of N H^2) over interval starts, and share of starts above the fitted line
  zz <- R$N0 * st$h0^2; b_anch <- 100 / sqrt(quantile(zz, 0.99)); bfit <- f$par[length(f$par)]
  above <- mean(R$N0 > 10000 / (bfit * st$h0)^2)
  PAR[[lab]] <- data.frame(state = sv, gamma_over_alpha = if (r1) "fixed 1" else "free", beta = if (bo) "by origin" else "pooled",
    alpha = f$par[1], gamma = if (r1) f$par[1] else f$par[2], beta_pooled_or_natural = f$par[if (bo) length(f$par) - 1 else length(f$par)],
    beta_planted = if (bo) f$par[length(f$par)] else NA, alpha_lo = ci[1, 1], alpha_hi = ci[2, 1],
    beta_lo = ci[1, ncol(bs)], beta_hi = ci[2, ncol(bs)], boundary = f$bound, sse_lnS1 = f$value, aic = nrow(R) * log(f$value / nrow(R)) + 2 * length(f$par),
    slope_lnN_lnH = -2 * (if (r1) 1 else f$par[2] / f$par[1]), beta_anchored_q99 = unname(b_anch), frac_starts_above_line = above)
  RES[[paste(lab, "ins")]] <- data.frame(state = sv, spec = lab, scheme = "in_sample", t(score(s1p)))
  RES[[paste(lab, "loio")]] <- data.frame(state = sv, spec = lab, scheme = "leave_one_installation_out", t(score(s1cv)))
  for (o in c("natural", "planted")) { idx <- which(if (o == "planted") pl else !pl)
    RES[[paste(lab, "loio", o)]] <- data.frame(state = sv, spec = lab, scheme = paste0("loio_", o), t(score(s1cv, idx))) }
  cat(format(Sys.time(), "%H:%M:%S"), lab, "done\n"); flush.console()
}
PAR <- do.call(rbind, PAR); RES <- do.call(rbind, RES)
write.csv(PAR, "out/garcia_rs_params.csv", row.names = FALSE); write.csv(RES, "out/garcia_rs_scores.csv", row.names = FALSE)
write.csv(data.frame(term = c("a", "k", "r2", "n"), deployed = c(AK_DEP, NA, NA), v102 = c(AK_V102, summary(al)$r.squared, nrow(R))), "out/garcia_rs_allometry.csv", row.names = FALSE)
cat("GARCIA_RS DONE\n")
