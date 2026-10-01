## surv_refit.R (2026-09-18, track 2). Eq. 5 (Table 6 vector, alive response, cloglog, offset ln YIP, on the deposit survival table) and
## Eq. 5a (the s06 respecification, death response with the same terms and offset, on the recovered ii frame) reproduced on the record
## frames with the fitting code path of ~/jobs/koa_origin_20260916/s06/06_survival_respec.R (damped Fisher scoring start from
## regenerate_table6.R handed to glm, same filter, same leave one installation out folds and AUC definitions), then refit on the v102 frames.
suppressPackageStartupMessages(library(parallel))
set.seed(20260916)
NCORES <- 4L
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
.src <- parse("surv/regenerate_table6_REFERENCE_COPY.R")
for (.e in .src) if (is.call(.e) && identical(.e[[1]], as.name("<-")) && is.name(.e[[2]]) && as.character(.e[[2]]) %in% c("cll_loglik", "cll_pieces", "fit_cloglog")) eval(.e, globalenv())
SURV_S9 <- c(b0 = 14.102, b1 = 0.130, b2 = -4.516, b3 = 6.684, b4 = 14.218, b5 = -2.806, b6 = 2.649, b7 = -21.188)
auc <- function(y, s) { r <- rank(s); n1 <- sum(y == 1); n0 <- sum(y == 0); if (n1 == 0 || n0 == 0) return(NA_real_); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
auc_within <- function(y, s, g) { num <- 0; den <- 0
  for (idx in split(seq_along(y), g)) { yy <- y[idx]; n1 <- sum(yy == 1); n0 <- sum(yy == 0); if (n1 == 0 || n0 == 0) next
    r <- rank(s[idx]); num <- num + (sum(r[yy == 1]) - n1 * (n1 + 1) / 2); den <- den + n1 * n0 }
  if (den == 0) NA_real_ else num / den }
prep <- function(f) {
  d <- read.csv(f, stringsAsFactors = FALSE); stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "latitude", "longitude")))
  ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(d[[k]])))
  d <- d[ok & d$yip > 0 & d$ht > 0 & d$dbh > 0 & d$cr > 0 & d$byi > 0, ]
  d$dead <- 1 - d$alive; d$inst <- paste(d$source, d$inst, sep = "/"); d$grp <- paste(d$inst, d$plot, d$t0, d$t1); d
}
NC <- c(conv = 0, nconv = 0)
cglm <- function(f, data) {
  X <- model.matrix(f, data); y <- model.response(model.frame(f, data))
  pre <- fit_cloglog(X, as.numeric(y), log(data$yip))
  m <- suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = data, offset = log(yip), start = pre$beta, control = glm.control(maxit = 200, epsilon = 1e-8)))
  attr(m, "converged_both") <- m$converged && pre$converged; m
}
TERMS <- ~ ht + log(ht) + rht + log(cr) + log(ht / dbh) + log(byi / 100) + I(byi / 1000)
F_ALIVE <- update(TERMS, alive ~ .); F_DEAD <- update(TERMS, dead ~ .)
loio <- function(d, f, score) { ids <- unique(d$inst)
  do.call(rbind, mclapply(as.character(ids), function(k) { tr <- d$inst != k
    mm <- tryCatch(cglm(f, d[tr, ]), error = function(e) NULL); if (is.null(mm)) return(NULL)
    eta <- predict(mm, d[!tr, ], type = "link") - log(d$yip[!tr])
    data.frame(inst = k, g = d$grp[!tr], y = d$dead[!tr], p_int = score(predict(mm, d[!tr, ], type = "response")), p_ann = score(1 - exp(-exp(eta))), conv = attr(mm, "converged_both")) }, mc.cores = NCORES)) }
