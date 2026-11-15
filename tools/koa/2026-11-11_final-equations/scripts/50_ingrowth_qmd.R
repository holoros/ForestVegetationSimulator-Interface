# 50_ingrowth_qmd.R  Two-stage ingrowth with QMD in stage 1 for the natural scenarios (section 13 of the PREREG note; Aaron's choice of November 15, 2026,
# post hoc from the screen of script 49): bootstrap, gates and scenario checks before anything is built. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/47_ingrowth.R"); eval(parse(text = L[4:10])); options(width = 200); TI <- 9
s2 <- x[Status == "live" & !is.na(DBH) & DBH > 0, .(qmd = QMD_koa[1]), by = .(pid, Measure)]; d <- merge(d, s2, by.x = c("pid", "m0"), by.y = c("pid", "Measure")); d[, `:=`(z = as.integer(y > 0), loff = log(yrs))]; stopifnot(nrow(d) == 48)
cat("koa QMD at the first visit (cm): "); print(round(quantile(d$qmd, c(0, .1, .25, .5, .75, .9, 1)), 1)); cat("QMD of the subplots with any recruit:", sort(round(d[z == 1, qmd], 1)), "; their recruits:", d[z == 1][order(qmd), y], "\n")
fit <- function(dd) { w <- NULL; m <- withCallingHandlers(glm(z ~ qmd, family = binomial("cloglog"), offset = loff, data = dd, control = glm.control(maxit = 100)), warning = function(e) { w <<- c(w, conditionMessage(e)); invokeRestart("muffleWarning") })
  list(b = coef(m), ok = m$converged && all(is.finite(coef(m))) && max(abs(coef(m))) < 50 && !any(grepl("numerically 0 or 1", w)), mu2 = mean(dd$y[dd$y > 0]), m = m) }
rate <- function(b, mu2, q) (1 - exp(-TI * exp(b[1] + b[2] * q))) * mu2 * 59.5 / TI
F <- fit(d); cat("\n(1) stage 1 fit, clean:", F$ok, "; stage 2 mean:", F$mu2, "\n"); print(round(coef(summary(F$m)), 4)); QG <- c(15, 25, 40, 60); cat("rate (trees/ha/yr) at QMD", QG, ":", round(rate(F$b, F$mu2, QG), 3), "; constant rate:", round(sum(d$y) / sum(d$yrs * d$area), 3), "\n")
ins <- unique(d$inst); sp <- split(seq_len(nrow(d)), d$inst); NBT <- 2000
BT <- do.call(rbind, lapply(seq_len(NBT), function(b) { dd <- d[unlist(sp[sample(ins, length(ins), replace = TRUE)])]; if (sum(dd$z) < 2) return(c(NA, NA, NA, 0)); f <- tryCatch(fit(dd), error = function(e) NULL); if (is.null(f)) return(c(NA, NA, NA, 0)); c(f$b, f$mu2, f$ok) }))
ok <- BT[, 4] == 1 & complete.cases(BT); q <- function(v) round(quantile(v, c(0.025, 0.975)), 4)
cat("\n(2) installation bootstrap:", NBT, "resamples; clean", sum(ok), "(", round(100 * mean(ok), 1), "%); resamples with fewer than two subplots with recruits:", sum(is.na(BT[, 1])), "\n")
cat("t0", round(F$b[1], 4), " 95%:", q(BT[ok, 1]), "\nt1 (QMD)", round(F$b[2], 4), " 95%:", q(BT[ok, 2]), " share negative:", round(mean(BT[ok, 2] < 0), 3), "\nstage 2 mean", F$mu2, " 95%:", q(BT[ok, 3]), "\n")
for (g in QG) cat("rate at QMD", g, ":", round(rate(F$b, F$mu2, g), 3), " 95%:", round(quantile(rate(t(BT[ok, 1:2]), BT[ok, 3], g), c(.025, .975)), 3), "\n")
th <- unname(readRDS("out/height_increment_42.rds")$FH$B2$th); eval(parse(text = L[grep("^hB2 <- ", L)]))
sim5 <- function(dbh, ht, ex, byi, pl, years, sm, ing) { out <- matrix(NA_real_, years + 1, 9, dimnames = list(NULL, c("BA", "TPH", "QMD", "HT", "VOL", "RD", "SDI", "HMAX", "ING")))
  for (y in 0:years) { s <- koa_stand(dbh, ht, ex); rd <- s$SDI / sm; ni <- if (is.null(ing)) 0 else ing(s$QMD); out[y + 1, ] <- c(s$BA, s$TPH, s$QMD, s$HT, 0.40 * s$BA * s$HT, rd, s$SDI, max(ht), ni); if (y == years) break
    bal <- koa_bal(dbh, s$ba); g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg)); pm <- mort_tree(dbh, ex, bal, s, rd, byi, pl, dbh + g)
    ht <- ht + hB2(ht, dbh, dbh + g, bal / max(s$BA, 1e-6) * rd, log(byi), pl); dbh <- dbh + g; ex <- ex * (1 - pm); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, DIN); ht <- c(ht, koa_height(DIN, cf)); ex <- c(ex, ni) } }
  out }
