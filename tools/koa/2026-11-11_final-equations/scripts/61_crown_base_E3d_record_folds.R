# 61_crown_base_E3d_record_folds.R  Held-out check of E3d (HCB = min(exp(d0 + d1 ln HT), 0.98 HT)) on the folds of record (make_folds, seed 20261110),
# with the equivalence test of utils.R (seed 1, 2,000 resamples). The first three lines reproduce the logged held-out RMSE of C0, C1 and C2
# (script 34) as a check that the folds match. Also scores the one-parameter form HCB = c HT. Frame: hcb_frame.csv (see CHANGELOG 1.14.2).
suppressMessages(library(data.table)); source("scripts/utils.R")
d <- fread("hcb_frame.csv"); d[, `:=`(Data = "FIA", planted = 0, pid = paste("FIA", Install, Plot, sep = "|"))]; d[, inst := paste(Data, Install)]
d <- merge(d, make_folds(d), by = "inst")
predR <- function(b, dd, tm) dd$HT / (1 + exp(as.numeric(cbind(1, if (length(tm)) as.matrix(dd[, ..tm])) %*% b)))
fitR <- function(dd, tm) { b <- optim(c(1, rep(0, length(tm))), function(b) sum((dd$HCB - predR(b, dd, tm))^2), method = "BFGS", control = list(maxit = 1000, reltol = 1e-12)); b$par }
d[, `:=`(lH = log(HT), dh = DBH / HT)]
for (tm in list(character(0), "lH", c("lH", "dh"))) { cv <- rbindlist(lapply(1:10, function(k) { b <- fitR(d[fold != k], tm); te <- d[fold == k]; data.table(obs = te$HCB, p = predR(b, te, tm)) })); cat("check", paste(tm, collapse = "+"), "held-out RMSE", round(sqrt(mean((cv$obs - cv$p)^2)), 4), "\n") }
predD <- function(b, dd) pmin(exp(b[1] + b[2] * log(dd$HT)), 0.98 * dd$HT)
fitD <- function(dd) optim(c(-1.5, 1), function(b) sum((dd$HCB - predD(b, dd))^2), method = "BFGS", control = list(maxit = 2000, reltol = 1e-12))$par
b <- fitD(d); cat("E3d full fit:", round(b, 5), "\n")
cv <- rbindlist(lapply(1:10, function(k) { bb <- fitD(d[fold != k]); te <- d[fold == k]; data.table(obs = te$HCB, pred = predD(bb, te), HT = te$HT, pid = te$pid) }))
m <- metrics(cv$obs, cv$pred); e <- equiv_boot(cv$obs, cv$pred, cv$pid, nboot = 2000)
r2 <- 1 - sum((cv$obs - cv$pred)^2) / sum((cv$obs - mean(cv$obs))^2)
print(cbind(m, e[, .(bias_rel, b0_lo, b0_hi, slope, b1_lo, b1_hi, pass_int, pass_slope)], r2 = r2))
cat("held-out RMSE on the crown ratio scale:", round(cv[, sqrt(mean(((1 - obs / HT) - (1 - pred / HT))^2))], 3), "\n")
cat("crown ratio implied at HT 5, 10, 20, 30 m:", round(1 - predD(b, data.table(HT = c(5, 10, 20, 30))) / c(5, 10, 20, 30), 3), "\n")
cat("residual SD (m):", round(sd(d$HCB - predD(b, d)), 3), "\n")
fitP <- function(dd) sum(dd$HCB * dd$HT) / sum(dd$HT^2)
cvp <- rbindlist(lapply(1:10, function(k) { c0 <- fitP(d[fold != k]); te <- d[fold == k]; data.table(obs = te$HCB, pred = c0 * te$HT, pid = te$pid) }))
cat("proportional HCB = c HT: c =", round(fitP(d), 4), " held-out RMSE", round(sqrt(mean((cvp$obs - cvp$pred)^2)), 4), "\n"); print(equiv_boot(cvp$obs, cvp$pred, cvp$pid, nboot = 2000)[, .(bias_rel, slope, b1_lo, b1_hi, pass_int, pass_slope)])
