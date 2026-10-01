## 02_height_refit.R: one static height equation with standard errors (red team major 1).
## Eq. 2 with rDBH = DBH / DBH.max within plot-year, random intercept on a0 by source/installation.
source("common.R")
suppressPackageStartupMessages(library(nlme))
tr <- std(read_dep(F_TREE))
need(tr, c("source", "inst", "plot", "year", "dbh", "ht", "baph", "byi"), "tree file")
## relative diameter and QMD are taken over every live stem in the plot-year, before the height filter
lv <- tr[is.finite(tr$dbh) & tr$dbh > 0, ]
if ("status" %in% names(lv)) lv <- lv[tolower(lv$status) == "live", ]   # 2026-09-16: live stems only
if ("expf" %in% names(lv)) lv <- lv[is.finite(lv$expf) & lv$expf > 0, ]
lkey <- interaction(lv$source, lv$inst, lv$plot, lv$year, drop = TRUE)
lv$rd_max <- lv$dbh / ave(lv$dbh, lkey, FUN = max)
w <- if ("expf" %in% names(lv)) lv$expf else rep(1, nrow(lv))
lv$qmd <- sqrt(ave(w * lv$dbh^2, lkey, FUN = sum) / ave(w, lkey, FUN = sum))
lv$rd_qmd <- lv$dbh / lv$qmd
d <- lv[is.finite(lv$ht) & lv$ht > 0 & is.finite(lv$byi) & is.finite(lv$baph), ]
d$grp_src <- factor(d$source); d$grp_inst <- factor(clus(d))
logmsg("height sample: ", nrow(d), " records, ", nlevels(d$grp_inst), " installations")
gate(nrow(d) > 1000, "height sample larger than 1,000 records")
gate(all(d$ht < 80) && all(d$dbh < 400), "heights below 80 m and diameters below 400 cm (F7)")

form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
st <- HT_REFIT_PRINTED
fit_nls <- safely(nls(form, data = d, start = as.list(st), control = nls.control(maxiter = 500, warnOnly = TRUE)), "nls fixed-effects fit")
st2 <- if (!is.null(fit_nls)) coef(fit_nls) else st
warns <- character()
fit <- safely(withCallingHandlers(
  nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1,
       random = a0 ~ 1 | grp_src/grp_inst, start = st2,
       control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)),
  warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }),
  "nlme fit, source/installation")
if (is.null(fit)) {
  fit <- safely(nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_inst,
                     start = st2, control = nlmeControl(maxIter = 200, returnObject = TRUE)), "nlme fit, installation only")
  re_struct <- "intercept by installation"
} else re_struct <- "intercept by data source and installation"
gate(!is.null(fit) && !any(grepl("converge", warns, ignore.case = TRUE)) && all(is.finite(sqrt(diag(vcov(fit))))),
     paste("height mixed model converged with finite standard errors", if (length(warns)) paste0("(warnings: ", paste(unique(warns), collapse = "; "), ")") else ""))

tt <- summary(fit)$tTable
coefs <- data.frame(parameter = rownames(tt), estimate = tt[, "Value"], se = tt[, "Std.Error"],
                    t = tt[, "t-value"], p = tt[, "p-value"],
                    lo95 = tt[, "Value"] - 1.96 * tt[, "Std.Error"], hi95 = tt[, "Value"] + 1.96 * tt[, "Std.Error"],
                    printed_v92 = HT_REFIT_PRINTED[rownames(tt)], engine_of_record = HT_ENGINE[rownames(tt)])
wcsv(coefs, "02_height_coefficients.csv")
wcsv(as.data.frame(vcov(fit)), "02_height_vcov.csv")
saveRDS(list(coef = fixef(fit), vcov = vcov(fit), sigma = fit$sigma, re = re_struct), file.path(OUT_DIR, "02_height_fit.rds"))
rel <- abs(fixef(fit) / HT_REFIT_PRINTED[names(fixef(fit))] - 1)
logmsg("max relative departure from the printed Table 3 vector: ", round(max(rel), 3))

