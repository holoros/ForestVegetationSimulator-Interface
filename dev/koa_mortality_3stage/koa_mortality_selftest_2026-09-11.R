#!/usr/bin/env Rscript
# =============================================================================
# koa_mortality_selftest_2026-09-11.R
#
# Self-test for the three-stage Acacia koa A.Gray mortality component as it is
# DEPLOYED IN THE PRODUCTION HiGy.R of the FvsHiHistory branch, version 0.5.0,
# ported 11 September 2026 onto the engine of record selected by
# MORTALITY_RULE_2026-09-12.md AMENDMENT 1 (candidate M1): the Stage 1
# occurrence gate on the stand rate, and the fitted tree-level survivor
# equation as the Stage 3 ordering. Built from the 9 September 2026 self-test
# with every check carried forward.
#
# The 0.4.0 layers are unchanged and still tested here: the anchored beta
# 0.16019053617304435, the H_QMD allometry and the A1 floor. Section 1 and the
# section-3 in-sample check still exercise the fitted-H40 arm on purpose
# (KOA_GARCIA_BETA, floor off), since that is the arm the underlying H40 plot
# data and the original 8 September 2026 numbers were built on;
# koa_mortality_step() still reproduces that arm exactly by explicit default,
# and as of 0.5.0 it also stays UNGATED and on the relative-size Stage 3 weight
# by explicit default (see HiGy.R 0.5.0 header).
#
# NEW IN THIS VERSION. Section 6 exercises the Stage 1 gate at low, middle and
# high stand density index and at both origins, including the direction of the
# gate either side of p_bar, the A1 floor being scaled by it, the ungated
# pass-through when SDI is missing, and the 0.95 clip. Section 7 exercises the
# two Stage 3 weights on the same tree list and asserts what must be true of
# both: identical stand totals, a different within-stand split, and no
# sensitivity to the LEVEL of the survivor equation. Cross-language validation
# against the deployed Python source is reported separately in
# HiGy_v050_parity_report_2026-09-11.md, since this file has no Python of its
# own to compare against.
#
# The test sources the production file and exercises the functions that file
# actually defines, so it cannot pass against a copy of the component that has
# drifted from what ships. It never redefines a constant, an equation or a
# guard, and every number it asserts comes from HiGy.R or from
# plot_interval_pairs_DATA.csv.
#
# Run:  Rscript koa_mortality_selftest_2026-09-11.R [HiGy.R] [plot_interval_pairs_DATA.csv]
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
chk(VersionTag == "HiGyV0.5.0", "VersionTag is HiGyV0.5.0")

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
             "KOA_BASE_NAT", "KOA_BASE_PLT",
             "KOA_S1_INTERCEPT", "KOA_S1_LNSDI", "KOA_S1_PLANTED", "KOA_S1_PBAR",
             "KOA_S1_SDI_FLOOR", "KOA_S1_ETA_CLIP", "KOA_RATE_CAP",
             "KOA_S3_SURV", "KOA_S3_W_FLOOR", "KOA_ALLOC_MODE"))
  chk(exists(nm), sprintf("%s is defined in the production file", nm))
chk(exists("koa_h_qmd"), "koa_h_qmd() is defined in the production file")
for (fn in c("koa_stage1_p", "koa_gate_rate", "koa_surv_annual"))
  chk(exists(fn) && is.function(get(fn)),
      sprintf("%s() is defined in the production file", fn))

# Stage 1 gate constants, asserted at the full precision they were transcribed
# at from the fit's own stage1_fit.json. A rounded constant here is a silent
# divergence from the deployed engine and must fail.
chk(identical(KOA_S1_INTERCEPT, -1.8660048476490962),  "Stage 1 intercept is exact to the fitted double")
chk(identical(KOA_S1_LNSDI,      0.18970168229495396), "Stage 1 ln(SDI) coefficient is exact to the fitted double")
chk(identical(KOA_S1_PLANTED,    0.1833723331227772),  "Stage 1 planted offset is exact to the fitted double")
chk(identical(KOA_S1_PBAR,       0.3600578102962374),  "Stage 1 mean annual occurrence p_bar is exact to the fitted double")
chk(KOA_S1_SDI_FLOOR == 1 && identical(KOA_S1_ETA_CLIP, c(-30, 5)),
    "Stage 1 guards match the deployed source (SDI floor 1, eta clip -30 to 5)")
