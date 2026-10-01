## figS_v103.R (koa v103, a2/figs, 2026-09-30). Supplemental Figs S5 (integrated long-term validation, plot level units), S6 and S7 (even-aged natural and
## planted projections with joint Monte Carlo bands) and S8 (modified Bakuzis matrix), v104 style (koa_figfix_20260929 figS67.R,
## figS8.R) on v103 inputs. Usage: Rscript figS_v103.R s5 s8 [s67]. s67 requires a2/closeout/MC_PROMOTED.
## Bias sign convention predicted minus observed. BYI in index units. No coordinates are read.
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
args <- commandArgs(TRUE); if (!length(args)) args <- c("s5", "s8")
J <- path.expand("~/jobs/koa_v103_20260930"); F <- file.path(J, "a2/figs"); OUT <- file.path(F, "out"); DAT <- file.path(F, "data")
set.seed(20260930)
COL <- c("100" = "#0F6E64", "264" = "#C08A1E", "450" = "#9E2B25")
th <- theme_classic(base_size = 8, base_family = "Liberation Sans") +
  theme(panel.background = element_rect(fill = "white", colour = NA), plot.background = element_rect(fill = "white", colour = NA),
        axis.line = element_line(linewidth = 0.35), axis.ticks = element_line(linewidth = 0.3), axis.text = element_text(size = 7, colour = "black"),
        axis.title = element_text(size = 7.5), legend.position = "bottom", legend.background = element_blank(),
        legend.text = element_text(size = 6.5), legend.title = element_text(size = 7), plot.tag = element_text(face = "bold", size = 9))
save2 <- function(p, stem, w, h) {
  ggsave(file.path(OUT, paste0(stem, ".png")), p, width = w, height = h, units = "mm", dpi = 300, bg = "white")
  ggsave(file.path(OUT, paste0(stem, ".tiff")), p, width = w, height = h, units = "mm", dpi = 600, bg = "white", compression = "lzw")
  cat("saved", stem, "\n")
}

