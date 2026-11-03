## ht_fit.R: Eq. 2 total height. Baseline B = v105d H1a refit with RD = SDI/741.7117; HT1 (RD on rate), HT2 (RD on shape exponent), HT3 (RD x rD).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R")); suppressPackageStartupMessages(library(nlme))
src <- readLines(file.path(W, "track2/height_refit_v103.R")); eval(parse(text = src[1:33]))
V104 <- c(a0 = 28.9288306400629, a1 = 0.966787802291731, b = 0.017026137590269, c = 0.792246824594636, g1 = 0.0768405891389797, g2 = -0.343309808337385)
d <- prep(file.path(W, "frames/final/tree_join_v103.csv")); nocoord(d)
d$SDI <- sdi_of(d$source, d$inst, d$plot, d$year); d$RD <- d$SDI / POP; stopifnot(all(is.finite(d$RD) & d$RD > 0)); d$lrd <- log(d$RD)
d$bV <- V104[["b"]]; d$cV <- V104[["c"]]; d$g2V <- V104[["g2"]]; d$Fs <- (1 - exp(-d$bV * d$dbh))^d$cV * exp(d$g2V * d$rd_max)
logm("height records", nrow(d), "installations", nlevels(d$grp_inst), "RD range", paste(signif(range(d$RD), 4), collapse = " "))
CTL <- nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)
FORMS <- list(B = ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lrd),
              HT1 = ht ~ (a0 + a1 * byi / 100) * (1 - exp(-bV * exp(g1 * lrd) * dbh))^cV * exp(g2V * rd_max),
              HT2 = ht ~ (a0 + a1 * byi / 100) * (1 - exp(-bV * dbh))^(cV * exp(-g1 * lrd)) * exp(g2V * rd_max),
              HT3 = ht ~ (a0 + a1 * byi / 100) * (1 - exp(-bV * dbh))^cV * exp(g1 * lrd + g2V * rd_max + g3 * rd_max * lrd))
