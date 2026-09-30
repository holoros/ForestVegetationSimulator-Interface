## s2_height_boot.R <B> <cores>. Installation-cluster bootstrap of the static height equation Eq. 2 (R1 comment 3), using the
## prep() and fit_ht() of ~/jobs/koa_v102_20260918/track2/height_refit.R verbatim (nls start from the printed vector, then nlme
## with random a0 on source/installation), plus a tree-level random intercept nested in installation for comparison.
suppressPackageStartupMessages(library(nlme))
JOB <- file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928"); OUT <- file.path(JOB, "out")
a <- commandArgs(trailingOnly = TRUE); B <- as.integer(a[1]); cores <- as.integer(a[2])
src <- readLines(file.path(JOB, "inputs/height_refit.R"))
eval(parse(text = src[grep("^HT_REFIT_PRINTED <-", src)]))
eval(parse(text = src[grep("^prep <- function", src):(grep("^RES <- list", src) - 1)]))
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
d <- prep(file.path(JOB, "inputs/tree_join_v102.csv"))
r0 <- fit_ht(d); m0 <- r0$fit; tt <- summary(m0)$tTable
logm("height ref n", nrow(d), "installations", nlevels(d$grp_inst), "fixef", paste(sprintf("%.6f", fixef(m0)), collapse = " "))
ref <- data.frame(term = rownames(tt), est = tt[, 1], wald_se = tt[, 2])
d$grp_tree <- factor(paste(d$grp_inst, d$plot, d$tree, sep = "/"))
form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
mt <- tryCatch(nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst/grp_tree, start = fixef(m0),
  control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)), error = function(e) { logm("tree RE error", conditionMessage(e)); NULL })
if (!is.null(mt)) { tt2 <- summary(mt)$tTable; ref$tree_est <- tt2[, 1]; ref$tree_se <- tt2[, 2]
  ref$tree_logLik <- as.numeric(logLik(mt)); ref$ref_logLik <- as.numeric(logLik(m0)); ref$tree_AIC <- AIC(mt); ref$ref_AIC <- AIC(m0); ref$n_trees <- nlevels(d$grp_tree)
  logm("tree RE logLik", round(logLik(mt), 2), "vs", round(logLik(m0), 2)) }
write.csv(ref, file.path(OUT, "height_ref_and_treeRE.csv"), row.names = FALSE)
ids <- levels(d$grp_inst); sp <- split(seq_len(nrow(d)), d$grp_inst)
set.seed(20260928); DRAWS <- lapply(seq_len(B), function(b) sample(ids, replace = TRUE))
one <- function(b) {
  s <- DRAWS[[b]]
  dd <- do.call(rbind, lapply(seq_along(s), function(j) { x <- d[sp[[s[j]]], ]; x$grp_inst <- paste(x$grp_inst, j, sep = "#"); x }))
  dd$grp_inst <- factor(dd$grp_inst); dd$grp_src <- factor(dd$grp_src)
  m <- tryCatch(suppressWarnings(fit_ht(dd)$fit), error = function(e) NULL)
  if (is.null(m)) return(c(draw = b, ok = 0, setNames(rep(NA, 6), rownames(tt))))
  c(draw = b, ok = 1, fixef(m))
}
bs <- do.call(rbind, parallel::mclapply(seq_len(B), one, mc.cores = cores, mc.preschedule = TRUE))
write.csv(bs, file.path(OUT, "boot_height.csv"), row.names = FALSE)
logm("HEIGHT BOOT DONE ok", sum(bs[, "ok"]), "of", B)
