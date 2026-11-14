# 38c_boot_summary.R  Summary of the plot-cluster bootstrap of the height increment equation (script 38): the first KOA_NUSE completed resamples
# (resamples are independent draws in a fixed seeded order, so the first N are a bootstrap of N). Percentile 95% intervals of the coefficients
# and of derived quantities, beside the plot-cluster robust (sandwich) standard errors of script 38b for comparison.
B <- readRDS("out/boot_B2_38.rds"); NU <- as.integer(Sys.getenv("KOA_NUSE", nrow(B))); stopifnot(nrow(B) >= NU); B <- B[seq_len(NU), , drop = FALSE]; ok <- complete.cases(B) & B[, "conv"] == 0; K <- B[ok, 1:6]
S <- read.csv("out/height_increment_B2_sandwich.csv"); th <- S$est; q <- function(v) quantile(v, c(.025, .975)); cat("resamples used", NU, "; converged and kept", sum(ok), "\n")
tab <- data.frame(par = S$par, est = th, se_boot = apply(K, 2, sd), lo = apply(K, 2, function(v) q(v)[1]), hi = apply(K, 2, function(v) q(v)[2]), se_sandwich = S$se, n_boot = sum(ok)); print(cbind(tab[1], round(tab[2:6], 4)))
der <- function(nm, est, v) data.frame(par = nm, est = est, se_boot = NA, lo = q(v)[1], hi = q(v)[2], se_sandwich = NA, n_boot = sum(ok))
D <- rbind(do.call(rbind, lapply(c(64, 121, 156, 248, 309, 386), function(b) der(paste0("A_at_BYI_", b), exp(th[1] + th[2] * log(b)), exp(K[, 1] + K[, 2] * log(b))))),
           der("exp_k_pl", exp(th[6]), exp(K[, 6])), der("m", exp(th[4]), exp(K[, 4])), der("share_a_lbyi_positive", mean(K[, 2] > 0), K[, 2] > 0))
print(cbind(D[1], round(D[c(2, 4, 5)], 3))); write.csv(rbind(tab, D), "out/boot_B2_38c_summary.csv", row.names = FALSE); cat("done\n")
