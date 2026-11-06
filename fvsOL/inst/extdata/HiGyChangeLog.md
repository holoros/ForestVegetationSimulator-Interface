# HiGy.R changelog 

### Version 0.4.2

Parameters and equation forms follow the koa v105final model.

#### Parameters
- `ht.pred.parm`, `ddbh.parm`, `dht.parm` and `mort.s3.parm` refit; `b3` of
  `ddbh.parm` and `dht.parm` fixed at 0.
- `ddbh()`: correction factor 1.57859; origin calibration 0.76421 (planted),
  0.23596 (natural).
- `dht()`: correction factor 2.39567; origin calibration 1.21046 (planted),
  0.17573 (natural).
- `mort_prob()` coefficients, `p.bar`, Garcia `beta`, `h.qmd.a` and `h.qmd.k`
  refit; natural stand mortality factor 2.43532.
- New: `sdi.max` (741.996871565), `rd.floor` (0.001130119195), `ingrowth.parm`.

#### Diameter and height increment
- `calc_plot_summary()` returns relative density `rd`: SDI on the 25.4 cm
  index diameter divided by `sdi.max`.
- BAL terms use the BAL share of plot BA times `rd`; `sqrt(ba*dbh)` and
  `sqrt(ba*ht)` replaced by `sqrt(rd*dbh)` and `sqrt(rd*ht)`.

#### Mortality
- Stage 3: `log(ba+1)` and `log(bal+1)` replaced by `log(rd)` (floored at
  `rd.floor`) and `log(bal/ba*rd+1)`.
- Stage 2: Garcia step from the previous year's `H_QMD` to the current
  year's, carried on the tree list as `h.qmd.prev`. Without it (first year)
  only the background floor applies.

#### BAL
- `calc_bal()`: plot BA times the expansion factor weighted share of the
  other trees with DBH at least as large (ties count as larger), as fitted.
- Tree BA and BAL recomputed after growth are now kept (the result was not
  assigned).

#### Crown ratio
- `make_ops(cr.update)`: 'engine' (default) predicts crown ratio from height
  to crown base each year, bounded 0.05 to 0.95; 'recession' keeps the 1%
  annual limit.
- `(pcr-cr)/cr<-0.01` was parsed as an assignment and stopped every
  `HiGYOneStand()` call; now `< -0.01`.

#### Ingrowth
- `pred_ingrowth()` and `calc_ingrowth()`, off by default
  (`make_ops(use.ingrowth)`). Recruits enter at 2.5 cm DBH, crown ratio 0.6,
  and are not returned to FVS.

#### Size limits, BYI, FVS hand-off
- `tree.size.cap` metric and by origin: DBH 90 cm natural, 69.7 cm planted;
  height 28.0416 m (92 ft). `max.dbh` 90 was converted as inches (228.6 cm).
  `make_fvs_calib()` gains `planted`.
- BYI cap of 600 removed; the model of record has none.
- `make_fvs_tree()`: `dg` returned inside bark (x 0.9, FVS-HI koa bark
  ratio). FVS adds `dg`/bark ratio to DBH, so diameter growth was 11% high.
- customRun_fvsRunHi.R: `h.qmd.prev` carried between cycles of a stand.

#### Checks
- Ten 60 year projections (natural and planted, BYI 142 to 418, one with
  ingrowth) against the v105final engine: largest relative difference
  1.6e-13 tree DBH, 7.7e-12 expansion factor, 6.0e-13 stand TPH.
- customRun_fvsRunHi.R with FVShi, 9 Hawaii stands, 50 years, 5 year
  cycles, NoTriple: no failures, NA or negative values. Tree DBH and height
  within 5.5e-7 and stand BA within 1.0e-6 (relative) of the engine
  projections of the same stands.

### Version 0.4.1

#### Parameters
All coefficients updated to the final koa model fit reported in the
Forest Ecosystems manuscript. No equation form changed.

