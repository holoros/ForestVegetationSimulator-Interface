# 49_ingrowth_screen.R  Exploratory screen of other stage 1 covariates and interactions for ingrowth (section 12 of the PREREG note), asked for by Aaron on
# November 15, 2026. Reported in full; nothing here is adopted by rule. Frame and folds of scripts 47 and 48. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/47_ingrowth.R"); eval(parse(text = L[4:10])); options(width = 200)
s2 <- x[Status == "live" & !is.na(DBH) & DBH > 0, .(qmd = QMD_koa[1], tph = TPH_koa[1]), by = .(pid, Measure)]; d <- merge(d, s2, by.x = c("pid", "m0"), by.y = c("pid", "Measure"), all.x = TRUE); cat("subplots with no live koa at the first visit:", sum(is.na(d$qmd)), "\n"); d[is.na(qmd), `:=`(qmd = 0, tph = 0)]
d[, `:=`(lbyi = log(BYI), z = as.integer(y > 0), loff = log(yrs), ltph = log(tph + 1), ba_oth = pmax(ba_all - ba, 0), share = ifelse(ba_all > 0, pmin(ba / ba_all, 1), 0))]; d <- merge(d, make_folds(d), by = "inst"); TI <- 9
cat("medians: SDI", round(median(d$sdi)), " QMD", round(median(d$qmd), 1), " stems", round(median(d$tph)), " other-species BA", round(median(d$ba_oth), 1), " koa share", round(median(d$share), 2), "\n")
cat("subplots with any recruit against the rest, means:\n"); print(d[, lapply(.SD, function(v) round(mean(v), 2)), by = .(any_recruit = z), .SDcols = c("rd", "sdi", "ba", "qmd", "tph", "ba_all", "ba_oth", "share", "BYI")])
FM <- list(const = z ~ 1, rd = z ~ rd, sdi = z ~ sdi, ba = z ~ ba, qmd = z ~ qmd, ltph = z ~ ltph, ba_all = z ~ ba_all, ba_oth = z ~ ba_oth, share = z ~ share, lbyi = z ~ lbyi,
           rd_lbyi = z ~ rd + lbyi, sdi_lbyi = z ~ sdi + lbyi, ba_lbyi = z ~ ba + lbyi, qmd_lbyi = z ~ qmd + lbyi, ltph_lbyi = z ~ ltph + lbyi, ba_oth_lbyi = z ~ ba_oth + lbyi, share_lbyi = z ~ share + lbyi,
           rd_x_lbyi = z ~ rd * lbyi, sdi_x_lbyi = z ~ sdi * lbyi, qmd_x_lbyi = z ~ qmd * lbyi, sdi_x_qmd = z ~ sdi * qmd, rd_qmd_lbyi = z ~ rd + qmd + lbyi)
fit <- function(nm, dd) { w <- NULL; m <- withCallingHandlers(glm(FM[[nm]], family = binomial("cloglog"), offset = loff, data = dd, control = glm.control(maxit = 100)), warning = function(e) { w <<- c(w, conditionMessage(e)); invokeRestart("muffleWarning") })
  m$okfit <- m$converged && all(is.finite(coef(m))) && max(abs(coef(m))) < 50 && !any(grepl("numerically 0 or 1", w)); m$mu2 <- if (any(dd$y > 0)) mean(dd$y[dd$y > 0]) else NA_real_; m }
pocc <- function(m, nd) { nd <- copy(nd); nd[, loff := log(TI)]; as.numeric(predict(m, nd, type = "response")) }
pdv <- function(y, mu) 2 * sum(ifelse(y > 0, y * log(y / mu), 0) - (y - mu)); bdv <- function(z, p) { p <- pmin(pmax(p, 1e-10), 1 - 1e-10); -2 * sum(z * log(p) + (1 - z) * log(1 - p)) }
F <- lapply(names(FM), fit, dd = d); names(F) <- names(FM)
cv <- rbindlist(lapply(sort(unique(d$fold)), function(k) { trn <- d[fold != k]; te <- d[fold == k]; rbindlist(lapply(names(FM), function(nm) { m <- tryCatch(fit(nm, trn), error = function(e) NULL); ok <- !is.null(m)
  data.table(form = nm, fold = k, clean = ok && m$okfit, y = te$y, z = te$z, p = if (ok) pocc(m, te) else NA_real_, mu = if (ok) pocc(m, te) * m$mu2 else NA_real_) })) }))
HO <- cv[, .(stage1_dev = round(bdv(z, p), 2), count_dev = round(pdv(y, mu), 2), predicted = round(sum(mu), 1), folds_clean = uniqueN(fold[clean])), by = form]
T <- rbindlist(lapply(names(F), function(nm) { m <- F[[nm]]; cs <- coef(summary(m)); k <- rownames(cs) != "(Intercept)"; data.table(form = nm, coef = if (any(k)) paste(sprintf("%s %.3g (z %.2f)", rownames(cs)[k], cs[k, 1], cs[k, 3]), collapse = "; ") else "", AIC = round(AIC(m), 2), clean = m$okfit) }))
R <- merge(T, HO, by = "form")[order(stage1_dev)]; cat("\nscreen, ordered by held-out stage 1 deviance (constant:", HO[form == "const", stage1_dev], "; count deviance of the constant:", HO[form == "const", count_dev], ")\n"); print(R[, .(form, AIC, stage1_dev, count_dev, predicted, folds_clean, clean, coef)], nrows = 100)
cat("\nforms below the constant on both held-out scores with every fold clean:", R[stage1_dev < HO[form == "const", stage1_dev] & count_dev < HO[form == "const", count_dev] & folds_clean == 10, form], "\n")
saveRDS(list(R = R), "out/ingrowth_49.rds"); cat("done\n")
