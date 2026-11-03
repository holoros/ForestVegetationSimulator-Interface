## 01_stage12.R: Stage 1 (occurrence) and Stage 2 (conditional rate) deployed vs M1 / M2 (+ ln(C2/100)).
source(path.expand("~/jobs/koa_compscreen_20261102/lib.R"))
js <- fromJSON(file.path(W, "out/v105_constants.json"))$STAGE1
f1 <- list(D = any_mort ~ lnsdi + planted + offset(log(yip)), M1 = any_mort ~ lnsdi + planted + lc2 + offset(log(yip)))
f2 <- list(D = log(m_ann) ~ lnsdi + planted, M2 = log(m_ann) ~ lnsdi + planted + lc2)
g1fit <- function(f, d) suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = d, control = glm.control(maxit = 100)))
prepd <- function(p) { p$any_mort <- as.logical(p$any_mort); p$lnsdi <- log(pmax(p$sdi, 1)); p$C2 <- c2_of(p$Data, p$Install, p$Plot); p$lc2 <- log(p$C2 / 100)
  p$key <- paste(p$Data, p$Install, p$Plot); p$inst <- paste(p$Data, p$Install); p }
## sample A: the specified frame
pA <- read.csv(file.path(W, "a2/mort/v104/plot_intervals_origin.csv"), stringsAsFactors = FALSE, colClasses = c(Install = "character", Plot = "character")); nocoord(pA)
pA <- prepd(pA[!as.logical(pA$removal), ])
gate <- function(d) { a <- coef(g1fit(f1$D, d)); dm <- d[d$any_mort & d$m_ann > 0, ]; b <- coef(lm(f2$D, dm))
  c(s1 = max(abs(a - unlist(js$stage1_beta))), s2 = max(abs(b - unlist(js$stage2_beta))), n = nrow(d)) }
gA <- gate(pA); logm("GATE sample A (v104 plot_intervals_origin, removal excluded): n", gA["n"], "max abs diff S1", signif(gA["s1"], 3), "S2", signif(gA["s2"], 3))
## sample B: stage1_garcia_v103.R lines 1-31 (no writes in those lines), evaluated with setwd suppressed
src <- readLines(file.path(W, "track2/stage1/stage1_garcia_v103.R"))[1:31]; src <- sub('setwd\\([^)]*\\); ', "", src)
envB <- new.env(); eval(parse(text = src), envir = envB); pB <- prepd(envB$d103)
gB <- gate(pB); logm("GATE sample B (stage1_garcia_v103 d103): n", gB["n"], "max abs diff S1", signif(gB["s1"], 3), "S2", signif(gB["s2"], 3))
use <- if (gA["s1"] < 1e-6 && gA["s2"] < 1e-6) "A" else if (gB["s1"] < 1e-6 && gB["s2"] < 1e-6) "B" else "A"
pi <- if (use == "A") pA else pB; stopifnot(all(is.finite(pi$C2)))
logm("screen sample", use, "rows", nrow(pi), "plots", length(unique(pi$key)), "installations", length(unique(pi$inst)), "with mortality", sum(pi$any_mort))
write.csv(data.frame(sample = c("A_v104_plot_intervals_origin", "B_stage1_garcia_v103"), n = c(gA["n"], gB["n"]), maxdiff_s1 = c(gA["s1"], gB["s1"]), maxdiff_s2 = c(gA["s2"], gB["s2"]),
  used = c(use == "A", use == "B")), file.path(OUT, "stage12_gate.csv"), row.names = FALSE)
dm <- pi[pi$any_mort & pi$m_ann > 0, ]
## point fits
F1 <- lapply(f1, g1fit, d = pi); F2 <- lapply(f2, function(f) lm(f, data = dm))
## LOIO
insts <- unique(pi$inst)
lo1 <- rbindlist(lapply(insts, function(k) { tr <- pi[pi$inst != k, ]; te <- pi[pi$inst == k, ]
  rbindlist(lapply(names(f1), function(m) { g <- g1fit(f1[[m]], tr); data.table(model = m, inst = k, y = as.integer(te$any_mort), p = predict(g, te, type = "response")) })) }))
lo2 <- rbindlist(lapply(unique(dm$inst), function(k) { tr <- dm[dm$inst != k, ]; te <- dm[dm$inst == k, ]
  rbindlist(lapply(names(f2), function(m) { g <- lm(f2[[m]], tr); data.table(model = m, inst = k, y = log(te$m_ann), p = predict(g, te)) })) }))