| Object | 0.4.0 | 0.4.1 |
|---|---|---|
| `ht.pred.parm` a0, a1, b, c, g1, g2 | 32.198224, 1.208508, 0.016579, 0.804891, 0.062077, -0.373262 | 28.928831, 0.966788, 0.017026, 0.792247, 0.076841, -0.34331 |
| `ddbh.parm` b0 to b9 | -1.1509411, 0.3371168, -0.0143456, -0.0017722, -0.4306515, 1.2809352, -0.0176013, -0.0176238, 0.3045245, 0.4103534 | 0.2879773, 0.3607553, -0.0223731, -0.0014547, -0.3377001, 0.8411799, -0.0167759, -0.0176977, 0.1402549, -0.0158981 |
| `ddbh()` Duan correction factor | 1.36869 | 1.50128 |
| `ddbh()` origin calibration, planted / natural | 1.43606 / 0.40548 | 0.97085 / 0.25558 |
| `dht.parm` b0 to b9 | -3.6114059, 1.1203441, -0.1154809, -0.0009067, -0.1332027, -0.5250905, 0.0379597, -0.1240880, 0.2232825, 1.0681935 | -2.3749351, 1.1606715, -0.1512773, -0.0001578, -0.1817711, 0.2179147, 0.0639156, -0.1195534, 0.0907741, 0.7574883 |
| `dht()` Duan correction factor | 1.030 | 2.41982 |
| `dht()` origin calibration, planted / natural | 2.64739 / 0.51917 | 1.19285 / 0.18025 |
| `mort_prob()` intercept, ln(SDI), planted | -1.67856483466631, 0.161863756638461, -0.19099361188623 | -1.66812398756876, 0.165585943273251, -0.219166792503203 |
| `calc_mortality()` p.bar | 0.313065206550519 | 0.31272560255909 |
| `plot_survival()` beta | 0.16019053617304435 | 0.14803309491927027 |
| `calc_mortality()` h.qmd.a, h.qmd.k | -0.16863070512157105, 1.1719473700506686 | 0.167997928455782, 1.04106514616602 |
| `calc_mortality()` natural stand mortality factor | 2.64629 | 2.51588 |
| `mort.s3.parm` b0 to b4 | -2.13468022306448, -0.818899541466801, -0.813105157217597, 0.382953931412773, 0.346317281270796 | -2.45353544308563, -1.24379127899638, -0.245835518593837, 0.801873721680337, 0.164263748192269 |

The base rows (used when `byi` is missing or 0) keep b8 = 0 and a1 = 0.
The height to crown base coefficients are unchanged.

#### BAL
- New run option `use.bal.percentile` in `make_ops()`, default FALSE.
  When TRUE, `calc_bal()` computes basal area in larger trees (BAL) as
  plot basal area times the share of the other trees on the plot, weighted
  by expansion factor, with diameter at least as large as the subject tree
  (trees of equal diameter count as larger). This is the BAL definition
  used to fit the 0.4.1 parameters, so it must be TRUE to reproduce the
  model of record. FALSE keeps the cumulative basal area of larger trees.
- New function `bal_percentile()` computes that share.

#### Bug fixes
- `calc_hcb()` filtered its parameters on `ht.parm.type`, which is defined
  only inside `calc_ht()`, so the first height to crown base prediction
  stopped with an error. It now uses `hcb.parm.type`.
- `calc_dht()` passed tree basal area to `dht()`. It now passes plot basal
  area (`ba.plot`), as `calc_ddbh()` does and as the equation was fitted.
- In `HiGYOneStand()`, BAL recalculated after growth was not assigned
  back to the tree list, so crown recession used BAL from before growth.

#### Checks (November 5, 2026, R 4.5.1)
- Height, diameter increment, height increment, and the three mortality
  stages return the same values as the koa model of record on a grid of
  5,184 tree conditions, natural and planted (largest difference 0).
- `calc_bal()` with the option off reproduces 0.4.0 exactly, and with it
  on reproduces the model of record exactly, on 200 random tree lists.
- Five annual cycles of a two plot, 24 tree stand finish with no missing
  values for natural and planted stands, with the option on and off.
- Not yet run through `customRun_fvsRunHi.R` inside FVS.

### Version 0.4.0

#### Height
- Relative diameter in the height equation changed from `dbh / qmd`
  (quadratic mean diameter) to `dbh / max.plot.dbh` (plot maximum
  diameter, capped at 1). `calc_plot_summary()` gains `max.plot.dbh`.
