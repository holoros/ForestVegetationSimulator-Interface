## lib_c.R: ../lib.R unchanged + gr.hat3c (gr.hat2g of inc_v103.R with the b3 slot selected by mode M3: "sq" identical expression, "lin" b3 x/ln(S+5), "none" no b3).
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"))
CB <- path.expand("~/jobs/koa_rdcomp_20261102/constrained"); OC <- file.path(CB, "out"); GUARD <- 45; M3 <- "sq"
MODE <- c(K0c = "sq", K3pc = "sq", K3c1 = "none", K3c2 = "lin"); FRAMEOF <- c(K0c = "K0", K3pc = "K3p", K3c1 = "K3p", K3c2 = "K3p")
gr.hat3c <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b4, b5, b6, b7, b8, b9, b3 = 0) {
  b0 <- b0 + b9 * Planted; b9 <- 0
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    t3 <- if (M3 == "sq") b3 * (bal.c^2 / log(pd.c + 5)) else if (M3 == "lin") b3 * (bal.c / log(pd.c + 5)) else 0
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + t3 + b4 * log(bal.c + 1) + b5 * log(cr.c) +
                b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pmin(pd.c, GUARD) + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1 }
PARS <- function() if (M3 == "none") c("b0", "b1", "b2", "b4", "b5", "b6", "b7", "b8", "b9") else paste0("b", 0:9)
pa_pred <- function(resp, d, b) { b3 <- if ("b3" %in% names(b)) b[["b3"]] else 0
  gr.hat3c(d$DBH.0, d$BALx.0, d$BALx.1, d$CRx.0, d$CRx.1, d$BAPH.0, d$BAPH.1, d$Planted, d$BYI, d$YIP,
           b[["b0"]], b[["b1"]], b[["b2"]], b[["b4"]], b[["b5"]], b[["b6"]], b[["b7"]], b[["b8"]], b[["b9"]], b3 = b3) }
fit_c <- function(d, start) { p <- PARS()
  f3 <- as.formula(sprintf("dDBH ~ gr.hat3c(d1 = DBH.0, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0 = b0, b1 = b1, b2 = b2, b4 = b4, b5 = b5, b6 = b6, b7 = b7, b8 = b8, b9 = b9%s)", if (M3 == "none") "" else ", b3 = b3"))
  nlme(f3, data = d, fixed = as.formula(paste(paste(p, collapse = " + "), "~ 1")), random = b0 ~ 1 | Data/Install/TreeID, start = start[p],
       weights = varPower(0.2, form = ~DBH.0), control = ctl) }
fitS <- function(resp, d, start) tryCatch(fit_c(d, start), error = function(e) NULL)
SIGNc <- function(b, cand) { s <- SIGN$dDBH(b); if (cand == "K3c2") s <- c(s, b3_nonpos = b[["b3"]] <= 0); s }
