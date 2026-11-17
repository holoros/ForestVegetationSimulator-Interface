# Forest Vegetation Simulator interfaces

This repository contains the R `rFVS` and R Shiny `fvsOL` interfaces for the US Forest Service Forest Vegetation Simulator. The `main` branch holds the interface source. The `ClaudeDevelopment` branch also contains active growth and yield development and research records; the two branches currently differ substantially. Do not assume that a model documented on `ClaudeDevelopment` is integrated into the `main` branch interface.

## Koa growth and yield system

The current standalone *Acacia koa* annual tree growth and mortality system is **version 1.14.1** (November 15, 2026). Its [source, equations, quick start, evidence and limitations](https://github.com/holoros/ForestVegetationSimulator-Interface/tree/ClaudeDevelopment/tools/koa/2026-11-11_final-equations) are on `ClaudeDevelopment`. The [changelog](https://github.com/holoros/ForestVegetationSimulator-Interface/blob/ClaudeDevelopment/tools/koa/2026-11-11_final-equations/CHANGELOG.md) traces changes from earlier releases. The version of record is [Zenodo DOI 10.5281/zenodo.24259455](https://doi.org/10.5281/zenodo.24259455).

The reference implementation is `koa_step_rdbyi.R` with coefficients in `koa_rdbyi_equations.csv`. Its fitted height increment is the default. Natural-stand ingrowth is an exploratory scenario assumption. Natural stands failed most benchmark tests, and only five benchmark plots extend beyond ten years; 40- and 100-year projections are extrapolations. The model has no fitted volume or carbon equation and is not validated for mixed stands. The research README reports the thinning correction, benchmark results, coverage, and further domain limits.

The Koa research source is a standalone model record. Integration with `fvsOL` or `rFVS` should be assessed separately before relying on the interface to reproduce its projections. Manuscript and supplement drafts are linked from the research folder; publication or coauthor approval should be checked separately.
