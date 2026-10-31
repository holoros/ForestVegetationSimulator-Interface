## byi_forms_v104.R (A4 red team, 30 Oct 2026). Screening of the BYI functional form and interactions in the increment equations.
## Linear mixed model APPROXIMATION of Eq. 4 on the calibration (NO) frames: response ln(annual increment), covariates at t0 as in Eq. 4,
## random intercepts Data/Install, ML fits for AIC. Not the recursion fit of record; used only to rank BYI forms. Live-list BAL (l).
suppressPackageStartupMessages({ library(nlme); library(splines) })
W <- path.expand("~/jobs/koa_v104_20261030"); setwd(W); OUT <- "a4/byi"
logm <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
prep <- function(resp) {
  d <- read.csv(sprintf("frames/final/%s_NO_v103_model.csv", resp), stringsAsFactors = FALSE)
  d <- d[complete.cases(d[, c("DBH.0","HT.0","BALl.0","CRl.0","BAPH.0","Planted","BYI","YIP")]) & d$BYI > 0 & d$CRl.0 > 0 & d[[resp]] > 0, ]
  size <- if (resp == "dDBH") d$DBH.0 else d$HT.0; guard <- if (resp == "dDBH") 45 else 20
  data.frame(y = log(d[[resp]] / d$YIP), lsize = log(size + 1), size = size, bal2 = d$BALl.0^2 / log(size + 5), lbal = log(d$BALl.0 + 1),
             lcr = log(d$CRl.0), sqb = sqrt(d$BAPH.0 * size), pls = d$Planted * pmin(size, guard), pl = d$Planted,
             byi = d$BYI, lbyi = log(d$BYI), b100 = d$BYI / 100, Data = d$Data, Install = paste(d$Data, d$Install), yip = d$YIP)
}
base <- "y ~ lsize + size + bal2 + lbal + lcr + sqb + pls + pl"
forms <- list(F0_none = "", F1_lnBYI = "+ lbyi", F2_linear = "+ b100", F3_sqrt = "+ sqrt(byi)", F4_quadratic = "+ b100 + I(b100^2)",
              F5_lnBYI_x_lnsize = "+ lbyi + lbyi:lsize", F6_lnBYI_x_lnBAL = "+ lbyi + lbyi:lbal", F7_lnBYI_x_planted = "+ lbyi + lbyi:pl",
              F8_lnBYI_x_lnCR = "+ lbyi + lbyi:lcr", F9_lnBYI_x_sqrtBAPHsize = "+ lbyi + lbyi:sqb", F10_spline3 = "+ ns(lbyi, 3)",
              F11_within_between = "+ lbyi_src + lbyi_dev")
ratio_hl <- function(m, resp, dd) {   # implied high (450) over low (100) ratio of predicted increment, natural tree, median covariates
  nd <- dd[1, ]; nd$pl <- 0; nd$pls <- 0
  for (v in c("lsize","size","bal2","lbal","lcr","sqb")) nd[[v]] <- median(dd[[v]][dd$pl == 0])
  mk <- function(B) { x <- nd; x$byi <- B; x$lbyi <- log(B); x$b100 <- B/100; x$lbyi_src <- if ("lbyi_src" %in% names(dd)) median(dd$lbyi_src) else NA; x$lbyi_dev <- log(B) - x$lbyi_src; x }
  exp(predict(m, mk(450), level = 0) - predict(m, mk(100), level = 0)) }
