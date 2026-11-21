# 71_supp_figs_v141.R  Supplement figures of s133 from the koa 1.15.0 outputs: Fig. S1 band coverage (out/coverage_j1.csv, script 51), Fig. S2 RD,
# height and volume with bands, Fig. S3 both band types at median BYI (ms_v136/scenarios_long_j1.csv, script 51), Fig. S5 Bakuzis matrix of the
# five BYI levels per origin (ms_v141/fig5_trajectories.csv, script 70). Headless, color, 600 dpi. No identifier printed.
suppressMessages({library(data.table); library(ggplot2); library(patchwork)}); setwd("~/jobs/koa_1150_20261121"); dir.create("ms_v141", showWarnings = FALSE)
th <- theme_bw(base_size = 8) + theme(panel.grid.minor = element_blank(), plot.tag = element_text(face = "bold"), strip.background = element_rect(fill = "#EEF3E8"))
oc <- c(Natural = "#2166AC", Planted = "#E08214"); lv <- c(lo = "#B2182B", md = "#4D9221", hi = "#2166AC"); lvl <- c(lo = "10th", md = "50th", hi = "90th")
C <- fread("out/coverage_j1.csv"); C[, origin := factor(ifelse(planted == 1, "Planted", "Natural"), c("Natural", "Planted"))]; C[, var := factor(var, c("surv", "qmd", "ba"), c("Survival", "QMD (cm)", "Basal area (m\u00b2 ha\u207b\u00b9)"))]
setorder(C, site_dev, var, origin, h); C[, idx := seq_len(.N), by = .(site_dev, var)]; C[, row := ifelse(site_dev, "SDImax deviates", "SDImax at Eq. S1 prediction")]
f1 <- ggplot(C, aes(idx, obs, colour = origin)) + geom_linerange(aes(ymin = lo, ymax = hi), alpha = 0.6) + geom_point(aes(shape = inside), size = 1.2) + scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1), name = "Inside band") +
  scale_colour_manual(values = oc, name = "Origin") + geom_vline(data = C[origin == "Natural", .(x = max(idx) + 0.5), by = .(var, row)], aes(xintercept = x), linetype = "dashed", colour = "grey40") +
  facet_wrap(row ~ var, scales = "free_y", ncol = 3) + labs(x = "Plot, ordered by origin and horizon", y = "Observed value and 90% band") + th + theme(legend.position = "bottom")
ggsave("ms_v141/FigS1_coverage.png", f1, width = 180, height = 110, units = "mm", dpi = 600)
S <- fread("ms_v136/scenarios_long_j1.csv"); S[, origin := factor(ifelse(planted == 1, "Planted", "Natural"), c("Natural", "Planted"))]; S[, level := factor(level, c("lo", "md", "hi"))]
pS2 <- function(v, ylab, tag) { d <- S[site_dev == FALSE & var == v]; g <- ggplot(d, aes(year, point, colour = level, fill = level)) + geom_ribbon(aes(ymin = p05, ymax = p95), alpha = 0.15, colour = NA) + geom_line(linewidth = 0.5) +
  geom_vline(data = data.table(origin = factor(c("Natural", "Planted"), c("Natural", "Planted")), x = c(33, 10)), aes(xintercept = x), linetype = "dashed", colour = "grey40") + facet_wrap(~origin, nrow = 1) +
  scale_colour_manual(values = lv, labels = lvl, name = "BYI percentile") + scale_fill_manual(values = lv, labels = lvl, name = "BYI percentile") + labs(x = "Years from start", y = ylab, tag = tag) + th
  if (v == "RD") g <- g + geom_hline(yintercept = 1, linetype = "dashed", colour = "grey30"); g }
