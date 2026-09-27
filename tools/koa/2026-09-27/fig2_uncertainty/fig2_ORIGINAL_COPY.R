## Figure 2, koa BYI site index surface. Journal register, advanced-viz house rules.
## Regenerated 2026-09-26 at 600 dpi to match Figures 1 and 3 to 6; the prior render was
## 2055 x 1122 at 326 dpi, the only figure in the set below 600 dpi, and its footnote wrote
## "Mg ha-1" with a plain hyphen while its own colourbar wrote the superscript correctly.
## Source raster: BYI_all.tif (EPSG:4326, 30 m cells), the deposited surface in stage_v190.
## Panel extents are Figure 1's exactly, so the two maps register.
suppressMessages({library(data.table); library(ggplot2); library(patchwork); library(scales)})

rd <- function(f) {
  d <- fread(f, col.names = c("x", "y", "v"), showProgress = FALSE)
  d[v > -9998]
}
arch <- rd("byi_arch.xyz"); isl <- rd("byi_isl.xyz")
cat("arch cells", nrow(arch), " isl cells", nrow(isl), "\n")

## One colour scale across both panels, anchored on the union of the two.
LIM <- range(c(arch$v, isl$v))
cat("shared scale limits:", LIM, "\n")
BRK <- seq(0, 1250, by = 250)

sbar <- function(x0, y0, km, lab, sz = 3.1) list(
  annotate("segment", x = x0, xend = x0 + km/111.32, y = y0, yend = y0, linewidth = 0.9),
  annotate("text", x = x0 + km/222.64, y = y0 + 0.075, label = lab, size = sz, fontface = "bold"))
narr <- function(x0, y0, h = 0.22, sz = 3.1) list(
  annotate("segment", x = x0, xend = x0, y = y0, yend = y0 + h,
           arrow = arrow(length = unit(1.9, "mm"), type = "closed"), linewidth = 0.6),
  annotate("text", x = x0, y = y0 - 0.075, label = "N", size = sz, fontface = "bold"))

panel <- function(d, ttl, sb, na_, xl, yl) {
  ggplot() +
    geom_raster(data = d, aes(x, y, fill = v)) +
    scale_fill_viridis_c(name = expression(bold("BYI (Mg ha"^-1*")")),
                         limits = LIM, breaks = BRK, oob = squish,
                         guide = guide_colourbar(title.position = "left",
                                                 barwidth = unit(58, "mm"),
                                                 barheight = unit(3.4, "mm"),
                                                 ticks.colour = "white")) +
    sb + na_ +
    coord_sf(xlim = xl, ylim = yl, expand = FALSE, crs = 4326) +
    labs(title = ttl) +
    theme_void(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.04,
                                    margin = margin(b = 3)),
          legend.title = element_text(face = "bold", size = 10, vjust = 0.9),
          legend.text  = element_text(size = 9))
}

XA <- c(-160.30, -154.72); YA <- c(18.82, 22.33)
XI <- c(-156.12, -154.72); YI <- c(18.87, 20.33)

a <- panel(arch, "(a) Hawaiian archipelago",
           sbar(-159.95, 19.35, 100, "100 km"), narr(-155.25, 21.75), XA, YA)
b <- panel(isl,  "(b) Hawaii Island detail",
           sbar(-156.10, 18.93, 30, "30 km"),  narr(-154.92, 20.02), XI, YI) +
     guides(fill = "none")

fig <- (a | b) + plot_layout(guides = "collect") +
  plot_annotation(caption = expression(
    "Sequential ramp. Site classes used in Figs. 3 to 6 and S6 to S8: Low 100, Medium 264, High 450 Mg ha"^-1*".")) &
  theme(legend.position = "bottom",
        legend.margin = margin(t = 0, b = 0),
        plot.caption = element_text(hjust = 0, size = 9, colour = "grey25",
                                    lineheight = 1.15, margin = margin(t = 4)),
        plot.caption.position = "plot",
        plot.background = element_rect(fill = "white", colour = NA))

W <- 17.4; H <- 9.6
ggsave("Fig2_byi_surface_v102.tiff", fig, width = W, height = H, units = "cm",
       dpi = 600, bg = "white", device = "tiff", compression = "lzw")
ggsave("Fig2_byi_surface_v102.pdf",  fig, width = W, height = H, units = "cm", bg = "white")
ggsave("Fig2_thumb.png",             fig, width = W, height = H, units = "cm", dpi = 72, bg = "white")
cat("wrote Fig2_byi_surface_v102.tiff/.pdf and Fig2_thumb.png\n")
