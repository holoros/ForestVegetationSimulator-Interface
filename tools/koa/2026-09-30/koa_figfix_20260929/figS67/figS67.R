## figS67.R (koa_figfix_20260929). Supplemental Figures S6 (even-aged natural) and S7 (even-aged planted) rebuilt from the
## deployed joint Monte Carlo trajectories that also feed Fig. 4, Table 5 and Table S30
## (koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv; rep 0 = point projection, reps 1..500 = joint draws).
## Replaces the 18 September S4/S5 images, which came from an earlier perturbation scheme. Headless, journal register.
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
tr <- fread(path.expand("~/jobs/koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv"))
tr <- tr[scenario %in% c("Even-aged natural", "Even-aged planted")]
setorder(tr, scenario, site, rep, age)
tr[, `:=`(MAI = VOL / age, GMAI = (VOL + cumsum(MORT_VOL)) / age, PAI = VOL - shift(VOL, fill = NA_real_)), by = .(scenario, site, rep)]
chk <- tr[rep == 0 & age %in% c(40, 100), .(scenario, site, age, QMD = round(QMD, 1), VOL = round(VOL, 1), MAI = round(MAI, 2), GMAI = round(GMAI, 2))]
print(chk)
tr[, byi := factor(c(Low = "100", Medium = "264", High = "450")[site], c("100", "264", "450"))]
V <- list(QMD = "QMD (cm)", HT = "Stand height (m)", BAPH = expression(paste("Basal area (", m^2, " ", ha^-1, ")")),
          TPH = expression(paste("Stems (", ha^-1, ")")), VOL = expression(paste("Volume (", m^3, " ", ha^-1, ")")),
          SDI = expression(paste("SDI (trees ", ha^-1, ")")), MAI = expression(paste("Net MAI (", m^3, " ", ha^-1, " ", yr^-1, ")")),
          GMAI = expression(paste("Gross MAI (", m^3, " ", ha^-1, " ", yr^-1, ")")), PAI = expression(paste("Net PAI (", m^3, " ", ha^-1, " ", yr^-1, ")")))
COL <- c("100" = "#0F6E64", "264" = "#C08A1E", "450" = "#9E2B25")
th <- theme_bw(base_size = 8) + theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(linewidth = 0.2, colour = "grey90"),
  legend.position = "bottom", plot.tag = element_text(face = "bold", size = 9), axis.title = element_text(size = 7.5))
mk <- function(scn, stem) {
  d <- tr[scenario == scn]; ps <- list(); k <- 0
  for (v in names(V)) { k <- k + 1
    x <- d[, .(age, rep, byi, val = get(v))]
    if (v %in% c("MAI", "GMAI", "PAI")) x <- x[age >= 5]
    b <- x[rep != 0, .(lo = quantile(val, 0.025, na.rm = TRUE), hi = quantile(val, 0.975, na.rm = TRUE)), by = .(age, byi)]
    p <- x[rep == 0]
    g <- ggplot() + annotate("rect", xmin = 52, xmax = 100, ymin = -Inf, ymax = Inf, fill = "grey92") +
      geom_ribbon(data = b, aes(age, ymin = lo, ymax = hi, fill = byi), alpha = 0.16) +
      geom_line(data = p, aes(age, val, colour = byi), linewidth = 0.6) +
      scale_colour_manual(values = COL, name = "BYI (index units)") + scale_fill_manual(values = COL, name = "BYI (index units)") +
      scale_x_continuous(breaks = seq(0, 100, 25)) + labs(x = "Stand age (yr)", y = V[[v]], tag = paste0("(", letters[k], ")")) + th
    if (v == "PAI") g <- g + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey40")
    ps[[k]] <- g }
  fig <- wrap_plots(ps, ncol = 3, guides = "collect") & theme(legend.position = "bottom")
  ggsave(paste0(stem, ".png"), fig, width = 174, height = 170, units = "mm", dpi = 300, bg = "white")
  ggsave(paste0(stem, ".tiff"), fig, width = 174, height = 170, units = "mm", dpi = 600, bg = "white", compression = "lzw")
  cat("saved", stem, "\n")
}
mk("Even-aged natural", "FigS6_natural")
mk("Even-aged planted", "FigS7_planted")
## peak ages of planted and natural standing volume (point projections), for the caption
print(tr[rep == 0, .(peak_age = age[which.max(VOL)], peak_vol = round(max(VOL), 1)), by = .(scenario, site)])
