## 06_verdicts.R: applies the PREREG rule to every candidate from out/*_results.csv; writes out/verdicts.csv and out/verdicts.md.
OUT <- path.expand("~/jobs/koa_compscreen_20261102/out"); rd <- function(f) read.csv(file.path(OUT, f), stringsAsFactors = FALSE)
f4 <- function(x, d = 4) ifelse(is.na(x), "-", formatC(x, digits = d, format = "f"))
V <- list()
add <- function(comp, cand, dep, metric_txt, better, dAIC, signs, mono, byi, boot_lo, boot_hi) {
  ex <- if (byi) is.finite(boot_lo) && (boot_lo > 0 || boot_hi < 0) else NA
  why <- c(if (!signs) "signs fail", if (!mono) "monotonicity fails", if (!better) "held-out metric not better", if (!(dAIC <= -4)) sprintf("dAIC %.2f > -4", dAIC), if (byi && !ex) "BYI bootstrap interval includes zero")
  V[[length(V) + 1]] <<- data.frame(component = comp, candidate = cand, held_out = metric_txt, dAIC = round(dAIC, 2), signs = signs, monotone = mono,
    byi_boot95 = if (byi) sprintf("%.3f to %.3f", boot_lo, boot_hi) else "n/a", verdict = if (length(why)) "FAIL (sensitivity)" else "PASS", reason = if (length(why)) paste(why, collapse = "; ") else "all conditions met") }
h <- rd("height_results.csv"); D <- h[h$cand == "D", ]
for (m in c("H1a", "H1b", "H1full")) { r <- h[h$cand == m, ]; if (!isTRUE(r$converged)) { V[[length(V) + 1]] <- data.frame(component = "Height (Eq. 2)", candidate = m, held_out = "-", dAIC = NA, signs = NA, monotone = NA, byi_boot95 = "n/a", verdict = "FAIL (not converged)", reason = "did not converge"); next }
  add("Height (Eq. 2)", m, D, sprintf("%s RMSE %.4f vs %.4f", r$heldout_scheme, r$heldout_rmse, D$heldout_rmse), r$heldout_rmse < D$heldout_rmse, r$dAIC, r$signs, r$mono, FALSE, NA, NA) }
hc <- rd("hcb_results.csv"); D <- hc[hc$cand == "D", ]
for (m in c("C1", "C2h")) { r <- hc[hc$cand == m, ]; add("HCB (Eq. 3)", m, D, sprintf("LOIO RMSE %.4f vs %.4f", r$loio_rmse, D$loio_rmse), r$loio_rmse < D$loio_rmse, r$dAIC, r$signs, r$mono, TRUE, r$b5_boot_lo, r$b5_boot_hi) }
s <- rd("stage12_results.csv")
r <- s[s$cand == "M1", ]; D <- s[s$component == "Stage 1" & s$cand == "D", ]
add("Mortality Stage 1", "M1", D, sprintf("LOIO AUC %.4f vs %.4f; Brier %.4f vs %.4f", r$loio_auc, D$loio_auc, r$loio_brier, D$loio_brier), r$loio_auc > D$loio_auc && r$loio_brier < D$loio_brier, r$dAIC, r$signs, r$mono, TRUE, r$boot_lo, r$boot_hi)
r <- s[s$cand == "M2", ]; D <- s[s$component == "Stage 2" & s$cand == "D", ]
add("Mortality Stage 2", "M2", D, sprintf("LOIO RMSE ln(m) %.4f vs %.4f", r$loio_rmse, D$loio_rmse), r$loio_rmse < D$loio_rmse, r$dAIC, r$signs, r$mono, TRUE, r$boot_lo, r$boot_hi)
s3 <- rd("stage3_results.csv"); D <- s3[s3$cand == "D", ]
for (m in c("M3a", "M3b", "M3c")) { r <- s3[s3$cand == m, ]
  add("Mortality Stage 3", m, D, sprintf("LOIO within-interval AUC %.4f vs %.4f; Brier %.4f vs %.4f", r$loio_auc_within, D$loio_auc_within, r$loio_brier, D$loio_brier),
      r$loio_auc_within > D$loio_auc_within && r$loio_brier < D$loio_brier, r$dAIC, r$signs, r$mono, m != "M3a", r$boot_lo, r$boot_hi) }
ig <- rd("ingrowth_results.csv"); D <- ig[ig$cand == "D", ]; r <- ig[ig$cand == "I1", ]
add("Ingrowth (Eq. 6)", "I1", D, sprintf("LOIO deviance %.0f vs %.0f", r$loio_deviance, D$loio_deviance), r$loio_deviance < D$loio_deviance, r$dQAIC, r$signs, r$mono, TRUE, r$boot_lo, r$boot_hi)
V <- do.call(rbind, V); write.csv(V, file.path(OUT, "verdicts.csv"), row.names = FALSE)
md <- c("| component | candidate | held-out (candidate vs deployed) | dAIC (ingrowth dQAIC) | signs | monotone | BYI coef bootstrap 95% | verdict | reason |", "|---|---|---|---|---|---|---|---|---|",
  apply(V, 1, function(x) paste0("| ", paste(x, collapse = " | "), " |"))); writeLines(md, file.path(OUT, "verdicts.md")); cat(md, sep = "\n")
