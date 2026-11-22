# HiGy.R changelog 

### Version 0.5.2

#### Growth equations
- Parameters from the koa model of record, version 1.15.1 (November 22, 2026).
  BYI is recomputed: the FIA plots that trained the BYI forests now carry
  out-of-bag predictions, and 474 duplicate rows of the biomass frame were
  removed before refitting. Maximum SDI, height, height increment, diameter
  increment and mortality were refit with forms unchanged; crown base (E3e)
  and ingrowth are unchanged. 25 parameter values changed, nothing else.
  On the nine test stands eight match the reference script to 2.6e-05 m2/ha
  in basal area; all 310 first-measurement stands run 50 years.

### Version 0.5.1

#### Growth equations
- Parameters from the koa model of record, version 1.15.0 (November 21, 2026).
  BYI for the 53 Kapapala plots is predicted from their own climate and soils
  (statewide forest model) in place of one fill value. Maximum SDI, height,
  height increment, diameter increment and mortality were refit with forms
  unchanged; crown base (E3e) and ingrowth are unchanged.

#### customRun_fvsRunHi.R
- The Event Monitor has not computed BYI at stop point 1, so a stand with a
  tree lacking a measured height halted with "BYI missing or zero".
  `read_stand_site()` now reads BYI and STDORGCD from `FVS_StandInit` in the
  input database when the Event Monitor value is missing.


### Version 0.5.0

#### Fixes
- `Hi.GY()` called `AcadianGYOneStand()`; now calls `HiGYOneStand()`.
- Crown recession: the t+1 BAL was computed but not assigned, basal area
  was not updated, and the crown ratio used the start-of-year `hcb`
  instead of the predicted `phcb`.
- Crown recession: `(pcr-cr)/cr<-0.01` parsed as an assignment, and the
  1% limits were reversed (crown ratio fell 1% a year when the predicted
  crown ratio was higher).
- `make_fvs_tree()`: diameter growth returned to FVS inside bark (bark
  ratio 0.9); FVS adds `DG/BRATIO` to DBH.
- `make_stand()` accepts a missing BYI, which the Event Monitor has not
  computed at the imputation stop point; `Hi.GY()` stops if BYI is missing
  or zero, and `calc_ht()` stops only if a height must be imputed.

#### Growth equations
Equations and parameters from the koa model of record, version 1.14.1
(https://doi.org/10.5281/zenodo.24259455).
- Maximum SDI (25.4 cm index diameter) predicted from BYI and origin
  (`sdimax.parm`, `pred_sdimax()`); `calc_plot_summary()` adds `sdimax`
  and relative density `rd`. SDI now uses the 25.4 cm index diameter.
- Competition in crown base, diameter increment and height increment is
  `bal / ba * rd`.
- Height: asymptote `exp(a0 + a1 ln(BYI))`, shared with height increment.
  The base (no BYI) model is removed.
- Height to crown base: `ht / (1 + exp(b0 + b1 ln(ht/dbh) + b2 sqrt(bal ba + 1) + b3 ln(ba + 1)))`
  with koa-only `bal` and `ba` (koa 1.14.3, E3e, https://doi.org/10.5281/zenodo.24418330). The crown record
  behind 1.14.2 held crown length (ht x cr) rather than crown base, which is why its competition terms took
  the wrong sign; E3e is fitted to ht x (1 - cr). `calc_hcb()` joins `ba.plot` from the plot summary.
  Checked 2026-11-21: `pred_hcb()` matches koa_step_rdbyi.R 1.14.3 exactly, and customRun_fvsRunHi.R runs the
  nine Hawaii test stands for 50 years (single and triple keys) with diameter and stems matching the reference
  in eight stands; PSP_202_2 differs through the 14 trees below breast height under the `ht < 1.3716` rule.
- Diameter increment: refit; crown ratio, Duan factor, origin
  calibration factors and the 0-4 cm cap removed.
- Height increment: asymptote form; Duan factor, origin calibration
  factors and the 0-2 m cap removed. Zero for trees above the asymptote.
- BAL: trees with equal DBH share the same BAL.

#### Mortality
- The three-stage plot model (Stage 1 probability, Garcia self-thinning,
  Stage 3 allocation and 95% cap, origin factor 2.65) is replaced by one
  tree-level annual equation: complementary log-log of ln(DBH + 1), DBH,
  DBH^2, BAL, ln(RD), ln(BYI) and origin (`mort.parm`, `pred_mort()`).

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

