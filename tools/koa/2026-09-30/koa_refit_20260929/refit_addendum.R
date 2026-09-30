#!/usr/bin/env Rscript
## refit_addendum.R, job koa_refit_20260929. Runs after refit.R.
##  A. Eq. 3 HCB refit under d, l, c: the HCB frame is FIA only and keys on Year (2011, 2019), not Measure (1, 2), so match on Year.
##  B. Installation-cluster bootstrap (2,000) of the recursion-consistent origin constants c_o for the deployed fits, conditional on coefficients.
##  C. Chosen-vector summary (out/deployed_choice.json) for the engine patch: dDBH_c_AP, dHT_c_AP, conventional cohort fraction.
suppressPackageStartupMessages(library(nlme))
set.seed(20260929)
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
IN <- file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918"); OUT <- "out"
nocoord <- function(d) stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2); rmse <- function(o, p) sqrt(mean((o - p)^2))
T <- read.csv(file.path(OUT, "bal_treevisit.csv"), stringsAsFactors = FALSE); T$BALd <- T$BAL
T$tkey <- paste(T$Data, T$Install, T$Plot, T$Measure, T$Tree, sep = "|")
## ---- A. HCB
H <- read.csv(file.path(IN, "frames/AK_HCB_v102_keydedup.csv"), stringsAsFactors = FALSE); nocoord(H)
ih <- match(paste(H$Data, H$Install, H$Plot, H$Year, H$Tree, sep = "|"), T$tkey)
logm("HCB rows", nrow(H), "unmatched to tree table on Year key", sum(is.na(ih)))
for (b in c("d", "l", "c")) H[[paste0("BAL", b)]] <- T[[paste0("BAL", b)]][ih]
logm("HCB deposited BAL equals frame BAL on", round(mean(abs(H$BALd - H$BAL) < 1e-6, na.rm = TRUE) * 100, 1), "% of matched rows")
HCB_P <- c(b0 = 0.1684, b1 = 1.0146, b2 = -0.376, b3 = -0.0078, b4 = -0.3734, b5 = -0.221)
HC <- list()
for (b in c("d", "l", "c")) {
  d <- H[is.finite(H[[paste0("BAL", b)]]) & H$HT > 0 & H$DBH > 0 & H$HCB >= 0 & is.finite(H$BYI) & H$BYI > 0, ]; d$BALx <- d[[paste0("BAL", b)]]; d$inst <- factor(paste(d$Data, d$Install))
  form <- HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / DBH, 0.5)) + b3 * sqrt(BALx * BAPH + 1) + b4 * log(BAPH + 1) + b5 * log(pmax(BYI, 1) / 100))))
  m0 <- tryCatch(nls(form, data = d, start = as.list(HCB_P), control = nls.control(maxiter = 500, warnOnly = TRUE)), error = function(e) { logm("nls", b, conditionMessage(e)); NULL })
  st <- if (!is.null(m0)) coef(m0) else HCB_P
  m1 <- tryCatch(nlme(form, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 ~ 1, random = b0 ~ 1 | inst, start = st, control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)), error = function(e) { logm("nlme", b, conditionMessage(e)); NULL })
  for (nm in c("nls", "nlme")) { m <- if (nm == "nls") m0 else m1; if (is.null(m)) next
    cf <- if (nm == "nls") summary(m)$coefficients else summary(m)$tTable; f0 <- if (nm == "nls") fitted(m) else fitted(m, level = 0)
    HC[[paste(b, nm)]] <- data.frame(bal = b, method = nm, n = nrow(d), term = rownames(cf), estimate = cf[, 1], se = cf[, 2], rmse_pa = rmse(d$HCB, f0), r2_pa = r2(d$HCB, f0),
      tau_inst = if (nm == "nlme") as.numeric(VarCorr(m)[1, "StdDev"]) else NA, aic = AIC(m), row.names = NULL) }
  ## deployed vector RSS on this frame for reference
  eta <- with(d, HCB_P["b0"] + HCB_P["b1"] * sqrt(HT / 100) + HCB_P["b2"] * log(pmax(HT / DBH, 0.5)) + HCB_P["b3"] * sqrt(BALx * BAPH + 1) + HCB_P["b4"] * log(BAPH + 1) + HCB_P["b5"] * log(pmax(BYI, 1) / 100))
  HC[[paste(b, "deployed")]] <- data.frame(bal = b, method = "deployed_HCB_P", n = nrow(d), term = names(HCB_P), estimate = HCB_P, se = NA, rmse_pa = rmse(d$HCB, d$HT / (1 + exp(-eta))), r2_pa = r2(d$HCB, d$HT / (1 + exp(-eta))), tau_inst = NA, aic = NA, row.names = NULL)
  logm("HCB", b, "n", nrow(d), "nls", !is.null(m0), "nlme", !is.null(m1))
}
write.csv(do.call(rbind, HC), file.path(OUT, "hcb_refit.csv"), row.names = FALSE)
## ---- B. bootstrap of c_o for the deployed fits
load(file.path(OUT, "fits.rda"))
gr.hat2 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, temp, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9) {
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + b3 * (bal.c^2 / log(pd.c + 5)) + b4 * log(bal.c + 1) + b5 * log(cr.c) + b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pd.c + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1
}
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
model_cols <- function(d, b) { d$BALx.0 <- d[[paste0("BAL", b, ".0")]]; d$BALx.1 <- d[[paste0("BAL", b, ".1")]]; d$CRx.0 <- d[[paste0("CR", b, ".0")]]; d$CRx.1 <- d[[paste0("CR", b, ".1")]]
  d[complete.cases(d[, c("DBH.0", "HT.0", "BALx.0", "BALx.1", "CRx.0", "CRx.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")]) & d$BYI > 0 & d$CRx.0 > 0 & d$CRx.1 > 0, ] }
