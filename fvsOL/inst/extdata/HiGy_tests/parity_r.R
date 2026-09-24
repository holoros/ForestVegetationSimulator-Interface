#!/usr/bin/env Rscript
# =============================================================================
# R side of the HiGy.R 0.4.0 fixture harness (18 cases). Adapted 23 September
# 2026 from the 11 September parity harness to add the origin mortality level
# factor KOA_MORT_CAL, applied as the engine of record applies it.
#
# Sources the ported HiGy.R UNMODIFIED and drives the same case list the Python
# side drives, from the same koa_parity_cases.json, through the functions
# HiGy.R actually ships:
#
#   koa_h_qmd()                 the H_QMD allometry
#   koa_regular_survival()      Stage 2, Garcia recursion with the A1 floor
#   koa_stage1_p()              Stage 1 occurrence probability
#   koa_gate_rate()             the deployed gate, m / p_bar * p
#   koa_step_deaths()           the production rate path, gate applied inside
#   koa_alloc_frac()            Stage 3, both weights
#
# It defines no coefficient and no equation of its own. Every number it reports
# comes out of HiGy.R.
#
# Writes out_r_stand.csv and out_r_tree.csv.
# =============================================================================
args  <- commandArgs(trailingOnly = TRUE)
higy  <- if (length(args) >= 1) args[1] else "../HiGy.R"
cases <- if (length(args) >= 2) args[2] else "koa_parity_cases.json"

suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(source(higy))

cat("R SIDE, ported production file\n")
cat("  file       :", normalizePath(higy), "\n")
cat("  VersionTag :", VersionTag, "\n")
cat("  R          :", R.version.string, "\n")
cat(sprintf("  beta %.17g  p_bar %.17g  cap %.17g  alloc_b %d\n",
            KOA_GARCIA_BETA_ANCHORED, KOA_S1_PBAR, KOA_ALLOC_CAP, KOA_ALLOC_B))

CFG <- fromJSON(cases, simplifyVector = TRUE)
BYI <- as.numeric(CFG$byi)

stand <- list(); tree <- list()

