## lib.R: inc_v103.R lines 1-112 of the v105b job (read only) + RD candidate frames. Candidates only substitute the BAL and BAPH input columns of gr.hat3.
suppressPackageStartupMessages({ library(nlme); library(data.table) })
src <- readLines(path.expand("~/jobs/koa_v105_20261102/track2/inc/inc_v103.R"))
commandArgs0 <- commandArgs; commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); commandArgs <- commandArgs0
JB <- path.expand("~/jobs/koa_rdcomp_20261102"); OB <- file.path(JB, "out")
POP <- 923
CANDS <- c("K0", "K1", "K2", "K3", "K1p", "K2p", "K3p")
SIGN <- list(dDBH = function(b) c(b1_pos = b[["b1"]] > 0, b4_neg = b[["b4"]] < 0, b5_pos = b[["b5"]] > 0, b6_neg = b[["b6"]] < 0),
             dHT = function(b) c(b1_pos = b[["b1"]] > 0, b4_neg = b[["b4"]] < 0))
DEP <- list(dDBH = c(b0 = -0.541410636939183, b1 = 0.3621753596463, b2 = -0.022054909414052, b3 = -0.00144466272815832, b4 = -0.339160009349766,
                     b5 = 0.839662419625068, b6 = -0.0172213642831846, b7 = -0.0178162013671103, b8 = 0.277933503297401, b9 = 0.245526870125033),
            dHT = c(b0 = -2.24886113151764, b1 = 1.16165051507421, b2 = -0.15180509481679, b3 = -0.00015477155580024, b4 = -0.181775875965963,
                    b5 = 0.211620077153593, b6 = 0.0642562650484806, b7 = -0.119569696604906, b8 = 0.075487779351045, b9 = 0.693040214723941))
base_frame <- function(resp) {
  d <- readRDS(file.path(OB, sprintf("frame_mem_%s_NO.rds", resp))); nocoord(d)   # in-memory rebuild (00b_frames_mem.R; PREREG Amendment 1)
  d$icls <- factor(as.character(d$icls), levels = c("1-2", "3-5", "6-10", "11-20", "21+")); d$rowid <- seq_len(nrow(d))
  S <- fread(file.path(OB, "stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))
  G <- fread(path.expand("~/jobs/koa_brms_sdimax_20261102/out/growth_plot_sdimax_lqmm.csv"), colClasses = list(character = c("Install", "Plot")))
  key <- paste(d$Data, d$Install, d$Plot); sk <- paste(S$Data, S$Install, S$Plot, S$Measure)
  d$SDI.0 <- S$SDI_qmd[match(paste(key, d$t.0), sk)]; d$SDI.1 <- S$SDI_qmd[match(paste(key, d$t.1), sk)]
  sm <- G$SDImax[match(key, paste(G$Data, G$Install, G$Plot))]; d$SDImax_plot <- ifelse(is.finite(sm), sm, POP); d$sdimax_src <- ifelse(is.finite(sm), "plot", "population")
  d <- model_cols(d, "l"); d <- d[is.finite(d$SDI.0) & is.finite(d$SDI.1), ]
  d$BALo.0 <- d$BALx.0; d$BALo.1 <- d$BALx.1; d$BAPHo.0 <- d$BAPH.0; d$BAPHo.1 <- d$BAPH.1; d }
frameK <- function(resp, cand) {
  d <- base_frame(resp); if (cand == "K0") return(d)
  sdimax <- if (grepl("p$", cand)) POP else d$SDImax_plot
  rd0 <- d$SDI.0 / sdimax; rd1 <- d$SDI.1 / sdimax; k <- sub("p$", "", cand)
  sh0 <- ifelse(d$BAPHo.0 > 0, d$BALo.0 / d$BAPHo.0, 0); sh1 <- ifelse(d$BAPHo.1 > 0, d$BALo.1 / d$BAPHo.1, 0)
  if (k == "K1") { d$BAPH.0 <- rd0; d$BAPH.1 <- rd1 }
  if (k == "K2") { d$BALx.0 <- d$BALo.0 * rd0; d$BALx.1 <- d$BALo.1 * rd1; d$BAPH.0 <- d$BAPHo.0 * rd0; d$BAPH.1 <- d$BAPHo.1 * rd1 }
  if (k == "K3") { d$BALx.0 <- sh0 * rd0; d$BALx.1 <- sh1 * rd1; d$BAPH.0 <- rd0; d$BAPH.1 <- rd1 }
  d }
## start (a): rescale b3, b4, b6 so each term's SD at t.0 matches K0's
rescale_start <- function(resp, b, d0, dk) {
  S0 <- if (resp == "dDBH") d0$DBH.0 else d0$HT.0
  t3 <- function(d) sd(d$BALx.0^2 / log(S0 + 5)); t4 <- function(d) sd(log(d$BALx.0 + 1)); t6 <- function(d) sd(sqrt(d$BAPH.0 * S0))
  s <- b; s["b3"] <- b[["b3"]] * t3(d0) / t3(dk); s["b4"] <- b[["b4"]] * t4(d0) / t4(dk); s["b6"] <- b[["b6"]] * t6(d0) / t6(dk); s }
solve_cK <- function(resp, d, b) sapply(c(natural = 0, planted = 1), function(pl) { dd <- d[d$Planted == pl, ]; if (nrow(dd) == 0) return(NA_real_)
  f <- function(lc) { bb <- b; bb["b0"] <- b["b0"] + lc; v <- sum(pa_pred(resp, dd, bb)) - sum(dd[[resp]]); if (!is.finite(v)) 1e12 else v }
  exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) })
fitS <- function(resp, d, start) tryCatch(fit_one(resp, d, "NO", start = start[paste0("b", 0:9)]), error = function(e) NULL)
strata <- function(resp, d, b, cc, cand) {
  per <- pa_pred(resp, d, b) * cc[ifelse(d$Planted == 1, "planted", "natural")]; ao <- d[[resp]] / d$YIP; ap <- per / d$YIP
  q <- cut(d$BALo.0, quantile(d$BALo.0, 0:5 / 5), include.lowest = TRUE, labels = paste0("Q", 1:5))
  sz <- if (resp == "dDBH") cut(d$DBH.0, c(0, 5, 10, 20, 30, 40, 60, 300), labels = c("0-5", "5-10", "10-20", "20-30", "30-40", "40-60", "60+")) else
    cut(d$HT.0, c(0, 5, 10, 15, 20, 30, 100), labels = c("0-5", "5-10", "10-15", "15-20", "20-30", "30+"))
  one <- function(i, s, l) data.frame(cand = cand, resp = resp, strat = s, level = l, n = length(i), ratio = sum(ao[i]) / sum(ap[i]), rmse_ann = rmse(ao[i], ap[i]))
  rbind(one(seq_along(ao), "all", "all"), do.call(rbind, lapply(levels(sz), function(l) { i <- which(sz == l); if (length(i) > 4) one(i, "size", l) })),
        do.call(rbind, lapply(levels(q), function(l) one(which(q == l), "BALquintile", l)))) }
