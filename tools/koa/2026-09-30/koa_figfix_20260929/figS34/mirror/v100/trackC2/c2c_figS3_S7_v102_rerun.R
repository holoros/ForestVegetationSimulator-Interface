## v102 PORT, 2026-09-23 (track5_figS37). Byte copy of koa_zenodo_180/stage/v100_checks/trackC2/c2c_figS3_S7.R (md5 79dd657c)
## with PATHS ONLY changed (TC2 absolute, the three frame names, the censored output name). Inputs are the v102 mirror built by
## ../../build_mirror.sh. No gate value is moved: the script has no hard stop on counts; its out/F_s11 comparison is a log line and
## now reads a v102 row built from track3/s06/v102 (build_adapters.py). Deployed natural level factor is 2.64629 in v102 (was 2.59367).
## =============================================================================
## c2c_figS3_S7.R, v100 trackC2, 2026-09-17. A. Weiskittel.
## Supplemental Figures S3 (sampling recovery and inference instability) and S7 (why the refitted
## survival equation cannot be deployed), regenerated on the origin-corrected survival samples with
## PSP thinning-removal intervals censored (interval ending in, or spanning, a removal year of a PSP
## installation; removal years from psp_origin_thinning_2026-09-16_DATA.csv), the rule of
## origin_refit_span.R. Fits reuse s06 prep(); estimates are exact maximum likelihood (see mlfit below).
## Figure logic follows koa_figs_g_20260908/make_figS7_20260908.R and the S10 block of
## cardinal_koa_v63_survival_figs.R, rebuilt on the current inputs.
## Panel S7(b) draws the retired Eq. 9 ramp AND the deployed stand rate (gated M1 times the natural
## level factor 2.64629, koa_params.MORT_CAL) along the deployed natural trajectories, BYI 100, 264, 450, years 1 to 100.
## Run from v100/trackC2: Rscript c2c_figS3_S7.R. No coordinate column is read or written.
## =============================================================================
## 2026-09-17 figfix: US spelling (modeled); retired Eq. 9 ramp relabeled "Retired density ramp" (legend) and
## "Retired ramp, recovered (ii)" (panel c), because manuscript Eq. 9 is now the Garcia self-thinning equation. No numeric change.
suppressPackageStartupMessages({
  library(sandwich); library(lmtest); library(ggplot2); library(patchwork); library(scales)
})
TC2  <- normalizePath("~/jobs/koa_figS7_20260924/mirror/v100/trackC2")   # v102 mirror (build_mirror.sh); record: normalizePath(".") under koa_origin_20260916
ROOT <- normalizePath(file.path(TC2, "..", ".."))
Sys.setenv(KOA_DEPOSIT = file.path(ROOT, "s06", "deposit"), KOA_OUT = file.path(TC2, "r", "output"))
setwd(file.path(TC2, "r"))
L <- readLines("06_survival_respec.R")
eval(parse(text = L[1:(grep("^specs <- list", L) - 1)]))
setwd(TC2)
set.seed(20260916)
LOGF <- file.path(TC2, "c2c_numbers.log"); cat("", file = LOGF)
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = LOGF, append = TRUE) }