res <- list(); COEF <- list()
for (resp in c("dDBH", "dHT")) {
  dd <- prep(resp); dd$lbyi_src <- ave(dd$lbyi, dd$Data); dd$lbyi_dev <- dd$lbyi - dd$lbyi_src
  logm(resp, "rows", nrow(dd), "installs", length(unique(dd$Install)), "BYI range", range(dd$byi))
  cat(sprintf("%s correlations with ln(BYI): lbal %.3f, sqb %.3f, lsize %.3f, pl %.3f\n", resp, cor(dd$lbyi, dd$lbal), cor(dd$lbyi, dd$sqb), cor(dd$lbyi, dd$lsize), cor(dd$lbyi, dd$pl)))
  print(do.call(rbind, lapply(split(dd, dd$Data), function(s) data.frame(n = nrow(s), byi_min = min(s$byi), byi_med = median(s$byi), byi_max = max(s$byi), sd_lbyi = sd(s$lbyi)))))
  for (nm in names(forms)) {
    f <- as.formula(paste(base, forms[[nm]]))
    m <- tryCatch(lme(f, random = ~ 1 | Data/Install, data = dd, method = "ML", control = lmeControl(opt = "optim", maxIter = 200, msMaxIter = 200)), error = function(e) NULL)
    if (is.null(m)) { logm(resp, nm, "FAILED"); next }
    m2 <- tryCatch(lme(f, random = ~ 1 | Install, data = dd, method = "ML", control = lmeControl(opt = "optim")), error = function(e) NULL)   # no source intercept
    tt <- summary(m)$tTable; bt <- tt[grep("byi", rownames(tt)), , drop = FALSE]
    r <- tryCatch(ratio_hl(m, resp, dd), error = function(e) NA)
    r2 <- if (!is.null(m2)) tryCatch(ratio_hl(m2, resp, dd), error = function(e) NA) else NA
    res[[length(res) + 1]] <- data.frame(resp = resp, form = nm, k_byi = nrow(bt), AIC = AIC(m), logLik = as.numeric(logLik(m)),
      ratio_450_100 = r, ratio_no_source_RE = r2, AIC_no_source_RE = if (!is.null(m2)) AIC(m2) else NA,
      min_p_byi = if (nrow(bt)) min(bt[, "p-value"]) else NA, sd_source = as.numeric(VarCorr(m)[2, 2]), sd_inst = as.numeric(VarCorr(m)[4, 2]))
    if (nrow(bt)) COEF[[paste(resp, nm)]] <- data.frame(resp = resp, form = nm, term = rownames(bt), est = bt[, "Value"], se = bt[, "Std.Error"], p = bt[, "p-value"])
    logm(resp, nm, "AIC", round(AIC(m), 1), "ratio", round(r, 3))
  }
}
R <- do.call(rbind, res); R$dAIC <- ave(R$AIC, R$resp, FUN = function(a) a - a[1])
write.csv(R, file.path(OUT, "byi_forms_v104.csv"), row.names = FALSE); write.csv(do.call(rbind, COEF), file.path(OUT, "byi_forms_coef_v104.csv"), row.names = FALSE)
print(R[, c("resp","form","AIC","dAIC","ratio_450_100","ratio_no_source_RE","min_p_byi","sd_source")], digits = 4)
## leave-one-source-out predictive check for the record form and the best interaction form, dDBH only
dd <- prep("dDBH"); dd$lbyi_src <- ave(dd$lbyi, dd$Data); dd$lbyi_dev <- dd$lbyi - dd$lbyi_src
best <- R[R$resp == "dDBH" & R$form != "F0_none" & R$form != "F11_within_between", ]; best <- best$form[which.min(best$AIC)]
loso <- do.call(rbind, lapply(c("F0_none", "F1_lnBYI", best), function(nm) { f <- as.formula(paste(base, forms[[nm]]))
  do.call(rbind, lapply(unique(dd$Data), function(s) { tr <- dd[dd$Data != s, ]; te <- dd[dd$Data == s, ]
    m <- tryCatch(lme(f, random = ~ 1 | Data/Install, data = tr, method = "ML", control = lmeControl(opt = "optim")), error = function(e) NULL)
    if (is.null(m)) return(NULL); p <- predict(m, te, level = 0); data.frame(form = nm, held = s, n = nrow(te), rmse_log = sqrt(mean((te$y - p)^2)), bias_log = mean(te$y - p)) })) }))
write.csv(loso, file.path(OUT, "byi_loso_v104.csv"), row.names = FALSE); print(loso, digits = 3)
logm("DONE")
