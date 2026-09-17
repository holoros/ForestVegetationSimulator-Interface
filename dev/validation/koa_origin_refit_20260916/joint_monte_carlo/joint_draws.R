## joint_draws.R (2026-09-16, v99 round): joint parameter table for the projection Monte Carlo.
## Each row is one replicate. Growth: the four data sources are resampled with replacement (both origins required),
## the V3 increment vectors are drawn from their fixed-effect MVN, and the four origin multipliers are recomputed on the
## resampled frame from the drawn vectors, so source-level and parameter uncertainty enter together and stay correlated.
## Height: the six Chapman-Richards terms drawn jointly from the refit vcov. Stage 1 occurrence: plot-cluster bootstrap
## refit with its mean annual occurrence, accepted only when both origins carry intervals with and without mortality and every
## coefficient is below 8 in absolute value. Natural mortality level: resampled from the plot-cluster bootstrap and rescaled so that
## the gated rate times the factor keeps the bootstrap level on the 23 natural calibration intervals under the drawn Stage 1
## (revision of the v99 round after red team, 2026-09-16).
suppressPackageStartupMessages({ library(nlme); library(MASS); library(jsonlite) })
set.seed(20260918)
N <- as.integer(Sys.getenv("KOA_NJOINT", "500"))   # one row per even-aged replicate; the uneven-aged scenario reads the first 300
RT <- file.path(Sys.getenv("HOME"), "jobs/koa_redteam_20260916/output")
source_lines <- readLines("origin_refit.R")
eval(parse(text = source_lines[grep("^gr.hat2 <- function", source_lines):(grep("^fit_inc <- function", source_lines) - 1)]))
ORIG <- read.csv("psp_origin_thinning_2026-09-16_DATA.csv", stringsAsFactors = FALSE)
psp_planted <- as.character(ORIG$Install[ORIG$Origin_new == "Planted"])
gr.hat3 <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)
  gr.hat2(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, 0, n, b0 + b9 * Planted, b1, b2, b3, b4, b5, b6, b7, b8, 0)
CFX <- c(dDBH = 1.48254, dHT = 1.030)
load("out/G_v3_fits.rda")
FR <- list()
for (resp in c("dDBH", "dHT")) {
  dat <- read.csv(paste0(resp, ".csv"), stringsAsFactors = FALSE)
  keep <- complete.cases(dat[, c(resp, "DBH.0", "HT.0", "BAL.0", "BAL.1", "CR.0", "CR.1", "BAPH.0", "BAPH.1", "Planted", "BYI", "YIP")])
  d <- dat[keep, ]; isp <- d$Data == "PSP"; d$Planted[isp] <- as.integer(as.character(d$Install[isp]) %in% psp_planted)
  m <- if (resp == "dDBH") dDBH.v3 else dHT.v3
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  pa_fun <- local({ d <- d; size <- size; resp <- resp; function(b) do.call(gr.hat3, c(list(d1 = d[[size]], bal1 = d$BAL.0, bal2 = d$BAL.1, cr1 = d$CR.0, cr2 = d$CR.1,
                                               bapa1 = d$BAPH.0, bapa2 = d$BAPH.1, Planted = d$Planted, rain = d$BYI, n = d$YIP), as.list(b))) / d$YIP * CFX[[resp]] })
  b_hat <- fixef(m); V <- vcov(m)
  gate <- max(abs(pa_fun(b_hat) - fitted(m, level = 0) / d$YIP * CFX[[resp]]))
  cat(resp, "reproduction gate max abs diff", gate, "\n"); if (!(gate < 1e-8)) stop("reproduction gate failed for ", resp)
  FR[[resp]] <- list(d = d, obs = d[[resp]] / d$YIP, org = ifelse(d$Planted == 1, "planted", "natural"), src = d$Data,
                     pa_fun = pa_fun, b_hat = b_hat, V = V)
  cat(resp, "fixef:", paste(names(b_hat), signif(b_hat, 7), collapse = " "), "\n")
}
srcs <- sort(unique(c(FR$dDBH$src, FR$dHT$src)))
kfun <- function(F, pa, s) {
  idx <- unlist(split(seq_along(F$src), F$src)[s], use.names = FALSE)
  kk <- tapply(F$obs[idx], F$org[idx], sum) / tapply(pa[idx], F$org[idx], sum); kk[c("natural", "planted")]
}
## base check: full frame, fitted vectors
k0 <- c(kfun(FR$dDBH, FR$dDBH$pa_fun(FR$dDBH$b_hat), srcs), kfun(FR$dHT, FR$dHT$pa_fun(FR$dHT$b_hat), srcs))
cat("base k (dd nat, dd plt, dh nat, dh plt):", k0, "\n")
## height
hc <- read.csv(file.path(RT, "02_height_coefficients.csv"), stringsAsFactors = FALSE)
hv <- as.matrix(read.csv(file.path(RT, "02_height_vcov.csv"))); rownames(hv) <- colnames(hv)
hmu <- setNames(hc$estimate, hc$parameter)[colnames(hv)]
## stage 1
pi <- read.csv("out_span/plot_intervals_origin.csv", stringsAsFactors = FALSE)
pi$any_mort <- as.logical(pi$any_mort); pi$removal <- as.logical(pi$removal)
pi <- pi[!pi$removal, ]; stopifnot(nrow(pi) == 290)
fit1 <- function(d) { s1 <- glm(any_mort ~ log(pmax(sdi, 1)) + planted, family = binomial(link = "cloglog"), offset = log(yip), data = d)
  c(coef(s1), pbar = mean(1 - exp(-exp(predict(s1, newdata = transform(d, yip = 1), type = "link"))))) }
