## verdicts.R: apply the PREREG rule to every candidate; writes out/verdicts.csv and out/increment_results.csv, out/monotonicity_increments.csv.
suppressPackageStartupMessages(library(data.table)); OUT <- path.expand("~/jobs/koa_formscreen_20261103/out")
V <- list(); fmt <- function(x, d = 4) formatC(x, digits = d, format = "f")
## increments
IR <- list(); MO <- list()
for (resp in c("dDBH", "dHT")) { cands <- if (resp == "dDBH") c("B", "D1", "D2", "D3") else c("B", "T1", "T2", "T3", "T4")
  R <- lapply(cands, function(c) { f <- file.path(OUT, sprintf("inc_%s_%s.rds", resp, c)); if (file.exists(f)) readRDS(f) else list(ok = FALSE) }); names(R) <- cands
  B <- R$B
  for (c in cands) { r <- R[[c]]
    if (!isTRUE(r$ok)) { IR[[paste(resp, c)]] <- data.frame(resp = resp, cand = c, ok = FALSE); V[[paste(resp, c)]] <- data.frame(component = resp, cand = c, heldout = "fit failed (both starts)",
        dAIC = NA, signs = NA, mono = NA, byi_boot = NA, verdict = if (c == "B") "baseline" else "FAIL (sensitivity)", reason = "no converged fit"); next }
    lo <- r$loso; better <- sum(lo$ok & lo$rmse_log < B$loso$rmse_log); dA <- r$aic - B$aic; mono <- all(r$mono$pass); sg <- all(r$sign)
    for (k in seq_len(nrow(r$mono))) MO[[paste(resp, c, k)]] <- data.frame(resp = resp, cand = c, r$mono[k, ])
    IR[[paste(resp, c)]] <- data.frame(resp = resp, cand = c, ok = TRUE, form = r$form, df = r$df, logLik = r$logLik, AIC = r$aic, dAIC = dA,
      coefs = paste(sprintf("%s %.5g (SE %.3g)", rownames(r$tTable), r$tTable[, 1], r$tTable[, 2]), collapse = "; "),
      loso = paste(sprintf("%s %.4f", lo$heldout, lo$rmse_log), collapse = " / "), loso_mean = mean(lo$rmse_log), better_of_4 = better,
      signs = sg, sign_detail = paste(names(r$sign), r$sign, collapse = " "), mono_x = r$mono$pass[1], mono_rd = r$mono$pass[2], mono_rd_npos = r$mono$n_pos[2], mono_rd_max = r$mono$max_deriv[2],
      ratio_all = r$strata$ratio_all, ratio_bigclass = r$strata$ratio_bigclass, ratio_BALQ5 = r$strata$ratio_BALQ5, c_nat = r$cc[["natural"]], c_plt = r$cc[["planted"]])
    if (c == "B") { V[[paste(resp, c)]] <- data.frame(component = resp, cand = "B (v105d refit)", heldout = sprintf("LOSO mean %.4f (%s)", mean(lo$rmse_log), paste(fmt(lo$rmse_log), collapse = "/")),
        dAIC = 0, signs = sg, mono = mono, byi_boot = "n/a", verdict = "baseline", reason = if (!mono) "baseline fails monotonicity (reported)" else ""); next }
    newbyi <- c %in% c("D3", "T4"); bfile <- file.path(OUT, sprintf("boot_%s_%s.csv", resp, c)); bt <- if (newbyi && file.exists(bfile)) read.csv(bfile) else NULL
    others <- sg && mono && better >= 3 && dA <= -4
    byi_ok <- if (!newbyi) TRUE else if (is.null(bt)) NA else { q <- quantile(bt$b10, c(.025, .975), na.rm = TRUE); q[1] > 0 || q[2] < 0 }
    why <- c(if (!sg) paste("signs fail:", paste(names(r$sign)[!r$sign], collapse = ",")), if (!mono) sprintf("monotonicity fails (d ln g/dRD > 0 at %d of %d grid points)", r$mono$n_pos[2], r$mono$n[2]),
             if (better < 3) sprintf("better than baseline on %d of 4 sources", better), if (dA > -4) sprintf("dAIC %.2f > -4", dA),
             if (newbyi && is.null(bt)) "b10 bootstrap not run (fails other conditions)", if (isFALSE(byi_ok)) "b10 bootstrap interval includes zero")
    V[[paste(resp, c)]] <- data.frame(component = resp, cand = c, heldout = sprintf("LOSO mean %.4f (%s); better %d of 4", mean(lo$rmse_log), paste(fmt(lo$rmse_log), collapse = "/"), better),
      dAIC = dA, signs = sg, mono = mono, byi_boot = if (!newbyi) "n/a" else if (is.null(bt)) "not run" else sprintf("%.4g to %.4g", quantile(bt$b10, .025, na.rm = TRUE), quantile(bt$b10, .975, na.rm = TRUE)),
      verdict = if (others && isTRUE(byi_ok)) "PASS" else "FAIL (sensitivity)", reason = paste(why, collapse = "; ")) } }
