# 48_ingrowth_two_stage.R  Two-stage ingrowth for the natural scenarios (section 11 of 2026-11-14_koa-height-crown-standmort_PREREG.md), from Aaron's
# suggestions of November 15, 2026 (RD with basal area and BYI; a two-stage approach): stage 1 occurrence of any koa recruit past 12.7 cm on a subplot
# (cloglog, interval offset), stage 2 recruits given occurrence (zero-truncated Poisson, one mean). Frame, folds and bootstrap of script 47. No identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/47_ingrowth.R"); eval(parse(text = L[4:10])); d[, `:=`(lbyi = log(BYI), z = as.integer(y > 0), loff = log(yrs))]; d <- merge(d, make_folds(d), by = "inst"); TI <- 9; stopifnot(all(d$yrs == TI))
cat("frame medians: RD", round(median(d$rd), 3), " koa BA", round(median(d$ba), 1), " all-species BA", round(median(d$ba_all), 1), " BYI", round(median(d$BYI), 1), "; correlation RD-BA", round(cor(d$rd, d$ba), 2), " RD-lnBYI", round(cor(d$rd, d$lbyi), 2), " BA-lnBYI", round(cor(d$ba, d$lbyi), 2), "\n")
cat("recruits per subplot with any:", sort(d[y > 0, y]), "\n")
FM <- list(T1 = z ~ 1, T2 = z ~ rd, T3 = z ~ ba, T4 = z ~ rd + ba + lbyi, T5 = z ~ rd + lbyi, T6 = z ~ ba + lbyi, T7 = z ~ rd + ba, T8 = z ~ lbyi, T4all = z ~ rd + ba_all + lbyi)
ztp <- function(yy) { m <- mean(yy); if (m <= 1 + 1e-9) return(1); lam <- uniroot(function(l) l / (1 - exp(-l)) - m, c(1e-6, 100))$root; lam / (1 - exp(-lam)) }   # mean recruits given any (equals the sample mean; lambda solved for the record)
fit <- function(nm, dd) { w <- NULL; m <- withCallingHandlers(glm(FM[[nm]], family = binomial("cloglog"), offset = loff, data = dd, control = glm.control(maxit = 100)), warning = function(e) { w <<- c(w, conditionMessage(e)); invokeRestart("muffleWarning") })
  m$okfit <- m$converged && all(is.finite(coef(m))) && max(abs(coef(m))) < 50 && !any(grepl("numerically 0 or 1", w)); m$mu2 <- if (any(dd$y > 0)) ztp(dd$y[dd$y > 0]) else NA_real_; m }
pocc <- function(m, nd) { nd <- copy(nd); nd[, loff := log(TI)]; as.numeric(predict(m, nd, type = "response")) }          # probability of any recruit over a nine-year interval
rate <- function(m, nd) pocc(m, nd) * m$mu2 / (TI / 59.5)                                                                   # expected trees/ha/yr
F <- lapply(names(FM), fit, dd = d); names(F) <- names(FM); N1 <- sum(d$y) / sum(d$yrs * d$area)
cat("\n(1) full fits, stage 1 (annual hazard of any recruit on a subplot); stage 2 mean recruits given any:", round(F$T1$mu2, 3), "; single-stage constant rate N1:", round(N1, 3), "trees/ha/yr; two-stage constant T1:", round(rate(F$T1, d[1]), 3), "\n")
for (nm in names(F)) { m <- F[[nm]]; cat("\n", nm, ": deviance", round(deviance(m), 2), " AIC", round(AIC(m), 2), " clean fit", m$okfit, "\n"); print(round(coef(summary(m)), 4)) }
pdv <- function(y, mu) 2 * sum(ifelse(y > 0, y * log(y / mu), 0) - (y - mu)); bdv <- function(z, p) { p <- pmin(pmax(p, 1e-10), 1 - 1e-10); -2 * sum(z * log(p) + (1 - z) * log(1 - p)) }
cv <- rbindlist(lapply(sort(unique(d$fold)), function(k) { trn <- d[fold != k]; te <- d[fold == k]; n1 <- sum(trn$y) / sum(trn$yrs * trn$area)
  rbind(data.table(form = "N1", fold = k, clean = TRUE, y = te$y, z = te$z, p = NA_real_, mu = n1 * te$yrs * te$area), rbindlist(lapply(names(FM), function(nm) { m <- tryCatch(fit(nm, trn), error = function(e) NULL); ok <- !is.null(m)
    data.table(form = nm, fold = k, clean = ok && m$okfit, y = te$y, z = te$z, p = if (ok) pocc(m, te) else NA_real_, mu = if (ok) pocc(m, te) * m$mu2 else NA_real_) }))) }))