one <- function(d, eq, frame) {
  f <- if (eq == "Eq5") F_ALIVE else F_DEAD; score <- if (eq == "Eq5") function(p) 1 - p else identity
  m <- cglm(f, d); lo <- loio(d, f, score)
  p_death_int <- if (eq == "Eq5") 1 - fitted(m) else fitted(m)
  ## installation cluster bootstrap for coefficient SEs (1,000 as s06 min(NBOOT, 1000))
  ids <- unique(d$inst); cl <- split(seq_len(nrow(d)), d$inst)
  bs <- do.call(rbind, mclapply(seq_len(1000), function(i) { idx <- unlist(cl[sample(as.character(ids), length(ids), replace = TRUE)], use.names = FALSE)
    tryCatch(coef(cglm(f, d[idx, ])), error = function(e) rep(NA, length(coef(m)))) }, mc.cores = NCORES))
  list(coef = data.frame(eq = eq, frame = frame, term = names(coef(m)), estimate = coef(m), se_glm = sqrt(diag(vcov(m))), boot_se = apply(bs, 2, sd, na.rm = TRUE),
                         boot_lo = apply(bs, 2, quantile, 0.025, na.rm = TRUE), boot_hi = apply(bs, 2, quantile, 0.975, na.rm = TRUE), row.names = NULL),
       stat = data.frame(eq = eq, frame = frame, response = if (eq == "Eq5") "alive" else "dead", n = nrow(d), deaths = sum(d$dead), installations = length(ids), aic = AIC(m), converged_glm = m$converged, converged_both = attr(m, "converged_both"),
                         auc_apparent = auc(d$dead, p_death_int), auc_loio_pooled = auc(lo$y, lo$p_int), auc_loio_annual = auc(lo$y, lo$p_ann), auc_within_interval = auc_within(lo$y, lo$p_ann, lo$g),
                         loio_folds = length(unique(lo$inst)), loio_folds_converged = sum(tapply(lo$conv, lo$inst, function(v) v[1])), expected_deaths = sum(p_death_int),
                         mean_annual_mortality = mean(1 - exp(-exp(predict(m, type = "link") - log(d$yip)))) * (if (eq == "Eq5") NA else 1)))
}
V2 <- "~/jobs/koa_v102_20260918/"
FR <- list(Eq5 = c(v102 = paste0(V2, "frames/surv_baseline_rebuilt_v102.csv"), v103 = "../frames/final/surv_baseline_rebuilt_v103.csv"),
           Eq5a = c(v102 = paste0(V2, "frames/surv_recovered_ii_v102.csv"), v103 = "../frames/final/surv_recovered_ii_v103.csv"))
CO <- list(); ST <- list()
for (eq in names(FR)) for (frame in names(FR[[eq]])) {
  d <- prep(FR[[eq]][[frame]]); logm(eq, frame, "records", nrow(d), "deaths", sum(d$dead), "installations", length(unique(d$inst)))
  r <- one(d, eq, frame); CO[[paste(eq, frame)]] <- r$coef; ST[[paste(eq, frame)]] <- r$stat
  logm(eq, frame, "coef", paste(sprintf("%.4f", r$coef$estimate), collapse = " "), "AUC app", round(r$stat$auc_apparent, 4), "loio annual", round(r$stat$auc_loio_annual, 4), "within", round(r$stat$auc_within_interval, 4))
}
CO <- do.call(rbind, CO); ST <- do.call(rbind, ST)
write.csv(CO, "out/surv_coefficients.csv", row.names = FALSE); write.csv(ST, "out/surv_stats.csv", row.names = FALSE)
## reproduction gate: the v102 vectors of record (koa_v102_20260918/track2/out/surv_coefficients.csv) on the v102 frames to 1e-6, and AIC, AUCs to 1e-6
R2C <- read.csv(paste0(V2, "track2/out/surv_coefficients.csv")); R2S <- read.csv(paste0(V2, "track2/out/surv_stats.csv"))
rc <- merge(CO[CO$frame == "v102", c("eq", "term", "estimate", "se_glm")], R2C[R2C$frame == "v102", c("eq", "term", "estimate")], by = c("eq", "term"), suffixes = c("", "_v102"))
rc$abs_diff <- abs(rc$estimate - rc$estimate_v102)
rs <- merge(ST[ST$frame == "v102", c("eq", "aic", "auc_apparent", "auc_loio_annual", "auc_within_interval")], R2S[R2S$frame == "v102", c("eq", "aic", "auc_apparent", "auc_loio_annual", "auc_within_interval")], by = "eq", suffixes = c("", "_v102"))
print(rc); print(rs); write.csv(rc, "out/surv_reproduction_coef.csv", row.names = FALSE); write.csv(rs, "out/surv_reproduction_stats.csv", row.names = FALSE)
ok <- max(rc$abs_diff) < 1e-6 && max(abs(rs$aic - rs$aic_v102), abs(rs$auc_apparent - rs$auc_apparent_v102), abs(rs$auc_loio_annual - rs$auc_loio_annual_v102)) < 1e-6
logm("SURVIVAL REPRODUCTION v102 max abs coef diff", max(rc$abs_diff), if (ok) "PASS" else "FAIL")
print(ST[, c("eq", "frame", "n", "deaths", "installations", "aic", "converged_glm", "auc_apparent", "auc_loio_annual", "auc_within_interval", "auc_loio_pooled")])
logm("SURV DONE")
