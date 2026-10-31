#!/usr/bin/env Rscript
## a5/loio/fit_folds.R (koa v104 A5 LOIO, 31 Oct 2026). Refit dDBH_L_NO on the NO frame with one installation held out,
## re-solve the origin constants (solve_c) and CF; machinery sourced from track2/inc/inc_v103.R lines 1-112 (as a4/inc/inc_byi_x_v104.R).
## Usage: Rscript fit_folds.R <fold1> [<fold2> ...]   fold "NONE" = no installation held out (sanity gate). Writes fits/fit_<fold>.csv.
## No coordinate column is read or written (nocoord asserted on the frame).
suppressPackageStartupMessages(library(nlme))
folds <- commandArgs(trailingOnly = TRUE)
src <- readLines(path.expand("~/jobs/koa_v104_20261030/track2/inc/inc_v103.R"))
commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112]))
LO <- path.expand("~/jobs/koa_v104_20261030/a5/loio/fits"); dir.create(LO, showWarnings = FALSE)
GUARD <- 45
d0 <- read.csv(file.path(FRD, "dDBH_NO_v103_model.csv"), stringsAsFactors = FALSE); nocoord(d0)
d0$icls <- factor(d0$icls, levels = c("1-2", "3-5", "6-10", "11-20", "21+"))
d0 <- model_cols(d0, "l"); d0$inst <- paste(d0$Data, d0$Install, sep = "|")
for (fold in folds) {
  d <- if (fold == "NONE") d0 else d0[d0$inst != fold, ]
  t0 <- Sys.time(); row <- data.frame(fold = fold, n_rows = nrow(d), n_dropped = nrow(d0) - nrow(d), n_inst = length(unique(d$inst)), status = "ok", msg = "")
  m <- tryCatch(fit_one("dDBH", d, "NO"), error = function(e) e)
  if (inherits(m, "error")) { row$status <- "FAILED_fit"; row$msg <- conditionMessage(m) } else {
    bb <- fixef(m); tau <- taus(m); cf <- exp(0.5 * sum(tau[1:2]^2))
    cc <- tryCatch(solve_c("dDBH", d, bb), error = function(e) e)
    for (k in names(bb)) row[[k]] <- bb[[k]]
    row$tau_source <- tau[1]; row$tau_inst <- tau[2]; row$tau_tree <- if (length(tau) > 2) tau[3] else NA; row$CF <- cf; row$logLik <- as.numeric(logLik(m))
    if (inherits(cc, "error") || any(!is.finite(cc))) { row$status <- "FAILED_c"; row$msg <- if (inherits(cc, "error")) conditionMessage(cc) else "non-finite c" } else {
      row$c_natural <- cc[["natural"]]; row$c_planted <- cc[["planted"]]; row$CAL_natural <- cc[["natural"]] / cf; row$CAL_planted <- cc[["planted"]] / cf }
  }
  row$secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")))
  write.csv(row, file.path(LO, sprintf("fit_%s.csv", gsub("[|]", "_", fold))), row.names = FALSE)
  logm("FOLD", fold, row$status, "rows", row$n_rows, "dropped", row$n_dropped, "secs", row$secs, if (!is.null(row$b8)) paste("b8", signif(row$b8, 6), "CF", signif(row$CF, 6), "c", signif(row$c_natural, 5), signif(row$c_planted, 5)) else row$msg)
}
logm("ALL DONE")
