## inc_fit.R <resp> <cand>: full-data fit (two starts), LOSO, strata, monotonicity grid. Env KOA_POP (default 741.7117; 923 for the code gate).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_inc.R"))
a <- commandArgs(trailingOnly = TRUE); resp <- a[1]; cand <- a[2]; FORM <- CAND_FORM[[cand]]; GUARD <- if (resp == "dDBH") 45 else 20
tag <- if (POP != 741.7117) sprintf("%s_%s_pop%s", resp, cand, round(POP)) else sprintf("%s_%s", resp, cand)
d <- base_frame(resp); logm(tag, "FORM", FORM, "rows", nrow(d), "trees", length(unique(d$TreeID)), "installations", length(unique(paste(d$Data, d$Install))), "POP", POP)
cf <- read.csv(path.expand("~/jobs/koa_v105d_20261102/out/inc/coefficients_v103.csv"), stringsAsFactors = FALSE)
dep <- with(cf[cf$fit == paste0(resp, "_L_NO"), ], setNames(estimate, term))
getB <- function(cn) { f <- file.path(OUT, sprintf("inc_%s_%s.rds", resp, cn)); if (!file.exists(f)) stop("need ", f); readRDS(f)$b }
r <- 923 / POP
starts <- switch(FORM,
  K3c1 = list(a = dep, b = replace(dep, c("b4", "b6"), c(dep[["b4"]] / r, dep[["b6"]] / sqrt(r)))),
  MOD = { B <- getB("B"); list(a = c(B, lc = log(-B[["b4"]]), ld = 0), b = c(B, lc = log(-B[["b4"]] / 2), ld = log(0.5))) },
  MODRD = { B <- getB("B"); M <- getB(if (resp == "dDBH") "D1" else "T1"); list(a = c(M, lg = log(0.05)), b = c(B, lc = log(-B[["b4"]]), ld = 0, lg = log(0.3))) },
  MODC2 = { M <- getB(if (resp == "dDBH") "D1" else "T1"); list(a = c(M, b10 = 0), b = c(M, b10 = -0.002)) },
  CRRD = { B <- getB("B"); list(a = replace(B, "b6", -0.1), b = replace(B, "b6", -1)) })
FT <- list(); SL <- list()
for (s in names(starts)) { t0 <- Sys.time(); m <- fitF(resp, d, starts[[s]]); FT[[s]] <- m
  SL[[s]] <- data.frame(start = s, ok = !is.null(m), logLik = if (is.null(m)) NA else as.numeric(logLik(m)), mins = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2))
  logm("  start", s, "ok", SL[[s]]$ok, "logLik", round(SL[[s]]$logLik, 4), "(", SL[[s]]$mins, "min)") }
SL <- do.call(rbind, SL); if (all(!SL$ok)) { saveRDS(list(ok = FALSE, starts = SL), file.path(OUT, sprintf("inc_%s.rds", tag))); stop("both starts failed") }
m <- FT[[SL$start[which.max(SL$logLik)]]]; b <- nlme::fixef(m); tt <- summary(m)$tTable; cc <- solve_cF(resp, d, b)
logm("  kept logLik", round(as.numeric(logLik(m)), 4), "AIC", round(AIC(m), 3), "df", attr(logLik(m), "df"), "; fixef", paste(sprintf("%s %.6g", names(b), b), collapse = " "), "; c", paste(round(cc, 4), collapse = " "))
## signs
sg <- c(b1_pos = b[["b1"]] > 0); if (resp == "dDBH") sg <- c(sg, b5_pos = b[["b5"]] > 0)
if (FORM %in% c("K3c1", "CRRD")) sg <- c(sg, b4_neg = b[["b4"]] < 0); if (FORM == "CRRD") sg <- c(sg, b6_neg = b[["b6"]] < 0)
if (FORM == "K3c1" && resp == "dDBH") sg <- c(sg, b6_neg = b[["b6"]] < 0)
## strata
per <- pa_pred(resp, d, b) * cc[ifelse(d$Planted == 1, "planted", "natural")]; ao <- d[[resp]] / d$YIP; ap <- per / d$YIP
q5 <- d$BALo.0 >= quantile(d$BALo.0, 0.8); big <- if (resp == "dDBH") d$DBH.0 > 40 & d$DBH.0 <= 60 else d$HT.0 > 20 & d$HT.0 <= 30
ST <- data.frame(ratio_all = sum(ao) / sum(ap), ratio_bigclass = sum(ao[big]) / sum(ap[big]), ratio_BALQ5 = sum(ao[q5]) / sum(ap[q5]))
## LOSO
LO <- list(); if (POP == 741.7117) for (ho in c("DOFAW", "FIA", "KMR PSP", "PSP")) { tr <- d[d$Data != ho, ]; te <- d[d$Data == ho, ]; t1 <- Sys.time(); mm <- fitF(resp, tr, b)
  row <- data.frame(heldout = ho, n_test = nrow(te), ok = FALSE, rmse_log = NA, bias_log = NA)
  if (!is.null(mm)) { b2 <- nlme::fixef(mm); c2 <- tryCatch(solve_cF(resp, tr, b2), error = function(e) NULL)
    if (!is.null(c2) && all(is.finite(c2))) { pr <- pa_pred(resp, te, b2) * c2[ifelse(te$Planted == 1, "planted", "natural")]
      if (all(is.finite(pr))) { lo <- log(te[[resp]] / te$YIP); lp <- log(pmax(pr, 1e-6) / te$YIP); row$ok <- TRUE; row$rmse_log <- rmse(lo, lp); row$bias_log <- mean(lp - lo) } } }
  logm("  LOSO", ho, "ok", row$ok, "rmse_log", round(row$rmse_log, 4), "(", round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 1), "min)"); LO[[ho]] <- row }