## ---- inputs and censoring ------------------------------------------------------
O <- read.csv(file.path(ROOT, "psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
rem <- setNames(lapply(strsplit(as.character(O$removal_t1_years), ";"), as.integer), as.character(O$Install))
censor <- function(d) {
  i <- as.character(d$inst)
  flag <- mapply(function(s, k, t0, t1) s == "PSP" && k %in% names(rem) &&
                   (as.integer(t1) %in% rem[[k]] || any(rem[[k]] > t0 & rem[[k]] < t1)),
                 d$source, i, d$t0, d$t1)
  list(d = d[!flag, ], n_cut = sum(flag), ev_cut = sum(d$alive[flag] == 0))
}
files <- c(baseline = "surv_baseline_rebuilt_v102.csv",      # v102 frames (symlinks to frames/); record: *_origin_2026-09-16_DATA.csv
           recovered_i = "surv_recovered_i_v102.csv",
           recovered_ii = "surv_recovered_ii_v102.csv")
fit_lv <- c("Baseline", "Recovered (i)", "Recovered (ii)")
names(fit_lv) <- names(files)
raw <- lapply(files, function(f) read.csv(file.path(ROOT, f), stringsAsFactors = FALSE))
stopifnot(!any(grepl("^(lat|lon|long|latitude|longitude)$", unlist(lapply(raw, names)), ignore.case = TRUE)))
S <- list(); cen <- list()
for (k in names(files)) {
  cc <- censor(raw[[k]]); cen[[k]] <- cc
  say("%s: %d records, %d events before censoring; removed %d records (%d events); %d remain",
      k, nrow(raw[[k]]), sum(raw[[k]]$alive == 0), cc$n_cut, cc$ev_cut, nrow(cc$d))
  write.csv(cc$d, file.path(TC2, sub("_v102", "_v102_censored", files[[k]])), row.names = FALSE)
  S[[k]] <- prep(cc$d)
}

## ---- fits, clustered and jackknife -------------------------------------------------
eq5 <- alive ~ ht + log(ht) + rht + log(cr) + log(ht / dbh) + log(byi / 100) + I(byi / 1000)
par_lv <- paste0("b", 0:7)
term_lab <- c("Intercept", "HT", "ln(HT)", "rHT", "ln(CR)", "ln(HT/DBH)", "ln(BYI/100)", "BYI/1000")
aucf <- function(y, s) { r <- rank(s); n1 <- sum(y == 1); n0 <- sum(y == 0); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
## MAXIMUM LIKELIHOOD, 2026-09-17. glm() does not converge on the recovered samples (200 iterations,
## oscillating) and its last iterate has a LOWER log-likelihood than the deposit's damped Fisher solution
## (recovered ii: -3238.82 against -3191.70). Every fit here is therefore the BFGS maximum of the exact
## cloglog log-likelihood started from both the damped solution and the glm iterate, keeping the better.
## Clustered covariance is computed by hand as vcovCL(type = "HC1") does for a glm (expected-information
## bread, cluster-summed scores, G/(G-1) times (n-1)/(n-k)); checked against sandwich on the baseline.
mlfit <- function(d) {
  X <- model.matrix(eq5, d); y <- d$alive; off <- log(d$yip)
  pre <- fit_cloglog(X, y, off)
  gl <- suppressWarnings(glm(eq5, family = binomial(link = "cloglog"), data = d, offset = log(yip), start = pre$beta,
                             control = glm.control(maxit = 200, epsilon = 1e-8)))
  sc <- sqrt(colMeans(X^2)); Xs <- sweep(X, 2, sc, "/")
  nll <- function(g) { mu <- exp(drop(Xs %*% g) + off); -sum(ifelse(y == 1, log(-expm1(-mu)), -mu)) }
  gr <- function(g) { mu <- exp(drop(Xs %*% g) + off); w <- ifelse(y == 1, mu * exp(-mu) / (-expm1(-mu)), -mu); -drop(crossprod(Xs, w)) }
  best <- NULL
  for (s0 in list(pre$beta, coef(gl))) {
    if (any(!is.finite(s0))) next
    o <- optim(s0 * sc, nll, gr, method = "BFGS", control = list(maxit = 5000, reltol = 1e-14))
    if (is.null(best) || o$value < best$value) best <- o
  }
  beta <- setNames(best$par / sc, par_lv)
  mu <- exp(drop(X %*% beta) + off); p <- -expm1(-mu)
  w <- ifelse(y == 1, mu * exp(-mu) / p, -mu)
  wf <- mu^2 * exp(-mu) / p   # (dp/deta)^2 / (p (1 - p)) with 1 - p = exp(-mu), stable when p rounds to 1
  llg <- { mg <- exp(drop(X %*% coef(gl)) + off); sum(ifelse(y == 1, log(-expm1(-mg)), -mg)) }
  list(beta = beta, ll = -best$value, p = p, X = X, U = X * w, I = crossprod(X * wf, X), optim_conv = best$convergence,
       grad = max(abs(gr(best$par))), glm = gl, glm_conv = gl$converged, glm_ll = llg, pre_conv = pre$converged)
}
vcl <- function(f, cl) {
  G <- length(unique(cl)); n <- nrow(f$X); k <- ncol(f$X); B <- solve(f$I)
  (G / (G - 1)) * ((n - 1) / (n - k)) * B %*% crossprod(rowsum(f$U, cl)) %*% B
}
coefs <- list(); comp <- list(); jks <- list(); etas <- list(); fits <- list()
for (k in names(S)) {
  d <- S[[k]]
  f <- mlfit(d); fits[[k]] <- f
  b <- f$beta; Vcl <- vcl(f, d$inst)
  if (f$glm_conv) {
    Vs <- vcovCL(f$glm, cluster = d$inst, type = "HC1")
    say("%s: glm converged; max|beta_ML - beta_glm| %.2e, max rel diff hand vs sandwich clustered SE %.2e", k,
        max(abs(b - coef(f$glm))), max(abs(sqrt(diag(Vcl)) / sqrt(diag(Vs)) - 1)))
  } else say("%s: glm NOT converged (ll %.3f); ML by BFGS ll %.3f (gradient %.1e, optim code %d); max|beta_ML - beta_glm| %.3f",
             k, f$glm_ll, f$ll, f$grad, f$optim_conv, max(abs(b - coef(f$glm))))
  ids <- unique(d$inst)
  jk <- do.call(rbind, parallel::mclapply(ids, function(j) {
    mm <- tryCatch(mlfit(d[d$inst != j, ]), error = function(e) NULL)
    if (is.null(mm)) return(NULL)
    as.data.frame(c(list(inst = j, optim_conv = mm$optim_conv, grad = mm$grad, glm_converged = mm$glm_conv,
                         ll_gain_over_glm = mm$ll - mm$glm_ll), as.list(mm$beta)))
  }, mc.cores = 8))
  n <- nrow(jk); B <- as.matrix(jk[, par_lv])
  jse <- sqrt((n - 1) / n * colSums(sweep(B, 2, colMeans(B))^2))
  jk$tp <- -1000 * jk$b6 / jk$b7; jk$sample <- k
  jks[[k]] <- jk
  say("%s jackknife: %d of %d folds fitted, %d glm fits not converged, all BFGS converged %s, max gradient %.1e",
      k, n, length(ids), sum(!jk$glm_converged), all(jk$optim_conv == 0), max(jk$grad))
  se_cl <- sqrt(diag(Vcl))
  coefs[[k]] <- data.frame(sample = k, fit = fit_lv[[k]], par = par_lv, term = term_lab, est = unname(b),
                           est_glm_lastiter = unname(coef(f$glm)),
                           se_model = sqrt(diag(solve(f$I))), se_cl = unname(se_cl), p_cl = 2 * pnorm(-abs(b / se_cl)),
                           cl_lo = b - 1.96 * se_cl, cl_hi = b + 1.96 * se_cl,
                           se_jk = unname(jse), p_jk = 2 * pnorm(-abs(b / jse)), jk_lo = b - 1.96 * jse, jk_hi = b + 1.96 * jse,
                           n_jk_folds = n, row.names = NULL)
  eta <- drop(f$X %*% b); etas[[k]] <- eta
  p <- f$p; y <- d$alive; ev <- 1 - y
  tp <- -1000 * b[7] / b[8]
  gr <- c(0, 0, 0, 0, 0, 0, -1000 / b[8], 1000 * b[7] / b[8]^2)
  se_tp <- sqrt(drop(t(gr) %*% Vcl %*% gr))
  byinst <- sort(tapply(ev, d$inst, sum), decreasing = TRUE)
  src <- d$source
  comp[[k]] <- data.frame(sample = k, records = nrow(d), events = sum(ev), tree_years = sum(d$yip),
    removed_records = cen[[k]]$n_cut, removed_events = cen[[k]]$ev_cut,
    annual_mort_pct = 100 * sum(ev) / sum(d$yip), installations = length(ids), inst_with_event = sum(byinst > 0),
    largest_share_pct = 100 * byinst[1] / sum(ev), largest_inst = names(byinst)[1], three_largest_pct = 100 * sum(byinst[1:3]) / sum(ev),
    ev_KMRPSP = sum(ev[src == "KMR PSP"]), ev_FIA = sum(ev[src == "FIA"]), ev_PSP = sum(ev[src == "PSP"]), ev_DOFAW = sum(ev[src == "DOFAW"]),
    auc_apparent = aucf(ev, 1 - p), brier = mean((y - p)^2), brier_skill = 1 - mean((y - p)^2) / (mean(y) * (1 - mean(y))),
    expected_events = sum(1 - p), loglik = f$ll, loglik_glm_lastiter = f$glm_ll, glm_converged = f$glm_conv,
    aic = -2 * f$ll + 2 * length(b),
    surv_1yr = mean(1 - exp(-1 * exp(eta))), surv_5yr = mean(1 - exp(-5 * exp(eta))),
    surv_10yr = mean(1 - exp(-10 * exp(eta))), surv_20yr = mean(1 - exp(-20 * exp(eta))),
    turning_point = unname(tp), tp_lo = unname(tp - 1.96 * se_tp), tp_hi = unname(tp + 1.96 * se_tp),
    tp_jk_min = min(jk$tp), tp_jk_median = median(jk$tp), tp_jk_max = max(jk$tp), jk_folds = n,
    tp_jk_kulani = { kk <- grep("Kulani", jk$inst); if (length(kk)) jk$tp[kk[1]] else NA },
    fold_cor_b6_b7 = cor(jk$b6, jk$b7), row.names = NULL)
  say("%s fit: n %d, events %d, AUC %.3f, Brier skill %.3f, expected %.1f, surv 1 yr %.3f, 10 yr %.3f, TP %.1f [%.1f, %.1f], jk TP %.1f to %.1f (Kulani fold %.1f)",
      k, nrow(d), sum(ev), comp[[k]]$auc_apparent, comp[[k]]$brier_skill, comp[[k]]$expected_events,
      comp[[k]]$surv_1yr, comp[[k]]$surv_10yr, tp, comp[[k]]$tp_lo, comp[[k]]$tp_hi, min(jk$tp), max(jk$tp), comp[[k]]$tp_jk_kulani)
}
CO <- do.call(rbind, coefs); CP <- do.call(rbind, comp); JK <- do.call(rbind, jks)
write.csv(CO, "FigS3_S7_coefficients.csv", row.names = FALSE)
write.csv(CP, "FigS3_S7_composition.csv", row.names = FALSE)
write.csv(JK, "FigS3_jackknife_folds.csv", row.names = FALSE)
## reproduction gate on the recovered samples (already censored upstream): must match out/F_s11
F11 <- read.csv(file.path(ROOT, "out", "F_s11_composition.csv"))
for (k in c("recovered_i", "recovered_ii")) {
  a <- CP[CP$sample == k, ]; b0 <- F11[F11$sample == k, ]
  say("check %s vs out/F_s11 (glm last iterate): records %d/%d events %d/%d; AUC %.3f vs %.3f; expected %.1f vs %.1f; TP %.1f vs %.1f",
      k, a$records, b0$records, a$events, b0$events, a$auc_apparent, b0$auc_apparent, a$expected_events, b0$expected_events,
      a$turning_point, b0$turning_point)
}

## ---- theme and palette -------------------------------------------------------------
fit_cols <- c("Baseline" = "#999999", "Recovered (i)" = "#56B4E9", "Recovered (ii)" = "#D55E00")
fit_shp  <- c("Baseline" = 16, "Recovered (i)" = 17, "Recovered (ii)" = 15)
fit_lty  <- c("Baseline" = "22", "Recovered (i)" = "42", "Recovered (ii)" = "solid")
TXT <- 2.4
theme_koa <- function(base_size = 8) {
  theme_classic(base_size = base_size) +
    theme(text = element_text(colour = "black"), axis.text = element_text(size = base_size - 1, colour = "black"),
          axis.line = element_line(linewidth = 0.3), axis.ticks = element_line(linewidth = 0.3),
          panel.background = element_rect(fill = "white", colour = NA), plot.background = element_rect(fill = "white", colour = NA),
          strip.background = element_blank(), strip.text = element_text(size = base_size, face = "bold", hjust = 0),
          legend.key.size = unit(3.2, "mm"), legend.text = element_text(size = base_size - 1),
          legend.margin = margin(0, 0, 0, 0), plot.tag = element_text(size = base_size + 1, face = "bold"),
          plot.margin = margin(2, 4, 2, 2))
}
theme_set(theme_koa())
savefig <- function(p, stem, h_mm) {
  ggsave(file.path(TC2, paste0(stem, ".png")), p, width = 170, height = h_mm, units = "mm", dpi = 300, bg = "white")
  ggsave(file.path(TC2, paste0(stem, ".pdf")), p, width = 170, height = h_mm, units = "mm", device = cairo_pdf, bg = "white")
  say("wrote %s, 170 x %d mm, 300 dpi PNG and PDF", stem, h_mm)
}

## =============================== Figure S3 ===============================
ssq <- function(x) sign(x) * sqrt(abs(x))
CO$fit <- factor(CO$fit, levels = fit_lv); CO$par <- factor(CO$par, levels = rev(par_lv))
iv <- rbind(data.frame(CO[, c("fit", "par")], scheme = "Installation clustered", lo = CO$cl_lo, hi = CO$cl_hi),
            data.frame(CO[, c("fit", "par")], scheme = "Delete-one-installation jackknife", lo = CO$jk_lo, hi = CO$jk_hi))
iv$scheme <- factor(iv$scheme, levels = c("Installation clustered", "Delete-one-installation jackknife"))
lim <- max(abs(c(iv$lo, iv$hi)), na.rm = TRUE) * 1.05
brk <- c(-100, -50, -20, -5, 0, 5, 20, 50, 100); brk <- brk[abs(brk) <= lim]
par_lab <- c(b0 = "b[0]~'(intercept)'", b1 = "b[1]~'(HT)'", b2 = "b[2]~'(ln HT)'", b3 = "b[3]~'(rHT)'",
             b4 = "b[4]~'(ln CR)'", b5 = "b[5]~'(ln HT/DBH)'", b6 = "b[6]~'(ln BYI/100)'", b7 = "b[7]~'(BYI/1000)'")
pa <- ggplot() +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.3) +
  geom_linerange(data = iv, aes(y = par, xmin = ssq(lo), xmax = ssq(hi), colour = fit, linewidth = scheme, group = fit),
                 position = position_dodge(width = 0.74)) +
  geom_point(data = CO, aes(y = par, x = ssq(est), colour = fit, shape = fit, group = fit),
             position = position_dodge(width = 0.74), size = 1.2) +
  scale_x_continuous(breaks = ssq(brk), labels = brk, limits = ssq(c(-lim, lim))) +
  scale_y_discrete(labels = function(v) parse(text = par_lab[v])) +
  scale_colour_manual(values = fit_cols, name = "Fit") + scale_shape_manual(values = fit_shp, name = "Fit") +
  scale_linewidth_manual(values = c("Installation clustered" = 0.95, "Delete-one-installation jackknife" = 0.28), name = "95% interval") +
  labs(x = "Coefficient estimate (signed square-root scale)", y = NULL) +
  guides(colour = guide_legend(order = 1), shape = guide_legend(order = 1),
         linewidth = guide_legend(order = 2, override.aes = list(colour = "black"))) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

lor <- do.call(rbind, lapply(names(S), function(k) {
  d <- S[[k]]; ev <- tapply(1 - d$alive, d$inst, sum); ev <- sort(ev, decreasing = TRUE)
  data.frame(fit = fit_lv[[k]], x = c(0, seq_along(ev) / length(ev)), y = c(0, cumsum(ev) / sum(ev)))
}))
lor$fit <- factor(lor$fit, levels = fit_lv)
top1 <- data.frame(fit = factor(fit_lv, levels = fit_lv), x = 1 / CP$installations, y = CP$largest_share_pct / 100,
                   share = CP$largest_share_pct, dy = c(0, 0.07, -0.07))
pb <- ggplot(lor, aes(x, y, colour = fit, linetype = fit)) +
  geom_abline(slope = 1, intercept = 0, colour = "grey70", linewidth = 0.3, linetype = "dotted") +
  geom_step(linewidth = 0.5, direction = "vh") +
  geom_point(data = top1, aes(x, y, colour = fit, shape = fit), inherit.aes = FALSE, size = 1.3) +
  annotate("text", x = 0.30, y = 0.53, hjust = 0, size = TXT, colour = "grey30", label = "largest single installation") +
  geom_text(data = top1, aes(x = 0.30, y = c(0.45, 0.37, 0.29), colour = fit, label = sprintf("%s %.1f%%", fit, share)),
            inherit.aes = FALSE, hjust = 0, size = TXT, show.legend = FALSE) +
  annotate("text", x = 0.98, y = 0.03, hjust = 1, vjust = 0, size = TXT, colour = "grey45", label = "equal sharing") +
  scale_x_continuous(labels = label_percent(accuracy = 1), limits = c(0, 1)) +
  scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, 1.02)) +
  scale_colour_manual(values = fit_cols) + scale_shape_manual(values = fit_shp) + scale_linetype_manual(values = fit_lty) +
  guides(colour = "none", shape = "none", linetype = "none") +
  labs(x = "Installations, ordered by event count", y = "Cumulative share of mortality events")

