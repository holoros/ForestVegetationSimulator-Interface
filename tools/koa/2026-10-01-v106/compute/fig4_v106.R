## fig_main_v103.R (koa v103, a2/figs, 2026-09-30). Main Figs 3 to 6 for the v103 engine in the v104 style of
## koa_figfix_20260929/main/fig_main.R (theme_koa, site palette, sizes). Usage: Rscript fig_main_v103.R fig3 fig5 fig6 [fig4]
## Fig 3: constants read at run time from engine_v103 (koa_equations.py, koa_params.py); height curves from track3_s02/v103
##   02_height_fit.rds; increment curve bands from the v103 installation cluster bootstraps (out/inc).
## Fig 4: joint Monte Carlo bands from engine_v103/out_m1 reps (run only after a2/closeout/MC_PROMOTED exists).
## Fig 5: long term trajectories of the 15 remeasured plots, engine_v103 (a2/figs/data/LT_v103_*), v102 engine as comparison.
## Fig 6: density and thinning scenarios, engine_v103 (a2/figs/data/SC_trajectories.csv).
## Bias sign convention: predicted minus observed. BYI in index units. No coordinates are read.
suppressPackageStartupMessages({ library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(readr) })
args <- commandArgs(TRUE); if (!length(args)) args <- c("fig3", "fig5", "fig6")
J <- path.expand("~/jobs/koa_v103_20260930"); E <- file.path(J, "engine_v103"); F <- file.path(J, "a2/figs")
OUT <- file.path(J, "a3/pending/v106/figs"); DAT <- file.path(J, "a3/pending/v106/figs/data"); dir.create(OUT, FALSE, TRUE); dir.create(DAT, FALSE, TRUE)   # v106: outputs redirected, a2/figs untouched
set.seed(20260930)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
theme_koa <- function(base = 8) {
  theme_classic(base_size = base, base_family = "Liberation Sans") +
    theme(panel.background = element_rect(fill = "white", colour = NA), plot.background = element_rect(fill = "white", colour = NA),
          axis.line = element_line(linewidth = 0.35), axis.ticks = element_line(linewidth = 0.3),
          axis.title = element_text(size = base), axis.text = element_text(size = base - 1, colour = "black"),
          legend.key.height = unit(3, "mm"), legend.key.width = unit(5, "mm"),
          legend.text = element_text(size = base - 1.5), legend.title = element_text(size = base - 1), legend.background = element_blank(),
          plot.tag = element_text(face = "bold", size = base + 1), strip.background = element_blank(), strip.text = element_text(face = "bold", size = base))
}
SITE_COL <- c("100" = "#0F6E64", "264" = "#C08A1E", "450" = "#9E2B25"); LVL_COL <- unname(SITE_COL)
save2 <- function(p, stem, w, h) {
  ggsave(file.path(OUT, paste0(stem, ".png")), p, width = w, height = h, units = "mm", dpi = 150, bg = "white")   # v104 main embed resolution
  ggsave(file.path(OUT, paste0(stem, ".tiff")), p, width = w, height = h, units = "mm", dpi = 600, compression = "lzw", bg = "white")
  logm("saved", stem)
}
strip_comments <- function(x) sub("#.*$", "", x)
eq_txt <- strip_comments(readLines(file.path(E, "koa_equations.py"))); par_txt <- strip_comments(readLines(file.path(E, "koa_params.py")))
rc_txt <- strip_comments(readLines(file.path(E, "run_candidates.py")))
py_dict <- function(txt, start_pat, after_line = 1) {
  i <- grep(start_pat, txt); i <- i[i >= after_line][1]; stopifnot(length(i) == 1, is.finite(i))
  s <- txt[i]; k <- i; while (!grepl("\\)", s)) { k <- k + 1; s <- paste(s, txt[k]) }
  m <- regmatches(s, gregexpr("([A-Za-z][A-Za-z0-9_]*)=(-?[0-9.]+(e-?[0-9]+)?)", s))[[1]]
  v <- as.numeric(sub("^[^=]*=", "", m)); names(v) <- sub("=.*$", "", m); v
}
py_scalar <- function(txt, name) { s <- txt[grep(sprintf("^%s\\s*=", name), txt)[1]]; as.numeric(sub(sprintf("^%s\\s*=\\s*", name), "", s)) }
py_tuple <- function(txt, name) { s <- txt[grep(sprintf("^%s\\s*=", name), txt)[1]]; as.numeric(strsplit(gsub("[()]|\\s", "", sub(sprintf("^%s\\s*=", name), "", s)), ",")[[1]]) }
lineA <- grep("^class LineageA", eq_txt)
S8 <- list(ddbh = py_dict(eq_txt, "^\\s+DDBH = dict\\(", lineA), dht = py_dict(eq_txt, "^\\s+DHT = dict\\(", lineA))
stopifnot(length(S8$ddbh) == 10, length(S8$dht) == 10)
HT_P <- py_dict(eq_txt, "^HT_P = dict\\(")
CF <- c(ddbh = py_scalar(par_txt, "CF_DDBH_MARGINAL"), dht = py_scalar(par_txt, "CF_DHT"))
CAL <- list(ddbh = py_tuple(par_txt, "CAL_DDBH"), dht = py_tuple(par_txt, "CAL_DHT"))
GUARD <- c(ddbh = py_scalar(par_txt, "DDBH_PLANTED_GUARD_CM"), dht = py_scalar(par_txt, "DDBH_HT_TRUNCATION_M"))
CLIP <- c(ddbh = py_scalar(par_txt, "DDBH_ANNUAL_CAP"), dht = py_scalar(par_txt, "DHT_ANNUAL_CAP"))
CAPS <- c(natural = py_scalar(par_txt, "HARNESS_DBH_MAX_NATURAL_CM"), planted = py_scalar(par_txt, "HARNESS_DBH_MAX_PLANTED_CM"))
OBS <- py_dict(rc_txt, "^OBS = dict\\(")
OBS[["BAPH"]] <- 46.9816543885033   # v106: rebuilt natural maximum, DOFAW Laupahoehoe 41 2001 (out/repair/plotyear_stand_before_after.csv); was 76.0621 (deposited doubled record, Kulani 23 1994)
stopifnot(all(is.finite(c(unlist(S8), HT_P, CF, unlist(CAL), GUARD, CLIP, CAPS, OBS[c("QMD", "BAPH")]))))
write_csv(tibble(name = c(names(S8$ddbh), names(S8$dht), names(HT_P), "CF_DDBH", "CF_DHT", "CAL_DDBH_nat", "CAL_DDBH_plt", "CAL_DHT_nat", "CAL_DHT_plt"),
                 group = c(rep("DDBH", 10), rep("DHT", 10), rep("HT_P", 6), rep("CF_CAL", 6)),
                 value = c(S8$ddbh, S8$dht, HT_P, CF, CAL$ddbh, CAL$dht)), file.path(DAT, "Fig_constants_read_v103.csv"))