chk(KOA_RATE_CAP == 0.95, "the gated stand rate is capped at 0.95, as deployed")
chk(KOA_S1_LNSDI > 0, "the ln(SDI) coefficient on occurrence is POSITIVE, the sign the rule rests on")

# Stage 3 survivor weight vector, manuscript Table 6.
chk(identical(unname(KOA_S3_SURV),
              c(14.102, 0.130, -4.516, 6.684, 14.218, -2.806, 2.649, -21.188)),
    "Stage 3 survivor vector is manuscript Table 6, element for element")
chk(identical(names(KOA_S3_SURV), paste0("b", 0:7)), "Stage 3 survivor vector is named b0 to b7")
chk(KOA_ALLOC_MODE == "tree_eq", "the Stage 3 production default is the fitted survivor weight")

# The Stage 3 weight must NOT have been wired into the retired cloglog path,
# and surv.parm must still carry its own (different) lineage untouched.
chk(identical(surv.parm$b0, c(18.133, 18.133)),
    "surv.parm is untouched and still carries the development-snapshot vector")
chk(!any(grepl("KOA_S3_SURV", sub("#.*$", "", src)[grep("surv_prob", src)])),
    "surv_prob() does not reference the Stage 3 survivor vector")
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

cat("\n   The 0.4.0 default is pinned: koa_allocate_mortality() is still relative size\n")
tl_w <- data.frame(dbh = tl$dbh, expf = tl$expf, ht = tl$ht,
                   cr = c(.45, .48, .52, .55, .60), byi = 264)
al_rs <- koa_allocate_mortality(tl_w, deaths_ha = 30)
al_ex <- koa_allocate_mortality(tl_w, deaths_ha = 30, mode = "rel_size")
chk(identical(al_rs$mort_frac, al_ex$mort_frac),
    "koa_allocate_mortality() still defaults to the as-published relative-size weight")
chk(max(abs(al_rs$w_alloc - exp(-KOA_ALLOC_B * (al_rs$rdbh - 1)))) < 1e-15,
    "its reported w_alloc is the as-published size weight")
al_te <- koa_allocate_mortality(tl_w, deaths_ha = 30, mode = "tree_eq")
chk(abs(sum(al_te$dexpf) - 30) < 1e-9, "mode = 'tree_eq' still delivers the stand deaths exactly")
chk(max(abs(al_te$mort_frac - al_rs$mort_frac)) > 1e-9,
    "mode = 'tree_eq' splits the same stand differently from the as-published weight")
e_miss <- tryCatch({ koa_allocate_mortality(tl, deaths_ha = 30, mode = "tree_eq"); NULL },
                   error = function(e) conditionMessage(e))
chk(!is.null(e_miss) && grepl("cr", e_miss),
    "mode = 'tree_eq' without the columns it needs fails loudly rather than falling back")

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
  # SDI is now part of the mirror. calc_mortality() passes sdi.koa into
  # koa_step_deaths(), which gates on it, so a mirror that omitted it would
  # compare a gated production number against an ungated hand calculation and
  # would have to fail. Added 11 September 2026 with the gate.
  sd0 <- koa_sdi(n0, qmd0)
  d  <- koa_step_deaths(n0, hq0, hq1, planted = 0, yip = 1, sdi = sd0)
  got <- sum(out$dexpf[out$plot == pl])
  d_ung <- koa_step_deaths(n0, hq0, hq1, planted = 0, yip = 1, sdi = sd0, gate = FALSE)
  cat(sprintf("   plot %d: N0 %.2f, SDI %.2f, H_QMD %.6f to %.6f m, gated stand deaths %.10f, allocated %.10f\n",
              pl, n0, sd0, hq0, hq1, d, got))
  cat(sprintf("           ungated stand deaths %.10f, gate factor %.10f (p/p_bar)\n",
              d_ung, d / d_ung))
  chk(abs(got - d) < 1e-9, sprintf("plot %d allocated deaths equal the GATED stand deaths", pl))
  chk(abs(d / d_ung - koa_stage1_p(sd0, 0) / KOA_S1_PBAR) < 1e-12,
      sprintf("plot %d gate factor is exactly p(SDI, origin) / p_bar", pl))
  chk(abs(d_ung - koa_step_deaths(n0, hq0, hq1, planted = 0, yip = 1)) < 1e-12,
      sprintf("plot %d gate is inert when no SDI is supplied", pl))
}
chk(sum(out$dexpf[out$plot == 2]) > 0, "a plot with no height growth still takes the gated A1 floor, not zero")

