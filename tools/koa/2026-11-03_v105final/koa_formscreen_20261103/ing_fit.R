## ing_fit.R: Eq. 6 ingrowth (quasi-Poisson, log link). Baseline B = deployed form with RD = SDI/741.7117 (frame RD column is SDI/500); I-a, I-b, I-c (PREREG).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R"))
d <- read.csv(file.path(W, "frames/final/koa_ingrowth_byi_obs_v103.csv"), stringsAsFactors = FALSE); nocoord(d)
o <- read.csv(file.path(W, "track2/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
d$rate <- d$ing_tph; d$src <- sub("\\|.*", "", d$key); d$inst <- sapply(strsplit(d$key, "\\|"), `[`, 2); d$cl <- paste(d$src, d$inst)
d$planted_new <- d$planted; isp <- d$src == "PSP"; d$planted_new[isp] <- as.integer(d$inst[isp] %in% as.character(o$Install[o$Origin_new == "Planted"]))
d$lc2 <- log(d$BYI / 100); d$RDn <- d$RD * 500 / POP; stopifnot(all(is.finite(d$lc2)), all(is.finite(d$RDn)))
rdfloor <- min(d$RDn[d$RDn > 0]); d$lnRD <- log(pmax(d$RDn, rdfloor)); d$lfree <- log(pmax(1 - d$RDn, 0.05))
logm("ingrowth rows", nrow(d), "plots", length(unique(d$key)), "installations", length(unique(d$cl)), "RD range", paste(signif(range(d$RDn), 4), collapse = " "),
     "| rows RD = 0:", sum(d$RDn == 0), "| rows RD >= 0.95:", sum(d$RDn >= 0.95), "| ln RD floor", signif(rdfloor, 4))
FM <- list(B = rate ~ RDn + planted_new, Ia = rate ~ lfree + planted_new, Ib = rate ~ lnRD + planted_new, Ic = rate ~ RDn + RDn:lc2 + planted_new)
qp <- function(f, dd) glm(f, quasipoisson(link = "log"), dd)
FT <- lapply(FM, qp, dd = d)
gate <- abs(coef(FT$B)[["RDn"]] * 500 / POP - (-2.68983595460914)); logm("GATE baseline RD slope x 500/741.71 vs v103 RD(SDI/500) slope -2.68983595460914:", signif(gate, 3), if (gate < 1e-6) "PASS" else "FAIL")
pdev <- function(y, mu) 2 * sum(ifelse(y > 0, y * log(y / mu), 0) - (y - mu))
cls <- unique(d$cl)
LO <- do.call(rbind, lapply(cls, function(k) { tr <- d[d$cl != k, ]; te <- d[d$cl == k, ]
  do.call(rbind, lapply(names(FM), function(m) { g <- qp(FM[[m]], tr); data.frame(model = m, cl = k, y = te$rate, mu = predict(g, te, type = "response")) })) }))
set.seed(SEED); idx <- split(seq_len(nrow(d)), d$cl)
BS <- sapply(seq_len(NB), function(b) { dd <- d[unlist(idx[sample(cls, length(cls), TRUE)], use.names = FALSE), ]; tryCatch(coef(qp(FM$Ic, dd))[["RDn:lc2"]], error = function(e) NA) })
gR <- seq(quantile(d$RDn, .01), quantile(d$RDn, .99), length.out = 50); ql <- quantile(d$lc2, seq(.01, .99, length.out = 9))
mono <- function(m) { mx <- 0; for (l in ql) for (pl in 0:1) { nd <- data.frame(RDn = gR, lnRD = log(pmax(gR, rdfloor)), lfree = log(pmax(1 - gR, 0.05)), lc2 = l, planted_new = pl)
  mx <- max(mx, max(diff(predict(FT[[m]], nd, type = "response")))) }; c(ok = mx <= 1e-12, max_increase = mx) }
sgn <- function(m) { cf <- coef(FT[[m]]); switch(m, B = cf[["RDn"]] < 0, Ia = cf[["lfree"]] > 0, Ib = cf[["lnRD"]] < 0, Ic = cf[["RDn"]] + cf[["RDn:lc2"]] * median(d$lc2) < 0) }
res <- do.call(rbind, lapply(names(FM), function(m) { g <- FT[[m]]; cf <- coef(g); se <- summary(g)$coefficients[, 2]; mo <- mono(m); bt <- if (m == "Ic") qboot(BS) else c(lo = NA, hi = NA, n_ok = NA)
  data.frame(component = "Ingrowth", cand = m, n = nrow(d), k = length(cf), deviance = deviance(g), dispersion = summary(g)$dispersion,
    coefs = paste(sprintf("%s=%.5g (SE %.3g)", names(cf), cf, se), collapse = "; "), loio_deviance = with(LO[LO$model == m, ], pdev(y, mu)),
    signs = sgn(m), mono = as.logical(mo[["ok"]]), mono_max_increase = mo[["max_increase"]], byi_boot_lo = bt[["lo"]], byi_boot_hi = bt[["hi"]], byi_boot_ok = bt[["n_ok"]]) }))
res$dQAIC <- (res$deviance - res$deviance[res$cand == "B"]) / res$dispersion + 2 * (res$k - res$k[res$cand == "B"]); res$gate <- ifelse(res$cand == "B", gate, NA)
write.csv(res, file.path(OUT, "ingrowth_results.csv"), row.names = FALSE); write.csv(data.frame(Ic_RDn_lc2 = BS), file.path(OUT, "ingrowth_boot.csv"), row.names = FALSE)
saveRDS(lapply(FT, function(g) list(coef = coef(g), se = summary(g)$coefficients[, 2])), file.path(OUT, "ingrowth_fits.rds"))
print(res, digits = 4); logm("INGROWTH DONE")
