## 03_boot.R <resp> <cand> <ncores>: v2 04_boot.R scheme on the common rows, B = 200, draws set.seed(20261101) once per response, shared by all candidates.
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R")); suppressPackageStartupMessages(library(parallel))
a <- commandArgs(trailingOnly = TRUE); resp <- a[1]; cand <- a[2]; NC <- as.integer(a[3]); B <- 200; GUARD <- if (resp == "dDBH") 45 else 20
d <- frameK(resp, cand); d$inst <- paste(d$Data, d$Install)
F <- readRDS(file.path(OB, sprintf("fit_%s.rds", cand)))[[resp]]; stopifnot(isTRUE(F$ok)); b0v <- F$b
dfile <- file.path(OB, sprintf("boot_draws_%s.rds", resp))
if (!file.exists(dfile)) { set.seed(20261101); sp0 <- split(seq_len(nrow(d)), d$inst); src_of <- tapply(d$Data, d$inst, function(x) x[1]); ids_by_src <- split(names(sp0), src_of[names(sp0)])
  DR <- lapply(seq_len(B), function(i) unlist(lapply(ids_by_src, function(v) sample(v, length(v), replace = TRUE)), use.names = FALSE))
  saveRDS(list(draws = DR, inst = sort(unique(d$inst)), n = nrow(d)), dfile) }
DD <- readRDS(dfile); stopifnot(identical(DD$inst, sort(unique(d$inst))), DD$n == nrow(d))
sp <- split(seq_len(nrow(d)), d$inst)
logm("boot", resp, cand, "rows", nrow(d), "installations", length(sp), "B", B, "cores", NC)
one <- function(i) { ids <- DD$draws[[i]]; idx <- unlist(lapply(ids, function(k) sp[[k]]), use.names = FALSE)
  dd <- d[idx, ]; dd$Install <- paste(dd$Install, rep(seq_along(ids), lengths(sp[ids])), sep = "_r"); dd$TreeID <- paste(dd$TreeID, dd$Install)
  t0 <- Sys.time(); m <- fitS(resp, dd, b0v)
  if (is.null(m)) return(data.frame(draw = i, ok = FALSE, secs = as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  cbind(data.frame(draw = i, ok = TRUE, secs = as.numeric(difftime(Sys.time(), t0, units = "secs"))), as.data.frame(t(fixef(m)))) }
res <- mclapply(seq_len(B), one, mc.cores = NC, mc.preschedule = FALSE)
allc <- unique(unlist(lapply(res, names))); res <- do.call(rbind, lapply(res, function(x) { for (v in setdiff(allc, names(x))) x[[v]] <- NA; x[, allc] }))
write.csv(res, file.path(OB, sprintf("boot_%s_%s.csv", resp, cand)), row.names = FALSE)
logm("BOOT DONE", resp, cand, "converged", sum(res$ok), "of", B, "median secs", round(median(res$secs), 1))