cat("\n   The production default is the gated, fitted-survivor-weight engine\n")
out_ung <- calc_mortality(tree.data, plot.data, gate = FALSE)
out_rs  <- calc_mortality(tree.data, plot.data, alloc.mode = "rel_size")
cat(sprintf("   total dexpf: production %.10f, gate off %.10f, relative-size Stage 3 %.10f\n",
            sum(out$dexpf), sum(out_ung$dexpf), sum(out_rs$dexpf)))
chk(abs(sum(out$dexpf) - sum(out_ung$dexpf)) > 1e-9,
    "calc_mortality(gate = TRUE) is the default and differs from gate = FALSE")
chk(abs(sum(out$dexpf) - sum(out_rs$dexpf)) < 1e-9,
    "the Stage 3 weight moves no stand total, only the within-stand split")
chk(max(abs(out$dexpf - out_rs$dexpf)) > 1e-9,
    "the Stage 3 weight does move the within-stand split")
chk(identical(names(out_rs), c(names(tree.data), "dexpf")),
    "alloc.mode = 'rel_size' returns the same column contract")
e_mode <- tryCatch({ calc_mortality(tree.data, plot.data, alloc.mode = "size"); NULL },
                   error = function(e) conditionMessage(e))
chk(!is.null(e_mode), "an unknown alloc.mode fails loudly")

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
# Changed again 11 September 2026 by the gate. The floor is still reached, and
# it is then SCALED by p(SDI, origin) / p_bar like any other rate, because the
# deployed engine gates after the floor. The expectation is therefore per plot,
# since each plot carries its own SDI.
expect_floor <- 0
for (pl in 1:2) {
  s   <- td3[td3$plot == pl & td3$dbh > 0, ]
  n0p <- sum(s$expf)
  sdp <- koa_sdi(n0p, sqrt(sum(s$expf * s$dbh^2) / n0p))
  expect_floor <- expect_floor + n0p * koa_gate_rate(KOA_BASE_NAT, sdp, 0)
}
expect_unfloored <- sum(td3$expf[td3$dbh > 0]) * KOA_BASE_NAT
cat(sprintf("   allocated %.10f, expected GATED A1 floor %.10f (ungated floor would be %.10f)\n",
            sum(out_ng$dexpf), expect_floor, expect_unfloored))
chk(abs(sum(out_ng$dexpf) - expect_floor) < 1e-6,
    "a tree list with no growth data takes the GATED A1 floor, matching the deployed engine, not zero")
chk(abs(expect_floor - expect_unfloored) > 1e-9,
    "the gate does scale the A1 floor, which is the deployed behaviour and not an oversight")

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

## ---- 6. The Stage 1 gate ---------------------------------------------------
# New 11 September 2026. The gate is the engine of record and this section is
# what pins it. Every number below comes out of HiGy.R; none is written here.
cat("\n6. Stage 1 occurrence gate (deterministic, ON in production)\n")

SDI_GRID <- c(50, 100, 200, 376.8, 400, 800, 1200, 1725)
cat(sprintf("   %8s %10s %10s %10s %10s\n", "SDI", "p nat", "p plt", "gate nat", "gate plt"))
for (s in SDI_GRID)
  cat(sprintf("   %8.1f %10.6f %10.6f %10.6f %10.6f\n", s,
              koa_stage1_p(s, 0), koa_stage1_p(s, 1),
              koa_stage1_p(s, 0) / KOA_S1_PBAR, koa_stage1_p(s, 1) / KOA_S1_PBAR))

