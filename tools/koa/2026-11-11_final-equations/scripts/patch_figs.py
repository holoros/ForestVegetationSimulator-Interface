# patch_figs.py  Builds scripts/54_fig3_figS4_v136.R from 37b and scripts/55_fig4_fig5_v136.R from 40 (run on firebreather in the job folder).
L = open('scripts/37b_fig3_figS4_v135.R').read().split('\n')
assert L[7].startswith('H <- readRDS("out/height_increment_33b.rds")') and L[16].startswith('hd <- f$hd; xs <- seq(1, 100') and L[17].startswith('pH <- ggplot()')
L[7] = ('CB <- readRDS("out/crown_base_34.rds"); thJ <- unlist(readRDS("out/height_increment_44.rds")$FF$J1$th); BJ <- readRDS("out/boot_round4_45.rds")$J1; BJ <- BJ[BJ[, "conv"] == 0, ]; '
        'kh <- function(th, d, byi) 1.37 + (exp(th[[1]] + th[[2]] * log(byi)) - 1.37) * (1 - exp(-exp(th[[7]]) * d))^exp(th[[8]]); cat("height increment drawn: J1 (adopted); height curve: joint curve of J1 at the median BYI of each origin\\n")')
L[16] = ('hd <- f$hd; xs <- seq(1, 100, length.out = 120); h1 <- rbindlist(lapply(c(0, 1), function(p) { by <- byiq[planted == p, md]; m <- apply(BJ, 1, function(b) kh(b, xs, by)); '
         'data.table(origin = orig(p), x = xs, y = kh(thJ, xs, by), lo = apply(m, 1, quantile, 0.025), hi = apply(m, 1, quantile, 0.975)) }))')
L[17] = ('pH <- ggplot() + geom_point(data = hd[DBH <= 100], aes(DBH, HT, colour = orig(planted)), size = 0.25, alpha = 0.25, show.legend = FALSE) + geom_ribbon(data = h1, aes(x, ymin = lo, ymax = hi, fill = origin), alpha = 0.35, show.legend = FALSE) + '
         'geom_line(data = h1, aes(x, y, colour = origin), linewidth = 0.6, show.legend = FALSE) + scale_colour_manual(values = OR) + scale_fill_manual(values = OR) + labs(x = "DBH (cm)", y = "Total height (m)")')
s = '\n'.join(L)
a = 'pr1 <- proj(H$FH[[hform]]$th, G[[hform]]); pr0 <- proj(numeric(0), G$R0);'
assert s.count(a) == 1; s = s.replace(a, 'pr1 <- proj(thJ[1:6], G$B2); pr0 <- proj(thJ, function(th, H, D, D1, x, lb, pl) kh(th, D1, exp(lb)) - kh(th, D, exp(lb)));')
b = 'cvh <- H$cv[form %in% c("R0", hform)];'; assert s.count(b) == 1; s = s.replace(b, 'cb52 <- readRDS("out/j1_eval_52.rds")$cb; cvh <- rbind(cb52[, .(form = "R0", planted, ylen, obs, pred = pR)], cb52[, .(form = "J1", planted, ylen, obs, pred = pJ)]);')
s = s.replace('ms_v135', 'ms_v136'); assert 'hform' not in s and 'H$' not in s and 'bH' not in s, [l[:90] for l in s.split('\n') if 'hform' in l or 'H$' in l or 'bH' in l]
s = '# 54_fig3_figS4_v136.R  Script 37b with the height curve panel drawn from the joint curve of J1 by origin and the height increment panel from J1 and the rule with the joint curve.\ndir.create("~/jobs/koa_final_eq_20261110/ms_v136", showWarnings = FALSE)\n' + s
open('scripts/54_fig3_figS4_v136.R', 'w').write(s)
t = open('scripts/40_fig4_fig5_v135.R').read(); assert t.count('ms_v134b/scenarios_long_b2.csv') == 1
t = t.replace('ms_v134b/scenarios_long_b2.csv', 'ms_v136/scenarios_long_j1.csv').replace('ms_v135', 'ms_v136')
open('scripts/55_fig4_fig5_v136.R', 'w').write('# 55_fig4_fig5_v136.R  Script 40 reading the scenarios of script 51 (natural scenarios with QMD ingrowth); Fig. 4 is unchanged.\n' + t); print('written')