src_lv <- c("KMR PSP", "FIA", "PSP", "DOFAW")
bs <- do.call(rbind, lapply(seq_len(nrow(CP)), function(i)
  data.frame(fit = fit_lv[[CP$sample[i]]], Data = src_lv, events = unlist(CP[i, c("ev_KMRPSP", "ev_FIA", "ev_PSP", "ev_DOFAW")]))))
bs$fit <- factor(bs$fit, levels = fit_lv); bs$Data <- factor(bs$Data, levels = src_lv)
rng <- do.call(rbind, lapply(split(bs, bs$Data), function(g) data.frame(Data = g$Data[1], lo = min(g$events), hi = max(g$events))))
dg <- position_dodge(width = 0.68)
pc <- ggplot(bs, aes(x = events, y = Data)) +
  geom_segment(data = rng, aes(x = lo, xend = hi, y = Data, yend = Data), inherit.aes = FALSE, colour = "grey85", linewidth = 0.9) +
  geom_point(aes(colour = fit, shape = fit, group = fit), position = dg, size = 1.4) +
  geom_text(aes(label = events, colour = fit, group = fit), position = dg, hjust = -0.4, size = TXT, show.legend = FALSE) +
  scale_x_continuous(limits = c(-10, max(bs$events) * 1.2), breaks = seq(0, 800, 200)) +
  scale_colour_manual(values = fit_cols) + scale_shape_manual(values = fit_shp) +
  guides(colour = "none", shape = "none") + labs(x = "Independent mortality events", y = NULL)