# 6a. The probability itself.
p_nat <- koa_stage1_p(SDI_GRID, 0); p_plt <- koa_stage1_p(SDI_GRID, 1)
chk(all(p_nat > 0 & p_nat < 1) && all(p_plt > 0 & p_plt < 1),
    "occurrence probability is strictly inside 0 and 1 across the SDI grid")
chk(all(diff(p_nat) > 0) && all(diff(p_plt) > 0),
    "occurrence probability increases monotonically with SDI, both origins")
chk(all(p_plt > p_nat), "planted stands carry the higher occurrence probability at every SDI")
chk(abs(koa_stage1_p(1, 0) -
        (1 - exp(-exp(KOA_S1_INTERCEPT)))) < 1e-15,
    "at SDI 1 the linear predictor is the intercept alone, ln(SDI) and ln(YIP) both zero")
chk(abs(koa_stage1_p(0.001, 0) - koa_stage1_p(1, 0)) < 1e-15,
    "SDI below the floor of 1 is clamped rather than taking a negative logarithm")
chk(koa_stage1_p(400, 0, yip = 5) > koa_stage1_p(400, 0, yip = 1),
    "the ln(YIP) offset makes a longer interval more likely to carry mortality")
chk(abs(koa_stage1_p(400, 1) -
        (1 - exp(-exp(KOA_S1_INTERCEPT + KOA_S1_LNSDI * log(400) + KOA_S1_PLANTED)))) < 1e-15,
    "the planted probability is the cloglog of the fitted linear predictor, term for term")

# 6b. The gate itself, low, middle and high density, both origins.
M_REF <- 0.02
cat(sprintf("\n   a reference stand rate of %.3f yr-1 gated at each density\n", M_REF))
for (s in c(50, 200, 376.8, 800, 1725))
  cat(sprintf("   SDI %8.1f: natural %.10f, planted %.10f\n", s,
              koa_gate_rate(M_REF, s, 0), koa_gate_rate(M_REF, s, 1)))
g_nat <- koa_gate_rate(M_REF, SDI_GRID, 0)
chk(all(diff(g_nat) > 0), "the gated rate increases monotonically with SDI")
chk(koa_gate_rate(M_REF, 50, 0) < M_REF,
    "at LOW density the gate scales the rate DOWN, because p is below p_bar")
chk(koa_gate_rate(M_REF, 1725, 0) > M_REF,
    "at HIGH density the gate scales the rate UP, because p is above p_bar")
chk(koa_gate_rate(M_REF, 400, 1) > koa_gate_rate(M_REF, 400, 0),
    "at the same density the planted gate is the stronger of the two")
for (org in 0:1)
  chk(abs(koa_gate_rate(M_REF, 500, org) -
          M_REF / KOA_S1_PBAR * koa_stage1_p(500, org)) < 1e-15,
      sprintf("the gated rate is exactly m / p_bar * p, origin %d", org))

# The SDI at which the gate is exactly neutral, solved from the file's own
# constants and not asserted as a remembered number.
sdi_star <- exp((log(-log(1 - KOA_S1_PBAR)) - KOA_S1_INTERCEPT) / KOA_S1_LNSDI)
cat(sprintf("   the gate is neutral (p = p_bar) at SDI %.4f natural\n", sdi_star))
chk(abs(koa_gate_rate(M_REF, sdi_star, 0) - M_REF) < 1e-12,
    "at the SDI where p equals p_bar the gate returns the incumbent rate unchanged")
chk(abs(koa_stage1_p(sdi_star, 0) - KOA_S1_PBAR) < 1e-12,
    "and that SDI is where the fitted occurrence equals the mean fitted occurrence")

# 6c. Guards: the clip, the pass-through, zero in and zero out.
chk(koa_gate_rate(0.9, 1725, 1) == KOA_RATE_CAP,
    "the gated rate is clipped at 0.95 and does not run past it")
