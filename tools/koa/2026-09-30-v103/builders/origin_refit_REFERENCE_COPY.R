## origin_refit.R (September 16, 2026). Stand-origin correction for the koa system.
## The PSP network (32 installations) is coded Natural in every deposit file but is plantation
## (PSP_PLOT CStratum, PLNT_DATE, per-tree Date Planted), except PSP 122 (FSI scarified regeneration).
## Many PSP intervals also carry thinning removals recorded as deaths.
## Stage A refits the increment equations (Eq. 4) with Planted recoded, after a reproduction gate.
## Stage B refits Stage 1 and Stage 2 of the mortality structure on the plot-interval table with
## Planted recoded and removal intervals excluded, after a reproduction gate.
## Headless. Every stage logs to run.log and writes to out/. Seed 20260916.
suppressPackageStartupMessages({library(nlme); library(jsonlite)})
set.seed(20260916)
OUT <- "out"; dir.create(OUT, showWarnings = FALSE)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
ORIG <- read.csv("psp_origin_thinning_2026-09-16_DATA.csv", stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
rem <- setNames(strsplit(as.character(ORIG$removal_t1_years), ";"), as.character(ORIG$Install))
rem <- lapply(rem, function(x) as.integer(x[!is.na(x) & x != "NA" & x != ""]))
recode <- function(d, data_col = "Data", inst_col = "Install") {
  isp <- d[[data_col]] == "PSP"
  d$Planted_old <- d$Planted
  d$Planted[isp] <- as.integer(as.character(d[[inst_col]][isp]) %in% psp_planted)
  d
}
STAGE <- Sys.getenv("KOA_STAGE", "AB")

## ---------------------------------------------------------------- Stage A, increments
gr.hat2 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, temp, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9) {
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + b3 * (bal.c^2 / log(pd.c + 5)) + b4 * log(bal.c + 1) + b5 * log(cr.c) +
                b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pd.c + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1
}
fit_inc <- function(resp, dat, start) {
  f <- as.formula(sprintf("%s ~ gr.hat2(d1 = %s, bal1 = BAL.0, bal2 = BAL.1, cr1 = CR.0, cr2 = CR.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, temp = temp, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0)",
                          resp, if (resp == "dDBH") "DBH.0" else "HT.0"))
  nlme(f, data = dat, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 ~ 1, random = b0 ~ 1 | Data/Install,
       start = start, weights = varPower(0.2, form = ~DBH.0), na.action = na.omit,
       control = nlmeControl(maxIter = 200, pnlsMaxIter = 20, msMaxIter = 200, minScale = 1e-10, returnObject = TRUE))
}
inc_stats <- function(m, dat, resp) {
  d <- getData(m); if (is.null(d)) d <- dat
  y <- d[[resp]]; f1 <- fitted(m, level = 2); f0 <- fitted(m, level = 0)
  vc <- as.numeric(VarCorr(m)[c(2, 4), 1]); cf <- exp(0.5 * sum(vc))
  ann <- y / d$YIP
  r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2)
  pa_ann <- f0 / d$YIP * cf
  data.frame(resp = resp, n = length(y), n_planted = sum(d$Planted == 1), r2_cond_period = r2(y, f1), r2_pa_period = r2(y, f0),
             cf_marginal = cf, tau_source = sqrt(vc[1]), tau_inst = sqrt(vc[2]),
             obs_mean_ann = mean(ann), pa_mean_ann_cf = mean(pa_ann), pa_bias_ann = mean(ann - pa_ann),
             pa_bias_natural = mean((ann - pa_ann)[d$Planted == 0]), pa_bias_planted = mean((ann - pa_ann)[d$Planted == 1]),
             obs_mean_natural = mean(ann[d$Planted == 0]), obs_mean_planted = mean(ann[d$Planted == 1]))
}
tab_coef <- function(m, lab) {
  s <- summary(m)$tTable
  data.frame(model = lab, term = rownames(s), estimate = s[, 1], se = s[, 2], t = s[, 4], p = s[, 5], row.names = NULL)
}
if (grepl("A", STAGE)) {
  for (spec in list(list(resp = "dDBH", rda = "dDBH_BYI.rda", obj = "dDBH.m3", csv = "dDBH.csv"),
                    list(resp = "dHT", rda = "dHT_BYI.rda", obj = "dHT.m3", csv = "dHT.csv"))) {
    res <- tryCatch({
      e <- new.env(); load(spec$rda, envir = e); m0 <- e[[spec$obj]]; b0 <- fixef(m0)
      dat <- read.csv(spec$csv, stringsAsFactors = FALSE)
      assign(spec$resp, dat, envir = globalenv())
      logm(spec$resp, "rows", nrow(dat), "planted", sum(dat$Planted == 1), "PSP rows", sum(dat$Data == "PSP"))
      ## reproduction gate: refit on the published frame from the published solution
      mr <- fit_inc(spec$resp, dat, b0)
      rel <- max(abs(fixef(mr) - b0) / pmax(abs(b0), 1e-8))
      logm(spec$resp, "reproduction max relative change in fixef", signif(rel, 3))
      gate <- rel < 0.01
      write.csv(data.frame(resp = spec$resp, max_rel_change = rel, pass = gate), file.path(OUT, sprintf("A_%s_reproduction_gate.csv", spec$resp)), row.names = FALSE)
      if (!gate) stop("reproduction gate failed")
      dn <- recode(dat)
      logm(spec$resp, "recoded planted rows", sum(dn$Planted == 1), "changed", sum(dn$Planted != dn$Planted_old))
      mn <- fit_inc(spec$resp, dn, b0)
      save(mn, file = file.path(OUT, sprintf("A_%s_origin_refit.rda", spec$resp)))
      write.csv(rbind(tab_coef(mr, "published_frame"), tab_coef(mn, "origin_recoded")), file.path(OUT, sprintf("A_%s_coefficients.csv", spec$resp)), row.names = FALSE)
      write.csv(as.matrix(vcov(mn)), file.path(OUT, sprintf("A_%s_vcov_origin.csv", spec$resp)))
      st <- rbind(cbind(model = "published_frame", inc_stats(mr, dat, spec$resp)), cbind(model = "origin_recoded", inc_stats(mn, dn, spec$resp)))
      write.csv(st, file.path(OUT, sprintf("A_%s_stats.csv", spec$resp)), row.names = FALSE)
      print(st); print(tab_coef(mn, "origin_recoded"))
      "ok"
    }, error = function(err) { logm("STAGE A FAILED", spec$resp, conditionMessage(err)); "fail" })
    logm("stage A", spec$resp, res); gc()
  }
}