if ("fig3" %in% args) {
  inc_b <- function(resp, b, cmult, size, bal, cr, baph, planted, byi) {
    y <- exp(b[["b0"]] + b[["b1"]] * log(size + 1) + b[["b2"]] * size + b[["b3"]] * bal^2 / log(size + 5) + b[["b4"]] * log(bal + 1) +
          b[["b5"]] * log(cr) + b[["b6"]] * sqrt(baph * size) + b[["b7"]] * planted * pmin(size, GUARD[[resp]]) + b[["b8"]] * log(byi) + b[["b9"]] * planted) * cmult
    pmin(y, CLIP[[resp]])
  }
  C0 <- list(ddbh = CF[["ddbh"]] * CAL$ddbh, dht = CF[["dht"]] * CAL$dht)
  bd <- read_csv(file.path(J, "out/inc/boot_v103_dDBH_v102recal.csv"), show_col_types = FALSE) |> filter(is.finite(c_natural), is.finite(c_planted))
  bh <- read_csv(file.path(J, "out/inc/boot_v103_dHT.csv"), show_col_types = FALSE) |> filter(ok, is.finite(c_natural), is.finite(c_planted))
  logm("boot draws dDBH", nrow(bd), "dHT", nrow(bh))
  BD <- list(ddbh = list(B = matrix(rep(S8$ddbh, each = nrow(bd)), nrow(bd), dimnames = list(NULL, names(S8$ddbh))), C = cbind(bd$c_natural, bd$c_planted)),
             dht = list(B = as.matrix(bh[, paste0("b", 0:9)]), C = cbind(bh$c_natural, bh$c_planted)))
  fixed <- list(cr = 0.7, baph = 30, byi = 264, bal = 15)
  ORIG <- c("Natural", "Planted")
  curve <- function(resp, grid) {
    D <- BD[[resp]]
    q <- t(sapply(seq_len(nrow(grid)), function(i) { r <- grid[i, ]
      v <- sapply(seq_len(nrow(D$B)), function(j) inc_b(resp, D$B[j, ], D$C[j, r$pl + 1], r$size, r$bal, fixed$cr, fixed$baph, r$pl, r$byi))
      quantile(v, c(0.025, 0.975), na.rm = TRUE) }))
    grid |> mutate(y = inc_b(resp, S8[[resp]], C0[[resp]][pl + 1], size, bal, fixed$cr, fixed$baph, pl, byi), lo = q[, 1], hi = q[, 2], o = factor(ORIG[pl + 1], ORIG))
  }
  pa <- curve("ddbh", expand_grid(size = seq(2, 80, 1), bal = c(5, 15, 30), pl = 0:1, byi = fixed$byi)) |> mutate(g = factor(bal), x = size)
  pb <- curve("dht", expand_grid(size = seq(1.5, 25, 0.5), bal = c(5, 15, 30), pl = 0:1, byi = fixed$byi)) |> mutate(g = factor(bal), x = size)
  pd_ <- curve("ddbh", expand_grid(byi = seq(50, 700, 10), size = c(10, 25, 40), pl = 0:1, bal = fixed$bal)) |> mutate(g = factor(size), x = byi)
  pe <- curve("dht", expand_grid(byi = seq(50, 700, 10), size = c(5, 12, 20), pl = 0:1, bal = fixed$bal)) |> mutate(g = factor(size), x = byi)
  write_csv(bind_rows(mutate(pa, panel = "a"), mutate(pb, panel = "b"), mutate(pd_, panel = "d"), mutate(pe, panel = "e")), file.path(DAT, "Fig3_increment_curves_DATA_v103.csv"))
  H <- readRDS(file.path(J, "track3_s02/v103/02_height_fit.rds")); stopifnot(max(abs(H$coef[names(HT_P)] - HT_P)) < 1e-5)
  ht_eq2 <- function(p, dbh, byi, baph, rd) (p[["a0"]] + p[["a1"]] * byi / 100) * (1 - exp(-p[["b"]] * dbh))^p[["c"]] * exp(p[["g1"]] * log(baph + 1) + p[["g2"]] * rd)
  L <- chol(H$vcov); Z <- matrix(rnorm(4000 * 6), 4000); B <- sweep(Z %*% L, 2, H$coef, "+"); colnames(B) <- names(H$coef)
  xs <- seq(2, 80, 1)
  pc <- bind_rows(lapply(c(100, 264, 450), function(s) { P <- apply(B, 1, function(p) ht_eq2(p, xs, s, 30, 0.8))
    tibble(dbh = xs, y = ht_eq2(H$coef, xs, s, 30, 0.8), lo = apply(P, 1, quantile, 0.025), hi = apply(P, 1, quantile, 0.975), g = factor(s)) }))
  write_csv(pc, file.path(DAT, "Fig3_height_curves_DATA_v103.csv"))
  tj <- read_csv(file.path(J, "frames/final/tree_join_v103.csv"), show_col_types = FALSE, col_select = c(source, inst, plot, year, dbh, ht, expf, status, baph, byi)) |>
    filter(tolower(status) == "live", dbh > 0, expf > 0) |> group_by(source, inst, plot, year) |> mutate(rd = dbh / max(dbh)) |> ungroup() |>
    filter(ht > 0, is.finite(byi), is.finite(baph)) |> mutate(pred = ht_eq2(H$coef, dbh, byi, baph, rd))
  eq <- read_csv(file.path(J, "track3_s02/v103/02_height_equivalence.csv"), show_col_types = FALSE) |> filter(vector == "refit, population-average")
  logm("height frame rows", nrow(tj), "equivalence n", eq$n); stopifnot(nrow(eq) == 1, eq$n == nrow(tj))
  write_csv(eq, file.path(DAT, "Fig3_panel_f_equivalence_v103.csv"))
  lab_bal <- expression(paste("BAL (", m^2, " ", ha^-1, ")"))
  LT <- scale_linetype_manual(values = c(Natural = "solid", Planted = "22"), name = "Origin")
  cpanel <- function(d, xl, yl, tag, legname, ymul, lpos, show_lt = FALSE) {
    g <- ggplot(d, aes(x, y, colour = g, linetype = o)) +
      geom_ribbon(aes(ymin = lo, ymax = hi, fill = g, group = interaction(g, o)), alpha = 0.10, colour = NA) +
      geom_line(linewidth = 0.6) + LT + scale_colour_manual(values = LVL_COL, name = legname) + scale_fill_manual(values = LVL_COL, guide = "none") +
      labs(x = xl, y = yl, tag = tag) + scale_y_continuous(limits = c(0, ymul * max(d$y)), expand = c(0, 0), oob = scales::squish) + theme_koa()
    if (show_lt) g + guides(colour = guide_legend(order = 1, direction = "horizontal", title.position = "top", override.aes = list(linetype = "solid", fill = NA)),
                            linetype = guide_legend(order = 2, direction = "horizontal", title.position = "top")) +
      theme(legend.position = lpos, legend.box = "vertical", legend.key.width = unit(3, "mm"), legend.spacing.y = unit(0.5, "mm"))
    else g + guides(linetype = "none", colour = guide_legend(direction = "horizontal", title.position = "top", override.aes = list(linetype = "solid", fill = NA))) +
      theme(legend.position = lpos, legend.key.width = unit(3, "mm"))
  }
  yD <- expression(paste(Delta, "DBH (cm ", yr^-1, ")")); yH <- expression(paste(Delta, "HT (m ", yr^-1, ")"))
  f3a <- cpanel(pa, "DBH (cm)", yD, "(a)", lab_bal, 1.45, c(0.52, 0.86))
  f3b <- cpanel(pb, "Height (m)", yH, "(b)", lab_bal, 1.45, c(0.52, 0.88))
  f3c <- ggplot(pc, aes(dbh, y, colour = g, fill = g)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.22, colour = NA) + geom_line(linewidth = 0.7) +
    scale_colour_manual(values = LVL_COL, name = "BYI (index units)") + scale_fill_manual(values = LVL_COL, name = "BYI (index units)") +
    labs(x = "DBH (cm)", y = "Height (m)", tag = "(c)") + coord_cartesian(ylim = c(0, NA)) + theme_koa() + theme(legend.position = c(0.72, 0.25))
  f3d <- cpanel(pd_, "BYI (index units)", yD, "(d)", "DBH (cm)", 1.9, c(0.48, 0.8), show_lt = TRUE)
  f3e <- cpanel(pe, "BYI (index units)", yH, "(e)", "Height (m)", 1.45, c(0.48, 0.88))
  lim <- c(0, 36)
  f3f <- ggplot(tj, aes(pred, ht)) +
    geom_polygon(data = tibble(x = c(0, 36, 36), y = c(0, 27, 45)), aes(x, y), fill = "grey80", alpha = 0.5, inherit.aes = FALSE) +
    geom_point(size = 0.25, alpha = 0.18, colour = "grey25", stroke = 0) + geom_abline(slope = 1, intercept = 0, linewidth = 0.45) +
    geom_smooth(method = "lm", formula = y ~ x, se = TRUE, colour = "#9E2B25", fill = "#9E2B25", alpha = 0.3, linewidth = 0.6) +
    coord_equal(xlim = lim, ylim = lim, expand = FALSE) + labs(x = "Predicted height (m)", y = "Observed height (m)", tag = "(f)") + theme_koa()
  save2((f3a | f3b | f3c) / (f3d | f3e | f3f), "Fig3_components", 174, 118)
}