chk(koa_gate_rate(0, 1725, 0) == 0, "a zero stand rate gates to zero")
chk(identical(koa_gate_rate(M_REF, NA, 0), M_REF),
    "a missing SDI passes the rate through UNGATED, matching the deployed wrapper")
chk(identical(koa_gate_rate(M_REF, NaN, 0), M_REF), "so does a NaN SDI")
chk(identical(koa_gate_rate(M_REF, Inf, 0), M_REF), "so does a non-finite SDI")

# 6d. The A1 floor is scaled by the gate rather than held.
f_lo <- koa_gate_rate(KOA_BASE_NAT, 50, 0); f_hi <- koa_gate_rate(KOA_BASE_NAT, 1725, 0)
cat(sprintf("   natural A1 floor %.6f gates to %.10f at SDI 50 and %.10f at SDI 1725\n",
            KOA_BASE_NAT, f_lo, f_hi))
chk(f_lo < KOA_BASE_NAT && f_hi > KOA_BASE_NAT,
    "the gate scales the A1 floor in both directions, which is the deployed behaviour")

# 6e. The gate is a PURE MULTIPLICATIVE FACTOR in the stand rate. This is the
# property the candidate rests on: the gate redistributes the rate across
# density and does not re-level it, so the same factor applies to whatever the
# Garcia step and the A1 floor produced. If this ever stopped holding the
# expectation-preservation argument would stop holding with it.
for (s in c(50, 266.3027, 800, 1725)) {
  fac <- koa_stage1_p(s, 0) / KOA_S1_PBAR
  r <- sapply(c(0.001, 0.003, 0.02, 0.2, 0.5), function(m) koa_gate_rate(m, s, 0) / m)
  chk(max(abs(r - fac)) < 1e-12,
      sprintf("at SDI %.1f the gate is one factor %.6f applied to every sub-cap rate", s, fac))
}
chk(koa_gate_rate(KOA_BASE_NAT, 800, 0) / KOA_BASE_NAT -
    koa_gate_rate(0.2, 800, 0) / 0.2 < 1e-12,
    "the A1 floor and a large Garcia step take the identical gate factor")

## ---- 7. The two Stage 3 weights on one tree list ---------------------------
# New 11 September 2026. What must hold of BOTH weights, and what separates them.
cat("\n7. Stage 3, the fitted survivor weight against the as-published size weight\n")
t7 <- data.frame(dbh  = c(5, 12, 20, 35, 60),
                 ht   = c(5, 11, 16, 22, 27),
                 cr   = c(.45, .50, .55, .60, .65),
                 expf = c(300, 150, 80, 40, 15),
                 byi  = 264)
t7$rht <- t7$ht / max(t7$ht)
N7 <- sum(t7$expf); D7 <- 0.06 * N7

f_te <- koa_alloc_frac(t7$dbh, t7$expf, D7, mode = "tree_eq",
                       ht = t7$ht, cr = t7$cr, rht = t7$rht, byi = t7$byi)
f_rs <- koa_alloc_frac(t7$dbh, t7$expf, D7, mode = "rel_size")
w_te <- pmin(pmax(1 - koa_surv_annual(t7$dbh, t7$ht, t7$cr, t7$rht, t7$byi),
                  KOA_S3_W_FLOOR), 1)
w_rs <- exp(-KOA_ALLOC_B * (t7$dbh / sqrt(sum(t7$expf * t7$dbh^2) / N7) - 1))
cat(sprintf("   %6s %8s %12s %12s %14s %14s\n", "dbh", "expf", "w tree_eq", "w rel_size",
            "mfrac tree_eq", "mfrac rel_size"))
for (i in seq_len(nrow(t7)))
  cat(sprintf("   %6.1f %8.1f %12.8f %12.8f %14.10f %14.10f\n",
              t7$dbh[i], t7$expf[i], w_te[i], w_rs[i], f_te[i], f_rs[i]))

