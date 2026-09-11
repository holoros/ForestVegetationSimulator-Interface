# HiGy.R 0.5.0 port, parity report

**Date.** September 11, 2026.
**Scope.** Ports `ben-package-2026-09-08/HiGy.R` (version 0.4.0, the `garcia_qmd_anchored` arm)
onto the mortality engine of record selected by `MORTALITY_RULE_2026-09-12.md` AMENDMENT 1,
namely candidate **M1**. Two things move and nothing else does. First, Stage 1 goes live as a
deterministic **gate** on the production stand rate: the deployed annual rate becomes
`m_garcia / p_bar * p(SDI, origin)`, clipped to `[0, 0.95]`, with `p` the complementary log-log
occurrence probability newly fitted on 326 plot intervals over 54 plots and
`p_bar = 0.3600578102962374` the mean fitted annual occurrence over that record. Second, Stage 3
orders deaths within the stand by the **fitted tree-level survivor equation** rather than by
relative size, with the as-published size weight retained and reachable by argument.

The García (2009) recursion, the anchored beta `0.16019053617304435`, the `H_QMD` allometry and
the A1 background floor are **unchanged**. This port adds a multiplier in front of the rate and
changes a weight behind it. `koa_mortality_step()` and `koa_allocate_mortality()`, the standalone
wrappers documented as not on the production path, keep the September 9 behaviour by explicit
default (ungated, unfloored, fitted beta, relative-size weight), so every 0.4.0 arm stays
separately reproducible from the same file exactly as the 0.4.0 parity report undertakes.

## What changed in HiGy.R (0.4.0 to 0.5.0)

1. **New Stage 1 constants**, transcribed at full fitted precision from the fit's own
   `out_stage1/stage1_fit.json` (`stage1_beta`, `stage1_mean_annual_p`):
   `KOA_S1_INTERCEPT = -1.8660048476490962`, `KOA_S1_LNSDI = 0.18970168229495396`,
   `KOA_S1_PLANTED = 0.1833723331227772`, `KOA_S1_PBAR = 0.3600578102962374`, together with the
   deployed guards `KOA_S1_SDI_FLOOR = 1.0`, `KOA_S1_ETA_CLIP = c(-30, 5)` and
   `KOA_RATE_CAP = 0.95`. Nothing is rounded and nothing is invented. The plot-clustered 95%
   intervals are carried as a comment for the record and are read by no code path. The self-test
   asserts each of the four coefficients with `identical()` against the fitted double, so a
   rounded constant fails rather than passes quietly.

2. **New function `koa_stage1_p(sdi, origin, yip)`**, ported line for line from the deployed
   `threestage.py:stage1_p()`: `p = 1 - exp(-exp(eta))` with
   `eta = b0 + b_lnSDI ln(max(SDI, 1)) + b_planted * planted + ln(YIP)` and `eta` clipped to
   `[-30, 5]` before exponentiation, the same clip the deployed source applies.

3. **New function `koa_gate_rate(m_stand, sdi, origin)`**, ported line for line from
   `threestage.py:rate_M1()`: `clip(m_stand / p_bar * p(SDI, origin), 0, 0.95)`. It takes **no
   `yip` argument** and always evaluates the occurrence at `yip = 1`. What multiplies the rate is
   the ratio `p(SDI) / p_bar`, a mean-one relative density adjustment, and `p_bar` is an annual
   mean; putting a multi-year `YIP` into the numerator alone would stop the ratio being mean one
   and would silently inflate every rate. The ratio is dimensionless, so the García step keeps its
   exactness in step length. When `sdi` is not finite the rate passes through **ungated**, which is
   what the deployed wrapper does; it is silent there and silent here so the two cannot disagree.