fwrite(rbindlist(IR, fill = TRUE), file.path(OUT, "increment_results.csv")); fwrite(rbindlist(MO, fill = TRUE), file.path(OUT, "monotonicity_increments.csv"))
bt <- function(lo, hi) if (is.na(lo)) "n/a" else sprintf("%.4g to %.4g", lo, hi)
excl <- function(lo, hi) is.na(lo) || lo > 0 || hi < 0
add <- function(comp, cand, ho_txt, ho_better, dA, sg, mono, lo, hi, extra = "") {
  if (cand == "B") return(data.frame(component = comp, cand = "B (v105d refit)", heldout = ho_txt, dAIC = 0, signs = sg, mono = mono, byi_boot = "n/a", verdict = "baseline", reason = if (!mono) "baseline fails monotonicity (reported)" else ""))
  why <- c(if (!sg) "signs fail", if (!mono) "monotonicity fails", if (!ho_better) "held-out metric not better", if (!is.finite(dA) || dA > -4) sprintf("dAIC %.2f > -4", dA), if (!excl(lo, hi)) "BYI bootstrap interval includes zero")
  data.frame(component = comp, cand = cand, heldout = ho_txt, dAIC = dA, signs = sg, mono = mono, byi_boot = bt(lo, hi), verdict = if (length(why)) "FAIL (sensitivity)" else "PASS", reason = paste(c(why, extra), collapse = "; ")) }
h <- fread(file.path(OUT, "height_results.csv")); hb <- h[cand == "B"]
for (i in seq_len(nrow(h))) with(h[i], V[[paste("H", cand)]] <<- add("Height (Eq. 2)", cand, sprintf("LOIO RMSE %.4f vs %.4f", heldout_rmse, hb$heldout_rmse), heldout_rmse < hb$heldout_rmse, dAIC, signs, mono, NA, NA))
hc <- fread(file.path(OUT, "hcb_results.csv")); hcb <- hc[cand == "B"]
for (i in seq_len(nrow(hc))) with(hc[i], V[[paste("C", cand)]] <<- add("HCB (Eq. 3)", cand, sprintf("LOIO RMSE %.4f vs %.4f", loio_rmse, hcb$loio_rmse), loio_rmse < hcb$loio_rmse, dAIC, signs, mono, byi_boot_lo, byi_boot_hi))
s <- fread(file.path(OUT, "stage12_results.csv"))
for (i in seq_len(nrow(s))) with(s[i], { b <- s[component == s$component[i] & cand == "B"]
  if (component == "Stage 1") V[[paste("S1", cand)]] <<- add("Mortality Stage 1", cand, sprintf("LOIO AUC %.4f vs %.4f; Brier %.4f vs %.4f", loio_auc, b$loio_auc, loio_brier, b$loio_brier),
      loio_auc > b$loio_auc && loio_brier < b$loio_brier, dAIC, signs, mono, byi_boot_lo, byi_boot_hi, if (is.finite(r0)) sprintf("r0 = %.2f", r0) else "")
  else V[[paste("S2", cand)]] <<- add("Mortality Stage 2", cand, sprintf("LOIO RMSE ln(m) %.4f vs %.4f", loio_rmse, b$loio_rmse), loio_rmse < b$loio_rmse, dAIC, signs, mono, byi_boot_lo, byi_boot_hi, if (is.finite(r0)) sprintf("r0 = %.2f", r0) else "") })
s3 <- fread(file.path(OUT, "stage3_results.csv")); b3 <- s3[cand == "B"]
for (i in seq_len(nrow(s3))) with(s3[i], V[[paste("S3", cand)]] <<- add("Mortality Stage 3", cand, sprintf("LOIO within AUC %.4f vs %.4f; Brier %.5f vs %.5f", loio_auc_within, b3$loio_auc_within, loio_brier, b3$loio_brier),
  loio_auc_within > b3$loio_auc_within && loio_brier < b3$loio_brier, dAIC, signs, mono, byi_boot_lo, byi_boot_hi, if (is.finite(r0)) sprintf("r0 = %.2f", r0) else ""))
ig <- fread(file.path(OUT, "ingrowth_results.csv")); ib <- ig[cand == "B"]
for (i in seq_len(nrow(ig))) with(ig[i], V[[paste("I", cand)]] <<- add("Ingrowth (Eq. 6)", cand, sprintf("LOIO deviance %.0f vs %.0f", loio_deviance, ib$loio_deviance), loio_deviance < ib$loio_deviance, dQAIC, signs, mono, byi_boot_lo, byi_boot_hi))
VV <- rbindlist(V, fill = TRUE); fwrite(VV, file.path(OUT, "verdicts.csv"))
cat("| component | candidate | held-out | dAIC | signs | monotone | BYI boot 95% | verdict | reason |\n|---|---|---|---|---|---|---|---|---|\n")
for (i in seq_len(nrow(VV))) with(VV[i], cat(sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", component, cand, heldout, if (is.na(dAIC)) "" else sprintf("%.2f", dAIC), signs, mono, byi_boot, verdict, reason)))
