## figS12_v103.R (koa v103, a2/figs, 2026-09-30). Supplemental Figs S1 (static height, HCB and survival diagnostics) and S2
## (increment diagnostics) under the v103 deployed components, v104 style. Rebuilt from, not copied from, koa_v102 track5_figS
## C1b_FigS1_v102.R and C1a_FigS2_v102.R (no refit here: the deployed v103 vectors are scored on the v103 frames).
## S1: HT_P v103 (track3_s02/v103/02_height_fit.rds) on frames/final/tree_join_v103.csv; HCB_P (engine_v103 LineageA.HCB, unchanged)
##   on frames/final/AK_HCB_v103.csv with BAL l and repaired all species BAPH; Eq. 5 (v102 vector kept, engine_v103 LineageA.SURV)
##   on frames/final/AK_SURV_v103.csv. S2: deployed dDBH (v102 vector, origin constants re-solved under BAL l on the NO frame) and
##   dHT_L_NO (out/inc/fits_v103.rda) on frames/final/d*_NO_v103_model.csv. Standardized residuals use the varPower(DBH.0) scale of
##   the NO frame L fit of the same response. Bootstrap intervals by installation (S1) or tree (S2 autocorrelation), 1000 draws.
suppressPackageStartupMessages({ library(nlme); library(ggplot2); library(patchwork) })
set.seed(20260930)
J <- path.expand("~/jobs/koa_v103_20260930"); F <- file.path(J, "a2/figs"); OUT <- file.path(F, "out"); DAT <- file.path(F, "data"); NB <- 1000
th <- theme_classic(base_size = 7.5, base_family = "Liberation Sans") +
  theme(panel.background = element_rect(fill = "white", colour = NA), plot.background = element_rect(fill = "white", colour = NA),
        axis.line = element_line(linewidth = 0.35), axis.ticks = element_line(linewidth = 0.3), axis.text = element_text(size = 6.5, colour = "black"),
        plot.tag = element_text(size = 8, face = "bold"), legend.key.size = unit(3, "mm"), legend.background = element_blank())
save2 <- function(p, stem, w, h) {
  ggsave(file.path(OUT, paste0(stem, ".png")), p, width = w, height = h, units = "mm", dpi = 300, bg = "white")
  ggsave(file.path(OUT, paste0(stem, ".tiff")), p, width = w, height = h, units = "mm", dpi = 600, bg = "white", compression = "lzw"); cat("saved", stem, "\n") }
PT <- list(size = 0.35, alpha = 0.25, shape = 16, colour = "grey25"); LCOL <- "#0F6E64"
p_op <- function(D, xl, yl) { lim <- range(c(0, D$pa, D$obs))
  ggplot(D, aes(pa, obs)) + do.call(geom_point, PT) + geom_abline(slope = 1, intercept = 0, linetype = 2, linewidth = 0.4) +
    geom_smooth(method = "lm", formula = y ~ x, se = TRUE, colour = LCOL, fill = LCOL, alpha = 0.25, linewidth = 0.5) +
    coord_equal(xlim = lim, ylim = lim) + labs(x = xl, y = yl) + th }
p_rv <- function(D, xl) ggplot(D, aes(pa, rs)) + do.call(geom_point, PT) + geom_hline(yintercept = 0, linetype = 2, linewidth = 0.4) +
  geom_smooth(method = "loess", formula = y ~ x, span = 0.75, se = TRUE, colour = LCOL, fill = LCOL, alpha = 0.3, linewidth = 0.5) + labs(x = xl, y = "Standardized residual") + th
p_qq <- function(D) ggplot(D, aes(sample = rs)) + stat_qq(size = 0.35, alpha = 0.35, shape = 16, colour = "grey25") + stat_qq_line(colour = LCOL, linewidth = 0.5) +
  labs(x = "Theoretical normal quantile", y = "Standardized residual quantile") + th
