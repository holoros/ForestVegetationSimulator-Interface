# Koa mortality system, implementation specification for FVS-HI

**For.** Ben Rice (Midgard), FVS-HI koa variant.
**From.** Aaron Weiskittel. Prepared August 26, 2026; finalized August 28, 2026.
Delivered with the stress test report, the harness, its log, and byte-identical
copies of the engine of record (see README.md in this package).
**Ground rule.** The model is final. Nothing here proposes a change to any
equation or constant. This document tells you exactly what to code, in what
order, and how to prove each step correct before moving to the next. Every
numbered step ends with a check you can run and tick off.

---

## 1. Scope and source of truth

**Step 1. Pin your sources before writing any code.**

The equations of record are the two R files, and the Python deposit is their
verified mirror. Code from whichever is more convenient, then verify against
the acceptance vectors in section 4, which were generated from the deposit.

| Artifact | Role | Where |
|----------|------|-------|
| `final/koa_survival_calibrated.R` | Equation of record for the stand rate (Eq. 5b), the tree weight (Eq. 5 as `koa.SURV.tree.mort`), the allocator, and the renormalizer | Koa project tree, also mirrored at the deposit root |
| `final/koa_ingrowth.R` | Equation of record for ingrowth | same |
| figshare_v64 Python files | Verified mirror, agreement with an independent transcription of the R text to 2.4e-19 in annual survival, R-vs-Python allocator gate to 4.4e-16 (GATE 1j) | `koa_survival_calibrated_py.py`, `koa_equations.py`, `koa_projector.py`, `koa_ingrowth.py`, `koa_params.py` |
| `koa_params.py` | Single source of every non-fitted constant, with provenance comments naming R line numbers | figshare_v64 |
| Manuscript Table 6 | The fitted Eq. 5 coefficient vector | manuscript, mirrored in `koa_equations.LineageA.SURV` |
| Supplement Table S3b | The Eq. 5b parameter table | supplement |

Three warnings on sources. First, the copies of `koa_equations.py` and
`koa_projector.py` inside the PR #31 validation harness are a June snapshot and
are not the equations of record, per the comment posted to PR #31 on August 19,
2026. Read the `koa-equations-of-record-20260819` branch
(`dev/koa_equations_of_record/`) or figshare_v64, which are byte-identical.
Second, no scalar maximum SDI is deployed anywhere. The values 500, 933, and
1350 metric are all withdrawn. If you find `SDImax` in any calling code, remove
it rather than replacing the number. Third, the supplement's Table S3b caption
still describes the retired relative-density ramp (RD 0.65 to 0.85 of an
SDImax). The deployed ramp is in absolute SDI, onset 200 and full lift 850, and
the R file is authoritative over that caption.

**Check 1.** You can open both R files and `koa_params.py`, and every constant
in the table in Step 3 below matches what you read there.

---

## 2. Equations and algorithm

All metric. DBH in cm, HT in m, BAPH and BAL in m2/ha, expansion factor in
trees/ha, BYI in Mg/ha. FVS-HI carries imperial internally, so convert at the
boundary and keep the mortality math metric.

**Step 2. Code the stand density inputs.**

    SDI = TPH * (QMD / 25)^1.605

The exponent is 1.605, not 1.6. The R file is explicit that the two agree only
at QMD 25 cm and that the ramp thresholds, the Reineke identity, and the
diameter-conditional bound are all stated on the 1.605 scale. The HiGy.R
comment at its line 1153 that reads `expf*(qmd/25)^1.6` is stale and must not
be transcribed.

If SDI cannot be formed but basal area can, use the Reineke fallback

    kR  = (pi/4) * 25^1.605 / 1e4        (= 0.013765233897615397)
    SDI = BAPH / (kR * Dq^0.395)

with Dq the stand's own QMD when available and 20 cm otherwise.

**Check 2.** At TPH 585 and QMD 16.748516964579895 cm you get
SDI 307.57016521239154.

**Step 3. Code Eq. 5b, the stand-level annual mortality ramp.**

    base = 0.006 if planted else 0.003
    frac = clip((SDI - 200) / (850 - 200), 0, 1)
    m_stand = clip(base + 0.15 * frac, 0, 0.20)
    annual stand survival = 1 - m_stand

Constants, pinned to `koa_params.py` and the R source (lines 481 to 553).