if ("s5" %in% args) {
  ## Fig S5 (s102 numbering; v100 supplement "Figure S6"): integrated long-term validation, two panels as in the caption of record,
  ## (a) projected against observed cohort survival coloured by initial SDI, (b) observed and projected annual mortality by initial
  ## SDI tertile. v103 units are PLOT level (a2/closeout/validation/val_v103_plotlevel.csv, 18 units). FIA 15-1-1-2628 is the
  ## disturbance case: drawn with its own marker in (a) and as its own column in (b), and excluded from the tertiles and intervals.
  ## Observed survival is expf weighted. Uncertainty: (a) Clopper-Pearson 95% interval of the count survival of the start cohort;
  ## (b) 95% percentile interval of the tertile mean from 5000 bootstrap resamples of plots.
  V <- file.path(J, "a2/closeout/validation")
  v <- fread(file.path(V, "val_v103_plotlevel.csv")); stopifnot(nrow(v) == 18, sum(v$role == "disturbance") == 1, v$pid[v$role == "disturbance"] == "FIA|15-1-1-2628")
  v[, dist := role == "disturbance"]
  v[, grp := fifelse(dist, "FIA 15-1-1-2628 (disturbance)", fifelse(origin == "natural", "Natural", "Planted"))]
  v[, k := round(obs_surv_count * n_records0)]; stopifnot(all(abs(v$k - v$obs_surv_count * v$n_records0) < 1e-6))
  v[, c("lo", "hi") := as.list(binom.test(k, n_records0)$conf.int), by = pid]
  v[, `:=`(obs_ann = 1 - obs_surv_w^(1 / ny), pr_ann = 1 - pr_surv^(1 / ny))]
  r_all <- with(v[!(dist)], cor(obs_surv_w, pr_surv)); r_b <- replicate(5000, { i <- sample(which(!v$dist), replace = TRUE); cor(v$obs_surv_w[i], v$pr_surv[i]) })
  cat(sprintf("S5 r (17 units, excl. 2628) %.3f [%.3f, %.3f]; with 2628 %.3f\n", r_all, quantile(r_b, 0.025, na.rm = TRUE), quantile(r_b, 0.975, na.rm = TRUE), cor(v$obs_surv_w, v$pr_surv)))
  GS <- c(Natural = 16, Planted = 17, `FIA 15-1-1-2628 (disturbance)` = 8)
  pa <- ggplot(v, aes(obs_surv_w, pr_surv)) + geom_abline(slope = 1, intercept = 0, linetype = 2, linewidth = 0.35) +
    geom_errorbar(aes(xmin = lo, xmax = hi, colour = sdi0), width = 0, linewidth = 0.3, alpha = 0.7, orientation = "y") +
    geom_point(aes(colour = sdi0, shape = grp), size = 1.9, stroke = 0.6) +
    scale_colour_viridis_c(option = "D", end = 0.92, name = expression(paste("Initial SDI (trees ", ha^-1, ")")), trans = "sqrt", breaks = c(10, 100, 500, 1500)) +
    scale_shape_manual(values = GS, name = NULL) + scale_x_continuous(limits = c(0, 1), expand = c(0.01, 0)) + scale_y_continuous(limits = c(0, 1), expand = c(0.01, 0)) +
    coord_equal() + labs(x = "Observed cohort survival (fraction)", y = "Projected cohort survival (fraction)", tag = "(a)") + th +
    theme(legend.position = "right", legend.box = "vertical", legend.key.height = unit(3.5, "mm"), legend.key.width = unit(3, "mm"))
  u <- v[!(dist)]; u[, sdit := cut(sdi0, quantile(sdi0, 0:3 / 3), include.lowest = TRUE, labels = c("Low", "Mid", "High"))]
  rng <- u[, .(lab = sprintf("%s\n%.0f to %.0f", sdit[1], min(sdi0), max(sdi0)), n = .N), by = sdit][order(sdit)]
  bt <- function(x) { b <- replicate(5000, mean(sample(x, length(x), TRUE))); c(mean(x), quantile(b, c(0.025, 0.975))) }
  M <- rbind(u[, { o <- bt(obs_ann); p <- bt(pr_ann); .(series = c("Observed", "Projected"), m = c(o[1], p[1]), lo = c(o[2], p[2]), hi = c(o[3], p[3]), n = .N) }, by = sdit],
             v[(dist), .(sdit = "2628", series = c("Observed", "Projected"), m = c(obs_ann, pr_ann), lo = NA_real_, hi = NA_real_, n = 1L)])
  M[, sdit := factor(sdit, c("Low", "Mid", "High", "2628"), c(rng$lab, sprintf("2628\ndisturbance\n%.0f", v$sdi0[v$dist])))]
  fwrite(M, file.path(DAT, "FigS5_mortality_tertiles_v103.csv")); fwrite(v, file.path(DAT, "FigS5_units_v103.csv"))
  print(M)
  pb <- ggplot(M, aes(sdit, m, colour = series, shape = series)) +
    geom_vline(xintercept = 3.5, linewidth = 0.3, colour = "grey60", linetype = "dotted") +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0, linewidth = 0.5, position = position_dodge(0.45), na.rm = TRUE) +
    geom_point(size = 2, position = position_dodge(0.45)) +
    scale_colour_manual(values = c(Observed = "grey25", Projected = "#0F6E64"), name = NULL) + scale_shape_manual(values = c(Observed = 16, Projected = 15), name = NULL) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
    labs(x = expression(paste("Initial SDI tertile (range, trees ", ha^-1, ")")), y = expression(paste("Annual mortality (", yr^-1, ")")), tag = "(b)") + th +
    theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1), axis.text.x = element_text(size = 6.5))
  save2(pa + pb + plot_layout(widths = c(1, 1.05)), "FigS5_validation", 174, 88)
}

if ("s8" %in% args) {
  B <- fread(file.path(J, "engine_v103/out_m1/koa_bakuzis_input_M1.csv"))
  B[, site := factor(site, c(100, 264, 450))]; B[, origin := factor(origin, c("natural", "planted"), c("Natural", "Planted"))]; setorder(B, origin, site, age)
  L <- list(age = "Age (yr)", HT = "Stand height (m)", QMD = "QMD (cm)", TPH = expression(paste("Stems (trees ", ha^-1, ")")),
            BAPH = expression(paste("Basal area (", m^2, " ", ha^-1, ")")), VOL = expression(paste("Volume (", m^3, " ", ha^-1, ")")))
  P <- list(c("age","HT"), c("QMD","HT"), c("age","TPH"), c("QMD","TPH"), c("HT","TPH"), c("TPH","BAPH"), c("HT","VOL"), c("TPH","VOL"))
  ps <- lapply(seq_along(P), function(k) { x <- P[[k]][1]; y <- P[[k]][2]
    g <- ggplot(B, aes(.data[[x]], .data[[y]], colour = site, linetype = origin, group = interaction(site, origin))) + geom_path(linewidth = 0.55) + geom_point(size = 1) +
      scale_colour_manual(values = COL, name = "BYI (index units)") + scale_linetype_manual(values = c(Natural = "solid", Planted = "22"), name = "Origin") +
      labs(x = L[[x]], y = L[[y]], tag = paste0("(", letters[k], ")")) + th
    if (k == 4) g <- g + scale_x_log10(breaks = c(15, 20, 30, 40, 60, 80)) + scale_y_log10(breaks = c(50, 100, 200, 400, 800))
    g })
  save2(wrap_plots(ps, ncol = 3, guides = "collect") & theme(legend.position = "bottom"), "FigS8_bakuzis", 174, 165)
  print(fread(file.path(J, "engine_v103/out_m1/bakuzis_slopes_M1.csv")))
}

