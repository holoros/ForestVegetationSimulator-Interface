## joint_draws_v103_inst.R (2026-09-30, closeout, red team must-change 5). Copy of a2/joint_draws_v103.R with ONE design change: the
## multiplier resample keeps every data source and resamples its installations (Data|Install) with replacement within source, as the
## constants bootstrap track2/inc/boot_v103.R does; one installation draw per row is applied to both the dDBH and dHT frames. Everything
## else (vector draws, pairing of vector j with the re-solve, height, Stage 1, kmort, seed, N) is unchanged. Output a2/closeout/jointmc/out.
## Original header: joint_draws_v102.R adapted to the v103 deployment. Same design: source resampling with both
## origins required; increment vectors from their fixed effect MVN (dDBH: the v102 vector of record and its v102 vcov, since the vector is
## deployed unchanged; dHT: dHT_L_NO and its v103 vcov); origin multipliers re-solved on the resampled v103 NO frame under the live list
## percentile BAL with the RECURSION CONSISTENT solve_c the engine constants were solved with (v102 used ratio of means, which no longer
## matches how CAL was set); height from the v103 vcov; Stage 1 plot cluster bootstrap on the v103 intervals with the acceptance rule;
## natural mortality level from the v103 plot bootstrap rescaled under the drawn Stage 1. Seed 20260930, N 500. cal = c / CF, CF the engine's.
## Draws are generated sequentially (RNG), the root solves run in parallel with three spare vector draws per row for a failed solve.
suppressPackageStartupMessages({ library(nlme); library(MASS); library(jsonlite); library(parallel) })
W <- path.expand("~/jobs/koa_v103_20260930"); setwd(W)
N <- as.integer(Sys.getenv("KOA_NJOINT", "500")); NC <- 4
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
src <- readLines("track2/inc/inc_v103.R"); eval(parse(text = src[grep("^HCB_P <- c\\(", src)[1]:grep("^taus <- function", src)[1]]))
KPL <- readLines("engine_v103/koa_params.py"); getpair <- function(nm) as.numeric(strsplit(sub("^[^(]*\\(([^)]*)\\).*", "\\1", grep(paste0("^", nm, " = "), KPL, value = TRUE)), ",")[[1]])
getnum <- function(nm) as.numeric(sub(paste0("^", nm, " = ([0-9.eE+-]+).*"), "\\1", grep(paste0("^", nm, " = "), KPL, value = TRUE)))
CFX <- c(dDBH = getnum("CF_DDBH_MARGINAL"), dHT = getnum("CF_DHT")); GD <- c(dDBH = 45, dHT = 20); logm("CFX", CFX)
e1 <- new.env(); load(path.expand("~/jobs/koa_v102_20260918/track2/inc/inc_fits.rda"), e1); mD <- e1$FITS[["dDBH V102 deployed_solution"]]
e2 <- new.env(); load("out/inc/fits_v103.rda", e2); mH <- e2$FITS[["dHT_L_NO"]]
B0 <- list(dDBH = fixef(mD), dHT = fixef(mH)); VV <- list(dDBH = vcov(mD), dHT = vcov(mH))
J <- fromJSON("out/v103_constants.json")
g1 <- max(abs(B0$dDBH - unlist(J$DDBH$coef)[names(B0$dDBH)])); g2 <- max(abs(B0$dHT - unlist(J$DHT$coef)[names(B0$dHT)]))
logm("GATE vectors vs v103_constants.json: dDBH", signif(g1, 3), "dHT", signif(g2, 3)); stopifnot(g1 < 1e-9, g2 < 1e-9)
FR <- lapply(c(dDBH = "dDBH", dHT = "dHT"), function(resp) { d <- read.csv(sprintf("frames/final/%s_NO_v103_model.csv", resp), stringsAsFactors = FALSE)
  d$icls <- factor(d$icls, levels = c("1-2", "3-5", "6-10", "11-20", "21+")); model_cols(d, "l") })
srcs <- sort(unique(c(FR$dDBH$Data, FR$dHT$Data))); logm("sources", paste(srcs, collapse = " "))
FR <- lapply(FR, function(d) { d$inst <- paste(d$Data, d$Install, sep = "|"); d }); SPI <- lapply(FR, function(d) split(seq_len(nrow(d)), d$inst))
IU <- unique(do.call(rbind, lapply(FR, function(d) unique(d[, c("inst", "Data")])))); IU <- IU[order(IU$Data, IU$inst), ]
ids_by_src <- split(IU$inst, IU$Data); logm("installations by source (union of frames):", paste(names(ids_by_src), lengths(ids_by_src), collapse = " "))
rows_of <- function(resp, s) { sp <- SPI[[resp]]; unlist(sp[s[s %in% names(sp)]], use.names = FALSE) }
csolve <- function(resp, b, s) { GUARD <<- GD[[resp]]; d <- FR[[resp]]; dd <- d[rows_of(resp, s), ]
  cc <- tryCatch(solve_c(resp, dd, b), error = function(e) c(natural = NA_real_, planted = NA_real_)); cc / CFX[[resp]] }