4. **New function `koa_surv_annual(dbh, ht, cr, rht, byi, yip)`** and its constant vector
   `KOA_S3_SURV = c(14.102, 0.130, -4.516, 6.684, 14.218, -2.806, 2.649, -21.188)`, transcribed
   from the deposit's `figshare_v66/koa_equations.py` `LineageA.SURV` and `LineageA.surv_annual()`.
   This is manuscript Table 6 on the ALIVE response,
   `P(alive) = clip(1 - exp(-exp(eta + ln YIP)), 0, 1)`. **It is not `surv_prob()` and it does not
   resolve the two divergences flagged above `surv.parm`.** `surv.parm` still carries the
   development-snapshot vector `(18.133, …)` and the `exp(-exp(eta))` sense, both untouched, and
   `mort.engine = 'cloglog'` still reproduces every pre-0.3.0 projection. The choice between those
   lineages stays open and stays yours and Aaron's. It does not need to be settled for this port,
   because a renormalized ordering weight is insensitive to the level the two lineages disagree
   about, and item 9 below is the check that proves it.

5. **`koa_alloc_frac()` gains `mode`**, defaulting to `KOA_ALLOC_MODE = "tree_eq"`. Under
   `tree_eq` the weight is `w = clip(1 - koa_surv_annual(...), 1e-9, 1)`; under `rel_size` it is
   the as-published `exp(-b (DBH/QMD - 1))` with `b = 3`. Everything after the weight is identical
   in both modes: `m_i = m_stand * w / wbar`, capped at 0.95, and renormalized by
   `koa_renormalize_to_stand_rate()`, which is untouched and remains the single carrier of that
   algebra. `tree_eq` requires `ht`, `cr`, `rht` and `byi`; a missing one raises an error naming it
   and never falls back silently to the other weight. `wbar` gained the deployed source's
   `max(wbar, 1e-9)` guard, which is a no-op on any real stand.

6. **`koa_step_deaths()` gains `gate`, default `TRUE`, and this is where the gate is applied.**
   `calc_mortality()`'s García branch reaches the step through this function and through no other,
   so gating here gates production and leaves `koa_regular_survival()` and every reproduction path
   alone. The gate is applied to the **post-floor** rate, because that is where the deployed engine
   applies it (it wraps the Python `stand_mortality()`, which floors before returning), and the
   optional irregular loss is then taken from the gated survivors. With `gate = FALSE` the returned
   deaths are bitwise the September 9 value, because that branch returns `reg$deaths` itself rather
   than recomputing it from the rate.

7. **`calc_mortality()` gains `gate = TRUE` and `alloc.mode = KOA_ALLOC_MODE`**, and forms
   `rht.step` in base R before the pipe on the same plot `htmax` the retired cloglog branch forms
   `r.ht` on, so the two branches of that function cannot disagree about what relative height
   means. The deployed Python projector takes its maximum over a koa-only tree list, where the two
   coincide; on an FVS-HI plot carrying OT records the plot maximum is this file's existing
   convention and is kept.

8. **The standalone wrappers pin their own defaults, as they already did for beta and the floor.**
   `koa_allocate_mortality()` defaults to `mode = "rel_size"` and `koa_mortality_step()` to
   `alloc_mode = "rel_size", gate = FALSE`. Both reach the deployed behaviour by argument. This is
   what keeps the 0.4.0 promise that every arm stays separately reproducible from one file, and the
   self-test now pins it explicitly rather than leaving it to be inferred.

9. **`VersionTag` moves to `"HiGyV0.5.0"`**, the file banner to `v0.5.0`, and a 0.5.0 entry is
   added to the update summary and to the component header.

Full diff-by-anchor is reproducible from `_ben_port_20260911/patch_higy_050.py` (not itself part
of the package). It is string-anchored against the September 9 file and requires an exact, unique
match for each of its 17 edits, so a bad anchor fails loudly rather than silently. All 17 matched.

## A consequence worth stating plainly: the gate scales the A1 floor

