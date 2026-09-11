#!/usr/bin/env Rscript
# =============================================================================
# koa_mortality_selftest_2026-09-09.R
#
# Self-test for the three-stage Acacia koa A.Gray mortality component as it is
# DEPLOYED IN THE PRODUCTION HiGy.R of the FvsHiHistory branch, version 0.4.0,
# ported 9 September 2026 onto the deposit's deployed arm (H_QMD, anchored
# beta 0.16019053617304435, A1 floor). Section 1 and the section-3 in-sample
# check still exercise the fitted-H40 arm on purpose (KOA_GARCIA_BETA, floor
# off), since that is the arm the underlying H40 plot data and the original
# 8 September 2026 numbers were built on; koa_mortality_step() still
# reproduces that arm exactly by explicit default (see HiGy.R 0.4.0 header).
# New section 1b and the section-5 additions exercise the ported anchored
# arm, and Rscript cross-validation against the deposit's Python source
# (figshare_v66/koa_mortality_garcia.py, koa_params.py) is reported
# separately in HiGy_v040_parity_report_2026-09-09.md, since this file has
# no Python of its own to compare against.
#
# The test sources the production file and exercises the functions that file
# actually defines, so it cannot pass against a copy of the component that has
# drifted from what ships. It never redefines a constant, an equation or a
# guard, and every number it asserts comes from HiGy.R or from
# plot_interval_pairs_DATA.csv.
#
# Run:  Rscript koa_mortality_selftest_2026-09-08.R [HiGy.R] [plot_interval_pairs_DATA.csv]
# Exit status 1 on any FAIL.
# =============================================================================

args    <- commandArgs(trailingOnly = TRUE)
higy    <- if (length(args) >= 1) args[1] else "HiGy.R"
csvpath <- if (length(args) >= 2) args[2] else "plot_interval_pairs_DATA.csv"

