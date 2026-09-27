# PREREG-KOA-01, variant A: the yield-density sign

**Run 2026-09-26 against the criteria fixed in `2026-09-26_koa-refinement_PREREG.md` before any result was seen.**
Source: `track3/lt/out/SC_trajectories.csv`, the deployed engine's own density and thinning scenarios.

## Outcome against the pre-registered criteria

The release mechanism the pre-registration proposed is **falsified**. The criterion required the dense arm's
increment to overtake the sparse arm's *after* their stem trajectories separated. The dense arm grows faster
from age 11, the earliest year available, and its stem count never falls below the sparse arm's at any age.
It is never released. Under the criterion as written, the cause was to be reported as unexplained rather than
assigned, and the decomposition below is what replaced the guess.

The sign is **not fixed and is not fixable by configuration**, which was the second pre-registered criterion.
Quadratic mean diameter at age 100 runs 50.9, 50.5, 55.0 and 60.5 cm across 250 to 2,000 natural stems ha-1.

## What the measurement shows

The trajectory file carries the change in quadratic mean diameter each year already split into the part from
growth and the part from mortality removing small stems. Split that way the two components move in opposite
directions with density.

| Age | Component | 250 stems | 500 | 1,000 | 2,000 |
|---|---|---|---|---|---|
| 11 | growth | 0.521 | 0.470 | 0.422 | 0.413 |
| 11 | selection | 0.021 | 0.045 | 0.135 | 0.302 |
| 20 | growth | 0.476 | 0.421 | 0.392 | 0.420 |
| 20 | selection | 0.034 | 0.069 | 0.161 | 0.236 |
| 60 | growth | 0.322 | 0.296 | 0.317 | 0.355 |
| 60 | selection | 0.054 | 0.088 | 0.113 | 0.097 |

Competition is working correctly. The growth component falls as density rises, 0.521 to 0.413 cm yr-1 at age
11. What rises is selection, fourteen-fold over the same range, and selection is the larger term in the dense
arms. Removing small stems raises the quadratic mean of the survivors arithmetically, so a stand that kills
more small trees reports a larger mean tree while every tree in it grows more slowly.

**Dominant diameter does not escape this.** D100 at age 100 runs 51.0, 56.3, 59.9 and 63.1 cm across the same
range, rising as well. It cannot help, because D100 is the mean of the largest 100 stems per hectare and the
dense arm selects those 100 from 608 stems at age 20 where the sparse arm selects from 214. Whenever stem
counts differ, every stand-level mean-size statistic in this grid carries the same contamination.

The thinning results follow from the same arithmetic rather than from a separate defect. Thinning planted
stands to 500 at age 8 gives a smaller quadratic mean diameter at age 100 than not thinning, 61.4 against
62.1, and a smaller D100, 68.6 against 69.3, because the unthinned stand goes on selecting through mortality
for the remaining 92 years while the thinned stand selected once.

## What this means for the manuscript

This is not a model defect and no variant would repair it. It is an interpretive trap, and Section 4.5 walks
into it: the density guidance reads quadratic mean diameter across density as a growth response when most of
the density signal in it is survivor selection. The same reading makes the thinning result look like thinning
harms tree size, which is not what the projection says.

The fix is to what is claimed rather than to what is computed. Report that individual diameter growth declines
with density as expected, that mean-size statistics of the survivors rise with density through selection, and
that the two must not be read as one. Where a size response to density is wanted, it needs a statistic held at
constant stem number or an explicit statement that the comparison is of survivors rather than of growth.

## Gates

The magnitude gate was not reached, since no variant was adopted. No estimate here travels without the
measurement behind it; the components are exact decompositions of the engine's own output rather than fitted
quantities, so they carry no sampling interval, and that is stated rather than papered over with one.

## Two wrong attributions, recorded

Before measuring, the cause was assigned twice and wrongly. The stress test assigned it to Stage 3 allocation.
I then argued that could not be right because the even-aged rows run through the cohort path, and proposed a
release mechanism instead. Both were wrong: the density grid does run a tree list through `project_thin` with
an allocator, so Stage 3 is in play, and the release mechanism is falsified above. The decomposition settled
in one measurement what two rounds of reasoning from code got wrong in opposite directions.

## Variants B and C

Not run. B, the fitted against anchored self-thinning beta, and C, leave-one-source-out on the origin
multipliers, remain as specified in the pre-registration.
