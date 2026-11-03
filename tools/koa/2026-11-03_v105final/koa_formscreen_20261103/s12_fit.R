## s12_fit.R: mortality Stage 1 (occurrence, cloglog) and Stage 2 (ln conditional rate, lm). Sample: stage1_garcia_v103.R path (as compscreen, 282 intervals).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R"))
src <- readLines(file.path(W, "track2/stage1/stage1_garcia_v103.R"))[1:31]; src <- sub('setwd\\([^)]*\\); ', "", src)
envB <- new.env(); eval(parse(text = src), envir = envB); p <- envB$d103; nocoord(p)
p$any_mort <- as.logical(p$any_mort); p$RD <- pmax(p$sdi, 1) / POP; p$lnrd <- log(p$RD); p$C2 <- c2_of(p$Data, p$Install, p$Plot); p$lc2 <- log(p$C2 / 100)
p$key <- paste(p$Data, p$Install, p$Plot); p$inst <- paste(p$Data, p$Install); stopifnot(all(is.finite(p$lc2)))
js <- fromJSON(file.path(W, "out/v105_constants.json"))$STAGE1
logm("Stage 1 rows", nrow(p), "plots", length(unique(p$key)), "installations", length(unique(p$inst)), "with mortality", sum(p$any_mort), "RD range", paste(signif(range(p$RD), 4), collapse = " "))
g1fit <- function(f, d) suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = d, control = glm.control(maxit = 100)))
R0G <- seq(round(quantile(p$RD, .05), 2), round(quantile(p$RD, .95), 2), by = 0.01)
F1 <- list(B = any_mort ~ lnrd + planted + offset(log(yip)), S1a = any_mort ~ hinge + planted + offset(log(yip)), S1b = any_mort ~ lnrd + lnrd:lc2 + planted + offset(log(yip)),
           S1c = any_mort ~ RD + planted + offset(log(yip)))
F2 <- list(B = log(m_ann) ~ lnrd + planted, S2a = log(m_ann) ~ hinge + planted, S2b = log(m_ann) ~ lnrd + lnrd:lc2 + planted, S2c = log(m_ann) ~ RD + planted)
fitter <- function(stage, m, d) { f <- if (stage == 1) F1[[m]] else F2[[m]]; FF <- if (stage == 1) function(dd) g1fit(f, dd) else function(dd) lm(f, dd)
  if (m %in% c("S1a", "S2a")) { ll <- sapply(R0G, function(r) { d$hinge <- pmax(0, d$RD - r); as.numeric(logLik(FF(d))) }); r0 <- R0G[which.max(ll)]; d$hinge <- pmax(0, d$RD - r0)
    g <- FF(d); attr(g, "r0") <- r0; g } else FF(d) }
addh <- function(g, d) { if (!is.null(attr(g, "r0"))) d$hinge <- pmax(0, d$RD - attr(g, "r0")); d }
dm <- p[p$any_mort & p$m_ann > 0, ]
A <- lapply(names(F1), function(m) fitter(1, m, p)); names(A) <- names(F1); Bm <- lapply(names(F2), function(m) fitter(2, m, dm)); names(Bm) <- names(F2)
g0 <- c(s1 = max(abs(coef(A$B)[["planted"]] - unlist(js$stage1_beta)[3]), abs(coef(A$B)[["lnrd"]] - unlist(js$stage1_beta)[2])),
        s2 = max(abs(coef(Bm$B)[["planted"]] - unlist(js$stage2_beta)[3]), abs(coef(Bm$B)[["lnrd"]] - unlist(js$stage2_beta)[2])))
logm("GATE baseline slopes vs deployed STAGE1 (ln SDI slope and planted; intercept shifts by slope x ln 741.71): S1", signif(g0[1], 3), "S2", signif(g0[2], 3))
## LOIO (threshold r0 re-profiled in every fold)
insts <- unique(p$inst)
lo1 <- rbindlist(lapply(insts, function(k) { tr <- p[p$inst != k, ]; te <- p[p$inst == k, ]
  rbindlist(lapply(names(F1), function(m) { g <- fitter(1, m, tr); data.table(model = m, inst = k, y = as.integer(te$any_mort), p = predict(g, addh(g, te), type = "response")) })) }))
lo2 <- rbindlist(lapply(unique(dm$inst), function(k) { tr <- dm[dm$inst != k, ]; te <- dm[dm$inst == k, ]
  rbindlist(lapply(names(F2), function(m) { g <- fitter(2, m, tr); data.table(model = m, inst = k, y = log(te$m_ann), p = predict(g, addh(g, te))) })) }))