js <- fromJSON("out_span/stage1_fit_origin.json"); s1_0 <- fit1(pi)
cat("stage 1 reproduction:", s1_0, "json pbar", js$stage1_mean_annual_p, "\n")
stopifnot(max(abs(s1_0[1:3] - unlist(js$stage1_beta))) < 1e-6, abs(s1_0[4] - js$stage1_mean_annual_p) < 1e-6)
keys <- paste(pi$Data, pi$Install, pi$Plot); pidx <- split(seq_len(nrow(pi)), keys); ukeys <- names(pidx)
## mortality level
mb <- read.csv("out_span/H_mort_boot_natural.csv", stringsAsFactors = FALSE)
kmort_pool <- mb$level[mb$form == "mult" & mb$cluster == "plot" & is.finite(mb$level)]
cat("kmort pool", length(kmort_pool), "median", median(kmort_pool), "\n")
## natural calibration intervals for the mortality factor rescaling (weights = initial stems ha-1)
NI <- read.csv("out_span/H_mort_intervals_natural_mult.csv", stringsAsFactors = FALSE)
stopifnot(nrow(NI) == 23)
pgate <- function(b, pb) (1 - exp(-exp(b[[1]] + b[[2]] * log(pmax(NI$sdi0, 1))))) / pb
g0 <- weighted.mean(pgate(s1_0, s1_0[["pbar"]]), NI$tph0)
mscale <- function(f) g0 / weighted.mean(pgate(f, f[["pbar"]]), NI$tph0)
cat("mortality rescale base check", mscale(s1_0), "\n"); stopifnot(abs(mscale(s1_0) - 1) < 1e-12)
rows <- vector("list", N); rej <- 0L; s1fail <- 0L
for (i in seq_len(N)) {
  repeat {
    s <- sample(srcs, length(srcs), replace = TRUE)
    ok <- all(sapply(FR, function(F) all(c("natural", "planted") %in% F$org[F$src %in% s])))
    if (ok) break; rej <- rej + 1L
  }
  bd <- mvrnorm(1, FR$dDBH$b_hat, FR$dDBH$V); bh <- mvrnorm(1, FR$dHT$b_hat, FR$dHT$V)
  kd <- kfun(FR$dDBH, FR$dDBH$pa_fun(bd), s); kh <- kfun(FR$dHT, FR$dHT$pa_fun(bh), s)
  hp <- mvrnorm(1, hmu, hv); hp["b"] <- max(hp["b"], 1e-4)
  repeat {
    ss <- sample(ukeys, length(ukeys), replace = TRUE)
    dd <- pi[unlist(pidx[ss], use.names = FALSE), ]
    okd <- all(sapply(0:1, function(o) all(c(TRUE, FALSE) %in% dd$any_mort[dd$planted == o])))
    f <- if (okd) tryCatch(suppressWarnings(fit1(dd)), error = function(e) NULL) else NULL
    if (!is.null(f) && all(is.finite(f)) && all(abs(f[1:3]) < 8)) break; s1fail <- s1fail + 1L
  }
  rows[[i]] <- data.frame(draw = i - 1L, sources = paste(sort(s), collapse = "|"),
    ht_a0 = hp["a0"], ht_a1 = hp["a1"], ht_b = hp["b"], ht_c = hp["c"], ht_g1 = hp["g1"], ht_g2 = hp["g2"],
    t(setNames(bd, paste0("d_", names(bd)))), t(setNames(bh, paste0("h_", names(bh)))),
    cal_dd_nat = kd[["natural"]], cal_dd_plt = kd[["planted"]], cal_dh_nat = kh[["natural"]], cal_dh_plt = kh[["planted"]],
    s1_int = f[[1]], s1_lnsdi = f[[2]], s1_pl = f[[3]], pbar = f[["pbar"]],
    kmort_boot = (kb <- sample(kmort_pool, 1)), kmort_scale = (ksc <- mscale(f)), kmort = kb * ksc, row.names = NULL, check.names = FALSE)
  if (i %% 100 == 0) cat("draw", i, format(Sys.time()), "\n")
}
K <- do.call(rbind, rows)
cat("source resamples rejected (an origin absent):", rej, " stage 1 refits redrawn:", s1fail, "\n")
writeLines(c(paste("rejected_source", rej), paste("redrawn_stage1", s1fail)), "out_span/K_joint_counts.txt")
write.csv(K, "out_span/K_joint_draws.csv", row.names = FALSE)
num <- K[, sapply(K, is.numeric) & names(K) != "draw"]
base <- c(hmu, setNames(FR$dDBH$b_hat, paste0("d_", names(FR$dDBH$b_hat))), setNames(FR$dHT$b_hat, paste0("h_", names(FR$dHT$b_hat))),
          k0, s1_0, 2.59367, 1, 2.59367)
names(base) <- names(num)
S <- data.frame(term = names(num), base = as.numeric(base), mean = colMeans(num), median = apply(num, 2, median),
                sd = apply(num, 2, sd), sd_log = apply(num, 2, function(x) if (all(is.finite(x) & x > 0)) sd(log(x)) else NA_real_),
                lo95 = apply(num, 2, quantile, 0.025), hi95 = apply(num, 2, quantile, 0.975), row.names = NULL)
write.csv(S, "out_span/K_joint_summary.csv", row.names = FALSE)
cal <- c("cal_dd_nat", "cal_dd_plt", "cal_dh_nat", "cal_dh_plt", "s1_lnsdi", "pbar", "kmort", "d_b0", "d_b9", "h_b0", "h_b9", "ht_a0")
write.csv(round(cor(num[, cal]), 6), "out_span/K_joint_cor.csv")
tab <- as.data.frame(table(K$sources)); names(tab) <- c("sources", "n"); write.csv(tab, "out_span/K_joint_source_sets.csv", row.names = FALSE)
print(S[S$term %in% cal, ]); print(round(cor(num[, cal[1:4]]), 3))
cat("JOINT DONE\n")