| Constant | Value | Meaning |
|----------|-------|---------|
| BASE_NAT | 0.003 /yr | background annual mortality, natural |
| BASE_PLT | 0.006 /yr | background annual mortality, planted |
| ONSET_SDI | 200 (metric, 79 imperial) | ramp onset, absolute SDI |
| FULL_SDI | 850 (metric, 335 imperial) | full lift, absolute SDI |
| MAXLIFT | 0.15 /yr | maximum density-dependent lift |
| MORT_MAX | 0.20 /yr | cap on the stand rate, inert (see section 5) |

The plateau is 0.153 /yr natural and 0.156 /yr planted, reached at SDI 850 and
constant above. There is no SDImax anywhere in this calculation. The 0.20 cap
can never act on these constants and is retained deliberately.

**Check 3.** Reproduce acceptance vector AT-1 in section 4 to within 1e-12.

**Step 4. Code Eq. 5, the fitted tree survivor equation, as the allocation
weight only.**

Eq. 5 is a complementary log-log model fitted on the alive response with a
ln(YIP) offset. It never sets the stand mortality level in deployment. Its only
production role is to order trees for the allocation in Step 5.

    HT'  = max(HT, 0.1)
    DBH' = max(DBH, 0.1)
    CR'  = clip(CR, 0.01, 0.99)
    eta  = 14.102
         + 0.130  * HT'
         - 4.516  * ln(HT')
         + 6.684  * rHT
         + 14.218 * ln(CR')
         - 2.806  * ln(HT' / DBH')
         + 2.649  * ln(max(BYI, 1) / 100)
         - 21.188 * (BYI / 1000)
    annual P(alive)      = 1 - exp(-exp(eta + ln(YIP)))   with YIP = 1
    annual tree mortality = exp(-exp(eta))
    weight w_i = clip(annual tree mortality, 1e-9, 1.0)

rHT is tree height over the stand's maximum tree height. The coefficient
vector is manuscript Table 6 (n = 5,969, 79 deaths), corrected into the record
on August 15, 2026. Do not use the older vector beginning 18.133, which is a
pre-deduplication development snapshot that survives only as a supplemental
comparison. YIP is 1 in every production call, so the offset term vanishes.
Note the two conventions inside the BYI terms, ln of BYI/100 and a linear
BYI/1000.

**Check 4.** Reproduce the five weights in acceptance vector AT-2.

**Step 5. Code the allocation with ratio normalization (R1).**

This is the heart of the port. Pseudocode, transcribed from
`koa.SURV.allocate` plus `koa.SURV.renormalize.to.stand.rate` (R lines 644 to
763) and their Python mirrors.

    allocate(dbh[], expf[], ht[], cr[], rht[], byi, m_stand):
        # 1. weights from Eq. 5 (Step 4)
        w[i]   = clip(eq5_annual_mortality(dbh[i], ht[i], cr[i], rht[i], byi),
                      1e-9, 1.0)
        # 2. ratio normalization: weighted mean of m0 is m_stand by algebra
        wbar   = sum(w[i] * expf[i]) / sum(expf[i])
        m0[i]  = m_stand * w[i] / wbar
        # 3. cap and renormalize
        return renormalize(m0, expf, m_stand, cap = 0.95)

    renormalize(m[], expf[], m_stand, cap, rtol = 1e-12, max_iter = 200):
        capped = clip(m, 0, cap)
        esum   = sum(expf)
        if esum <= 0 or len(m) == 0 or m_stand <= 0:
            return capped                        # guard, silent
        if m_stand >= cap:                       # INFEASIBLE. Test this FIRST.
            warn("stand rate %g at or above per-tree cap %g; every tree set
                  to the cap; stand under delivers by %g")
            return array of cap, same length as m
        if max(m) <= cap:
            return capped                        # cap does not bind, lambda=1,
                                                 # bitwise no-op
        # cap binds and the target is feasible: solve for lambda with
        #   sum(expf * min(lambda * m, cap)) / esum == m_stand
        wmean(lam) = sum(expf * min(lam * m, cap)) / esum
        lo = 1; hi = 1
        repeat up to max_iter:                   # geometric bracketing
            if wmean(hi) >= m_stand: break
            lo = hi; hi = 2 * hi
        else: warn and return capped             # bracketing failure, never
                                                 # observed in practice
        repeat up to max_iter:                   # bisection
            if hi - lo <= rtol * hi: break
            mid = (lo + hi) / 2
            if wmean(mid) < m_stand: lo = mid else hi = mid
        return clip(hi * m, 0, cap)              # return the UPPER bracket

Four transcription details are load bearing, and GATE 1j exists because
transcribing them differently in one carrier produced a real divergence.
First, the infeasibility test (m_stand >= cap) comes before the no-bind early
return, because an infeasible stand rate can arrive with no individual m above
the cap and must warn rather than under deliver silently. This is the
guard-order fix of August 18, 2026. Second, the bisection convergence test
runs before the midpoint is formed. Third, the function returns the upper
bracket hi, not the midpoint. Fourth, the renormalizer is a single function
that the allocator calls. Do not inline a second copy anywhere.

The per-tree cap is ALLOC_MORT_CAP = 0.95. The delivered guarantee is that
after capping, the expansion-factor-weighted mean of the per-tree annual
mortality equals m_stand exactly (to solver tolerance about 1e-12 relative
where the cap binds, to machine precision where it does not). Where the cap
does not bind the result is exactly m_stand * w / wbar, so the allocation is
ordering-only, and every tree's rate is proportional to its Eq. 5 risk.

**Check 5.** Reproduce acceptance vectors AT-2, AT-3, AT-4, and AT-6.

**Step 6. Apply mortality annually and place it correctly in the cycle.**

The model is annual. The reference engine consumes a projection interval of n
years as n independent annual passes, and within one year the sequence is, all
steps reading start-of-year state,

1. sort trees by descending DBH and compute per-tree BA, BAL (cumulative BA of
   larger trees), BAPH, TPH, QMD, SDI (Step 2 formula), and max height
2. update crown ratio from the HCB model, CR = clip(1 - HCB/HT, 0.05, 0.95)
3. rHT = HT / max height
4. compute (do not yet apply) the diameter and height increments
5. compute m_stand from the step-1 SDI, allocate to trees with the step-2 CR
   and step-3 rHT (Steps 3 to 5), and reduce each expansion factor by its
   allocated rate
6. apply the increments
7. add expected ingrowth from the step-1 SDI, recruits at 2.5 cm DBH,
   exp(5.3836 - 0.0061866 * SDI - 1.6359 * planted) trees/ha/yr

Density is recomputed once per year, so mortality in year t sees the
pre-growth, pre-ingrowth density of year t, and the increments of year t see
pre-mortality competition. There is no per-period rate anywhere. Survival over
a k-year step at frozen state is exactly (1 - m_annual)^k, and in a live
projection the annual recomputation makes the realized k-year survival
path dependent.

Mapping onto FVS. FVS-HI runs cycles of TIMEINT years (default 10, minimum 1)
and calls its mortality routine once per cycle. Two acceptable mappings, in
order of preference. Preferred, run the koa mortality chain inside an annual
subloop within the cycle, recomputing SDI, CR, and the weights each year,
which reproduces the reference engine exactly and makes results insensitive to
TIMEINT by construction. Acceptable fallback, compute the annual chain once at
the cycle start and apply the per-tree survival compounded, expf multiplied by
(1 - m_i)^TIMEINT, which freezes the within-cycle density feedback and will
diverge from the reference on long cycles in dense stands. TIMEINT sensitivity
is a known issue in FVS work generally, so whichever mapping you choose, run
the section 4 integration check at TIMEINT 1, 5, and 10 and report the spread.
The annualized-rate structure exists precisely so the model does not inherit
the interval-length pathology of the raw fitted Eq. 5, whose offset structure
makes survival rise with interval length.

Do not carry the reference engine's 1e-5 trees/ha expansion-factor floor into
FVS (section 5, item 4). Kill trees the normal FVS way.

**Check 6.** Reproduce acceptance vector AT-5, then run the integration check
in section 4 at three TIMEINT settings.

---

## 3. Edge-case contract

The FVS port must reproduce every row, or divergence must be a recorded
decision. These are the measured behaviors of the reference engine (stress run
of August 26, 2026, `_stress_20260826/`).

| Case | Required behavior |
|------|-------------------|
| SDI at 0, 50, 100, 199, 200 | mortality = base exactly (0.003 nat, 0.006 plt) |
| SDI 201 to 849 | base + 0.15 x (SDI - 200)/650, strictly increasing |
| SDI 850 and above (851, 1200, 1873, 3000 tested) | plateau, 0.153 nat / 0.156 plt, flat |
| Monotonicity | non-decreasing in SDI everywhere |
| Negative SDI | clips to base rate, no error |
| NaN SDI | reference propagates NaN silently; port should reject or guard (decision, section 5) |
| Allocation, cap not binding | m_i = m_stand x w_i / wbar exactly; expf-weighted mean = m_stand to machine precision; rank order of m_i equals rank order of w_i |
| Planted vs natural | changes m_stand only, never the ordering |
| Cap first binds | at m_stand = cap x wbar / max(w); below that, bitwise identical to the unrenormalized allocation |
| Cap binding, m_stand < 0.95 | uncapped trees rescaled by a common lambda > 1, weighted mean restored to m_stand (solver rtol 1e-12), capped trees at exactly 0.95 |
| m_stand >= 0.95 | warning naming the rate and the shortfall, every tree at 0.95; unreachable from Eq. 5b (max 0.156) but the branch must exist |
| Bounds | no tree ever above 0.95 or below 0, under any input tested |
| Single tree | receives exactly m_stand |
| All-identical trees | every tree receives exactly m_stand (tolerance 1e-15) |
| Extreme expf asymmetry (1 vs 1000) | weighted mean holds; the rare tree may carry a rate near the cap |
| Empty tree list | reference returns an empty result with only a numpy 0/0 warning; port should skip the mortality call explicitly |
| Total expf = 0 with trees present | reference returns clipped input, constraint unenforced, silent; unreachable in normal stepping |
| DBH at or below 2.5 cm | no floor, no special case; weights evaluate and the mean holds; do not add a DBH guard the model does not have |
| DBH 200 cm | Eq. 5 weight underflows to the 1e-9 clip, tree allocated a near-zero rate (5e-11 scale), rest of stand carries the mortality; mean holds |
| NaN DBH or NaN CR on one tree | reference silently NaNs every tree's rate through the shared wbar; port must validate inputs before the call (decision, section 5) |
| Negative expf | reference accepts it and enforces the constraint against the corrupted mean; port must validate |
| Determinism | no RNG anywhere in the chain; identical inputs give bitwise identical outputs; ingrowth is a deterministic expectation |
| Multi-year step | per-year compounding, (1 - annual)^k at frozen state; never a per-period rate |
| Mortality recovered as 1 - survival | carries one ulp of roundoff (3e-18 scale); all conformance checks tolerance based, never exact equality |

---

## 4. Acceptance tests

Generated from the reference engine on August 26, 2026, full double precision
in `_stress_20260826/stress_mortality_output.log`. Match AT-1 to 1e-12 and the
allocation vectors to 1e-9 per tree, which absorbs the solver tolerance.

**AT-1, ramp.** Annual mortality from Step 3.

| SDI | planted 0 | planted 1 |
|-----|-----------|-----------|
| 0 | 0.003 | 0.006 |
| 200 | 0.003 | 0.006 |
| 400 | 0.049153846153846 | 0.052153846153846 |
| 525 | 0.078 | 0.081 |
| 850 | 0.153 | 0.156 |
| 1200 | 0.153 | 0.156 |

**AT-2, five-tree allocation, cap not binding.** Inputs, with rht = ht/27.

| tree | dbh (cm) | expf (/ha) | ht (m) | cr | rht |
|------|------|------|-----|-----|------|
| 1 | 5 | 300 | 5 | 0.15 | 0.18518518518518517 |
| 2 | 12 | 150 | 11 | 0.30 | 0.4074074074074074 |
| 3 | 20 | 80 | 16 | 0.45 | 0.5925925925925926 |
| 4 | 35 | 40 | 22 | 0.55 | 0.8148148148148148 |
| 5 | 60 | 15 | 27 | 0.65 | 1.0 |

BYI 264, natural origin. Derived stand state BAPH 12.888414 m2/ha, TPH 585,
QMD 16.748516964579895 cm, SDI 307.57016521239154, and from AT-1 logic
m_stand = 0.027823884279782662.

Expected Eq. 5 weights w, then allocated m_i.

| tree | w_i | m_i |
|------|-----|-----|
| 1 | 0.9999999994233205 | 0.028882340573294470 |
| 2 | 0.9999961589159170 | 0.028882229650451601 |
| 3 | 0.9978197008574770 | 0.028819368447527995 |
| 4 | 0.8434082209293338 | 0.024359603493245084 |
| 5 | 4.774739382096271e-06 | 1.3790564906195346e-07 |

Expansion-weighted mean of m_i = 0.027823884279782666 (= m_stand to one ulp).

**AT-3, cap-binding renormalization.** Same five trees, forced
m_stand = 0.93. Expected m_i = [0.95, 0.95, 0.95, 0.95, 0.17000000000001433],
four trees at the cap, weighted mean 0.93000000000000027. Match the fifth
tree to 1e-9.

**AT-4, infeasible fallback.** Same five trees, forced m_stand = 0.99 against
cap 0.95. Expected, a warning naming the stand rate and the cap, and every
tree at exactly 0.95 (stand under delivers by 0.04).

**AT-5, compounding.** A frozen annual rate of 0.05 applied to expf 100 for
ten annual steps gives 59.873693923837862, which is 100 x 0.95^10.

**AT-6, single tree.** allocate(dbh = [20], expf = [100], ht = [15],
cr = [0.5], rht = [1.0], byi = 264, m_stand = 0.05) returns exactly 0.05.

**Integration check.** After the unit vectors pass, reproduce the deposit's
23-plot long-term validation (`koa_longterm_validation.py`, engine mode
calib_alloc, annual stepping, no ingrowth, intervals 4 to 52 years, mean 17).
The reference results your implementation must match are cohort survival
fraction bias +0.083, RMSE 0.25, r 0.651, surviving-cohort QMD bias
-0.597 cm, RMSE 6.58 cm, r 0.559, and surviving-cohort BAPH bias
-2.548 m2/ha, RMSE 16.60, r 0.589 (the deposit's
`koa_longterm_validation_summary.txt`, the Table S4b-class check). Match bias
and r to the printed precision. Run it at TIMEINT 1, 5, and 10 per Step 6 and
report the spread across the three.

---

## 5. Known behaviors requiring a decision or documentation

**Item 1, MORT_MAX 0.20 is inert and its rationale is undocumented.** The 0.20
caps the stand-level rate inside Eq. 5b. No derivation for the value exists in
the R source, and on the deployed constants it can never bind, since the ramp
maximum is 0.006 + 0.15 = 0.156. It bound in this week's stress run only under
a diagnostics override of maxlift. The value is retained deliberately because
the model is final and no deployed constant moves. Port it as written, keep it
inert, and do not repurpose it as a per-tree cap. The per-tree cap is 0.95 and
lives in the allocator. `koa_params.py` carries a fuller note flagging the cap
as hazardous to any future respecification compared under it.

**Item 2, the infeasible-rate fallback.** A stand rate at or above the
per-tree cap of 0.95 cannot be delivered by any allocation, so the renormalizer
warns and returns every tree at the cap, under delivering by the difference.
Eq. 5b cannot produce such a rate, so the branch is unreachable in production,
yet it must exist, warn, and be tested (AT-4), because a direct caller can
reach it and because its absence was the original silent-shortfall defect.

**Item 3, input validation is the port's job.** The reference engine has no
input guard. One NaN DBH or crown ratio silently poisons the whole stand's
mortality through the shared weight mean, and a negative expansion factor is
accepted. Decide the FVS-side behavior (reject the tree list, or clean and
log) and document it. Reproducing the NaN propagation is not required.

**Item 4, the 1e-5 expansion-factor floor.** The reference engine never lets a
tree record's expansion factor reach zero, flooring it at 1e-5 trees/ha each
year. This is a Python-engine bookkeeping convenience, not model content. The
recommended port drops the floor and kills trees the normal FVS way, recorded
as a conscious divergence with effect bounded at 1e-5 trees/ha per record.

**Item 5, extrapolation behavior to reproduce knowingly.** No DBH floor exists
in the mortality chain, so trees below 2.5 cm receive mortality (the 2.5 cm
threshold is a fitting screen, and ingrowth enters at exactly 2.5 cm). At the
other extreme a very large tree's Eq. 5 weight underflows to the 1e-9 clip and
the tree becomes effectively immortal in the allocation while the stand rate
is carried by the rest. Both behaviors follow from the equations as fitted.

**Item 6, one-ulp arithmetic.** Survival is the carried quantity and mortality
is recovered as 1 - s, so conformance tests must use tolerances, never exact
equality against literal constants.

---

## 6. One open item from the PR #31 thread

The one open offer already on the PR #31 thread, quoted verbatim from the
comment posted August 19, 2026, is,

> On your earlier point about research code in the shipped package tree, the
> harness moved to `dev/validation/koa_stress_test/` on 13 August;
> `fvsOL/inst/extdata/koa_stress_test/REPORT.md` is the only thing left inside
> the package, and I am happy to move that too if you would rather the package
> tree carry nothing from this work at all.

Anything further travels in the cover message rather than in this
specification, which is frozen with the model.
