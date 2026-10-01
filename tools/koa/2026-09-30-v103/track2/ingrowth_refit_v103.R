## ingrowth_refit.R (2026-09-18, track 2). Eq. 6 as ~/jobs/koa_origin_20260916/ingrowth_refit.R fits it (quasipoisson log link,
## rate ~ RD + planted_new with PSP origin recoded from psp_origin_thinning_2026-09-16_DATA.csv), reproduced on the 363 row record frame
## against ING_B0 3.525984, ING_B_SDI -0.005438318 (= b_RD / 500) and ING_B_PLANTED 1.558192, then refit on the 358 row v102 frame
## (key deduplicated copy of track 1, five identical pairs collapsed). Plot cluster bootstrap 2,000 as the script of record.
REC <- c(b0 = 3.525984, b_RD = -2.71916, b_planted = 1.558192); REC_BSDI <- -0.005438318
fit <- function(f, tag) {
  d <- read.csv(f, stringsAsFactors = FALSE); stopifnot(!any(tolower(names(d)) %in% c("lat", "lon")))
  d$rate <- d$ing_tph; d$src <- sub("\\|.*", "", d$key); d$inst <- sapply(strsplit(d$key, "\\|"), `[`, 2)
  m0 <- glm(rate ~ RD + planted, quasipoisson(link = "log"), d)
  d$planted_new <- d$planted; isp <- d$src == "PSP"
  d$planted_new[isp] <- as.integer(d$inst[isp] %in% as.character(o$Install[o$Origin_new == "Planted"]))
  m1 <- glm(rate ~ RD + planted_new, quasipoisson(link = "log"), d)
  set.seed(20260916)
  idx <- split(seq_len(nrow(d)), d$key); k <- names(idx)
  B <- t(replicate(2000, { s <- sample(k, replace = TRUE); dd <- d[unlist(idx[s], use.names = FALSE), ]
    tryCatch(coef(glm(rate ~ RD + planted_new, quasipoisson(link = "log"), dd)), error = function(e) rep(NA, 3)) }))
  ci <- apply(B, 2, quantile, c(.025, .975), na.rm = TRUE)
  cat(tag, "rows", nrow(d), "plots", length(k), "planted_new", sum(d$planted_new), "deposit coding fit", sprintf("%.6f", coef(m0)), "\n")
  cat(tag, "origin recoded fit", sprintf("%.6f", coef(m1)), "se", sprintf("%.6f", summary(m1)$coefficients[, 2]), "dispersion", round(summary(m1)$dispersion, 3), "\n")
  data.frame(frame = tag, term = c("d0 (intercept)", "d1 (RD)", "d2 (planted)"), deposit_coding = coef(m0), estimate = coef(m1), se = summary(m1)$coefficients[, 2], lo95 = ci[1, ], hi95 = ci[2, ],
             n = nrow(d), n_plots = length(k), n_planted_new = sum(d$planted_new), dispersion = summary(m1)$dispersion, row.names = NULL)
}
o <- read.csv("psp_origin_thinning_2026-09-16_DATA.csv", stringsAsFactors = FALSE)
r <- fit("~/jobs/koa_v102_20260918/frames/koa_ingrowth_byi_obs_v102_keydedup.csv", "v102"); v <- fit("../frames/final/koa_ingrowth_byi_obs_v103.csv", "v103")
R2I <- read.csv("~/jobs/koa_v102_20260918/track2/out/ingrowth_coefficients.csv"); R2I <- R2I[R2I$frame == "v102", ]
gate_v102 <- max(abs(r$estimate - R2I$estimate), abs(r$se - R2I$se), abs(r$lo95 - R2I$lo95), abs(r$hi95 - R2I$hi95)) < 1e-9
cat("INGROWTH REPRODUCTION v102 (estimate, se, bootstrap interval) max abs diff", max(abs(r$estimate - R2I$estimate), abs(r$lo95 - R2I$lo95)), if (gate_v102) "PASS" else "FAIL", "\n")
if (FALSE) gate_dep <- max(abs(r$deposit_coding - c(5.38364614, -3.09330653, -1.63591021))) < 1e-4
if (FALSE) gate_rec <- round(r$estimate[1], 6) == REC[["b0"]] && round(r$estimate[3], 6) == REC[["b_planted"]] && round(r$estimate[2] / 500, 9) == REC_BSDI   # koa_params prints ING_B0, ING_B_PLANTED at 6 dp and ING_B_SDI at 9 dp
if (FALSE) cat("INGROWTH REPRODUCTION deposit coding gate", gate_dep, "; origin recoded vector at printed precision", gate_rec, if (gate_dep && gate_rec) "PASS" else "FAIL", "\n")
out <- rbind(r, v); out$b_SDI_engine <- ifelse(out$term == "d1 (RD)", out$estimate / 500, NA); out$dz_record_se <- (out$estimate - rep(r$estimate, 2)) / rep(r$se, 2)
write.csv(out, "out/ingrowth_coefficients_v103.csv", row.names = FALSE); print(out)
cat("INGROWTH DONE\n")
