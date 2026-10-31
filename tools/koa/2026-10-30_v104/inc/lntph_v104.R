## lntph_v104.R (A4): stem density term ln(TPH at t0) added to the deployed dDBH L_NO form, tested on twenty random 80/20 installation splits
## (seed 20261030, fixed before any fit): coefficient with its 95 percent interval across splits, and out-of-sample period RMSE (cm) with and without the term.
suppressPackageStartupMessages(library(nlme)); set.seed(20261030)
src <- readLines(path.expand("~/jobs/koa_v104_20261030/track2/inc/inc_v103.R")); commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); load(file.path(OUT, "fits_v103.rda")); OUTX <- file.path(W, "a4/inc/out"); GUARD <- 45
T <- read.csv(file.path(W, "inputs/AK_TREE_v103.csv"), stringsAsFactors = FALSE); nocoord(T)
tp <- unique(T[T$Status == "live" & is.finite(T$DBH) & T$DBH > 0, c("Data", "Install", "Plot", "Measure", "TPH")]); tp <- tp[!duplicated(tp[, 1:4]), ]
d <- read.csv(file.path(FRD, "dDBH_NO_v103_model.csv"), stringsAsFactors = FALSE); d <- merge(d, tp, by.x = c("Data", "Install", "Plot", "t.0"), by.y = c("Data", "Install", "Plot", "Measure"), all.x = TRUE)
d <- model_cols(d, "l"); d <- d[is.finite(d$TPH) & d$TPH > 0, ]; d$lnTPH <- log(d$TPH); logm("rows with TPH", nrow(d))
gr.hat3t <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, lntph, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10) gr.hat3(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0 + b10 * lntph, b1, b2, b3, b4, b5, b6, b7, b8, b9)
f0 <- dDBH ~ gr.hat3(d1 = DBH.0, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
f1 <- dDBH ~ gr.hat3t(d1 = DBH.0, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, lntph = lnTPH, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10)
st <- fixef(FITS[["dDBH_L_NO"]]); inst <- unique(paste(d$Data, d$Install)); splits <- replicate(20, sample(inst, round(0.8 * length(inst))), simplify = FALSE)
res <- list()
for (s in seq_along(splits)) { tr <- d[paste(d$Data, d$Install) %in% splits[[s]], ]; te <- d[!(paste(d$Data, d$Install) %in% splits[[s]]), ]; t0 <- Sys.time()
  m0 <- tryCatch(nlme(f0, data = tr, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = st, weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) NULL)
  m1 <- tryCatch(nlme(f1, data = tr, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 + b10 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = c(st, b10 = 0), weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) NULL)
  if (is.null(m0) || is.null(m1)) { logm("split", s, "FAILED"); next }
  c0 <- tryCatch(solve_c("dDBH", tr, fixef(m0)), error = function(e) c(natural = NA, planted = NA)); b1v <- fixef(m1); p1 <- function(dd) { bb <- b1v[1:10]; bb["b0"] <- b1v[["b0"]]; exp(b1v[["b10"]] * dd$lnTPH) * pa_pred("dDBH", dd, bb) }
  c1 <- tryCatch(sapply(c(natural = 0, planted = 1), function(pl) { dd <- tr[tr$Planted == pl, ]; f <- function(lc) { v <- sum(p1(dd)) * exp(lc) - sum(dd$dDBH); if (!is.finite(v)) 1e12 else v }; exp(uniroot(f, c(-4, 4))$root) }), error = function(e) c(natural = NA, planted = NA))
  pr0 <- pa_pred("dDBH", te, fixef(m0)) * c0[ifelse(te$Planted == 1, "planted", "natural")]; pr1 <- p1(te) * c1[ifelse(te$Planted == 1, "planted", "natural")]
  res[[s]] <- data.frame(split = s, n_train = nrow(tr), n_test = nrow(te), b10 = b1v[["b10"]], b10_se = sqrt(vcov(m1)["b10", "b10"]), rmse_without = rmse(te$dDBH, pr0), rmse_with = rmse(te$dDBH, pr1), aic_without = AIC(m0), aic_with = AIC(m1))
  logm("split", s, "b10", round(b1v[["b10"]], 4), "rmse without", round(rmse(te$dDBH, pr0), 3), "with", round(rmse(te$dDBH, pr1), 3), round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
  write.csv(do.call(rbind, res), file.path(OUTX, "lntph_splits_v104.csv"), row.names = FALSE) }
r <- do.call(rbind, res); logm("SUMMARY b10 mean", round(mean(r$b10), 4), "q025/q975", round(quantile(r$b10, c(0.025, 0.975)), 4), "| mean RMSE without", round(mean(r$rmse_without), 3), "with", round(mean(r$rmse_with), 3)); logm("LNTPH DONE")
