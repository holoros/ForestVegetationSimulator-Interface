# patch_53.py  Builds scripts/53_longterm_metrics_j1.R from scripts/36_longterm_metrics.R (run on firebreather in the job folder).
s = open('scripts/36_longterm_metrics.R').read()
def rep(a, b, n=1):
    global s
    assert s.count(a) == n, (a[:60], s.count(a)); s = s.replace(a, b)
s = ("# 53_longterm_metrics_j1.R  Script 36 with the system of manuscript v136: height increment J1, the joint height curve wherever a height is filled in or the\n"
     "# fallback rule is applied, and two-stage QMD ingrowth in the natural scenarios.\n") + s
a = s.index('H <- readRDS("out/height_increment_33b.rds");'); b = s.index('hcb <- function(')
new = ('CB <- readRDS("out/crown_base_34.rds"); thB <- readRDS("out/height_increment_44.rds")$FF$J1$th; kh3 <- function(d, byi) 1.37 + (exp(thB[[1]] + thB[[2]] * log(byi)) - 1.37) * (1 - exp(-exp(thB[[7]]) * d))^exp(thB[[8]])\n'
       'getL <- function(p) { pv <- pick[planted == p]; L <- tr[pid == pv$pid & Measure == pv$Measure & Status == "live" & !is.na(DBH) & DBH > 0]; L[is.na(HT) | HT < 1.37, HT := kh3(DBH, BYI)]; L }\n'
       'IB <- readRDS("out/ingrowth_50.rds"); irate <- function(q) (1 - exp(-9 * exp(IB$b[[1]] + IB$b[[2]] * q))) * IB$mu2 * 59.5 / 9\n'
       'hfn <- function(nm) if (nm == "R0") function(Hh, D, D1, x, lbyi, pl) kh3(D1, exp(lbyi)) - kh3(D, exp(lbyi)) else function(Hh, D, D1, x, lbyi, pl) { Hh <- pmax(Hh, 0.5); A. <- exp(thB[[1]] + thB[[2]] * lbyi); cc <- exp(thB[[4]]); inc <- pmax(cc * exp(thB[[3]] + thB[[6]] * pl) * Hh * ((A. / Hh)^(1 / cc) - 1), 0) * exp(thB[[5]] * x); inc[!is.finite(inc)] <- 0; inc }\n'
       'forms <- c("R0", "J1"); cat("height forms compared: R0 (fallback rule with the joint curve) and J1 (adopted); crown base form:", CB$pick, "; natural scenarios with QMD ingrowth\\n")\n')
s = s[:a] + new + s[b:]
rep('dbh <- dbh + g; ex <- ex * (1 - pm) }', 'dbh <- dbh + g; ex <- ex * (1 - pm); if (pl == 0) { ni <- irate(s$QMD); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, 12.7); ht <- c(ht, kh3(12.7, byi)); ex <- c(ex, ni) } } }')
rep('out/longterm_metrics_36', 'out/longterm_metrics_53', 2)
open('scripts/53_longterm_metrics_j1.R', 'w').write(s); print('written')
