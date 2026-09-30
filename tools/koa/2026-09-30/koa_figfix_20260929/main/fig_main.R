## fig_v102.R (track 4, 2026-09-18): manuscript main figures for koa v102, rebuilt from engine_v102 constants and outputs.
## Fig. 3 component equations (v99 fig3_fig5_v99.R layout), Fig. 4 stand projections with Monte Carlo bands (v99 "Fig. 5" block),
## Fig. 5 long term trajectories against the 15 remeasured plots and Fig. 6 general behavior (v98 fig6_fig7_v98.R layout).
## Every constant is read from the engine_v102 source files at run time (koa_equations.py, koa_params.py, run_candidates.py) or from
## the track 2 and track 3 v102 fits; nothing is typed in from the record engine. Coordinates are never read.
suppressPackageStartupMessages({ library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(readr) })
J <- path.expand("~/jobs/koa_v102_20260918"); E <- file.path(J, "track2/engine_v102"); T3 <- file.path(J, "track3"); T4 <- file.path(J, "track4")
OUT <- path.expand("~/jobs/koa_figfix_20260929/main/figs"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
LT_DIR <- file.path(T3, "lt/out")   # v102 long-term outputs live under track3
set.seed(20260916)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
## ---------------------------------------------------------------- constants read from engine_v102
strip_comments <- function(x) sub("#.*$", "", x)
eq_txt <- strip_comments(readLines(file.path(E, "koa_equations.py")))
par_txt <- strip_comments(readLines(file.path(E, "koa_params.py")))
rc_txt <- strip_comments(readLines(file.path(E, "run_candidates.py")))
py_dict <- function(txt, start_pat, after_line = 1) {
  i <- grep(start_pat, txt); i <- i[i >= after_line][1]; stopifnot(length(i) == 1, is.finite(i))
  s <- txt[i]; k <- i
  while (!grepl("\\)", s)) { k <- k + 1; s <- paste(s, txt[k]) }
  m <- regmatches(s, gregexpr("([A-Za-z][A-Za-z0-9_]*)=(-?[0-9.]+(e-?[0-9]+)?)", s))[[1]]
  v <- as.numeric(sub("^[^=]*=", "", m)); names(v) <- sub("=.*$", "", m); v
}
py_scalar <- function(txt, name) { s <- txt[grep(sprintf("^%s\\s*=", name), txt)[1]]; as.numeric(sub(sprintf("^%s\\s*=\\s*", name), "", s)) }
py_tuple <- function(txt, name) { s <- txt[grep(sprintf("^%s\\s*=", name), txt)[1]]; as.numeric(strsplit(gsub("[()]|\\s", "", sub(sprintf("^%s\\s*=", name), "", s)), ",")[[1]]) }
lineA <- grep("^class LineageA", eq_txt)
S8 <- list(ddbh = py_dict(eq_txt, "^\\s+DDBH = dict\\(", lineA), dht = py_dict(eq_txt, "^\\s+DHT = dict\\(", lineA))
stopifnot(length(S8$ddbh) == 10, length(S8$dht) == 10, all(names(S8$ddbh) == paste0("b", 0:9)))
HT_P <- py_dict(eq_txt, "^HT_P = dict\\(")
CF <- c(ddbh = py_scalar(par_txt, "CF_DDBH_MARGINAL"), dht = py_scalar(par_txt, "CF_DHT"))
CAL <- list(ddbh = py_tuple(par_txt, "CAL_DDBH"), dht = py_tuple(par_txt, "CAL_DHT"))
MORT_CAL <- py_tuple(par_txt, "MORT_CAL")
GUARD <- c(ddbh = py_scalar(par_txt, "DDBH_PLANTED_GUARD_CM"), dht = py_scalar(par_txt, "DDBH_HT_TRUNCATION_M"))
CLIP <- c(ddbh = py_scalar(par_txt, "DDBH_ANNUAL_CAP"), dht = py_scalar(par_txt, "DHT_ANNUAL_CAP"))
CAPS <- c(natural = py_scalar(par_txt, "HARNESS_DBH_MAX_NATURAL_CM"), planted = py_scalar(par_txt, "HARNESS_DBH_MAX_PLANTED_CM"))
OBS <- py_dict(rc_txt, "^OBS = dict\\(")
stopifnot(all(is.finite(c(unlist(S8), HT_P, CF, unlist(CAL), MORT_CAL, GUARD, CLIP, CAPS, OBS[c("QMD", "BAPH")]))))
H <- readRDS(file.path(T3, "s02/v102/02_height_fit.rds"))   # track 3 refit on the v102 height frame, identical to HT_P at printed precision
stopifnot(max(abs(H$coef[names(HT_P)] - HT_P)) < 1e-6)
consts <- bind_rows(tibble(group = "DDBH", name = names(S8$ddbh), value = S8$ddbh, source = "koa_equations.py LineageA.DDBH"),
                    tibble(group = "DHT", name = names(S8$dht), value = S8$dht, source = "koa_equations.py LineageA.DHT"),
                    tibble(group = "HT_P", name = names(HT_P), value = HT_P, source = "koa_equations.py HT_P (curves use track3/s02/v102/02_height_fit.rds coef and vcov)"),
                    tibble(group = "CF", name = c("CF_DDBH_MARGINAL", "CF_DHT"), value = CF, source = "koa_params.py"),
                    tibble(group = "CAL", name = c("CAL_DDBH_natural", "CAL_DDBH_planted", "CAL_DHT_natural", "CAL_DHT_planted"), value = c(CAL$ddbh, CAL$dht), source = "koa_params.py"),
                    tibble(group = "MORT_CAL", name = c("MORT_CAL_natural", "MORT_CAL_planted"), value = MORT_CAL, source = "koa_params.py (used by the Fig. 5 and Fig. 6 engine runs)"),
                    tibble(group = "GUARD_CLIP", name = c("DDBH_PLANTED_GUARD_CM", "DDBH_HT_TRUNCATION_M", "DDBH_ANNUAL_CAP", "DHT_ANNUAL_CAP"), value = c(GUARD, CLIP), source = "koa_params.py"),
                    tibble(group = "CAPS", name = c("HARNESS_DBH_MAX_NATURAL_CM", "HARNESS_DBH_MAX_PLANTED_CM"), value = CAPS, source = "koa_params.py (Fig. 4 dotted ceilings)"),
                    tibble(group = "OBS", name = c("OBS_QMD", "OBS_BAPH"), value = OBS[c("QMD", "BAPH")], source = "run_candidates.py OBS (Fig. 4 dashed observed maxima)"))
write_csv(consts, file.path(OUT, "Fig_constants_read_v102.csv"))
print(as.data.frame(consts), digits = 8)

theme_koa <- function(base = 8) {
  theme_classic(base_size = base, base_family = "Liberation Sans") +
    theme(panel.background = element_rect(fill = "white", colour = NA),
          plot.background = element_rect(fill = "white", colour = NA),
          axis.line = element_line(linewidth = 0.35), axis.ticks = element_line(linewidth = 0.3),
          axis.title = element_text(size = base), axis.text = element_text(size = base - 1, colour = "black"),
          legend.key.height = unit(3, "mm"), legend.key.width = unit(5, "mm"),
          legend.text = element_text(size = base - 1.5), legend.title = element_text(size = base - 1),
          legend.background = element_blank(),
          plot.tag = element_text(face = "bold", size = base + 1),
          strip.background = element_blank(), strip.text = element_text(face = "bold", size = base))
}
SITE_COL <- c("100" = "#0F6E64", "264" = "#C08A1E", "450" = "#9E2B25")
LVL_COL <- c("#0F6E64", "#C08A1E", "#9E2B25")
save3 <- function(p, stem, w, h) {
  ggsave(file.path(OUT, paste0(stem, ".pdf")), p, width = w, height = h, units = "mm", device = cairo_pdf, bg = "white")
  ggsave(file.path(OUT, paste0(stem, ".tiff")), p, width = w, height = h, units = "mm", dpi = 600, compression = "lzw", bg = "white")
  ggsave(file.path(OUT, paste0(stem, ".png")), p, width = w, height = h, units = "mm", dpi = 150, bg = "white")
  logm("saved", stem)
}

## ---------------------------------------------------------------- Fig. 3, component equations
inc <- function(resp, size, bal, cr, baph, planted, byi) {
  b <- S8[[resp]]
  y <- exp(b[["b0"]] + b[["b1"]] * log(size + 1) + b[["b2"]] * size + b[["b3"]] * bal^2 / log(size + 5) + b[["b4"]] * log(bal + 1) +
        b[["b5"]] * log(cr) + b[["b6"]] * sqrt(baph * size) + b[["b7"]] * planted * pmin(size, GUARD[[resp]]) + b[["b8"]] * log(byi) +
        b[["b9"]] * planted) * CF[[resp]] * ifelse(planted > 0, CAL[[resp]][2], CAL[[resp]][1])
  pmin(y, CLIP[[resp]])
}
fixed <- list(cr = 0.7, baph = 30, planted = 0, byi = 264, bal = 15)
ORIG <- c("Natural", "Planted")
pa <- expand_grid(dbh = seq(2, 80, 0.5), bal = c(5, 15, 30), pl = 0:1) |>
  mutate(y = inc("ddbh", dbh, bal, fixed$cr, fixed$baph, pl, fixed$byi), g = factor(bal), o = factor(ORIG[pl + 1], ORIG))
pb <- expand_grid(ht = seq(1.5, 25, 0.25), bal = c(5, 15, 30), pl = 0:1) |>
  mutate(y = inc("dht", ht, bal, fixed$cr, fixed$baph, pl, fixed$byi), g = factor(bal), o = factor(ORIG[pl + 1], ORIG))
pd_ <- expand_grid(byi = seq(50, 700, 5), dbh = c(10, 25, 40), pl = 0:1) |>
  mutate(y = inc("ddbh", dbh, fixed$bal, fixed$cr, fixed$baph, pl, byi), g = factor(dbh), o = factor(ORIG[pl + 1], ORIG))
pe <- expand_grid(byi = seq(50, 700, 5), ht = c(5, 12, 20), pl = 0:1) |>
  mutate(y = inc("dht", ht, fixed$bal, fixed$cr, fixed$baph, pl, byi), g = factor(ht), o = factor(ORIG[pl + 1], ORIG))
write_csv(bind_rows(mutate(pa, panel = "a"), mutate(pb, panel = "b"), mutate(pd_, panel = "d"), mutate(pe, panel = "e")), file.path(OUT, "Fig3_increment_curves_DATA_v102.csv"))
LT <- scale_linetype_manual(values = c(Natural = "solid", Planted = "22"), name = "Origin")
ht_eq2 <- function(p, dbh, byi, baph, rd) (p[["a0"]] + p[["a1"]] * byi / 100) * (1 - exp(-p[["b"]] * dbh))^p[["c"]] *
  exp(p[["g1"]] * log(baph + 1) + p[["g2"]] * rd)
L <- chol(H$vcov); Z <- matrix(rnorm(4000 * 6), 4000); B <- sweep(Z %*% L, 2, H$coef, "+"); colnames(B) <- names(H$coef)
xs <- seq(2, 80, 1)
pc <- bind_rows(lapply(c(100, 264, 450), function(s) {
  P <- apply(B, 1, function(p) ht_eq2(p, xs, s, 30, 0.8))
  tibble(dbh = xs, y = ht_eq2(H$coef, xs, s, 30, 0.8), lo = apply(P, 1, quantile, 0.025), hi = apply(P, 1, quantile, 0.975), g = factor(s))
}))
write_csv(pc, file.path(OUT, "Fig3_height_curves_DATA_v102.csv"))
tj <- read_csv(file.path(J, "track2/height/tree_join_v102.csv"), show_col_types = FALSE,
               col_select = c(source, inst, plot, year, dbh, ht, expf, status, baph, byi)) |>
  filter(tolower(status) == "live", dbh > 0, expf > 0) |>
  group_by(source, inst, plot, year) |> mutate(rd = dbh / max(dbh)) |> ungroup() |>
  filter(ht > 0, is.finite(byi), is.finite(baph)) |>
  mutate(pred = ht_eq2(H$coef, dbh, byi, baph, rd))
logm("height frame rows", nrow(tj))
stopifnot(nrow(tj) == 9059)   # v102 static height frame; registry ht_stats n = 9059, and line 111 cross-checks it against 02_height_equivalence.csv
eq <- read_csv(file.path(T3, "s02/v102/02_height_equivalence.csv"), show_col_types = FALSE) |> filter(vector == "refit, population-average")
stopifnot(nrow(eq) == 1, eq$n == nrow(tj), eq$nboot == 5000)
lim <- c(0, 36)
lab_bal <- expression(paste("BAL (", m^2, " ", ha^-1, ")"))
f3a <- ggplot(pa, aes(dbh, y, colour = g, linetype = o)) + geom_line(linewidth = 0.6) + LT +
  scale_colour_manual(values = LVL_COL, name = lab_bal) +
  labs(x = "DBH (cm)", y = expression(paste(Delta, "DBH (cm ", yr^-1, ")")), tag = "(a)") +
  guides(linetype = "none", colour = guide_legend(direction = "horizontal", title.position = "top", override.aes = list(linetype = "solid"))) + scale_y_continuous(limits = c(0, 1.45 * max(pa$y)), expand = c(0, 0)) + theme_koa() +
  theme(legend.position = c(0.52, 0.86), legend.key.width = unit(3, "mm"))
f3b <- ggplot(pb, aes(ht, y, colour = g, linetype = o)) + geom_line(linewidth = 0.6) + LT +
  scale_colour_manual(values = LVL_COL, name = lab_bal) +
  labs(x = "Height (m)", y = expression(paste(Delta, "HT (m ", yr^-1, ")")), tag = "(b)") +
  guides(linetype = "none", colour = guide_legend(direction = "horizontal", title.position = "top", override.aes = list(linetype = "solid"))) + scale_y_continuous(limits = c(0, 1.45 * max(pb$y)), expand = c(0, 0)) + theme_koa() +
  theme(legend.position = c(0.52, 0.88), legend.key.width = unit(3, "mm"))
f3c <- ggplot(pc, aes(dbh, y, colour = g, fill = g)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.22, colour = NA) +
  geom_line(linewidth = 0.7) + scale_colour_manual(values = LVL_COL, name = "BYI (index units)") +
  scale_fill_manual(values = LVL_COL, name = "BYI (index units)") +
  labs(x = "DBH (cm)", y = "Height (m)", tag = "(c)") + coord_cartesian(ylim = c(0, NA)) +
  theme_koa() + theme(legend.position = c(0.72, 0.25))
f3d <- ggplot(pd_, aes(byi, y, colour = g, linetype = o)) + geom_line(linewidth = 0.6) + LT +
  scale_colour_manual(values = LVL_COL, name = "DBH (cm)") +
  labs(x = "BYI (index units)", y = expression(paste(Delta, "DBH (cm ", yr^-1, ")")), tag = "(d)") +
  scale_y_continuous(limits = c(0, 1.9 * max(pd_$y)), expand = c(0, 0)) + theme_koa() +
  guides(colour = guide_legend(order = 1, direction = "horizontal", title.position = "top", override.aes = list(linetype = "solid")), linetype = guide_legend(order = 2, direction = "horizontal", title.position = "top")) +
  theme(legend.position = c(0.48, 0.8), legend.box = "vertical", legend.key.width = unit(3, "mm"), legend.spacing.y = unit(0.5, "mm"))
f3e <- ggplot(pe, aes(byi, y, colour = g, linetype = o)) + geom_line(linewidth = 0.6) + LT +
  scale_colour_manual(values = LVL_COL, name = "Height (m)") +
  labs(x = "BYI (index units)", y = expression(paste(Delta, "HT (m ", yr^-1, ")")), tag = "(e)") +
  scale_y_continuous(limits = c(0, 1.45 * max(pe$y)), expand = c(0, 0)) + theme_koa() + guides(linetype = "none", colour = guide_legend(direction = "horizontal", title.position = "top", override.aes = list(linetype = "solid"))) +
  theme(legend.position = c(0.48, 0.88), legend.key.width = unit(3, "mm"))
f3f <- ggplot(tj, aes(pred, ht)) +
  geom_polygon(data = tibble(x = c(0, 36, 36), y = c(0, 27, 45)), aes(x, y), fill = "grey80", alpha = 0.5, inherit.aes = FALSE) +
  geom_point(size = 0.25, alpha = 0.18, colour = "grey25", stroke = 0) +
  geom_abline(slope = 1, intercept = 0, linewidth = 0.45) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#9E2B25", linewidth = 0.6) +
  coord_equal(xlim = lim, ylim = lim, expand = FALSE) +
  labs(x = "Predicted height (m)", y = "Observed height (m)", tag = "(f)") + theme_koa()
fig3 <- (f3a | f3b | f3c) / (f3d | f3e | f3f)
save3(fig3, "Fig3_components", 174, 118)
write_csv(eq, file.path(OUT, "Fig3_panel_f_equivalence_v102.csv"))

## ---------------------------------------------------------------- Fig. 4, stand projections with Monte Carlo bands
tr <- read_csv(file.path(T3, "derived/engine_v102_out_m1/trajectories.csv"), show_col_types = FALSE) |>
  mutate(byi = c(Low = "100", Medium = "264", High = "450")[site], MAI = VOL / age)
cat("reps per scenario (rep 0 is the point run):", paste(tr |> filter(rep != 0) |> distinct(scenario, rep) |> count(scenario) |> mutate(s = paste(scenario, n)) |> pull(s), collapse = ", "), "\n")
long <- tr |> select(scenario, byi, age, rep, QMD, BAPH, TPH, VOL, MAI) |>
  pivot_longer(c(QMD, BAPH, TPH, VOL, MAI), names_to = "var", values_to = "val")
bands <- long |> filter(rep != 0) |> group_by(scenario, byi, age, var) |>
  summarise(lo = quantile(val, 0.025, na.rm = TRUE), hi = quantile(val, 0.975, na.rm = TRUE), .groups = "drop")
pts <- long |> filter(rep == 0, !(var == "MAI" & age < 5))
bands <- bands |> filter(!(var == "MAI" & age < 5))
write_csv(bands, file.path(OUT, "Fig4_bands_DATA_v102.csv")); write_csv(pts, file.path(OUT, "Fig4_point_DATA_v102.csv"))
vars <- list(QMD = "QMD (cm)", BAPH = expression(paste("Basal area (", m^2, " ", ha^-1, ")")), TPH = expression(paste("Stems (", ha^-1, ")")),
          VOL = expression(paste("Volume (", m^3, " ", ha^-1, ")")), MAI = expression(paste("Net MAI (", m^3, " ", ha^-1, " ", yr^-1, ")")))
scen <- c("Even-aged natural", "Even-aged planted", "Uneven-aged natural")
stopifnot(all(scen %in% tr$scenario))
ceil <- tibble(scenario = scen, var = "QMD", y = c(CAPS[["natural"]], CAPS[["planted"]], CAPS[["natural"]]))
obsmax <- tibble(var = c("QMD", "BAPH"), y = c(OBS[["QMD"]], OBS[["BAPH"]]))
panels <- list(); k <- 0
for (v in names(vars)) for (s in scen) {
  k <- k + 1
  pb_ <- bands |> filter(var == v, scenario == s); pp <- pts |> filter(var == v, scenario == s)
  yr <- range(c(bands$lo[bands$var == v], bands$hi[bands$var == v], pts$val[pts$var == v]), na.rm = TRUE)
  if (v == "MAI") yr <- c(0, min(yr[2], 35))
  if (v == "BAPH") yr[2] <- max(yr[2], 1.04 * OBS[["BAPH"]])
  g <- ggplot() + annotate("rect", xmin = 52, xmax = 100, ymin = -Inf, ymax = Inf, fill = "grey90") +
    geom_ribbon(data = pb_, aes(age, ymin = lo, ymax = hi, fill = byi), alpha = 0.16) +
    geom_line(data = pp, aes(age, val, colour = byi), linewidth = 0.65) +
    scale_colour_manual(values = SITE_COL, name = "BYI (index units)") +
    scale_fill_manual(values = SITE_COL, name = "BYI (index units)") +
    scale_x_continuous(breaks = seq(0, 100, 25), expand = c(0.01, 0)) +
    coord_cartesian(ylim = c(0, yr[2])) +
    labs(x = if (v == "MAI") "Stand age (yr)" else NULL, y = if (s == scen[1]) vars[[v]] else NULL,
         title = if (v == "QMD") s else NULL) + theme_koa(7.5) +
    theme(plot.title = element_text(size = 8, face = "bold", hjust = 0.5))
  if (v == "QMD") g <- g + geom_hline(data = ceil |> filter(scenario == s), aes(yintercept = y), linetype = "dotted", linewidth = 0.45)
  if (v %in% obsmax$var && !(v == "QMD" && s == scen[2])) g <- g + geom_hline(yintercept = obsmax$y[obsmax$var == v], linetype = "dashed", linewidth = 0.3, colour = "grey40")
  panels[[k]] <- g
}
fig4 <- wrap_plots(panels, ncol = 3, guides = "collect") & theme(legend.position = "bottom")
save3(fig4, "Fig4_projections", 174, 210)

## ---------------------------------------------------------------- Fig. 5, long term trajectory validation (15 remeasured plots)
theme_koa6 <- function(base = 8) theme_koa(base) + theme(legend.key.width = unit(6, "mm"))
pn <- read_csv(file.path(LT_DIR, "LT_v102_points.csv"), show_col_types = FALSE) |> mutate(engine = "With natural level factor")
po <- read_csv(file.path(LT_DIR, "LT_u101_points.csv"), show_col_types = FALSE) |> mutate(engine = "Without natural level factor")
tn <- read_csv(file.path(LT_DIR, "LT_v102_traj.csv"), show_col_types = FALSE)
cat("LT plots", n_distinct(pn$pid), "points", nrow(pn), "\n"); stopifnot(n_distinct(pn$pid) == 15)
ptsL <- bind_rows(pn, po) |> mutate(origin = ifelse(planted == 1, "Planted", "Natural"),
                                    engine = factor(engine, c("With natural level factor", "Without natural level factor")))
longp <- pn |> group_by(pid) |> summarise(span = max(h), n = n(), .groups = "drop") |> filter(span >= 20) |> pull(pid)
lab <- function(p) { x <- sub("^DOFAW\\|", "", p); x <- sub("\\|", " ", x); ifelse(x == "Kulani 12", "Kulani 12 (planted)", paste0(x, " (natural)")) }
lp <- pn |> filter(pid %in% longp) |> mutate(plot = lab(pid), obs_s = obs_surv)
ltr <- tn |> filter(pid %in% longp) |> left_join(pn |> distinct(pid, tph0), by = "pid") |> mutate(plot = lab(pid), surv = TPH / tph0)
cat("long plots:", paste(sort(unique(lp$plot)), collapse = "; "), "\n")
pal <- c("#555555", "#C08A1E", "#E07B39", "#3B5BA5", "#6B4C9A")
mk_top <- function(y_tr, y_ob, ylab, tag) {
  ggplot() + geom_line(data = ltr, aes(h, .data[[y_tr]], colour = plot), linewidth = 0.6) +
    geom_point(data = lp, aes(h, .data[[y_ob]], colour = plot), size = 1.4) +
    scale_colour_manual(values = pal, name = "DOFAW plot") + guides(colour = guide_legend(nrow = 2)) + labs(x = "Years since first measurement", y = ylab, tag = tag) + theme_koa6()
}
a <- mk_top("surv", "obs_s", "Cohort survival (fraction)", "(a)")
b <- mk_top("QMD", "obsQMD", "Cohort QMD (cm)", "(b)")
c <- mk_top("BAPH", "obsBAPH", expression(paste("Cohort basal area (", m^2, " ", ha^-1, ")")), "(c)")
res <- ptsL |> transmute(pid, origin, engine, h, `Survival (fraction)` = obs_surv - pr_surv, `QMD (cm)` = obsQMD - prQMD,
                         `Basal area (m2 ha-1)` = obsBAPH - prBAPH) |>
  pivot_longer(c(`Survival (fraction)`, `QMD (cm)`, `Basal area (m2 ha-1)`), names_to = "var", values_to = "err")
mk_bot <- function(v, ylab, tag) {
  dd <- res |> filter(var == v)
  ggplot(dd, aes(h, err, colour = origin, shape = engine)) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey40") +
    geom_point(size = 1.2, alpha = 0.8) + scale_shape_manual(values = c(16, 1), name = NULL) +
    scale_colour_manual(values = c(Natural = "#0F6E64", Planted = "#9E2B25"), name = NULL) +
    labs(x = "Projection horizon (yr)", y = ylab, tag = tag) + theme_koa6()
}
d_ <- mk_bot("Survival (fraction)", "Survival error", "(d)")
e_ <- mk_bot("QMD (cm)", "QMD error (cm)", "(e)")
f_ <- mk_bot("Basal area (m2 ha-1)", expression(paste("Basal area error (", m^2, " ", ha^-1, ")")), "(f)")
fig5 <- ((a | b | c) + plot_layout(guides = "collect")) / ((d_ | e_ | f_) + plot_layout(guides = "collect")) & theme(legend.position = "bottom")
save3(fig5, "Fig5_longterm", 180, 150)
write_csv(res, file.path(OUT, "Fig5_longterm_residuals_DATA_v102.csv"))

## ---------------------------------------------------------------- Fig. 6, general behavior scenarios
sc <- read_csv(file.path(LT_DIR, "SC_trajectories.csv"), show_col_types = FALSE)
sc <- sc |> mutate(panel = case_when(group == "density" & origin == "natural" ~ "Natural, initial density",
                                     group == "density" & origin == "planted" ~ "Planted, initial density",
                                     TRUE ~ "Thinning from below"),
                   series = ifelse(group == "thinning", paste(ifelse(origin == "planted", "Planted,", "Natural,"),
                                  sub("thinned to 500 at 8 and 250 at 20", "thinned to 500 at 8, 250 at 20", tolower(label))), label))
lev <- c(unique(sc$series[sc$panel == "Natural, initial density"]), unique(sc$series[sc$panel == "Planted, initial density"]), unique(sc$series[sc$panel == "Thinning from below"]))
sc$series <- factor(sc$series, lev)
levels(sc$series) <- sub("^([0-9,]+) stems$", "\\1 stems ha\u207b\u00b9", levels(sc$series)); lev <- levels(sc$series)
cols <- c("#9CC9C1", "#4E9E92", "#0F6E64", "#063B35", "#E7B9B5", "#C9706A", "#9E2B25", "#5A1411",
          "#9E2B25", "#C08A1E", "#6B4C9A", "#0F6E64", "#3B5BA5")
stopifnot(length(lev) == length(cols)); names(cols) <- lev
mkp <- function(var, ylab, panel_name, tag, show_x = FALSE, dashed_total = FALSE) {
  dd <- sc |> filter(panel == panel_name)
  if (var == "mai_total") dd <- dd |> filter(year >= 5)
  g <- ggplot(dd, aes(year, .data[[var]], colour = series)) + geom_line(linewidth = 0.6)
  if (dashed_total) g <- g + geom_line(data = dd |> filter(group == "thinning"), aes(year, total_yield, colour = series), linetype = "22", linewidth = 0.5)
  g + scale_colour_manual(values = cols, name = NULL) + labs(x = if (show_x) "Stand age (yr)" else NULL, y = ylab, tag = tag) +
    theme_koa6() + theme(legend.position = "bottom", legend.key.height = unit(2.5, "mm")) + guides(colour = guide_legend(ncol = 1))
}
panels6 <- c("Natural, initial density", "Planted, initial density", "Thinning from below")
rows <- list(list("QMD", "QMD (cm)"), list("TPH", expression(paste("Stems (", ha^-1, ")"))),
             list("VOL", expression(paste("Volume (", m^3, " ", ha^-1, ")"))), list("mai_total", expression(paste("Total MAI (", m^3, " ", ha^-1, " ", yr^-1, ")"))))
pl <- list(); k <- 0
for (i in seq_along(rows)) for (j in seq_along(panels6)) {
  k <- k + 1
  g <- mkp(rows[[i]][[1]], if (j == 1) rows[[i]][[2]] else NULL, panels6[j], paste0("(", letters[k], ")"), show_x = i == length(rows), dashed_total = (rows[[i]][[1]] == "VOL" && j == 3))
  if (i == 1) g <- g + ggtitle(panels6[j]) + theme(plot.title = element_text(face = "bold", size = 8, hjust = 0.5))
  if (rows[[i]][[1]] == "TPH") g <- g + scale_y_log10(breaks = c(100, 200, 300, 500, 1000, 2000))
  if (i < length(rows)) g <- g + theme(legend.position = "none")
  pl[[k]] <- g
}
fig6 <- wrap_plots(pl, ncol = 3)
save3(fig6, "Fig6_scenarios", 180, 215)
logm("FIGS DONE")
