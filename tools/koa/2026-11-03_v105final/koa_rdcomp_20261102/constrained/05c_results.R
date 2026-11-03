## 05c_results.R: K3c table and the PREREG_K3c adoption rule. K0 = K0c (gr.hat3c refit, gated against v105b).
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R"))
CS <- c("K0c", "K3pc", "K3c1", "K3c2"); F <- lapply(setNames(CS, CS), function(k) readRDS(file.path(OC, sprintf("fit_%s.rds", k))))
SRC <- c("DOFAW", "FIA", "KMR PSP", "PSP"); MO <- read.csv(file.path(OC, "monotonicity_summary.csv")); K0 <- F$K0c
## gates G0
K0old <- readRDS(file.path(OB, "fit_K0.rds"))$dDBH; K3old <- readRDS(file.path(OB, "fit_K3p.rds"))$dDBH
st0 <- K0$strata; r46 <- st0$ratio[st0$strat == "size" & st0$level == "40-60"]
G0 <- data.frame(check = c("K0c vs deployed v105b vector (max abs diff)", "K0c logLik", "K0c 40-60 cm ratio", "K0c LOSO RMSE vs parent K0 (max abs diff)",
                           "K3pc (start = stored K3p vector) vs parent K3p (max abs diff)", "K3p via gr.hat3c from parent's kept start (g0b log)"),
  value = c(max(abs(K0$b[names(DEP$dDBH)] - DEP$dDBH)), K0$logLik, r46, max(abs(K0$loso$rmse_log - K0old$loso$rmse_log)), max(abs(F$K3pc$b - K3old$b)), NA))
print(G0, digits = 6); write.csv(G0, file.path(OC, "gate_G0.csv"), row.names = FALSE)
bootci <- function(k, term) { f <- file.path(OC, sprintf("boot_dDBH_%s.csv", k)); if (!file.exists(f)) return(c(NA, NA, 0)); b <- read.csv(f); b <- b[b$ok, ]
  if (!term %in% names(b)) return(c(NA, NA, nrow(b))); c(quantile(b[[term]], c(.025, .975), na.rm = TRUE), nrow(b)) }
ROWS <- list(); COEF <- list(); STR <- list()
for (k in CS) { R <- F[[k]]; lo <- R$loso; l0 <- K0$loso
  better <- sapply(SRC, function(s) { a <- lo$rmse_log[lo$heldout == s]; z <- l0$rmse_log[l0$heldout == s]; isTRUE(lo$ok[lo$heldout == s]) && is.finite(a) && a < z })
  st <- R$strata; b8 <- bootci(k, "b8"); mo <- MO[MO$cand == k, ]
  ROWS[[k]] <- data.frame(cand = k, n = R$n, df = R$df, logLik = R$logLik, AIC = R$aic, dAIC = R$aic - K0$aic, sign_pass = all(R$sign), sign_detail = paste(names(R$sign), R$sign, collapse = ";"),
    mono_pass = mo$pass, mono_max_deriv = mo$max_deriv_an, b3 = if ("b3" %in% names(R$b)) R$b[["b3"]] else 0, b4 = R$b[["b4"]], b5 = R$b[["b5"]], b6 = R$b[["b6"]], b8 = R$b[["b8"]],
    b8_lo = b8[1], b8_hi = b8[2], boot_n = b8[3], b8_identified = if (b8[3] > 0) (b8[1] > 0 | b8[2] < 0) else NA,
    t(setNames(sapply(SRC, function(s) lo$rmse_log[lo$heldout == s]), paste0("loso_", gsub(" ", "", SRC)))), n_better = sum(better), better_sources = paste(SRC[better], collapse = ";"),
    c_nat = R$cc[["natural"]], c_pl = R$cc[["planted"]], ratio_all = st$ratio[st$strat == "all"], ratio_40_60 = st$ratio[st$strat == "size" & st$level == "40-60"],
    t(setNames(st$ratio[st$strat == "BALquintile"], paste0("ratio_BAL", st$level[st$strat == "BALquintile"]))), check.names = FALSE)
  for (tm in names(R$b)) { ci <- bootci(k, tm); COEF[[paste(k, tm)]] <- data.frame(cand = k, term = tm, est = R$b[[tm]], se = R$tTable[tm, 2], wald_lo = R$b[[tm]] - 1.96 * R$tTable[tm, 2],
    wald_hi = R$b[[tm]] + 1.96 * R$tTable[tm, 2], boot_lo = ci[1], boot_hi = ci[2], boot_n = ci[3]) }
  STR[[k]] <- st }
T <- do.call(rbind, ROWS); rownames(T) <- NULL
T$verdict <- NA; T$reasons <- NA
for (i in seq_len(nrow(T))) { k <- T$cand[i]; if (k == "K0c") { T$verdict[i] <- "baseline (K0 = v105b)"; next }; if (k == "K3pc") { T$verdict[i] <- "reference (parent K3p, not a K3c candidate)"; next }
  r <- c(); if (!T$sign_pass[i]) r <- c(r, paste("signs fail:", T$sign_detail[i])); if (!T$mono_pass[i]) r <- c(r, "monotonicity fails")
  if (T$n_better[i] < 3) r <- c(r, sprintf("better on %d of 4", T$n_better[i])); if (T$dAIC[i] > -4) r <- c(r, sprintf("dAIC %.2f > -4", T$dAIC[i]))
  if (is.na(T$b8_identified[i])) r <- c(r, "b8 bootstrap not run") else if (!T$b8_identified[i]) r <- c(r, sprintf("b8 interval %.3f to %.3f includes 0", T$b8_lo[i], T$b8_hi[i]))
  T$verdict[i] <- if (length(r)) "FAIL" else "PASS"; T$reasons[i] <- paste(r, collapse = "; ") }
write.csv(T, file.path(OC, "results_K3c.csv"), row.names = FALSE); write.csv(do.call(rbind, COEF), file.path(OC, "coefficients_K3c.csv"), row.names = FALSE)
write.csv(do.call(rbind, STR), file.path(OC, "strata_K3c.csv"), row.names = FALSE)
p <- T[T$verdict == "PASS", ]; cat("ADOPTED:", if (nrow(p)) p$cand[order(-p$n_better, p$AIC)][1] else "none (K0 v105b stays)", "\n")
print(T, digits = 5); print(do.call(rbind, COEF), digits = 4)
