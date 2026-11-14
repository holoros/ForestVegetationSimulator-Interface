# 41_release_check.R  Checks the reference implementation of deposit 1.14.0 (release_v114/koa_step_rdbyi.R with koa_rdbyi_equations.csv) against
# script 39 by a different code path: the six scenarios are projected 100 years with koa_project() and compared with the point projections
# that script 39 saved (ms_v134b/scenarios_long_b2.csv), and with height = "rule" against script 23t (ms_rdbyi2/scenarios_long_rdbyi2.csv).
# The scenario starting lists come from the first 46 lines of script 39. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/39_b2_items.R"); eval(parse(text = L[1:46]))
e <- new.env(); sys.source("release_v114/koa_step_rdbyi.R", e); cfn <- e$koa_read_coef("release_v114/koa_rdbyi_equations.csv")
chk <- function(file, how) { S <- fread(file)[site_dev == FALSE & var %in% c("BA", "TPH", "QMD", "HT") & year %in% c(20, 40, 100)]; worst <- 0
  for (i in seq_len(nrow(SC))) { Lx <- getL(SC$planted[i]); z <- e$koa_project(Lx$DBH, Lx$HT, Lx$EXPF_c, SC$byi[i], SC$planted[i], 100, cfn, height = how)
    for (v in c("BA", "TPH", "QMD", "HT")) for (y in c(20, 40, 100)) { ref <- S[planted == SC$planted[i] & level == SC$level[i] & var == v & year == y, point]; worst <- max(worst, abs(z[[v]][y + 1] - ref) / max(abs(ref), 1e-9)) } }
  worst }
w1 <- chk("ms_v134b/scenarios_long_b2.csv", "E5"); w2 <- chk("ms_rdbyi2/scenarios_long_rdbyi2.csv", "rule")
cat("largest relative difference, 6 scenarios x 4 variables x 3 years: E5 against script 39", signif(w1, 3), "; rule against script 23t", signif(w2, 3), "\n")
x <- c(0, 0.5); cat("crown ratio from koa_hcb at HT 8 and 20 m, x = 0 and 0.5:", round(1 - e$koa_hcb(8, x, cfn) / 8, 3), round(1 - e$koa_hcb(20, x, cfn) / 20, 3), "\n")
stopifnot(w1 < 1e-6, w2 < 1e-6); cat("PASS\n")
