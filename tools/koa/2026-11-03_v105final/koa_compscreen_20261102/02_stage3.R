## 02_stage3.R: Stage 3 ordering, deployed (size_competition_only) vs M3a, M3b, M3c. Fitting path of the registry 06_survival_respec.R
## (damped Fisher scoring start from the deposit's fit_cloglog, then glm cloglog with offset ln YIP).
source(path.expand("~/jobs/koa_compscreen_20261102/lib.R"))
.src <- parse(path.expand("~/jobs/koa_origin_20260916/s06/deposit/regenerate_table6.R"))
for (.e in .src) if (is.call(.e) && identical(.e[[1]], as.name("<-")) && is.name(.e[[2]]) && as.character(.e[[2]]) %in% c("cll_loglik", "cll_pieces", "fit_cloglog")) eval(.e, globalenv())
cglm <- function(f, data) { X <- model.matrix(f, data); y <- model.response(model.frame(f, data)); pre <- fit_cloglog(X, as.numeric(y), log(data$yip))
  m <- suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = data, offset = log(yip), start = pre$beta, control = glm.control(maxit = 200, epsilon = 1e-8)))
  if (!m$converged) stop("nonconv"); m }
d <- fread(file.path(W, "frames/final/surv_recovered_ii_v103.csv"), colClasses = list(character = c("inst", "plot"))); nocoord(d); d <- as.data.frame(d)
ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(d[[k]]))); d <- d[ok & d$yip > 0 & d$ht > 0 & d$dbh > 0 & d$cr > 0 & d$byi > 0, ]
d$dead <- 1 - d$alive; d$cl <- paste(d$source, d$inst, sep = "/"); d$grp <- paste(d$cl, d$plot, d$t0, d$t1)
d$SDI <- sdi_of(d$source, d$inst, d$plot, d$t0); d$RD <- d$SDI / POP; d$share <- ifelse(d$baph > 0, d$bal / d$baph, 0); d$lc2 <- log(d$byi / 100)
stopifnot(all(is.finite(d$RD) & d$RD > 0)); logm("records", nrow(d), "deaths", sum(d$dead), "installations", length(unique(d$cl)))
FM <- list(D = dead ~ log(dbh) + rht + log(baph + 1) + log(bal + 1),
           M3a = dead ~ log(dbh) + rht + log(RD) + log(share * RD + 1),
           M3b = dead ~ log(dbh) + rht + log(RD) + log(share * RD + 1) + lc2,
           M3c = dead ~ log(dbh) + rht + log(baph + 1) + log(bal + 1) + lc2)
FT <- lapply(FM, cglm, data = d)
S3 <- c(-2.45353544308563, -1.24379127899638, -0.245835518593837, 0.801873721680337, 0.164263748192269)
g <- max(abs(coef(FT$D) - S3)); logm("GATE Stage 3 refit vs STAGE3_COEF max abs diff", signif(g, 3), if (g < 1e-6) "PASS" else "FAIL")
## LOIO
cls <- unique(d$cl)
LO <- rbindlist(lapply(cls, function(k) { tr <- d[d$cl != k, ]; te <- d[d$cl == k, ]
  rbindlist(lapply(names(FM), function(m) { mm <- tryCatch(cglm(FM[[m]], tr), error = function(e) NULL); if (is.null(mm)) return(NULL)
    data.table(model = m, cl = k, g = te$grp, y = te$dead, p = predict(mm, te, type = "response")) })) }))
nf <- LO[, .(folds = uniqueN(cl)), by = model]; print(nf)
## installation-cluster bootstrap of lc2 (M3b, M3c)
set.seed(SEED); cl_idx <- split(seq_len(nrow(d)), d$cl)
BS <- t(sapply(seq_len(NB), function(b) { idx <- unlist(cl_idx[sample(cls, length(cls), TRUE)], use.names = FALSE); db <- d[idx, ]
  sapply(c("M3b", "M3c"), function(m) tryCatch(coef(cglm(FM[[m]], db))[["lc2"]], error = function(e) NA)) }))
## monotonicity: P(death) non-decreasing in stand density (RD or BAPH) at fixed share, and in share (or BAL) at fixed density
qs <- function(v) quantile(v, c(.1, .5, .9)); grid <- function(v) seq(quantile(v, .01), quantile(v, .99), length.out = 50)
mono <- function(m) { cf <- coef(FT[[m]]); ok <- TRUE
  base <- expand.grid(dbh = qs(d$dbh), rht = qs(d$rht), lc2 = qs(d$lc2))
  eta <- function(nd) drop(model.matrix(update(FM[[m]], NULL ~ .), nd) %*% cf)
  for (i in seq_len(nrow(base))) {
    if (m %in% c("M3a", "M3b")) {
      for (sh in qs(d$share)) { nd <- data.frame(base[i, ], RD = grid(d$RD), share = sh, row.names = NULL); ok <- ok && all(diff(eta(nd)) >= -1e-10) }
      for (r in qs(d$RD)) { nd <- data.frame(base[i, ], RD = r, share = grid(d$share), row.names = NULL); ok <- ok && all(diff(eta(nd)) >= -1e-10) }
    } else {
      for (sh in qs(d$share)) { b <- grid(d$baph); nd <- data.frame(base[i, ], baph = b, bal = sh * b, row.names = NULL); ok <- ok && all(diff(eta(nd)) >= -1e-10) }
      for (b in qs(d$baph)) { nd <- data.frame(base[i, ], baph = b, bal = grid(d$share) * b, row.names = NULL); ok <- ok && all(diff(eta(nd)) >= -1e-10) }
    } }
  ok }
cn <- function(m, i) unname(coef(FT[[m]])[i])
res <- data.frame(component = "Stage 3", cand = names(FM), n = nrow(d), logLik = sapply(FT, function(m) as.numeric(logLik(m))), AIC = sapply(FT, AIC),
  c_lndbh = sapply(names(FM), cn, 2), c_rht = sapply(names(FM), cn, 3), c_density = sapply(names(FM), cn, 4), c_competition = sapply(names(FM), cn, 5),
  lc2 = sapply(names(FM), function(m) if ("lc2" %in% names(coef(FT[[m]]))) coef(FT[[m]])[["lc2"]] else NA),
  loio_auc_within = sapply(names(FM), function(m) with(LO[model == m], auc_within(y, p, g))), loio_auc_pooled = sapply(names(FM), function(m) with(LO[model == m], auc(y, p))),
  loio_brier = sapply(names(FM), function(m) with(LO[model == m], mean((y - p)^2))), loio_folds = nf$folds[match(names(FM), nf$model)],
  boot_lo = c(NA, NA, qboot(BS[, "M3b"])["lo"], qboot(BS[, "M3c"])["lo"]), boot_hi = c(NA, NA, qboot(BS[, "M3b"])["hi"], qboot(BS[, "M3c"])["hi"]),
  boot_ok = c(NA, NA, qboot(BS[, "M3b"])["n_ok"], qboot(BS[, "M3c"])["n_ok"]))
res$signs <- res$c_lndbh < 0 & res$c_rht < 0 & res$c_density > 0 & res$c_competition > 0; res$mono <- sapply(names(FM), mono); res$dAIC <- res$AIC - res$AIC[1]
res$gate_maxdiff <- c(g, NA, NA, NA)
write.csv(res, file.path(OUT, "stage3_results.csv"), row.names = FALSE); write.csv(BS, file.path(OUT, "stage3_boot.csv"), row.names = FALSE)
print(res, digits = 4); logm("cor ln(BAPH+1) vs ln(RD)", round(cor(log(d$baph + 1), log(d$RD)), 4)); logm("STAGE3 DONE")
