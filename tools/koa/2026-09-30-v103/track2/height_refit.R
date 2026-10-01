## height_refit.R (2026-09-18, track 2). Static height Eq. 2 of record (HT_P in koa_equations.py, refit 2026-09-16, rDBH = DBH / DBH.max)
## reproduced with the fitting steps of ~/jobs/koa_redteam_20260916/02_height_refit.R on the record input (tree_join_record_rebuilt.csv,
## equal to derived/tree_join.csv on every cell) and then refit on the v102 input (tree_join_v102.csv built from the deduplicated tree
## table). Same filter (live stems, dbh > 0, expf > 0, rDBH over live stems of the plot-year, ht > 0, finite byi and baph), same nls start
## from the printed Table 3 vector, same nlme random intercept a0 on source/installation, same control. Statistics follow the record script.
suppressPackageStartupMessages(library(nlme))
set.seed(20260916)
HT_REFIT_PRINTED <- c(a0 = 25.37, a1 = 1.042, b = 0.0220, c = 0.814, g1 = 0.0556, g2 = -0.282)
REC <- c(a0 = 30.188188, a1 = 1.426287, b = 0.018401, c = 0.817994, g1 = 0.051108, g2 = -0.35086)
REC_SE <- c(a0 = 1.358658, a1 = 0.143993, b = 0.000936, c = 0.011012, g1 = 0.00495058, g2 = 0.0155361)
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2); rmse <- function(o, p) sqrt(mean((o - p)^2))
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
prep <- function(f) {
  tr <- read.csv(f, stringsAsFactors = FALSE, check.names = FALSE)
  lv <- tr[is.finite(tr$dbh) & tr$dbh > 0, ]
  lv <- lv[tolower(lv$status) == "live", ]
  lv <- lv[is.finite(lv$expf) & lv$expf > 0, ]
  lkey <- interaction(lv$source, lv$inst, lv$plot, lv$year, drop = TRUE)
  lv$rd_max <- lv$dbh / ave(lv$dbh, lkey, FUN = max)
  d <- lv[is.finite(lv$ht) & lv$ht > 0 & is.finite(lv$byi) & is.finite(lv$baph), ]
  d$grp_src <- factor(d$source); d$grp_inst <- factor(paste(d$source, d$inst, sep = "/"))
  d
}
fit_ht <- function(d) {
  form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
  fit_nls <- tryCatch(nls(form, data = d, start = as.list(HT_REFIT_PRINTED), control = nls.control(maxiter = 500, warnOnly = TRUE)), error = function(e) NULL)
  st2 <- if (!is.null(fit_nls)) coef(fit_nls) else HT_REFIT_PRINTED
  warns <- character()
  fit <- withCallingHandlers(nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = st2,
                                  control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)),
                             warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") })
  list(fit = fit, warns = unique(warns), nls_ok = !is.null(fit_nls))
}
RES <- list(); CO <- list()
for (tag in c("record", "v102")) {
  d <- prep(sprintf("height/tree_join_%s.csv", if (tag == "record") "record_rebuilt" else "v102"))
  logm(tag, "height sample", nrow(d), "records,", nlevels(d$grp_inst), "installations,", "PSP rows", sum(d$source == "PSP"))
  r <- fit_ht(d); fit <- r$fit
  logm(tag, "nls start ok", r$nls_ok, "warnings:", paste(r$warns, collapse = " | "))
  tt <- summary(fit)$tTable
  vc <- VarCorr(fit); vv <- suppressWarnings(as.numeric(vc[grep("^a0$|\\(Intercept\\)", rownames(vc)), 1])); vv <- vv[is.finite(vv)]
  p_cond <- as.numeric(fitted(fit)); p_pa <- as.numeric(fitted(fit, level = 0))
  orig <- ifelse(!is.na(d$planted) & d$planted == 1, "planted", "natural")
  CO[[tag]] <- data.frame(frame = tag, parameter = rownames(tt), estimate = tt[, "Value"], se = tt[, "Std.Error"], row.names = NULL)
  RES[[tag]] <- data.frame(frame = tag, n = nrow(d), n_inst = nlevels(d$grp_inst), n_psp = sum(d$source == "PSP"), logLik = as.numeric(logLik(fit)), AIC = AIC(fit),
    tau_source = sqrt(vv[1]), tau_inst = sqrt(vv[2]), sigma = fit$sigma,
    r2_cond = r2(d$ht, p_cond), rmse_cond = rmse(d$ht, p_cond), r2_pa = r2(d$ht, p_pa), rmse_pa = rmse(d$ht, p_pa),
    bias_pa = mean(d$ht - p_pa), bias_pa_natural = mean((d$ht - p_pa)[orig == "natural"]), bias_pa_planted = mean((d$ht - p_pa)[orig == "planted"]))
  write.csv(as.data.frame(vcov(fit)), sprintf("height/height_vcov_%s.csv", tag), row.names = FALSE)
  saveRDS(list(coef = fixef(fit), vcov = vcov(fit), sigma = fit$sigma), sprintf("height/height_fit_%s.rds", tag))
  logm(tag, "fixef", paste(names(fixef(fit)), sprintf("%.6f", fixef(fit)), collapse = " "))
}
CO <- do.call(rbind, CO); ST <- do.call(rbind, RES)
write.csv(CO, "out/height_coefficients.csv", row.names = FALSE); write.csv(ST, "out/height_stats.csv", row.names = FALSE)
## reproduction check at printed precision (6 decimals for a0..g1 as in koa_equations.py, 5 for g2 which prints -0.35086)
rc <- CO[CO$frame == "record", ]; dig <- c(a0 = 6, a1 = 6, b = 6, c = 6, g1 = 6, g2 = 5)
rc$record <- REC[rc$parameter]; rc$record_se <- REC_SE[rc$parameter]
rc$match <- round(rc$estimate, dig[rc$parameter]) == round(rc$record, dig[rc$parameter]); rc$abs_diff <- abs(rc$estimate - rc$record)
print(rc); logm("HEIGHT REPRODUCTION", if (all(rc$match)) "PASS" else "FAIL")
write.csv(rc, "out/height_reproduction_check.csv", row.names = FALSE)
## side by side
v <- CO[CO$frame == "v102", ]; s <- merge(rc[, c("parameter", "estimate", "se")], v[, c("parameter", "estimate", "se")], by = "parameter", suffixes = c("_record", "_v102"))
s <- s[match(names(REC), s$parameter), ]; s$dz_record_se <- (s$estimate_v102 - s$estimate_record) / s$se_record
write.csv(s, "out/height_side_by_side.csv", row.names = FALSE); print(s); print(ST)
logm("HEIGHT DONE")