strip_comments <- function(x) sub("#.*$", "", x)
eq_txt <- strip_comments(readLines(file.path(J, "engine_v103/koa_equations.py")))
py_dict <- function(txt, start_pat, after_line = 1) { i <- grep(start_pat, txt); i <- i[i >= after_line][1]; s <- txt[i]; k <- i
  while (!grepl("\\)", s)) { k <- k + 1; s <- paste(s, txt[k]) }
  m <- regmatches(s, gregexpr("([A-Za-z][A-Za-z0-9_]*)=(-?[0-9.]+(e-?[0-9]+)?)", s))[[1]]; v <- as.numeric(sub("^[^=]*=", "", m)); names(v) <- sub("=.*$", "", m); v }
lineA <- grep("^class LineageA", eq_txt)
HCB <- py_dict(eq_txt, "^\\s+HCB = dict\\(", lineA); SURV <- py_dict(eq_txt, "^\\s+SURV = dict\\(", lineA); stopifnot(length(HCB) == 6, length(SURV) == 8)
args <- commandArgs(TRUE); if (!length(args)) args <- c("s1", "s2")
stats <- list()
opst <- function(lab, o, p) { f <- lm(o ~ p); data.frame(component = lab, n = length(o), bias_pred_minus_obs = mean(p - o), rmse = sqrt(mean((o - p)^2)),
  r2 = 1 - sum((o - p)^2) / sum((o - mean(o))^2), intercept = coef(f)[1], slope = coef(f)[2], slope_lo95 = confint(f)[2, 1], slope_hi95 = confint(f)[2, 2], row.names = NULL) }