for (i in seq_len(nrow(CFG$cases))) {
  cc   <- CFG$cases[i, ]
  tl   <- CFG$treelists[[as.character(cc$treelist)]]
  dbh  <- as.numeric(tl$dbh);  ht   <- as.numeric(tl$ht)
  cr   <- as.numeric(tl$cr);   expf <- as.numeric(tl$expf)
  ddbh <- as.numeric(tl$ddbh)
  planted <- as.integer(cc$planted)
  mode    <- as.character(cc$alloc_mode)
  gate_on <- if ("gate" %in% names(cc) && !is.na(cc$gate)) as.logical(as.integer(cc$gate)) else TRUE

  N0   <- sum(expf)
  qmd0 <- sqrt(sum(expf * dbh^2) / N0)
  qmd1 <- sqrt(sum(expf * (dbh + ddbh)^2) / N0)
  sdi  <- if (identical(as.character(cc$sdi_mode), "none")) NA_real_ else koa_sdi(N0, qmd0)

  h0 <- koa_h_qmd(qmd0); h1 <- koa_h_qmd(qmd1)

  # Stage 2, post-A1-floor stand rate. Same quantity the deployed Python
  # stand_mortality() returns for engine 'garcia_qmd_anchored'.
  reg      <- koa_regular_survival(N0, h0, h1, origin = planted)
  m_garcia <- reg$m_step

  # Stage 1 gate.
  k <- koa_mort_cal(planted)
  if (isTRUE(gate_on) && is.finite(sdi)) {
    p1      <- koa_stage1_p(sdi, origin = planted, yip = 1)
    m_stand <- min(max(koa_gate_rate(m_garcia, sdi = sdi, origin = planted) * k, 0), KOA_RATE_CAP)
  } else if (isTRUE(gate_on)) {
    p1      <- NA_real_
    m_stand <- min(max(m_garcia * k, 0), KOA_RATE_CAP)
  } else {
    p1      <- NA_real_
    m_stand <- m_garcia
  }

  # The production rate path, which must agree with the two lines above.
  deaths_prod <- koa_step_deaths(N0, h0, h1, planted = planted, yip = 1,
                                 sdi = sdi, gate = gate_on)

  # Stage 3.
  rht  <- ht / max(max(ht), 0.1)
  ba_t <- dbh^2 * 0.00007854 * expf
  baph <- sum(ba_t)
  o    <- order(-dbh)
  bal  <- numeric(length(dbh)); bal[o] <- cumsum(ba_t[o]) - ba_t[o]
  if (mode == "tree_eq") {
    b <- KOA_S3_RESPEC
    w <- pmin(pmax(1 - exp(-exp(b[["b0"]] + b[["b1"]] * log(pmax(dbh, 0.1)) + b[["b2"]] * rht +
                                b[["b3"]] * log(baph + 1) + b[["b4"]] * log(pmax(bal, 0) + 1))),
                   KOA_S3_W_FLOOR), 1)
  } else {
    w <- exp(-KOA_ALLOC_B * (dbh / max(qmd0, 0.1) - 1))
  }
  wbar <- sum(w * expf) / N0

  warned <- 0L
  mfrac <- withCallingHandlers(
    koa_alloc_frac(dbh, expf, deaths_prod, mode = mode,
                   ht = ht, cr = cr, rht = rht, byi = BYI, ba = baph, bal = bal),
    warning = function(x) {
      if (grepl("cap", conditionMessage(x))) warned <<- 1L
      invokeRestart("muffleWarning")
    })
  deaths_i  <- expf * mfrac
  deaths_ha <- N0 * m_stand

  stopifnot(abs(deaths_prod - deaths_ha) < 1e-9 * max(1, N0))

  stand[[i]] <- data.frame(
    label = as.character(cc$label), treelist = as.character(cc$treelist),
    planted = planted, alloc_mode = mode, gate = as.integer(gate_on),
    n_tree = length(dbh), N0 = N0, QMD0 = qmd0, QMD1 = qmd1, SDI = sdi,
    BAPH = sum(dbh^2 * 0.00007854 * expf),
    H_QMD0 = h0, H_QMD1 = h1, m_garcia = m_garcia, p_stage1 = p1,
    m_stand = m_stand, deaths_ha = deaths_ha, deaths_alloc = sum(deaths_i),
    wbar = wbar, max_mort_frac = max(mfrac), cap_warn = warned,
    stringsAsFactors = FALSE)
  tree[[i]] <- data.frame(label = as.character(cc$label), tree = seq_along(dbh),
                          dbh = dbh, expf = expf, w = w, mort_frac = mfrac,
                          deaths = deaths_i, stringsAsFactors = FALSE)
}

S <- do.call(rbind, stand); T <- do.call(rbind, tree)

# Written with an explicit %.17g on every numeric column, not through format(),
# so the two sides are compared on full double precision and not on whatever
# common width format() happens to choose for a column.
write17 <- function(d, path) {
  out <- as.data.frame(lapply(d, function(x)
    if (is.numeric(x)) vapply(x, function(v) sprintf("%.17g", v), "") else as.character(x)),
    stringsAsFactors = FALSE)
  write.csv(out, path, row.names = FALSE, quote = FALSE)
}
write17(S, "out_r_stand.csv")
write17(T, "out_r_tree.csv")

cat(sprintf("\n%-22s %8s %10s %9s %16s %16s %10s\n",
            "label", "SDI", "m_garcia", "p1", "m_stand", "deaths_ha", "capwarn"))
for (i in seq_len(nrow(S)))
  cat(sprintf("%-22s %8.2f %10.6f %9.6f %16.12f %16.6f %10d\n",
              S$label[i], S$SDI[i], S$m_garcia[i], S$p_stage1[i],
              S$m_stand[i], S$deaths_ha[i], S$cap_warn[i]))
cat("\nwrote out_r_stand.csv and out_r_tree.csv\n")
