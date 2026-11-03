## 03c_boot.R <cand> <ncores>: ../03_boot.R scheme through gr.hat3c, shared draws ../out/boot_draws_dDBH.rds (set.seed(20261101)), B = 200.
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R")); suppressPackageStartupMessages(library(parallel))
a <- commandArgs(trailingOnly = TRUE); cand <- a[1]; NC <- as.integer(a[2]); B <- 200; resp <- "dDBH"; M3 <- MODE[[cand]]
d <- frameK(resp, FRAMEOF[[cand]]); d$inst <- paste(d$Data, d$Install)
F <- readRDS(file.path(OC, sprintf("fit_%s.rds", cand))); stopifnot(isTRUE(F$ok)); b0v <- F$b
DD <- readRDS(file.path(OB, "boot_draws_dDBH.rds")); stopifnot(identical(DD$inst, sort(unique(d$inst))), DD$n == nrow(d))
sp <- split(seq_len(nrow(d)), d$inst); logm("boot", cand, "mode", M3, "rows", nrow(d), "installations", length(sp), "B", B, "cores", NC)
one <- function(i) { ids <- DD$draws[[i]]; idx <- unlist(lapply(ids, function(k) sp[[k]]), use.names = FALSE)
  dd <- d[idx, ]; dd$Install <- paste(dd$Install, rep(seq_along(ids), lengths(sp[ids])), sep = "_r"); dd$TreeID <- paste(dd$TreeID, dd$Install)
  t0 <- Sys.time(); m <- fitS(resp, dd, b0v)
  if (is.null(m)) return(data.frame(draw = i, ok = FALSE, secs = as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  cbind(data.frame(draw = i, ok = TRUE, secs = as.numeric(difftime(Sys.time(), t0, units = "secs"))), as.data.frame(t(fixef(m)))) }
res <- mclapply(seq_len(B), one, mc.cores = NC, mc.preschedule = FALSE)
allc <- unique(unlist(lapply(res, names))); res <- do.call(rbind, lapply(res, function(x) { for (v in setdiff(allc, names(x))) x[[v]] <- NA; x[, allc] }))
write.csv(res, file.path(OC, sprintf("boot_dDBH_%s.csv", cand)), row.names = FALSE)
logm("BOOT DONE", cand, "converged", sum(res$ok), "of", B, "median secs", round(median(res$secs), 1))