HO <- cv[, .(subplots = .N, stage1_deviance = round(bdv(z, p), 3), count_deviance = round(pdv(y, mu), 3), predicted = round(sum(mu), 2), observed = sum(y), folds_clean = uniqueN(fold[clean])), by = form]
cat("\n(2) held out by installation: stage 1 binomial deviance and Poisson deviance of the expected counts\n"); print(HO)
el <- paste0("T", 2:8); best <- HO[form %in% el][order(stage1_deviance)]$form[1]; cat("lowest held-out stage 1 deviance among T2 to T8:", best, "\n")
ins <- unique(d$inst); sp <- split(seq_len(nrow(d)), d$inst); NBT <- 2000; idx <- lapply(seq_len(NBT), function(b) unlist(sp[sample(ins, length(ins), replace = TRUE)]))
md <- d[, .(rd = median(rd), ba = median(ba), lbyi = median(lbyi), ba_all = median(ba_all))]; qv <- function(v) quantile(d[[v]], c(0.1, 0.9))
ratio <- function(m, v) { a <- copy(md); b <- copy(md); a[[v]] <- qv(v)[[1]]; b[[v]] <- qv(v)[[2]]; rate(m, b) / rate(m, a) }
cat("\n(3) expected-rate ratio, 90th over 10th percentile of each term (others at their medians), with the installation bootstrap of both stages\n")
RT <- rbindlist(lapply(el, function(nm) { vs <- all.vars(FM[[nm]])[-1]; B <- lapply(idx, function(ix) { dd <- d[ix]; if (sum(dd$z) < 2) return(NULL); m <- tryCatch(fit(nm, dd), error = function(e) NULL); if (is.null(m) || !m$okfit) return(NULL); sapply(vs, function(v) ratio(m, v)) }); okb <- !sapply(B, is.null); Bm <- do.call(rbind, B[okb])
  data.table(form = nm, term = vs, ratio = round(sapply(vs, function(v) ratio(F[[nm]], v)), 3), lo = round(apply(Bm, 2, quantile, 0.025), 3), hi = round(apply(Bm, 2, quantile, 0.975), 3), share_below_1 = round(colMeans(Bm < 1), 3), boot_clean = round(mean(okb), 3)) })); print(RT)
B1 <- sapply(idx, function(ix) { dd <- d[ix]; if (sum(dd$z) < 1) return(NA); rate(fit("T1", dd), dd[1]) }); cat("two-stage constant T1 rate:", round(rate(F$T1, d[1]), 3), " 95%:", round(quantile(B1, c(.025, .975), na.rm = TRUE), 3), "\n")
# scenarios
th <- unname(readRDS("out/height_increment_42.rds")$FH$B2$th); eval(parse(text = L[grep("^hB2 <- ", L)]))
sim4 <- function(dbh, ht, ex, byi, pl, years, sm, ing) { out <- matrix(NA_real_, years + 1, 9, dimnames = list(NULL, c("BA", "TPH", "QMD", "HT", "VOL", "RD", "SDI", "HMAX", "ING")))
  for (y in 0:years) { s <- koa_stand(dbh, ht, ex); rd <- s$SDI / sm; ni <- if (is.null(ing)) 0 else ing(rd, s$BA, log(byi)); out[y + 1, ] <- c(s$BA, s$TPH, s$QMD, s$HT, 0.40 * s$BA * s$HT, rd, s$SDI, max(ht), ni); if (y == years) break
    bal <- koa_bal(dbh, s$ba); g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg)); pm <- mort_tree(dbh, ex, bal, s, rd, byi, pl, dbh + g)
    ht <- ht + hB2(ht, dbh, dbh + g, bal / max(s$BA, 1e-6) * rd, log(byi), pl); dbh <- dbh + g; ex <- ex * (1 - pm); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, DIN); ht <- c(ht, koa_height(DIN, cf)); ex <- c(ex, ni) } }
  out }
