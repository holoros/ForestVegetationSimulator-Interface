# 63_crown_base_E3e.R  Crown base refit on the corrected response (koa 1.14.3, November 21, 2026).
# The 360 US Forest Service FIA crown records store HCB = HT x CR, where CR is the FIA live (compacted) crown ratio, so the stored value is live
# crown length. Every crown base fit from the 2025 originals (koa.R: koa5$HCB = koa5$HT*(koa5$CR/100)) through E3d modeled crown length.
# Crown base is HT x (1 - CR). This script refits the forms the system can apply (koa-only competition, BYI, no climate) on the corrected response,
# on the folds of record (make_folds, as script 61 and 62b), applies the rule of record (among sign-consistent forms, fewest terms within 2% of the
# lowest held-out RMSE), bootstraps the pick by plot cluster (2,000 resamples), scores the manuscript equivalence tests (plots resampled 2,000 times,
# 90% interval within 25%), and writes the E3e rows into koa_rdbyi_equations.csv in place of E3d. Expected signs on eta of HCB = HT/(1+exp(eta)):
# slenderness, BAL and BA lower eta (raise the crown base). Run from ~/jobs/koa_final_eq_20261110.
suppressMessages(library(data.table)); source("scripts/utils.R")
fr <- fread("2026-11-20_koa-hcb-frame_DATA.csv"); fr[, `:=`(Data = "FIA", planted = 0, pid = paste("FIA", Install, Plot, sep = "|"))]; fr[, inst := paste(Data, Install)]
rk <- RNGkind(); RNGkind("Mersenne-Twister", "Inversion", "Rejection"); fr <- merge(fr, make_folds(fr), by = "inst"); RNGkind(rk[1], rk[2], rk[3])
stopifnot(nrow(fr) == 360, all(abs(fr$HCB - fr$HT * fr$CR) < 1e-6)); fr[, `:=`(CL = HCB, HCB = HT * (1 - CR))]
cat("stored HCB equals HT x CR (crown length) for all", nrow(fr), "records; corrected crown ratio 5th, 25th, 50th, 75th, 95th percentile:", round(quantile(fr$CR, c(.05, .25, .5, .75, .95)), 3), "\n")
cat("Spearman correlation of crown ratio with koa BAL", round(cor(fr$CR, fr$BAL_k, method = "spearman"), 3), "and with all-species BAL", round(cor(fr$CR, fr$BAL_all, method = "spearman"), 3), "\n\n")
sdimax <- exp(5.64535004933422 + 0.267708773204307 * log(fr$BYI))
fr[, `:=`(lH = log(HT), lsl = log(HT / DBH), dh = DBH / HT, sH = sqrt(HT / 100), sbalba_k = sqrt(BAL_k * BA_k + 1), lba_k = log(BA_k + 1), bal_k = BAL_k, lb = log(BYI), rd_k = SDI_k / sdimax)]
F <- list(
  E3d_D0   = list(l = "exp",   t = c("lH"), s = c(0)),
  H25k     = list(l = "logis", t = c("sH", "lsl", "sbalba_k", "lba_k"), s = c(0, -1, -1, -1)),
  H25k_BYI = list(l = "logis", t = c("sH", "lsl", "sbalba_k", "lba_k", "lb"), s = c(0, -1, -1, -1, 0)),
  M5k      = list(l = "logis", t = c("lsl", "sbalba_k", "lba_k"), s = c(-1, -1, -1)),
  M5k_BYI  = list(l = "logis", t = c("lsl", "sbalba_k", "lba_k", "lb"), s = c(-1, -1, -1, 0)),
  L0       = list(l = "logis", t = c("lH"), s = c(0)),
  L8       = list(l = "logis", t = c("lH", "bal_k"), s = c(0, -1)),
  L8_BYI   = list(l = "logis", t = c("lH", "bal_k", "lb"), s = c(0, -1, 0)),
  L8_lba   = list(l = "logis", t = c("lH", "bal_k", "lba_k"), s = c(0, -1, -1)),
  L8_rd    = list(l = "logis", t = c("lH", "bal_k", "rd_k"), s = c(0, -1, -1)),
  L9       = list(l = "logis", t = c("lH", "dh", "bal_k", "lba_k"), s = c(0, 1, -1, -1)),
  L13      = list(l = "logis", t = c("lsl", "bal_k"), s = c(-1, -1)),
  L14      = list(l = "logis", t = c("lH", "lsl", "bal_k"), s = c(0, -1, -1)))