LO <- if (length(LO)) do.call(rbind, LO) else NULL
## monotonicity grid (observed range)
P <- function(v, k) seq(quantile(v, .01), quantile(v, .99), length.out = k); sz <- if (resp == "dDBH") c(d$DBH.0) else c(d$HT.0)
S <- P(sz, 20); CR <- P(c(d$CRx.0, d$CRx.1), 5); BY <- P(d$BYI, 5); xmax <- max(d$XK.0, d$XK.1); rdmin <- quantile(c(d$RD.0, d$RD.1), .01); rdmax <- max(d$RD.0, d$RD.1)
Xg <- seq(0, xmax, length.out = 31); RDg <- seq(rdmin, rdmax, length.out = 31); RDa <- seq(rdmin, rdmax, length.out = 5); SH <- seq(0, 1, 0.1); h <- 1e-6
A <- expand.grid(s = S, cr = CR, by = BY, pl = 0:1, x = Xg, rd = RDa); A <- A[A$x <= A$rd + 1e-12, ]   # x = share RD cannot exceed RD
A$fd <- (lng1(resp, b, A$s, A$x + h, A$rd, A$cr, A$by, A$pl) - lng1(resp, b, A$s, pmax(A$x - h, 0), A$rd, A$cr, A$by, A$pl)) / (A$x + h - pmax(A$x - h, 0))
Bg <- expand.grid(s = S, cr = CR, by = BY, pl = 0:1, sh = SH, rd = RDg)
Bg$fd <- (lng1(resp, b, Bg$s, Bg$sh * (Bg$rd + h), Bg$rd + h, Bg$cr, Bg$by, Bg$pl) - lng1(resp, b, Bg$s, Bg$sh * (Bg$rd - h), Bg$rd - h, Bg$cr, Bg$by, Bg$pl)) / (2 * h)
MO <- data.frame(wrt = c("x_at_fixed_RD", "RD_at_fixed_share"), n = c(nrow(A), nrow(Bg)), n_pos = c(sum(A$fd > 1e-8), sum(Bg$fd > 1e-8)), max_deriv = c(max(A$fd), max(Bg$fd)),
                 xmax_obs = xmax, rdmax_obs = rdmax)
MO$pass <- MO$n_pos == 0; logm("  mono", paste(MO$wrt, MO$n_pos, "of", MO$n, "positive, max", signif(MO$max_deriv, 4), collapse = " | "))
## dominant / suppressed split of the RD derivative (reported)
MOs <- aggregate(fd ~ sh, Bg, function(v) c(n_pos = sum(v > 1e-8), max = max(v))); 
res <- list(ok = TRUE, resp = resp, cand = cand, form = FORM, pop = POP, b = b, tTable = tt, logLik = as.numeric(logLik(m)), aic = AIC(m), df = attr(logLik(m), "df"),
            n = nrow(d), cc = cc, sign = sg, strata = ST, loso = LO, starts = SL, mono = MO, mono_by_share = MOs, sigma = m$sigma)
saveRDS(res, file.path(OUT, sprintf("inc_%s.rds", tag))); logm("INC DONE", tag)
