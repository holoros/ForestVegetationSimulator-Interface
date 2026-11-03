## 05_height.R: Eq. 2 height. Deployed v105b partial (a0, a1 free; b, c, g1, g2 at v104) vs H1a (ln(BAPH+1) -> ln(RD), a0 a1 g1 free), H1b (RD), H1full
## (six free, ln(RD)); diagnostic H0g (deployed form, a0 a1 g1 free). nlme random a0 ~ 1 | source/installation, ML, the v105b control.
source(path.expand("~/jobs/koa_compscreen_20261102/lib.R")); suppressPackageStartupMessages(library(nlme))
src <- readLines(file.path(W, "track2/height_refit_v103.R")); eval(parse(text = src[1:33]))   # prep(), fit_ht() (no writes)
V104 <- c(a0 = 28.9288306400629, a1 = 0.966787802291731, b = 0.017026137590269, c = 0.792246824594636, g1 = 0.0768405891389797, g2 = -0.343309808337385)
d <- prep(file.path(W, "frames/final/tree_join_v103.csv")); nocoord(d)
d$SDI <- sdi_of(d$source, d$inst, d$plot, d$year); d$RD <- d$SDI / POP; stopifnot(all(is.finite(d$RD) & d$RD > 0))
d$Fs <- (1 - exp(-V104[["b"]] * d$dbh))^V104[["c"]] * exp(V104[["g2"]] * d$rd_max)
d$F <- d$Fs * exp(V104[["g1"]] * log(d$baph + 1)); d$lrd <- log(d$RD); d$lbaph <- log(d$baph + 1)
logm("height records", nrow(d), "installations", nlevels(d$grp_inst), "sources", nlevels(d$grp_src), "| cor ln(BAPH+1) vs ln(RD)", round(cor(d$lbaph, d$lrd), 4))
CTL <- nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)
FORMS <- list(D = ht ~ (a0 + a1 * byi / 100) * F, H0g = ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lbaph),
              H1a = ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lrd), H1b = ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * RD),
              H1full = ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * lrd + g2 * rd_max))