# 7a. Both weights deliver the stand rate exactly. This is the contract.
for (nm in c("tree_eq", "rel_size")) {
  f <- if (nm == "tree_eq") f_te else f_rs
  chk(abs(sum(f * t7$expf) - D7) < 1e-9,
      sprintf("mode = '%s' allocates exactly the stand deaths", nm))
  chk(abs(sum(f * t7$expf) / N7 - D7 / N7) < 1e-12,
      sprintf("mode = '%s' delivers the stand rate as the weighted mean", nm))
  chk(all(f >= 0) && all(f <= KOA_ALLOC_CAP + 1e-15),
      sprintf("mode = '%s' respects the per-tree cap", nm))
}
chk(max(abs(f_te - f_rs)) > 1e-9, "the two weights give a genuinely different split")

# 7b. THE LEVEL OF THE SURVIVOR EQUATION DOES NOT ACT. This is the claim the
# port rests on and the one Ben asked about, so it is asserted and not stated.
# Multiplying the weight by any constant leaves every allocated fraction alone,
# because the constant cancels between w_i and wbar.
for (k in c(0.1, 0.5, 2, 37)) {
  w_scaled <- w_te * k
  wbar_s   <- sum(w_scaled * t7$expf) / N7
  f_scaled <- koa_renormalize_to_stand_rate((D7 / N7) * w_scaled / wbar_s,
                                            t7$expf, D7 / N7, cap = KOA_ALLOC_CAP)
  chk(max(abs(f_scaled - f_te)) < 1e-12,
      sprintf("scaling the survivor weight by %g changes no allocated fraction", k))
}

# 7c. The ordering the weight induces, and how flat it is. Both weights put more
# mortality on small trees; the fitted equation does so far less steeply, which
# is the substantive difference between the two and is reported, not asserted
# against a remembered number.
chk(all(diff(f_te) <= 0), "the fitted survivor weight still puts more mortality on small trees")
chk(all(diff(f_rs) <= 0), "so does the as-published size weight")
cat(sprintf("   spread across the tree list (max fraction / stand rate): tree_eq %.4f, rel_size %.4f\n",
            max(f_te) / (D7 / N7), max(f_rs) / (D7 / N7)))
chk(max(f_te) / (D7 / N7) < max(f_rs) / (D7 / N7),
    "the fitted survivor weight is FLATTER across the diameter distribution than the size weight")

# 7d. The survivor equation itself behaves.
s7 <- koa_surv_annual(t7$dbh, t7$ht, t7$cr, t7$rht, t7$byi)
chk(all(s7 > 0) && all(s7 < 1), "annual survival is strictly inside 0 and 1 on the test list")
chk(koa_surv_annual(20, 16, 0.55, 0.7, 264, yip = 5) >
    koa_surv_annual(20, 16, 0.55, 0.7, 264, yip = 1),
    "the ln(YIP) offset enters the survivor equation as an offset on the ALIVE response")
chk(abs(koa_surv_annual(20, 16, 0.99, 0.7, 264) -
        koa_surv_annual(20, 16, 1.50, 0.7, 264)) < 1e-15,
    "crown ratio is clipped at 0.99 exactly as the deployed source clips it")
chk(abs(koa_surv_annual(0.05, 16, 0.55, 0.7, 264) -
        koa_surv_annual(0.10, 16, 0.55, 0.7, 264)) < 1e-15,
    "diameter is floored at 0.1 cm exactly as the deployed source floors it")

# 7e. And it is NOT the retired path. surv_prob() must be unchanged and must
# still disagree with it, since the two lineages were never reconciled.
sp7 <- surv_prob(t7$dbh, t7$ht, t7$cr, t7$rht, t7$byi,
                 surv.parm$b0[2], surv.parm$b1[2], surv.parm$b2[2], surv.parm$b3[2],
                 surv.parm$b4[2], surv.parm$b5[2], surv.parm$b6[2], surv.parm$b7[2])
cat(sprintf("   koa_surv_annual mean %.8f, surv_prob mean %.8f on the same trees\n",
            mean(s7), mean(sp7)))
chk(max(abs(s7 - sp7)) > 1e-6,
    "koa_surv_annual() and surv_prob() are still two different lineages, as flagged in HiGy.R")

cat(sprintf("\nself-test %s\n", if (ok_all) "PASSED" else "FAILED"))
if (!ok_all) quit(status = 1)
