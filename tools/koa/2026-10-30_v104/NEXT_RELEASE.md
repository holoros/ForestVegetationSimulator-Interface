# koa engine and HiGy.R: next release roadmap (after v104 / HiGy.R 0.4.2)

Written 31 October 2026. Ranked by expected effect on long-term projections. Numbers are from the v104 Bakuzis assessment of 31 October 2026 (`a4/bakuzis/bakuzis_checks_v103_v104.csv` and `sc_summary` in `numbers_v104.json` of job koa_v104_20261030).

1. **Replace the hard diameter ceiling with a smooth size asymptote.** The harness caps diameter at 90 cm (natural) and 69.7 cm (planted) (koa_params HARNESS_DBH_MAX_NATURAL_CM, HARNESS_DBH_MAX_PLANTED_CM). Either add a size asymptote to Eq. 4 (diameter increment) or tie the mortality of trees at the ceiling to it. In the 31 October assessment basal area falls past about 150 yr while the cohort stops growing, and basal area site order reverses at 200 and 300 yr (even-aged natural, low / medium / high: 21.8 / 20.8 / 20.2 m2 ha-1 at 200 yr and 12.2 / 11.2 / 10.7 at 300 yr).
2. **Express Stage 2 after peak SDI relative to the Garcia maximum size-density line.** After-peak log stems against log QMD slopes are -2.90 to -3.22 for even-aged natural stands (planted -2.05 to -2.34); the target is a return toward -1.6.
3. **Compute top height from the initial cohort's 100 largest stems per hectare,** not from the surviving list, so mortality cannot raise top height by removing small trees.
4. **Re-check Stage 3 ordering at dense natural starts.** QMD at 100 yr is 63.2 cm at 2,000 stems ha-1 against 55.8 cm at 250, the reverse of the expected density order.
5. **Merge or retire the 0.5.x HiGy line on `koa-mortality-m1-20260911`,** now that 0.4.2 on ClaudeDevelopment carries the v104 constants and the expansion-weighted BAL. Its mortality section is a separate port and should not be merged wholesale.
