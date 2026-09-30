## incform.R, 2026-09-27. Stress test of the increment equation form on the koa v102 frames.
## EQUATION LEVEL ONLY. This is not a test of full model behavior, which runs only through customRun_fvsRunHi.R.
## Compares, for dDBH and dHT: (A) the deployed nlme fit (raw period increment, annual stepping gr.hat3, random b0 by
## Data/Install, varPower on DBH.0) as the engine uses it (level 0 x CF x origin k); (A0) its level 0 prediction alone;
## (AM) its marginal mean integrated over the fitted random intercept distribution; (B) gnls with the same mean and
## variance function and no random effects; (C) a log linear lm on the annual rate with Duan smearing (reference).
## Each is scored uncalibrated and with origin k refit on the training data, in sample, grouped 10 fold CV by
## installation, and leave one source out. Seed 20260927.
suppressPackageStartupMessages({ library(nlme); library(statmod) })
set.seed(20260927)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
src <- readLines("inc/origin_refit_REFERENCE_COPY.R")
eval(parse(text = src[grep("^gr.hat2 <- function", src):(grep("^fit_inc <- function", src) - 1)]))
ORIG <- read.csv("inc/psp_origin_thinning_2026-09-16_DATA.csv", stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
ENG <- list(dDBH = list(cf = 1.36869, k = c(natural = 0.40548, planted = 1.43606)),
            dHT  = list(cf = 1.030,   k = c(natural = 0.51917, planted = 2.64739)))
MC <- c("DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")
BN <- paste0("b", 0:9)
ctl  <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
gctl <- gnlsControl(maxIter = 200, nlsMaxIter = 50, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
PARS <- b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1
GH <- statmod::gauss.quad(15, kind = "hermite")

prep <- function(resp) {
  d <- read.csv(sprintf("inc/frames/V102/%s.csv", resp), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "latitude", "longitude")))
  d <- d[complete.cases(d[, c(resp, MC)]), ]; isp <- d$Data == "PSP"
  d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  d$inst <- paste(d$Data, d$Install); d$org <- ifelse(d$Planted == 1, "planted", "natural"); d
}
fml <- function(resp) {
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
}
fit_nlme <- function(resp, d, start) nlme(fml(resp), data = d, fixed = PARS, random = b0 ~ 1 | Data/Install, start = start,
                                          weights = varPower(0.2, form = ~DBH.0), control = ctl)
fit_gnls <- function(resp, d, start) gnls(fml(resp), data = d, params = PARS, start = start,
                                          weights = varPower(0.2, form = ~DBH.0), control = gctl)
sz <- function(resp, d) if (resp == "dDBH") d$DBH.0 else d$HT.0
pred_period <- function(resp, d, b) gr.hat3(sz(resp, d), d$BAL.0, d$BAL.1, d$CR.0, d$CR.1, d$BAPH.0, d$BAPH.1, d$Planted, d$BYI, d$YIP,
                                            b[["b0"]], b[["b1"]], b[["b2"]], b[["b3"]], b[["b4"]], b[["b5"]], b[["b6"]], b[["b7"]], b[["b8"]], b[["b9"]])
re_var <- function(m) { vc <- VarCorr(m); vv <- suppressWarnings(as.numeric(vc[grep("^b0$|\\(Intercept\\)", rownames(vc)), 1])); vv[is.finite(vv)] }
pred_marg <- function(resp, d, b, s2) {
  s <- sqrt(s2); out <- 0
  for (j in seq_along(GH$nodes)) { bb <- b; bb[["b0"]] <- b[["b0"]] + sqrt(2) * s * GH$nodes[j]; out <- out + GH$weights[j] / sqrt(pi) * pred_period(resp, d, bb) }
  out
}
ll_frame <- function(resp, d) { x <- sz(resp, d); data.frame(x = x, bal = d$BAL.0, cr = d$CR.0, ba = d$BAPH.0, pl = d$Planted, byi = d$BYI) }
fit_loglin <- function(resp, d) {
  a <- d[[resp]] / d$YIP; keep <- a > 0; dd <- ll_frame(resp, d); dd$y <- NA; dd$y[keep] <- log(a[keep])
  m <- lm(y ~ log(x + 1) + x + I(bal^2 / log(x + 5)) + log(bal + 1) + log(cr) + sqrt(ba * x) + I(pl * x) + log(byi) + I(byi / 1000) + pl, data = dd[keep, ])
  list(m = m, duan = mean(exp(resid(m))), dropped = sum(!keep), n = nrow(d))
}
pred_loglin <- function(f, resp, d) exp(predict(f$m, newdata = ll_frame(resp, d))) * f$duan
kfit <- function(obs, pred, org) { k <- tapply(obs, org, sum) / tapply(pred, org, sum); k }
kapply <- function(pred, org, k) pred * ifelse(is.na(k[org]), 1, k[org])