if ("fig4" %in% args) {
  stopifnot(file.exists(file.path(J, "a2/closeout/MC_PROMOTED")))
  M <- file.path(E, "out_m1")
  ## engine_v103 out_m1 rep columns are GLOBAL draw indices (even-aged 0 to 2999, 500 per scenario x BYI; uneven-aged 0 to 899, 300 per
  ## BYI). No rep is the point run (v102 trajectories.csv used rep 0 as the point run). Bands: 2.5 and 97.5 percentiles over all draws
  ## of a cell. Point projections: traj_M1.csv (even-aged) and uneven_aged_traj_M1.csv (uneven-aged), the deployed point runs.
  re <- read_csv(file.path(M, "reps_evenaged_M1.csv"), show_col_types = FALSE) |> mutate(scenario = ifelse(scen == "nat", "Even-aged natural", "Even-aged planted"))
  ru <- read_csv(file.path(M, "uneven_aged_reps_M1.csv"), show_col_types = FALSE) |> mutate(scenario = "Uneven-aged natural")
  tr <- bind_rows(re |> select(scenario, byi, year, rep, QMD, BAPH, TPH, VOL), ru |> select(scenario, byi, year, rep, QMD, BAPH, TPH, VOL)) |>
    mutate(byi = as.character(byi), age = year, MAI = VOL / age)
  pe <- read_csv(file.path(M, "traj_M1.csv"), show_col_types = FALSE) |> mutate(scenario = ifelse(origin == "nat", "Even-aged natural", "Even-aged planted"))
  pu <- read_csv(file.path(M, "uneven_aged_traj_M1.csv"), show_col_types = FALSE) |> transmute(scenario = "Uneven-aged natural", byi = BYI, year = age, QMD, BAPH, TPH, VOL = Vol)
  pt <- bind_rows(pe |> select(scenario, byi, year, QMD, BAPH, TPH, VOL), pu) |> mutate(byi = as.character(byi), age = year, MAI = VOL / age)
  nrep <- tr |> distinct(scenario, byi, rep) |> count(scenario, byi, name = "draws"); print(nrep)
  write_csv(nrep, file.path(DAT, "Fig4_nreps_v103.csv"))
  long <- tr |> select(scenario, byi, age, rep, QMD, BAPH, TPH, VOL, MAI) |> pivot_longer(c(QMD, BAPH, TPH, VOL, MAI), names_to = "var", values_to = "val")
  bands <- long |> group_by(scenario, byi, age, var) |>
    summarise(lo = quantile(val, 0.025, na.rm = TRUE), hi = quantile(val, 0.975, na.rm = TRUE), .groups = "drop") |> filter(!(var == "MAI" & age < 5), age <= 100)
  pts <- pt |> select(scenario, byi, age, QMD, BAPH, TPH, VOL, MAI) |> pivot_longer(c(QMD, BAPH, TPH, VOL, MAI), names_to = "var", values_to = "val") |>
    filter(!(var == "MAI" & age < 5), age <= 100)
  stopifnot(nrow(distinct(pts, scenario, byi)) == 9)
  write_csv(bands, file.path(DAT, "Fig4_bands_DATA_v103.csv")); write_csv(pts, file.path(DAT, "Fig4_point_DATA_v103.csv"))
  vars <- list(QMD = "QMD (cm)", BAPH = expression(paste("Basal area (", m^2, " ", ha^-1, ")")), TPH = expression(paste("Stems (trees ", ha^-1, ")")),
               VOL = expression(paste("Volume (", m^3, " ", ha^-1, ")")), MAI = expression(paste("Net MAI (", m^3, " ", ha^-1, " ", yr^-1, ")")))
  scen <- c("Even-aged natural", "Even-aged planted", "Uneven-aged natural")
  ceil <- tibble(scenario = scen, y = c(CAPS[["natural"]], CAPS[["planted"]], CAPS[["natural"]]))
  obsmax <- tibble(var = c("QMD", "BAPH"), y = c(OBS[["QMD"]], OBS[["BAPH"]]))
  panels <- list(); k <- 0
  for (v in names(vars)) for (s in scen) { k <- k + 1
    pb_ <- bands |> filter(var == v, scenario == s); pp <- pts |> filter(var == v, scenario == s)
    yr <- range(c(bands$lo[bands$var == v], bands$hi[bands$var == v], pts$val[pts$var == v]), na.rm = TRUE)
    if (v == "MAI") yr <- c(0, min(yr[2], 35)); if (v == "BAPH") yr[2] <- max(yr[2], 1.04 * OBS[["BAPH"]])
    g <- ggplot() + annotate("rect", xmin = if (s == "Even-aged planted") 18 else 52, xmax = 100, ymin = -Inf, ymax = Inf, fill = "grey93") +   # v106: planted record ends at 18 yr
      geom_ribbon(data = pb_, aes(age, ymin = lo, ymax = hi, fill = byi), alpha = 0.16) + geom_line(data = pp, aes(age, val, colour = byi), linewidth = 0.65) +
      scale_colour_manual(values = SITE_COL, name = "BYI (index units)") + scale_fill_manual(values = SITE_COL, name = "BYI (index units)") +
      scale_x_continuous(breaks = seq(0, 100, 25), expand = c(0.01, 0)) + coord_cartesian(ylim = c(0, yr[2])) +
      labs(x = if (v == "MAI") "Stand age (yr)" else NULL, y = if (s == scen[1]) vars[[v]] else NULL, title = if (v == "QMD") s else NULL) +
      theme_koa(7.5) + theme(plot.title = element_text(size = 8, face = "bold", hjust = 0.5))
    if (v == "QMD") g <- g + geom_hline(data = ceil |> filter(scenario == s), aes(yintercept = y), linetype = "dotted", linewidth = 0.45)
    if (v %in% obsmax$var && !(v == "QMD" && s == scen[2])) g <- g + geom_hline(yintercept = obsmax$y[obsmax$var == v], linetype = "dashed", linewidth = 0.3, colour = "grey40")
    panels[[k]] <- g }
  save2(wrap_plots(panels, ncol = 3, guides = "collect") & theme(legend.position = "bottom"), "Fig4_projections", 174, 210)
}