tpd <- data.frame(fit = factor(fit_lv, levels = fit_lv), tp = CP$turning_point, lo = CP$tp_lo, hi = CP$tp_hi)
JK$fit <- factor(fit_lv[JK$sample], levels = fit_lv)
JK$yy <- as.numeric(JK$fit) + 0.28
JK$kul <- grepl("Kulani", JK$inst)
xl <- range(c(tpd$lo, tpd$hi, JK$tp), finite = TRUE)
pdd <- ggplot() +
  geom_linerange(data = tpd, aes(y = as.numeric(fit), xmin = lo, xmax = hi, colour = fit), linewidth = 0.95) +
  geom_point(data = tpd, aes(y = as.numeric(fit), x = tp, colour = fit, shape = fit), size = 1.7) +
  geom_point(data = JK[!JK$kul, ], aes(x = tp, y = yy, colour = fit), shape = 124, size = 1.8, alpha = 0.7) +
  geom_point(data = JK[JK$kul, ], aes(x = tp, y = yy), shape = 124, size = 2.6, colour = "black") +
  geom_text(data = JK[JK$kul, ], aes(x = tp, y = yy + 0.16, label = "Kulani deleted"), size = TXT, hjust = 0.5) +
  scale_y_continuous(breaks = 1:3, labels = fit_lv, limits = c(0.6, 3.6)) +
  scale_x_continuous(limits = c(floor(xl[1] / 25) * 25, ceiling(xl[2] / 25) * 25)) +
  scale_colour_manual(values = fit_cols) + scale_shape_manual(values = fit_shp) +
  guides(colour = "none", shape = "none") +
  labs(x = expression(BYI~turning~point~(Mg~ha^-1)), y = NULL) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

