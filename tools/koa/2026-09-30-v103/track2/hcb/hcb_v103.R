## hcb_v103.R (koa v103). Eq. 3 HCB_P (engine form) refit on the FIA crown frame with covariates rebuilt from HI_TREE (per subplot all species
## live list, BAPH x 4 subplot expansion) under each BAL definition; nls from HCB_P; plot-cluster bootstrap (500) SEs; compared with the deployed
## HCB_P on the same covariates. Deploy rule (RUN.md): refit deployed only if population average RMSE improves and every coefficient keeps its sign.
set.seed(20260930); W <- path.expand("~/jobs/koa_v103_20260930")
d <- read.csv(file.path(W, "frames/final/AK_HCB_v103.csv"), stringsAsFactors = FALSE); stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "latitude", "longitude", "x", "y")))
HCB_P <- c(b0 = 0.1684, b1 = 1.0146, b2 = -0.376, b3 = -0.0078, b4 = -0.3734, b5 = -0.221)
f_hcb <- function(p, HT, DBH, BAL, BAPH, BYI) { eta <- p[1] + p[2] * sqrt(HT / 100) + p[3] * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + p[4] * sqrt(pmax(BAL * BAPH + 1, 0)) + p[5] * log(BAPH + 1) + p[6] * log(pmax(BYI, 1) / 100); HT / (1 + exp(-eta)) }
rmse <- function(o, p) sqrt(mean((o - p)^2)); r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2)
d <- d[is.finite(d$HCB) & is.finite(d$HT) & d$HT > 0 & is.finite(d$BYI), ]; d$plot <- paste(d$Install, d$Plot)
cat("HCB frame rows", nrow(d), "plots", length(unique(d$plot)), "installations", length(unique(d$Install)), "\n")
R <- list(); CO <- list()
pred_dep_depcov <- f_hcb(HCB_P, d$HT, d$DBH, d$BAL_dep, d$BAPH_dep, d$BYI)
R[["deployed_depcov"]] <- data.frame(fit = "HCB_P deployed, deposited frame covariates", bal = "deposited", n = nrow(d), rmse = rmse(d$HCB, pred_dep_depcov), r2 = r2(d$HCB, pred_dep_depcov), bias = mean(pred_dep_depcov - d$HCB), signs_kept = NA)
for (b in c("d", "l", "c")) {
  bal <- d[[paste0("BAL", b)]]; dd <- data.frame(HCB = d$HCB, HT = d$HT, DBH = d$DBH, BAL = bal, BAPH = d$BAPH_hi, BYI = d$BYI, plot = d$plot)
  p0 <- f_hcb(HCB_P, dd$HT, dd$DBH, dd$BAL, dd$BAPH, dd$BYI)
  R[[paste0("dep_", b)]] <- data.frame(fit = "HCB_P deployed, rebuilt covariates", bal = b, n = nrow(dd), rmse = rmse(dd$HCB, p0), r2 = r2(dd$HCB, p0), bias = mean(p0 - dd$HCB), signs_kept = NA)
  fm <- HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b3 * sqrt(pmax(BAL * BAPH + 1, 0)) + b4 * log(BAPH + 1) + b5 * log(pmax(BYI, 1) / 100))))
  m <- tryCatch(nls(fm, data = dd, start = as.list(HCB_P), control = nls.control(maxiter = 500, warnOnly = TRUE)), error = function(e) NULL)
  if (is.null(m)) { cat("nls failed", b, "\n"); next }
  cf <- coef(m); p1 <- fitted(m); sk <- all(sign(cf) == sign(HCB_P))
  ids <- unique(dd$plot); sp <- split(seq_len(nrow(dd)), dd$plot)
  B <- t(replicate(500, { idx <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE); tryCatch(coef(nls(fm, data = dd[idx, ], start = as.list(cf), control = nls.control(maxiter = 200, warnOnly = TRUE))), error = function(e) rep(NA, 6)) }))
  CO[[b]] <- data.frame(bal = b, term = names(cf), HCB_P = HCB_P, estimate = cf, se_nls = summary(m)$coefficients[, 2], boot_se = apply(B, 2, sd, na.rm = TRUE),
                        lo95 = apply(B, 2, quantile, 0.025, na.rm = TRUE), hi95 = apply(B, 2, quantile, 0.975, na.rm = TRUE), sign_kept = sign(cf) == sign(HCB_P), row.names = NULL)
  CO[[b]]$dz_boot <- (CO[[b]]$estimate - HCB_P) / CO[[b]]$boot_se
  R[[paste0("refit_", b)]] <- data.frame(fit = "HCB_P form refit (nls)", bal = b, n = nrow(dd), rmse = rmse(dd$HCB, p1), r2 = r2(dd$HCB, p1), bias = mean(p1 - dd$HCB), signs_kept = sk)
  cat(b, "deployed RMSE", round(rmse(dd$HCB, p0), 4), "refit RMSE", round(rmse(dd$HCB, p1), 4), "signs kept", sk, "coef", sprintf("%.4f", cf), "\n")
}
R <- do.call(rbind, R); CO <- do.call(rbind, CO); print(R); print(CO)
write.csv(R, "hcb_fit_stats_v103.csv", row.names = FALSE); write.csv(CO, "hcb_coefficients_v103.csv", row.names = FALSE)
cat("HCB DONE\n")
