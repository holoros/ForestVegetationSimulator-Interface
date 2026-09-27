# RUN.md - koa_loso_origin_20260926

Purpose: PREREG-KOA-01 variant C, leave-one-source-out test of the koa v102 stand-origin
calibration multipliers, with installation-cluster bootstrap intervals.

- Date: 2026-09-26
- Host: ifm-kershaw (firebreather), Debian 11, 8 cores, 94 GiB
- R: 4.5.1 (2025-06-13); packages: nlme (base R otherwise), parallel for forking
- Seed: 20260926 throughout. Bootstrap B = 5,000 for stages A, B, D; 200 refits per fold stage C
- Scripts: C_loso.R (stages A, B, C), D_multistart.R (stage D)
- Launch: setsid nohup Rscript C_loso.R (NB=5000 NB_REFIT=200 CORES=7) > run.log
          setsid nohup Rscript D_multistart.R (NB=5000 CORES=7) > runD.log
- Wall time: stage A about 2 min per response, stage B about 20 s per fold refit,
  stage D about 1 min per fold (four starts in parallel plus 5,000 resamples),
  stage C 5 to 17 min per fold and left running
- Input md5s: see INPUT_MD5.txt. Inputs are read-only from ~/jobs/koa_v102_20260918/track2/inc.
  Nothing outside ~/jobs/koa_loso_origin_20260926 was written.
- Restricted data: none exported. The V102 increment frames carry no coordinate columns and both
  scripts assert that before use. Only origin-level aggregate multipliers, interval bounds and
  cluster counts are written; no per-installation or per-plot values.
- Result: RESULT_VARIANT_C.md

## GitHub and Zenodo

Both pending Aaron's explicit go-ahead, not skipped on Claude's judgment.
- GitHub: not pushed. Needs Aaron's yes for a session PAT and a decision on the owning repo.
- Zenodo: not applicable as it stands. This is a pre-registered methodological check on an
  existing deposit, not a new citable product, and the pre-registration states the deposit is
  untouched by all three variants. If variant C's result is written into the manuscript, the
  tables here become supplemental material and should ride along with the manuscript's own
  deposit version rather than getting a deposit of their own.