pa_pred <- function(resp, d, b) { size <- if (resp == "dDBH") d$DBH.0 else d$HT.0
  gr.hat3(size, d$BALx.0, d$BALx.1, d$CRx.0, d$CRx.1, d$BAPH.0, d$BAPH.1, d$Planted, d$BYI, d$YIP, b["b0"], b["b1"], b["b2"], b["b3"], b["b4"], b["b5"], b["b6"], b["b7"], b["b8"], b["b9"]) }
solve_c1 <- function(resp, dd, b) { f <- function(lc) { bb <- b; bb["b0"] <- b["b0"] + lc; sum(pa_pred(resp, dd, bb)) - sum(dd[[resp]]) }; exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) }
BS <- list()
for (tag in c("dDBH_c_AP", "dHT_c_AP", "dDBH_l_AP", "dHT_l_AP")) {
  cal <- CAL[[tag]]; resp <- cal$resp; d <- model_cols(read.csv(sprintf("frames/%s_AP.csv", resp), stringsAsFactors = FALSE), cal$bal)
  cl <- paste(d$Data, d$Install); ids <- unique(cl); sp <- split(seq_len(nrow(d)), cl)
  p0 <- pa_pred(resp, d, cal$b)   # base prediction at c = 1, reused: c scales the recursion nonlinearly, so solve per draw on the subset
  t0 <- Sys.time()
  bs <- t(replicate(2000, { idx <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE); dd <- d[idx, ]
    sapply(c(natural = 0, planted = 1), function(pl) { s <- dd[dd$Planted == pl, ]; if (nrow(s) < 10) return(NA_real_); tryCatch(solve_c1(resp, s, cal$b), error = function(e) NA_real_) }) }))
  ci <- apply(bs, 2, quantile, c(0.025, 0.975), na.rm = TRUE); selog <- apply(log(bs), 2, sd, na.rm = TRUE)
  BS[[tag]] <- data.frame(fit = tag, origin = c("natural", "planted"), c = cal$cc, c_lo95 = ci[1, ], c_hi95 = ci[2, ], selog = selog, n_draws_ok = colSums(is.finite(bs)))
  logm(tag, "c bootstrap done in", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min;", paste(sprintf("%s %.4f (%.4f to %.4f) selog %.4f", c("nat", "pl"), cal$cc, ci[1, ], ci[2, ], selog), collapse = "; "))
  write.csv(do.call(rbind, BS), file.path(OUT, "c_bootstrap.csv"), row.names = FALSE)
}
## ---- C. deployed choice
ST <- read.csv(file.path(OUT, "fit_stats.csv")); CO <- read.csv(file.path(OUT, "coefficients.csv")); CF <- read.csv(file.path(OUT, "cohort_bal_fraction.csv"))
pick <- function(tag) { s <- ST[ST$fit == tag, ]; co <- CO[CO$fit == tag, ]; list(fit = tag, coef = setNames(as.list(co$estimate), co$term), se = setNames(as.list(co$se), co$term),
  cf_source_inst = s$cf_source_inst, c_natural = s$c_natural, c_planted = s$c_planted, k_natural = s$k_natural, k_planted = s$k_planted, n = s$n, logLik = s$logLik) }
ch <- list(rule = "conventional BAL deployed (preregistered rule: live list did not beat it by > 2% RMSE on the AP frame AND a closer top quintile ratio; RMSE 1.103 vs 1.114 and Q5 ratio 1.076 vs 1.039)",
  frame = "AP (all valid intervals)", bal_definition = "conventional: basal area per ha of live trees strictly larger than the subject",
  dDBH = pick("dDBH_c_AP"), dHT = pick("dHT_c_AP"), cohort_fraction = as.list(CF[CF$bal == "c", ]), alternative_live_list = list(dDBH = pick("dDBH_l_AP"), dHT = pick("dHT_l_AP"), cohort_fraction = as.list(CF[CF$bal == "l", ])))
writeLines(jsonlite::toJSON(ch, auto_unbox = TRUE, pretty = TRUE, digits = NA), file.path(OUT, "deployed_choice.json"))
logm("ADDENDUM DONE"); cat("done\n")