k0 <- c(csolve("dDBH", B0$dDBH, IU$inst), csolve("dHT", B0$dHT, IU$inst)); eng <- c(getpair("CAL_DDBH"), getpair("CAL_DHT"))
logm("base cal (dd nat, dd plt, dh nat, dh plt):", paste(signif(k0, 7), collapse = " "), "| engine", paste(eng, collapse = " "))
stopifnot(max(abs(k0 - eng)) < 1e-5); logm("engine CAL gate PASS", signif(max(abs(k0 - eng)), 3))
hc <- read.csv("track2/out/height_coefficients.csv", stringsAsFactors = FALSE); hc <- hc[hc$frame == "v103", ]
hv <- as.matrix(read.csv("track2/height/height_vcov_v103.csv")); rownames(hv) <- colnames(hv); hmu <- setNames(hc$estimate, hc$parameter)[colnames(hv)]
stopifnot(max(abs(hmu - unlist(J$HT_P)[names(hmu)])) < 1e-9)
s1src <- readLines("track2/stage1/stage1_garcia_v103.R"); owd <- getwd(); eval(parse(text = s1src[1:grep("^d103 <- p103", s1src)])); setwd(owd)
pi <- d103; stopifnot(nrow(pi) == 282)
fit1 <- function(d) { s1 <- glm(any_mort ~ log(pmax(sdi, 1)) + planted, family = binomial(link = "cloglog"), offset = log(yip), data = d)
  c(coef(s1), pbar = mean(1 - exp(-exp(predict(s1, newdata = transform(d, yip = 1), type = "link"))))) }
js <- fromJSON("engine_v103/out_stage1/stage1_fit.json"); s1_0 <- fit1(pi)
stopifnot(max(abs(s1_0[1:3] - unlist(js$stage1_beta))) < 1e-6, abs(s1_0[4] - js$stage1_mean_annual_p) < 1e-6); logm("stage 1 reproduction PASS")
keys <- paste(pi$Data, pi$Install, pi$Plot); pidx <- split(seq_len(nrow(pi)), keys); ukeys <- names(pidx)
mb <- read.csv("a2/mort/v103/H_mort_boot_natural.csv", stringsAsFactors = FALSE); kmort_pool <- mb$level[mb$form == "mult" & mb$cluster == "plot" & is.finite(mb$level)]
NI <- read.csv("a2/mort/v103/H_mort_intervals_natural_mult.csv", stringsAsFactors = FALSE); stopifnot(nrow(NI) == 24)
pgate <- function(b, pb) (1 - exp(-exp(b[[1]] + b[[2]] * log(pmax(NI$sdi0, 1))))) / pb
g0 <- weighted.mean(pgate(s1_0, s1_0[["pbar"]]), NI$tph0); mscale <- function(f) g0 / weighted.mean(pgate(f, f[["pbar"]]), NI$tph0)
KMORT <- getpair("MORT_CAL")[1]; logm("kmort pool", length(kmort_pool), "median", median(kmort_pool), "MORT_CAL", KMORT)
set.seed(20260930); DR <- vector("list", N); rej <- 0L; s1fail <- 0L
for (i in seq_len(N)) {
  repeat { s <- unlist(lapply(ids_by_src, function(v) sample(v, length(v), replace = TRUE)), use.names = FALSE)
    if (all(sapply(names(FR), function(r) all(c(0, 1) %in% FR[[r]]$Planted[rows_of(r, s)])))) break; rej <- rej + 1L }
  bd <- mvrnorm(4, B0$dDBH, VV$dDBH); bh <- mvrnorm(4, B0$dHT, VV$dHT)
  hp <- mvrnorm(1, hmu, hv); hp["b"] <- max(hp["b"], 1e-4)
  repeat { ss <- sample(ukeys, length(ukeys), replace = TRUE); dd <- pi[unlist(pidx[ss], use.names = FALSE), ]
    okd <- all(sapply(0:1, function(o) all(c(TRUE, FALSE) %in% dd$any_mort[dd$planted == o])))
    f <- if (okd) tryCatch(suppressWarnings(fit1(dd)), error = function(e) NULL) else NULL
    if (!is.null(f) && all(is.finite(f)) && all(abs(f[1:3]) < 8)) break; s1fail <- s1fail + 1L }
  kb <- sample(kmort_pool, 1); DR[[i]] <- list(s = s, bd = bd, bh = bh, hp = hp, f = f, kb = kb)
}
logm("draws generated; solving multipliers on", NC, "cores")
one <- function(i) { x <- DR[[i]]; out <- list()
  for (resp in c("dDBH", "dHT")) { M <- if (resp == "dDBH") x$bd else x$bh
    for (j in 1:4) { b <- setNames(M[j, ], colnames(M)); k <- csolve(resp, b, x$s); if (all(is.finite(k)) && all(k > 0)) break }
    out[[resp]] <- list(b = b, k = k, j = j) }
  out }