- All six `ht.pred.parm` coefficients (`a0`, `a1`, `b`, `c`, `g1`, `g2`)
  refit.
- Fixed a latent bug: the base/site parameter filter in `calc_ht()` was
  computed but never applied — the coefficient lookup read from the
  unfiltered table, so the site-quality row was silently never selected
  regardless of `byi`. Now applied correctly.

#### Height-to-crown-base
- Coefficients unchanged.
- Guards added to the equation: `ht/dbh` floored via
  `pmax(ht/pmax(dbh, 0.1), 0.5)`; `byi` itself floored at
  1 (`log(pmax(byi, 1)/100)`) instead of the ratio floored at 0.01.
- Same latent base/site filter bug as Height, fixed the same way.

#### Diameter increment
- All `ddbh.parm` coefficients refit.
- Stand density index and relative height dropped from the equation
  entirely. A competition term (`bal^2/log(dbh+5)`) and a size-competition
  term (`sqrt(ba*dbh)`) added; crown-ratio term simplified to
  `log(pmax(cr, 0.01))`.
- Duan correction factor: 1.026 → 1.36869.
- A multiplicative origin-calibration factor added: 0.40548 (natural) /
  1.43606 (planted).
- Output cap: 0-6 cm/yr → 0-4 cm/yr.
- A breast-height gate added: trees below 1.3716 m get zero diameter
  increment (previously ungated).

#### Height increment
- All `dht.parm` coefficients refit, mirroring the diameter-increment
  restructuring (competition term, simplified crown-ratio term, size term,
  origin-calibration factor).
- Duan correction factor: 0.863 → 1.030.
- Origin-calibration factor added: 0.51917 (natural) / 2.64739 (planted).
- Output cap: 0-6 m/yr → 0-2 m/yr.

#### Mortality
Replaces the single tree-level logistic survival equation with a
three-stage stand mortality model:

- **Stage 1 — plot probability.** A new stand-level logistic model
  (intercept, ln(SDI), planted offset) estimates the annual probability a
  stand experiences *any* mortality at all, and scales the Stage 2 rate
  by how that probability compares to the fitting population's average.
- **Stage 2 — whole-stand self-thinning.** Garcia (2009) self-thinning
  curve replaces the per-tree logistic survival equation. Given
  trees/ha and how much an allometric height-equivalent of QMD (`H_QMD`,
  not a literal top height) grew over the step, it returns the stand
  mortality fraction the self-thinning line implies, floored at a small
  origin-specific background rate (0.3%/yr natural, 0.6%/yr planted, even
  with no growth).
- **Origin-level factor.** Natural stands run this refit's mortality
  about 2.6x higher than planted stands, applied as a fixed multiplier
  after the Stage 1 gate.
- **Stage 3 — per-tree allocation.** The single stand-level death rate is
  spent across individual trees by a logistic weight scoring each tree's
  diameter, height relative to the plot's tallest tree, and local
  competition (plot BA, BA in larger trees) — smaller, more suppressed,
  more crowded trees get a larger share. Per-tree shares are capped at
  95%/yr and rescaled, so they still sum to the plot's target rate.
- **Result cap**: stand mortality rate capped at 95%/yr (was implicit,
  uncapped, in the 0.2.0 per-tree equation).
- Unlike every other equations, mortality does not use site index (`byi`) 
- `calc_plot_summary()` gains `max.plot.ht` (relative-height term) and
  `sdi` (stand density index, Reineke exponent 1.605.


### version 0.2.0
- updated equations- integration of biomass yield index (BYI) and planted indicator
- planted indicator is derived from FVS_Standinit.StdOrgCd (Stand Origin Code; also used by the FIAVBC keyword)
  Sourced from FVS `StdOrgCd` (Stand Origin Code) Event Monitor variable (requires
  SQLIN query and Event Monitor Compute)
    # Natural stand = 0 - established through natural regeneration
    # Plantation = 1 - established through planting

### version 0.1.0
- initial version 
- designed to work with FVS-HI and customRun_fvsRunHi.R
- contains equations for koa

