## 06_survival_respec.R: survival equation with the offset placed so survival falls with interval
## length, P(death | YIP) = 1 - exp(-YIP * exp(eta)), fitted to the death response (red team major 5).
source("common.R")
prep <- function(d) {
  d <- std(d)
  need(d, c("inst", "alive", "yip", "ht", "dbh", "rht", "cr", "byi"), "survival table")
  ## 2026-09-16: no deduplication here; the deposited table carries none and Table S11 fits are undeduplicated
  ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(d[[k]])))
  d <- d[ok & d$yip > 0 & d$ht > 0 & d$dbh > 0 & d$cr > 0 & d$byi > 0, ]
  d$dead <- 1 - d$alive
  d$inst <- clus(d)
  d$grp <- paste(d$inst, d$plot, if ("t0" %in% names(d)) d$t0 else "", if ("t1" %in% names(d)) d$t1 else d$yip)
  d
}
## 2026-09-16: cold glm() oscillates on these cloglog fits (regenerate_table6.R documents it), so every
## fit starts from the deposit's damped Fisher scoring solution and is then handed to glm().
.src <- parse(dep("regenerate_table6.R"))
for (.e in .src) if (is.call(.e) && identical(.e[[1]], as.name("<-")) && is.name(.e[[2]]) &&
                    as.character(.e[[2]]) %in% c("cll_loglik", "cll_pieces", "fit_cloglog")) eval(.e, globalenv())
cglm <- function(f, data) {
  X <- model.matrix(f, data); y <- model.response(model.frame(f, data))
  pre <- fit_cloglog(X, as.numeric(y), log(data$yip))
  m <- suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = data, offset = log(yip),
                            start = pre$beta, control = glm.control(maxit = 200, epsilon = 1e-8)))
  if (!m$converged || !pre$converged) logmsg("WARNING cloglog fit not converged: ", deparse(f[[3]])[1])
  m
}
specs <- list(
  table_s9_terms = dead ~ ht + log(ht) + rht + log(cr) + log(ht / dbh) + log(byi / 100) + I(byi / 1000),
  with_density   = dead ~ ht + log(ht) + rht + log(cr) + log(ht / dbh) + log(byi / 100) + I(byi / 1000) + log(baph + 1) + log(bal + 1),
  size_competition_only = dead ~ log(dbh) + rht + log(baph + 1) + log(bal + 1))
