#!/usr/bin/env Rscript
# Compare the R side of the HiGy.R 0.4.0 fixture harness with the expected
# values written by the Python engine of record. Run parity_r.R first.
# Usage: Rscript check_parity.R [tolerance]   (default relative tolerance 1e-10)
args <- commandArgs(trailingOnly = TRUE)
tol  <- if (length(args) >= 1) as.numeric(args[1]) else 1e-10
cmp <- function(r, p, keys, cols) {
  m <- merge(r, p, by = keys, suffixes = c(".r", ".py"))
  stopifnot(nrow(m) == nrow(r), nrow(m) == nrow(p))
  worst <- 0; bad <- character(0)
  for (cn in cols) {
    a <- m[[paste0(cn, ".r")]]; b <- m[[paste0(cn, ".py")]]
    both_na <- is.na(a) & is.na(b)
    rel <- ifelse(both_na, 0, abs(a - b) / pmax(1, abs(b)))
    rel[is.na(rel)] <- Inf
    worst <- max(worst, rel)
    if (any(rel > tol)) bad <- c(bad, paste0(cn, " [", paste(unique(m[[keys[1]]][rel > tol]), collapse = ","), "]"))
  }
  list(worst = worst, bad = bad, n = nrow(m))
}
S <- cmp(read.csv("out_r_stand.csv"), read.csv("expected_python_stand.csv"), "label",
         c("N0", "QMD0", "QMD1", "SDI", "H_QMD0", "H_QMD1", "m_garcia", "p_stage1",
           "m_stand", "deaths_ha", "deaths_alloc", "wbar", "max_mort_frac", "cap_warn"))
T <- cmp(read.csv("out_r_tree.csv"), read.csv("expected_python_tree.csv"), c("label", "tree"),
         c("dbh", "expf", "w", "mort_frac", "deaths"))
cat(sprintf("stand: %d cases, worst relative difference %.3g\n", S$n, S$worst))
cat(sprintf("tree : %d rows,  worst relative difference %.3g\n", T$n, T$worst))
if (length(c(S$bad, T$bad))) {
  cat("FAIL on:", c(S$bad, T$bad), sep = "\n  "); quit(status = 1)
}
cat(sprintf("PASS: all cases agree to relative tolerance %g\n", tol))
