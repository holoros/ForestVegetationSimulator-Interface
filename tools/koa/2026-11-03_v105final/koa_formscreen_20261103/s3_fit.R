## s3_fit.R: mortality Stage 3 (tree ordering, cloglog, offset ln YIP). Baseline B = v105d M3a refit (RD = SDI/741.7117); S3a, S3b, S3c (PREREG).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R"))
.src <- parse(path.expand("~/jobs/koa_origin_20260916/s06/deposit/regenerate_table6.R"))
for (.e in .src) if (is.call(.e) && identical(.e[[1]], as.name("<-")) && is.name(.e[[2]]) && as.character(.e[[2]]) %in% c("cll_loglik", "cll_pieces", "fit_cloglog")) eval(.e, globalenv())
cglm <- function(f, data) { X <- model.matrix(f, data); y <- model.response(model.frame(f, data)); pre <- fit_cloglog(X, as.numeric(y), log(data$yip))
  m <- suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = data, offset = log(yip), start = pre$beta, control = glm.control(maxit = 200, epsilon = 1e-8)))
  if (!m$converged) stop("nonconv"); m }
d <- fread(file.path(W, "frames/final/surv_recovered_ii_v103.csv"), colClasses = list(character = c("inst", "plot"))); nocoord(d); d <- as.data.frame(d)
ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(d[[k]]))); d <- d[ok & d$yip > 0 & d$ht > 0 & d$dbh > 0 & d$cr > 0 & d$byi > 0, ]
d$dead <- 1 - d$alive; d$cl <- paste(d$source, d$inst, sep = "/"); d$grp <- paste(d$cl, d$plot, d$t0, d$t1)
d$SDI <- sdi_of(d$source, d$inst, d$plot, d$t0); d$RD <- d$SDI / POP; d$share <- ifelse(d$baph > 0, d$bal / d$baph, 0); d$lc2 <- log(d$byi / 100)
d$shRD <- d$share * d$RD; d$shlc2 <- d$share * d$lc2; stopifnot(all(is.finite(d$RD) & d$RD > 0))
logm("records", nrow(d), "deaths", sum(d$dead), "installations", length(unique(d$cl)), "RD range", paste(signif(range(d$RD), 4), collapse = " "))
FM <- list(B = dead ~ log(dbh) + rht + log(RD) + log(shRD + 1), S3a = dead ~ log(dbh) + rht + log(RD) + shRD + shlc2,
           S3b = dead ~ log(dbh) + log(cr) + log(RD) + log(shRD + 1), S3c = dead ~ log(dbh) + rht + hinge + log(shRD + 1))
R0G <- seq(round(quantile(d$RD, .05), 2), round(quantile(d$RD, .95), 2), by = 0.01)
fitm <- function(m, dd) { if (m != "S3c") return(cglm(FM[[m]], dd))
  ll <- sapply(R0G, function(r) { dd$hinge <- pmax(0, dd$RD - r); tryCatch(as.numeric(logLik(cglm(FM[[m]], dd))), error = function(e) -Inf) })
  r0 <- R0G[which.max(ll)]; dd$hinge <- pmax(0, dd$RD - r0); g <- cglm(FM[[m]], dd); attr(g, "r0") <- r0; g }
addh <- function(g, nd) { if (!is.null(attr(g, "r0"))) nd$hinge <- pmax(0, nd$RD - attr(g, "r0")); nd }
FT <- lapply(names(FM), fitm, dd = d); names(FT) <- names(FM)
M3A <- c(-1.20495317438739, 0.115178151642855, 2.08683986849611)   # v105d M3a c2 (rHT), c3 (ln RD), c4 slopes; c1 ln DBH -0.680325725635804
logm("GATE baseline slopes (ln DBH, rHT, ln RD) vs v105d M3a (unchanged by the divisor):", signif(max(abs(coef(FT$B)[2:4] - c(-0.680325725635804, M3A[1:2]))), 3), "| ln(share RD + 1):", signif(coef(FT$B)[[5]], 6), "(v105d 2.0868 at SDImax 923)")
cls <- unique(d$cl)
LO <- rbindlist(lapply(cls, function(k) { tr <- d[d$cl != k, ]; te <- d[d$cl == k, ]
  rbindlist(lapply(names(FM), function(m) { mm <- tryCatch(fitm(m, tr), error = function(e) NULL); if (is.null(mm)) return(NULL)
    data.table(model = m, cl = k, g = te$grp, y = te$dead, p = predict(mm, addh(mm, te), type = "response")) })) }))
