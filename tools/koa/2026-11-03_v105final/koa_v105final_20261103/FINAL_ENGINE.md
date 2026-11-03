# FINAL ENGINE: koa v105final = D742 with total height Eq. 2 AND HCB Eq. 3 at the v105c forms (run P_HT_HCB)

Decided 2026-11-03 from koa_v105attr_20261103 outputs (out/metrics_long.csv, out/attribution.csv, out/eichhorn_exact.csv). The Track B form screen
(~/jobs/koa_formscreen_20261103; result as reported by the coordinator, not read by this job: nothing passed) leaves the v105d forms wherever the rule
does not revert them.

## Rule (coordinator, set before the HCB / Stage 3 coverage and the pairwise results were known)

"final = D742 with total height reverted to v105c form (R_HT), unless the HCB or Stage 3 revert restores pooled BA coverage to within 0.02 of C742 without
introducing a new Eichhorn or Bakuzis flag, in which case also revert that component; if both, pick the one with smaller added flags."

## Evidence (each run's own output files; Eichhorn = unrounded median CV of VOL at equal HT, limit 10%)

| run | Eq.2 / Eq.3 / Stage 3 | pooled plot BA coverage | Eichhorn EAN / UAN / EAP (%) | Bakuzis PASS/FLAG | low-site nat. culmination (yr) | plot-level BA RMSE, all 17 |
|---|---|---|---|---|---|---|
| D742 | H1a / C2h / M3a | 0.647 | 11.35 F / 12.63 F / 9.34 | 94/35 | 10 | 12.605 |
| R_HT | v105c / C2h / M3a | 0.647 | 8.82 / 9.98 / 7.69 | 96/33 | 22 | 12.605 |
| R_HCB | H1a / v105c / M3a | 0.706 | 11.17 F / 11.74 F / 10.06 F | 93/36 | 21 | 13.258 |
| R_S3 | H1a / C2h / v105c | 0.647 | 11.12 F / 12.24 F / 9.32 | 94/35 | 10 | 12.611 |
| P_HT_HCB | v105c / v105c / M3a | 0.706 | 8.68 / 9.21 / 8.22 | 96/33 | 23 | 13.258 |
| C742 | all v105c (dDBH K3c1) | 0.706 | 8.53 / 9.42 / 8.19 | 96/33 | 21 | 13.259 |

## Application

- Stage 3: its revert does not restore coverage (0.647) -> not reverted (either reading).
- HCB: the rule text admits two readings of "without introducing a new flag":
  (a) evaluated on the single-revert run R_HCB (H1a kept): new flags (Eichhorn even-aged planted 10.06%, Bakuzis 36 vs 35) -> not reverted -> final R_HT;
  (b) evaluated on the engine the clause creates ("also revert" on top of R_HT = P_HT_HCB): coverage 0.706 (= C742), no new flag relative to R_HT
      (Eichhorn PASS in all strata, Bakuzis 96/33) -> HCB also reverted -> final P_HT_HCB.
  Adopted: (b), because the clause specifies a final engine that has both components reverted, and only P_HT_HCB tests that engine; the R_HCB flags come
  from the H1a height it keeps, which the final engine does not keep. The choice of reading was made after P_HT_HCB was seen (it was run as an
  information run); this is declared here. Under reading (a) the final engine would be R_HT (koa_v105attr_20261103/R_HT, a complete engine build).
- Final = P_HT_HCB: dDBH K3c1 and dHT K3c1h refitted with RD = SDI/741.996871565 (brms SDImax of record), mortality Stage 3 M3a refitted under the same
  divisor (floor 0.001130119), total height Eq. 2 at the v105c HT_P (ln(BAPH+1)), HCB at the v105c HCB_P, MORT_CAL re-solved 2.43532.

## Trade-off carried into v105final (regression vs R_HT / D742)

- Plot-level BA RMSE 13.258 vs 12.605 and QMD RMSE 2.779 vs 2.171 (all 17 units; the v105c level is 13.265 / 2.814): the C2h HCB gave the better
  validation fit; reverting it returns validation to the v105c level. The realism checks (culmination, Eichhorn, Bakuzis, coverage) all pass at C742 level.
