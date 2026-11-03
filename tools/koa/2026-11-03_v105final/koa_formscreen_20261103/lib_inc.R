## lib_inc.R: increment machinery. inc_v103.R lines 1-112 of koa_v105_20261102 (read only, as koa_rdcomp_20261102/lib.R) + a general recursion grF
## whose competition block is selected by FORM. Frames: koa_rdcomp_20261102/out/frame_mem_<resp>_NO.rds + stand_plotyear SDI_qmd (as rdcomp/K3c1).
suppressPackageStartupMessages({ library(nlme); library(data.table) })
src <- readLines(path.expand("~/jobs/koa_v105_20261102/track2/inc/inc_v103.R"))
commandArgs0 <- commandArgs; commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); commandArgs <- commandArgs0
JB <- path.expand("~/jobs/koa_formscreen_20261103"); OUT <- file.path(JB, "out"); RDC <- path.expand("~/jobs/koa_rdcomp_20261102/out")
POP <- as.numeric(Sys.getenv("KOA_POP", "741.7117")); SEED <- 20261103L
logm <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console() }
nocoord <- function(d) stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y", "lat_true", "lon_true")))
rmse <- function(o, p) sqrt(mean((o - p)^2))
base_frame <- function(resp) {
  d <- readRDS(file.path(RDC, sprintf("frame_mem_%s_NO.rds", resp))); nocoord(d)
  d$icls <- factor(as.character(d$icls), levels = c("1-2", "3-5", "6-10", "11-20", "21+")); d$rowid <- seq_len(nrow(d))
  S <- fread(file.path(RDC, "stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot"))); nocoord(S)
  key <- paste(d$Data, d$Install, d$Plot); sk <- paste(S$Data, S$Install, S$Plot, S$Measure)
  d$SDI.0 <- S$SDI_qmd[match(paste(key, d$t.0), sk)]; d$SDI.1 <- S$SDI_qmd[match(paste(key, d$t.1), sk)]
  d <- model_cols(d, "l"); d <- d[is.finite(d$SDI.0) & is.finite(d$SDI.1), ]
  d$BALo.0 <- d$BALx.0; d$BAPHo.0 <- d$BAPH.0
  d$RD.0 <- d$SDI.0 / POP; d$RD.1 <- d$SDI.1 / POP
  d$SH.0 <- ifelse(d$BAPH.0 > 0, d$BALx.0 / d$BAPH.0, 0); d$SH.1 <- ifelse(d$BAPH.1 > 0, d$BALx.1 / d$BAPH.1, 0)
  d$XK.0 <- d$SH.0 * d$RD.0; d$XK.1 <- d$SH.1 * d$RD.1; d }
FORM <- "K3c1"; GUARD <- 45
grF <- function(S0, x0, x1, cr0, cr1, rd0, rd1, Pl, BYI, n, b0, b1, b2, b5, b7, b8, b9, b4 = 0, b6 = 0, lc = 0, ld = 0, lg = 0, b10 = 0) {
  b0 <- b0 + b9 * Pl; maxn <- max(n); s <- S0; x <- x0; cr <- cr0; rd <- rd0
  xg <- (x1 - x0) / n; crg <- (cr1 - cr0) / n; rdg <- (rd1 - rd0) / n; lc2 <- log(BYI / 100)
  for (i in 1:maxn) {
    comp <- switch(FORM, K3c1 = b4 * log(x + 1) + b6 * sqrt(rd * s), MOD = -exp(lc) * x^exp(ld), MODRD = -exp(lc) * x^exp(ld) - exp(lg) * rd,
                   MODC2 = -exp(lc) * x^exp(ld) + b10 * s * lc2, CRRD = b4 * log(x + 1) + b6 * (1 - cr) * rd)
    gr <- exp(b0 + b1 * log(s + 1) + b2 * s + b5 * log(cr) + comp + b7 * Pl * pmin(s, GUARD) + b8 * log(BYI))
    s <- s + ifelse(i <= n, gr, 0.0); x <- x + xg; cr <- cr + crg; rd <- rd + rdg }
  s - S0 }
PARS_OF <- list(K3c1 = c("b0", "b1", "b2", "b4", "b5", "b6", "b7", "b8", "b9"), MOD = c("b0", "b1", "b2", "b5", "b7", "b8", "b9", "lc", "ld"),
                MODRD = c("b0", "b1", "b2", "b5", "b7", "b8", "b9", "lc", "ld", "lg"), MODC2 = c("b0", "b1", "b2", "b5", "b7", "b8", "b9", "lc", "ld", "b10"),
                CRRD = c("b0", "b1", "b2", "b4", "b5", "b6", "b7", "b8", "b9"))
CAND_FORM <- c(B = "K3c1", D1 = "MOD", D2 = "MODRD", D3 = "MODC2", T1 = "MOD", T2 = "MODRD", T3 = "CRRD", T4 = "MODC2")
pa_pred <- function(resp, d, b) { size <- if (resp == "dDBH") d$DBH.0 else d$HT.0; g <- function(k) if (k %in% names(b)) b[[k]] else 0
  grF(size, d$XK.0, d$XK.1, d$CRx.0, d$CRx.1, d$RD.0, d$RD.1, d$Planted, d$BYI, d$YIP, g("b0"), g("b1"), g("b2"), g("b5"), g("b7"), g("b8"), g("b9"),
      b4 = g("b4"), b6 = g("b6"), lc = g("lc"), ld = g("ld"), lg = g("lg"), b10 = g("b10")) }
fitF <- function(resp, d, start) { p <- PARS_OF[[FORM]]; size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ grF(S0 = %s, x0 = XK.0, x1 = XK.1, cr0 = CRx.0, cr1 = CRx.1, rd0 = RD.0, rd1 = RD.1, Pl = Planted, BYI = BYI, n = YIP, %s)",
                           resp, size, paste(p, "=", p, collapse = ", ")))
  tryCatch(nlme(f3, data = d, fixed = as.formula(paste(paste(p, collapse = " + "), "~ 1")), random = b0 ~ 1 | Data/Install/TreeID, start = start[p],
                weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) { logm("  fit error:", conditionMessage(e)); NULL }) }
solve_cF <- function(resp, d, b) sapply(c(natural = 0, planted = 1), function(pl) { dd <- d[d$Planted == pl, ]; if (nrow(dd) == 0) return(NA_real_)
  f <- function(lc) { bb <- b; bb["b0"] <- b["b0"] + lc; v <- sum(pa_pred(resp, dd, bb)) - sum(dd[[resp]]); if (!is.finite(v)) 1e12 else v }
  exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) })
## one-step ln g on a grid (n = 1, x and rd held), for the monotonicity check
lng1 <- function(resp, b, s, x, rd, cr, by, pl) log(pa_pred(resp, data.frame(DBH.0 = s, HT.0 = s, XK.0 = x, XK.1 = x, CRx.0 = cr, CRx.1 = cr, RD.0 = rd, RD.1 = rd,
                                                                         Planted = pl, BYI = by, YIP = 1), b))
