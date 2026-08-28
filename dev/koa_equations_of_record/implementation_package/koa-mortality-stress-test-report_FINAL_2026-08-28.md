# Stress test of the deployed koa mortality and survival chain

**Status.** FINAL, August 28, 2026 (run of August 26, 2026). Harness
`stress_mortality.py` and run log `stress_mortality_output.log` sit alongside
this report in this package.
The model is FINAL. This exercise tests and documents the behavioral envelope an
FVS-HI implementation must reproduce, and it changes nothing. The Cowork
sandbox shell failed with the known bridge-socket fault after the final green
run, so the log file is an assembly of verbatim captured segments with
provenance annotated in its header, and the deterministic harness regenerates
the exact log on any rerun.

**What was tested.** The figshare_v64 deposit's own modules, imported
unmodified from a read-only copy, namely `koa_survival_calibrated_py.py`
(Eq. 5b stand rate, allocation, R1 renormalizer), `koa_equations.py` (Eq. 5
cloglog used as the allocation ordering weight), `koa_projector.py`
(`project_psp`, the annual stepping engine), and `koa_ingrowth.py`. Deployed
flags confirmed in `koa_params.py` as ALLOC_MODE = "tree_eq" and
ALLOC_RENORMALIZE = True, with constants BASE_NAT 0.003, BASE_PLT 0.006,
ONSET_SDI 200, FULL_SDI 850, MAXLIFT 0.15, MORT_MAX 0.20, ALLOC_MORT_CAP 0.95,
and the August 18, 2026 guard-order fix present in both carriers. The prior
gate battery (gates 1, 1c through 1j, injection tests) was not rerun. As
corroboration the deposit's `test_engine_equivalence.py` was executed in this
session and PASSED, with a maximum survival deviation of 2.439e-19 between the
deposited engine and the script's independent transcription of the R text,
both transcriptions being Python. The R-versus-Python gate proper (GATE 1j,
allocator agreement 4.4e-16) is cited from the deposit's own record in
DEPOSIT_CHANGELOG.md and the posted PR #31 comment of August 19, 2026, and was
not rerun here since R is unavailable in this sandbox.

## Result summary

34 cases ran, 24 PASS and 10 FLAG. Every FLAG is a documented
correct-but-surprising behavior or a divergence from a tasking assumption, not
an equation defect. No case produced a per-tree mortality outside [0, 0.95], no
case broke the expansion-factor-weighted mean constraint where the code
promises it, and the chain is bitwise deterministic.

## Test matrix