p_cond <- as.numeric(fitted(fit))
p_pa   <- as.numeric(fitted(fit, level = 0))
p_eng  <- ht_eq2(HT_ENGINE, d$dbh, d$byi, d$baph, d$rd_qmd)
p_prn  <- ht_eq2(HT_REFIT_PRINTED, d$dbh, d$byi, d$baph, d$rd_max)
orig <- if ("planted" %in% names(d)) ifelse(d$planted == 1, "planted", "natural") else rep("all", nrow(d))
stat_row <- function(lab, p) data.frame(prediction = lab, n = nrow(d), r2 = r2(d$ht, p), rmse = rmse(d$ht, p),
  mae = mean(abs(d$ht - p)), bias = mean(d$ht - p),
  bias_natural = mean((d$ht - p)[orig != "planted"]), bias_planted = if (any(orig == "planted")) mean((d$ht - p)[orig == "planted"]) else NA)
stats <- rbind(stat_row("refit, conditional", p_cond), stat_row("refit, population-average", p_pa),
               stat_row("printed v92 vector, population-average", p_prn), stat_row("engine vector of record (rDBH = DBH/QMD)", p_eng))
wcsv(stats, "02_height_fit_stats.csv")
logmsg("population-average R2 ", round(stats$r2[2], 3), " against the published 0.783")

## equivalence tests, clustered by installation
eq <- rbind(cbind(vector = "refit, population-average", equiv_boot(d$ht, p_pa, d$grp_inst)),
            cbind(vector = "engine vector of record", equiv_boot(d$ht, p_eng, d$grp_inst)))
wcsv(eq, "02_height_equivalence.csv")

## stratified bias by height class and origin, both vectors
hc <- cut(d$dbh, c(0, 10, 20, 40, 60, Inf), right = FALSE)
strat <- aggregate(cbind(obs = d$ht, refit = p_pa, engine = p_eng), list(dbh_class = hc, origin = orig), mean)
strat$n <- aggregate(d$ht, list(hc, orig), length)$x
wcsv(strat, "02_height_bias_by_class.csv")

## leave one installation out, population-average, fixed-effects refit per fold
if (RUN_LOIO) {
  insts <- levels(d$grp_inst)
  one <- function(k) {
    tr_i <- d$grp_inst != k
    f <- tryCatch(nls(form, data = d[tr_i, ], start = as.list(fixef(fit)), control = nls.control(maxiter = 200, warnOnly = TRUE)), error = function(e) NULL)
    if (is.null(f)) return(NULL)
    data.frame(inst = k, obs = d$ht[!tr_i], pred = predict(f, d[!tr_i, ]))
  }
  lo <- do.call(rbind, parallel::mclapply(insts, one, mc.cores = NCORES))
  wcsv(data.frame(folds = length(insts), folds_fitted = length(unique(lo$inst)), n = nrow(lo),
                  r2 = r2(lo$obs, lo$pred), rmse = rmse(lo$obs, lo$pred), bias = mean(lo$obs - lo$pred)), "02_height_loio.csv")
}

## what the two vectors imply at the Table S12 stand states (mean tree, rDBH = 1 under the engine)
states <- expand.grid(qmd = c(20, 30, 40, 50, 60, 70), baph = c(20, 40, 60), byi = SITE_BYI)
states$engine <- ht_eq2(HT_ENGINE, states$qmd, states$byi, states$baph, 1)
for (r in c(0.6, 0.8, 1.0)) states[[paste0("refit_rd", r)]] <- ht_eq2(fixef(fit), states$qmd, states$byi, states$baph, r)
wcsv(states, "02_height_vector_contrast.csv")
logmsg("height refit done: ", paste(names(fixef(fit)), round(fixef(fit), 4), collapse = " "))
cat("done\n")

## 2026-09-16: base form without BYI (FVS-HI 'base' row, used when no BYI is supplied), same random structure
form0 <- ht ~ a0 * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
fit0 <- safely(nlme(form0, data = d, fixed = a0 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst,
                    start = fixef(fit)[c("a0", "b", "c", "g1", "g2")] * c(1.3, 1, 1, 1, 1),
                    control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)), "base height form")
if (!is.null(fit0)) {
  t0 <- summary(fit0)$tTable
  wcsv(data.frame(parameter = rownames(t0), estimate = t0[, "Value"], se = t0[, "Std.Error"],
                  r2_pa = r2(d$ht, as.numeric(fitted(fit0, level = 0)))), "02_height_coefficients_base.csv")
}
cat("done (base)\n")