The gate is applied after the floor, so the floor is scaled like any other rate. A flat stand no
longer returns exactly 0.003 or 0.006 yr⁻¹; it returns that value times `p / p_bar`. The gate is
neutral at SDI **266.30 natural** (solved from the file's own constants, not remembered), scales
the rate **down** below that and **up** above it. The natural A1 floor of 0.003 yr⁻¹ becomes
0.0023119841 at SDI 50 and 0.0039220972 at SDI 1725. This is the deployed behaviour, not an
oversight, and the self-test asserts the direction in both cases so it cannot be changed by
accident.

## Cross-language parity against the deployed Python source

Both sides ran on firebreather (R 4.5.1, Python 3 with numpy), the R side sourcing the ported
`HiGy.R` unmodified and the Python side importing `threestage.py`, `koa_mortality_garcia.py`,
`koa_equations.py`, `koa_params.py` and `koa_survival_calibrated_py.py` unmodified from the
`koa_m1_regen` job tree, which is the same source `regen_m1.py` deploys. Both sides read the same
`koa_parity_cases_050.json`, so the two cannot drift on what they were asked. The Python side
reproduces what `run_candidates.project()` does per year; the R side drives `koa_h_qmd()`,
`koa_regular_survival()`, `koa_stage1_p()`, `koa_gate_rate()`, `koa_step_deaths()` and
`koa_alloc_frac()`. Every tree list in the case file is synthetic and written for this harness; it
carries no plot identifier and no observation from the FIA record.

Eighteen cases were run, spanning the gate scaling down, neutral and up, both origins, both
Stage 3 weights, the A1 floor reached and gated, the per-tree cap solve, the 0.95 clip, the
ungated pass-through on a missing SDI, and the gate switched off.

| label | origin | SDI | Stage 3 | m_garcia | p(SDI, origin) | m_stand R | m_stand Py | match |
|---|---|---|---|---|---|---|---|---|
| A_low_nat_treeeq | natural | 75.6 | tree_eq | 0.003000000000 | 0.296375977462 | 0.002469403265 | 0.002469403265 | exact |
| B_low_plt_treeeq | planted | 75.6 | tree_eq | 0.006000000000 | 0.344434340461 | 0.005739650644 | 0.005739650644 | exact |
| C_mid_nat_treeeq | natural | 376.8 | tree_eq | 0.005359382308 | 0.379208840517 | 0.005644441234 | 0.005644441234 | exact |
| D_mid_plt_treeeq | planted | 376.8 | tree_eq | 0.006000000000 | 0.436007395005 | 0.007265623173 | 0.007265623173 | exact |
| E_high_nat_treeeq | natural | 1725.5 | tree_eq | 0.048630584619 | 0.470744405149 | 0.063580277872 | 0.063580277872 | exact |
| F_high_plt_treeeq | planted | 1725.5 | tree_eq | 0.048630584619 | 0.534360378893 | 0.072172459199 | 0.072172459199 | exact |
| G_low_nat_relsize | natural | 75.6 | rel_size | 0.003000000000 | 0.296375977462 | 0.002469403265 | 0.002469403265 | exact |
| H_mid_nat_relsize | natural | 376.8 | rel_size | 0.005359382308 | 0.379208840517 | 0.005644441234 | 0.005644441234 | exact |
| I_high_plt_relsize | planted | 1725.5 | rel_size | 0.048630584619 | 0.534360378893 | 0.072172459199 | 0.072172459199 | exact |
| J_flat_nat_treeeq | natural | 376.8 | tree_eq | 0.003000000000 | 0.379208840517 | 0.003159566295 | 0.003159566295 | exact |
| K_flat_plt_treeeq | planted | 376.8 | tree_eq | 0.006000000000 | 0.436007395005 | 0.007265623173 | 0.007265623173 | exact |
| L_surge_nat_treeeq | natural | 376.8 | tree_eq | 0.387141034509 | 0.379208840517 | 0.407732587975 | 0.407732587975 | exact |
| M_surge_nat_relsize | natural | 376.8 | rel_size | 0.387141034509 | 0.379208840517 | 0.407732587975 | 0.407732587975 | exact |
| N_capbind_nat_treeeq | natural | 1360.4 | tree_eq | 0.731502314079 | 0.455684591842 | 0.925780038346 | 0.925780038346 | exact |
| O_capbind_nat_relsize | natural | 1360.4 | rel_size | 0.731502314079 | 0.455684591842 | 0.925780038346 | 0.925780038346 | exact |
| P_clip_nat_treeeq | natural | 1360.4 | tree_eq | 0.831447303018 | 0.455684591842 | 0.950000000000 | 0.950000000000 | exact |
| Q_nosdi_nat_treeeq | natural | not available | tree_eq | 0.005359382308 | not evaluated | 0.005359382308 | 0.005359382308 | exact |
| R_ungated_nat_treeeq | natural | 1725.5 | tree_eq | 0.048630584619 | gate off | 0.048630584619 | 0.048630584619 | exact |

Every compared quantity agrees on all eighteen cases: `H_QMD` at both ends of the step to 8
decimal places, `m_garcia`, `p`, `m_stand`, `wbar` and the maximum per-tree fraction to 12, and
allocated deaths to 6. Across the 126 per-tree rows the largest absolute difference is
**9.095e-13 trees ha⁻¹** on deaths and **3.331e-16** on the per-tree mortality fraction, both far
inside the contract. The two sides also take the same branch of the allocator: in case P the gated
rate reaches the 0.95 clip, the allocation is infeasible, and **both sides warn and put every tree
at the cap**; in cases N and O the stand rate is below the cap while the per-tree cap binds, so the
lambda bisection runs on both sides and returns the same answer. A worked per-tree example, case
O, natural, SDI 1360.4, relative-size weight, stand rate 0.925780038346:

| tree | expf | deaths R | deaths Py | match |
|---|---|---|---|---|
| 1 | 5200.0 | 4940.000000 | 4940.000000 | exact |
| 2 | 3800.0 | 3610.000000 | 3610.000000 | exact |
| 3 | 2600.0 | 2470.000000 | 2470.000000 | exact |
| 4 | 1500.0 | 1425.000000 | 1425.000000 | exact |
| 5 | 800.0 | 736.675040 | 736.675040 | exact |
| 6 | 350.0 | 113.628598 | 113.628598 | exact |
| 7 | 120.0 | 8.155513 | 8.155513 | exact |

Harness and raw output: `parity_python_050.py`, `parity_r_050.R`, `parity_compare_050.py`,
`koa_parity_cases_050.json` and `parity_compare_050.txt`, retained in `_ben_port_20260911/` and on
firebreather job `koa_m1_regen`. The comparator exits non-zero on any disagreement, so this report
could not have been written against a failing run.

## Self-test

`koa_mortality_selftest_2026-09-11.R` is built from the September 9 file with every check carried
forward and **144 checks now pass, none fail**. Section 0 gains `identical()` assertions on all
four Stage 1 coefficients at full precision, on the Table 6 vector element for element, on the
deployed guards, and on the fact that `surv.parm` is still untouched and `surv_prob()` still does
not reference the new vector. Section 2 gains checks that pin the 0.4.0 allocation default, that
`mode = 'tree_eq'` without its columns fails loudly, and that the two modes split the same stand
differently. Section 5's per-plot mirror now passes SDI, because production gates on it and a
mirror that omitted it would compare a gated number against an ungated hand calculation; the
mirror additionally asserts that the gate factor is exactly `p(SDI, origin) / p_bar` and that the
gate is inert when no SDI is supplied. The missing-increment guard's expectation moved from the
flat A1 floor to the **gated** A1 floor, computed per plot since each plot carries its own SDI.

Two new sections do the work the port needs done.

**Section 6, the gate.** The occurrence probability is strictly inside 0 and 1 across an SDI grid
from 50 to 1725, rises monotonically at both origins, and is higher for planted at every density.
The SDI floor of 1 clamps rather than taking a negative logarithm, the `ln(YIP)` offset makes a
longer interval more likely to carry mortality, and the planted probability equals the cloglog of
the fitted linear predictor term for term. The gated rate rises monotonically with SDI, is below
the incumbent at SDI 50 and above it at SDI 1725, and equals `m / p_bar * p` exactly at both
origins. The neutral SDI is solved from the file's own constants and the gate is asserted to return
the incumbent rate unchanged there. The gate is shown to be **one multiplicative factor applied to
every sub-cap rate**, so the A1 floor and a large García step take the identical factor, which is
the property the expectation-preservation argument rests on. The 0.95 clip, the zero-in-zero-out
case, and the ungated pass-through on `NA`, `NaN` and `Inf` are all asserted.

**Section 7, the two Stage 3 weights on one tree list.** Both weights allocate exactly the stand
deaths, deliver the stand rate as the expansion-factor-weighted mean, respect the per-tree cap, and
put more mortality on small trees. The two give a genuinely different split. **Scaling the survivor
weight by 0.1, 0.5, 2 or 37 changes no allocated fraction to 1e-12**, which is the assertion that
the level of that equation does not act. The survivor equation itself is checked to clip crown
ratio at 0.99 and floor diameter at 0.1 cm exactly as the deployed source does, and to carry the
`ln(YIP)` offset on the ALIVE response. Finally it is asserted that `koa_surv_annual()` and
`surv_prob()` still disagree, because the two lineages were never reconciled and this port does not
reconcile them.

One number from section 7 is worth carrying out of it. On the worked five-tree list the fitted
survivor weight is **flatter** across the diameter distribution than the as-published size weight:
the largest per-tree fraction is 1.06 times the stand rate under `tree_eq` against 1.68 under
`rel_size`. The same pattern holds across the parity cases, where the tree_eq spread runs about
1.04 and the rel_size spread about 1.97 on identical stands. The fitted equation spreads mortality
more evenly across small and mid-sized trees and then drops the largest trees to essentially
nothing, whereas the size weight grades more smoothly from small to large. Full output:
`selftest_output_2026-09-11.txt`. **Result: self-test PASSED, 144 of 144 checks.**

## What a reuser must know

**The gate is a ratio, not a level.** By construction the mean deployed rate over the fitting
record is unchanged from the 0.4.0 engine. What moves is where the rate sits across density. If you
compare a 0.5.0 projection against a 0.4.0 one and find the average mortality broadly similar while
low-density stands thin less and high-density stands thin more, that is the port working, not a
bug. The mortality **level** defect is still open and is stated as such in
`MORTALITY_RULE_2026-09-12.md` AMENDMENT 1 section 4: the projection underpredicts mortality by a
factor of four to twenty and underpredicts diameter increment by about 20 percent, and the two have
to be repaired together. M1 does not repair either and was never going to.

**Chen's threshold is deliberately not deployed.** Chen et al. (2023) threshold `p` into a binary
indicator to produce exact zeros in a plot-level prediction. A projected mean stand over a century
is not a single plot realization, so a hard threshold would put a discontinuity into a
deterministic trajectory that nothing in the koa record supports. `p` enters continuously and the
deviation is disclosed in the manuscript.

**Two different Stage 1s now live in this file and they are not the same thing.**
`koa_irregular_event()` is the optional stochastic irregular-event arm, still off by default, still
out of scope. `koa_stage1_p()` is the new deterministic occurrence gate and is on. They share a
name in the Chen structure and share nothing else.

**The gate needs SDI and passes through silently without it.** That mirrors the deployed wrapper
exactly, which is why it was done that way, but it means a caller who wants the gate must supply
SDI. `calc_mortality()` always does, through `sdi.koa`. A caller driving `koa_step_deaths()` by hand
should check.

**`koa_surv_annual()` is an ordering weight and nothing else.** Do not read its returned survival
probabilities as a prediction. Its level is known to be wrong, which is why it appears here only
inside a renormalization that cancels the level, and why the manuscript uses it as a ranking. Item 9
of the self-test is the proof that the cancellation is exact.

## What this does and does not establish

This confirms the R port reproduces the deployed Python engine's gated stand rate and its Stage 3
allocation exactly on the eighteen cases run, at both origins, under both Stage 3 weights, with the
gate scaling down, neutral and up, with the A1 floor binding and not binding, with the per-tree cap
solve running and the 0.95 clip reached, and that the port did not disturb Stage 1's stochastic arm,
the renormalization algebra, the retired cloglog path, or any 0.4.0 reproduction default.

It does not re-run the deposit's own gate harness, which certifies the Python deposit rather than
this R package. It does not re-score M1 against the six gates of `MORTALITY_RULE_2026-09-12.md`;
those scores (H1 FAIL 0.0075 to 0.0106, H2 FAIL decreasing, H3 PASS, H4 4 of 6) come from the
Python run and were not re-derived here. It does not compare a full multi-decade FVS-HI projection
against the Python projector, because the two growth engines differ by design in where the height
increment is taken relative to mortality, which the 0.3.0 entry documents. Parity is established on
the mortality component, which is the same scope the 0.4.0 report established it on.
