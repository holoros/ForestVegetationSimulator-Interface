## s2_height_treere.R (R1 c3). Eq. 2 with a tree-level random intercept on a0. The three-level fit (source/installation/tree) in
## s2_height_boot.R stops with a backsolve singularity (the source variance is essentially zero, tau source 0.0019 in the v102 fit),
## so the tree level is nested in installation with the source level dropped; the two-level reference without the source level is
## fitted too so that the tree effect is compared like for like.
suppressPackageStartupMessages(library(nlme))
JOB <- file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928"); OUT <- file.path(JOB, "out")
src <- readLines(file.path(JOB, "inputs/height_refit.R"))
eval(parse(text = src[grep("^HT_REFIT_PRINTED <-", src)]))
eval(parse(text = src[grep("^prep <- function", src):(grep("^RES <- list", src) - 1)]))
d <- prep(file.path(JOB, "inputs/tree_join_v102.csv")); m0 <- fit_ht(d)$fit
d$grp_tree <- factor(paste(d$grp_inst, d$plot, d$tree, sep = "/"))
form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
ct <- nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)
mi <- nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_inst, start = fixef(m0), control = ct); cat("inst-only ok\n")
ftree <- function(st, cc) tryCatch(nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_inst/grp_tree, start = st, control = cc), error = function(e) { cat("tree fit error:", conditionMessage(e), "\n"); NULL })
mt <- ftree(fixef(mi), ct)
if (is.null(mt)) { cat("retry with pnlsTol 0.01, tolerance 1e-5\n"); mt <- ftree(fixef(mi), nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, pnlsTol = 0.01, tolerance = 1e-5, returnObject = TRUE)) }
if (is.null(mt)) { cat("retry pdDiag-free: random = list(grp_inst = a0 ~ 1, grp_tree = a0 ~ 1), niterEM 50\n"); mt <- tryCatch(nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = list(grp_inst = pdIdent(a0 ~ 1), grp_tree = pdIdent(a0 ~ 1)), start = fixef(mi), control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, pnlsTol = 0.01, niterEM = 50, returnObject = TRUE)), error = function(e) { cat("tree fit error 3:", conditionMessage(e), "\n"); NULL }) }
stopifnot(!is.null(mt))
t0 <- summary(m0)$tTable; ti <- summary(mi)$tTable; tt <- summary(mt)$tTable
r <- data.frame(term = rownames(t0), ref_est = t0[, 1], ref_se = t0[, 2], inst_only_est = ti[, 1], inst_only_se = ti[, 2], tree_est = tt[, 1], tree_se = tt[, 2],
  se_ratio_tree_vs_ref = tt[, 2] / t0[, 2], dz_tree_refSE = (tt[, 1] - t0[, 1]) / t0[, 2],
  logLik_ref = as.numeric(logLik(m0)), logLik_inst_only = as.numeric(logLik(mi)), logLik_tree = as.numeric(logLik(mt)),
  AIC_ref = AIC(m0), AIC_inst_only = AIC(mi), AIC_tree = AIC(mt), n = nrow(d), n_trees = nlevels(d$grp_tree), row.names = NULL)
print(r, digits = 4); print(VarCorr(mt)); write.csv(r, file.path(OUT, "height_treeRE.csv"), row.names = FALSE)
