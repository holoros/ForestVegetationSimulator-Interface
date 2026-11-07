# koa submission build, November 7, 2026

Scripts behind manuscript v125 to v132 and supplement s118 to s123 (Forest Ecosystems submission), the Zenodo 1.12.1 update and publication (DOI 10.5281/zenodo.24013562), and the Zenodo 1.12.2 version that carries the submitted supplement s123 (DOI 10.5281/zenodo.24039072).

- `2026-11-07_v125_build` to `2026-11-07_v132_build`, `2026-11-07_s118_build`: anchored docx edits from each prior build, using `docedit.py` (copied here once). Each script's docstring names its sources and edits.
- `2026-11-07_firebreather_scripts/zenodo_1.12.1`: draft creation, text updates (README, CITATION.cff, FILE_MAP, SHA256SUMS, DEPOSIT_CHANGELOG), file pushes, audit and publication of 1.12.1.
- `2026-11-07_zenodo_1.12.2`: `zen1122_draft.py` (new version, reserved DOI), `texts_1122.py`, `push_1122.py` and `publish_1122.py`.
- `2026-11-07_firebreather_scripts/containment_check`: c1.py (tree-level planted flag, superseded) and c2.py (plot-level origin), the check that withdrew a planned Section 3.5 sentence.

The Zenodo scripts read the token from ~/.config/zenodo/token on the server; no token is stored here. Manuscript files, PDFs and data are not in this folder.
