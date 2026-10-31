## a5/rerun/h/h_boot.R <B> <cores>. Installation-cluster bootstrap of Eq. 2 on the FINAL height frame.
## Logic copied from ~/jobs/koa_rv_incr_20260928/s2_height_boot.R (preliminary run, 1,205 of 2,000), which sourced prep()/fit_ht()
## from the track2 height_refit.R. Here prep()/fit_ht() are taken verbatim from ~/jobs/koa_v104_20261030/track2/height_refit_v103.R
## (the script that produced the v103/v104 Table 2 vector, HT_P) and the input is frames/final/tree_join_v103.csv.
## Only changes vs preliminary: input frame (final), seed 20261031, checkpointed batches (draw index sets generated up front, so
## results do not depend on batching), tree-RE comparison dropped (not part of the bootstrap result).
suppressPackageStartupMessages(library(nlme))
J <- path.expand("~/jobs/koa_v104_20261030"); O <- file.path(J, "a5/rerun/h")
a <- commandArgs(trailingOnly = TRUE); B <- as.integer(a[1]); cores <- as.integer(a[2])
src <- readLines(file.path(J, "track2/height_refit_v103.R"))
eval(parse(text = src[grep("^HT_REFIT_PRINTED <-", src)]))
eval(parse(text = src[grep("^prep <- function", src):(grep("^RES <- list", src) - 1)]))
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
d <- prep(file.path(J, "frames/final/tree_join_v103.csv"))
logm("final height frame n", nrow(d), "installations", nlevels(d$grp_inst))
t0 <- Sys.time(); r0 <- fit_ht(d); m0 <- r0$fit; tt <- summary(m0)$tTable
logm("reference fit secs", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "fixef", paste(sprintf("%.6f", fixef(m0)), collapse = " "))
ref <- data.frame(term = rownames(tt), est = tt[, 1], wald_se = tt[, 2], n = nrow(d), n_inst = nlevels(d$grp_inst))
write.csv(ref, file.path(O, "h_ref_final.csv"), row.names = FALSE)
ids <- levels(d$grp_inst); sp <- split(seq_len(nrow(d)), d$grp_inst)
set.seed(20261031); DRAWS <- lapply(seq_len(B), function(b) sample(ids, replace = TRUE))
one <- function(b) {
  s <- DRAWS[[b]]
  dd <- do.call(rbind, lapply(seq_along(s), function(j) { x <- d[sp[[s[j]]], ]; x$grp_inst <- paste(x$grp_inst, j, sep = "#"); x }))
  dd$grp_inst <- factor(dd$grp_inst); dd$grp_src <- factor(dd$grp_src)
  m <- tryCatch(suppressWarnings(fit_ht(dd)$fit), error = function(e) NULL)
  if (is.null(m)) return(c(draw = b, ok = 0, setNames(rep(NA, 6), rownames(tt))))
  c(draw = b, ok = 1, fixef(m))
}
## per-draw checkpoint: each worker writes draws/draw_<b>.csv, so an interrupted run loses at most the draws in flight
DD <- file.path(O, "draws"); dir.create(DD, showWarnings = FALSE)
one_ck <- function(b) { fn <- file.path(DD, sprintf("draw_%04d.csv", b)); if (file.exists(fn)) return(invisible(NULL))
  r <- one(b); write.csv(as.data.frame(t(r)), paste0(fn, ".tmp"), row.names = FALSE); file.rename(paste0(fn, ".tmp"), fn); invisible(NULL) }
todo <- which(!file.exists(file.path(DD, sprintf("draw_%04d.csv", seq_len(B)))))
logm("draws to do", length(todo), "cores", cores)
invisible(parallel::mclapply(todo, one_ck, mc.cores = cores, mc.preschedule = FALSE))
fs <- list.files(DD, pattern = "^draw_[0-9]+\\.csv$", full.names = TRUE)
bs <- do.call(rbind, lapply(fs, read.csv)); bs <- bs[order(bs$draw), ]
write.csv(bs, file.path(O, "h_boot_final.csv"), row.names = FALSE)
logm("HEIGHT BOOT DONE ok", sum(bs$ok), "of", nrow(bs))
