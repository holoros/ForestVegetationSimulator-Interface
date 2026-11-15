# koa_step_rdbyi.R  Standalone reference implementation of the koa (Acacia koa) annual individual-tree system, relative-density framework with
# the maximum stand density index predicted from site (BYI) and origin. Version of November 15, 2026 (deposit 1.14.1): the height curve E2 and the
# height increment equation E5 are fitted jointly and share one asymptote, A = exp(a0 + a_lbyi ln(BYI)), and a two-stage ingrowth rate is available
# for natural stands. Reads its coefficients from koa_rdbyi_equations.csv.
# Nothing is hard-coded except unit constants (breast height 1.37 m, 0.00007854 for basal area in m2 from cm, Reineke exponent 1.605,
# reference diameter 25.4 cm, and for ingrowth the entry diameter 12.7 cm, the nine-year interval and the 59.5 trees per ha that one tree stands
# for on the subplots the rate was fitted to) and three numerical guards (relative density below 0.001, basal area below 1e-6 and height below
# 0.5 m are held at those values where they enter a logarithm or a ratio). The height increment is zero for a tree taller than the asymptote.
# No multiplier, cap or frontier. Competition is from live koa only. Crown base is an output only: no equation uses it.
# Inputs: dbh (cm), ht (m), expf (trees per ha represented by each record), byi (biomass yield index, Mg per ha), planted (1 or 0).
# sdimax may be supplied for a site with a local estimate; by default it is S1: SDImax = exp(s0 + s1 ln(BYI) + s2 planted).
# height = "rule" in koa_step and koa_project gives the height increment rule of earlier versions with the present curve, E2(D + dD) - E2(D),
# which is the documented fallback for a tree list without competition.
# ingrowth = TRUE in koa_project adds, each year, the expected number of koa per ha passing 12.7 cm, from the koa QMD at the start of the year,
# as one record at 12.7 cm with the height of E2. The rate was fitted to natural stands (48 subplots, 10 recruits) and chosen after the fact from
# a screen of forms; it is a scenario assumption, falls toward zero as QMD rises, and is not meant for planted stands.
koa_read_coef <- function(path) { d <- read.csv(path, stringsAsFactors = FALSE); g <- function(eq) { x <- d[d$equation == eq, ]; setNames(x$estimate, x$term) }
  list(e2 = g("E2_height"), s1 = g("S1_sdimax"), e3 = g("E3c_crown_base"), e4 = g("E4r_diameter_increment"), e5 = g("E5_height_increment"), e6 = g("E6r_mortality"), ig = g("IG_ingrowth")) }
koa_sdimax <- function(byi, planted, cf) exp(cf$s1[["(Intercept)"]] + cf$s1[["lbyi"]] * log(byi) + cf$s1[["planted"]] * planted)            # S1
koa_asymptote <- function(byi, cf) exp(cf$e5[["a0"]] + cf$e5[["a_lbyi"]] * log(byi))                                    # A, total height (m), shared by E2 and E5
koa_height <- function(dbh, byi, cf) 1.37 + (koa_asymptote(byi, cf) - 1.37) * (1 - exp(-cf$e2[["b"]] * dbh))^cf$e2[["c"]]  # E2
koa_hcb <- function(ht, x, cf) ht / (1 + exp(cf$e3[["b0"]] + cf$e3[["lH"]] * log(ht) + cf$e3[["x"]] * x))            # E3c, height to crown base (m); x = (BAL/BA) RD
koa_dht <- function(ht, x, byi, planted, cf) { h <- cf$e5; H <- pmax(ht, 0.5); A <- koa_asymptote(byi, cf); m <- exp(h[["lc"]])
  pmax(m * exp(h[["lk"]] + h[["k_pl"]] * planted) * H * ((A / H)^(1 / m) - 1), 0) * exp(h[["x"]] * x) }                # E5, m per year
koa_ingrowth <- function(qmd, cf) (1 - exp(-9 * exp(cf$ig[["t0"]] + cf$ig[["t_qmd"]] * qmd))) * cf$ig[["mu2"]] * 59.5 / 9   # trees per ha per year passing 12.7 cm
koa_stand <- function(dbh, ht, expf) { ba <- 0.00007854 * dbh^2 * expf; B <- sum(ba); N <- sum(expf); q <- sqrt(B / N / 0.00007854)
  list(BA = B, TPH = N, QMD = q, SDI = N * (q / 25.4)^1.605, HT = sum(ht * ba) / B, ba = ba) }
koa_bal <- function(dbh, ba) { o <- order(-dbh); cs <- cumsum(ba[o]); d <- dbh[o]; g <- cumsum(c(TRUE, diff(d) != 0)); out <- numeric(length(dbh))
  out[o] <- ave(cs, g, FUN = max) - ave(ba[o], g, FUN = sum); out }                                                     # basal area of larger trees; ties share
koa_step <- function(dbh, ht, expf, byi, planted, cf, sdimax = koa_sdimax(byi, planted, cf), height = c("E5", "rule")) { height <- match.arg(height)
  s <- koa_stand(dbh, ht, expf); bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sdimax; x <- (bal / max(s$BA, 1e-6)) * rd; b <- cf$e4; m <- cf$e6
  dD <- exp(b[["b0"]] + b[["ls"]] * log(dbh + 1) + b[["s"]] * dbh + b[["xrd"]] * x + b[["lbyi"]] * log(byi) + b[["pl"]] * planted)   # E4r, cm per year
  dH <- if (height == "E5") koa_dht(ht, x, byi, planted, cf) else koa_height(dbh + dD, byi, cf) - koa_height(dbh, byi, cf)   # E5, or the rule as fallback
  eta <- m[["(Intercept)"]] + m[["ld"]] * log(dbh + 1) + m[["dbh_m"]] * dbh + m[["dbh_m2"]] * dbh^2 + m[["BAL"]] * bal + m[["lrd"]] * log(max(rd, 0.001)) + m[["lbyi"]] * log(byi) + m[["planted"]] * planted
  pm <- 1 - exp(-exp(eta))                                                                                             # E6r, annual probability of death
  list(dbh = dbh + dD, ht = ht + dH, expf = expf * (1 - pm), hcb = koa_hcb(ht, x, cf), qmd = s$QMD) }                  # all use the start-of-year state; hcb is for the start-of-year trees
koa_project <- function(dbh, ht, expf, byi, planted, years, cf, sdimax = koa_sdimax(byi, planted, cf), height = c("E5", "rule"), ingrowth = FALSE) { height <- match.arg(height); out <- vector("list", years + 1)
  for (y in 0:years) { s <- koa_stand(dbh, ht, expf); out[[y + 1]] <- data.frame(year = y, BA = s$BA, TPH = s$TPH, QMD = s$QMD, SDI = s$SDI, RD = s$SDI / sdimax, HT = s$HT)
    if (y < years) { z <- koa_step(dbh, ht, expf, byi, planted, cf, sdimax, height); dbh <- z$dbh; ht <- z$ht; expf <- z$expf
      if (ingrowth) { ni <- koa_ingrowth(z$qmd, cf); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, 12.7); ht <- c(ht, koa_height(12.7, byi, cf)); expf <- c(expf, ni) } } } }
  do.call(rbind, out) }
