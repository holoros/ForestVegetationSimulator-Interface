## export_baselines.R: baseline (v105d form) refits under SDImax 741.7117, term/estimate/se, v105d prep/out style. NOT replacements (no candidate passed).
O <- path.expand("~/jobs/koa_formscreen_20261103/out"); wr <- function(df, f) write.csv(df, file.path(O, f), row.names = FALSE)
for (resp in c("dDBH", "dHT")) { r <- readRDS(file.path(O, sprintf("inc_%s_B.rds", resp))); tt <- r$tTable
  df <- data.frame(term = c(rownames(tt), "b3"), estimate = c(tt[, 1], 0), se = c(tt[, 2], 0)); df <- df[order(as.integer(sub("b", "", df$term))), ]
  df <- rbind(df, data.frame(term = c("c_natural", "c_planted", "SDIMAX_POP"), estimate = c(r$cc[["natural"]], r$cc[["planted"]], 741.7117), se = NA))
  wr(df, sprintf("baseline_refit_coefficients_%s_K3c1%s.csv", resp, if (resp == "dHT") "h" else "")) }
h <- readRDS(file.path(O, "height_fits.rds"))$B; V104 <- c(b = 0.017026137590269, c = 0.792246824594636, g2 = -0.343309808337385)
wr(data.frame(frame = "H1a_sdimax741", parameter = c("a0", "a1", "b", "c", "g1", "g2"), estimate = c(h$fixef[["a0"]], h$fixef[["a1"]], V104[["b"]], V104[["c"]], h$fixef[["g1"]], V104[["g2"]]),
              se = c(h$tTable["a0", 2], h$tTable["a1", 2], 0, 0, h$tTable["g1", 2], 0), fixed = c(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE)), "baseline_refit_coefficients_height_H1a.csv")
c2 <- readRDS(file.path(O, "hcb_fits.rds"))$B; wr(data.frame(term = names(c2$coef), estimate = unname(c2$coef), se = unname(c2$se)), "baseline_refit_coefficients_hcb_C2h.csv")
s3 <- readRDS(file.path(O, "stage3_fits.rds"))$B; wr(data.frame(term = paste0("c", 0:4), estimate = unname(s3$coef), se = unname(s3$se)), "baseline_refit_coefficients_stage3_M3a.csv")
s12 <- readRDS(file.path(O, "stage12_fits.rds")); wr(rbind(data.frame(stage = 1, term = names(s12$S1$B$coef), estimate = unname(s12$S1$B$coef), se = unname(s12$S1$B$se)),
  data.frame(stage = 2, term = names(s12$S2$B$coef), estimate = unname(s12$S2$B$coef), se = unname(s12$S2$B$se))), "baseline_refit_coefficients_stage12_lnRD.csv")
ig <- readRDS(file.path(O, "ingrowth_fits.rds"))$B; wr(data.frame(term = names(ig$coef), estimate = unname(ig$coef), se = unname(ig$se)), "baseline_refit_coefficients_ingrowth_RD741.csv")
## dHT baseline: share of positive d ln g/dRD by share level (monotonicity diagnostic, suppressed vs dominant)
for (resp in c("dDBH", "dHT")) for (cn in c("B", if (resp == "dDBH") c("D1", "D2", "D3") else c("T1", "T3", "T4"))) { r <- readRDS(file.path(O, sprintf("inc_%s_%s.rds", resp, cn)))
  m <- r$mono_by_share; x <- data.frame(resp = resp, cand = cn, share = m$sh, n_pos = m$fd[, "n_pos"], max_deriv = m$fd[, "max"])
  f <- file.path(O, "monotonicity_RD_by_share.csv"); write.table(x, f, sep = ",", row.names = FALSE, col.names = !file.exists(f), append = file.exists(f)) }
cat("exported\n"); print(read.csv(file.path(O, "monotonicity_RD_by_share.csv"))[read.csv(file.path(O, "monotonicity_RD_by_share.csv"))$resp == "dHT" & read.csv(file.path(O, "monotonicity_RD_by_share.csv"))$cand == "B", ])
