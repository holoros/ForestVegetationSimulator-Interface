#!/usr/bin/env Rscript
# =============================================================================
# R side of the BAL parity harness, v103, 30 September 2026.
# Sources the EDITED copy a2/higy/engine/HiGy.R and drives koa_parity_bal_v103.json:
#   1. hand, edge and random lists through koa_bal_percentile_weighted() and
#      calc_bal_percentile()                                 -> out/parity_bal_r_lists.csv
#   2. calc_bal_percentile() on the Python project_psp per year states
#      (out/parity_bal_py_proj.csv, same dbh, expf, ba)      -> out/parity_bal_r_on_pystate.csv
#   3. a 10 year HiGYOneStand() projection of each projection list, recording
#      the BAL each calc_bal_koa() call returns (phase 1 start of step,
#      phase 2 crown recession)                              -> out/parity_bal_r_proj.csv
# Defines no equation of its own; the recorder wraps calc_bal_percentile only.
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
HERE <- if (length(args) >= 1) args[1] else "."
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(source(file.path(HERE, "engine", "HiGy.R")))
OUT <- file.path(HERE, "out"); dir.create(OUT, showWarnings = FALSE)
stopifnot(identical(KOA_BAL_DEFINITION, "percentile"), isTRUE(KOA_BAL_PERCENTILE_WEIGHTED))
cat("R SIDE: ", normalizePath(file.path(HERE, "engine", "HiGy.R")), VersionTag, R.version.string, "\n")

wcsv <- function(df, f) {
  for (k in names(df)) if (is.double(df[[k]])) df[[k]] <- sprintf("%.17g", df[[k]])
  write.csv(df, f, row.names = FALSE, quote = FALSE)
}
CFG <- fromJSON(file.path(HERE, "koa_parity_bal_v103.json"), simplifyVector = FALSE)
TPH_FAC <- 0.00007854

# 1. lists
rows <- list()
for (grp in c("hand", "edge", "random")) for (cc in CFG[[grp]]) {
  dbh <- as.numeric(unlist(cc$dbh)); expf <- as.numeric(unlist(cc$expf))
  fr  <- koa_bal_percentile_weighted(dbh, expf)
  td  <- data.frame(plot = 1, tree = seq_along(dbh), dbh = dbh, expf = expf,
                    ba = dbh^2 * TPH_FAC * expf)
  tb  <- calc_bal_percentile(td); tb <- tb[order(tb$tree), ]
  rows[[length(rows) + 1]] <- data.frame(group = grp, case = cc$id, i = seq_along(dbh),
                                         frac = fr, bal = tb$bal)
}
wcsv(do.call(rbind, rows), file.path(OUT, "parity_bal_r_lists.csv"))

# 2. on the Python states
py <- read.csv(file.path(OUT, "parity_bal_py_proj.csv"), stringsAsFactors = FALSE)
rows <- list()
for (key in unique(paste(py$list, py$year, sep = "#"))) {
  g  <- py[paste(py$list, py$year, sep = "#") == key, ]
  td <- data.frame(plot = 1, tree = g$tree, dbh = g$dbh, expf = g$expf,
                   ba = g$dbh^2 * TPH_FAC * g$expf)
  tb <- calc_bal_percentile(td)
  tb <- tb[match(g$tree, tb$tree), ]
  rows[[length(rows) + 1]] <- data.frame(list = g$list, year = g$year, tree = g$tree,
                                         frac = koa_bal_percentile_weighted(g$dbh, g$expf),
                                         bal = tb$bal)
}
wcsv(do.call(rbind, rows), file.path(OUT, "parity_bal_r_on_pystate.csv"))

# 3. HiGYOneStand projection with a recorder on calc_bal_percentile
.orig_cbp <- calc_bal_percentile
REC <- list(); CUR_YR <- 0L; PHASE <- 0L
calc_bal_percentile <- function(tree.data, weighted = KOA_BAL_PERCENTILE_WEIGHTED) {
  out <- .orig_cbp(tree.data, weighted)
  PHASE <<- PHASE + 1L
  REC[[length(REC) + 1]] <<- data.frame(year = CUR_YR, phase = PHASE, tree = out$tree,
                                        dbh = out$dbh, ht = out$ht, cr = out$cr,
                                        expf = out$expf, ba = out$ba, bal = out$bal)
  out
}
ops <- make_ops(rtn.vars = c('year', 'plot', 'tree', 'sp', 'dbh', 'ht', 'cr', 'expf',
                             'ddbh.mult', 'dht.mult', 'mort.mult', 'max.dbh', 'max.height'))
allrec <- list(); allst <- list()
for (pid in names(CFG$projection)) {
  L <- CFG$projection[[pid]]
  dbh <- as.numeric(unlist(L$dbh))
  stand <- make_stand(pid, byi = L$byi, planted = L$planted)   # global: calc_* defaults read stand$byi
  assign("stand", stand, envir = .GlobalEnv)
  tree <- data.frame(year = 0, plot = 1, tree = seq_along(dbh), sp = "AK", dbh = dbh,
                     ht = as.numeric(unlist(L$ht)), cr = as.numeric(L$cr),
                     expf = as.numeric(unlist(L$expf)), ddbh.mult = 1, dht.mult = 1, mort.mult = 1,
                     max.dbh = if (L$planted == 1) 69.7 else 90.0,     # Python harness_dbh_max(planted)
                     max.height = 28.041600000000003,                   # Python HARNESS_HT_MAX_PSP_M
                     stringsAsFactors = FALSE)
  REC <- list()
  for (yr in seq_len(L$n_years)) {
    CUR_YR <- yr; PHASE <- 0L
    tree <- HiGYOneStand(tree, stand, ops)
    allst[[length(allst) + 1]] <- data.frame(list = pid, year = yr, TPH = sum(tree$expf),
                                             BAPH = sum(tree$dbh^2 * TPH_FAC * tree$expf))
  }
  r <- do.call(rbind, REC); r$list <- pid
  allrec[[length(allrec) + 1]] <- r
}
wcsv(do.call(rbind, allrec), file.path(OUT, "parity_bal_r_proj.csv"))
wcsv(do.call(rbind, allst), file.path(OUT, "parity_bal_r_proj_stand_end.csv"))
cat("R lists, on-python-state and projection written\n")
