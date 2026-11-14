# koa_step_rdbyi.R  Standalone reference implementation of the koa (Acacia koa) annual individual-tree system, relative-density framework with
# the maximum stand density index predicted from site (BYI) and origin. Version of November 14, 2026 (deposit 1.14.0): height increment is the
# fitted equation E5 (bounded differential Chapman-Richards form) and crown base E3c is added. Reads its coefficients from koa_rdbyi_equations.csv.
# Nothing is hard-coded except unit constants (breast height 1.37 m, 0.00007854 for basal area in m2 from cm, Reineke exponent 1.605 and
# reference diameter 25.4 cm) and three numerical guards (relative density below 0.001, basal area below 1e-6 and height below 0.5 m are held
# at those values where they enter a logarithm or a ratio). The height increment is zero for a tree taller than the asymptote of E5.
# No multiplier, cap, frontier or ingrowth. Competition is from live koa only. Crown base is an output only: no equation uses it.
# Inputs: dbh (cm), ht (m), expf (trees per ha represented by each record), byi (biomass yield index, Mg per ha), planted (1 or 0).
# sdimax may be supplied for a site with a local estimate; by default it is S1: SDImax = exp(s0 + s1 ln(BYI) + s2 planted).
# height = "rule" in koa_step and koa_project gives the height increment rule of versions up to 1.13.1, E2(D + dD) - E2(D), which is the
# documented fallback for a tree list without BYI or competition.
koa_read_coef <- function(path) { d <- read.csv(path, stringsAsFactors = FALSE); g <- function(eq) { x <- d[d$equation == eq, ]; setNames(x$estimate, x$term) }
  list(e2 = g("E2_height"), s1 = g("S1_sdimax"), e3 = g("E3c_crown_base"), e4 = g("E4r_diameter_increment"), e5 = g("E5_height_increment"), e6 = g("E6r_mortality")) }
koa_sdimax <- function(byi, planted, cf) exp(cf$s1[["(Intercept)"]] + cf$s1[["lbyi"]] * log(byi) + cf$s1[["planted"]] * planted)            # S1
koa_height <- function(dbh, cf) 1.37 + cf$e2[["a0"]] * (1 - exp(-cf$e2[["b"]] * dbh))^cf$e2[["c"]]                    # E2
koa_hcb <- function(ht, x, cf) ht / (1 + exp(cf$e3[["b0"]] + cf$e3[["lH"]] * log(ht) + cf$e3[["x"]] * x))            # E3c, height to crown base (m); x = (BAL/BA) RD
koa_dht <- function(ht, x, byi, planted, cf) { h <- cf$e5; H <- pmax(ht, 0.5); A <- exp(h[["a0"]] + h[["a_lbyi"]] * log(byi)); m <- exp(h[["lc"]])
  pmax(m * exp(h[["lk"]] + h[["k_pl"]] * planted) * H * ((A / H)^(1 / m) - 1), 0) * exp(h[["x"]] * x) }                # E5, m per year
koa_stand <- function(dbh, ht, expf) { ba <- 0.00007854 * dbh^2 * expf; B <- sum(ba); N <- sum(expf); q <- sqrt(B / N / 0.00007854)
  list(BA = B, TPH = N, QMD = q, SDI = N * (q / 25.4)^1.605, HT = sum(ht * ba) / B, ba = ba) }
koa_bal <- function(dbh, ba) { o <- order(-dbh); cs <- cumsum(ba[o]); d <- dbh[o]; g <- cumsum(c(TRUE, diff(d) != 0)); out <- numeric(length(dbh))
  out[o] <- ave(cs, g, FUN = max) - ave(ba[o], g, FUN = sum); out }                                                     # basal area of larger trees; ties share
koa_step <- function(dbh, ht, expf, byi, planted, cf, sdimax = koa_sdimax(byi, planted, cf), height = c("E5", "rule")) { height <- match.arg(height)
  s <- koa_stand(dbh, ht, expf); bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sdimax; x <- (bal / max(s$BA, 1e-6)) * rd; b <- cf$e4; m <- cf$e6
  dD <- exp(b[["b0"]] + b[["ls"]] * log(dbh + 1) + b[["s"]] * dbh + b[["xrd"]] * x + b[["lbyi"]] * log(byi) + b[["pl"]] * planted)   # E4r, cm per year
  dH <- if (height == "E5") koa_dht(ht, x, byi, planted, cf) else koa_height(dbh + dD, cf) - koa_height(dbh, cf)       # E5, or the rule as fallback
  eta <- m[["(Intercept)"]] + m[["ld"]] * log(dbh + 1) + m[["dbh_m"]] * dbh + m[["dbh_m2"]] * dbh^2 + m[["BAL"]] * bal + m[["lrd"]] * log(max(rd, 0.001)) + m[["lbyi"]] * log(byi) + m[["planted"]] * planted
  pm <- 1 - exp(-exp(eta))                                                                                             # E6r, annual probability of death
  list(dbh = dbh + dD, ht = ht + dH, expf = expf * (1 - pm), hcb = koa_hcb(ht, x, cf)) }                               # all use the start-of-year state; hcb is for the start-of-year trees
koa_project <- function(dbh, ht, expf, byi, planted, years, cf, sdimax = koa_sdimax(byi, planted, cf), height = c("E5", "rule")) { height <- match.arg(height); out <- vector("list", years + 1)
  for (y in 0:years) { s <- koa_stand(dbh, ht, expf); out[[y + 1]] <- data.frame(year = y, BA = s$BA, TPH = s$TPH, QMD = s$QMD, SDI = s$SDI, RD = s$SDI / sdimax, HT = s$HT)
    if (y < years) { z <- koa_step(dbh, ht, expf, byi, planted, cf, sdimax, height); dbh <- z$dbh; ht <- z$ht; expf <- z$expf } }
  do.call(rbind, out) }
