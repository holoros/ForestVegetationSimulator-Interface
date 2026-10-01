## stage1_garcia_v103.R (koa v103). Stage 1 irregular mortality gate (fitB of koa_origin_20260916/origin_refit_span.R), the Garcia allometry
## ln QMD0 = A + k_HD ln H40_0, the anchored beta (100 / sqrt(z99 of N H_QMD^2)), and the Garcia alpha check and H_QMD re-anchor refits
## (track3/garcia scripts of v102), each first reproduced on its v102 (or record) input, then run on v103.
suppressPackageStartupMessages(library(jsonlite))
setwd("~/jobs/koa_v103_20260930/track2/stage1"); J <- path.expand("~/jobs/koa_v102_20260918"); W <- path.expand("~/jobs/koa_v103_20260930")
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
nocoord <- function(d) stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
OUT <- list()
## ---------------------------------------------------------------- Stage 1 (and Stage 2)
fitB <- function(d) {
  s1 <- glm(any_mort ~ log(pmax(sdi, 1)) + planted, family = binomial(link = "cloglog"), offset = log(yip), data = d)
  dm <- d[d$any_mort & d$m_ann > 0, ]; s2 <- lm(log(m_ann) ~ log(pmax(sdi, 1)) + planted, data = dm)
  list(s1 = s1, s2 = s2, pbar = mean(1 - exp(-exp(predict(s1, newdata = transform(d, yip = 1), type = "link")))), duan = mean(exp(residuals(s2))), n = nrow(d),
       nplots = length(unique(paste(d$Data, d$Install, d$Plot))), nmort = nrow(dm), uncond_w = weighted.mean(d$m_ann, d$expf_alive)) }
