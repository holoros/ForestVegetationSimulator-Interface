## figS8.R (koa_figfix_20260929). Supplemental Figure S8, modified Bakuzis matrix, redrawn from the deployed engine's
## Bakuzis input (engine_v102/out_m1/koa_bakuzis_input_M1.csv; ages 25, 50, 100, 150, 200) with a legend and plain
## logarithmic ticks. Relations and data unchanged from the 18 September matplotlib version.
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
B <- fread(path.expand("~/jobs/koa_v102_20260918/track2/engine_v102/out_m1/koa_bakuzis_input_M1.csv"))
B[, site := factor(site, c(100, 264, 450))]; B[, origin := factor(origin, c("natural", "planted"), c("Natural", "Planted"))]
setorder(B, origin, site, age)
L <- list(age = "Age (yr)", HT = "Stand height (m)", QMD = "QMD (cm)", TPH = expression(paste("Stems (", ha^-1, ")")),
          BAPH = expression(paste("Basal area (", m^2, " ", ha^-1, ")")), VOL = expression(paste("Volume (", m^3, " ", ha^-1, ")")))
P <- list(c("age","HT"), c("QMD","HT"), c("age","TPH"), c("QMD","TPH"), c("HT","TPH"), c("TPH","BAPH"), c("HT","VOL"), c("TPH","VOL"))
COL <- c("100" = "#0F6E64", "264" = "#C08A1E", "450" = "#9E2B25")
th <- theme_bw(base_size = 8) + theme(panel.grid.minor = element_blank(), plot.tag = element_text(face = "bold", size = 9), legend.position = "bottom")
ps <- lapply(seq_along(P), function(k) { x <- P[[k]][1]; y <- P[[k]][2]
  g <- ggplot(B, aes(.data[[x]], .data[[y]], colour = site, linetype = origin, group = interaction(site, origin))) +
    geom_path(linewidth = 0.55) + geom_point(size = 1) +
    scale_colour_manual(values = COL, name = "BYI (index units)") + scale_linetype_manual(values = c(Natural = "solid", Planted = "22"), name = "Origin") +
    labs(x = L[[x]], y = L[[y]], tag = paste0("(", letters[k], ")")) + th
  if (k == 4) g <- g + scale_x_log10(breaks = c(15, 20, 30, 40, 60, 80)) + scale_y_log10(breaks = c(50, 100, 200, 400, 800))
  g })
fig <- wrap_plots(ps, ncol = 3, guides = "collect") & theme(legend.position = "bottom")
ggsave("FigS8_bakuzis.png", fig, width = 174, height = 165, units = "mm", dpi = 300, bg = "white")
ggsave("FigS8_bakuzis.tiff", fig, width = 174, height = 165, units = "mm", dpi = 600, bg = "white", compression = "lzw")
print(dcast(B[age %in% c(100, 200)], origin + age ~ site, value.var = "VOL"))
cat("done\n")
