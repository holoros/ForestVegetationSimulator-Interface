## parity_frames.R: (1) v105c frames = v105b frames on every v105b column (+ TPH/QMD); (2) with DDBH_FORM v105b the patched machinery reproduces
## v105b predictions and constants exactly; (3) the K3c1 columns equal the screen's K3p frame (koa_rdcomp_20261102 frameK) on the same rows.
suppressPackageStartupMessages(library(nlme)); V5 <- path.expand("~/jobs/koa_v105_20261102"); VC <- path.expand("~/jobs/koa_v105c_20261102")
src <- readLines(file.path(VC, "track2/inc/inc_v103.R")); commandArgs0 <- commandArgs; commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); commandArgs <- commandArgs0; out <- list()
J <- jsonlite::fromJSON(file.path(V5, "out/v105_constants.json"))
for (resp in c("dDBH", "dHT")) for (fr in c("NO", "CS")) { a <- read.csv(file.path(VC, sprintf("frames/final/%s_%s_v103_model.csv", resp, fr)), stringsAsFactors = FALSE)
  b <- read.csv(file.path(V5, sprintf("frames/final/%s_%s_v103_model.csv", resp, fr)), stringsAsFactors = FALSE)
  out[[length(out) + 1]] <- data.frame(check = sprintf("frame %s %s: v105b columns identical (rows %d vs %d; new columns %s)", resp, fr, nrow(a), nrow(b), paste(setdiff(names(a), names(b)), collapse = " ")),
    value = as.numeric(identical(a[, names(b)], b)), pass = identical(a[, names(b)], b)) }
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20
  a <- model_cols(read.csv(file.path(VC, sprintf("frames/final/%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE), "l")
  b <- model_cols(read.csv(file.path(V5, sprintf("frames/final/%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE), "l")
  vec <- unlist(J[[if (resp == "dDBH") "DDBH" else "DHT"]]$coef)[paste0("b", 0:9)]
  DDBH_FORM <- "v105b"; pa <- pa_pred(resp, a, vec); ca <- solve_c(resp, a, vec)
  pb <- { e <- new.env(); s5 <- readLines(file.path(V5, "track2/inc/inc_v103.R")); eval(parse(text = s5[22:111]), envir = e); e$GUARD <- GUARD; e$pa_pred(resp, b, vec) }
  out[[length(out) + 1]] <- data.frame(check = sprintf("%s DDBH_FORM v105b: pa_pred patched vs v105b code, max abs diff", resp), value = max(abs(pa - pb)), pass = max(abs(pa - pb)) == 0)
  cdep <- c(J[[if (resp == "dDBH") "DDBH" else "DHT"]]$c_natural, J[[if (resp == "dDBH") "DDBH" else "DHT"]]$c_planted)
  out[[length(out) + 1]] <- data.frame(check = sprintf("%s DDBH_FORM v105b: solve_c on CSV frame vs deployed c (max abs diff)", resp), value = max(abs(ca - cdep)), pass = max(abs(ca - cdep)) < 1e-6) }
## K3c1 columns vs the screen frame
DDBH_FORM <- "K3c1"; a <- model_cols(read.csv(file.path(VC, "frames/final/dDBH_NO_v103_model.csv"), stringsAsFactors = FALSE), "l")
eK <- new.env(); local({ commandArgs <- function(trailingOnly = TRUE) "none"; source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"), local = TRUE) }, envir = eK)
k <- eK$frameK("dDBH", "K3p"); stopifnot(identical(paste(a$TreeID, a$t.0, a$t.1), paste(k$TreeID, k$t.0, k$t.1)))
for (v in c("XK.0", "XK.1", "RD.0", "RD.1")) { kk <- switch(v, XK.0 = k$BALx.0, XK.1 = k$BALx.1, RD.0 = k$BAPH.0, RD.1 = k$BAPH.1)
  out[[length(out) + 1]] <- data.frame(check = sprintf("K3c1 %s vs screen K3p frame, max abs diff", v), value = max(abs(a[[v]] - kk)), pass = max(abs(a[[v]] - kk)) < 1e-12) }
O <- do.call(rbind, out); print(O, digits = 6); write.csv(O, file.path(VC, "v105c/out/parity_frames.csv"), row.names = FALSE); cat("PARITY_FRAMES", if (all(O$pass)) "PASS" else "FAIL", "\n")
