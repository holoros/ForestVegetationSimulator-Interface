# Koa mortality in FVS-HI, changelog

**Files.** [`fvsOL/inst/extdata/HiGy.R`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/blob/FvsHiHistory/fvsOL/inst/extdata/HiGy.R)
and [`fvsOL/inst/extdata/customRun_fvsRunHi.R`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/blob/FvsHiHistory/fvsOL/inst/extdata/customRun_fvsRunHi.R),
on branch [`FvsHiHistory`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/tree/FvsHiHistory)
of MidgardNaturalResources/ForestVegetationSimulator-Interface. Base blobs
`734bdc916009e2dab1e95818071b42d4736d712f` (40,658 bytes) and
`0c705443eced07570f15099ad8033c254892c66f` (10,048 bytes).

**For.** Ben Rice, Midgard Natural Resources.
**From.** Aaron Weiskittel, University of Maine.
**Date.** September 8, 2026, corrected September 9, 2026, HiGy.R ported September 9, 2026,
ported again onto the M1 engine of record September 11, 2026.
**Status.** REVIEW. Nothing here has been pushed to any branch, nothing has been posted to
[pull request 31](https://github.com/USDAForestService/ForestVegetationSimulator-Interface/pull/31),
and nothing has been deposited. `customRun_fvsRunHi.R` is unchanged and is still the September 8
file, byte for byte (see the 0.4.0 entry below for why no edit was needed there, which still
holds after the 0.5.0 port for the same reason). `HiGy.R` is now the ported 0.5.0 file, delivered
in `ben-package-2026-09-11`; the 0.4.0 file stays in `ben-package-2026-09-08` and the September 8
file is kept there as `HiGy_PREV_20260909a.R`. The self-test is now
`koa_mortality_selftest_2026-09-11.R`; the September 8 and September 9 self-tests and their
outputs are kept unchanged alongside it.

**Project material.** Zenodo concept DOI
[10.5281/zenodo.21081014](https://doi.org/10.5281/zenodo.21081014), which resolves to the
latest published version of the koa deposit and carries the fitting script, the memo of
record and the plot-interval table every number below rests on. The deposit version the
correction below refers to is 1.7.0, certified on 22 of 22 gates.

---

## 0.5.0, September 11, 2026. Stage 1 deployed as a gate, and Stage 3 moved onto the fitted survivor equation

The manuscript's mortality engine of record moved again on September 12, 2026 under
`MORTALITY_RULE_2026-09-12.md`, a rule pre-registered before any candidate engine was built and
amended once, in writing and with both readings kept, after the candidates were scored. Five
candidates were scored on six gates and **M1 was selected**. `ben-package-2026-09-11/HiGy.R` now
implements M1. Two things move and nothing else does.

**First, Stage 1 is live as a gate on the production stand rate.** The deployed annual rate is

    m_deployed = clip( m_garcia / p_bar * p(SDI, origin), 0, 0.95 )
    p(SDI, origin) = 1 - exp(-exp(eta)),  eta clipped to [-30, 5]
    eta = -1.8660048476490962 + 0.18970168229495396 ln(max(SDI, 1))
          + 0.1833723331227772 * planted + ln(YIP)

with `p_bar = 0.3600578102962374` the mean fitted annual occurrence over the fitting record.
Dividing the incumbent rate by `p_bar` makes it conditional on occurrence, which is the footing
Chen's Stage 2 is fitted on; multiplying by the fitted occurrence then gates it. **By construction
the mean deployed rate over the fitting record is unchanged**, so nothing published moves except
through the gate, and the only thing that moves is the density response, which now enters through
occurrence rather than through magnitude. The new constants are `KOA_S1_INTERCEPT`, `KOA_S1_LNSDI`,
`KOA_S1_PLANTED`, `KOA_S1_PBAR`, `KOA_S1_SDI_FLOOR`, `KOA_S1_ETA_CLIP` and `KOA_RATE_CAP`,
transcribed at full fitted precision from the fit's own `out_stage1/stage1_fit.json`; the new
functions are `koa_stage1_p()` and `koa_gate_rate()`, ported line for line from the deployed
`threestage.py` (`stage1_p`, `rate_M1`). The gate is applied inside `koa_step_deaths()`, which is
the only path `calc_mortality()` reaches the García step through, and it is applied **after** the
A1 floor because that is where the deployed engine applies it.

That is the finding the rule rests on, and it is a finding about koa rather than an inheritance
from the Chen paper. On 326 consecutive plot intervals over 54 plots, **koa mortality is density
dependent in how often it happens and density independent in how much happens when it does.** The
ln(SDI) coefficient on occurrence is +0.1897 with a plot-clustered 95% interval of
[+0.0473, +0.3411], excluding zero, at AUC 0.667; the ln(SDI) coefficient on the conditional annual
rate is −0.0610 with an interval of [−0.2610, +0.1274], including zero. By SDI tertile, occurrence
runs 0.385, 0.454 and 0.550 while the conditional rate runs 0.180, 0.179 and 0.151. Adding ln(QMD)
to the conditional magnitude leaves R² at 0.028 with nothing significant and a coefficient that is
biologically backwards. That decomposition is why every single-stage density-dependent arm tested
on this project has failed: a single-stage rate averages a density-dependent occurrence against a
density-independent magnitude and dilutes the response to nothing.

Chen et al. (2023) threshold `p` into a binary indicator, which exists to produce exact zeros in a
plot-level prediction. **The threshold is not deployed**, `p` enters continuously, and the deviation
is disclosed in the manuscript. A projected mean stand over a century is not a single plot
realization, and a hard threshold would put a discontinuity into a deterministic trajectory that
nothing in the koa record supports. The stochastic irregular-event arm already in the file
(`koa_irregular_event()`) is a different device again and stays off and out of scope; after this
entry the file carries two things called Stage 1 and they are not the same thing.

**Second, Stage 3 orders deaths by the fitted tree-level survivor equation rather than by relative
size.** `koa_alloc_frac()` gains `mode`, defaulting to `KOA_ALLOC_MODE = "tree_eq"`, where the
weight is `w = clip(1 - koa_surv_annual(dbh, ht, cr, rht, byi), 1e-9, 1)`. The new function
`koa_surv_annual()` and its vector `KOA_S3_SURV = (14.102, 0.130, −4.516, 6.684, 14.218, −2.806,
2.649, −21.188)` are transcribed from the deposit's `figshare_v66/koa_equations.py`
`LineageA.SURV` and `LineageA.surv_annual()`, which is manuscript Table 6 on the ALIVE response.
The as-published size weight `exp(−3 (DBH/QMD − 1))` is retained and reachable at
`mode = 'rel_size'`. Everything after the weight is unchanged, including
`koa_renormalize_to_stand_rate()`, which remains the single carrier of the R1 algebra.

**The level of that equation still does not act, and that is the point.** Per-tree rates are
`m_stand * w_i / wbar` and are then renormalized, so any constant multiplying the weight cancels
between `w_i` and `wbar`. Deaths are ordered by the equation, not sized by it. This is the same
reason Chen uses his Stage 3 as a ranking, and it is why deploying an equation with known level
problems here is safe. The September 11 self-test asserts it directly: scaling the weight by 0.1,
0.5, 2 or 37 changes no allocated fraction to 1e-12. It follows that **`koa_surv_annual()` does not
resolve the two divergences flagged above `surv.parm`** in the 0.3.0 file, namely the coefficient
vector and the sense of the return. `surv.parm` and `surv_prob()` are untouched, still carry the
development-snapshot vector and the `exp(-exp(eta))` sense, and `mort.engine = 'cloglog'` still
reproduces every pre-0.3.0 projection. Those divergences remain open and remain for Aaron and Ben
to settle. They do not need to be settled for this port, because a renormalized ordering weight is
insensitive to the level the two lineages disagree about.

**What is unchanged.** The García (2009) recursion, the anchored beta 0.16019053617304435, the
`H_QMD` allometry and the A1 background floor all stand exactly as the 0.4.0 entry left them. This
port adds a multiplier in front of the rate and changes a weight behind it. `koa_mortality_step()`
and `koa_allocate_mortality()`, the standalone wrappers documented as not on the production path,
keep the September 9 behaviour by explicit default (ungated, unfloored, fitted beta, relative-size
weight) and reach the deployed behaviour by argument, exactly as `koa_mortality_step()` already
pinned its own beta and floor. `customRun_fvsRunHi.R` again needed no edit, for the same reason it
needed none in 0.4.0.

**One consequence worth stating plainly.** Because the gate is applied after the floor, the A1
floor is scaled like any other rate. A flat stand no longer returns exactly 0.003 or 0.006 yr⁻¹ but
that value times `p / p_bar`. The gate is neutral at SDI 266.30 natural, scales the rate down below
that and up above it; the natural floor of 0.003 yr⁻¹ becomes 0.0023119841 at SDI 50 and
0.0039220972 at SDI 1725. This is the deployed behaviour and not an oversight, and the self-test
asserts the direction in both cases so it cannot be changed by accident.

**What M1 does not do.** It does not move the mortality level. Under the rule's own gates M1 fails
H1 at 0.0075 to 0.0106 yr⁻¹ against an observed 0.0962, and fails H2. It was selected because it is
the only candidate that both clears the density envelope (H3, which AMENDMENT 1 makes a veto) and
improves on the incumbent, because it deploys Stage 1 so the occurrence probability is live and
gating the rate, because it changes no fitted coefficient, and because it preserves the deployed
expectation. Its Bakuzis outcome of 4 of 6 is the best any engine has returned on this project.
M2, the Chen-faithful candidate, is the only one to reach the observed level and it breaks the
size-density relation outright, taking the Reineke slope to between −4.67 and −6.52 and putting
five reported diameters past anything ever measured in a koa stand. **The level cannot be repaired
on its own**: the projection underpredicts mortality by a factor of four to twenty and
underpredicts diameter increment by about 20 percent, and raising one without the other produces a
stand that thins far faster than it grows. That is the honest statement of the open defect and it
is a larger piece of work than either side of it alone.

Cross-validated against the deployed Python source (`threestage.py`, `koa_mortality_garcia.py`,
`koa_equations.py`, `koa_params.py`, `koa_survival_calibrated_py.py`, imported unmodified) on
firebreather, with both sides reading one shared case file so they cannot drift on what they were
asked. Eighteen cases span the gate scaling down, neutral and up, both origins, both Stage 3
weights, the A1 floor reached and gated, the per-tree cap solve, the 0.95 clip, the ungated
pass-through on a missing SDI, and the gate switched off. All eighteen match to 12 decimal places on
the stand rate and 6 on per-tree deaths; across the 126 per-tree rows the largest difference is
9.095e-13 trees ha⁻¹. The self-test (`koa_mortality_selftest_2026-09-11.R`) passes 144 of 144
checks, including two new sections that exercise the gate at low, middle and high density at both
origins and the two Stage 3 weights on one tree list. Full account, the parity table and what this
validation does and does not cover: `HiGy_v050_parity_report_2026-09-11.md`.

---

## 0.4.0, September 9, 2026. HiGy.R ported onto the deployed arm

`ben-package-2026-09-08/HiGy.R` now implements `garcia_qmd_anchored`, the arm this changelog's
September 9 correction (below) describes as the deposit's actual deployed arm of record, in place
of the fitted H40 arm the September 4 memo specified. The bounded edit named in that correction as
what moving `HiGy.R` onto the deployed arm would take is exactly what changed: the beta constant
(now `KOA_GARCIA_BETA_ANCHORED = 0.16019053617304435`, ported from the deposit's
`koa_params.GARCIA_BETA_ANCHORED`), the height variable driving the Garcia (2009) step (now
`H_QMD` via the new `koa_h_qmd()`, ported from `koa_mortality_garcia.h_from_qmd()`, in place of
`koa_h40()`), and the A1 background floor (now applied, 0.003 yr⁻¹ natural and 0.006 yr⁻¹
planted, ported from `koa_params.BASE_NAT`/`BASE_PLT` via `koa_mortality_garcia.mort_garcia()`
and `background_mortality()`). Stage 1 and Stage 3 are unchanged. `koa_mortality_step()`, the
standalone wrapper documented as not on the production path, keeps the fitted H40, unfloored arm
by explicit default, so both arms stay separately reproducible from the same file; the production
path (`calc_mortality()` with `mort.engine = 'garcia'`, the only path `customRun_fvsRunHi.R`
drives) now runs the deployed arm, which needed no change to `customRun_fvsRunHi.R` itself since
that file only ever passed the string label `'garcia'` through and never referenced any
`HiGy.R` constant or function by name.

Cross-validated against the deposit's actual Python source (`figshare_v66/koa_mortality_garcia.py`
and `koa_params.py`, staged unmodified) on firebreather: seven test cases spanning growth, flat
height, both stand origins, and a falling-QMD case match to every printed digit between the R port
and the Python deposit (12 decimal places on the step mortality fraction). The self-test
(`koa_mortality_selftest_2026-09-09.R`) passes in full, including new checks that the ported arm's
floor binds correctly on a flat stand and that production output now differs from what the
pre-port fitted-H40 arm would have returned on the same worked example. Full account, the parity
table, and what this validation does and does not cover: `HiGy_v040_parity_report_2026-09-09.md`.

---

## Correction, September 9, 2026. The 86 percent overprediction is a frame mismatch, not a property of the anchored beta

The September 8 version of this changelog, in three places, read the self-test's beta
sensitivity block as a comparison between the two candidate arms and concluded that the
anchored beta 0.16019053617304435 overpredicts regular deaths by 86 percent. That reading is
withdrawn. The two betas are calibrated on different height variables, and the self-test
compares them on only one of those variables.

The fitted 0.117 m⁻¹ is a weighted nonlinear least squares estimate with top height H40 as the
state variable of the García step. The anchored 0.16019053617304435 is a different kind of
constant on a different height. It is 100/√z99, with z99 the 99th percentile of N·H_QMD² over
the 471 live plot-measures of the koa tree record, where H_QMD is the allometric height
equivalent of quadratic mean diameter, H_QMD = exp((ln QMD − a)/k_HD) with a = −0.168630705121571
and k_HD = 1.1719473700506686, fitted by ordinary least squares on the same 360 regular
intervals. The self-test's beta sensitivity block calls `koa_regular_survival()` on the
observed H40 pairs with `beta = 0.16019053617304435`, so it substitutes the anchored constant
into the H40 parameterization. That is what produces 25,295 deaths against 13,138 and the ratio
of 1.925, and it measures what happens when a constant calibrated on one height variable is
run on another. It does not measure the anchored arm.

On the H_QMD frame the deposit actually deploys, under `mort_engine = "garcia_qmd_anchored"`,
the anchored arm predicts total deaths on the 360 regular intervals 35.1 percent above observed
with a root mean squared error of 96.1 trees ha⁻¹ on end-of-interval density, the lowest of any
candidate, and its tree-year-weighted annual bias is −0.0031 yr⁻¹, the least biased of every
arm, against −0.0214 yr⁻¹ for the fitted 0.117 run on the same frame. Refitting beta alone on
H_QMD by the same objective gives 0.1717, with a plot-cluster bootstrap standard error of 0.0229
over 103 clusters at B = 2,000, and the deposit's joint refit gives 0.16701. The anchored value
therefore sits 6.7 percent below the maximum-fit value in its own frame, at the 27.8th
percentile of that bootstrap, while 0.117 sits at the 3.15th percentile and is the outsider on
that frame. The bootstrap interval 0.057 to 0.159 that the anchored value was said to just
miss is an H40-frame interval and does not bound an H_QMD-frame parameter. The same comparison
appears in the comment on `GARCIA_BETA_ANCHORED` in the deposit's `koa_params.py`, which reads
the move from 0.117 to 0.1602 as just outside that interval, and it is superseded on the same
ground.

The refit to 0.1717 was built in full and rejected, since satisfying the extrapolation budget of
gate C8 under it required a natural diameter ceiling of 66.04 cm, below the observed maximum
quadratic mean diameter of 69.68 cm, and under that ceiling the uneven-aged path inverted site
ordering in diameter and volume. The deployed beta stays 0.16019053617304435. Deposit 1.7.0
adds a monotone height guard at the harness layer, a restatement of the gate C8 extrapolation
frame with its transport offset declared, and the disclosures that go with both, and it moves
no point estimate.

What this means for the package is stated plainly rather than left to inference. The `HiGy.R`
in `ben-package-2026-09-08` implements the fitted H40 arm at `KOA_GARCIA_BETA = 0.117` with
`koa_h40()` as the state variable and no floor, because that is what the September 4 memo
specified, and its header comment says so. The deployed arm of record is the García step on
H_QMD with alpha = gamma = 2.96, beta = 0.16019053617304435, the allometry above, the A1 floor
taking the stand rate as the larger of 1 − N₁/N₀ and 0.003 yr⁻¹ natural or 0.006 yr⁻¹ planted,
and Stage 3 relative-size allocation with the stand rate preserved. Moving `HiGy.R` onto that
arm is a bounded edit, namely the beta constant, the height variable driving the step, and the
floor, with everything in Stage 1 and Stage 3 unchanged. It is not made in this correction,
which changes no code, and it is listed under what is left to explore below. The forty-four
self-test checks and every validation number in the 0.3.0 entry describe the H40 file as
shipped and remain correct for it.

The three corrected passages are marked in place below, in the third finding under
misrepresentation, in the section on the single largest open question, and in what is left to
explore, and a fourteenth item is added to the directions explored. Nothing else in the
September 8 text is altered.

---

## 0.3.0, September 8, 2026. Three-stage García mortality replaces the tree-level survivor equation

### What the branch version history actually records, and what it does not

Six commits on `FvsHiHistory` carry the koa model, all of them made on September 5, 2026 as a
reconstruction of an earlier development sequence, and each of them touches exactly one file,
namely
[`fvsOL/inst/extdata/WeiskittelKoaGy.R`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/blob/FvsHiHistory/fvsOL/inst/extdata/WeiskittelKoaGy.R).
They are, in order,
[`5453a2a`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/5453a2a990)
"Koa model development, Initial koa model 2025-09-23", which adds the file at 175 lines in
customary units,
[`7700053`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/7700053224)
"Version 2026-02-23",
[`1e9f6f2`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/1e9f6f27e8)
"Version 2026-03-10",
[`1b6de46`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/1b6de468d9)
"Version 2026-03-24",
[`66db4b2`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/66db4b2e83)
"Version 2026-03-27", and
[`8e04788`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/8e047883bc)
"Version 2026-04-27", which is the branch tip for that file.

Neither production file appears in any of the six. The
[history of `HiGy.R` on this branch](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commits/FvsHiHistory/fvsOL/inst/extdata/HiGy.R)
holds two entries only, namely
[`254f4ff`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/254f4ffc23)
"Midgard pr26 (#109)" of June 5, 2026 and
[`afa0428`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/afa0428efa)
"Acd v12 3 5 (#100)" of February 23, 2026, and
[`customRun_fvsRunHi.R`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commits/FvsHiHistory/fvsOL/inst/extdata/customRun_fvsRunHi.R)
carries the same two plus one earlier. So the version history Ben means is the history of the
standalone prediction script and not of the FVS drop-in, the drop-in has not moved since
June 5, 2026, and every koa modelling decision taken since then lives outside this repository.
That is the single most useful thing the history establishes, since it means the two files are
a clean base rather than a base carrying half-applied corrections.

### Does anything we sent Ben misrepresent the current state of the code

Yes, in five places, and four of the five are consequences of an earlier pass having compared
against the Zenodo deposit's copy of `HiGy.R` rather than against the repository's. The two
files are not the same file and have not been since August 12, 2026.

First and largest, the deposit's copy of `HiGy.R` states that `surv_prob()` was corrected on
August 12, 2026 from `exp(-exp(eta))` to `1 - exp(-exp(eta))`, and that `surv.parm` was
corrected on August 15, 2026 from the pre-deduplication development vector to manuscript
Table 6. Both changes are described in that file as fixes of record and as changes to what
FVS-HI actually predicts. Neither is present in the repository's file, at
`HiGy.R` lines 554 to 557 and 602 for the deposit against the corresponding lines 458 to 461
and 470 of the repository blob, so anything we sent implying that FVS-HI runs the corrected
mortality equation is wrong. FVS-HI runs the uncorrected one.

Second, the two corrections are coupled and neither may be applied alone, which nothing we
sent says. `WeiskittelKoaGy.R` on this same branch, at its 2026-04-27 tip
([`8e04788`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/8e047883bc)),
states the opposite convention explicitly, namely that the fit is a complementary log-log on
the death response with P(alive) equal to exp(-exp(eta) YIP), and it pairs that form with the
same development coefficient vector the repository's `HiGy.R` carries. The two lineages are
each internally consistent and they contradict one another. There is also a units question
under both, since `WeiskittelKoaGy.R` forms the slenderness term as the height to diameter
ratio in m m⁻¹ while `HiGy.R` forms it with diameter in cm, a difference of ln 100 inside the
linear predictor and therefore of 4.605 b₅ in eta.

An indicative calculation on the eight-tree two-plot list of the self-test, at biomass yield
index 264 Mg ha⁻¹, puts numbers on the coupling. The repository's current pairing returns
0.139 yr⁻¹, the deposit's pairing returns 0.916 yr⁻¹, the development vector with the
deposit's sign returns 0.861 yr⁻¹, and Table 6 with the repository's sign returns
0.084 yr⁻¹, against a pooled regular rate of 0.030 yr⁻¹ in the koa record. Only the last of
the four is within reach of the observed record and it is the pairing neither file carries.
This is one stand and it is not a proof, yet it is enough to say that pushing the deposit's
two changes into FVS-HI as sent would have removed roughly nine tenths of a stand per year.
That is why neither change is applied in this revision.

Third, the September 4, 2026 memo names the H40 arm as the component and the deposit moved off
that arm the following day. On September 5, 2026 the deposit's deployed engine became the
variant that runs the same García step on the allometric height equivalent of quadratic mean
diameter with beta anchored at 0.16019053617304435 rather than the fitted 0.117, and nothing
sent to Ben carries that. The two arms are not interchangeable and the memo as sent points at
the arm the deposit no longer uses. Corrected September 9, 2026. The September 8 text supported
that sentence with the self-test figures of 13,138 deaths under the fitted beta against 25,295
under the anchored beta on the 360 regular intervals, a ratio of 1.925 against 13,595 observed.
Those figures are real but they are both computed on H40, so the second is the anchored
constant run in the wrong frame and not the anchored arm. On its own H_QMD frame the anchored
arm is 35.1 percent high on total deaths with the lowest density error of any candidate, as the
correction entry above sets out, and that is the comparison the two arms should be judged on.

Fourth, the deposit floors its stand rate as the larger of 1 minus N₁/N₀ and an origin
background of 0.003 yr⁻¹ natural or 0.006 yr⁻¹ planted, and neither the September 4 memo nor
its reference implementation `koa_mortality_3stage_fvs.R` carries that floor. An unfloored
García step returns zero regular mortality on a stand whose top height is flat where the
deposit returns the background, which is a real difference in deployed behaviour rather than a
documentation gap.

Fifth, the README of the September 4 package lists `PROPOSED_PR31_COMMENT.md` in its file
manifest and that file is not in the package directory, so if the package was sent as
assembled then its manifest points at something Ben does not have.

Two claims in the September 8 draft changelog are also withdrawn here. It stated that the
August 12 and August 15 fixes were still the fixes of record in this file, which is false for
the repository file, and it stated that `customRun_fvsRunHi.R` does not exist anywhere, which
was true of the Koa project tree and false of the repository.

### What changes in `HiGy.R`

Mortality moves to the three-stage structure of Chen et al. (2023), namely occurrence of an
irregular event, regular stand-level survival, and allocation of the stand deaths to trees.
The version tag becomes `HiGyV0.3.0` and a 0.3.0 entry is added to the file's own update
summary.

Stage 2, the regular stage, is the whole-stand model of García (2009) with mean spacing
S = 100/√N and top height H40 as the state variable, run at α = γ = 2.96 and β = 0.117 m⁻¹
with the ratio γ/α fixed at 1. It is deterministic and it is the default. That is the fitted
H40 arm of the September 4 memo, and it is the arm this file carries as shipped. The deployed
arm of record, the same step on H_QMD at the anchored beta with the A1 floor, is set out in the
correction entry above and is not yet in this file. The step is
S₁^α = S₀^α − (β H40₀)^α + (β H40₁)^α with N₁ = 10,000/S₁², which is exact for any cycle
length because the state variable is height rather than time, so no annualization appears
anywhere in the component. A flat or falling top height returns exactly zero regular mortality
and a stand approaches the limiting line S = β H40 from below without crossing it. Stage 3
spreads the plot's deaths across that plot's trees on the as-published size weight
exp(−3(DBH/QMD − 1)), with per-tree fractions m_stand·w/w̄, the 0.95 per-tree cap, and the
renormalizer carried over line for line so that the expansion-factor-weighted allocated
mortality equals the stand rate and the summed `dexpf` equals the stand deaths. Stage 1 is
stochastic and is off by default, drawing occurrence at 0.14 per plot interval annualized
against the 2.68 yr mean interval and magnitude from the 60 observed cohort-loss fractions.

The new functions are `koa_planted()`, `koa_sdi()`, `koa_h40()`, `koa_regular_survival()`,
`koa_renormalize_to_stand_rate()`, `koa_alloc_frac()`, `koa_allocate_mortality()`,
`koa_irregular_event()`, `koa_mortality_step()` and `koa_step_deaths()`, all placed in the
Mortality section ahead of `surv.parm`, and `calc_mortality()` is rewritten around them with a
new `mort.engine` argument. Stand density index is computed on the Reineke exponent 1.605 and
is reported rather than used, since the García step is driven by top height, and the inert
1.6 comment in `HiGYOneStand()` now carries a note saying so. `make_ops()` gains `mort.engine`,
`irregular`, `mort.seed` and `planted.background`, and `HiGYOneStand()` reads all four
defensively so that an older options frame still runs the default engine rather than failing on
a missing column. `planted_background` is exposed as a TODO parameter on
`koa_regular_survival()` and on `calc_mortality()`, default NA and off.

Everything the component needs is a literal in the file. No coefficient, lookup table or
empirical distribution is read from disk, nothing is sourced, and the self-test checks that by
scanning the executable lines for external-input call sites and finding none.

`surv_prob()` and `surv.parm` are retained unchanged and are no longer the production mortality
path. `calc_mortality(mort.engine = "cloglog")` runs the version 0.2.0 body and reaches them,
and the block above `surv.parm` states the two unresolved divergences in full so that no reader
takes a number from that branch without seeing them.

### What changes in `customRun_fvsRunHi.R`

Three things move and nothing else does. The `make_ops()` call passes the new mortality options
through from `runOps`, each guarded with `is.null()` so that a saved run carrying only the two
size-cap choices still reaches the default engine. `uiHi()` gains two radio groups, one
choosing the mortality equation between `garcia` and `cloglog` and one switching the stochastic
irregular stage, with the seed read from `runOps$uiHiMortSeed` when the interface supplies it.
The log now records which engine ran, whether the irregular stage was on, and the seed, and it
warns in the log when a run has been made stochastic. The seed is set once per stand cycle
rather than once per year, so a multi-year cycle draws a distinct event in each of its years
while the whole cycle stays reproducible. The FVS control flow, the stop points, the dubbing
block and the tree list round trip are untouched.

### Reasoning

On the survivor cohort, meaning trees live at the first measurement and followed to the second
with ingrowth excluded, the *Acacia koa* A. Gray network yields 421 consecutive plot intervals
on 112 plots carrying 1,383 cohort deaths. Sixty of those intervals, 14 percent, exceed
0.10 yr⁻¹ and carry 913 of the deaths, 66 percent, as a mixture of thinning removals, one FIA
die-off and older plantation losses of unrecorded cause. The withdrawn density ramp of the
August 28, 2026 package was calibrated on tree-year records that pool those irregular intervals
with the regular ones, which is why it doubles regular mortality. On the 360 regular intervals,
103 plots, 469 deaths and 15,562 tree-years at a pooled 3.0 percent yr⁻¹, the ramp overpredicts
regular deaths by 101 percent under leave-one-installation-out, with an annual bias of
+0.024 yr⁻¹ whose plot-cluster bootstrap interval of +0.012 to +0.038 at B = 2,000 excludes
zero by a wide margin, and it is worst above stand density index 500, which is where a long
projection spends its time.

The García form was chosen on behaviour as much as on fit, and that distinction is worth
keeping in front of a reviewer. Its leave-one-installation-out annual bias is −0.011 yr⁻¹ with
an interval of −0.016 to −0.001, it carries the lowest cross-validated root mean squared error
on stand density of any self-thinning-consistent candidate, it bounds 99.4 percent of the
observed (N, H40) pairs beneath its limiting line, and it implies a Reineke slope of −1.71,
the first estimate for the species and inside the −1.2 to −2.2 band. Set against that, the
density signal in the regular record is weak enough that a constant 3.1 percent yr⁻¹ is nearly
as accurate as any fitted form, so the case rests on bounded self-thinning, path invariance and
the absence of any annualization more than on a fit statistic. The death count also depends on
the sentinel reading, in which a dead status with zero diameter counts as a death unless the
tree is later recorded live. Under the alternative reading the regular set holds 21 deaths and
nothing is estimable, so the sentinel reading is the stated basis and whether the older
plantation sentinel losses are deaths or unrecorded thinning is a question for the data
custodians rather than for the model.

There is no lag in this file and that is worth stating, since the reference Python projector
carries one. `HiGYOneStand()` calls `calc_ddbh()` and `calc_dht()` before `calc_mortality()`,
so the end-of-cycle top height is available at the moment the step is taken and is computed
from the same trees carrying this cycle's increments. The Python computes its height increment
after mortality and therefore drives the García step on the previous year's realized height
change, a one-year lag it documents and lives with. Reproducing that lag here would be
reproducing a limitation rather than a model.

### Directions explored since the previous production version, and the disposition of each

1. **Stand density ramp on absolute stand density index, Eq. 5b, onset 200 and full lift 850,
   maximum lift 0.15 yr⁻¹ over backgrounds of 0.003 and 0.006 yr⁻¹.** DROPPED. It was the
   instruction of record in the August 28, 2026 package and it was withdrawn on
   September 4, 2026 for the leave-one-installation-out bias above. It was never in `HiGy.R`,
   so the withdrawal costs this file nothing and the self-test now asserts its absence.
2. **The Table 6 complementary log-log as the Stage 3 ordering weight.** DROPPED. Within plot,
   relative diameter alone orders deaths at a concordance of 0.73 in regular intervals and 0.78
   in irregular ones, with relative height and basal area in larger trees no better, so the
   cloglog buys no ordering and costs four covariates.
3. **Free γ/α in the García form.** DROPPED. The ratio is not identified on this record, the
   free-fit bootstrap interval running 0.33 to 11.6, so it is fixed at 1, which is García's own
   remedy for sparse data.
4. **A constant annual rate, 3.1 percent yr⁻¹ pooled on the regular set.** CONSIDERED AND NOT
   ADOPTED, yet kept in the reasoning above rather than buried, since it is nearly as accurate
   as any fitted form and a reviewer is entitled to know that the fit is not what carries the
   argument.
5. **An origin term inside the fitted form.** NOT FITTED. The fit predicts 0.4 percent yr⁻¹ for
   planted stands against 2.2 percent observed over 41 intervals, because planted H40 growth is
   small in those intervals. `planted_background` is exposed as a TODO parameter, default NA
   and off, and it is deliberately not surfaced in the run interface, since an interface field
   would invite a number to be invented for it.
6. **Stage 1 on by default.** DROPPED. Occurrence is only weakly predictable, a logistic on ln
   stand density index, origin and ln interval reaching an area under the curve of 0.61, so a
   deterministic run has no business drawing it. It is available behind the interface switch
   and a run that uses it must record the seed.
7. **Deleting `surv_prob()` and `surv.parm` once projection stopped calling them.** DROPPED, on
   three grounds, since Table 6 is the published equation, the deposit's reproducibility gate
   reads those eight coefficients out of a file of this name, and a reviewer must be able to
   recover any projection this file made before version 0.3.0.
8. **Applying the deposit's August 12 and August 15 corrections to `surv_prob()` and
   `surv.parm` while implementing mortality.** DROPPED, and this is the largest change of
   disposition against the previous pass. The two are coupled, the branch's own
   `WeiskittelKoaGy.R` asserts the opposite response convention, a units question sits under
   both, and the indicative calculation above shows the deposit's pairing removing 0.916 yr⁻¹
   from a healthy stand. Folding any of that into a mortality edit would have made it
   unreviewable. It is raised rather than decided.
9. **Carrying the deposit's one-year H40 lag into this file for consistency with the Python
   projector.** DROPPED, for the reason given at the end of the reasoning above.
10. **Repairing the three defects found in the base files while working in them.** DROPPED and
    flagged in place instead. `Hi.GY()` calls `AcadianGYOneStand()`, which is defined nowhere in
    the file, so that function errors if it is ever reached, and nothing reaches it today since
    `customRun_fvsRunHi.R` calls `HiGYOneStand()` directly. The dubbing block of
    `customRun_fvsRunHi.R` multiplies the whole height column by 3.28084 before `calc_hcb()`
    runs, while `pred_hcb()` was fitted in metres, and the `cratio` assignment in the same block
    returns a proportion on the untouched rows and a percentage on the imputed ones. Each is a
    separate correction with its own control and none is part of the mortality change.
11. **The September 8, 2026 basal area in larger trees correction.** NOT APPLIED. `calc_bal()`
    still forms the quantity as `cumsum(ba) - ba`, which is the construction the deposit retired
    that day in favour of a single carrier. The correction moved 21 of 24 even-aged quadratic
    mean diameters in the deposit's own projection table by a mean of 5.0586 cm. It reaches
    mortality, since the three-stage component takes its projected top height from the diameter
    and height increments and both read `bal`, yet it belongs in its own edit.
12. **The diameter increment correction factor and the planted term guard.** NOT APPLIED. The
    deposit carries cf = 1.369 rather than 1.026 and `pmin(dbh, 45.0)` rather than
    `pmin(dbh, 40)`. Both are flagged in place above `ddbh()` and both move mortality through
    the projected top height, so both should be settled before release.
13. **Short-circuiting the García step on a flat top height.** ADOPTED, and it is the one change
    of substance made after the first validation run. Evaluating the general expression when
    H40₁ equals H40₀ subtracts and re-adds the same (β H)^α term, loses low bits, and returns
    deaths of order 10⁻¹³ trees ha⁻¹ rather than zero. The residue is physically nothing yet it
    accumulates over a long projection and it makes a stated property of the component
    untestable, so the flat case now returns exactly zero. No growing stand is affected.
14. **Refitting beta on the H_QMD frame in place of the envelope anchor.** Added
    September 9, 2026. BUILT AND REJECTED on the deposit side. The refit gives 0.1717 with a
    plot-cluster bootstrap standard error of 0.0229 over 103 clusters at B = 2,000, and the
    joint refit gives 0.16701, so the anchored 0.16019053617304435 sits 6.7 percent below the
    maximum-fit value on its own frame. It was rejected because satisfying the gate C8
    extrapolation budget under it required a natural diameter ceiling of 66.04 cm, below the
    observed maximum quadratic mean diameter of 69.68 cm, and the harness would then have
    forbidden the natural arm from reaching a stand size koa has been measured at. The
    anchored constant stays and this file, when ported, takes it and not the refit.

### The single largest open question, for Aaron. Resolved September 9, 2026

As written on September 8 this section read as follows, and it is kept so the record of what
was claimed stays legible. The deployed beta was said to be unsettled, with the two candidates
giving materially different mortality. The memo of record specifies the fitted β = 0.117 m⁻¹,
with a plot-cluster bootstrap interval of 0.057 to 0.159, and that is what this revision
implements because that is what was sent to Ben. The deposit moved on September 5, 2026 to
β = 0.16019053617304435 anchored on the observed density envelope, run on the allometric height
equivalent of quadratic mean diameter rather than on H40, on the ground that the fitted arm sat
at floor mortality on every stand of the projection table since no observed plot-measure lies
above the fitted line. The September 8 text then stated that, measured on the same 360 regular
intervals, the fitted beta predicts 13,138 deaths and the anchored beta predicts 25,295 against
13,595 observed, so that the fitted arm was 3.4 percent low and the anchored arm 86 percent high
on that set, and framed the choice as one between an arm that fits the interval record and an
arm that behaves on a long projection.

Corrected September 9, 2026. The 86 percent is withdrawn as a description of the anchored arm.
Both death counts in that sentence were computed with H40 as the state variable, and the
anchored beta is not an H40 parameter. It is calibrated on H_QMD, and on H_QMD it predicts
total deaths 35.1 percent above observed with a root mean squared error of 96.1 trees ha⁻¹ on
end-of-interval density, the lowest of any candidate, and a tree-year-weighted annual bias of
−0.0031 yr⁻¹, against −0.0214 yr⁻¹ for the fitted beta on the same frame. The interval 0.057 to
0.159 is likewise an H40-frame interval and bounds nothing on H_QMD, where the refit gives 0.1717
with a bootstrap standard error of 0.0229 and the anchored value sits at the 27.8th percentile.
So the choice was never between fit and behaviour. On its own frame the anchored arm is both
the better fit and the arm that passes the hard gates.

The decision has been taken. The deployed beta stays 0.16019053617304435 on the H_QMD frame,
the refit to 0.1717 was built and rejected because the extrapolation budget under it required a
natural diameter ceiling of 66.04 cm below the observed maximum quadratic mean diameter of
69.68 cm, and deposit 1.7.0 moves no point estimate. What remains for this file is the port,
meaning the beta constant, the height variable driving the step and the A1 floor, which is a
code edit with its own self-test and is listed under what is left to explore.

### Validation

Run on firebreather under R 4.5.1 on September 8, 2026 by
`koa_mortality_selftest_2026-09-08.R`, which sources the production `HiGy.R` and exercises the
functions that file defines, so it cannot pass against a copy of the component that has drifted
from what ships. Verbatim output is in `selftest_output_2026-09-08.txt`. Forty-four checks, all
passing, exit status 0. Both production files parse cleanly.

Cycle-length invariance holds far tighter than the 10⁻⁶ contract. One 10-year cycle from H40
10 m to 20 m starting at 1,500 trees ha⁻¹ returns 1068.8547160632 trees ha⁻¹, ten 1-year cycles
on the same height path return the same figure to 4.547 × 10⁻¹³, and one hundred sub-steps
agree to 4.547 × 10⁻¹². No regular mortality occurs when H40 is flat and none when H40 falls,
both now exactly. A stand started at 99.9 percent of the limiting line at H40 15 m finishes at
1508.8 trees ha⁻¹ against a line at 1509.3, so the line is approached from below and not
crossed. Carried through the allocator, one 10-year step and ten 1-year steps give the same
stand total of 95.6948983216 trees ha⁻¹ to 6.253 × 10⁻¹³, while the per-tree split differs,
which is expected and is stated in the test output rather than smoothed over, since Stage 3
re-reads the diameter distribution at every step.

The renormalization contract holds exactly. On the five-tree list at 30 deaths ha⁻¹ the summed
`dexpf` is 30.000000000000 and the expansion-factor-weighted mean per-tree mortality is
0.051282051282 against a target of 0.051282051282, with the mortality fraction decreasing
monotonically with diameter. AT-3 reproduces, four trees at the 0.95 cap and the fifth at
0.17000000000006 with the weighted mean restored to 0.93000000000000. AT-4 issues the
infeasibility warning naming the stand rate 0.97 and the cap 0.95 and returns every tree at
exactly 0.95. AT-6 returns 0.05000000000000000 on the single tree, which is the stand rate to
the last bit. AT-1, AT-2 and AT-5 describe the withdrawn ramp and its Eq. 5 ordering weight and
are retired, so the test asserts the ramp's absence instead and finds zero occurrences of any
onset, full-lift or maximum-lift constant in the executable lines of the production file.

The embedded magnitude distribution matches `plot_interval_pairs_DATA.csv` element for element,
60 values against 60 at a maximum absolute difference of 0, median 0.3176 and interquartile
range 0.1635 to 0.6949 on both sides. The source table reads 421 plot intervals on 112 plots
with 1,383 cohort deaths, of which 60 irregular intervals carry 913 deaths, 66.0 percent. The
observed occurrence rate is 0.1425 per plot interval at a mean interval of 2.6841 yr against
the embedded 0.14 and 2.68, and 20,000 draws of the annualized hazard at a step of 2.68 yr
return 0.1400. On the in-sample regular set of 360 intervals the component predicts 13,138
deaths against 13,595 observed, −3.4 percent, at a root mean squared error of 101.1
trees ha⁻¹ on end-of-interval density, and 99.44 percent of regular (N, H40) pairs lie beneath
the limiting line. The same section of the self-test prints a beta sensitivity block, reported
and not asserted, in which `koa_regular_survival()` is called on the same H40 pairs with
`beta = 0.16019053617304435` and returns 25,295 deaths, a ratio of 1.925 to the fitted
figure. Stated precisely, that block measures the effect of substituting the anchored constant
into the H40 parameterization of the shipped file. It is a useful guard against anyone making
that substitution by editing one constant, and that is all it is. It does not evaluate the
anchored arm, which runs on H_QMD, and the 86 percent that the September 8 text drew from it is
withdrawn in the correction entry at the top of this document. A self-test for the H_QMD arm
will need the allometry and the floor in the production file before it can be written.

End to end through `calc_mortality()` on two plots for one FVS year, plot 1 with height growth
from H40 23.875000 m to 24.045000 m takes 2.6136034469 trees ha⁻¹ of stand deaths and is
allocated 2.6136034469, plot 2 with no height growth takes none, and the returned frame carries
the input columns plus `dexpf` and nothing else. The FVS mortality multiplier scales allocated
mortality exactly, 0.5 returning half to twelve decimal places. A tree list arriving without
`ddbh` or `dht` raises the ordering warning and returns no mortality rather than an invented
number. `mort.engine = "cloglog"` reaches the retired path and returns a different answer, and
`make_ops()` accepts the interface strings, coerces them, and falls back to `garcia` on an
unrecognised engine.

### What is left to explore

**The first paragraph below is DONE, as of September 9, 2026 (same day, later); see the 0.4.0
entry near the top of this document and `HiGy_v040_parity_report_2026-09-09.md`.** It is kept
here unchanged since it correctly anticipated the port, down to the self-test restating named
below. The beta question was first and, as of September 9, 2026, it is decided rather than open. The
September 8 text called it a decision rather than a study and placed the floor question with it,
since the deposit's origin backgrounds of 0.003 yr⁻¹ natural and 0.006 yr⁻¹ planted are already
of record and adding them is a one-line change once someone rules that they belong. Both are
now ruled. What is first is the port of the deployed arm into this file, namely
`KOA_GARCIA_BETA` to 0.16019053617304435, the state variable of the step from `koa_h40()` to
H_QMD formed from the plot's quadratic mean diameter through a = −0.168630705121571 and
k_HD = 1.1719473700506686, and the A1 floor taking the stand rate as the larger of 1 − N₁/N₀
and the origin background. Stage 1, Stage 3 and the renormalization contract do not move. The
port needs its own self-test, since the cycle-length invariance, the flat-height short circuit
and the limiting-line checks of the present test are all written on H40 and will need restating
on H_QMD, and the beta sensitivity block should then be retired or rewritten so that it compares
arms on their own frames rather than constants on a shared one.

The `surv_prob()` sense and the `surv.parm` vector are second, and they cannot be settled
separately from one another or from the slenderness units. What is needed is one ruling on
whether the published fit is on the alive response or the death response, taken against the
fitting script rather than against either file's comments, after which the correct pairing goes
into both `HiGy.R` and `WeiskittelKoaGy.R` in a single edit with its own control.

A planted background rate is the largest open fit. The gap is 0.4 percent yr⁻¹ predicted
against 2.2 percent observed over 41 intervals, the hook is in place, and what is missing is an
estimate that survives the sentinel question rather than an implementation.

The sentinel death-recording convention is the constraint under everything else. Under the
alternative reading the regular set holds 21 deaths and no parameter in this component is
estimable, so a ruling from the data custodians on whether the zero-diameter dead records are
deaths or unrecorded thinning would either confirm the whole fit or retire it.

Density-dependent background mortality was fitted in eight forms on this record and none of them
ships, every one failing the Bakuzis Reineke slope gate, and the flat diagnostic arms show the
failure is driven by the mortality level the record demands rather than by density dependence.
That is a level problem and it will not be solved by a better density term.

The three flagged defects of item 10 above, the basal area construction of item 11 and the two
diameter increment constants of item 12 each need their own edit and their own control, and
items 11 and 12 move mortality through the projected top height, so both should be closed before
this file is released rather than after.

Ingrowth is still absent from `HiGy.R`, which bounds what any mortality component can be asked
to do over a long projection, since a stand that loses stems and gains none will run down
whatever the mortality equation is.

### URLs that could not be supplied, flagged rather than omitted

Four items in this entry have no public URL and are named here so that no reader assumes one
exists. The deposit-side files quoted throughout, meaning the deposit's own copy of `HiGy.R`,
`koa_survival_calibrated.R`, `DEPOSIT_CHANGELOG.md` and `verify_reproducibility.R`, sit in the
working deposit tree and are reachable only through the concept DOI above once the version
carrying them is published, so they are cited by file and line rather than by link.
García (2009) carries no DOI and is Mathematical and Computational Forestry and Natural Resource
Sciences 1, 1 to 9. No comment has been posted to pull request 31 and no URL exists for one,
and the `PROPOSED_PR31_COMMENT.md` that the September 4 package's manifest names is not in that
package directory. The August 28, 2026 and September 4, 2026 packages themselves were sent
directly and have no repository or archive location, so they are cited by package folder and
file name.

### References

Chen, C., Kershaw, J.A., Weiskittel, A.R., McGarrigle, E., 2023. Can a multistage approach
improve individual tree mortality predictions across the complex mixed-species and managed
forests of eastern North America? Forest Ecosystems 10, 100086.
https://doi.org/10.1016/j.fecs.2023.100086

García, O., 2009. A simple and effective forest stand mortality model. Mathematical and
Computational Forestry and Natural Resource Sciences 1, 1 to 9.

---

## 0.2.0, February 23, 2026 and June 5, 2026. What stands in the repository before this entry

Biomass yield index and the planted indicator were integrated across the equations, with the
planted indicator derived from `FVS_Standinit.StdOrgCd`. Mortality is the manuscript Table 6
tree-level complementary log-log throughout, evaluated per tree by `surv_prob()` with
`dexpf = expf * (1 - surv)`, and it carries no stand density term of any kind, so a HiGy.R
stand has no self-thinning and its density trajectory is the sum of tree-level probabilities
that never learn the trees are competing. The file reached this state in
[`afa0428`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/afa0428efa)
of February 23, 2026 and
[`254f4ff`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/254f4ffc23)
of June 5, 2026 and has not moved since.

The August 12, 2026 sign correction and the August 15, 2026 coefficient correction described in
the earlier draft of this changelog were made in the manuscript deposit's copy of this file and
were never pushed here. Both are open questions rather than applied fixes so far as the
repository is concerned, and they are set out in full in the block above `surv.parm` in the
0.3.0 file and in the second finding of this entry.

## 0.1.0. Initial version

Designed to work with FVS-HI and `customRun_fvsRunHi.R`, containing the koa equations. The
standalone prediction script that preceded it,
[`WeiskittelKoaGy.R`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/blob/FvsHiHistory/fvsOL/inst/extdata/WeiskittelKoaGy.R),
entered the branch on
[`5453a2a`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/5453a2a990)
as the initial koa model of September 23, 2025 and reached its present form on
[`8e04788`](https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/commit/8e047883bc)
of April 27, 2026. It carries a self-thinning rule expressed as a fraction of a maximum stand
density index of 500 and a stand density index formed on a denominator of 25.4 rather than 25,
both of which are withdrawn elsewhere in the koa system, so it should not be read as a current
statement of the model.