cat("koa mortality self-test against the production HiGy.R,", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("R:", R.version.string, "\n")
cat("production file:", normalizePath(higy), "\n")

ok_all <- TRUE
chk <- function(cond, msg) {
  ok_all <<- ok_all && isTRUE(cond)
  cat(sprintf("  [%s] %s\n", if (isTRUE(cond)) "PASS" else "FAIL", msg))
}

## ---- 0. The production file loads, is self-contained, and carries no ramp ----
src <- readLines(higy, warn = FALSE)
suppressPackageStartupMessages(source(higy))
cat("\n0. Production file\n")
cat(sprintf("   VersionTag = %s, %d lines, %d bytes\n", VersionTag, length(src), file.size(higy)))
chk(VersionTag == "HiGyV0.4.0", "VersionTag is HiGyV0.4.0")

# Self-containment: no source(), no read.csv/read.table/readRDS/load outside comments
code <- sub("#.*$", "", src)
ext <- grep("(^|[^a-zA-Z._])(source|read\\.csv|read\\.table|readRDS|load|file\\.path|system\\.file)\\s*\\(", code)
cat(sprintf("   external-input call sites in code (excluding comments): %d\n", length(ext)))
if (length(ext)) cat(paste0("     line ", ext, ": ", trimws(code[ext]), collapse = "\n"), "\n")
chk(length(ext) == 0, "production file loads no external data and sources no other file")

# Every component constant is a literal in the file
for (nm in c("KOA_GARCIA_ALPHA", "KOA_GARCIA_BETA", "KOA_REINEKE_EXP", "KOA_ALLOC_CAP",
             "KOA_IRREG_RATE", "KOA_IRREG_INTERVAL", "KOA_ALLOC_B", "KOA_IRREG_LOSS",
             "KOA_GARCIA_BETA_ANCHORED", "KOA_GARCIA_ALLOM_A", "KOA_GARCIA_ALLOM_K_HD",
             "KOA_BASE_NAT", "KOA_BASE_PLT"))
  chk(exists(nm), sprintf("%s is defined in the production file", nm))
chk(exists("koa_h_qmd"), "koa_h_qmd() is defined in the production file")
chk(abs(KOA_GARCIA_BETA_ANCHORED - 0.16019053617304435) < 1e-15,
    "anchored beta matches the deposit's GARCIA_BETA_ANCHORED exactly")
chk(abs(KOA_GARCIA_ALLOM_A - (-0.16863070512157105)) < 1e-15,
    "H_QMD allometry intercept matches the deposit's GARCIA_ALLOM_A exactly")
chk(abs(KOA_GARCIA_ALLOM_K_HD - 1.1719473700506686) < 1e-15,
    "H_QMD allometry slope matches the deposit's GARCIA_ALLOM_K_HD exactly")
chk(KOA_BASE_NAT == 0.003 && KOA_BASE_PLT == 0.006,
    "A1 floor constants match the deposit's BASE_NAT / BASE_PLT exactly")
cat(sprintf("   alpha = gamma = %.2f, beta = %.3f m-1, Reineke exponent %.3f, cap %.2f, b %d\n",
            KOA_GARCIA_ALPHA, KOA_GARCIA_BETA, KOA_REINEKE_EXP, KOA_ALLOC_CAP, KOA_ALLOC_B))
chk(KOA_REINEKE_EXP == 1.605, "stand density index exponent is 1.605 and not 1.6")
chk(length(KOA_IRREG_LOSS) == 60, "embedded magnitude vector holds 60 elements")

# The withdrawn Eq. 5b ramp must be absent from executable code
ramp <- grep("(onset|full.?lift|0\\.15\\s*\\*|850)", code)
cat(sprintf("   withdrawn-ramp constants found in executable code: %d\n", length(ramp)))
chk(length(ramp) == 0, "the withdrawn Eq. 5b density ramp appears nowhere in executable code")

## ---- 1. Cycle-length invariance, the 1e-6 contract -------------------------
# Pinned to the fitted H40 arm explicitly (beta = KOA_GARCIA_BETA, floor off)
# since koa_regular_survival()'s own default changed to the anchored H_QMD
# arm with the floor on 9 September 2026. These checks are about the Garcia
# recursion's algebraic properties (cycle invariance, no growth -> no
# mortality, the limiting line), which hold on either arm; they are run here
# on the original fitted arm so the numbers stay comparable to 8 September
# 2026. Section 1b below repeats the growth-driven checks on the ported arm.
cat("\n1. Cycle-length invariance of the Garcia step (fitted H40 arm)\n")
b117 <- KOA_GARCIA_BETA
one <- koa_regular_survival(1500, 10, 20, beta = b117, base_nat = NA, base_plt = NA)$N1
N <- 1500; h <- seq(10, 20, length.out = 11)
for (i in 2:11) N <- koa_regular_survival(N, h[i - 1], h[i], beta = b117, base_nat = NA, base_plt = NA)$N1
N100 <- 1500; h100 <- seq(10, 20, length.out = 101)
for (i in 2:101) N100 <- koa_regular_survival(N100, h100[i - 1], h100[i], beta = b117, base_nat = NA, base_plt = NA)$N1
cat(sprintf("   one 10-year step H40 10 to 20 m from 1,500 trees ha-1: %.10f\n", one))
cat(sprintf("   ten 1-year sub-steps on the same height path:          %.10f  (diff %.3e)\n", N, abs(one - N)))
cat(sprintf("   one hundred sub-steps on the same height path:         %.10f  (diff %.3e)\n", N100, abs(one - N100)))
chk(abs(one - N) < 1e-6, "one 10-year step and ten 1-year steps agree to 1e-6")
chk(abs(one - N100) < 1e-6, "one 10-year step and one hundred sub-steps agree to 1e-6")
chk(koa_regular_survival(1500, 12, 12, beta = b117, base_nat = NA, base_plt = NA)$deaths == 0,
    "no regular mortality when H40 is flat (fitted arm, floor off)")
chk(koa_regular_survival(1500, 12, 9, beta = b117, base_nat = NA, base_plt = NA)$deaths == 0,
    "no regular mortality when H40 falls (fitted arm, floor off)")

# The limiting line is approached from below and never crossed
Nlim <- 10000 / (b117 * 15)^2
st <- koa_regular_survival(0.999 * Nlim, 15, 22, beta = b117, base_nat = NA, base_plt = NA)
cat(sprintf("   stand started at 99.9%% of the line at H40 15 m: N1 = %.1f, line at H40 22 m = %.1f\n",
            st$N1, st$N_limit))
chk(st$N1 <= st$N_limit, "a stand on the line stays beneath it")

## ---- 1b. The ported anchored arm: floor and cycle invariance ---------------
# Same structural properties, now on the arm HiGy.R actually ships as of
# 0.4.0: default beta (KOA_GARCIA_BETA_ANCHORED) and default floor on. The
# height values below are treated as H_QMD (koa_regular_survival() does not
# care which height variable it is handed, only calc_mortality() decides
# that by what it passes in); a flat H_QMD now returns the A1 floor rather
# than zero, and cycle invariance still holds because it is a property of
# the Garcia recursion, not of beta or the floor.
cat("\n1b. Cycle-length invariance and the A1 floor (ported H_QMD arm)\n")
one_a <- koa_regular_survival(1500, 10, 20)$N1
Na <- 1500; ha <- seq(10, 20, length.out = 11)
for (i in 2:11) Na <- koa_regular_survival(Na, ha[i - 1], ha[i])$N1
cat(sprintf("   one 10-year step: %.10f, ten 1-year sub-steps: %.10f (diff %.3e)\n", one_a, Na, abs(one_a - Na)))
chk(abs(one_a - Na) < 1e-6, "cycle-length invariance holds on the anchored arm too")
flat_nat <- koa_regular_survival(1500, 12, 12, origin = "Natural")
flat_plt <- koa_regular_survival(1500, 12, 12, origin = "Planted")
cat(sprintf("   flat H_QMD, natural: m_step = %.6f (floor %.3f), planted: m_step = %.6f (floor %.3f)\n",
            flat_nat$m_step, KOA_BASE_NAT, flat_plt$m_step, KOA_BASE_PLT))
chk(abs(flat_nat$m_step - KOA_BASE_NAT) < 1e-12, "flat H_QMD returns the natural A1 floor, not zero")
chk(abs(flat_plt$m_step - KOA_BASE_PLT) < 1e-12, "flat H_QMD returns the planted A1 floor, not zero")
grown <- koa_regular_survival(1500, 10, 20, origin = "Natural")
cat(sprintf("   growing H_QMD 10 to 20 m: m_step = %.6f (raw Garcia step, above the %.3f floor)\n",
            grown$m_step, KOA_BASE_NAT))
chk(grown$m_step > KOA_BASE_NAT, "a growing stand's raw Garcia step exceeds the floor and is not clamped to it")
chk(abs(koa_regular_survival(1500, 10, 20, base_nat = NA, base_plt = NA)$deaths -
        koa_regular_survival(1500, 10, 20, beta = b117, base_nat = NA, base_plt = NA)$deaths) > 1e-6,
    "the anchored beta and the fitted beta give different deaths on the same height path, as expected")

## ---- 2. Renormalization contract, AT-3, AT-4 and AT-6 ----------------------
cat("\n2. Allocation and the renormalization contract\n")
tl <- data.frame(dbh = c(5, 12, 20, 35, 60), expf = c(300, 150, 80, 40, 15), ht = c(5, 11, 16, 22, 27))
al <- koa_allocate_mortality(tl, deaths_ha = 30)
cat(sprintf("   five-tree list, 30 deaths ha-1: mort_frac = %s\n", paste(sprintf("%.6f", al$mort_frac), collapse = ", ")))
cat(sprintf("   sum(dexpf) = %.12f (target 30), expf-weighted mean = %.12f (target %.12f)\n",
            sum(al$dexpf), sum(al$mort_frac * al$expf) / sum(al$expf), 30 / sum(al$expf)))
chk(abs(sum(al$dexpf) - 30) < 1e-9, "allocated deaths equal the stand deaths")
chk(all(diff(al$mort_frac) <= 0), "mortality fraction decreases with diameter")

cat("\n   AT-3, cap binding, stand rate 0.93 on the same five trees\n")
at3 <- koa_allocate_mortality(tl, deaths_ha = 0.93 * sum(tl$expf))
cat(sprintf("   mort_frac = %s\n", paste(sprintf("%.14f", at3$mort_frac), collapse = ", ")))
cat(sprintf("   expf-weighted mean = %.14f (target 0.93), max = %.14f\n",
            sum(at3$mort_frac * at3$expf) / sum(at3$expf), max(at3$mort_frac)))
chk(abs(sum(at3$mort_frac * at3$expf) / sum(at3$expf) - 0.93) < 1e-9, "AT-3 weighted mean restored to 0.93")
chk(max(at3$mort_frac) <= KOA_ALLOC_CAP + 1e-15, "AT-3 no tree above the 0.95 cap")
chk(sum(at3$mort_frac >= KOA_ALLOC_CAP - 1e-12) == 4, "AT-3 four trees sit at the cap")

cat("\n   AT-4, infeasible stand rate at or above the cap\n")
w4 <- NULL
at4 <- withCallingHandlers(koa_allocate_mortality(tl, deaths_ha = 0.97 * sum(tl$expf)),
                           warning = function(w) { w4 <<- conditionMessage(w); invokeRestart("muffleWarning") })
cat(sprintf("   warning: %s\n", if (is.null(w4)) "NONE" else w4))
cat(sprintf("   mort_frac = %s\n", paste(sprintf("%.4f", at4$mort_frac), collapse = ", ")))
chk(!is.null(w4) && grepl("cap", w4), "AT-4 issues the infeasibility warning naming the cap")
chk(all(abs(at4$mort_frac - KOA_ALLOC_CAP) < 1e-15), "AT-4 returns every tree at exactly the cap")

cat("\n   AT-6, single tree receives exactly the stand rate\n")
at6 <- koa_allocate_mortality(data.frame(dbh = 20, expf = 100), deaths_ha = 5)
cat(sprintf("   mort_frac = %.17f (target 0.05)\n", at6$mort_frac))
chk(abs(at6$mort_frac - 0.05) < 1e-15, "AT-6 single tree receives the stand rate to machine precision")

cat("\n   AT-1, AT-2 and AT-5 are RETIRED. They describe the withdrawn Eq. 5b ramp and its\n")
cat("   Eq. 5 cloglog ordering weight, neither of which exists in this file. Their standing\n")
cat("   replacement is the ramp-absence check in section 0 above.\n")

## ---- 3. The embedded magnitude vector against the source table -------------
cat("\n3. Embedded irregular magnitude vector against plot_interval_pairs_DATA.csv\n")
if (file.exists(csvpath)) {
  p <- read.csv(csvpath, stringsAsFactors = FALSE)
  fr <- sort(round(p$ndead[p$irreg] / p$ntree[p$irreg], 4))
  emb <- sort(KOA_IRREG_LOSS)
  cat(sprintf("   csv: %d plot intervals, %d plots, %d cohort deaths, %d irregular intervals carrying %d deaths (%.1f%%)\n",
              nrow(p), length(unique(p$key)), sum(p$ndead), sum(p$irreg),
              sum(p$ndead[p$irreg]), 100 * sum(p$ndead[p$irreg]) / sum(p$ndead)))
  cat(sprintf("   csv fractions n = %d, embedded n = %d, max abs elementwise difference = %.10f\n",
              length(fr), length(emb), if (length(fr) == length(emb)) max(abs(fr - emb)) else NA))
  cat(sprintf("   csv median %.4f IQR %.4f to %.4f; embedded median %.4f IQR %.4f to %.4f\n",
              median(fr), quantile(fr, .25), quantile(fr, .75),
              median(emb), quantile(emb, .25), quantile(emb, .75)))
  chk(length(fr) == length(emb) && max(abs(fr - emb)) < 1e-9,
      "embedded magnitude vector matches the source table element for element")
  cat(sprintf("   observed occurrence rate %.4f per interval at mean interval %.4f yr; embedded %.2f and %.2f\n",
              mean(p$irreg), mean(p$YIP), KOA_IRREG_RATE, KOA_IRREG_INTERVAL))
  chk(abs(mean(p$irreg) - KOA_IRREG_RATE) < 0.01, "embedded occurrence rate matches the source table")
  chk(abs(mean(p$YIP) - KOA_IRREG_INTERVAL) < 0.01, "embedded reference interval matches the source table")

  # Pinned to the fitted H40 arm explicitly: this table's H40_0/H40_1 columns
  # are H40, not H_QMD, and koa_regular_survival()'s own default changed to
  # the anchored H_QMD arm 9 September 2026. Using the new default here would
  # repeat exactly the frame mismatch the 9 September changelog withdrew.
  reg <- p[!p$irreg & !is.na(p$H40_0) & !is.na(p$H40_1) & p$H40_0 > 0 & p$H40_1 > 0 & !is.na(p$SDI0), ]
  pr <- mapply(function(N0, H0, H1) koa_regular_survival(N0, H0, H1, beta = KOA_GARCIA_BETA,
                                                          base_nat = NA, base_plt = NA)$N1,
               reg$N0, reg$H40_0, reg$H40_1)
  cat(sprintf("   in-sample regular set (%d intervals, %d plots): predicted deaths %.0f against observed %.0f (%+.1f%%), RMSE N1 %.1f trees ha-1\n",
              nrow(reg), length(unique(reg$key)), sum(reg$N0 - pr), sum(reg$N0 - reg$N1),
              100 * (sum(reg$N0 - pr) / sum(reg$N0 - reg$N1) - 1), sqrt(mean((pr - reg$N1)^2))))
  chk(abs(100 * (sum(reg$N0 - pr) / sum(reg$N0 - reg$N1) - 1)) < 10, "in-sample deaths bias within 10 percent")
  beneath <- mean(100 / sqrt(reg$N0) >= KOA_GARCIA_BETA * reg$H40_0)
  cat(sprintf("   share of regular (N, H40) pairs beneath the limiting line: %.4f\n", beneath))
  chk(beneath >= 0.99, "at least 99 percent of regular pairs lie beneath the limiting line")

  # Beta sensitivity, kept for continuity with 8 September 2026 and NOT a
  # pass/fail check. This substitutes the anchored beta into the H40
  # parameterization, which the 9 September 2026 changelog correction
  # identifies as a frame mismatch: it measures what happens when a constant
  # calibrated on H_QMD is run on H40, not the anchored arm itself (which
  # predicts 35.1 percent above observed on the correct H_QMD frame, per the
  # changelog and the parity report). Reported here unchanged, for history.
  BETA_ANCHORED <- KOA_GARCIA_BETA_ANCHORED
  pa <- mapply(function(N0, H0, H1) koa_regular_survival(N0, H0, H1, beta = BETA_ANCHORED,
                                                          base_nat = NA, base_plt = NA)$N1,
               reg$N0, reg$H40_0, reg$H40_1)
  cat(sprintf("\n   BETA SENSITIVITY ON H40 (frame mismatch, reported not asserted). Fitted beta %.6f predicts %.0f regular deaths;\n",
              KOA_GARCIA_BETA, sum(reg$N0 - pr)))
  cat(sprintf("   the anchored beta %.17f run on H40 (NOT its own frame) predicts %.0f, a ratio of %.3f.\n",
              BETA_ANCHORED, sum(reg$N0 - pa), sum(reg$N0 - pa) / sum(reg$N0 - pr)))
  cat(sprintf("   Observed deaths on those intervals are %.0f. See HiGy_v040_parity_report_2026-09-09.md\n",
              sum(reg$N0 - reg$N1)))
  cat("   for the anchored arm evaluated correctly, on H_QMD, against the Python deposit source.\n")
} else {
  cat("   plot_interval_pairs_DATA.csv not found; the table-based checks are SKIPPED\n")
  ok_all <- FALSE
}

## ---- 4. Stage 1 occurrence -------------------------------------------------
cat("\n4. Stage 1 irregular occurrence (stochastic, off in production)\n")
set.seed(20260908)
ev <- replicate(20000, koa_irregular_event(yip = KOA_IRREG_INTERVAL)$event)
cat(sprintf("   20,000 draws at yip = %.2f: occurrence %.4f (target %.2f)\n", KOA_IRREG_INTERVAL, mean(ev), KOA_IRREG_RATE))
chk(abs(mean(ev) - KOA_IRREG_RATE) < 0.01, "annualized hazard reproduces the observed occurrence rate")
chk(koa_irregular_event(yip = 5, seed = 1)$p_step > koa_irregular_event(yip = 1, seed = 1)$p_step,
    "a longer step carries a higher event probability")

## ---- 5. End to end through calc_mortality() inside the production file -----
cat("\n5. End to end through calc_mortality()\n")
stand <- data.frame(stand.id = "TEST", elev = 500, byi = 264, planted = 0)
tree.data <- data.frame(
  plot = c(1,1,1,1,1, 2,2,2),
  tree = 1:8,
  sp   = "AK",
  dbh  = c(5, 12, 20, 35, 60, 10, 22, 40),
  ht   = c(5, 11, 16, 22, 27, 9, 17, 24),
  cr   = c(.5,.5,.55,.6,.65,.5,.55,.6),
  expf = c(300, 150, 80, 40, 15, 200, 90, 30),
  ddbh = c(.30,.35,.30,.20,.10, 0, 0, 0),   # plot 2 takes no increment
  dht  = c(.25,.30,.28,.20,.12, 0, 0, 0),
  mort.mult = 1,
  stringsAsFactors = FALSE)
tree.data$ba <- (tree.data$dbh^2 * 0.00007854) * tree.data$expf
plot.data <- data.frame(plot = c(1, 2),
                        ba.plot = tapply(tree.data$ba, tree.data$plot, sum),
                        htmax = tapply(tree.data$ht, tree.data$plot, max))
out <- calc_mortality(tree.data, plot.data)
cat("   returned columns: ", paste(names(out), collapse = ", "), "\n")
chk(identical(names(out), c(names(tree.data), "dexpf")), "returned frame is the input columns plus dexpf and nothing else")

for (pl in 1:2) {
  s <- tree.data[tree.data$plot == pl, ]
  # Mirrors calc_mortality()'s garcia branch exactly: production drives the
  # step on H_QMD (via koa_h_qmd()), ported 9 September 2026, not H40.
  n0  <- sum(s$expf)
  qmd0 <- sqrt(sum(s$expf * s$dbh^2) / n0)
  qmd1 <- sqrt(sum(s$expf * (s$dbh + s$ddbh)^2) / n0)
  hq0 <- koa_h_qmd(qmd0); hq1 <- koa_h_qmd(qmd1)
  d  <- koa_step_deaths(n0, hq0, hq1, planted = 0, yip = 1)
  got <- sum(out$dexpf[out$plot == pl])
  cat(sprintf("   plot %d: N0 %.2f, H_QMD %.6f to %.6f m, stand deaths %.10f, allocated %.10f\n",
              pl, n0, hq0, hq1, d, got))
  chk(abs(got - d) < 1e-9, sprintf("plot %d allocated deaths equal the stand deaths", pl))
}
chk(sum(out$dexpf[out$plot == 2]) > 0, "a plot with no height growth still takes the A1 floor (ported arm), not zero")

cat("\n   Confirms the port actually changed production behaviour\n")
s1 <- tree.data[tree.data$plot == 1, ]
h0_old <- koa_h40(s1$dbh, s1$ht, s1$expf); h1_old <- koa_h40(s1$dbh + s1$ddbh, s1$ht + s1$dht, s1$expf)
d_old  <- koa_step_deaths(sum(s1$expf), h0_old, h1_old, planted = 0, yip = 1)
d_new  <- sum(out$dexpf[out$plot == 1])
cat(sprintf("   plot 1: old fitted-H40 arm (as koa_step_deaths defaulted before this port) would give %.10f;\n", d_old))
cat(sprintf("   ported production calc_mortality() gives %.10f (uses the current default beta/state/floor).\n", d_new))
chk(abs(d_old - d_new) > 1e-9, "production calc_mortality() output differs from the pre-port fitted-H40 arm")

cat("\n   Engine switch\n")
out_cl <- calc_mortality(tree.data, plot.data, mort.engine = "cloglog")
cat(sprintf("   garcia total dexpf %.6f, cloglog total dexpf %.6f\n", sum(out$dexpf), sum(out_cl$dexpf)))
chk(abs(sum(out$dexpf) - sum(out_cl$dexpf)) > 1e-9, "mort.engine = 'cloglog' reaches the retired path and returns a different answer")
chk(identical(names(out_cl), c(names(tree.data), "dexpf")), "the retired path returns the same column contract")

cat("\n   mort.mult passthrough\n")
td2 <- tree.data; td2$mort.mult <- 0.5
out_h <- calc_mortality(td2, plot.data)
cat(sprintf("   mort.mult 1.0 total %.10f, mort.mult 0.5 total %.10f, ratio %.10f\n",
            sum(out$dexpf), sum(out_h$dexpf), sum(out_h$dexpf) / sum(out$dexpf)))
chk(abs(sum(out_h$dexpf) / sum(out$dexpf) - 0.5) < 1e-12, "the FVS mortality multiplier scales allocated mortality exactly")

cat("\n   Missing-increment guard\n")
td3 <- tree.data[, setdiff(names(tree.data), c("ddbh", "dht"))]
w3 <- NULL
out_ng <- withCallingHandlers(calc_mortality(td3, plot.data),
                              warning = function(w) { w3 <<- conditionMessage(w); invokeRestart("muffleWarning") })
cat(sprintf("   warning raised: %s\n", if (is.null(w3)) "NONE" else substr(w3, 1, 90)))
chk(!is.null(w3), "a tree list without ddbh or dht raises the ordering warning")
# Changed 9 September 2026 by the port. A missing ddbh/dht leaves QMD (and so
# H_QMD) unchanged over the step, which is the same "flat" case section 1b
# tests directly: the deposit's own stand_mortality() returns the A1 floor
# whenever h_prev is None or the step shows no growth (garcia_step's grow
# mask forces N1 = N0, and mort_garcia still floors that at the background
# rate). So the ported arm returning the floor here, not zero, matches the
# deployed source; the old zero-mortality expectation was specific to the
# 8 September 2026 unfloored fitted arm and is superseded.
expect_floor <- sum(td3$expf[td3$dbh > 0]) * KOA_BASE_NAT
cat(sprintf("   allocated %.10f, expected A1 floor %.10f (%.3f x natural background)\n",
            sum(out_ng$dexpf), expect_floor, KOA_BASE_NAT))
chk(abs(sum(out_ng$dexpf) - expect_floor) < 1e-6,
    "a tree list with no growth data takes the A1 floor (ported arm), matching the deposit, not zero")

cat("\n   Step-length behaviour carried through the allocator\n")
big <- koa_mortality_step(tl, H40_1 = 30, origin = "Natural", yip = 10)
stp <- tl; tot <- 0; hs <- seq(koa_h40(tl$dbh, tl$ht, tl$expf), 30, length.out = 11)
for (i in 2:11) { r <- koa_mortality_step(stp, H40_0 = hs[i - 1], H40_1 = hs[i], yip = 1)
                  tot <- tot + sum(r$tree$dexpf); stp$expf <- stp$expf - r$tree$dexpf }
cat(sprintf("   one 10-year step total deaths %.10f, ten 1-year steps total %.10f, diff %.3e\n",
            big$stand$deaths_total, tot, abs(big$stand$deaths_total - tot)))
cat("   The stand totals agree; the per-tree split does not, and that is expected rather than a defect,\n")
cat("   since Stage 3 re-reads the diameter distribution at every step and a ten-step run reallocates\n")
cat("   ten times against a shrinking small-tree tail.\n")
chk(abs(big$stand$deaths_total - tot) < 1e-6, "stand deaths are invariant to step length through the allocator")

cat(sprintf("\nself-test %s\n", if (ok_all) "PASSED" else "FAILED"))
if (!ok_all) quit(status = 1)
