## inc_refit.R (2026-09-18, track 2). The deployed V3 increment fits (koa_equations.py LineageA.DDBH and DHT) reproduced on the frames
## of record and refit on the v102 frames, exactly as ~/jobs/koa_dedup_refit_20260917/refit.R did (same gr.hat3, random b0 on Data/Install,
## varPower(0.2, ~DBH.0), complete cases on the twelve model columns, PSP Planted recoded from psp_origin_thinning_2026-09-16_DATA.csv,
## start published fixef with b9 = 0). The Duan CF is exp(0.5 (tau_source^2 + tau_inst^2)) from the fit and the origin multipliers follow
## calib.R, k_o = sum obs annual increment / sum(population average prediction x deployed CF) by origin, with the installation cluster
## bootstrap (2,000 resamples) for se_log as calib.R. On V102 the alternative start from the deployed solution is also run as followup.R did.
suppressPackageStartupMessages(library(nlme))
set.seed(20260916)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
src <- readLines("inc/origin_refit_REFERENCE_COPY.R")
eval(parse(text = src[grep("^gr.hat2 <- function", src):(grep("^fit_inc <- function", src) - 1)]))
ORIG <- read.csv("inc/psp_origin_thinning_2026-09-16_DATA.csv", stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
ctl <- nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE)
CFX <- c(dDBH = 1.48254, dHT = 1.030)
DEP <- list(dDBH = c(b0 = -2.0972488, b1 = 0.3105931, b2 = -0.0085285, b3 = -0.0019684, b4 = -0.2899832, b5 = -0.2599003, b6 = -0.0105114, b7 = -0.0258191, b8 = 0.3108402, b9 = 0.4018344),
            dHT = c(b0 = -4.0426171, b1 = 0.9238575, b2 = -0.1099897, b3 = -0.0012181, b4 = -0.0358816, b5 = -1.5423408, b6 = 0.0486628, b7 = -0.1196098, b8 = 0.2471449, b9 = 1.0236256))
