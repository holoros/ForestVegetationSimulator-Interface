# Koa equations of record, 19 August 2026

This directory is a verbatim snapshot of the *Acacia koa* A. Gray growth-and-yield engine as it
stands in the FAIR deposit release tree `figshare_v64/`, taken on 19 August 2026 after the model
architecture was declared final. Every file here is byte-identical to its deposit counterpart, and
the deposit is the source of truth: if the two ever disagree, the deposit is right and this
snapshot is stale.

It is a specification, not a merge candidate. Nothing in the shipped `fvsOL` package tree is
touched, no build step reads this directory, and no keyword or variant wiring is proposed here.
The purpose is to give a reviewer of the FVS-HI koa work one clean, current, self-contained
statement of the deployed equations to read against, rather than a reconstruction assembled from
a long correction history.

## What the model is

Mortality is computed at the stand level by the calibrated density-dependent annual rate
(manuscript Eq. 5b) and then disaggregated to individual trees by the fitted tree-level survivor
equation used as an ordering weight only, with a post-cap renormalization so that the tree-level
rates reproduce the stand rate they were derived from. The mortality ramp is parameterized in
absolute stand density index, onset at SDI 200 metric (79 imperial) and full lift at SDI 850
metric (335 imperial). No scalar maximum stand density index is deployed anywhere in the
production path. The three values that have at various times been deployed or proposed, 500, 933
and 1350 metric, are all withdrawn; `SDImax` is a reporting-only argument defaulting to `NA` in R
and to a poisoned sentinel in the Python carriers, so an importer that reads it fails loudly
instead of silently receiving a withdrawn constant. The ingrowth density term is a slope per unit
of absolute stand density index, `b_sdi` = -0.0061866, which equals the retired relative-density
coefficient -3.0933 divided by 500 and is the quantity the model was actually fitted on. Both
equations invert basal area to stand density index through the Reineke identity at the stand's own
quadratic mean diameter, with the fallback anchored at 42 m² ha⁻¹, the highest koa basal area in
the published literature.

## What is in here

`koa_survival_calibrated.R` and `koa_ingrowth.R` are the operational equations of record in R.
`koa_survival_calibrated_py.py` and `koa_ingrowth.py` are their Python carriers,
`koa_projector.py` is the stand projector that consumes them, `koa_equations.py` holds the static
and increment components, and `koa_params.py` is the single place the deployed constants live.
`test_engine_equivalence.py` reconciles the R and Python transcriptions against each other and is
the reason the two are known to agree rather than assumed to.

## Verification standing behind this snapshot

The deposit tree these files come from passed a full gate battery on 19 August 2026. Gates 1 and
1c through 1j ran on the Ohio Supercomputer Center Cardinal cluster under R 4.5.2 (job 13729394)
and all pass: the manuscript parameter tables match the deployed vectors, the deployed constants
reconcile across every carrier, and the renormalization gate includes a direct injection test for
the one branch that the ordinary allocation path cannot reach. Gate 3 (regression against the
prior deliverable, paired plot-level bootstrap), gate 4 (magnitude against observed anchors), the
interval and input gates, and the engine equivalence test all pass as well. The R and Python
allocators agree to a maximum absolute difference of 4.4e-16 across the tested cases.

## Relationship to pull request #31

Pull request #31 on this repository carries a validation harness under `dev/validation/koa_stress_test/`
whose copies of `koa_equations.py` and `koa_projector.py` predate this snapshot and differ from it.
Those copies are the state the stress test was run against and are correct as a record of that run;
they are not the equations of record and should not be read as such. This directory supersedes them
for any question about what the model currently does.