if ("s67" %in% args) {
  stopifnot(file.exists(file.path(J, "a2/closeout/MC_PROMOTED")))
  ## reps are global draw indices (500 per scenario x BYI), none is the point run: bands over all draws, point run from traj_M1.csv
  tr <- fread(file.path(J, "engine_v103/out_m1/reps_evenaged_M1.csv"))
  pt <- fread(file.path(J, "engine_v103/out_m1/traj_M1.csv"))[, .(year, QMD, BAPH, TPH, VOL, HT, MORT_VOL, scen = origin, byi, rep = -1L)]
  cat("draws per scen and byi:\n"); print(tr[, uniqueN(rep), by = .(scen, byi)])
  tr <- rbind(tr, pt, use.names = TRUE)
  setorder(tr, scen, byi, rep, year)
  tr[, `:=`(age = year, MAI = VOL / year, GMAI = (VOL + cumsum(MORT_VOL)) / year, PAI = VOL - shift(VOL), SDI = TPH * (QMD / 25.4)^1.605), by = .(scen, byi, rep)]
  tr[, byi := factor(as.character(byi), c("100", "264", "450"))]
  V <- list(QMD = "QMD (cm)", HT = "Stand height (m)", BAPH = expression(paste("Basal area (", m^2, " ", ha^-1, ")")),
            TPH = expression(paste("Stems (trees ", ha^-1, ")")), VOL = expression(paste("Volume (", m^3, " ", ha^-1, ")")),
            SDI = expression(paste("SDI, QMD form (trees ", ha^-1, ")")), MAI = expression(paste("Net MAI (", m^3, " ", ha^-1, " ", yr^-1, ")")),
            GMAI = expression(paste("Gross MAI (", m^3, " ", ha^-1, " ", yr^-1, ")")), PAI = expression(paste("Net PAI (", m^3, " ", ha^-1, " ", yr^-1, ")")))
  mk <- function(sc, stem) { d <- tr[scen == sc & age <= 100]; ps <- list(); k <- 0; bands <- list()
    for (v in names(V)) { k <- k + 1
      x <- d[, .(age, rep, byi, val = get(v))]; if (v %in% c("MAI", "GMAI", "PAI")) x <- x[age >= 5]
      b <- x[rep >= 0, .(lo = quantile(val, 0.025, na.rm = TRUE), hi = quantile(val, 0.975, na.rm = TRUE)), by = .(age, byi)]; p <- x[rep == -1]
      bands[[v]] <- merge(b, p[, .(age, byi, point = val)], by = c("age", "byi"))[, var := v]
      g <- ggplot() + annotate("rect", xmin = 52, xmax = 100, ymin = -Inf, ymax = Inf, fill = "grey93") +
        geom_ribbon(data = b, aes(age, ymin = lo, ymax = hi, fill = byi), alpha = 0.16) + geom_line(data = p, aes(age, val, colour = byi), linewidth = 0.6) +
        scale_colour_manual(values = COL, name = "BYI (index units)") + scale_fill_manual(values = COL, name = "BYI (index units)") +
        scale_x_continuous(breaks = seq(0, 100, 25)) + labs(x = "Stand age (yr)", y = V[[v]], tag = paste0("(", letters[k], ")")) + th
      if (v == "PAI") g <- g + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey40")
      ps[[k]] <- g }
    fwrite(rbindlist(bands), file.path(DAT, paste0(stem, "_bands_DATA_v103.csv")))
    save2(wrap_plots(ps, ncol = 3, guides = "collect") & theme(legend.position = "bottom"), stem, 174, 170) }
  mk("nat", "FigS6_natural"); mk("plt", "FigS7_planted")
  print(tr[rep == -1 & age <= 100, .(peak_age = age[which.max(VOL)], peak_vol = round(max(VOL), 1)), by = .(scen, byi)])
}
cat("done", args, "\n")
