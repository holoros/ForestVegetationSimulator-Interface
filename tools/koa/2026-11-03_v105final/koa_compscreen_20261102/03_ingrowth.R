## 03_ingrowth.R: Eq. 6 ingrowth, deployed (quasi-Poisson rate ~ RD(SDI/500) + planted_new) vs I1 (+ ln(C2/100)).
source(path.expand("~/jobs/koa_compscreen_20261102/lib.R"))
d <- read.csv(file.path(W, "frames/final/koa_ingrowth_byi_obs_v103.csv"), stringsAsFactors = FALSE); nocoord(d)
o <- read.csv(file.path(W, "track2/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
d$rate <- d$ing_tph; d$src <- sub("\\|.*", "", d$key); d$inst <- sapply(strsplit(d$key, "\\|"), `[`, 2); d$cl <- paste(d$src, d$inst)
d$planted_new <- d$planted; isp <- d$src == "PSP"; d$planted_new[isp] <- as.integer(d$inst[isp] %in% as.character(o$Install[o$Origin_new == "Planted"]))
d$lc2 <- log(d$BYI / 100); stopifnot(all(is.finite(d$lc2)))
FM <- list(D = rate ~ RD + planted_new, I1 = rate ~ RD + planted_new + lc2)
qp <- function(f, dd) glm(f, quasipoisson(link = "log"), dd)
FT <- lapply(FM, qp, dd = d)
gate <- max(abs(coef(FT$D) - c(3.383783316541, -2.68983595460914, 1.63983185201748))); logm("GATE ingrowth deployed refit vs v103 vector max abs diff", signif(gate, 3), if (gate < 1e-6) "PASS" else "FAIL")
pdev <- function(y, mu) 2 * sum(ifelse(y > 0, y * log(y / mu), 0) - (y - mu))
cls <- unique(d$cl)
LO <- do.call(rbind, lapply(cls, function(k) { tr <- d[d$cl != k, ]; te <- d[d$cl == k, ]
  do.call(rbind, lapply(names(FM), function(m) { g <- qp(FM[[m]], tr); data.frame(model = m, cl = k, y = te$rate, mu = predict(g, te, type = "response")) })) }))
set.seed(SEED); idx <- split(seq_len(nrow(d)), d$key); k <- names(idx)
BS <- sapply(seq_len(NB), function(b) { dd <- d[unlist(idx[sample(k, replace = TRUE)], use.names = FALSE), ]; tryCatch(coef(qp(FM$I1, dd))[["lc2"]], error = function(e) NA) })
phi <- summary(FT$I1)$dispersion
gR <- seq(quantile(d$RD, .01), quantile(d$RD, .99), length.out = 50)
mono <- function(m) all(sapply(quantile(d$lc2, c(.1, .5, .9)), function(l) sapply(0:1, function(pl) all(diff(predict(FT[[m]], data.frame(RD = gR, planted_new = pl, lc2 = l), type = "response")) <= 1e-12))))
res <- data.frame(component = "Ingrowth", cand = names(FM), n = nrow(d), plots = length(k), installations = length(cls), deviance = sapply(FT, deviance),
  dispersion = sapply(FT, function(m) summary(m)$dispersion), b0 = sapply(FT, function(m) coef(m)[[1]]), b_RD500 = sapply(FT, function(m) coef(m)[["RD"]]),
  b_planted = sapply(FT, function(m) coef(m)[["planted_new"]]), lc2 = c(NA, coef(FT$I1)[["lc2"]]), lc2_se = c(NA, summary(FT$I1)$coefficients["lc2", 2]),
  loio_deviance = sapply(names(FM), function(m) with(LO[LO$model == m, ], pdev(y, mu))), boot_lo = c(NA, qboot(BS)["lo"]), boot_hi = c(NA, qboot(BS)["hi"]), boot_ok = c(NA, qboot(BS)["n_ok"]))
res$dQAIC <- (res$deviance - res$deviance[1]) / phi + 2 * c(0, 1); res$phi_used <- phi
res$signs <- res$b_RD500 < 0; res$mono <- sapply(names(FM), mono); res$gate_maxdiff <- c(gate, NA)
write.csv(res, file.path(OUT, "ingrowth_results.csv"), row.names = FALSE); write.csv(data.frame(lc2 = BS), file.path(OUT, "ingrowth_boot.csv"), row.names = FALSE)
print(res, digits = 4); logm("INGROWTH DONE")