## plot-cluster bootstrap of the new coefficients
set.seed(SEED); keys <- unique(pi$key); idx <- split(seq_len(nrow(pi)), pi$key)
BS <- t(sapply(seq_len(NB), function(b) { s <- sample(keys, length(keys), TRUE); db <- pi[unlist(idx[s], use.names = FALSE), ]
  a <- tryCatch({ g <- g1fit(f1$M1, db); if (g$converged) coef(g)[["lc2"]] else NA }, error = function(e) NA)
  dmb <- db[db$any_mort & db$m_ann > 0, ]; c(M1 = a, M2 = tryCatch(coef(lm(f2$M2, dmb))[["lc2"]], error = function(e) NA)) }))
## monotonicity
gS <- seq(quantile(pi$sdi, .01), quantile(pi$sdi, .99), length.out = 50); qc <- quantile(pi$C2, c(.1, .5, .9))
mono1 <- all(sapply(qc, function(cv) sapply(0:1, function(pl) all(diff(predict(F1$M1, data.frame(lnsdi = log(gS), planted = pl, lc2 = log(cv / 100), yip = 1), type = "response")) >= -1e-12))))
p1dep <- function(sdi, pl) 1 - exp(-exp(coef(F1$D)[1] + coef(F1$D)[2] * log(sdi) + coef(F1$D)[3] * pl))
mono2 <- all(sapply(qc, function(cv) sapply(0:1, function(pl) all(diff(p1dep(gS, pl) * exp(predict(F2$M2, data.frame(lnsdi = log(gS), planted = pl, lc2 = log(cv / 100))))) >= -1e-12))))
mono2D <- all(sapply(0:1, function(pl) all(diff(p1dep(gS, pl) * exp(predict(F2$D, data.frame(lnsdi = log(gS), planted = pl)))) >= -1e-12)))
mono1D <- all(sapply(0:1, function(pl) all(diff(p1dep(gS, pl)) >= -1e-12)))
## table
res <- rbind(
  data.frame(component = "Stage 1", cand = c("D", "M1"), n = nrow(pi), logLik = sapply(F1, function(m) as.numeric(logLik(m))), AIC = sapply(F1, AIC),
    lnSDI = sapply(F1, function(m) coef(m)[["lnsdi"]]), planted = sapply(F1, function(m) coef(m)[["planted"]]), lc2 = c(NA, coef(F1$M1)[["lc2"]]),
    lc2_se = c(NA, summary(F1$M1)$coefficients["lc2", 2]),
    loio_auc = sapply(names(f1), function(m) with(lo1[model == m], auc(y, p))), loio_brier = sapply(names(f1), function(m) with(lo1[model == m], mean((y - p)^2))), loio_rmse = NA,
    boot_lo = c(NA, qboot(BS[, "M1"])["lo"]), boot_hi = c(NA, qboot(BS[, "M1"])["hi"]), boot_ok = c(NA, qboot(BS[, "M1"])["n_ok"]),
    signs = c(coef(F1$D)[["lnsdi"]] > 0, coef(F1$M1)[["lnsdi"]] > 0), mono = c(mono1D, mono1)),
  data.frame(component = "Stage 2", cand = c("D", "M2"), n = nrow(dm), logLik = sapply(F2, function(m) as.numeric(logLik(m))), AIC = sapply(F2, AIC),
    lnSDI = sapply(F2, function(m) coef(m)[["lnsdi"]]), planted = sapply(F2, function(m) coef(m)[["planted"]]), lc2 = c(NA, coef(F2$M2)[["lc2"]]),
    lc2_se = c(NA, summary(F2$M2)$coefficients["lc2", 2]), loio_auc = NA, loio_brier = NA,
    loio_rmse = sapply(names(f2), function(m) with(lo2[model == m], rmse(y, p))),
    boot_lo = c(NA, qboot(BS[, "M2"])["lo"]), boot_hi = c(NA, qboot(BS[, "M2"])["hi"]), boot_ok = c(NA, qboot(BS[, "M2"])["n_ok"]),
    signs = c(TRUE, TRUE), mono = c(mono2D, mono2)))
res$dAIC <- res$AIC - ave(ifelse(res$cand == "D", res$AIC, NA), res$component, FUN = function(v) v[!is.na(v)][1])
write.csv(res, file.path(OUT, "stage12_results.csv"), row.names = FALSE); write.csv(BS, file.path(OUT, "stage12_boot.csv"), row.names = FALSE)
print(res, digits = 4); logm("n insts LOIO S1", length(insts), "S2", length(unique(dm$inst))); logm("STAGE12 DONE")