if ("fig5" %in% args) {
  pn <- read_csv(file.path(DAT, "LT_v103_points.csv"), show_col_types = FALSE) |> mutate(engine = "v103 engine", obs_s = obs_surv_w)
  po <- read_csv(path.expand("~/jobs/koa_v102_20260918/track3/lt/out/LT_v102_points.csv"), show_col_types = FALSE) |> mutate(engine = "v102 engine", obs_s = obs_surv)
  tn <- read_csv(file.path(DAT, "LT_v103_traj.csv"), show_col_types = FALSE)
  logm("LT plots", n_distinct(pn$pid), "points", nrow(pn)); stopifnot(n_distinct(pn$pid) == 15)
  ptsL <- bind_rows(pn, po) |> mutate(origin = ifelse(planted == 1, "Planted", "Natural"), engine = factor(engine, c("v103 engine", "v102 engine")))
  longp <- pn |> group_by(pid) |> summarise(span = max(h), .groups = "drop") |> filter(span >= 20) |> pull(pid)
  lab <- function(p) { x <- sub("^DOFAW\\|", "", p); x <- sub("\\|", " ", x); ifelse(x == "Kulani 12", "Kulani 12 (planted)", paste0(x, " (natural)")) }
  lp <- pn |> filter(pid %in% longp) |> mutate(plot = lab(pid))
  ltr <- tn |> filter(pid %in% longp) |> left_join(pn |> distinct(pid, tph0), by = "pid") |> mutate(plot = lab(pid), surv = TPH / tph0)
  pal <- c("#555555", "#C08A1E", "#E07B39", "#3B5BA5", "#6B4C9A")
  th6 <- theme_koa() + theme(legend.key.width = unit(6, "mm"))
  mk_top <- function(y_tr, y_ob, ylab, tag) ggplot() + geom_line(data = ltr, aes(h, .data[[y_tr]], colour = plot), linewidth = 0.6) +
    geom_point(data = lp, aes(h, .data[[y_ob]], colour = plot), size = 1.4) + scale_colour_manual(values = pal, name = "DOFAW plot") +
    guides(colour = guide_legend(nrow = 2)) + labs(x = "Years since first measurement", y = ylab, tag = tag) + th6
  a <- mk_top("surv", "obs_s", "Cohort survival (fraction)", "(a)"); b <- mk_top("QMD", "obsQMD", "Cohort QMD (cm)", "(b)")
  c_ <- mk_top("BAPH", "obsBAPH", expression(paste("Cohort basal area (", m^2, " ", ha^-1, ")")), "(c)")
  res <- ptsL |> transmute(pid, origin, engine, h, `Survival (fraction)` = pr_surv - obs_s, `QMD (cm)` = prQMD - obsQMD, BA = prBAPH - obsBAPH) |>
    pivot_longer(c(`Survival (fraction)`, `QMD (cm)`, BA), names_to = "var", values_to = "err") |> filter(is.finite(err))
  hc <- function(h) cut(h, c(0, 5, 10, 20, 35, 60), labels = c("1-5", "6-10", "11-20", "21-35", "36-52"))
  mid <- c("1-5" = 3, "6-10" = 8, "11-20" = 15.5, "21-35" = 28, "36-52" = 44)
  cb <- res |> filter(engine == "v103 engine") |> mutate(hc = hc(h)) |> group_by(var, origin, hc) |>
    group_modify(function(d, k) { ids <- unique(d$pid); bs <- replicate(2000, { s <- sample(ids, length(ids), TRUE); mean(unlist(lapply(s, function(i) d$err[d$pid == i]))) })
      tibble(n = nrow(d), plots = length(ids), m = mean(d$err), lo = quantile(bs, 0.025), hi = quantile(bs, 0.975)) }) |> ungroup() |> mutate(hm = mid[as.character(hc)])
  write_csv(res, file.path(DAT, "Fig5_longterm_residuals_DATA_v103.csv")); write_csv(cb, file.path(DAT, "Fig5_horizon_bias_CI_v103.csv"))
  OCOL <- c(Natural = "#0F6E64", Planted = "#9E2B25")
  mk_bot <- function(v, ylab, tag) { dd <- res |> filter(var == v); cc <- cb |> filter(var == v)
    ggplot(dd, aes(h, err, colour = origin)) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey40") +
      geom_point(aes(shape = engine), size = 1.1, alpha = 0.7) +
      geom_errorbar(data = cc, aes(x = hm + ifelse(origin == "Planted", 0.8, -0.8), ymin = lo, ymax = hi), inherit.aes = FALSE, colour = "black", width = 0, linewidth = 0.45) +
      geom_point(data = cc, aes(x = hm + ifelse(origin == "Planted", 0.8, -0.8), y = m, fill = origin), inherit.aes = FALSE, shape = 23, size = 1.8, colour = "black", stroke = 0.3) +
      scale_shape_manual(values = c(`v103 engine` = 16, `v102 engine` = 1), name = NULL) + scale_colour_manual(values = OCOL, name = NULL) +
      scale_fill_manual(values = OCOL, guide = "none") + labs(x = "Projection horizon (yr)", y = ylab, tag = tag) + th6 }
  d_ <- mk_bot("Survival (fraction)", "Survival bias (predicted minus observed)", "(d)")
  e_ <- mk_bot("QMD (cm)", "QMD bias (cm)", "(e)")
  f_ <- mk_bot("BA", expression(paste("Basal area bias (", m^2, " ", ha^-1, ")")), "(f)")
  fig5 <- ((a | b | c_) + plot_layout(guides = "collect")) / ((d_ | e_ | f_) + plot_layout(guides = "collect")) & theme(legend.position = "bottom")
  save2(fig5, "Fig5_longterm", 180, 150)
}

