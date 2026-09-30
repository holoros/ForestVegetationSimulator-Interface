## s_eval2.R (R1 c4 follow-up). Deployed calibrated Eq. 4 (reference coefficients, deposited BAL, CFX x deployed multiplier) scored by
## measurement period on the planted PSP network, to separate interval length from calendar period and stand development.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
REF <- load_ref(); KDEP <- list(dDBH = c(natural = 0.40548, planted = 1.43606), dHT = c(natural = 0.51917, planted = 2.64739))
out <- list()
for (resp in c("dDBH", "dHT")) { d <- prep(resp); p <- fitted(REF[[resp]], level = 0) / d$YIP * CFX[[resp]] * KDEP[[resp]][d$org]
  i <- which(d$Data %in% c("PSP", "KMR PSP") & d$Planted == 1); per <- paste(d$t.0, d$t.1, sep = "-")[i]
  for (pp in sort(unique(per))) { j <- i[per == pp]
    out[[paste(resp, pp)]] <- data.frame(resp = resp, period = pp, yip = d$YIP[j[1]], n = length(j), n_inst = length(unique(d$InstID[j])),
      mean_size0 = mean(d[[sizevar(resp)]][j]), mean_BAL0 = mean(d$BAL.0[j]), obs = mean(d$ann[j]), pred = mean(p[j]), ratio = sum(d$ann[j]) / sum(p[j])) } }
o <- do.call(rbind, out); o <- o[o$n >= 20, ]; print(o, digits = 3); write.csv(o, file.path(OUT, "eval_planted_by_period.csv"), row.names = FALSE)
