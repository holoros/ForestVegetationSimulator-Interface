# koa review analyses and increment refit comparison, 27 to 30 September 2026

Analysis scripts, run notes and small aggregate outputs from firebreather (Debian 11, R 4.5.1, nlme; python3). No data tables, no plot keys, no coordinates.

koa_rv_incr, koa_rv_byi, koa_rv_facts, koa_rv_mort, koa_rv_kulani, koa_rv_stock, koa_rv_fiaagent (28 to 29 Sept): reviewer requested analyses behind the v102 to v104 revisions (BAL live list shift, BYI validity, mortality, Kulani contrast, stocking, FIA fire attribution). koa_incform: increment form comparison. koa_bal_recal: origin multipliers under three BAL definitions without refitting. koa_figfix: figure regeneration for v104.

koa_refit_20260929: two pass refit of the increment equations under deposited, live list and conventional BAL on consecutive, non overlapping and all interval frames, with engine deployment trials (engine_refit, engine_refit2, patch scripts only here) and the RLF financial yield grid comparison (fin/). Two red team reviews (kept with the manuscript, not here) returned do not deploy: the all interval fits under predict trees above 20 cm and flip the crown ratio and stand basal area signs, and the second pass NO frame fits do not beat the incumbent v102 vectors under identical covariates and carry a weakly identified BYI slope. The incumbent v102 increment vectors stay deployed pending upstream data repair.

Upstream data defects documented here: (1) deposited plot year BAPH and TPH are exactly doubled on 29 single species plot years (PSP 2021 x20, PSP 201 to 208 in 2017, Kulani 12 and 23 in 1994, Waiakea 24 in 1968; out/plotyear_repair_log.csv) and mis-scaled on 17 more; (2) Keauhou installations 101 to 108 carry a 2015 record that copies 2014 verbatim, with partial copies in 2017 and 2019.
