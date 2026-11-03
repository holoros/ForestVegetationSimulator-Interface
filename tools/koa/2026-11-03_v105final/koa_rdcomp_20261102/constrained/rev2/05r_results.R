## 05r_results.R: rule table per PREREG_K3c rev2.
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/rev2/lib_r2.R"))
K0 <- readRDS(file.path(OC, "fit_K0c.rds")); K3p <- readRDS(file.path(OC, "fit_K3pc.rds")); K3c1 <- readRDS(file.path(OC, "fit_K3c1.rds")); K3c3 <- readRDS(file.path(OR, "fit_K3c3.rds"))
P05 <- readRDS(file.path(OR, "fit_P05.rds")); P5 <- readRDS(file.path(OR, "fit_P5.rds")); MS <- fread(file.path(OR, "monotonicity_summary_rev2.csv"))
bt <- fread(file.path(OC, "boot_dDBH_K3c1.csv")); logm("K3c1 boot cols", paste(head(names(bt), 15), collapse = " "))
b8ci <- if ("b8" %in% names(bt)) quantile(bt$b8[is.finite(bt$b8)], c(.025, .975)) else c(NA, NA); logm("K3c1 b8 boot", round(b8ci, 4), "n", sum(is.finite(bt$b8)))
sr <- function(f, lev) f$strata$ratio[f$strata$level == lev]
row <- function(nm, f, ci = c(NA, NA)) { l <- setNames(f$loso$rmse_log, f$loso$heldout); l0 <- setNames(K0$loso$rmse_log, K0$loso$heldout)
  mx <- MS[cand == sub("K3pc", "K3p", sub("K3c2", "K3c1", nm))]
  r46 <- sr(f, "40-60"); q5 <- sr(f, "Q5"); w46 <- abs(r46 - 1) - abs(sr(K0, "40-60") - 1); wq5 <- abs(q5 - 1) - abs(sr(K0, "Q5") - 1)
  data.frame(cand = nm, df = f$df, logLik = f$logLik, dAIC = f$aic - K0$aic, signs = all(f$sign), sign_detail = paste(names(f$sign), f$sign, collapse = ";"),
    mono_X = mx[wrt == "X"]$pass, mono_RD = mx[wrt == "RD"]$pass, maxd_X = mx[wrt == "X"]$max_an, maxd_RD = mx[wrt == "RD"]$max_an,
    b4 = f$b[["b4"]], b5 = f$b[["b5"]], b6 = f$b[["b6"]], b8 = f$b[["b8"]], b8_lo = ci[1], b8_hi = ci[2],
    loso_DOFAW = l[["DOFAW"]], loso_FIA = l[["FIA"]], loso_KMRPSP = l[["KMR PSP"]], loso_PSP = l[["PSP"]], n_better = sum(l < l0[names(l)]),
    r4060 = r46, rQ5 = q5, worse4060 = w46, worseQ5 = wq5) }
R <- rbind(row("K0", K0), row("K3pc", K3p), row("K3c1", K3c1, b8ci), row("K3c2", K3c1, b8ci), row("K3c3", K3c3))
R$i <- R$signs & R$mono_X & R$mono_RD; R$ii <- R$n_better >= 3; R$iii <- R$dAIC <= -4; R$iv <- !is.na(R$b8_lo) & (R$b8_lo > 0 | R$b8_hi < 0); R$v <- R$worse4060 <= 0.05 & R$worseQ5 <= 0.05
R$verdict <- ifelse(R$cand %in% c("K0", "K3pc"), "reference", ifelse(R$i & R$ii & R$iii & R$iv & R$v, "PASS", "FAIL")); print(R)
fwrite(R, file.path(OR, "results_K3c_rev2.csv"))
P <- data.frame(fit = c("K3c1 (b3 = 0)", "b3 fixed -0.05", "b3 fixed -0.5", "K3p (b3 free)"), b3 = c(0, -0.05, -0.5, K3p$b[["b3"]]), logLik = c(K3c1$logLik, P05$logLik, P5$logLik, K3p$logLik))
print(P); fwrite(P, file.path(OR, "k3c2_profile.csv"))
ST <- rbind(K0$strata, K3p$strata, K3c1$strata, K3c3$strata); fwrite(ST, file.path(OR, "strata_rev2.csv")); print(ST[ST$level %in% c("all", "40-60", "Q5"), ])
logm("05r DONE")