auc_within <- function(y, s, g) {   # pairs compared only inside the same plot interval, as Stage 3 allocates
  num <- 0; den <- 0
  for (idx in split(seq_along(y), g)) {
    yy <- y[idx]; n1 <- sum(yy == 1); n0 <- sum(yy == 0)
    if (n1 == 0 || n0 == 0) next
    r <- rank(s[idx]); num <- num + (sum(r[yy == 1]) - n1 * (n1 + 1) / 2); den <- den + n1 * n0
  }
  if (den == 0) NA_real_ else num / den
}
eq5_terms <- alive ~ ht + log(ht) + rht + log(cr) + log(ht / dbh) + log(byi / 100) + I(byi / 1000)
loio <- function(d, f, fam_resp, score) {
  ids <- unique(d$inst)
  do.call(rbind, parallel::mclapply(as.character(ids), function(k) {
    tr <- d$inst != k
    mm <- tryCatch(cglm(f, d[tr, ]), error = function(e) NULL)
    if (is.null(mm)) return(NULL)
    eta <- predict(mm, d[!tr, ], type = "link") - log(d$yip[!tr])   # link carries the offset; remove it for the annual score
    data.frame(inst = k, g = d$grp[!tr], y = d$dead[!tr], p_int = score(predict(mm, d[!tr, ], type = "response")), p_ann = score(1 - exp(-exp(eta))))
  }, mc.cores = NCORES))
}
eq5_row <- function(d, label) {
  m <- cglm(eq5_terms, d)
  lo <- loio(d, eq5_terms, "alive", function(p) 1 - p)
  X <- model.matrix(eq5_terms, d); eta_s9 <- drop(X %*% SURV_S9)
  dep_ann <- 1 - (1 - exp(-exp(eta_s9)))          # annual death score under the deployed coefficients
  dep_row <- data.frame(sample = label, spec = "eq5_deployed_coefficients_no_refit", n = nrow(d), deaths = sum(d$dead), aic = NA,
                        auc_apparent = auc(d$dead, 1 - (1 - exp(-exp(eta_s9 + log(d$yip))))), auc_loio_pooled = NA,
                        auc_loio_annual = auc(d$dead, dep_ann), auc_within_interval = auc_within(d$dead, dep_ann, d$grp),
                        expected_events = sum(exp(-exp(eta_s9 + log(d$yip)))))
  list(dep = dep_row, coef = data.frame(sample = label, term = names(coef(m)), estimate = coef(m), table_s9 = if (nrow(d) == 5969) SURV_S9 else NA),
       stats = data.frame(sample = label, spec = "eq5_alive_as_published", n = nrow(d), deaths = sum(d$dead), aic = AIC(m),
                          auc_apparent = auc(d$dead, 1 - fitted(m)), auc_loio_pooled = auc(lo$y, lo$p_int),
                          auc_loio_annual = auc(lo$y, lo$p_ann), auc_within_interval = auc_within(lo$y, lo$p_ann, lo$g), expected_events = sum(1 - fitted(m))))
}
run <- function(d, label) {
  logmsg(label, ": ", nrow(d), " records, ", sum(d$dead), " deaths, ", length(unique(d$inst)), " installations")
  gate(sum(d$dead) >= 20, paste(label, "has at least 20 deaths"))
  res <- list(); coefs <- list()
  base_auc <- auc(d$dead, d$yip)
  for (nm in names(specs)) {
    f <- specs[[nm]]
    if (!all(all.vars(f) %in% names(d))) { logmsg("skip spec ", nm, " (columns absent)"); next }
    m <- safely(cglm(f, d), paste(label, nm))
    if (is.null(m)) next
    ## installation cluster bootstrap for coefficient intervals
    ids <- unique(d$inst); cl <- split(seq_len(nrow(d)), d$inst)
    bs <- do.call(rbind, parallel::mclapply(seq_len(min(NBOOT, 1000)), function(i) {
      idx <- unlist(cl[sample(as.character(ids), length(ids), replace = TRUE)], use.names = FALSE)
      tryCatch(coef(cglm(f, d[idx, ])), error = function(e) rep(NA, length(coef(m))))
    }, mc.cores = NCORES))
    ci <- apply(bs, 2, stats::quantile, c(0.025, 0.975), na.rm = TRUE)
    coefs[[nm]] <- data.frame(sample = label, spec = nm, term = names(coef(m)), estimate = coef(m),
                              boot_lo = ci[1, ], boot_hi = ci[2, ], excludes_zero = ci[1, ] > 0 | ci[2, ] < 0)
    p <- fitted(m)
    ## leave one installation out, pooled
    lo <- do.call(rbind, parallel::mclapply(as.character(ids), function(k) {
      tr <- d$inst != k
      mm <- tryCatch(cglm(f, d[tr, ]), error = function(e) NULL)
      if (is.null(mm)) return(NULL)
      data.frame(inst = k, y = d$dead[!tr], p = predict(mm, d[!tr, ], type = "response"))
    }, mc.cores = NCORES))
    ann <- exp(predict(m, type = "link") - log(d$yip))          # annual hazard, offset removed
    sweep_surv <- sapply(c(1, 5, 10), function(t) mean(exp(-t * ann)))
    ## calibration by interval length is the check that the offset form holds
    yb <- cut(d$yip, unique(stats::quantile(d$yip, c(0, 1/3, 2/3, 1))), include.lowest = TRUE)
    calib_yip <- paste(sprintf("%s: %d obs / %.1f exp", levels(yb), as.integer(tapply(d$dead, yb, sum)), tapply(p, yb, sum)), collapse = "; ")
    base_rate <- mean(d$dead)
    brier <- mean((d$dead - p)^2)
    lo_ann <- loio(d, f, "dead", identity)
    res[[nm]] <- data.frame(sample = label, spec = nm, n = nrow(d), deaths = sum(d$dead), aic = AIC(m),
      auc_loio_annual = auc(lo_ann$y, lo_ann$p_ann), auc_within_interval = auc_within(lo_ann$y, lo_ann$p_ann, lo_ann$g),
      auc_apparent = auc(d$dead, p), auc_interval_only = base_auc,
      auc_loio_pooled = auc(lo$y, lo$p), loio_folds_scoreable = sum(tapply(lo$y, lo$inst, function(v) any(v == 1) && any(v == 0))),
      observed_events = sum(d$dead), expected_events = sum(p),
      brier = brier, brier_skill = 1 - brier / (base_rate * (1 - base_rate)),
      mean_annual_mortality = mean(1 - exp(-ann)),
      surv_1yr = sweep_surv[1], surv_5yr = sweep_surv[2], surv_10yr = sweep_surv[3],
      calibration_by_interval = calib_yip)
  }
  e5 <- tryCatch(eq5_row(d, label), error = function(e) { logmsg("eq5 row failed: ", conditionMessage(e)); NULL })
  if (!is.null(e5)) { wcsv(e5$coef, paste0("06_eq5_coefficients_", label, ".csv")); res$eq5 <- e5$stats; res$eq5dep <- e5$dep }
  list(stats = do.call(rbind, lapply(res, function(z) { for (k in setdiff(names(res[[1]]), names(z))) z[[k]] <- NA; z[names(res[[1]])] })), coefs = do.call(rbind, coefs))
}
out <- list()
b <- read_dep(F_SURV); if (!is.null(b)) out$baseline <- run(prep(b), "baseline")
r <- read_dep(F_SURV_RECOVERED); if (!is.null(r)) out$recovered <- run(prep(r), "recovered")
if (length(out)) {
  wcsv(do.call(rbind, lapply(out, `[[`, "stats")), "06_survival_respec_stats.csv")
  wcsv(do.call(rbind, lapply(out, `[[`, "coefs")), "06_survival_respec_coefficients.csv")
}
if (is.null(r)) logmsg("recovered survival sample not configured; respecification ran on the baseline only")
cat("done\n")
