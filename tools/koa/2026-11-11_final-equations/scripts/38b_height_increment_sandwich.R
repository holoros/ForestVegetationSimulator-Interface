# 38b_height_increment_sandwich.R  Plot-cluster robust (sandwich) standard errors of the adopted height increment equation (B2), computed at the
# full-frame estimates with the weights of the last pass: V = (J'WJ)^-1 [sum over plots of s_p s_p'] (J'WJ)^-1 with s_p = J_p' W_p r_p and a
# small-sample factor P/(P-1). An interim interval while the plot-cluster bootstrap of script 38 runs. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/33b_height_increment_round2.R"); eval(parse(text = L[5:34]))
R <- readRDS("out/height_increment_33b.rds"); th <- R$FH$B2$th; dl <- R$FH$B2$delta; g <- G$B2; pr <- proj(th, g); r <- prs$H1 - pr$end; w <- prs$w0 / (prs$yip * pmax(pr$gbar, 0.01)^(2 * dl))
J <- sapply(seq_along(th), function(j) { h <- 1e-4 * max(1, abs(th[j])); a <- th; b <- th; a[j] <- a[j] + h; b[j] <- b[j] - h; (proj(a, g)$end - proj(b, g)$end) / (2 * h) })
A <- crossprod(J * sqrt(w)); sc <- rowsum(J * (w * r), prs$pid); P <- nrow(sc); Bm <- crossprod(sc) * P / (P - 1); Ai <- solve(A); V <- Ai %*% Bm %*% Ai; se <- sqrt(diag(V))
tab <- data.table(par = names(th), est = th, se = se, lo = th - qt(0.975, P - 1) * se, hi = th + qt(0.975, P - 1) * se); cat("plots (clusters):", P, "; pairs:", n, "; variance power:", round(dl, 3), "\n"); print(tab[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 4) else v)])
dm <- function(f) { gr <- sapply(seq_along(th), function(j) { h <- 1e-5; a <- th; b <- th; a[j] <- a[j] + h; b[j] <- b[j] - h; (f(a) - f(b)) / (2 * h) }); s <- sqrt(as.numeric(t(gr) %*% V %*% gr)); c(est = f(th), lo = f(th) - qt(0.975, P - 1) * s, hi = f(th) + qt(0.975, P - 1) * s) }
bq <- c(64, 121, 156, 248, 309, 386); for (q in bq) { z <- exp(dm(function(b) b[1] + b[2] * log(q))); cat("asymptote (m) at BYI", q, ":", round(z, 1), "\n") }
cat("planted rate multiplier exp(k_pl):", round(exp(dm(function(b) b[6])), 2), "\n"); cat("shape m = exp(lc):", round(exp(dm(function(b) b[4])), 3), "; rate k natural (per yr):", round(exp(dm(function(b) b[3])), 4), "\n")
fwrite(tab, "out/height_increment_B2_sandwich.csv"); cat("done\n")
