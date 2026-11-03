## 04_results.R: assemble the candidate x metric x response table and apply the preregistered adoption rule.
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"))
F <- lapply(setNames(CANDS, CANDS), function(k) { f <- file.path(OB, sprintf("fit_%s.rds", k)); if (file.exists(f)) readRDS(f) else NULL })
SRC <- c("DOFAW", "FIA", "KMR PSP", "PSP"); ROWS <- list(); COEF <- list(); STR <- list(); LOS <- list()
bootci <- function(resp, k, term) { f <- file.path(OB, sprintf("boot_%s_%s.csv", resp, k)); if (!file.exists(f)) return(c(NA, NA, 0))
  b <- read.csv(f); b <- b[b$ok, ]; c(quantile(b[[term]], c(.025, .975), na.rm = TRUE), nrow(b)) }
for (resp in c("dDBH", "dHT")) { K0 <- F$K0[[resp]]
  for (k in CANDS) { R <- F[[k]][[resp]]; if (is.null(R) || !isTRUE(R$ok)) { ROWS[[paste(resp, k)]] <- data.frame(resp = resp, cand = k, fit_ok = FALSE); next }
    lo <- R$loso; l0 <- K0$loso; better <- sapply(SRC, function(s) { a <- lo$rmse_log[lo$heldout == s]; z <- l0$rmse_log[l0$heldout == s]; isTRUE(lo$ok[lo$heldout == s]) && is.finite(a) && a < z })
    st <- R$strata; sz <- if (resp == "dDBH") "40-60" else "20-30"
    b8 <- bootci(resp, k, "b8")
    row <- data.frame(resp = resp, cand = k, fit_ok = TRUE, n = R$n, logLik = R$logLik, AIC = R$aic, dAIC = R$aic - K0$aic, sign_pass = all(R$sign),
      sign_detail = paste(names(R$sign), R$sign, collapse = ";"), b3 = R$b[["b3"]], b4 = R$b[["b4"]], b6 = R$b[["b6"]], b8 = R$b[["b8"]],
      b8_lo = b8[1], b8_hi = b8[2], boot_n = b8[3], b8_identified = if (b8[3] > 0) (b8[1] > 0 | b8[2] < 0) else NA,
      t(setNames(sapply(SRC, function(s) lo$rmse_log[lo$heldout == s]), paste0("loso_", gsub(" ", "", SRC)))), n_better = sum(better),
      better_sources = paste(SRC[better], collapse = ";"), ratio_all = st$ratio[st$strat == "all"], ratio_size_key = st$ratio[st$strat == "size" & st$level == sz],
      t(setNames(st$ratio[st$strat == "BALquintile"], paste0("ratio_BAL", st$level[st$strat == "BALquintile"]))), check.names = FALSE)
    ROWS[[paste(resp, k)]] <- row
    for (tm in paste0("b", 0:9)) { ci <- bootci(resp, k, tm); COEF[[paste(resp, k, tm)]] <- data.frame(resp = resp, cand = k, term = tm, est = R$b[[tm]], se = R$tTable[tm, 2], boot_lo = ci[1], boot_hi = ci[2], boot_n = ci[3]) }
    STR[[paste(resp, k)]] <- st; LOS[[paste(resp, k)]] <- cbind(lo, better_than_K0 = better[match(lo$heldout, SRC)]) } }
fill <- function(L) { allc <- unique(unlist(lapply(L, names))); do.call(rbind, lapply(L, function(x) { for (v in setdiff(allc, names(x))) x[[v]] <- NA; x[, allc] })) }
T <- fill(ROWS); rownames(T) <- NULL
## rule
T$rule_signs <- T$sign_pass; T$rule_3of4 <- T$n_better >= 3; T$rule_dAIC <- T$dAIC <= -4; T$rule_b8 <- T$b8_identified
T$verdict <- NA; T$reasons <- NA
for (i in seq_len(nrow(T))) { if (T$cand[i] == "K0") { T$verdict[i] <- "baseline"; next }; if (!isTRUE(T$fit_ok[i])) { T$verdict[i] <- "FAIL"; T$reasons[i] <- "fit failed"; next }
  r <- c(); if (!isTRUE(T$rule_signs[i])) r <- c(r, paste("signs fail:", T$sign_detail[i])); if (!isTRUE(T$rule_3of4[i])) r <- c(r, sprintf("better on %d of 4 sources", T$n_better[i]))
  if (!isTRUE(T$rule_dAIC[i])) r <- c(r, sprintf("dAIC %.2f > -4", T$dAIC[i]))
  if (is.na(T$rule_b8[i])) r <- c(r, "b8 bootstrap not run") else if (!T$rule_b8[i]) r <- c(r, sprintf("b8 interval %.3f to %.3f includes 0", T$b8_lo[i], T$b8_hi[i]))
  own <- length(r) == 0
  if (!grepl("p$", T$cand[i])) { j <- which(T$resp == T$resp[i] & T$cand == paste0(T$cand[i], "p"))
    if (!length(j) || !isTRUE(T$rule_3of4[j])) r <- c(r, sprintf("population variant better on %s of 4 sources", if (length(j)) T$n_better[j] else "NA"))
    else if (own) r <- c(r, sprintf("passes; adoption goes to its population variant %sp (which must pass on its own)", T$cand[i])) }
  T$verdict[i] <- if (own && grepl("p$", T$cand[i])) "PASS" else if (own) "PASS (plot-specific; via population variant)" else "FAIL"; T$reasons[i] <- paste(r, collapse = "; ") }
write.csv(T, file.path(OB, "results_table.csv"), row.names = FALSE); write.csv(fill(COEF), file.path(OB, "coefficients.csv"), row.names = FALSE)
write.csv(fill(STR), file.path(OB, "strata.csv"), row.names = FALSE); write.csv(fill(LOS), file.path(OB, "loso.csv"), row.names = FALSE)
for (resp in c("dDBH", "dHT")) { p <- T[T$resp == resp & T$verdict == "PASS", ]; cat(resp, ": adopted ->", if (nrow(p)) p$cand[order(-p$n_better, p$AIC)][1] else "none (K0 stays)", "\n") }
print(T[, c("resp", "cand", "n", "dAIC", "sign_pass", "b4", "b6", "b8", "b8_lo", "b8_hi", "boot_n", "n_better", "ratio_size_key", "verdict")], digits = 4)