pred <- function(b, dd, f) { eta <- as.numeric(cbind(1, as.matrix(dd[, f$t, with = FALSE])) %*% b); if (f$l == "exp") pmin(exp(eta), 0.98 * dd$HT) else dd$HT / (1 + exp(eta)) }
fit <- function(dd, f) { lo <- c(-Inf, ifelse(f$s > 0, 0, -Inf)); hi <- c(Inf, ifelse(f$s < 0, 0, Inf))
  st <- if (f$l == "exp") c(log(mean(dd$HCB)) - log(mean(dd$HT)), 1) else c(qlogis(1 - mean(dd$HCB / dd$HT)), rep(0, length(f$t)))
  o <- optim(st, function(b) sum((dd$HCB - pred(b, dd, f))^2), method = "L-BFGS-B", lower = lo, upper = hi, control = list(maxit = 10000, factr = 1e5)); setNames(o$par, c("b0", f$t)) }
res <- rbindlist(lapply(names(F), function(nm) { f <- F[[nm]]; b <- fit(fr, f); f0 <- f; f0$s <- f0$s * 0; bf <- fit(fr, f0)
  cv <- rbindlist(lapply(1:10, function(k) { bb <- fit(fr[fold != k], f); te <- fr[fold == k]; data.table(obs = te$HCB, p = pred(bb, te, f), HT = te$HT) }))
  data.table(form = nm, k = length(b), terms = paste(f$t, collapse = "+"), coefs = paste(sprintf("%.4f", b), collapse = " "), free_coefs = paste(sprintf("%.4f", bf), collapse = " "),
             rmse = sqrt(mean((cv$obs - cv$p)^2)), bias = mean(cv$obs - cv$p), slope = unname(coef(lm(obs ~ p, cv))[2]), r2 = 1 - sum((cv$obs - cv$p)^2) / sum((cv$obs - mean(cv$obs))^2),
             cr_rmse = sqrt(mean(((cv$obs - cv$p) / cv$HT)^2)), at_bound = any(abs(b[-1][f$s != 0]) < 1e-8)) }))