if ("fig6" %in% args) {
  sc <- read_csv(file.path(DAT, "SC_trajectories.csv"), show_col_types = FALSE)
  sc <- sc |> mutate(panel = case_when(group == "density" & origin == "natural" ~ "Natural, initial density", group == "density" & origin == "planted" ~ "Planted, initial density", TRUE ~ "Thinning from below"),
                     series = ifelse(group == "thinning", paste(ifelse(origin == "planted", "Planted,", "Natural,"), sub("thinned to 500 at 8 and 250 at 20", "thinned to 500 at 8, 250 at 20", tolower(label))), label))
  lev <- c(unique(sc$series[sc$panel == "Natural, initial density"]), unique(sc$series[sc$panel == "Planted, initial density"]), unique(sc$series[sc$panel == "Thinning from below"]))
  sc$series <- factor(sc$series, lev); levels(sc$series) <- sub("^([0-9,]+) stems$", "\\1 trees ha⁻¹", levels(sc$series)); lev <- levels(sc$series)
  cols <- c("#9CC9C1", "#4E9E92", "#0F6E64", "#063B35", "#E7B9B5", "#C9706A", "#9E2B25", "#5A1411", "#9E2B25", "#C08A1E", "#6B4C9A", "#0F6E64", "#3B5BA5")
  stopifnot(length(lev) == length(cols)); names(cols) <- lev
  th6 <- theme_koa() + theme(legend.key.width = unit(6, "mm"))
  mkp <- function(var, ylab, panel_name, tag, show_x = FALSE, dashed_total = FALSE) { dd <- sc |> filter(panel == panel_name)
    if (var == "mai_total") dd <- dd |> filter(year >= 5)
    g <- ggplot(dd, aes(year, .data[[var]], colour = series)) + geom_line(linewidth = 0.6)
    if (dashed_total) g <- g + geom_line(data = dd |> filter(group == "thinning"), aes(year, total_yield, colour = series), linetype = "22", linewidth = 0.5)
    g + scale_colour_manual(values = cols, name = NULL) + labs(x = if (show_x) "Stand age (yr)" else NULL, y = ylab, tag = tag) +
      th6 + theme(legend.position = "bottom", legend.key.height = unit(2.5, "mm")) + guides(colour = guide_legend(ncol = 1)) }
  panels6 <- c("Natural, initial density", "Planted, initial density", "Thinning from below")
  rows <- list(list("QMD", "QMD (cm)"), list("TPH", expression(paste("Stems (trees ", ha^-1, ")"))), list("VOL", expression(paste("Volume (", m^3, " ", ha^-1, ")"))),
               list("mai_total", expression(paste("Total MAI (", m^3, " ", ha^-1, " ", yr^-1, ")"))))
  pl <- list(); k <- 0
  for (i in seq_along(rows)) for (j in seq_along(panels6)) { k <- k + 1
    g <- mkp(rows[[i]][[1]], if (j == 1) rows[[i]][[2]] else NULL, panels6[j], paste0("(", letters[k], ")"), show_x = i == length(rows), dashed_total = (rows[[i]][[1]] == "VOL" && j == 3))
    if (i == 1) g <- g + ggtitle(panels6[j]) + theme(plot.title = element_text(face = "bold", size = 8, hjust = 0.5))
    if (rows[[i]][[1]] == "TPH") g <- g + scale_y_log10(breaks = c(100, 200, 300, 500, 1000, 2000))
    if (i < length(rows)) g <- g + theme(legend.position = "none")
    pl[[k]] <- g }
  save2(wrap_plots(pl, ncol = 3), "Fig6_scenarios", 180, 215)
}
logm("DONE", paste(args, collapse = " "))