MCOUT <- file.path(W, "a2/closeout/jointmc/out")
RS <- mclapply(seq_len(N), one, mc.cores = NC); saveRDS(list(DR = DR, RS = RS), file.path(MCOUT, "joint_raw_v103.rds"))
spare <- sum(sapply(RS, function(r) (r$dDBH$j > 1) + (r$dHT$j > 1))); fail <- sum(sapply(RS, function(r) !all(is.finite(c(r$dDBH$k, r$dHT$k)))))
logm("spare vector draws used", spare, "| rows still without a solve", fail); stopifnot(fail == 0)
rows <- lapply(seq_len(N), function(i) { x <- DR[[i]]; r <- RS[[i]]; f <- x$f; ksc <- mscale(f)
  data.frame(draw = i - 1L, sources = paste(sort(unique(sub("\\|.*", "", x$s))), collapse = "|"), n_inst_distinct = length(unique(x$s)),
    ht_a0 = x$hp["a0"], ht_a1 = x$hp["a1"], ht_b = x$hp["b"], ht_c = x$hp["c"], ht_g1 = x$hp["g1"], ht_g2 = x$hp["g2"],
    t(setNames(r$dDBH$b, paste0("d_", names(r$dDBH$b)))), t(setNames(r$dHT$b, paste0("h_", names(r$dHT$b)))),
    cal_dd_nat = r$dDBH$k[["natural"]], cal_dd_plt = r$dDBH$k[["planted"]], cal_dh_nat = r$dHT$k[["natural"]], cal_dh_plt = r$dHT$k[["planted"]],
    s1_int = f[[1]], s1_lnsdi = f[[2]], s1_pl = f[[3]], pbar = f[["pbar"]], kmort_boot = x$kb, kmort_scale = ksc, kmort = x$kb * ksc, row.names = NULL, check.names = FALSE) })
K <- do.call(rbind, rows)
writeLines(c(paste("rejected_source", rej), paste("redrawn_stage1", s1fail), paste("spare_vector_draws", spare)), file.path(MCOUT, "K_joint_counts.txt"))
write.csv(K, file.path(MCOUT, "K_joint_draws.csv"), row.names = FALSE)
num <- K[, sapply(K, is.numeric) & !(names(K) %in% c("draw", "n_inst_distinct"))]
base <- c(hmu, setNames(B0$dDBH, paste0("d_", names(B0$dDBH))), setNames(B0$dHT, paste0("h_", names(B0$dHT))), k0, s1_0, KMORT, 1, KMORT); names(base) <- names(num)
S <- data.frame(term = names(num), base = as.numeric(base), mean = colMeans(num), median = apply(num, 2, median), sd = apply(num, 2, sd),
  sd_log = apply(num, 2, function(x) if (all(is.finite(x) & x > 0)) sd(log(x)) else NA_real_), lo95 = apply(num, 2, quantile, 0.025), hi95 = apply(num, 2, quantile, 0.975), row.names = NULL)
write.csv(S, file.path(MCOUT, "K_joint_summary.csv"), row.names = FALSE)
cal <- c("cal_dd_nat", "cal_dd_plt", "cal_dh_nat", "cal_dh_plt", "s1_lnsdi", "pbar", "kmort", "d_b0", "d_b9", "h_b0", "h_b9", "ht_a0")
write.csv(round(cor(num[, cal]), 6), file.path(MCOUT, "K_joint_cor.csv"))
tab <- as.data.frame(table(K$sources)); names(tab) <- c("sources", "n"); write.csv(tab, file.path(MCOUT, "K_joint_source_sets.csv"), row.names = FALSE)
print(S[S$term %in% cal, ]); logm("rejected", rej, "stage1 redrawn", s1fail); logm("JOINT DRAWS DONE")