## ---------------------------------------------------------------- Stage B, Stage 1 and Stage 2
if (grepl("B", STAGE)) {
  res <- tryCatch({
    pi0 <- read.csv("plot_intervals.csv", stringsAsFactors = FALSE)
    js <- fromJSON("stage1_fit.json")
    fitB <- function(d) {
      s1 <- glm(any_mort ~ log(pmax(sdi, 1)) + planted, family = binomial(link = "cloglog"), offset = log(yip), data = d)
      dm <- d[d$any_mort & d$m_ann > 0, ]
      s2 <- lm(log(m_ann) ~ log(pmax(sdi, 1)) + planted, data = dm)
      list(s1 = s1, s2 = s2, pbar = mean(1 - exp(-exp(predict(s1, newdata = transform(d, yip = 1), type = "link") ))),
           duan = mean(exp(residuals(s2))), n = nrow(d), nplots = length(unique(paste(d$Data, d$Install, d$Plot))), nmort = nrow(dm),
           uncond = sum(d$expf_died) / sum(d$expf_alive * d$yip) , uncond_w = weighted.mean(d$m_ann, d$expf_alive))
    }
    pi0$any_mort <- as.logical(pi0$any_mort)
    b_old <- fitB(pi0)
    g1 <- max(abs(coef(b_old$s1) - unlist(js$stage1_beta)))
    g2 <- max(abs(coef(b_old$s2) - unlist(js$stage2_beta)))
    logm("stage B reproduction: max abs diff S1", signif(g1, 3), "S2", signif(g2, 3), "pbar", b_old$pbar, "json", js$stage1_mean_annual_p)
    gate <- g1 < 1e-4 && g2 < 1e-4
    pi1 <- pi0; pi1$planted_old <- pi1$planted
    isp <- pi1$Data == "PSP"
    pi1$planted[isp] <- as.integer(as.character(pi1$Install[isp]) %in% psp_planted)
    pi1$removal <- mapply(function(d, i, t1) d == "PSP" && as.character(i) %in% names(rem) && as.integer(t1) %in% rem[[as.character(i)]], pi1$Data, pi1$Install, pi1$m_to)
    logm("PSP intervals", sum(isp), "recoded planted", sum(pi1$planted != pi1$planted_old), "removal intervals", sum(pi1$removal))
    pi2 <- pi1[!pi1$removal, ]
    b_new <- fitB(pi2)
    ## plot-clustered bootstrap, 2,000 resamples
    keys <- unique(paste(pi2$Data, pi2$Install, pi2$Plot)); kk <- paste(pi2$Data, pi2$Install, pi2$Plot)
    idx <- split(seq_len(nrow(pi2)), kk)
    B <- t(replicate(2000, { s <- sample(keys, length(keys), TRUE); d <- pi2[unlist(idx[s], use.names = FALSE), ]
      out <- tryCatch({ f <- fitB(d); c(coef(f$s1), coef(f$s2)) }, error = function(e) rep(NA, 6)); out }))
    ci <- apply(B, 2, quantile, c(0.025, 0.975), na.rm = TRUE)
    sm <- function(lab, b, gatepass = NA) data.frame(fit = lab, term = c(paste0("s1_", names(coef(b$s1))), paste0("s2_", names(coef(b$s2)))),
                                                     estimate = c(coef(b$s1), coef(b$s2)), row.names = NULL)
    out <- rbind(sm("published_table", b_old), cbind(sm("origin_recoded_removals_excluded", b_new)))
    out$lo95 <- NA; out$hi95 <- NA
    out[out$fit != "published_table", c("lo95", "hi95")] <- t(ci)
    write.csv(out, file.path(OUT, "B_stage12_coefficients.csv"), row.names = FALSE)
    summ <- data.frame(fit = c("published_table", "origin_recoded_removals_excluded"),
                       n_intervals = c(b_old$n, b_new$n), n_plots = c(b_old$nplots, b_new$nplots), n_with_mortality = c(b_old$nmort, b_new$nmort),
                       pbar = c(b_old$pbar, b_new$pbar), duan = c(b_old$duan, b_new$duan),
                       auc = NA, gate_reproduction = c(gate, NA),
                       share_with_mortality = c(mean(pi0$any_mort), mean(pi2$any_mort)),
                       uncond_weighted = c(b_old$uncond_w, b_new$uncond_w),
                       cond_weighted = c(weighted.mean(pi0$m_ann[pi0$any_mort], pi0$expf_alive[pi0$any_mort]), weighted.mean(pi2$m_ann[pi2$any_mort], pi2$expf_alive[pi2$any_mort])))
    ## background mortality by origin, weighted annual rate on intervals below SDI 200
    bg <- do.call(rbind, lapply(list(published = pi0, recoded = pi2), function(d) {
      do.call(rbind, lapply(0:1, function(p) { s <- d[d$planted == p & d$sdi < 200, ]
        data.frame(origin = ifelse(p == 1, "planted", "natural"), n = nrow(s), w_ann_mort = if (nrow(s)) weighted.mean(s$m_ann, s$expf_alive) else NA,
                   median_ann_mort = if (nrow(s)) median(s$m_ann) else NA) })) }))
    bg$table <- rep(c("published", "recoded"), each = 2)
    write.csv(summ, file.path(OUT, "B_stage12_summary.csv"), row.names = FALSE)
    write.csv(bg, file.path(OUT, "B_background_by_origin.csv"), row.names = FALSE)
    js_new <- js
    js_new$stage1_beta <- as.list(setNames(coef(b_new$s1), c("intercept", "lnSDI", "planted")))
    js_new$stage2_beta <- as.list(setNames(coef(b_new$s2), c("intercept", "lnSDI", "planted")))
    js_new$stage1_ci <- list(intercept = ci[, 1], lnSDI = ci[, 2], planted = ci[, 3])
    js_new$stage2_ci <- list(intercept = ci[, 4], lnSDI = ci[, 5], planted = ci[, 6])
    js_new$stage1_mean_annual_p <- b_new$pbar; js_new$stage2_duan <- b_new$duan
    js_new$n_intervals <- b_new$n; js_new$n_plots <- b_new$nplots; js_new$n_with_mortality <- b_new$nmort
    js_new$obs_uncond_weighted <- b_new$uncond_w
    js_new$stage2_obs_cond_mean_weighted <- summ$cond_weighted[2]
    js_new$note <- "origin recoded (PSP plantations) and PSP thinning-removal intervals excluded, 2026-09-16"
    write(toJSON(js_new, auto_unbox = TRUE, digits = NA, pretty = TRUE), file.path(OUT, "stage1_fit_origin.json"))
    write.csv(pi2, file.path(OUT, "plot_intervals_origin.csv"), row.names = FALSE)
    print(out); print(summ); print(bg)
    "ok"
  }, error = function(err) { logm("STAGE B FAILED", conditionMessage(err)); "fail" })
  logm("stage B", res)
}
logm("ORIGIN REFIT DONE")