| # | Sec | Case | Expected | Observed | Verdict |
|---|-----|------|----------|----------|---------|
| 1 | a | Ramp values on 14-point SDI grid (0 to 3000), both origins | base + 0.15 x clip((SDI-200)/650, 0, 1) | exact, max dev < 1e-15 | PASS |
| 2 | a | Monotone non-decreasing in SDI | non-decreasing | non-decreasing | PASS |
| 3 | a | Onset breakpoint | mort(199) = mort(200) = base, mort(201) > base | 0.003, 0.003, 0.0032307692 | PASS |
| 4 | a | Full-lift breakpoint | mort(849) < mort(850) = mort(851) = plateau | 0.1527692308, 0.153, 0.153 | PASS |
| 5 | a | Plateau value | natural 0.153, planted 0.156, MORT_MAX 0.20 never binds | as expected | PASS |
| 6 | a | 15.3% vs 10.85% in code terms | see plateau note below | consistent, implied mean interval 5.55 yr | PASS |
| 7 | b | Weighted mean equals stand rate | m_stand 0.132778162886499 | dev 0.0 | PASS |
| 8 | b | Ordering follows Eq. 5 risk | identical rank order of weight and rate | identical | PASS |
| 9 | b | R1 ordering-only below cap | m_i / w constant | spread 5.6e-17 | PASS |
| 10 | b | Planted origin | same ordering, scaled rates | rank identical, wmean 0.1358 vs 0.1328 | PASS |
| 11 | c | First cap pinning | at m_stand = cap x wbar / wmax = 0.904080 | pinned at 1.01x threshold, not at 0.99x | PASS |
| 12 | c | Between pinning and infeasibility | common lambda > 1 rescale of uncapped trees, wmean restored | wmean dev 7.8e-16, uncapped m_i/w spread 7.3e-12 | PASS |
| 13 | c | Infeasible rate 0.99 | RuntimeWarning, all trees at 0.95 | warned, all at cap, shortfall 0.04 | PASS |
| 14 | c | Bounds over whole sweep | 0 <= m_i <= 0.95 | held everywhere | PASS |
| 15 | c | MORT_MAX 0.20 semantics | see FLAG 1 | stand-rate cap, inert on deployed constants | FLAG |
| 16 | d | Single tree | m_i = m_stand exactly | dev 6.9e-18 | PASS |
| 17 | d | expf 1 vs 1000 | wmean held, rare tree carries 0.9319 | wmean dev < 1e-15 | PASS |
| 18 | d | All-identical trees | every tree at the stand rate | max dev < 1e-15 | PASS |
| 19 | d | Empty tree list | silent empty return | empty array, numpy 0/0 warning only | FLAG |
| 20 | d | Renormalizer with total expf 0 | early return of clipped input | constraint silently unenforced | FLAG |
| 21 | d | DBH 1.0 and 2.5 cm | weight evaluates, wmean holds | m_i [0.0534, 0.0534, 0.0433], dev 0.0 | FLAG |
| 22 | d | 200 cm DBH tree | weight floors at 1e-9 clip | m_i 5.2e-11, wmean holds | FLAG |
| 23 | e | 10-yr frozen-state survival | expf x (1-annual)^10 | dev 7.1e-15 | PASS |
| 24 | e | One projector year | removes exactly the allocated rates, weights use recomputed CR | TPH dev 0.0 | PASS |
| 25 | e | YIP | inert in deployed chain, annual compounding | confirmed by code read and numerics | PASS |
| 26 | e | expf floor 1e-5 | cohort never reaches zero | present in project_psp | FLAG |
| 27 | f | Order of operations | see sequence below | confirmed | PASS |
| 28 | g | Bitwise determinism | identical alloc and 10-yr projection with ingrowth | bitwise identical | PASS |
| 29 | g | No RNG in mortality path | none | none, ingrowth is expected-value | PASS |
| 30 | h | NaN DBH | poisons every tree's rate | all NaN, no raise | FLAG |
| 31 | h | Negative expf | accepted, constraint enforced against corrupted mean | rates in bounds, no warning | FLAG |
| 32 | h | NaN crown ratio | poisons every tree's rate | all NaN, no raise | FLAG |
| 33 | h | NaN SDI | NaN mortality returned | NaN, no raise | FLAG |
| 34 | h | Negative SDI | clips to base rate | 0.003 | PASS |

## The plateau numbers, stated precisely in code terms

The nominal plateau of Eq. 5b is base + MAXLIFT, which is 0.003 + 0.15 = 0.153
per year for natural origin and 0.006 + 0.15 = 0.156 for planted, reached at
SDI 850 and constant above it. MORT_MAX 0.20 sits above both and never binds on
the deployed constants. The manuscript's 15.3% is that annual natural plateau.
The supplement's 10.85% above SDI 1,200 is a different quantity, namely the
expected deaths per tree-year when the 15.3% annual rate is compounded over the
observed multi-year remeasurement intervals in that density bin, per record
(1 - (1 - 0.153)^L) / L for an L-year interval, summed over records and divided
by tree-years. Compounding pulls this below the annual rate for any L above
one year. The identity reproduces 0.1085 exactly at an implied mean interval of
5.55 years, which is consistent with the supplement's remeasurement mix. The
mechanism is verified as an identity here, while the bin-exact 10.85% was not
recomputed from the variant (ii) profiling sample, so an FVS reader should
treat 15.3% as the number the code produces and 10.85% as a reporting
derivative for interval data, never as a second plateau.

A related transcription nuance surfaced during testing. `surv_calibrated`
returns survival, and mortality recovered as 1 - s carries one ulp of roundoff
(about 3e-18 at the base rate), so equality checks against literal constants in
any port must be tolerance based, not exact.

## Order of operations within one projection year (Part 1f)

`project_psp` consumes a projection interval as that many independent annual
steps. Within one year, in order, with every step reading start-of-year state,

1. sort trees by descending DBH
2. stand summary from the sorted list, per-tree BA, BAL as cumulative BA less
   own BA, BAPH, TPH, QMD, SDI = TPH x (QMD/25)^1.605, HTmax
3. crown update, HCB model then CR = clip(1 - HCB/HT, 0.05, 0.95), which
   overwrites the input CR from year one onward
4. rHT = HT / max(HTmax, 0.1)
5. dDBH and dHT computed but not applied, with dDBH = 0 where HT < 1.3716 m
6. mortality, m_stand = 1 - surv_calibrated(sdi from step 2, planted), weights
   w = clip(1 - Eq5_survival(dbh, ht, step-3 CR, step-4 rHT, byi), 1e-9, 1),
   m_i = renormalize(m_stand x w / wbar, expf, m_stand, cap 0.95), then
   expf = max(expf x (1 - m_i), 1e-5)