run5 <- function(ing = NULL, years = 200) rbindlist(lapply(seq_len(nrow(SC)), function(i) { L. <- getL(SC$planted[i]); cbind(planted = SC$planted[i], level = SC$level[i], byi = SC$byi[i], sdimax = SC$sdimax[i], year = 0:years, as.data.table(sim5(L.$DBH, L.$HT, L.$EXPF_c, SC$byi[i], SC$planted[i], years, SC$sdimax[i], if (SC$planted[i] == 0) ing else NULL))) }))
N1 <- sum(d$y) / sum(d$yrs * d$area); S0 <- run5(); S1 <- run5(function(q) N1); SQ <- run5(function(q) rate(F$b, F$mu2, q)); YR <- c(20, 40, 100, 200)
cat("\n(3) natural scenarios: none, constant rate, QMD form (ING = trees/ha entering that year)\n")
print(rbind(cbind(ingrowth = "none", S0), cbind(ingrowth = "constant", S1), cbind(ingrowth = "QMD", SQ))[planted == 0 & year %in% YR, .(ingrowth, level, year, BA = round(BA, 1), TPH = round(TPH), QMD = round(QMD, 1), RD = round(RD, 2), HT = round(HT, 1), ING = round(ING, 3))][order(match(level, c("lo", "md", "hi")), year, ingrowth)], nrows = 200)
cat("\nQMD form, rate by year (median BYI): "); print(SQ[planted == 0 & level == "md" & year %in% c(0, 5, 10, 20, 30, 40, 60, 100, 150, 200), .(year, QMD = round(QMD, 1), ING = round(ING, 3))])
cat("total trees/ha added over 200 years: QMD form", round(SQ[planted == 0, sum(ING[year < 200]), by = level]$V1, 1), "; constant", round(200 * N1, 1), "\n")
mxo <- max(d$y / (d$yrs * d$area)); cat("rate range in the scenarios:", round(range(SQ[planted == 0, ING]), 3), "; largest subplot rate observed:", round(mxo, 2), "; scenario QMD range:", round(range(SQ[planted == 0, QMD]), 1), "; frame QMD range:", round(range(d$qmd), 1), "\n")
g0 <- gates6(S0); gQ <- gates6(SQ); cat("\n(4) gates without ingrowth and with the QMD form\n"); print(rbind(cbind(ingrowth = "none", g0), cbind(ingrowth = "QMD", gQ)))
kk <- which(ok)[1:300]; BD <- rbindlist(parallel::mclapply(kk, function(j) cbind(draw = j, run5(function(q) rate(BT[j, 1:2], BT[j, 3], q))[planted == 0 & year %in% YR, .(level, year, BA, TPH, QMD, RD)]), mc.cores = 4))
cat("\n(5) QMD form: 95% range over 300 bootstrap draws of both stages (every other equation at its estimates)\n")
print(BD[, .(BA_lo = round(quantile(BA, .025), 1), BA_hi = round(quantile(BA, .975), 1), TPH_lo = round(quantile(TPH, .025)), TPH_hi = round(quantile(TPH, .975)), QMD_lo = round(quantile(QMD, .025), 1), QMD_hi = round(quantile(QMD, .975), 1)), by = .(level, year)][order(match(level, c("lo", "md", "hi")), year)])
worse <- any(unlist(g0) & !unlist(gQ)); cat("\n(6) checks: clean bootstrap share at least 90%:", mean(ok) >= 0.9, "; no gate lost:", !worse, "; rate within the observed range:", max(SQ[planted == 0, ING]) <= mxo, "\n")
saveRDS(list(b = F$b, mu2 = F$mu2, BT = BT, S0 = S0, S1 = S1, SQ = SQ, BD = BD), "out/ingrowth_50.rds"); cat("done\n")