js <- fromJSON(file.path(J, "track2/engine_v102/out_stage1/stage1_fit.json"))
ORT <- read.csv(file.path(W, "inputs/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORT$Install[ORT$Origin_new == "Planted"])
remS <- setNames(strsplit(as.character(ORT$removal_t1_years), ";"), as.character(ORT$Install)); remS <- lapply(remS, function(x) as.integer(x[!is.na(x) & x != "NA" & x != ""]))
prep_pi <- function(pi0) { pi0$any_mort <- as.logical(pi0$any_mort); pi1 <- pi0; pi1$planted_old <- pi1$planted; isp <- pi1$Data == "PSP"
  pi1$planted[isp] <- as.integer(as.character(pi1$Install[isp]) %in% psp_planted)
  pi1$removal <- mapply(function(d, i, t0, t1) d == "PSP" && as.character(i) %in% names(remS) && (as.integer(t1) %in% remS[[as.character(i)]] || any(remS[[as.character(i)]] > t0 & remS[[as.character(i)]] < t1)), pi1$Data, pi1$Install, pi1$m_from, pi1$m_to)
  pi1 }
p102 <- prep_pi(read.csv(file.path(J, "frames/plot_intervals_v102_keydedup.csv"), stringsAsFactors = FALSE)); nocoord(p102)
b102 <- fitB(p102[!p102$removal, ])
g1 <- max(abs(coef(b102$s1) - unlist(js$stage1_beta))); g2 <- max(abs(coef(b102$s2) - unlist(js$stage2_beta))); gp <- abs(b102$pbar - js$stage1_mean_annual_p)
logm("STAGE 1 REPRODUCTION on plot_intervals_origin_v102 (", b102$n, "intervals ): max abs diff S1", signif(g1, 3), "S2", signif(g2, 3), "pbar", signif(gp, 3), if (max(g1, g2, gp) < 1e-9) "PASS" else "FAIL")
remy <- lapply(seq_len(nrow(ORT)), function(i) { y <- c(ORT$Thin_Yr[i], suppressWarnings(as.numeric(unlist(strsplit(as.character(ORT$removal_t1_years[i]), ";"))))); unique(y[is.finite(y)]) }); names(remy) <- as.character(ORT$Install)
p103 <- prep_pi(read.csv(file.path(W, "frames/final/plot_intervals_v103.csv"), stringsAsFactors = FALSE)); nocoord(p103)
p103$spans_thin <- mapply(function(d, i, t0, t1) d == "PSP" && !is.null(remy[[as.character(i)]]) && any(remy[[as.character(i)]] > t0 & remy[[as.character(i)]] < t1), p103$Data, p103$Install, p103$m_from, p103$m_to)
logm("v103 plot_intervals rows", nrow(p103), "| removal flag", sum(p103$removal), "| additionally spanning a Thin_Yr or removal year (refit2 screen)", sum(p103$spans_thin & !p103$removal))
d103 <- p103[!p103$removal & !p103$spans_thin, ]
b103 <- fitB(d103)
set.seed(20260916); kk <- paste(d103$Data, d103$Install, d103$Plot); keys <- unique(kk); idx <- split(seq_len(nrow(d103)), kk)
B <- t(replicate(2000, { s <- sample(keys, length(keys), TRUE); d <- d103[unlist(idx[s], use.names = FALSE), ]; tryCatch({ f <- fitB(d); c(coef(f$s1), coef(f$s2), f$pbar) }, error = function(e) rep(NA, 7)) }))
ci <- apply(B, 2, quantile, c(0.025, 0.975), na.rm = TRUE); bse <- apply(B, 2, sd, na.rm = TRUE)
S1 <- data.frame(term = c("s1_intercept", "s1_lnSDI", "s1_planted", "s2_intercept", "s2_lnSDI", "s2_planted", "pbar"),
  v102 = c(coef(b102$s1), coef(b102$s2), b102$pbar), v102_lo = c(unlist(js$stage1_ci$intercept)[1], js$stage1_ci$lnSDI[1], js$stage1_ci$planted[1], js$stage2_ci$intercept[1], js$stage2_ci$lnSDI[1], js$stage2_ci$planted[1], NA),
  v102_hi = c(unlist(js$stage1_ci$intercept)[2], js$stage1_ci$lnSDI[2], js$stage1_ci$planted[2], js$stage2_ci$intercept[2], js$stage2_ci$lnSDI[2], js$stage2_ci$planted[2], NA),
  v103 = c(coef(b103$s1), coef(b103$s2), b103$pbar), v103_boot_se = bse, v103_lo = ci[1, ], v103_hi = ci[2, ])
S1$v102_se_approx <- (S1$v102_hi - S1$v102_lo) / 3.92; S1$dz <- (S1$v103 - S1$v102) / S1$v102_se_approx
print(S1); write.csv(S1, "stage1_v103.csv", row.names = FALSE)
cat(sprintf("Stage 1 n %d -> %d, plots %d -> %d, with mortality %d -> %d, duan %.5f -> %.5f\n", b102$n, b103$n, b102$nplots, b103$nplots, b102$nmort, b103$nmort, b102$duan, b103$duan))
js2 <- js; js2$stage1_beta <- as.list(setNames(coef(b103$s1), c("intercept", "lnSDI", "planted"))); js2$stage2_beta <- as.list(setNames(coef(b103$s2), c("intercept", "lnSDI", "planted")))
js2$stage1_ci <- list(intercept = ci[, 1], lnSDI = ci[, 2], planted = ci[, 3]); js2$stage2_ci <- list(intercept = ci[, 4], lnSDI = ci[, 5], planted = ci[, 6])
js2$stage1_mean_annual_p <- b103$pbar; js2$stage2_duan <- b103$duan; js2$n_intervals <- b103$n; js2$n_plots <- b103$nplots; js2$n_with_mortality <- b103$nmort; js2$obs_uncond_weighted <- b103$uncond_w
js2$stage1_auc <- NULL; js2$note <- "v103 2026-09-30: plot_intervals_origin with sdi repaired from the live all species list, the copied 2015 Keauhou visits merged out, refit2 removal screen added"
write(toJSON(js2, auto_unbox = TRUE, digits = NA, pretty = TRUE), "stage1_fit_v103.json")
## ---------------------------------------------------------------- Garcia allometry
allo <- function(f) { p <- read.csv(f, stringsAsFactors = FALSE); nocoord(p); p$irreg <- as.logical(toupper(as.character(p$irreg)))
  reg <- p[!p$irreg & !is.na(p$H40_0) & !is.na(p$H40_1) & p$H40_0 > 0 & p$H40_1 > 0 & !is.na(p$SDI0), ]; reg <- reg[reg$QMD0 > 0, ]
  m <- lm(log(QMD0) ~ log(H40_0), data = reg); s <- summary(m)
  c(A = coef(m)[[1]], K_HD = coef(m)[[2]], se_A = s$coefficients[1, 2], se_K = s$coefficients[2, 2], n = nrow(reg), plots = length(unique(reg$key)), r2 = s$r.squared, rmse = s$sigma) }
AL <- rbind(record = allo(file.path(J, "inputs/plot_interval_pairs_DATA_record.csv")), v102 = allo(file.path(J, "frames/plot_interval_pairs_DATA_v102.csv")), v103 = allo(file.path(W, "frames/final/plot_interval_pairs_DATA_v103.csv")))
print(AL); write.csv(AL, "garcia_allometry_v103.csv")
ga <- abs(AL["record", "A"] - (-0.16863070512157105)) + abs(AL["record", "K_HD"] - 1.1719473700506686)
logm("ALLOMETRY REPRODUCTION on the record pair table: A", AL["record", "A"], "K_HD", AL["record", "K_HD"], "n", AL["record", "n"], "abs diff", signif(ga, 3), if (ga < 1e-9) "PASS" else "FAIL (see garcia_allometry_v103.csv)")
## ---------------------------------------------------------------- anchored beta
z99f <- function(tf, A, K, mode) { t <- read.csv(tf, stringsAsFactors = FALSE); nocoord(t); if ("KeyDupFlag" %in% names(t)) t <- t[t$KeyDupFlag == 0, ]
  t$key <- paste(t$Data, t$Install, t$Plot, t$Measure); L <- t[t$Status == "live" & t$DBH > 0 & t$EXPF > 0, ]
  g <- split(L, L$key); g <- g[sapply(g, nrow) >= 5]
  z <- sapply(g, function(x) { if (mode == "list") { N <- sum(x$EXPF); Q <- sqrt(sum(x$EXPF * x$DBH^2) / N) } else { N <- x$TPH[1]; Q <- x$QMD[1] }; N * exp((log(Q) - A) / K)^2 })
  c(z99 = unname(quantile(z, 0.99)), n = length(z), beta = 100 / sqrt(unname(quantile(z, 0.99)))) }
BA <- rbind(record_list = z99f(file.path(J, "inputs/AK_TREE_record.csv"), -0.16863070512157105, 1.1719473700506686, "list"),
            record_plotcols = z99f(file.path(J, "inputs/AK_TREE_record.csv"), -0.16863070512157105, 1.1719473700506686, "plot"),
            v103_plotcols_newallo = z99f(file.path(W, "inputs/AK_TREE_v103.csv"), AL["v103", "A"], AL["v103", "K_HD"], "plot"),
            v103_list_newallo = z99f(file.path(W, "inputs/AK_TREE_v103.csv"), AL["v103", "A"], AL["v103", "K_HD"], "list"))
print(BA); write.csv(BA, "garcia_beta_anchor_v103.csv")
logm("BETA ANCHOR REPRODUCTION: record z99 target 389696.30682452075 n 471; list form", BA["record_list", "z99"], BA["record_list", "n"], "| plot column form", BA["record_plotcols", "z99"], BA["record_plotcols", "n"])
## ---------------------------------------------------------------- Garcia alpha checks
src <- readLines(file.path(Sys.getenv("HOME"), "jobs/koa_mort3/koa_mortality_3stage_FINAL_2026-09-04.R"))
eval(parse(text = src[grep("^garcia_lnS2 <- function", src):(grep("^pred_garcia <- function", src))]))
rem <- setNames(lapply(strsplit(as.character(ORT$removal_t1_years), ";"), as.integer), as.character(ORT$Install))
gcheck <- function(f, seed = 20260916) { pairs <- read.csv(f, stringsAsFactors = FALSE); pairs$irreg <- as.logical(toupper(as.character(pairs$irreg)))
  pairs$removal <- mapply(function(d, i, m1) d == "PSP" && !is.null(rem[[as.character(i)]]) && m1 %in% rem[[as.character(i)]], pairs$Data, pairs$Install, pairs$m1)
  mk <- function(pairs) { reg <- pairs[!pairs$irreg & !is.na(pairs$H40_0) & !is.na(pairs$H40_1) & pairs$H40_0 > 0 & pairs$H40_1 > 0 & !is.na(pairs$SDI0), ]
    reg$S0 <- 100 / sqrt(reg$N0); reg$S1 <- 100 / sqrt(reg$N1); reg$lnS1 <- log(reg$S1); reg$ty <- reg$ntree * reg$YIP; reg$w <- sqrt(reg$ntree); reg }
  r0 <- mk(pairs); r1 <- mk(pairs[!pairs$removal, ]); f0 <- fit_garcia(r0, 1); f1 <- fit_garcia(r1, 1)
  set.seed(seed); keys <- unique(r1$key); idx <- split(seq_len(nrow(r1)), r1$key)
  B <- t(replicate(500, { s <- sample(keys, replace = TRUE); fit_garcia(r1[unlist(idx[s], use.names = FALSE), ], 1)[1:2] }))
  data.frame(set = c("published_set", "removals_excluded"), rbind(f0, f1), n_regular = c(nrow(r0), nrow(r1)), alpha_lo = c(NA, quantile(B[, 1], .025)), alpha_hi = c(NA, quantile(B[, 1], .975))) }
G102 <- gcheck(file.path(J, "frames/plot_interval_pairs_DATA_v102.csv")); D102 <- read.csv(file.path(J, "track3/garcia/D_garcia_check.csv"))
gg <- max(abs(G102$alpha - D102$alpha), abs(G102$beta - D102$beta), abs(G102$alpha_lo - D102$alpha_lo), abs(G102$alpha_hi - D102$alpha_hi), na.rm = TRUE)
logm("GARCIA CHECK REPRODUCTION v102 max abs diff", signif(gg, 3), if (gg < 1e-6) "PASS" else "FAIL"); print(G102)
G103 <- gcheck(file.path(W, "frames/final/plot_interval_pairs_DATA_v103.csv")); print(G103)
write.csv(rbind(cbind(frame = "v102", G102), cbind(frame = "v103", G103)), "garcia_check_v103.csv", row.names = FALSE)
logm("STAGE1 GARCIA DONE")