figS3 <- (pa / (pb | pc) / pdd) + plot_layout(heights = c(1.5, 1, 0.75), guides = "collect") +
  plot_annotation(tag_levels = "a", tag_prefix = "(", tag_suffix = ")") &
  theme(legend.position = "bottom", legend.box = "vertical", legend.direction = "horizontal")
savefig(figS3, "FigS3_survival_recovery_censored", 200)

## =============================== Figure S7 ===============================
yg <- seq(1, 20, by = 0.25)
sc <- do.call(rbind, lapply(names(S), function(k) data.frame(fit = fit_lv[[k]], yip = yg,
  p = vapply(yg, function(y) mean(1 - exp(-y * exp(etas[[k]]))), numeric(1)))))
sc$fit <- factor(sc$fit, levels = fit_lv)
write.csv(sc, "FigS7a_survival_by_interval.csv", row.names = FALSE)
ann <- sc[sc$fit == "Recovered (ii)" & sc$yip %in% c(1, 10), ]
pf <- ggplot(sc, aes(yip, p, colour = fit, linetype = fit, linewidth = fit)) + geom_line() +
  geom_point(data = ann, aes(yip, p, colour = fit), shape = 15, inherit.aes = FALSE, size = 1.4, show.legend = FALSE) +
  geom_text(data = ann, aes(x = yip + 0.6, y = p, colour = fit, label = sprintf("%.3f", p)), inherit.aes = FALSE,
            hjust = 0, vjust = 1.6, size = TXT, show.legend = FALSE) +
  annotate("text", x = 20, y = 0.03, hjust = 1, vjust = 0, size = TXT, colour = "grey35", label = "a survival function must fall, not rise") +
  scale_x_continuous(limits = c(0, 20.6), breaks = seq(0, 20, 5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  scale_colour_manual(values = fit_cols, name = "Fit") +
  scale_linetype_manual(values = fit_lty, name = "Fit") +
  scale_linewidth_manual(values = c("Baseline" = 0.5, "Recovered (i)" = 1.3, "Recovered (ii)" = 0.5), guide = "none") +
  labs(x = "Interval length (yr)", y = expression(Mean~modeled~italic(P)*"(alive)"))

## (b) density gradient on the standardised recovered (ii) sample
EQ9 <- c(onset = 200, full = 850, base_nat = 0.003, base_plt = 0.006, lift = 0.15, cap = 0.20)
eq9 <- function(sdi, base) pmin(EQ9[["cap"]], base + EQ9[["lift"]] * pmin(1, pmax(0, (sdi - EQ9[["onset"]]) / (EQ9[["full"]] - EQ9[["onset"]]))))
si <- S[["recovered_ii"]]; si$eta <- etas[["recovered_ii"]]
si$p_dead_eq5 <- exp(-exp(pmin(si$eta, 700)) * si$yip)
si$sdi_use <- ifelse(is.na(si$sdi), 0, si$sdi)
si$m9 <- eq9(si$sdi_use, ifelse(si$planted == 1, EQ9[["base_plt"]], EQ9[["base_nat"]]))
si$p_dead_eq9 <- 1 - (1 - si$m9)^si$yip
OBS_II <- sum(si$alive == 0); EXP9_II <- sum(si$p_dead_eq9)
say("Eq. 9 ramp expected events on recovered (ii): %.1f against %d observed", EXP9_II, OBS_II)
st <- si[order(si$alive), ]
st <- st[!duplicated(st[, c("source", "inst", "plot", "tree", "t0")]), ]
st <- st[st$dbh >= 2.5, ]
nNA <- sum(is.na(st$sdi)); st <- st[!is.na(st$sdi), ]
say("standardised recovered (ii): n %d, events %d, tree-years %.0f, installations %d (dropped %d records without SDI)",
    nrow(st), sum(st$alive == 0), sum(st$yip), length(unique(st$inst)), nNA)
st$bin <- cut(st$sdi, c(0, 100, 200, 350, 500, 850, 1200, Inf), include.lowest = TRUE)
dens <- do.call(rbind, lapply(split(st, st$bin, drop = TRUE), function(g) data.frame(
  bin = as.character(g$bin[1]), n = nrow(g), events = sum(g$alive == 0), tree_years = sum(g$yip), sdi = median(g$sdi),
  plots = length(unique(paste(g$inst, g$plot))),
  Observed = 100 * sum(g$alive == 0) / sum(g$yip), Eq5 = 100 * sum(g$p_dead_eq5) / sum(g$yip), Eq9 = 100 * sum(g$p_dead_eq9) / sum(g$yip))))
write.csv(dens, "FigS7b_density_bins.csv", row.names = FALSE)
for (i in seq_len(nrow(dens))) say("  bin %-12s n %5d ev %4d ty %6.0f medSDI %6.1f obs %.3f Eq5 %.3f Eq9 %.3f %%/yr",
                                   dens$bin[i], dens$n[i], dens$events[i], dens$tree_years[i], dens$sdi[i], dens$Observed[i], dens$Eq5[i], dens$Eq9[i])
lab_obs <- "Observed"; lab5 <- "Eq. 5 refit, recovered (ii)"; lab9 <- "Retired density ramp"; labM1 <- "Deployed: gated M1 x natural factor (projected natural stands)"
dl <- rbind(data.frame(sdi = dens$sdi, pct = dens$Observed, series = lab_obs),
            data.frame(sdi = dens$sdi, pct = dens$Eq5, series = lab5),
            data.frame(sdi = dens$sdi, pct = dens$Eq9, series = lab9))
ramp <- rbind(data.frame(sdi = seq(15, 1900, 5), origin = "natural"), data.frame(sdi = seq(15, 1900, 5), origin = "planted"))
ramp$pct <- 100 * eq9(ramp$sdi, ifelse(ramp$origin == "planted", EQ9[["base_plt"]], EQ9[["base_nat"]]))
TR <- read.csv(file.path(TC2, "S18_trajectories_100yr.csv"))
dep <- TR[TR$cand == "M1" & TR$factor == 1 & TR$planted == 0 & TR$year <= 100, c("byi", "year", "SDI", "m_stand", "m_realised", "TPH")]
dep <- dep[order(dep$byi, dep$year), ]; dep$pct <- 100 * dep$m_stand
write.csv(dep, "FigS7b_deployed_M1_natural_paths.csv", row.names = FALSE)
for (b in c(100, 264, 450)) { g <- dep[dep$byi == b, ]
  say("deployed M1 x factor, natural BYI %d: SDI %.0f to %.0f, stand rate %.2f to %.2f %%/yr, TPH-weighted realised %.3f %%/yr",
      b, min(g$SDI), max(g$SDI), min(g$pct), max(g$pct), 100 * weighted.mean(g$m_realised, g$TPH)) }
dend <- do.call(rbind, lapply(split(dep, dep$byi), function(g) g[which.max(g$m_stand), ]))
ser_cols <- c("Observed" = "#000000", "Eq. 5 refit, recovered (ii)" = "#D55E00", "Retired density ramp" = "#CC79A7",
              "Deployed: gated M1 x natural factor (projected natural stands)" = "#332288")
ser_shp <- c("Observed" = 16, "Eq. 5 refit, recovered (ii)" = 15, "Retired density ramp" = 18, "Deployed: gated M1 x natural factor (projected natural stands)" = NA)
dep$series <- labM1
pg <- ggplot() +
  geom_line(data = ramp, aes(sdi, pct, group = origin), colour = ser_cols[[lab9]], linewidth = 0.3, linetype = "22") +
  geom_path(data = dep, aes(SDI, pct, group = byi, colour = series), linewidth = 0.6) +
  geom_line(data = dl, aes(sdi, pct, colour = series), linewidth = 0.5) +
  geom_point(data = dl, aes(sdi, pct, colour = series, shape = series), size = 1.4) +
  scale_x_log10(limits = c(15, 2100), breaks = c(20, 50, 200, 500, 2000), labels = label_comma()) +
  scale_y_log10(breaks = c(0.1, 0.3, 1, 3, 10), labels = c("0.1", "0.3", "1", "3", "10")) +
  scale_colour_manual(values = ser_cols, name = NULL, breaks = names(ser_cols)) +
  scale_shape_manual(values = ser_shp, name = NULL, breaks = names(ser_cols), na.translate = FALSE) +
  guides(colour = guide_legend(ncol = 2, order = 3, override.aes = list(shape = c(16, 15, 18, NA))), shape = "none") +
  labs(x = expression(Stand~density~index~(trees~ha^-1)), y = expression(Annual~mortality~('%'~yr^-1)))

## (c) observed against expected
LV <- read.csv(file.path(ROOT, "out_span", "H_mort_level_natural.csv"))
LV <- LV[LV$form == "mult", ]
IV <- read.csv(file.path(ROOT, "out_span", "H_mort_intervals_natural_mult.csv"))
say("natural interval file: %d intervals, %d plots", nrow(IV), length(unique(IV$pid)))
obs_iv <- sum(IV$tph0 * (1 - IV$obs_surv))
calib <- rbind(
  data.frame(panel = "Tree records (events)", row = paste0("Eq. 5, ", fit_lv), series = fit_lv, observed = CP$events, expected = CP$expected_events),
  data.frame(panel = "Tree records (events)", row = "Retired ramp, recovered (ii)", series = lab9, observed = OBS_II, expected = EXP9_II),
  data.frame(panel = "Natural plot intervals (trees per ha)",
             row = c("M1 without factor", "M1 x factor (in sample)", "M1 x factor (LOIO)"),
             series = c("M1 uncal", labM1, labM1), observed = obs_iv,
             expected = c(sum(IV$tph0 * (1 - IV$pr_surv_uncal_mult)), sum(IV$tph0 * (1 - IV$pr_surv_cal_mult)), LV$loio_cal)))
calib$pct <- 100 * (calib$expected / calib$observed - 1)
write.csv(calib, "FigS7c_observed_expected.csv", row.names = FALSE)
for (i in seq_len(nrow(calib))) say("  %-38s observed %9.1f expected %9.1f (%+.1f%%)", calib$row[i], calib$observed[i], calib$expected[i], calib$pct[i])
say("  level file check: obs_deaths %.1f, pred_uncal %.1f, level %.5f", LV$obs_deaths, LV$pred_deaths_uncal, LV$level)
calib$row <- factor(calib$row, levels = rev(calib$row))
calib$panel <- factor(calib$panel, levels = c("Tree records (events)", "Natural plot intervals (trees per ha)"))
cc <- c(fit_cols, "Retired density ramp" = ser_cols[[lab9]], "M1 uncal" = "#DDAA33", ser_cols[labM1])
ph <- ggplot(calib, aes(y = row)) +
  geom_segment(aes(x = observed, xend = expected, yend = row, colour = series), linewidth = 0.5,
               arrow = arrow(length = unit(1.2, "mm"), type = "closed")) +
  geom_point(aes(x = observed), shape = 21, fill = "white", colour = "black", size = 1.5) +
  geom_point(aes(x = expected, colour = series), shape = 16, size = 1.5) +
  geom_text(aes(x = pmax(expected, observed), label = sub("^[-+]0%$", "0%", sprintf("%+.0f%%", pct)), colour = series), hjust = -0.3, size = TXT, show.legend = FALSE) +
  facet_wrap(~panel, ncol = 1, scales = "free") +
  scale_x_log10(labels = label_comma(accuracy = 1), expand = expansion(mult = c(0.08, 0.35))) +
  scale_colour_manual(values = cc) + guides(colour = "none") +
  labs(x = "Mortality, observed (open) against expected (filled)", y = NULL)

disc <- rbind(data.frame(fit = fit_lv, metric = "Apparent AUC", value = CP$auc_apparent, ref = 0.5),
              data.frame(fit = fit_lv, metric = "Brier skill score", value = CP$brier_skill, ref = 0))
disc$fit <- factor(disc$fit, levels = fit_lv)
pi_ <- ggplot(disc, aes(x = fit, y = value, colour = fit)) +
  geom_hline(aes(yintercept = ref), colour = "grey55", linewidth = 0.3, linetype = "dashed") +
  geom_segment(aes(xend = fit, y = ref, yend = value), linewidth = 0.5) +
  geom_point(aes(shape = fit), size = 1.6) +
  geom_text(aes(label = sprintf("%.3f", value)), hjust = -0.28, size = TXT, show.legend = FALSE) +
  facet_wrap(~metric, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = fit_cols) + scale_shape_manual(values = fit_shp) +
  scale_x_discrete(labels = c("Baseline", "Rec. (i)", "Rec. (ii)"), expand = expansion(add = c(0.6, 1.0))) +
  scale_y_continuous(expand = expansion(c(0.2, 0.25))) +
  guides(colour = "none", shape = "none") + labs(x = NULL, y = NULL)

figS7 <- ((pf | pg) + plot_layout(widths = c(1, 1.25))) / ((ph | pi_) + plot_layout(widths = c(1.5, 1))) + plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "a", tag_prefix = "(", tag_suffix = ")") &
  theme(legend.position = "bottom", legend.box = "vertical", legend.direction = "horizontal")
savefig(figS7, "FigS7_survival_deployability_censored", 150)
say("done")
