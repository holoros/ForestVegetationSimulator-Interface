## lib_r2.R: ../lib_c.R unchanged + gr.hat3c redefined with M6 ("sqrt" b6 sqrt(bapa S) as before, "log" b6 ln(bapa)) and M3 "sqfix" (b3 fixed at B3FIX).
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R"))
RB <- path.expand("~/jobs/koa_rdcomp_20261102/constrained/rev2"); OR <- file.path(RB, "out"); M6 <- "sqrt"; B3FIX <- 0
gr.hat3c <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b4, b5, b6, b7, b8, b9, b3 = 0) {
  b0 <- b0 + b9 * Planted; b9 <- 0
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    t3 <- if (M3 == "sq") b3 * (bal.c^2 / log(pd.c + 5)) else if (M3 == "lin") b3 * (bal.c / log(pd.c + 5)) else if (M3 == "sqfix") B3FIX * (bal.c^2 / log(pd.c + 5)) else 0
    t6 <- if (M6 == "log") b6 * log(bapa.c) else b6 * sqrt(bapa.c * pd.c)
    gr <- exp(b0 + b1 * log(pd.c + 1) + b2 * pd.c + t3 + b4 * log(bal.c + 1) + b5 * log(cr.c) +
                t6 + b7 * Planted * pmin(pd.c, GUARD) + b8 * log(rain) + b9 * (rain / 1000))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1 }
PARS <- function() if (M3 %in% c("none", "sqfix")) c("b0", "b1", "b2", "b4", "b5", "b6", "b7", "b8", "b9") else paste0("b", 0:9)
fit_c <- function(d, start) { p <- PARS()
  f3 <- as.formula(sprintf("dDBH ~ gr.hat3c(d1 = DBH.0, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0 = b0, b1 = b1, b2 = b2, b4 = b4, b5 = b5, b6 = b6, b7 = b7, b8 = b8, b9 = b9%s)", if (M3 %in% c("none", "sqfix")) "" else ", b3 = b3"))
  nlme(f3, data = d, fixed = as.formula(paste(paste(p, collapse = " + "), "~ 1")), random = b0 ~ 1 | Data/Install/TreeID, start = start[p],
       weights = varPower(0.2, form = ~DBH.0), control = ctl) }
fitS <- function(resp, d, start) tryCatch(fit_c(d, start), error = function(e) NULL)
SET <- function(cand) { if (cand == "K3c3") { M3 <<- "none"; M6 <<- "log" } else if (cand == "P05") { M3 <<- "sqfix"; B3FIX <<- -0.05; M6 <<- "sqrt" }
  else if (cand == "P5") { M3 <<- "sqfix"; B3FIX <<- -0.5; M6 <<- "sqrt" } else if (cand %in% c("K0", "K3p")) { M3 <<- "sq"; M6 <<- "sqrt" }
  else if (cand == "K3c1") { M3 <<- "none"; M6 <<- "sqrt" } else stop("cand") }