7. increments applied, DBH += dDBH and HT += dHT, with size caps that reject
   the step (a tree at the cap keeps its old value rather than being clamped)
8. ingrowth, expected recruits from the step-2 SDI, appended at 2.5 cm DBH with
   modeled height from step-2 BAPH and QMD, crown ratio 0.6
9. if the list exceeds 300 records, bin to 0.5 cm DBH classes with
   expf-weighted means

SDI is recomputed only at the top of the next year. Mortality in year t
therefore uses the pre-growth, pre-ingrowth density of year t, and the year-t
increments use pre-mortality competition. YIP never enters the deployed chain
because Eq. 5b has no interval term and the allocation weight calls the fitted
Eq. 5 with yip = 1.

## The ten FLAGs, in full

**FLAG 1, MORT_MAX 0.20 is a stand-rate cap, not the per-tree cap.** The
tasking described mort_max = 0.20 near line 88 of
`koa_survival_calibrated_py.py` as a per-tree cap with infeasibility at stand
rates above 0.20. Measured behavior differs. The 0.20 clips the stand-level
annual mortality inside Eq. 5b, where it can never act because the ramp maximum
is 0.156, and the per-tree cap in allocation is ALLOC_MORT_CAP = 0.95, so the
allocation becomes infeasible only at stand rates of 0.95 and above, which
Eq. 5b cannot produce. The 0.20 was forced to bind in this run only through the
diagnostics override maxlift = 0.25, where 0.256 clipped to 0.200 as designed.
`koa_params.py` itself flags MORT_MAX as inert and hazardous, retained
deliberately because no deployed constant moves. Both caps, their separate
roles, and the inertness of 0.20 are stated in the implementation spec.

**FLAG 2, empty tree list.** `allocate` on a zero-length list returns an empty
array with only a numpy scalar-divide warning from wbar = 0/0. Correct as a
no-op yet silent. The FVS port should skip the mortality call explicitly when
no trees exist.

**FLAG 3, renormalizer with total expf = 0.** The esum <= 0 guard returns the
clipped input without enforcing the weighted-mean constraint and without
warning. Unreachable through the projector, reachable by a direct caller.

**FLAG 4, sub-threshold DBH.** The 2.5 cm screen is a fitting screen, not a
runtime guard. Trees at 1.0 and 2.5 cm receive well-defined weights and rates,
and the weighted mean holds. The projector zeroes diameter increment below
breast height (HT < 1.3716 m) but mortality still applies to such trees. The
FVS port must not add a DBH floor the model does not have.

**FLAG 5, 200 cm DBH.** Far beyond the data (DBH support ends near 90 cm and
the tallest measured koa stem is 34.14 m), Eq. 5 mortality underflows and the
weight floors at the 1e-9 clip, so a giant tree is allocated a near-zero rate
(5.2e-11 here) and is effectively immortal while density-driven mortality is
loaded onto the rest of the stand. The weighted mean still holds. This is
coherent extrapolation behavior and the spec states it so FVS reproduces it or
consciously diverges.

**FLAG 6, expansion-factor floor.** `project_psp` floors expf at 1e-5 trees per
hectare every year, so a cohort never reaches zero. FVS kills trees by reducing
trees per acre and its natural port drops this floor. The spec makes that a
documented decision with a stated tolerance consequence, at most 1e-5 trees per
hectare per record, immaterial at reporting precision.

**FLAGs 7 through 10, input hygiene.** A NaN DBH or NaN crown ratio on any one
tree propagates through the shared wbar and silently turns every tree's rate to
NaN, with no raise and no drop. A negative expansion factor is accepted and the
constraint is enforced against the corrupted mean while per-tree rates stay in
bounds. A NaN SDI returns NaN mortality from Eq. 5b. Only negative SDI is
benign, clipping to the base rate. The deposit's own injection gates cover
these at the equation level, but the engine has no input guard, and the FVS
port should validate its tree list before the mortality call because FVS's own
data are not guaranteed clean.

## Determinism

Two back-to-back runs of the allocation and a 10-year projection with ingrowth
are bitwise identical, and a code read confirms no random draws anywhere in
`surv_calibrated`, `allocate`, `renormalize_to_stand_rate`, `project_psp`, or
`ingrowth_annual`, whose recruitment is an expected value, not a draw.

## Acceptance vectors

Six numeric vectors (AT-1 through AT-6) were generated from this run at full
double precision and are printed at the end of `stress_mortality_output.log`.
They are restated with inputs and expected outputs in the implementation spec,
section 4, and cover the ramp, an uncapped allocation, a cap-binding
renormalization, the infeasible fallback, ten-year compounding, and the
single-tree degenerate case.