## annual scale predictions for every method from a fitted set, with k taken from the training rows
predict_all <- function(resp, tr, te, fits) {
  obs_tr <- tr[[resp]] / tr$YIP; P <- list(); K <- list()
  add <- function(lab, ptr, pte) { k <- kfit(obs_tr, ptr, tr$org); P[[lab]] <<- pte; P[[paste0(lab, "_k")]] <<- kapply(pte, te$org, k); K[[lab]] <<- k }
  if (!is.null(fits$nlme)) {
    b <- fixef(fits$nlme); s2 <- sum(re_var(fits$nlme))
    l0_tr <- pred_period(resp, tr, b) / tr$YIP; l0_te <- pred_period(resp, te, b) / te$YIP
    add("A0_nlme_level0", l0_tr, l0_te)
    add("AM_nlme_marginal", pred_marg(resp, tr, b, s2) / tr$YIP, pred_marg(resp, te, b, s2) / te$YIP)
    add("AL_nlme_lognormalCF", l0_tr * exp(s2 / 2), l0_te * exp(s2 / 2))
  }
  if (!is.null(fits$gnls)) { b <- coef(fits$gnls); add("B_gnls", pred_period(resp, tr, b) / tr$YIP, pred_period(resp, te, b) / te$YIP) }
  if (!is.null(fits$ll)) add("C_loglin_duan", pred_loglin(fits$ll, resp, tr), pred_loglin(fits$ll, resp, te))
  list(P = P, K = K)
}
cut_q <- function(x, q) { br <- unique(quantile(x, seq(0, 1, length.out = q + 1), na.rm = TRUE)); as.character(cut(x, br, include.lowest = TRUE, dig.lab = 4)) }
evals <- function(resp, obs, pred, d, method, scheme) {
  strat <- list(all = rep("all", nrow(d)), origin = d$org, source = d$Data, size_quintile = cut_q(sz(resp, d), 5), byi_tercile = cut_q(d$BYI, 3),
                origin_x_size = paste(d$org, cut_q(sz(resp, d), 3)))
  do.call(rbind, lapply(names(strat), function(s) { g <- strat[[s]]; ok <- is.finite(pred)
    do.call(rbind, lapply(split(which(ok), g[ok]), function(i) data.frame(resp = resp, scheme = scheme, method = method, stratum = s, level = g[i[1]], n = length(i),
      obs_mean = mean(obs[i]), pred_mean = mean(pred[i]), bias = mean(obs[i] - pred[i]), rel_bias_pct = 100 * (mean(pred[i]) / mean(obs[i]) - 1),
      rmse = sqrt(mean((obs[i] - pred[i])^2)), r2 = 1 - sum((obs[i] - pred[i])^2) / sum((obs[i] - mean(obs[i]))^2), obs_over_pred = sum(obs[i]) / sum(pred[i])))) }))
}
safe <- function(expr, lab) tryCatch(expr, error = function(e) { logm("FAIL", lab, conditionMessage(e)); NULL })