PARS <- list(B = c("a0", "a1", "g1"), HT1 = c("a0", "a1", "g1"), HT2 = c("a0", "a1", "g1"), HT3 = c("a0", "a1", "g1", "g3"))
fit1 <- function(m, dd, start) { w <- character()
  f <- withCallingHandlers(tryCatch(nlme(FORMS[[m]], data = dd, fixed = as.formula(paste(paste(PARS[[m]], collapse = " + "), "~ 1")), random = a0 ~ 1 | grp_src/grp_inst,
         start = start[PARS[[m]]], control = CTL), error = function(e) { w <<- c(w, paste("ERROR", conditionMessage(e))); NULL }),
         warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  list(fit = f, warn = unique(w), conv = !is.null(f) && !any(grepl("ERROR|converge|maxIter|singular", w, ignore.case = TRUE))) }
nls_start <- function(m, s) { r <- tryCatch(coef(nls(FORMS[[m]], data = d, start = as.list(s[PARS[[m]]]), control = nls.control(maxiter = 500, warnOnly = TRUE))), error = function(e) NULL)
  if (is.null(r)) s[PARS[[m]]] else r }
H1A <- c(a0 = 36.8783667238855, a1 = 1.75656549996992, g1 = 0.045154489386926)   # v105d H1a (SDImax 923); a0, a1 rescale by (923/741.7117)^-g1
st <- list(B = c(H1A[c("a0", "a1")] * (923 / POP)^(-H1A[["g1"]]), g1 = H1A[["g1"]]))
st$B <- nls_start("B", st$B); st$HT1 <- nls_start("HT1", c(st$B[c("a0", "a1")], g1 = 0.05)); st$HT2 <- nls_start("HT2", c(st$B[c("a0", "a1")], g1 = 0.05))
st$HT3 <- nls_start("HT3", c(st$B, g3 = 0))
FT <- list(); TM <- c()
for (m in names(FORMS)) { t0 <- Sys.time(); FT[[m]] <- fit1(m, d, st[[m]]); TM[m] <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  logm(m, "converged", FT[[m]]$conv, "secs", round(TM[m], 1), if (!is.null(FT[[m]]$fit)) paste("fixef", paste(sprintf("%s=%.6g", names(fixef(FT[[m]]$fit)), fixef(FT[[m]]$fit)), collapse = " "), "logLik", round(as.numeric(logLik(FT[[m]]$fit)), 3)) else "",
       if (length(FT[[m]]$warn)) paste("| warnings:", paste(FT[[m]]$warn, collapse = "; ")) else "") }
g <- abs(as.numeric(logLik(FT$B$fit)) - (-18782.83)); logm("GATE baseline H1a logLik under SDImax 741.71 vs compscreen H1a (-18782.83, 2 dp):", signif(g, 3), if (g < 0.1) "PASS (nlme stop tolerance; identical model)" else "FAIL")
mods <- names(FT)[sapply(FT, function(z) !is.null(z$fit))]
grp <- as.character(d$grp_inst); HO <- list(); NF <- setNames(rep(0, length(mods)), mods)
for (k in unique(grp)) { tr <- droplevels(d[grp != k, ]); te <- d[grp == k, ]
  for (m in mods) { z <- fit1(m, tr, fixef(FT[[m]]$fit)); if (is.null(z$fit)) { NF[m] <- NF[m] + 1; next }
    p <- eval(FORMS[[m]][[3]], c(as.list(te), as.list(fixef(z$fit)))); HO[[length(HO) + 1]] <- data.frame(model = m, fold = k, y = te$ht, p = as.numeric(p), conv = z$conv) } }
HO <- do.call(rbind, HO); saveRDS(HO, file.path(OUT, "height_heldout_predictions.rds"))
common <- Reduce(intersect, lapply(mods, function(m) unique(HO$fold[HO$model == m])))
monoD <- list()
mono <- function(m) { f <- fixef(FT[[m]]$fit); rg <- grid50(d$RD); ok <- TRUE; mx <- -Inf
  for (db in qs(d$dbh)) for (rm in qs(d$rd_max)) for (by in qs(d$byi)) {
    nd <- data.frame(dbh = db, rd_max = rm, byi = by, lrd = log(rg), bV = V104[["b"]], cV = V104[["c"]], g2V = V104[["g2"]]); nd$Fs <- (1 - exp(-nd$bV * nd$dbh))^nd$cV * exp(nd$g2V * nd$rd_max)
    h <- eval(FORMS[[m]][[3]], c(as.list(nd), as.list(f))); dh <- diff(h); mx <- max(mx, -min(dh)); ok <- ok && all(dh >= -1e-10) }
  monoD[[m]] <<- mx; ok }
res <- do.call(rbind, lapply(mods, function(m) { z <- FT[[m]]; f <- fixef(z$fit); tt <- summary(z$fit)$tTable; ho <- HO[HO$model == m & HO$fold %in% common, ]
  data.frame(component = "Height", cand = m, converged = z$conv, n = nrow(d), free = paste(PARS[[m]], collapse = " "),
    coefs = paste(sprintf("%s=%.6g (SE %.3g)", names(f), f, tt[, 2]), collapse = "; "), logLik = as.numeric(logLik(z$fit)), AIC = AIC(z$fit),
    heldout_rmse = if (nrow(ho)) rmse(ho$y, ho$p) else NA, heldout_folds = length(unique(ho$fold)), heldout_folds_failed = NF[[m]],
    heldout_folds_nonconv = sum(!HO$conv[HO$model == m & !duplicated(HO[, c("model", "fold")])]), signs = f[["a0"]] > 0 && f[["a1"]] > 0, mono = mono(m), secs = round(TM[m], 1)) }))
res$mono_max_decrease <- unlist(monoD[res$cand]); res$dAIC <- res$AIC - res$AIC[res$cand == "B"]; res$gate_loglik_diff <- ifelse(res$cand == "B", g, NA)
write.csv(res, file.path(OUT, "height_results.csv"), row.names = FALSE)
saveRDS(lapply(FT, function(z) if (!is.null(z$fit)) list(fixef = fixef(z$fit), tTable = summary(z$fit)$tTable, vcov = vcov(z$fit))), file.path(OUT, "height_fits.rds"))
print(res, digits = 5); logm("HEIGHT DONE")
