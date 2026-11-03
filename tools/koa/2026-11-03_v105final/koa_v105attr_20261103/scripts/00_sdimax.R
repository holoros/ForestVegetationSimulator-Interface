## 00_sdimax.R: population SDImax at QMD 25.4 cm per posterior draw of brms RI_LONG (read only), median and 95% quantile interval.
suppressPackageStartupMessages({ library(brms); library(posterior) })
f <- readRDS(path.expand("~/jobs/koa_brms_sdimax_20261102/fits/RI_LONG_ad0.99_it6000_td12.rds"))
d <- as_draws_df(f, variable = c("b_Intercept", "b_lqmd"))
s <- exp(d$b_Intercept + d$b_lqmd * log(25.4))
o <- data.frame(quantity = "SDImax_pop_QMD25.4", n_draws = length(s), median = median(s), mean = mean(s), q2.5 = quantile(s, .025), q97.5 = quantile(s, .975),
  b0_mean = mean(d$b_Intercept), b1_mean = mean(d$b_lqmd), at_posterior_means = exp(mean(d$b_Intercept) + mean(d$b_lqmd) * log(25.4)), row.names = NULL)
print(o, digits = 12); write.csv(o, "prep/out/sdimax_pop.csv", row.names = FALSE)
