## 04r_mono.R: monotonicity grid per PREREG_K3c rev2 (criterion i). One annual step, ln g of the actual gr.hat3c expression; fd h 1e-6 + analytic.
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/rev2/lib_r2.R"))
d <- frameK("dDBH", "K3p"); d0 <- frameK("dDBH", "K0"); P <- function(v, k) seq(quantile(v, .01), quantile(v, .99), length.out = k)
S <- P(d$DBH.0, 20); CR <- P(d$CRx.0, 5); BY <- P(d$BYI, 5); RDp <- quantile(d$BAPH.0, c(.01, .99))
Xg <- seq(quantile(d$BALx.0, .01), max(quantile(d$BALx.0, .99), 1.5), length.out = 31); RDa <- c(seq(RDp[1], RDp[2], length.out = 5), 1.5)
RDg <- seq(RDp[1], max(RDp[2], 1.5), length.out = 31); SH <- seq(0, 1, 0.1)
logm("grid: DBH", round(range(S), 3), "CR", round(range(CR), 3), "BYI", round(range(BY), 2), "X", round(range(Xg), 3), "RD", round(range(RDg), 4))
lng <- function(b, s, x, rd, cr, by, pl) log(pa_pred("dDBH", data.frame(DBH.0 = s, BALx.0 = x, BALx.1 = x, CRx.0 = cr, CRx.1 = cr, BAPH.0 = rd, BAPH.1 = rd, Planted = pl, BYI = by, YIP = 1), b))
h <- 1e-6; get_b <- function(cand) switch(cand, K0 = readRDS(file.path(OB, "fit_K0.rds"))$dDBH$b, K3p = readRDS(file.path(OB, "fit_K3p.rds"))$dDBH$b,
  K3c1 = readRDS(file.path(OC, "fit_K3c1.rds"))$b, K3c3 = readRDS(file.path(OR, "fit_K3c3.rds"))$b)
an_x <- function(cand, b, s, x, rd) { b3 <- if (cand %in% c("K0", "K3p")) b[["b3"]] else 0; 2 * b3 * x / log(s + 5) + b[["b4"]] / (x + 1) }
an_rd <- function(cand, b, s, x, rd, sh) { b3 <- if (cand %in% c("K0", "K3p")) b[["b3"]] else 0
  sh * (2 * b3 * x / log(s + 5) + b[["b4"]] / (x + 1)) + if (cand == "K3c3") b[["b6"]] / rd else b[["b6"]] * sqrt(s) / (2 * sqrt(rd)) }
ALL <- list(); SUM <- list()
for (cand in c("K0", "K3p", "K3c1", "K3c3")) { if (cand == "K3c3" && !file.exists(file.path(OR, "fit_K3c3.rds"))) next
  SET(cand); b <- get_b(cand)
  if (cand == "K0") { Xk <- seq(quantile(d0$BALx.0, .01), quantile(d0$BALx.0, .99), length.out = 31); RDak <- P(d0$BAPH.0, 5); RDk <- P(d0$BAPH.0, 31) } else { Xk <- Xg; RDak <- RDa; RDk <- RDg }
  A <- expand.grid(s = S, cr = CR, by = BY, pl = 0:1, x = Xk, rd = RDak); A$fd <- (lng(b, A$s, A$x + h, A$rd, A$cr, A$by, A$pl) - lng(b, A$s, pmax(A$x - h, 0), A$rd, A$cr, A$by, A$pl)) / (A$x + h - pmax(A$x - h, 0))
  A$an <- an_x(cand, b, A$s, A$x, A$rd); A$wrt <- "X"
  B <- expand.grid(s = S, cr = CR, by = BY, pl = 0:1, sh = SH, rd = RDk)
  if (cand == "K0") { B$x <- B$sh * quantile(d0$BALx.0, .99); B$fd <- (lng(b, B$s, B$x, B$rd + h, B$cr, B$by, B$pl) - lng(b, B$s, B$x, B$rd - h, B$cr, B$by, B$pl)) / (2 * h)
    B$an <- b[["b6"]] * sqrt(B$s) / (2 * sqrt(B$rd)) } else { B$x <- B$sh * B$rd
    B$fd <- (lng(b, B$s, B$sh * (B$rd + h), B$rd + h, B$cr, B$by, B$pl) - lng(b, B$s, B$sh * (B$rd - h), B$rd - h, B$cr, B$by, B$pl)) / (2 * h)
    B$an <- an_rd(cand, b, B$s, B$x, B$rd, B$sh) }
  B$wrt <- "RD"; A$sh <- NA; G <- rbind(A[, c("s", "cr", "by", "pl", "x", "rd", "sh", "wrt", "fd", "an")], B[, c("s", "cr", "by", "pl", "x", "rd", "sh", "wrt", "fd", "an")]); G$cand <- cand
  xmax <- 3.245; ex <- an_x(cand, b, S, xmax, 1)
  for (w in c("X", "RD")) { g <- G[G$wrt == w, ]; pos <- g$an > 1e-10 | g$fd > 1e-10
    SUM[[paste(cand, w)]] <- data.frame(cand = cand, wrt = w, n = nrow(g), n_pos = sum(pos), max_fd = max(g$fd), max_an = max(g$an), max_absdiff_fd_an = max(abs(g$fd - g$an)),
      first_pos_x = if (any(pos)) min(g$x[pos]) else NA, pass = !any(pos), dx_at_obsmax_X_max = if (w == "X") max(ex) else NA) }
  ALL[[cand]] <- G; logm(cand, "done") }
SM <- do.call(rbind, SUM); print(SM); fwrite(SM, file.path(OR, "monotonicity_summary_rev2.csv")); fwrite(do.call(rbind, ALL), file.path(OR, "monotonicity_grid_rev2.csv.gz"))
## per-DBH max d ln g/dX for K3p (where it turns)
g <- ALL$K3p; g <- g[g$wrt == "X", ]; print(aggregate(cbind(max_an = an) ~ s, g, max)[c(1, 5, 10, 15, 20), ])
logm("04r DONE")
