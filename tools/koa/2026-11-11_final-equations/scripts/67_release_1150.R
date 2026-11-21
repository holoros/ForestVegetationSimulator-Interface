# 67_release_1150.R  Coefficient file of the 1.15.0 release (release_v1150/koa_rdbyi_equations.csv): S1, E4r and E6r refitted by script 22t
# with the predicted Kapapala BYI (release_rdbyi2), E2 and E5 from script 44 (J1) with the 500 joint resamples of script 45, ingrowth from
# script 50, and crown base E3e carried from 1.14.3. Release check by a different code path: koa_project() of release_v1150/koa_step_rdbyi.R
# against the point projections of script 51. No identifier is printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121"); dir.create("release_v1150", showWarnings = FALSE)
ch <- fread("out/boot_round4_45_choice.csv"); pick <- if (any(ch$candidate)) ch[candidate == TRUE][order(ratio)]$form[1] else NA
cat("script 45 adopted:", pick, "\n"); cat("kept J1 by Aaron's choice of 21 Nov 2026 (the rule of script 45 picks", pick, "by asymptote interval width)\n")
th <- unlist(readRDS("out/height_increment_44.rds")$FF$J1$th); B <- readRDS("out/boot_round4_45.rds")$J1; B <- B[B[, "conv"] == 0, ]; nb <- nrow(B)
row <- function(eq, term, est, v) data.table(equation = eq, term = term, estimate = est, se_model = NA_real_, se_plot_bootstrap = sd(v), lo95 = quantile(v, 0.025), hi95 = quantile(v, 0.975), n_boot = length(v))
e2 <- rbind(row("E2_height", "b", exp(th[["ln_b"]]), exp(B[, "ln_b"])), row("E2_height", "c", exp(th[["ln_c"]]), exp(B[, "ln_c"])))
e5 <- rbindlist(lapply(c("a0", "a_lbyi", "lk", "lc", "x", "k_pl"), function(p) row("E5_height_increment", p, th[[p]], B[, p])))
IG <- readRDS("out/ingrowth_50.rds"); K <- IG$BT[IG$BT[, 4] == 1 & complete.cases(IG$BT), 1:3]
ig <- rbind(row("IG_ingrowth", "t0", IG$b[[1]], K[, 1]), row("IG_ingrowth", "t_qmd", IG$b[[2]], K[, 2]), row("IG_ingrowth", "mu2", IG$mu2, K[, 3]))
r2 <- fread("release_rdbyi2/koa_rdbyi_equations.csv"); o3 <- fread("release_v1143/koa_rdbyi_equations.csv")
new <- rbind(e2, r2[equation == "S1_sdimax"], o3[equation == "E3e_crown_base"], r2[equation == "E4r_diameter_increment"], e5, r2[equation == "E6r_mortality"], ig, fill = TRUE)
stopifnot(nrow(new) == nrow(o3), nb == 500, setequal(paste(new$equation, new$term), paste(o3$equation, o3$term)))
fwrite(new, "release_v1150/koa_rdbyi_equations.csv")
cmp <- merge(o3[, .(equation, term, v1143 = estimate)], new[, .(equation, term, v1150 = estimate)], by = c("equation", "term"), sort = FALSE)
cat("coefficients, 1.14.3 against 1.15.0:\n"); print(cmp[, .(equation, term, v1143 = signif(v1143, 6), v1150 = signif(v1150, 6))], nrows = 100)
s <- readLines("release_v1143/koa_step_rdbyi.R"); i <- grep("^# with koa-only BAL and BA. Reads its coefficients", s)
s[i] <- "# with koa-only BAL and BA. Version 1.15.0 (November 21, 2026) refits S1, E4r, E6r, E2, E5 and ingrowth with BYI predicted for the 53 Kapapala plots"
s <- append(s, "# (statewide C2 forest from their own climate and soils) in place of one fill value; forms unchanged. Reads its coefficients from koa_rdbyi_equations.csv.", i)
writeLines(s, "release_v1150/koa_step_rdbyi.R")
L <- readLines("scripts/51_j1_items.R"); eval(parse(text = L[1:grep("^SC <- CJ", L)]))
e <- new.env(); sys.source("release_v1150/koa_step_rdbyi.R", e); cfn <- e$koa_read_coef("release_v1150/koa_rdbyi_equations.csv")
S <- fread("ms_v136/scenarios_long_j1.csv")[site_dev == FALSE & var %in% c("BA", "TPH", "QMD", "HT") & year %in% c(20, 40, 100)]; w1 <- 0
for (i in seq_len(nrow(SC))) { Lx <- getL(SC$planted[i]); z <- e$koa_project(Lx$DBH, Lx$HT, Lx$EXPF_c, SC$byi[i], SC$planted[i], 100, cfn, height = "E5", ingrowth = SC$planted[i] == 0)
  for (v in c("BA", "TPH", "QMD", "HT")) for (y in c(20, 40, 100)) { ref <- S[planted == SC$planted[i] & level == SC$level[i] & var == v & year == y, point]; w1 <- max(w1, abs(z[[v]][y + 1] - ref) / max(abs(ref), 1e-9)) } }
cat("scenario BYI levels:\n"); print(SC)
cat("largest relative difference, koa_project against script 51 (6 scenarios x 4 variables x 3 years):", signif(w1, 3), "\n")
cat("asymptote (m) at the median BYI natural and planted:", round(e$koa_asymptote(SC[level == "md"]$byi, cfn), 2), "\n")
stopifnot(w1 < 1e-6); cat("PASS\n")