setorder(res, rmse); options(width = 250); print(res, digits = 4)
ok <- res[at_bound == FALSE]; pick <- ok[rmse <= min(rmse) * 1.02][order(k, rmse)][1]
cat("\nrule among sign-consistent forms on the folds of record: fewest terms within 2% of the lowest held-out RMSE ->", pick$form, "\n")
f <- F[[pick$form]]; b0 <- fit(fr, f); idx <- split(seq_len(nrow(fr)), fr$pid); set.seed(20261121)
BO <- t(replicate(2000, { ix <- unlist(idx[sample(names(idx), length(idx), TRUE)], use.names = FALSE); fit(fr[ix], f) })); if (nrow(BO) == 1) BO <- t(BO)
cat("\nplot-cluster bootstrap (2,000 resamples) of", pick$form, "\n"); print(round(rbind(est = b0, se = apply(BO, 2, sd), lo = apply(BO, 2, quantile, .025), hi = apply(BO, 2, quantile, .975), at_bound = colMeans(abs(BO) < 1e-8)), 4))
cv <- rbindlist(lapply(1:10, function(k) { bb <- fit(fr[fold != k], f); te <- fr[fold == k]; data.table(pid = te$pid, HT = te$HT, obs = te$HCB, pred = pred(bb, te, f)) }))
cvd <- rbindlist(lapply(1:10, function(k) { bb <- fit(fr[fold != k], F$E3d_D0); te <- fr[fold == k]; data.table(pid = te$pid, HT = te$HT, obs = te$HCB, pred = pred(bb, te, F$E3d_D0)) }))
eqv <- function(cv) { ix0 <- split(seq_len(nrow(cv)), cv$pid); set.seed(20261121)
  B <- t(replicate(2000, { ix <- unlist(ix0[sample(names(ix0), length(ix0), TRUE)], use.names = FALSE); z <- cv[ix]; c(rb = mean(z$obs - z$pred) / mean(z$obs), sl = unname(coef(lm(obs ~ pred, z))[2])) }))
  q <- apply(B, 2, quantile, c(.05, .95)); data.table(n = nrow(cv), bias = mean(cv$obs - cv$pred), rmse = sqrt(mean((cv$obs - cv$pred)^2)), r2 = 1 - sum((cv$obs - cv$pred)^2) / sum((cv$obs - mean(cv$obs))^2),
    cr_rmse = sqrt(mean(((cv$obs - cv$pred) / cv$HT)^2)), slope = unname(coef(lm(obs ~ pred, cv))[2]), sl_lo = q[1, 2], sl_hi = q[2, 2], rb = mean(cv$obs - cv$pred) / mean(cv$obs), rb_lo = q[1, 1], rb_hi = q[2, 1],
    bias_test = ifelse(q[1, 1] > -0.25 & q[2, 1] < 0.25, "Pass", "Fail"), slope_test = ifelse(q[1, 2] > 0.75 & q[2, 2] < 1.25, "Pass", "Fail")) }
EQ <- rbind(cbind(model = pick$form, eqv(cv)), cbind(model = "E3d form, corrected response", eqv(cvd))); cat("\nheld-out equivalence tests on the folds of record (plots resampled 2,000 times)\n"); print(EQ, digits = 3)
suppressMessages(library(nlme)); fx <- as.formula(paste("HCB ~ HT/(1+exp(", paste(c("b0", paste0("b", seq_along(f$t), "*", f$t)), collapse = "+"), "))")); st <- setNames(as.numeric(b0), c("b0", paste0("b", seq_along(f$t))))
mm <- try(nlme(fx, data = as.data.frame(fr), fixed = as.formula(paste(paste(names(st), collapse = "+"), "~1")), random = b0 ~ 1 | inst/pid, start = st, control = nlmeControl(maxIter = 500, returnObject = TRUE)), silent = TRUE)
if (!inherits(mm, "try-error")) { cat("\nmixed-effects check, random intercept by installation and plot (report only)\n"); print(summary(mm)$tTable, digits = 4) }
EQS <- fread("release_v1143/koa_rdbyi_equations.csv"); fwrite(EQS, sprintf("release_v1143/koa_rdbyi_equations_PREV_%s.csv", format(Sys.Date(), "%Y%m%d")))
new <- data.table(equation = "E3e_crown_base", term = names(b0), estimate = as.numeric(b0), se_model = NA_real_, se_plot_bootstrap = apply(BO, 2, sd), lo95 = apply(BO, 2, quantile, .025), hi95 = apply(BO, 2, quantile, .975), n_boot = 2000)
EQS <- rbind(EQS[!grepl("^E3", equation)], new, fill = TRUE); fwrite(EQS, "release_v1143/koa_rdbyi_equations.csv"); cat("\nkoa_rdbyi_equations.csv: E3d rows replaced by E3e\n"); print(new, digits = 5)
saveRDS(list(res = res, pick = pick$form, b = b0, BO = BO, cv = cv, cvd = cvd, EQ = EQ, fr = fr), "out/crown_base_63.rds"); fwrite(res, "out/crown_base_forms_63.csv"); fwrite(EQ, "out/crown_base_equivalence_63.csv"); cat("done\n")