## installation-cluster bootstrap of the new BYI terms (S1b, S2b lnrd:lc2)
set.seed(SEED); idx <- split(seq_len(nrow(p)), p$inst)
BS <- t(sapply(seq_len(NB), function(b) { db <- p[unlist(idx[sample(insts, length(insts), TRUE)], use.names = FALSE), ]
  a <- tryCatch({ g <- fitter(1, "S1b", db); if (g$converged) coef(g)[["lnrd:lc2"]] else NA }, error = function(e) NA)
  dmb <- db[db$any_mort & db$m_ann > 0, ]; c(S1b = a, S2b = tryCatch(coef(fitter(2, "S2b", dmb))[["lnrd:lc2"]], error = function(e) NA)) }))
## monotonicity over the observed RD range (1st-99th pct), C2 at its 1st..99th pct (9 values), both origins
gR <- grid50(p$RD); qc <- quantile(p$lc2, seq(.01, .99, length.out = 9))
nd_of <- function(g, l, pl) addh(g, data.frame(RD = gR, lnrd = log(gR), lc2 = l, planted = pl, yip = 1))
p1 <- function(g, l, pl) predict(g, nd_of(g, l, pl), type = "response")
mono1 <- function(m) { g <- A[[m]]; mx <- 0; for (l in qc) for (pl in 0:1) { dd <- diff(p1(g, l, pl)); mx <- max(mx, -min(dd)) }; c(ok = mx <= 1e-12, max_decrease = mx) }
mono2 <- function(m) { g <- Bm[[m]]; mx <- 0; for (l in qc) for (pl in 0:1) { dd <- diff(p1(A$B, l, pl) * exp(predict(g, nd_of(g, l, pl)))); mx <- max(mx, -min(dd)) }; c(ok = mx <= 1e-12, max_decrease = mx) }
dslope1 <- function(g) { cf <- coef(g); nm <- setdiff(names(cf), c("(Intercept)", "planted")); if ("lnrd:lc2" %in% nm) cf[["lnrd"]] + cf[["lnrd:lc2"]] * median(p$lc2) else cf[[nm[1]]] }
row <- function(stage, m, g, lo) { cf <- coef(g); se <- summary(g)$coefficients[, 2]; mo <- if (stage == 1) mono1(m) else mono2(m)
  bt <- if (m %in% c("S1b", "S2b")) qboot(BS[, m]) else c(lo = NA, hi = NA, n_ok = NA)
  data.frame(component = paste("Stage", stage), cand = m, n = nobs(g), k = attr(logLik(g), "df") + !is.null(attr(g, "r0")), r0 = if (is.null(attr(g, "r0"))) NA else attr(g, "r0"),
    coefs = paste(sprintf("%s=%.5g (SE %.3g)", names(cf), cf, se), collapse = "; "), logLik = as.numeric(logLik(g)),
    loio_auc = if (stage == 1) with(lo[model == m], auc(y, p)) else NA, loio_brier = if (stage == 1) with(lo[model == m], mean((y - p)^2)) else NA,
    loio_rmse = if (stage == 2) with(lo[model == m], rmse(y, p)) else NA, density_slope_median_c2 = dslope1(g),
    signs = if (stage == 1) dslope1(g) > 0 else TRUE, mono = as.logical(mo[["ok"]]), mono_max_decrease = mo[["max_decrease"]],
    byi_boot_lo = bt[["lo"]], byi_boot_hi = bt[["hi"]], byi_boot_ok = bt[["n_ok"]]) }
res <- rbind(do.call(rbind, lapply(names(A), function(m) row(1, m, A[[m]], lo1))), do.call(rbind, lapply(names(Bm), function(m) row(2, m, Bm[[m]], lo2))))
res$AIC <- -2 * res$logLik + 2 * res$k; res$dAIC <- res$AIC - ave(ifelse(res$cand == "B", res$AIC, NA), res$component, FUN = function(v) v[!is.na(v)][1])
res$gate_slope_maxdiff <- ifelse(res$cand == "B", ifelse(res$component == "Stage 1", g0[1], g0[2]), NA)
write.csv(res, file.path(OUT, "stage12_results.csv"), row.names = FALSE); write.csv(BS, file.path(OUT, "stage12_boot.csv"), row.names = FALSE)
saveRDS(list(S1 = lapply(A, function(g) list(coef = coef(g), se = summary(g)$coefficients[, 2], r0 = attr(g, "r0"))), S2 = lapply(Bm, function(g) list(coef = coef(g), se = summary(g)$coefficients[, 2], r0 = attr(g, "r0")))), file.path(OUT, "stage12_fits.rds"))
print(res, digits = 4); logm("STAGE12 DONE")
