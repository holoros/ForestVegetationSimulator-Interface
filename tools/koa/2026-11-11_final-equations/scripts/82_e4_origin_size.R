# 82_e4_origin_size.R  koa v142, red team A5: does the planted contrast in Eq. 5 (E4r, diameter increment) fade with size?
# Candidates, fitted on the v142 frames with the 22t machinery (same frame, censoring, S1, weights, projection over the interval):
#   E4r     dDBH = exp(b0 + b1 ln(DBH+1) + b2 DBH + b3 (BAL/BA) RD + b4 ln(BYI) + b5 planted)            (deployed form)
#   E4r-pD  E4r + b6 planted x DBH                                                                   (red team suggestion)
#   E4r-pL  E4r + b6 planted x ln(DBH+1)
# Rule written before the fit (21 November 2026): a fading form is adopted only if (1) b6 < 0, (2) held-out installation RMSE of annual
# increment (S1 and E4 refitted in each fold) falls by at least 1% against E4r, (3) held-out bias for planted plots does not grow in magnitude,
# and (4) the pseudo-AIC (common final weights of E4r) falls by more than 2. If both pass, the lower held-out RMSE wins. Otherwise E4r stays and
# the test is reported. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_1150_20261121/scripts/22t_rdbyi_final.R"); eval(parse(text = L[1:27]))
G0 <- fitg(d, bgs); b0 <- G0$b; cat("E4r refit on v142 frames: convergence", G0$conv, "delta", round(G0$delta, 4), "\n"); print(round(b0, 5))
mk <- function(extra) {
  xmx <- function(S, BAL, BA, SDI, sm, byi, pl) { X <- cbind(1, log(S + 1), S, BAL / pmax(BA, 1e-6) * SDI / sm, log(byi), pl); cbind(X, if (extra == "pD") pl * S else if (extra == "pL") pl * log(S + 1) else NULL) }
  pj <- function(b, dd, sm = dd$sm) { S <- dd$S0; n <- dd$yip; acc <- numeric(nrow(dd)); for (t in seq_len(max(n))) { a <- t <= n; if (!any(a)) break; w <- (t - 1) / n[a]; iw <- function(v0, v1) (1 - w) * v0[a] + w * v1[a]
      g <- exp(xmx(S[a], iw(dd$BAL, dd$e_BAL), iw(dd$BA_koa, dd$e_BA_koa), iw(dd$SDI_koa, dd$e_SDI_koa), sm[a], dd$BYI[a], dd$planted[a]) %*% b); S[a] <- S[a] + g; acc[a] <- acc[a] + g }; list(end = S, gbar = acc / n) }
  ft <- function(dd, b, sm = dd$sm, passes = 3) { w <- 1 / dd$yip; dl <- 0; conv <- NA; for (it in seq_len(passes)) { o <- optim(b, function(bb) sum(w * (dd$S1 - pj(bb, dd, sm)$end)^2), method = "BFGS", control = list(maxit = 500, reltol = 1e-10)); b <- o$par; conv <- o$convergence
      pr <- pj(b, dd, sm); r <- dd$S1 - pr$end; dl <- max(0, min(1.5, coef(lm(log(pmax(r^2 / dd$yip, 1e-8)) ~ log(pmax(pr$gbar, 0.01))))[[2]] / 2)); w <- 1 / (dd$yip * pmax(pr$gbar, 0.01)^(2 * dl)) }; list(b = b, delta = dl, conv = conv) }
  list(pj = pj, ft = ft) }
wfin <- { pr <- proj(b0, d); 1 / (d$yip * pmax(pr$gbar, 0.01)^(2 * G0$delta)) }
out <- list(); coefs <- list()
for (v in c("E4r", "pD", "pL")) { M_ <- mk(if (v == "E4r") "none" else v); st <- if (v == "E4r") unname(b0) else c(unname(b0), 0)
  Fv <- M_$ft(d, st); bv <- Fv$b; wsse <- sum(wfin * (d$S1 - M_$pj(bv, d)$end)^2); k <- length(bv); n <- nrow(d)
  cv <- rbindlist(parallel::mclapply(sort(unique(d$fold_s)), function(kk) { bk <- s1fit(M[fold != kk]); trn <- d[fold_s != kk]; te <- d[fold_s == kk]; smt <- s1p(bk, trn$lbyi, trn$planted); sme <- s1p(bk, te$lbyi, te$planted); b <- M_$ft(trn, bv, smt)$b
    te2 <- copy(te); te2[, `:=`(e_BAL = BAL, e_BA_koa = BA_koa, e_SDI_koa = SDI_koa)]; data.table(planted = te$planted, obs = (te$S1 - te$S0) / te$yip, pred = (M_$pj(b, te2, sme)$end - te$S0) / te$yip) }, mc.cores = 5))
  out[[v]] <- data.table(form = v, k = k, conv = Fv$conv, delta = Fv$delta, b5 = bv[6], b6 = if (k > 6) bv[7] else NA_real_, pseudoAIC = n * log(wsse / n) + 2 * k,
    cv_rmse = sqrt(mean((cv$obs - cv$pred)^2)), cv_bias = mean(cv$obs - cv$pred), cv_bias_planted = cv[planted == 1, mean(obs - pred)], cv_bias_natural = cv[planted == 0, mean(obs - pred)],
    mult_d5 = exp(bv[6] + if (k > 6) bv[7] * (if (v == "pD") 5 else log(6)) else 0), mult_d20 = exp(bv[6] + if (k > 6) bv[7] * (if (v == "pD") 20 else log(21)) else 0),
    mult_d40 = exp(bv[6] + if (k > 6) bv[7] * (if (v == "pD") 40 else log(41)) else 0), mult_d60 = exp(bv[6] + if (k > 6) bv[7] * (if (v == "pD") 60 else log(61)) else 0))
  coefs[[v]] <- data.table(form = v, term = paste0("b", seq_along(bv) - 1), value = bv); cat(v, "done\n"); flush.console() }
R <- rbindlist(out); R[, dAIC := pseudoAIC - pseudoAIC[form == "E4r"]]; R[, rmse_change := cv_rmse / cv_rmse[form == "E4r"] - 1]
R[, pass := form != "E4r" & !is.na(b6) & b6 < 0 & rmse_change <= -0.01 & abs(cv_bias_planted) <= abs(cv_bias_planted[form == "E4r"]) & dAIC < -2]
print(R, digits = 4); fwrite(R, "out/e4_origin_size_82.csv"); fwrite(rbindlist(coefs), "out/e4_origin_size_82_coef.csv")
win <- if (any(R$pass)) R[pass == TRUE][which.min(cv_rmse), form] else "E4r"; cat("RULE OUTCOME:", win, if (win == "E4r") "(no fading form passed; constant multiplier retained)" else "adopted by the rule", "\n"); cat("82 done\n")