load("inc/inc_fits.rda")   # FITS from koa_v102_20260918/track2/inc_refit.R
EV <- list(); KT <- list(); CO <- list(); VC <- list(); LL <- list(); SAVE <- list()
for (resp in c("dDBH", "dHT")) {
  d <- prep(resp); obs <- d[[resp]] / d$YIP
  logm(resp, "rows", nrow(d), "installations", length(unique(d$inst)), "sources", paste(names(table(d$Data)), table(d$Data), collapse = " "),
       "planted rows", sum(d$Planted == 1), "BYI min", min(d$BYI), "CR min", min(d$CR.0))
  m_dep <- FITS[[paste(resp, "V102 deployed_solution")]]; m_alt <- FITS[[paste(resp, "V102 record")]]
  stopifnot(!is.null(m_dep), nrow(m_dep$data) == nrow(d))
  ## in sample, deployed nlme as the engine uses it, then every candidate
  b <- fixef(m_dep); eng <- pred_period(resp, d, b) / d$YIP * ENG[[resp]]$cf * ENG[[resp]]$k[d$org]
  EV[[paste(resp, "ins eng")]] <- evals(resp, obs, eng, d, "A_engine_deployed", "in_sample")
  t0 <- Sys.time(); g <- safe(fit_gnls(resp, d, fixef(m_dep)), paste(resp, "gnls full")); logm(resp, "gnls full", round(difftime(Sys.time(), t0, units = "secs")), "s")
  ll <- fit_loglin(resp, d); logm(resp, "loglin dropped nonpositive rows", ll$dropped, "of", ll$n, "Duan", round(ll$duan, 4))
  LL[[resp]] <- data.frame(resp = resp, n = ll$n, dropped_nonpositive = ll$dropped, duan = ll$duan, sigma_log = summary(ll$m)$sigma)
  SAVE[[resp]] <- list(gnls = g, ll = ll)
  for (alt in c("deployed", "record_start")) {
    mm <- if (alt == "deployed") m_dep else m_alt
    if (is.null(mm)) next
    r <- predict_all(resp, d, d, list(nlme = mm, gnls = if (alt == "deployed") g else NULL, ll = if (alt == "deployed") ll else NULL))
    for (lab in names(r$P)) EV[[paste(resp, "ins", alt, lab)]] <- evals(resp, obs, r$P[[lab]], d, if (alt == "deployed") lab else paste0(lab, "@recordstart"), "in_sample")
    for (lab in names(r$K)) KT[[paste(resp, alt, lab)]] <- data.frame(resp = resp, scheme = "in_sample", method = if (alt == "deployed") lab else paste0(lab, "@recordstart"),
                                                                     k_natural = r$K[[lab]][["natural"]], k_planted = r$K[[lab]][["planted"]])
    vv <- re_var(mm); VC[[paste(resp, alt)]] <- data.frame(resp = resp, fit = paste0("nlme_", alt), logLik = as.numeric(logLik(mm)), tau_source = sqrt(vv[1]), tau_inst = sqrt(vv[2]),
      lognormal_cf = exp(sum(vv) / 2), sigma = mm$sigma, varpower = as.numeric(coef(mm$modelStruct$varStruct, unconstrained = FALSE)))
    st <- summary(mm)$tTable; CO[[paste(resp, alt)]] <- data.frame(resp = resp, fit = paste0("nlme_", alt), term = rownames(st), estimate = st[, 1], se = st[, 2], row.names = NULL)
  }
  if (!is.null(g)) {
    st <- summary(g)$tTable; CO[[paste(resp, "gnls")]] <- data.frame(resp = resp, fit = "gnls", term = rownames(st), estimate = st[, 1], se = st[, 2], row.names = NULL)
    VC[[paste(resp, "gnls")]] <- data.frame(resp = resp, fit = "gnls", logLik = as.numeric(logLik(g)), tau_source = NA, tau_inst = NA, lognormal_cf = NA, sigma = g$sigma,
                                            varpower = as.numeric(coef(g$modelStruct$varStruct, unconstrained = FALSE)))
  }
  ## grouped 10 fold CV by installation, installations stratified by origin; then leave one source out
  inst <- unique(d[, c("inst", "org")]); inst <- inst[!duplicated(inst$inst), ]
  fold <- integer(nrow(inst)); for (o in unique(inst$org)) { i <- which(inst$org == o); fold[i] <- sample(rep_len(1:10, length(i))) }
  fmap <- setNames(fold, inst$inst)
  schemes <- list(cv10 = lapply(1:10, function(f) d$inst %in% names(fmap)[fmap == f]),
                  loso = lapply(setNames(unique(d$Data), unique(d$Data)), function(s) d$Data == s))
  for (sc in names(schemes)) {
    PR <- list()
    for (h in seq_along(schemes[[sc]])) {
      te_i <- schemes[[sc]][[h]]; tr <- d[!te_i, ]; te <- d[te_i, ]
      if (length(unique(tr$Data)) < 2) { logm(resp, sc, h, "skipped: one source left"); next }
      t0 <- Sys.time()
      fn <- safe(fit_nlme(resp, tr, fixef(m_dep)), paste(resp, sc, h, "nlme"))
      fg <- safe(fit_gnls(resp, tr, if (is.null(g)) fixef(m_dep) else coef(g)), paste(resp, sc, h, "gnls"))
      fl <- safe(fit_loglin(resp, tr), paste(resp, sc, h, "loglin"))
      r <- predict_all(resp, tr, te, list(nlme = fn, gnls = fg, ll = fl))
      eng_te <- if (!is.null(fn)) { l0tr <- pred_period(resp, tr, fixef(fn)) / tr$YIP; k <- kfit(tr[[resp]] / tr$YIP, l0tr, tr$org); kapply(pred_period(resp, te, fixef(fn)) / te$YIP, te$org, k) } else rep(NA, nrow(te))
      r$P[["A_engine_refit"]] <- eng_te
      for (lab in names(r$P)) { v <- rep(NA_real_, nrow(d)); if (is.null(PR[[lab]])) PR[[lab]] <- v; PR[[lab]][te_i] <- r$P[[lab]] }
      for (lab in names(r$K)) KT[[paste(resp, sc, h, lab)]] <- data.frame(resp = resp, scheme = paste0(sc, "_fold"), method = lab, k_natural = unname(r$K[[lab]]["natural"]), k_planted = unname(r$K[[lab]]["planted"]))
      logm(resp, sc, names(schemes[[sc]])[h], h, "test rows", sum(te_i), "done in", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s",
           "nlme", !is.null(fn), "gnls", !is.null(fg))
      gc()
    }
    for (lab in names(PR)) EV[[paste(resp, sc, lab)]] <- evals(resp, obs, PR[[lab]], d, lab, sc)
  }
}
EV <- do.call(rbind, EV); KT <- do.call(rbind, KT); CO <- do.call(rbind, CO); VC <- do.call(rbind, VC); LL <- do.call(rbind, LL)
write.csv(EV, "out/incform_eval.csv", row.names = FALSE); write.csv(KT, "out/incform_k.csv", row.names = FALSE)
write.csv(CO, "out/incform_coef.csv", row.names = FALSE); write.csv(VC, "out/incform_varcomp.csv", row.names = FALSE); write.csv(LL, "out/incform_loglin.csv", row.names = FALSE)
save(SAVE, file = "out/incform_fits.rda")
logm("INCFORM DONE")
