# PREREG-KOA-01: three-variant staged refinement of the koa v102 system

**Written 2026-09-26, before any variant was run.** Criteria, gates and stopping rules below are fixed
in advance. Results go in a separate file so this one cannot be edited to match them.

## Decision this serves

Whether the v102 system's long-term projections can support density and rotation guidance, or whether
that guidance has to be withdrawn to site-class and age ranges the data actually cover. Three structural
findings from the 26 September stress test bear on it. The accuracy the decision needs is modest, the
direction of the density response has to be right, but it does not need to be right to a centimetre.

## ORIENT, and a correction to the stress test's attribution

The stress test reported that quadratic mean diameter at age 100 rises with initial density, 50.9 to
60.5 cm across 250 to 2,000 stems ha-1 natural, and that thinning from below leaves a smaller quadratic
mean diameter than not thinning. Both are reproduced. Its attribution is wrong, and two candidate
mechanisms are ruled out before designing anything.

**Not Stage 3 allocation.** `ALLOC_MODE` acts only on the tree-list path. `koa_params.py` records, in
its own 18 August correction, that the even-aged rows run through `koa_projector.project_cohort`, which
carries no tree list and never reaches the allocator. The even-aged density grid is where the sign error
appears, so the allocator cannot be its cause there.

**Not the self-thinning guardrail.** The guardrail does inflate diameter on thinning,
`DBH *= (TPH/tphn)**GUARDRAIL_DBH_EXPONENT` at `koa_projector.py:206`, which would produce exactly this
sign. But it is gated on `engine == "ramp" and bounded and surv_fn is None`, and the deployed engine is
`garcia_qmd_anchored` (C5, `MORT_ENGINE` at `koa_params.py:175`), a García-family arm. The guardrail
never fires in the deployed configuration.

**Remaining candidate, to be tested.** In a single-cohort representation quadratic mean diameter is a
scalar, so density-dependent mortality removes stems without removing small stems. A denser stand
self-thins harder, its competition terms fall faster, and the surviving average tree is released. If the
release effect outruns the competition effect the observed sign follows, and it is a property of the
cohort representation rather than of any parameter. That distinction decides whether the fix is a
parameter change or a scope restriction on what the projections may be used for.

## Variants

**A. Yield-density mechanism.** Decompose the even-aged density grid. For each initial density record
TPH, BAPH, BAL and annual diameter increment by year. Then run the same grid through the tree-list path
(`project_psp`, where the allocator does act) and compare.

**B. Self-thinning, fitted against anchored beta.** Run the grid and the main projection under
`GARCIA_BETA = 0.117`, the fitted value, against the deployed `GARCIA_BETA_ANCHORED = 0.16019053617304435`.
Report both rather than replacing one with the other.

**C. Origin transferability.** Leave-one-source-out on the origin calibration multipliers, testing whether
the origin contrast survives removal of any single data source.

## Criteria, fixed now

**A is confirmed as a structural release effect** if the cumulative diameter increment of the highest
initial density arm overtakes that of the lowest before age 100, and the crossover age falls after the
age at which their TPH trajectories separate. If the increment curves do not cross, the mechanism is
something else and A is reported as unexplained rather than assigned a cause.

**The sign is called fixed** only if quadratic mean diameter at age 100 is non-increasing across all four
initial densities. A reduction in the slope is not a fix and will not be reported as one.

**B is adopted** only if the fitted beta's projections stay inside the observed density envelope. The
anchoring note records that beta 0.117 permits basal area and stand density index beyond any observed koa
plot-year, so the expected outcome is that B is reported as a sensitivity and not deployed. Recording
that expectation now so a confirming result is not written up as a discovery.

**C changes the manuscript** only if the origin contrast fails to survive leave-one-source-out. If it
survives, the two-scenario presentation stands and the Eichhorn and stocking-guide failures are reported
as a known limitation of the calibration rather than as a defect to fix.

## Gates, fixed now

Magnitude (F5): no accepted variant may project basal area above 76.06 m2 ha-1 or stand density index
above 1,453, the observed maxima. A variant that exceeds either is reported, never adopted.

Uncertainty (principle 15): every reported estimate carries an interval with its type named. Monte Carlo
intervals for projections, plot-level bootstrap for evaluation statistics.

Evaluation (principle 16): bootstrap equivalence at the plot level, 5,000 resamples, region of equivalence
plus or minus 25 percent of the observed mean stated here in advance, and the smallest passing region
reported alongside the verdict for each variant.

Comparison (principle 2): one table across all variants carrying bias, RMSE, interval coverage and the
equivalence outcome for intercept and slope. No variant is adopted on a single metric.

## Stopping rules

Stop and report rather than continuing if any variant needs a new equation rather than a configuration
change, if a variant passes its own criterion but fails a gate, or if the comparison table shows no
variant dominating the deployed configuration on more than one axis.

## What this does not touch

The deposit, which is clean and whose data files are unaffected by all three variants. The 1.9.3 staging
stands regardless of the outcome.


---

## Amendment, 2026-09-26, after reading code and before seeing any result

The ORIENT section above rules out Stage 3 allocation on the ground that the even-aged rows run through
`project_cohort`. That is wrong for this grid. `track3/lt/scenarios.py` builds a weighted tree list with
`dens_list` and runs it through `project_thin`, whose signature carries `alloc_mode="tree_eq"`, so the
allocator does act in the density and thinning scenarios. The guardrail exclusion stands, since the deployed
engine is a Garcia-family arm and the guardrail is gated on `engine == "ramp"`.

That makes two wrong attributions of this mechanism from reading code, in opposite directions. The response
was to stop assigning a cause and measure the decomposition the trajectory file already carries. The
pre-registered criteria were not changed, and variant A was then judged against them as written; it failed
the release criterion and the sign criterion both. Result in
`2026-09-26_koa-refinement_VARIANT-A_RESULT.md`.
