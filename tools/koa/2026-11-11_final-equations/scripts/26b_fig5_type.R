# 26b_fig5_type.R  As 26 with the figure drawn at its placed width (113 mm) so type is 9 to 10.5 pt on the page.
# 26_fig5_shade.R  Redraws Fig. 5 from the scenario file of 23t with the shading starting where the thinning-free record ends: year 33 for natural stands,
# year 10 for planted stands (all but one planted benchmark plot ends by year 10 once horizons stop before the first removal year).
suppressMessages({library(data.table); library(ggplot2)}); setwd("~/jobs/koa_final_eq_20261110"); MC <- fread("ms_rdbyi2/scenarios_long_rdbyi2.csv")
OR <- c(Natural = "#0072B2", Planted = "#D55E00"); LV <- c(Low = "#56B4E9", Median = "#009E73", High = "#CC79A7"); orig <- function(p) factor(ifelse(p == 1, "Planted", "Natural"), levels = names(OR))
theme_koa <- function() theme_classic(base_size = 10.5) + theme(axis.text = element_text(colour = "black", size = 9), legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(4.5, "mm"), strip.background = element_blank(), strip.text = element_text(face = "bold"), plot.margin = margin(3, 5, 3, 3))
sc <- MC[site_dev == FALSE & var %in% c("BA", "QMD", "TPH")]; sc[, `:=`(origin = orig(planted), lev = factor(c(lo = "Low", md = "Median", hi = "High")[level], levels = names(LV)))]; vl <- c(BA = "Basal area (m² ha⁻¹)", QMD = "QMD (cm)", TPH = "Stems (ha⁻¹)"); sc[, vlab := factor(vl[var], levels = vl)]
shade <- data.table(origin = orig(c(0, 1)), xmin = c(33, 10), xmax = 100)
fig5 <- ggplot(sc, aes(year, point, colour = lev, fill = lev)) + geom_rect(data = shade, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "#F0E442", alpha = 0.18) + geom_ribbon(aes(ymin = p05, ymax = p95), alpha = 0.15, colour = NA) + geom_line(linewidth = 0.6) +
  facet_grid(vlab ~ origin, scales = "free_y", switch = "y") + scale_colour_manual(values = LV) + scale_fill_manual(values = LV) + labs(x = "Years from starting measurement", y = NULL) + theme_koa() + theme(strip.placement = "outside")
ggsave("ms_rdbyi2/Fig5_projections_113mm.png", fig5, width = 113, height = 150, units = "mm", dpi = 400, type = "cairo"); cat("Fig5 redrawn, planted shading from year 10\n")