PARS <- list(D = c("a0", "a1"), H0g = c("a0", "a1", "g1"), H1a = c("a0", "a1", "g1"), H1b = c("a0", "a1", "g1"), H1full = c("a0", "a1", "b", "c", "g1", "g2"))
fit1 <- function(m, dd, start) { w <- character()
  f <- withCallingHandlers(tryCatch(nlme(FORMS[[m]], data = dd, fixed = as.formula(paste(paste(PARS[[m]], collapse = " + "), "~ 1")), random = a0 ~ 1 | grp_src/grp_inst,
         start = start[PARS[[m]]], control = CTL), error = function(e) { w <<- c(w, paste("ERROR", conditionMessage(e))); NULL }),
         warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  list(fit = f, warn = unique(w), conv = !is.null(f) && !any(grepl("ERROR|converge|maxIter|singular", w, ignore.case = TRUE))) }
nls_start <- function(m, base) { s <- base[PARS[[m]]]; r <- tryCatch(coef(nls(FORMS[[m]], data = d, start = as.list(s), control = nls.control(maxiter = 500, warnOnly = TRUE))), error = function(e) NULL)
  if (is.null(r)) s else r }
st <- list(D = V104, H0g = V104, H1a = replace(V104, "g1", 0.05), H1b = replace(V104, "g1", 0.05))
for (m in c("H1a", "H1b")) st[[m]][PARS[[m]]] <- nls_start(m, st[[m]])
FT <- list(); TM <- c()
for (m in c("D", "H0g", "H1a", "H1b")) { t0 <- Sys.time(); FT[[m]] <- fit1(m, d, st[[m]]); TM[m] <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  logm(m, "converged", FT[[m]]$conv, "secs", round(TM[m], 1), "fixef", paste(sprintf("%s=%.5f", names(fixef(FT[[m]]$fit)), fixef(FT[[m]]$fit)), collapse = " "), "logLik", round(as.numeric(logLik(FT[[m]]$fit)), 3),
       if (length(FT[[m]]$warn)) paste("| warnings:", paste(FT[[m]]$warn, collapse = "; ")) else "") }
g <- max(abs(fixef(FT$D$fit)[c("a0", "a1")] - c(28.990422, 1.142886))); logm("GATE deployed partial refit vs engine HT_P a0 a1 max abs diff", signif(g, 3), if (g < 1e-5) "PASS" else "FAIL")
## H1full (all six, ln(RD))
s6 <- V104; s6[c("a0", "a1", "g1")] <- fixef(FT$H1a$fit)[c("a0", "a1", "g1")]; s6n <- nls_start("H1full", s6)
t0 <- Sys.time(); FT$H1full <- fit1("H1full", d, s6n); TM["H1full"] <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
logm("H1full converged", FT$H1full$conv, "secs", round(TM["H1full"], 1), if (!is.null(FT$H1full$fit)) paste("fixef", paste(sprintf("%s=%.5f", names(fixef(FT$H1full$fit)), fixef(FT$H1full$fit)), collapse = " "), "logLik", round(as.numeric(logLik(FT$H1full$fit)), 3)) else "",
     if (length(FT$H1full$warn)) paste("| warnings:", paste(FT$H1full$warn, collapse = "; ")) else "")
saveRDS(lapply(FT, function(z) list(fixef = if (!is.null(z$fit)) fixef(z$fit), warn = z$warn, conv = z$conv)), file.path(OUT, "height_fits_summary.rds"))
## held-out: LOIO unless a full-data fit took > 60 s (PREREG fallback: leave-one-source-out)
mods <- c("D", "H0g", "H1a", "H1b"); if (FT$H1full$conv) mods <- c(mods, "H1full")
scheme <- if (max(TM[mods]) > 60) "LOSO" else "LOIO"; grp <- if (scheme == "LOIO") as.character(d$grp_inst) else as.character(d$grp_src)
logm("held-out scheme", scheme, "(max full fit secs", round(max(TM[mods]), 1), ") folds", length(unique(grp)))
HO <- list(); NF <- setNames(rep(0, length(mods)), mods)
for (k in unique(grp)) { tr <- droplevels(d[grp != k, ]); te <- d[grp == k, ]
  for (m in mods) { z <- fit1(m, tr, fixef(FT[[m]]$fit)); if (is.null(z$fit)) { NF[m] <- NF[m] + 1; next }
    p <- eval(FORMS[[m]][[3]], c(as.list(te), as.list(fixef(z$fit)))); HO[[length(HO) + 1]] <- data.frame(model = m, fold = k, y = te$ht, p = as.numeric(p), conv = z$conv) } }
HO <- do.call(rbind, HO); saveRDS(HO, file.path(OUT, "height_heldout_predictions.rds")); write.csv(HO[, c("model", "fold", "conv")][!duplicated(HO[, c("model", "fold")]), ], file.path(OUT, "height_heldout_folds.csv"), row.names = FALSE)
common <- Reduce(intersect, lapply(mods, function(m) unique(HO$fold[HO$model == m])))
## monotonicity: height non-decreasing in stand density at fixed DBH
mono <- function(m) { f <- fixef(FT[[m]]$fit); p <- V104; p[names(f)] <- f
  dv <- if (m %in% c("D", "H0g")) seq(quantile(d$baph, .01), quantile(d$baph, .99), length.out = 50) else seq(quantile(d$RD, .01), quantile(d$RD, .99), length.out = 50)
  ok <- TRUE
  for (db in quantile(d$dbh, c(.1, .5, .9))) for (rm in quantile(d$rd_max, c(.1, .5, .9))) for (by in quantile(d$byi, c(.1, .5, .9))) {
    term <- if (m %in% c("D", "H0g")) log(dv + 1) else if (m == "H1b") dv else log(dv)
    h <- (p[["a0"]] + p[["a1"]] * by / 100) * (1 - exp(-p[["b"]] * db))^p[["c"]] * exp(p[["g1"]] * term + p[["g2"]] * rm); ok <- ok && all(diff(h) >= -1e-10) }
  ok }
res <- do.call(rbind, lapply(names(FT), function(m) { z <- FT[[m]]; if (is.null(z$fit)) return(data.frame(component = "Height", cand = m, converged = FALSE))
  f <- fixef(z$fit); p <- V104; p[names(f)] <- f; ho <- HO[HO$model == m & HO$fold %in% common, ]
  data.frame(component = "Height", cand = m, converged = z$conv, n = nrow(d), free = paste(PARS[[m]], collapse = " "), a0 = p[["a0"]], a1 = p[["a1"]], b = p[["b"]], c = p[["c"]], g1 = p[["g1"]], g2 = p[["g2"]],
    a1_se = summary(z$fit)$tTable["a1", 2], g1_se = if ("g1" %in% names(f)) summary(z$fit)$tTable["g1", 2] else NA,
    logLik = as.numeric(logLik(z$fit)), AIC = AIC(z$fit), heldout_scheme = scheme, heldout_rmse = if (nrow(ho)) rmse(ho$y, ho$p) else NA,
    heldout_folds = length(unique(ho$fold)), heldout_folds_failed = if (m %in% names(NF)) NF[[m]] else NA, heldout_folds_nonconv = sum(!HO$conv[HO$model == m & !duplicated(HO[, c("model", "fold")])]),
    signs = p[["a0"]] > 0 && p[["a1"]] > 0 && p[["g1"]] > 0, mono = mono(m), secs = round(TM[m], 1)) }))
res$dAIC <- res$AIC - res$AIC[res$cand == "D"]; res$gate_maxdiff <- ifelse(res$cand == "D", g, NA)
write.csv(res, file.path(OUT, "height_results.csv"), row.names = FALSE); print(res, digits = 5); logm("HEIGHT DONE")