nf <- LO[, .(folds = uniqueN(cl)), by = model]; print(nf)
set.seed(SEED); cl_idx <- split(seq_len(nrow(d)), d$cl)
BS <- sapply(seq_len(NB), function(b) { idx <- unlist(cl_idx[sample(cls, length(cls), TRUE)], use.names = FALSE); tryCatch(coef(cglm(FM$S3a, d[idx, ]))[["shlc2"]], error = function(e) NA) })
## monotonicity: P(death) non-decreasing in RD at fixed share and in share at fixed RD (eta; dbh, rht/cr, lc2 at 10/50/90 pct)
mono <- function(m) { g <- FT[[m]]; cf <- coef(g); mx <- 0; base <- expand.grid(dbh = qs(d$dbh), rht = qs(d$rht), cr = qs(d$cr), lc2 = qs(d$lc2))
  et <- function(nd) { nd$shRD <- nd$share * nd$RD; nd$shlc2 <- nd$share * nd$lc2; nd <- addh(g, nd); drop(model.matrix(update(FM[[m]], NULL ~ .), nd) %*% cf) }
  for (i in seq_len(nrow(base))) { for (sh in qs(d$share)) { e <- diff(et(data.frame(base[i, ], RD = grid50(d$RD), share = sh, row.names = NULL))); mx <- max(mx, -min(e)) }
    for (r in qs(d$RD)) { e <- diff(et(data.frame(base[i, ], RD = r, share = seq(0, 1, length.out = 50), row.names = NULL))); mx <- max(mx, -min(e)) } }
  c(ok = mx <= 1e-10, max_decrease = mx) }
sgn <- function(m) { cf <- coef(FT[[m]]); dens <- if (m == "S3c") cf[["hinge"]] else cf[["log(RD)"]]; comp <- if (m == "S3a") cf[["shRD"]] else cf[["log(shRD + 1)"]]
  sz <- if (m == "S3b") cf[["log(cr)"]] else cf[["rht"]]; cf[["log(dbh)"]] < 0 && sz < 0 && dens > 0 && comp > 0 }
res <- do.call(rbind, lapply(names(FM), function(m) { g <- FT[[m]]; cf <- coef(g); se <- summary(g)$coefficients[, 2]; mo <- mono(m); bt <- if (m == "S3a") qboot(BS) else c(lo = NA, hi = NA, n_ok = NA)
  data.frame(component = "Stage 3", cand = m, n = nrow(d), k = length(cf) + !is.null(attr(g, "r0")), r0 = if (is.null(attr(g, "r0"))) NA else attr(g, "r0"),
    coefs = paste(sprintf("%s=%.5g (SE %.3g)", names(cf), cf, se), collapse = "; "), logLik = as.numeric(logLik(g)),
    loio_auc_within = with(LO[model == m], auc_within(y, p, g)), loio_auc_pooled = with(LO[model == m], auc(y, p)), loio_brier = with(LO[model == m], mean((y - p)^2)),
    loio_folds = nf$folds[nf$model == m], signs = sgn(m), mono = as.logical(mo[["ok"]]), mono_max_decrease = mo[["max_decrease"]],
    byi_boot_lo = bt[["lo"]], byi_boot_hi = bt[["hi"]], byi_boot_ok = bt[["n_ok"]]) }))
res$AIC <- -2 * res$logLik + 2 * res$k; res$dAIC <- res$AIC - res$AIC[res$cand == "B"]
write.csv(res, file.path(OUT, "stage3_results.csv"), row.names = FALSE); write.csv(data.frame(S3a_shlc2 = BS), file.path(OUT, "stage3_boot.csv"), row.names = FALSE)
saveRDS(lapply(FT, function(g) list(coef = coef(g), se = summary(g)$coefficients[, 2], r0 = attr(g, "r0"))), file.path(OUT, "stage3_fits.rds"))
print(res, digits = 4); logm("STAGE3 DONE")