f2 <- (pS2("RD", "Relative density", "(a, b)") / pS2("HT", "Height (m)", "(c, d)") / pS2("VOL", expression(Assumed~volume~(m^3~ha^{-1})), "(e, f)")) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
ggsave("ms_v141/FigS2_rd_height_volume.png", f2, width = 160, height = 190, units = "mm", dpi = 600)
pS3 <- function(v, ylab, tag) { d <- dcast(S[level == "md" & var == v], origin + year ~ site_dev, value.var = c("point", "p05", "p50", "p95"))
  ggplot(d, aes(year)) + geom_ribbon(aes(ymin = p05_TRUE, ymax = p95_TRUE), fill = "#9ECAE1", alpha = 0.45) + geom_ribbon(aes(ymin = p05_FALSE, ymax = p95_FALSE), fill = "#2166AC", alpha = 0.35) +
  geom_line(aes(y = point_FALSE), colour = "#08306B", linewidth = 0.5) + geom_line(aes(y = p50_FALSE), colour = "#08306B", linetype = "dashed", linewidth = 0.4) +
  geom_vline(data = data.table(origin = factor(c("Natural", "Planted"), c("Natural", "Planted")), x = c(33, 10)), aes(xintercept = x), linetype = "dashed", colour = "grey40") + facet_wrap(~origin, nrow = 1) + labs(x = "Years from start", y = ylab, tag = tag) + th }
f3 <- pS3("BA", expression(Basal~area~(m^2~ha^{-1})), "(a, b)") / pS3("QMD", "QMD (cm)", "(c, d)") / pS3("TPH", expression(Stems~(ha^{-1})), "(e, f)")
ggsave("ms_v141/FigS3_band_types.png", f3, width = 160, height = 190, units = "mm", dpi = 600)
T <- fread("ms_v141/fig5_trajectories.csv"); T[, level := factor(level, c("5th", "10th", "50th", "90th", "95th"))]; T[, origin := factor(origin, c("Natural", "Planted"))]
pal <- c("5th" = "#B2182B", "10th" = "#EF8A62", "50th" = "#4D9221", "90th" = "#2166AC", "95th" = "#542788")
cell <- function(x, y, xl, yl, logxy = FALSE) { g <- ggplot(T, aes(.data[[x]], .data[[y]], colour = level, linetype = origin)) + geom_path(linewidth = 0.4) + scale_colour_manual(values = pal, name = "BYI percentile") +
  scale_linetype_manual(values = c(Natural = "solid", Planted = "22"), name = "Origin") + labs(x = xl, y = yl) + th; if (logxy) g <- g + scale_x_log10() + scale_y_log10(); g }
e <- plot_spacer()
f5 <- (cell("year", "HT", "Years", "Height (m)") | cell("QMD", "HT", "QMD (cm)", "Height (m)") | e | e) / (cell("year", "TPH", "Years", expression(Stems~(ha^{-1}))) | cell("QMD", "TPH", "QMD (cm)", expression(Stems~(ha^{-1})), TRUE) | cell("HT", "TPH", "Height (m)", expression(Stems~(ha^{-1}))) | e) /
  (cell("year", "BA", "Years", expression(Basal~area~(m^2~ha^{-1}))) | cell("QMD", "BA", "QMD (cm)", expression(Basal~area~(m^2~ha^{-1}))) | cell("HT", "BA", "Height (m)", expression(Basal~area~(m^2~ha^{-1}))) | cell("TPH", "BA", expression(Stems~(ha^{-1})), expression(Basal~area~(m^2~ha^{-1})))) /
  (cell("year", "VOL", "Years", expression(Volume~(m^3~ha^{-1}))) | cell("QMD", "VOL", "QMD (cm)", expression(Volume~(m^3~ha^{-1}))) | cell("HT", "VOL", "Height (m)", expression(Volume~(m^3~ha^{-1}))) | cell("TPH", "VOL", expression(Stems~(ha^{-1})), expression(Volume~(m^3~ha^{-1})))) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
ggsave("ms_v141/FigS5_bakuzis_matrix.png", f5, width = 180, height = 190, units = "mm", dpi = 600)
cat("coverage rows", nrow(C), "; 71 done\n")
