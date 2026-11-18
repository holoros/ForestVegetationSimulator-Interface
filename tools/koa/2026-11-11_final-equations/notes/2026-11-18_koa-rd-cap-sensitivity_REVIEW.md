# Koa: relative density held at or below 1.0, sensitivity run (November 18, 2026)

**Status: sensitivity only. Nothing is deployed, and manuscript v137, supplement v129, the workbook, and Zenodo 1.14.1 are unchanged by it.**

## Bottom line

Holding stand relative density (RD) at or below 1.0 changes nothing in natural stands, lowers planted basal area at 40 years by 2 to 8%, and narrows the upper side of the planted bands by 10 to 19 m² ha⁻¹. The benchmark does not move (basal area RMSE 6.80 against 6.76 m² ha⁻¹), because the cap binds on 1 of the 53 remeasured plots. One long-run gate that the published system passes, the yield-density relation, fails under the cap, so the capped system passes four of six gates where the published system passes five.

## What was run

The rule was written into the script header before the run. At the end of each annual step, after growth, mortality, and ingrowth, a stand whose stand density index exceeds its maximum (SDI_max from Eq. 2) has every record's expansion factor multiplied by SDI_max / SDI. The stand returns to RD = 1, and the removed stems are spread in proportion to stems with no size preference. This is a set rule and not a fitted equation, which is the kind of constraint the November rebuild removed.

The comparison used the published system (script 51) and the same system with the rule, on the six scenarios of Table 4 with 500 paired Monte Carlo draws (same seed and same random numbers in both arms), on the benchmark with SDI_max predicted out of fold, and on the six 200-year gates. The published arm reproduces script 51 to 1 × 10⁻¹⁰. Script: `scripts/58_rd_cap_sensitivity.R`; log: `logs/58_rd_cap_sensitivity.log`; outputs: `out/rd_cap_table_58.csv` and `out/rd_cap_scenarios_58.csv` (firebreather, `~/jobs/koa_final_eq_20261110`; copies in `tools/2026-11-18_v137-build/rd_cap/`).

## Results

**Table 1.** Planted scenarios with and without the cap, as point projection (90% band from 500 paired draws). Natural scenarios are identical in both arms at every year and are not shown. The published bands differ in the last digit from Table 4 of the manuscript because the draws use a different seed.

| BYI (Mg ha⁻¹) | Year | BA published (m² ha⁻¹) | BA capped (m² ha⁻¹) | RD published | RD capped | Stems published (ha⁻¹) | Stems capped (ha⁻¹) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 121 | 20 | 27.4 (14.2 to 41.3) | 27.4 (14.2 to 36.1) | 0.88 (0.49 to 1.24) | 0.88 (0.49 to 1.00) | 403 (292 to 447) | 403 (251 to 443) |
| 121 | 40 | 36.5 (20.8 to 51.6) | 35.7 (20.8 to 41.3) | 1.02 (0.62 to 1.30) | 1.00 (0.62 to 1.00) | 271 (152 to 345) | 265 (139 to 339) |
| 121 | 100 | 38.1 (18.2 to 61.5) | 37.8 (18.6 to 46.8) | 0.88 (0.42 to 1.34) | 0.87 (0.43 to 1.00) | 105 (43 to 179) | 105 (43 to 165) |
| 156 | 20 | 31.5 (18.0 to 45.2) | 31.5 (18.0 to 38.6) | 0.92 (0.59 to 1.22) | 0.92 (0.59 to 1.00) | 404 (320 to 446) | 404 (278 to 444) |
| 156 | 40 | 41.1 (25.3 to 54.3) | 39.2 (25.3 to 43.6) | 1.05 (0.69 to 1.32) | 1.00 (0.69 to 1.00) | 267 (170 to 341) | 255 (154 to 332) |
| 156 | 100 | 41.4 (18.7 to 63.2) | 40.8 (18.7 to 49.6) | 0.87 (0.41 to 1.31) | 0.86 (0.40 to 1.00) | 101 (41 to 174) | 101 (41 to 159) |
| 309 | 20 | 45.3 (26.3 to 62.1) | 44.3 (26.3 to 50.5) | 1.02 (0.68 to 1.29) | 1.00 (0.68 to 1.00) | 400 (308 to 451) | 392 (253 to 450) |
| 309 | 40 | 54.8 (36.2 to 70.6) | 50.5 (36.2 to 56.1) | 1.08 (0.80 to 1.30) | 1.00 (0.80 to 1.00) | 247 (151 to 337) | 229 (137 to 327) |
| 309 | 100 | 49.7 (22.8 to 81.8) | 48.7 (22.8 to 62.9) | 0.82 (0.38 to 1.34) | 0.80 (0.38 to 1.00) | 87 (37 to 172) | 88 (39 to 152) |

Notes: BA, basal area; BYI, Biomass Yield Index; RD, relative density (SDI / SDI_max). QMD changed by 1.4% or less in every cell and is in the output file.

In the point runs the cap binds in years 33 to 47 on the low site, 27 to 47 on the median site, and 19 to 42 on the high site, and removes 9, 21, and 50 stems ha⁻¹ in total. Across draws it binds in 13 to 18% of planted stand-years and in under 1% of natural stand-years. The largest published point RD is 1.09 and the largest 95th percentile is 1.35.

On the benchmark, survival RMSE is 0.125 against 0.124, QMD RMSE is 2.78 cm in both arms, and basal area RMSE is 6.80 against 6.76 m² ha⁻¹ (planted 5.84 against 5.79, natural 10.78 in both). Every equivalence test returns the same pass or fail as the published system.

The gates differ in one place. The published system passes site order, the density limit, the basal area ceiling, no late rise, and yield-density, and fails Sukachev. Under the cap the yield-density gate also fails, so basal area no longer rises with starting density at every checked age in the planted density series (300 to 2,400 stems ha⁻¹). The likely reason is that the denser starts are all held on the same limiting line, which the script does not test directly.

## Reading

Three things bear on whether to adopt the cap. First, the data cannot tell the two systems apart, since only one benchmark plot reaches the cap inside its record. Second, the cap removes the upper tail that makes planted RD exceed 1.0 in Table 4 and Fig. S2, and it is conservative for long projections (lower basal area, narrower upper band). Third, it is a set rule with no size preference in who dies, it costs a gate, and it would change Table 4, Fig. 5, the supplement scenario tables, the workbook, and the deposit.

A middle route that needs no rerun is already supported by the text. The Discussion says the fitted maximum is a scaling quantity more than a self-thinning frontier, and the reference code accepts a local SDI_max, so the manuscript can stay as published and cite this run as a supplement sensitivity in a revision if a referee asks.