if ("s1" %in% args) {
  H <- readRDS(file.path(J, "track3_s02/v103/02_height_fit.rds"))
  tj <- read.csv(file.path(J, "frames/final/tree_join_v103.csv"), stringsAsFactors = FALSE)
  tj <- tj[which(tolower(tj$status) == "live" & tj$dbh > 0 & tj$expf > 0), ]
  tj$rd <- tj$dbh / ave(tj$dbh, interaction(tj$source, tj$inst, tj$plot, tj$year, drop = TRUE), FUN = max)
  tj <- tj[which(tj$ht > 0 & is.finite(tj$byi) & is.finite(tj$baph)), ]
  p <- H$coef; pa <- (p[["a0"]] + p[["a1"]] * tj$byi / 100) * (1 - exp(-p[["b"]] * tj$dbh))^p[["c"]] * exp(p[["g1"]] * log(tj$baph + 1) + p[["g2"]] * tj$rd)
  HT <- data.frame(obs = tj$ht, pa = pa, rs = (tj$ht - pa) / sd(tj$ht - pa)); stopifnot(nrow(HT) == 8914)
  stats$ht <- opst("height, HT_P v103 population average", HT$obs, HT$pa)
  hc <- read.csv(file.path(J, "frames/final/AK_HCB_v103.csv"), stringsAsFactors = FALSE)
  hc <- hc[complete.cases(hc[, c("DBH", "HT", "HCB", "BAPH_hi", "BALl", "BYI")]) & hc$DBH > 0 & hc$HT > 0, ]
  eta <- HCB[1] + HCB[2] * sqrt(hc$HT / 100) + HCB[3] * log(pmax(hc$HT / pmax(hc$DBH, 0.1), 0.5)) + HCB[4] * sqrt(hc$BALl * hc$BAPH_hi + 1) + HCB[5] * log(hc$BAPH_hi + 1) + HCB[6] * log(pmax(hc$BYI, 1) / 100)
  hp <- pmin(pmax(hc$HT / (1 + exp(-eta)), 0), 0.95 * hc$HT)
  HCd <- data.frame(obs = hc$HCB, pa = hp, rs = (hc$HCB - hp) / sqrt(sum((hc$HCB - hp)^2) / (nrow(hc) - 6)))
  stats$hcb <- opst("HCB, HCB_P deployed, BAL l, repaired BAPH", HCd$obs, HCd$pa)
  s <- read.csv(file.path(J, "frames/final/AK_SURV_v103.csv"), stringsAsFactors = FALSE)
  f <- subset(s, DBH.0 > 0 & Status.0 == "live" & YIP > 0 & dDBH.ann > 0 & dDBH.ann < 10); f$slender <- f$HT.0 / f$DBH.0
  y <- ifelse(f$Status.1 == "live", 1L, 0L); inst <- paste(f$Data, f$Install)
  X <- with(f, cbind(1, HT.0, log(HT.0), rHT.0, log(CR.0), log(slender), log(BYI / 100), BYI / 1000))
  p <- 1 - exp(-exp(as.vector(X %*% SURV) + log(f$YIP))); ok <- is.finite(p); p <- p[ok]; y <- y[ok]; inst <- inst[ok]
  cat("survival rows", length(y), "deaths", sum(y == 0), "\n")
  qd <- ceiling(10 * rank(p, ties.method = "first") / length(p))
  hl <- do.call(rbind, lapply(1:10, function(k) { i <- qd == k; bt <- binom.test(sum(y[i]), sum(i))
    data.frame(decile = k, n = sum(i), mean_pred_survival = mean(p[i]), obs_survival = mean(y[i]), lo = bt$conf.int[1], hi = bt$conf.int[2]) }))
  aucv <- { r <- rank(1 - p); dd <- y == 0; (sum(r[dd]) - sum(dd) * (sum(dd) + 1) / 2) / (sum(dd) * sum(!dd)) }
  stats$surv <- data.frame(component = "survival, Eq. 5 v102 vector on the v103 frame", n = length(y), bias_pred_minus_obs = mean(p) - mean(y),
                           rmse = sqrt(mean((y - p)^2)), r2 = NA, intercept = NA, slope = NA, slope_lo95 = NA, slope_hi95 = NA, auc = aucv, deaths = sum(y == 0), exp_deaths = sum(1 - p))
  write.csv(hl, file.path(DAT, "FigS1_survival_deciles_v103.csv"), row.names = FALSE)
  SV <- data.frame(p = pmin(p, 1 - 1e-12), y = y, status = factor(ifelse(y == 1, "Alive", "Dead"), c("Alive", "Dead")))
  SV$pr <- (SV$y - SV$p) / sqrt(SV$p * (1 - SV$p))
  str_tr <- scales::trans_new("survival", function(x) -log10(1 - x), function(x) 1 - 10^(-x))
  sbrk <- c(0.9, 0.999, 1 - 1e-6, 1 - 1e-12); slab <- parse(text = c("0.9", "0.999", "1-10^-6", "1-10^-12"))
  lim_g <- range(c(hl$mean_pred_survival, hl$lo, hl$hi))
  p_g <- ggplot(hl, aes(mean_pred_survival, obs_survival)) + geom_abline(slope = 1, intercept = 0, linetype = 2, linewidth = 0.4) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0, linewidth = 0.4, colour = "grey30") + geom_point(size = 1.4, colour = LCOL) +
    coord_equal(xlim = lim_g, ylim = lim_g) + labs(x = "Mean predicted interval survival", y = "Observed proportion surviving") + th
  p_h <- ggplot(SV, aes(p, fill = status, colour = status)) + geom_density(alpha = 0.35, linewidth = 0.4, adjust = 1.2) +
    geom_rug(data = SV[SV$y == 0, ], aes(x = p), inherit.aes = FALSE, colour = "#9E2B25", linewidth = 0.3, length = unit(1.5, "mm")) +
    scale_x_continuous(trans = str_tr, breaks = sbrk, labels = slab) +
    scale_fill_manual(values = c(Alive = "grey45", Dead = "#9E2B25"), name = NULL) + scale_colour_manual(values = c(Alive = "grey25", Dead = "#9E2B25"), name = NULL) +
    labs(x = "Predicted interval survival", y = "Density") + th + theme(legend.position = "top", legend.margin = margin(0, 0, -4, 0), plot.margin = margin(4, 8, 4, 4))
  p_i <- ggplot(SV, aes(p, pr)) + geom_point(aes(colour = status), size = 0.45, alpha = 0.4, shape = 16) + geom_hline(yintercept = 0, linetype = 2, linewidth = 0.4) +
    geom_smooth(method = "loess", formula = y ~ x, span = 0.75, se = TRUE, colour = LCOL, fill = LCOL, alpha = 0.3, linewidth = 0.5) +
    scale_x_continuous(trans = str_tr, breaks = sbrk, labels = slab) +
    scale_y_continuous(trans = scales::pseudo_log_trans(sigma = 1, base = 10), breaks = c(-10^c(6, 4, 2), 0), labels = parse(text = c("-10^6", "-10^4", "-10^2", "0"))) +
    scale_colour_manual(values = c(Alive = "grey25", Dead = "#9E2B25"), name = NULL) + labs(x = "Predicted interval survival", y = "Pearson residual") + th +
    theme(legend.position = c(0.02, 0.02), legend.justification = c(0, 0), plot.margin = margin(4, 8, 4, 4))
  fig <- p_op(HT, "Predicted height (m)", "Observed height (m)") + p_rv(HT, "Predicted height (m)") + p_qq(HT) +
    p_op(HCd, "Predicted height to crown base (m)", "Observed height to crown base (m)") + p_rv(HCd, "Predicted height to crown base (m)") + p_qq(HCd) +
    p_g + p_h + p_i + plot_layout(ncol = 3) + plot_annotation(tag_levels = "a", tag_prefix = "(", tag_suffix = ")")
  save2(fig, "FigS1_height_hcb_survival", 170, 190)
}