run4 <- function(ing = NULL, years = 200) rbindlist(lapply(seq_len(nrow(SC)), function(i) { L. <- getL(SC$planted[i]); cbind(planted = SC$planted[i], level = SC$level[i], byi = SC$byi[i], sdimax = SC$sdimax[i], year = 0:years, as.data.table(sim4(L.$DBH, L.$HT, L.$EXPF_c, SC$byi[i], SC$planted[i], years, SC$sdimax[i], if (SC$planted[i] == 0) ing else NULL))) }))
mk <- function(m) function(rd, ba, lbyi) rate(m, data.table(rd = rd, ba = ba, lbyi = lbyi, ba_all = ba))
S0 <- run4(); S1 <- run4(function(rd, ba, lbyi) N1); SB <- run4(mk(F[[best]])); S4 <- run4(mk(F$T4)); YR <- c(20, 40, 100, 200)
cat("\n(4) natural scenarios: none, constant rate N1,", best, "and T4 (ING = trees/ha entering that year)\n")
print(unique(rbind(cbind(ingrowth = "none", S0), cbind(ingrowth = "N1", S1), cbind(ingrowth = best, SB), cbind(ingrowth = "T4", S4))[planted == 0 & year %in% YR, .(ingrowth, level, year, BA = round(BA, 1), TPH = round(TPH), QMD = round(QMD, 1), RD = round(RD, 2), ING = round(ING, 2))])[order(match(level, c("lo", "md", "hi")), year, ingrowth)], nrows = 200)
mxo <- max(d$y / (d$yrs * d$area)); rng <- range(SB[planted == 0, ING]); cat("\nrate in the scenarios with", best, ":", round(rng, 3), "; with T4:", round(range(S4[planted == 0, ING]), 3), "; largest subplot rate observed:", round(mxo, 2), "\nscenario BYI (natural):", round(SC[planted == 0, byi], 1), "; frame BYI range:", round(range(d$BYI), 1), "; scenario BA range with", best, ":", round(range(SB[planted == 0, BA]), 1), "; frame koa BA range:", round(range(d$ba), 1), "\n")
g0 <- gates6(S0); gB <- gates6(SB); cat("\n(5) gates without ingrowth and with", best, "\n"); print(rbind(cbind(ingrowth = "none", g0), cbind(ingrowth = best, gB)))
a <- HO[form == best, stage1_deviance] < HO[form == "T1", stage1_deviance] && HO[form == best, count_deviance] < HO[form == "N1", count_deviance]; dens <- RT[form == best & term %in% c("rd", "ba")]; b <- nrow(dens) > 0 && all(dens$ratio < 1 & dens$hi < 1)
cc <- HO[form == best, folds_clean] == uniqueN(d$fold) && RT[form == best, boot_clean[1]] >= 0.9; dd <- identical(unlist(g0), unlist(gB)) && rng[1] >= 0 && rng[2] <= mxo
cat("\n(6) rule for", best, ": (a) held-out deviances below the constants:", a, "; (b) falls with density, upper limit below one:", b, "; (c) clean fits:", cc, "; (d) gates unchanged and rate in range:", dd, "\nreplaces the constant rate:", a && b && cc && dd, "\n")
saveRDS(list(F = lapply(F, coef), mu2 = F$T1$mu2, HO = HO, RT = RT, best = best, adopt = a && b && cc && dd), "out/ingrowth_48.rds"); cat("done\n")
