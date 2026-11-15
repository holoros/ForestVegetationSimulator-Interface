# 56_release_1141.R  Coefficient file of the 1.14.1 release (release_v1141/koa_rdbyi_equations.csv) from the fitted objects: script 44 (J1 estimates),
# script 45 (500 joint resamples), script 50 (ingrowth stages and their 2,000 resamples), and the 1.14.0 file for the equations that did not change.
# Then the release check by a different code path: koa_project() of release_v1141/koa_step_rdbyi.R against the point projections of script 51
# (E5, with ingrowth in the natural scenarios) and against the 200-year runs of script 53 for the fallback rule. No identifier is printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_final_eq_20261110")
old <- fread("release_v114/koa_rdbyi_equations.csv"); th <- unlist(readRDS("out/height_increment_44.rds")$FF$J1$th); B <- readRDS("out/boot_round4_45.rds")$J1; B <- B[B[, "conv"] == 0, ]; nb <- nrow(B)
row <- function(eq, term, est, v) data.table(equation = eq, term = term, estimate = est, se_model = NA_real_, se_plot_bootstrap = sd(v), lo95 = quantile(v, 0.025), hi95 = quantile(v, 0.975), n_boot = length(v))
e2 <- rbind(row("E2_height", "b", exp(th[["ln_b"]]), exp(B[, "ln_b"])), row("E2_height", "c", exp(th[["ln_c"]]), exp(B[, "ln_c"])))
e5 <- rbindlist(lapply(c("a0", "a_lbyi", "lk", "lc", "x", "k_pl"), function(p) row("E5_height_increment", p, th[[p]], B[, p])))
IG <- readRDS("out/ingrowth_50.rds"); K <- IG$BT[IG$BT[, 4] == 1 & complete.cases(IG$BT), 1:3]
ig <- rbind(row("IG_ingrowth", "t0", IG$b[[1]], K[, 1]), row("IG_ingrowth", "t_qmd", IG$b[[2]], K[, 2]), row("IG_ingrowth", "mu2", IG$mu2, K[, 3]))
new <- rbind(e2, old[equation == "S1_sdimax"], old[equation == "E3c_crown_base"], old[equation == "E4r_diameter_increment"], e5, old[equation == "E6r_mortality"], ig)
stopifnot(nrow(new) == 31, nb == 500, nrow(K) == 1723); fwrite(new, "release_v1141/koa_rdbyi_equations.csv"); cat("coefficient rows:", nrow(new), "(1.14.0:", nrow(old), ")\n"); print(new[equation %in% c("E2_height", "E5_height_increment", "IG_ingrowth"), .(equation, term, estimate = signif(estimate, 6), se = signif(se_plot_bootstrap, 4), lo95 = signif(lo95, 5), hi95 = signif(hi95, 5), n_boot)])
# release check
L <- readLines("scripts/51_j1_items.R"); eval(parse(text = L[1:grep("^SC <- CJ", L)]))
e <- new.env(); sys.source("release_v1141/koa_step_rdbyi.R", e); cfn <- e$koa_read_coef("release_v1141/koa_rdbyi_equations.csv")
S <- fread("ms_v136/scenarios_long_j1.csv")[site_dev == FALSE & var %in% c("BA", "TPH", "QMD", "HT") & year %in% c(20, 40, 100)]; w1 <- 0
for (i in seq_len(nrow(SC))) { Lx <- getL(SC$planted[i]); z <- e$koa_project(Lx$DBH, Lx$HT, Lx$EXPF_c, SC$byi[i], SC$planted[i], 100, cfn, height = "E5", ingrowth = SC$planted[i] == 0)
  for (v in c("BA", "TPH", "QMD", "HT")) for (y in c(20, 40, 100)) { ref <- S[planted == SC$planted[i] & level == SC$level[i] & var == v & year == y, point]; w1 <- max(w1, abs(z[[v]][y + 1] - ref) / max(abs(ref), 1e-9)) } }
M <- fread("out/longterm_metrics_53.csv")[form == "R0" & year %in% c(20, 40, 100, 200)]; w2 <- 0
for (i in seq_len(nrow(SC))) { Lx <- getL(SC$planted[i]); z <- e$koa_project(Lx$DBH, Lx$HT, Lx$EXPF_c, SC$byi[i], SC$planted[i], 200, cfn, height = "rule", ingrowth = SC$planted[i] == 0)
  for (v in c("HT", "QMD")) for (y in c(20, 40, 100, 200)) { ref <- M[planted == SC$planted[i] & level == SC$level[i] & year == y][[v]]; w2 <- max(w2, abs(z[[v]][y + 1] - ref) / max(abs(ref), 1e-9)) } }
cat("largest relative difference: E5 with ingrowth against script 51 (6 scenarios x 4 variables x 3 years)", signif(w1, 3), "; rule against script 53 (6 scenarios x 2 variables x 4 years)", signif(w2, 3), "\n")
cat("asymptote (m) at BYI 156 and 248:", round(e$koa_asymptote(c(156.1, 247.7), cfn), 2), "; height at DBH 12.7 cm, BYI 248:", round(e$koa_height(12.7, 247.7, cfn), 2), "; ingrowth at QMD 15, 25, 40, 60:", round(e$koa_ingrowth(c(15, 25, 40, 60), cfn), 3), "\n")
stopifnot(w1 < 1e-6, w2 < 1e-6); cat("PASS\n")