if ("s2" %in% args) {
  src <- readLines(file.path(J, "track2/inc/inc_v103.R")); i0 <- grep("^HCB_P <- c\\(", src)[1]; i1 <- grep("^taus <- function", src)[1]
  e <- new.env(); eval(parse(text = src[i0:i1]), envir = e); attach(e, warn.conflicts = FALSE)
  fe <- new.env(); load(file.path(J, "out/inc/fits_v103.rda"), fe)
  wcor <- function(x, y, w) { mx <- sum(w * x) / sum(w); my <- sum(w * y) / sum(w); sum(w * (x - mx) * (y - my)) / sqrt(sum(w * (x - mx)^2) * sum(w * (y - my)^2)) }
  acf_tree <- function(r, id, t, lags = 1:5, B = NB) { o <- order(id, t); r <- r[o]; id <- id[o]; tid <- as.integer(factor(id)); nt <- max(tid); n <- length(r)
    P <- lapply(lags, function(k) { i <- which(tid[seq_len(n - k)] == tid[(k + 1):n]); list(x = r[i], y = r[i + k], g = tid[i]) })
    est <- sapply(P, function(p) if (length(p$x) > 2) cor(p$x, p$y) else NA)
    bs <- t(replicate(B, { w <- tabulate(sample.int(nt, nt, TRUE), nt); sapply(P, function(p) { ww <- w[p$g]; if (sum(ww > 0) > 2) wcor(p$x, p$y, ww) else NA }) }))
    data.frame(lag = lags, r = est, lo95 = apply(bs, 2, quantile, 0.025, na.rm = TRUE), hi95 = apply(bs, 2, quantile, 0.975, na.rm = TRUE), n_pairs = sapply(P, function(p) length(p$x))) }
  res <- list(); acs <- list()
  for (resp in c("dDBH", "dHT")) {
    assign("GUARD", if (resp == "dDBH") 45 else 20, envir = e)
    d <- read.csv(file.path(J, sprintf("frames/final/%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE); d <- model_cols(d, "l")
    b <- if (resp == "dDBH") START$dDBH else fe$CAL$dHT_L_NO$b
    cc <- solve_c(resp, d, b); cat(resp, "rows", nrow(d), "c", round(cc, 5), "\n")
    ## v102 caption plotted the prediction before the origin constants. Under v103 those constants differ by origin by up to 6.6 fold
    ## (dHT c natural 0.44, planted 2.89), so the uncalibrated scale is not interpretable (slope of observed on it about zero; kept in
    ## the stats table). Plotted: the deployed prediction, origin constant applied inside the recursion (b0 + log c by origin).
    praw <- pa_pred(resp, d, b)
    pcal <- numeric(nrow(d)); for (o in c("natural", "planted")) { i <- (d$Planted == 1) == (o == "planted"); bb <- b; bb["b0"] <- b["b0"] + log(cc[[o]]); pcal[i] <- pa_pred(resp, d[i, ], bb) }
    per <- pcal
    m <- fe$FITS[[paste0(resp, "_L_NO")]]; dl <- coef(m$modelStruct$varStruct, unconstrained = FALSE)[["power"]]
    rs <- (d[[resp]] - per) / (m$sigma * abs(d$DBH.0)^dl)
    inst <- paste(d$Data, d$Install); rsc <- rs - ave(rs, inst)
    res[[resp]] <- data.frame(obs = d[[resp]] / d$YIP, pa = per / d$YIP, rs = rs)
    stats[[paste0(resp, "_raw")]] <- cbind(opst(paste(resp, "population average before origin constants, annual"), d[[resp]] / d$YIP, praw / d$YIP), c_natural = cc[["natural"]], c_planted = cc[["planted"]])
    stats[[resp]] <- cbind(opst(paste(resp, "deployed, origin constants in the recursion, annual (plotted)"), d[[resp]] / d$YIP, pcal / d$YIP), c_natural = cc[["natural"]], c_planted = cc[["planted"]])
    for (rt in c("Population-average", "Installation mean removed")) acs[[paste(resp, rt)]] <- cbind(resp = resp, residual = rt, acf_tree(if (rt == "Population-average") rs else rsc, d$TreeID, d$t.0))
  }
  A <- do.call(rbind, acs); A$residual <- factor(A$residual, c("Population-average", "Installation mean removed")); write.csv(A, file.path(DAT, "FigS2_autocorrelation_v103.csv"), row.names = FALSE)
  p_ac <- function(r_) ggplot(A[A$resp == r_, ], aes(lag, r, colour = residual, shape = residual)) + geom_hline(yintercept = 0, linewidth = 0.3) +
    geom_errorbar(aes(ymin = lo95, ymax = hi95), width = 0.2, position = position_dodge(0.4), linewidth = 0.4) + geom_point(position = position_dodge(0.4), size = 1.3) +
    scale_colour_manual(values = c("grey20", LCOL), name = NULL) + scale_shape_manual(values = c(16, 17), name = NULL) + scale_x_continuous(breaks = 1:5) +
    coord_cartesian(ylim = c(min(-0.1, A$lo95, na.rm = TRUE), 1)) + labs(x = "Lag (remeasurement intervals)", y = paste("Within-tree residual correlation,", if (r_ == "dHT") "height" else "diameter")) + th +
    theme(legend.position = c(0.98, 0.98), legend.justification = c(1, 1))
  p_hist <- ggplot(res$dHT, aes(rs)) + geom_histogram(aes(y = after_stat(density)), binwidth = 0.25, fill = "grey75", colour = "grey35", linewidth = 0.15) +
    stat_function(fun = dnorm, args = list(mean = 0, sd = 1), colour = LCOL, linewidth = 0.5) + labs(x = "Standardized residual\n(height increment)", y = "Density") + th
  xd <- expression(paste("Predicted ", Delta, "DBH (cm ", yr^-1, ")")); yd <- expression(paste("Observed ", Delta, "DBH (cm ", yr^-1, ")"))
  xh <- expression(paste("Predicted ", Delta, "HT (m ", yr^-1, ")")); yh <- expression(paste("Observed ", Delta, "HT (m ", yr^-1, ")"))
  fig <- p_op(res$dDBH, xd, yd) + p_rv(res$dDBH, xd) + p_qq(res$dDBH) + p_op(res$dHT, xh, yh) + p_rv(res$dHT, xh) + p_qq(res$dHT) +
    p_ac("dHT") + p_ac("dDBH") + p_hist + plot_layout(ncol = 3) + plot_annotation(tag_levels = "a", tag_prefix = "(", tag_suffix = ")")
  save2(fig, "FigS2_increment_diagnostics", 170, 185)
}
st <- do.call(rbind, lapply(stats, function(x) { for (k in c("auc", "deaths", "exp_deaths", "c_natural", "c_planted")) if (!k %in% names(x)) x[[k]] <- NA; x }))
write.csv(st, file.path(DAT, paste0("FigS12_stats_", paste(args, collapse = "_"), "_v103.csv")), row.names = FALSE); print(st)