CAL_DEP <- list(dDBH = c(natural = 0.38479, planted = 1.58591), dHT = c(natural = 0.52127, planted = 2.65956))
MC <- c("DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2); rmse <- function(o, p) sqrt(mean((o - p)^2))
prep <- function(resp, frame) {
  dat <- read.csv(sprintf("inc/frames/%s/%s.csv", frame, resp), stringsAsFactors = FALSE)
  stopifnot(!any(tolower(names(dat)) %in% c("lat", "lon", "latitude", "longitude")))
  keep <- complete.cases(dat[, c(resp, MC)])
  d <- dat[keep, ]; isp <- d$Data == "PSP"; d$Planted_deposit <- d$Planted
  d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  d
}
fit3 <- function(resp, d, start) {
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install, start = start, weights = varPower(0.2, form = ~DBH.0), control = ctl)
}
summ <- function(m, d, resp, frame, start_lab) {
  s <- summary(m)$tTable
  vc <- VarCorr(m); vv <- suppressWarnings(as.numeric(vc[grep("^b0$|\\(Intercept\\)", rownames(vc)), 1])); vv <- vv[is.finite(vv)]
  cf <- exp(0.5 * sum(vv)); y <- d[[resp]]; f2 <- fitted(m, level = 2); f0 <- fitted(m, level = 0)
  ann <- y / d$YIP; pa <- f0 / d$YIP * CFX[[resp]]; org <- ifelse(d$Planted == 1, "planted", "natural")
  k <- tapply(ann, org, sum) / tapply(pa, org, sum); cal <- pa * k[org]
  cl <- paste(d$Data, d$Install); ids <- unique(cl); sp <- split(seq_along(cl), cl)
  bs <- t(replicate(2000, { ss <- sample(ids, replace = TRUE); idx <- unlist(sp[ss], use.names = FALSE); tapply(ann[idx], org[idx], sum) / tapply(pa[idx], org[idx], sum) }))
  ci <- apply(bs, 2, quantile, c(0.025, 0.975), na.rm = TRUE); selog <- apply(log(bs), 2, sd, na.rm = TRUE)
  list(coef = data.frame(resp = resp, frame = frame, start = start_lab, term = rownames(s), estimate = s[, 1], se = s[, 2], row.names = NULL),
       stat = data.frame(resp = resp, frame = frame, start = start_lab, n = nrow(d), n_planted = sum(d$Planted == 1), n_natural = sum(d$Planted == 0),
         logLik = as.numeric(logLik(m)), aic = AIC(m), tau_source = sqrt(vv[1]), tau_inst = sqrt(vv[2]), sigma = m$sigma,
         varpower = as.numeric(coef(m$modelStruct$varStruct, unconstrained = FALSE)), cf_marginal_fit = cf, cf_deployed_used = CFX[[resp]],
         r2_cond_period = r2(y, f2), r2_pa_period = r2(y, f0), rmse_cond_period = rmse(y, f2), rmse_pa_period = rmse(y, f0),
         r2_pa_ann_cf = r2(ann, pa), rmse_pa_ann_cf = rmse(ann, pa), r2_pa_ann_cal = r2(ann, cal), rmse_pa_ann_cal = rmse(ann, cal),
         k_natural = k[["natural"]], k_planted = k[["planted"]], k_natural_selog = selog[["natural"]], k_planted_selog = selog[["planted"]],
         k_natural_lo95 = ci[1, "natural"], k_natural_hi95 = ci[2, "natural"], k_planted_lo95 = ci[1, "planted"], k_planted_hi95 = ci[2, "planted"]))
}
CO <- list(); ST <- list(); FITS <- list()
for (resp in c("dDBH", "dHT")) {
  e <- new.env(); load(sprintf("inc/%s_BYI.rda", resp), envir = e); b0 <- fixef(e[[ls(e)[1]]])
  for (frame in c("RECORD", "V102")) {
    d <- prep(resp, frame)
    logm(resp, frame, "rows", nrow(d), "planted (recoded)", sum(d$Planted == 1), "PSP", sum(d$Data == "PSP"), "FIA", sum(d$Data == "FIA"))
    starts <- list(record = c(b0, b9 = 0)); if (frame == "V102") starts$deployed_solution <- DEP[[resp]]
    for (sl in names(starts)) {
      t0 <- Sys.time(); m <- fit3(resp, d, starts[[sl]]); r <- summ(m, d, resp, frame, sl)
      CO[[paste(resp, frame, sl)]] <- r$coef; ST[[paste(resp, frame, sl)]] <- r$stat; FITS[[paste(resp, frame, sl)]] <- m
      logm(resp, frame, sl, "done in", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s; logLik", round(r$stat$logLik, 3), "; fixef", paste(sprintf("%.7f", fixef(m)), collapse = " "), "; CF", round(r$stat$cf_marginal_fit, 5), "; k", round(r$stat$k_natural, 5), round(r$stat$k_planted, 5), "; tau_source", signif(r$stat$tau_source, 4))
    }
    gc()
  }
}
CO <- do.call(rbind, CO); ST <- do.call(rbind, ST)
write.csv(CO, "out/inc_coefficients.csv", row.names = FALSE); write.csv(ST, "out/inc_stats.csv", row.names = FALSE); save(FITS, file = "inc/inc_fits.rda")
## reproduction check on RECORD
rep <- do.call(rbind, lapply(c("dDBH", "dHT"), function(resp) {
  cc <- CO[CO$resp == resp & CO$frame == "RECORD", ]; st <- ST[ST$resp == resp & ST$frame == "RECORD", ]
  rbind(data.frame(resp = resp, quantity = cc$term, refit = cc$estimate, deployed = DEP[[resp]][cc$term], digits = 7),
        data.frame(resp = resp, quantity = "CF_marginal", refit = st$cf_marginal_fit, deployed = if (resp == "dDBH") 1.48254 else NA, digits = 5),
        data.frame(resp = resp, quantity = c("CAL_natural", "CAL_planted"), refit = c(st$k_natural, st$k_planted), deployed = CAL_DEP[[resp]], digits = 5))
}))
rep$match <- ifelse(is.na(rep$deployed), NA, round(rep$refit, rep$digits) == round(rep$deployed, rep$digits)); rep$abs_diff <- abs(rep$refit - rep$deployed)
write.csv(rep, "out/inc_reproduction_check.csv", row.names = FALSE); print(rep)
logm("INCREMENT REPRODUCTION", if (all(rep$match[!is.na(rep$match)])) "PASS" else "FAIL")
## which V102 optimum
for (resp in c("dDBH", "dHT")) { s <- ST[ST$resp == resp & ST$frame == "V102", ]; logm(resp, "V102 logLik record start", round(s$logLik[s$start == "record"], 3), "deployed solution start", round(s$logLik[s$start == "deployed_solution"], 3), "; higher:", s$start[which.max(s$logLik)]) }
print(ST[, c("resp", "frame", "start", "n", "logLik", "tau_source", "tau_inst", "cf_marginal_fit", "k_natural", "k_planted", "r2_cond_period", "rmse_cond_period", "r2_pa_ann_cal", "rmse_pa_ann_cal")])
logm("INC DONE")
