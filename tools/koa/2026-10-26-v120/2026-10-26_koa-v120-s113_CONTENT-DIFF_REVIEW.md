# Koa manuscript v120 and supplement s113: content diff and review record (October 26, 2026)

v120 replaces v119, and s113 replaces s112. Every v119 section, table, figure, number, and reference carries forward. Nothing was removed except one duplicated affiliation line on the named title block and the phrase "rather than hidden" in S8. The cover letter and title page are v120. Figures are unchanged (v117 set). Do not submit v119 or s112.

Build: `tools/2026-10-26_v120_build/build_v120.py` (applied to the v119 and s112 docx with docedit.py, every edit anchored on text that occurs exactly once). Review record: `reviews/2026-10-26_koa-v120_*` (VERIFY_R1, REDTEAM_A_R1, REDTEAM_B_R1, ADJUDICATION_R1, VOICE_R1, REPAIR_ATTACK_R1, round-state.json).

## Process

Mode: gates batched, gate summary only. One round of the adversarial protocol on v119 and s112, run on a canary copy with three planted defects (an abstract value 58% changed to 85%, the ln(BAL + 1) coefficient order swapped, Woollons 1998 changed to 2008). All three were caught by the verifier and by red team B, and the coefficient swap by red team A, so the round counts. Four fresh agents ran in parallel (verifier with independent claim extraction and reference cross-check, a framing-blind red team on Methods and Results only, a full-package red team on framing, disclosure and journal compliance, and a voice pass), then a fresh adjudicator re-derived every finding against the real files, I repaired, and a fresh repair attacker checked the diff and the frame. Firebreather was reachable, so the four findings that needed the deposit code or the calibration frame were resolved there rather than left open.

Adjudication: 48 findings, 14 confirmed, 22 rejected, 12 wording. Repair attack: no new factual, sign, method, or disclosure defect; four should items, all applied. Round 2 was not needed because the repair attack found no new confirmed defect.

## Confirmed defects fixed

| ID | Where | Change | Evidence |
|---|---|---|---|
| V-C4 | Table 5 caption, 4.6 | Plantation record floor 158 to 109 Mg ha⁻¹ (158 is the PSP network floor only; KMR PSP extends planted support to 109, as 3.1 and Table 6 say). The Table 5 note and the 3.1 PSP sentence keep 158 to 561 because they describe the PSP network. | Table S12 (KMR PSP 366 calibration records) |
| V-C5 | Table 6 | "Source ratios 0.88 (DOFAW) to 1.38 (KMR PSP)" to "0.44 (DOFAW planted) to 1.38 (KMR PSP)"; 0.88 matched nothing. | Table S12: 0.961/2.193 = 0.44, 3.026/2.193 = 1.38 |
| V-C6 | 3.5 | "QMD does not fall with density" to "QMD at age 40 is not ordered by initial density ... (Table S31)". | Table S31: natural 35.2, 34.8, 36.3, 40.5; planted 47.9, 45.1, 44.5, 47.8 at age 40 |
| V-6209 | 3.1 | "the 6,209 diameter increment records of the original frame" (a frame absent from Table S33) to "the remaining 4,715 records of the diameter calibration frame"; the ranges 557 to 6,339 mm yr⁻¹, 10.8 to 19.5 °C, and BYI 109 to 691 Mg ha⁻¹ are unchanged. | firebreather, `koa_v103_20260930/frames/final/dDBH_NO_v103_model.csv`: 4,971 records with origin minus Kulani 12 (101) and Waiakea 24 (155) = 4,715; BYI 109.3 to 691.2, rain 557.0 to 6,338.5, temp 10.8 to 19.5 |
| A3a | 2.6, S5, Fig. 5 caption | Uneven-aged starting list stated: a single class of 500 stems ha⁻¹ at 8.0 cm DBH (S5 adds crown ratio 0.6 and height from Eq. 2). | `engine_v103/regenerate_uneven_aged.py` init_stand(): dbh 8.0, expf 500, cr 0.6, ht from predict_HT; make_tableS14.py uses the same list |
| B2 | 2.6, S3.3 | Eq. 7 definitions reconciled. The fitting BA.perc is the strictly smaller share (a percentile); the simulator computes the expansion-weighted share of the other stems at least as large, which is 1 − BA.perc, not BA.perc. 2.6 now reads "The quantity 1 − BA.perc is the expansion-weighted share ... at least as large", and S3.3 "The simulator now returns 1 − BA.perc as (W≥,i − wi)/(W − wi)". BAL = (1 − BA.perc) × BAPH stands. | `koa_equations.py` bal_percentile_fraction_weighted (share with DBH ≥ DBH_i; equal weights give (r_ge − 1)/(n − 1) = 1 − (r_min − 1)/(n − 1)) and stand_bal |
| A6c | Table S20 | Floors 0.003 and 0.006 yr⁻¹ now carry their provenance: carried from the original simulator (koa_survival_calibrated.R in the deposit) rather than estimated from the data. | `koa_params.py` BASE_NAT, BASE_PLT, citing koa_survival_calibrated.R line 482 |
| B4, B12 | References (main and supplement) | [dataset] entry moved to alphabetical position (after Weiskittel 2011 in the main text, before Wilton 2015 in the supplement) and now cites the version DOI 10.5281/zenodo.23399505 with Version 1.9.6. The concept DOI stays in Data and code availability. BLIND files keep their withheld entry. | guide: alphabetical then chronological, version plus persistent identifier |
| B14 | S7.2 | "The highest published koa basal area, 42 m² ha⁻¹" to "The 42 m² ha⁻¹ reported for natural koa stands", since the main text cites 78.8 (Scowcroft et al., 2010). | ms 3.5 |
| B18 | 2.4.3 | Heading restored to Heading 3 style (was bold body text). | rendered p. 10 |

## Wording items applied

2.6: planted rate "left unscaled, a choice made on the original covariates and not revalidated on the recomputed system (Section S4.3; Table S23)" (A5); the −1.92 Reineke slope now sits beside the −1.43 (−1.68 to −1.20) boundary fitted at τ = 0.99 on the original covariates (Section S7.2) (A6b); "the calibration below" to "the origin calibration of Section S3.2" (B25). Table 6: Stage 3 data cell now says the deployed vector was fitted to the 4,911-record sample before deduplication, with the refit on 4,223 records keeping every sign (A10); basal area "equivalent in the mean but not in slope when origins are pooled" (A12). Table S16 note: HCB rows are the mixed-effects fit, not the deployed crown vector (A13). Cover letter: "yet, to our knowledge, it has had no growth and yield model" (B9). Title page: AI declaration matched to the manuscript wording (B21), Oxford commas in the CRediT prose (B22). Duplicate corresponding affiliation line removed from the named manuscript (B23).

## Voice pass

Slop check (manuscript register) on v120: lexical 0.0, rhetorical 0.6, mean 26.1 words per sentence (v119 was outside the band at 31.5), SD 16.6, no em dashes, no British spellings outside one quoted reference title. Applied: 23 main-text splits and small fixes (M1, M4, M5, M8 to M14, M16 to M18, M20 to M27 of VOICE_R1), 14 supplement edits including 47 serial commas and the 19 to 22°N range, and four cover letter edits (merge, two serial commas, the colon). Not applied: M2, M3, M7, M15, S11 (flagged RISK), M19 (the repair attacker judged "For the same reason" a manufactured link, so the original sentence stands), S4 (file pointer), C2 beyond its comma (the "refitted, re-solved, respecified" terms mirror the manuscript's method statements), and M6 and the B9 clause in 2.6, because the 90 cm sentence is final at Aaron's instruction. No number, citation, hedge, or direction changed, checked by numeric multiset diff of every file pair.

## Rejected findings worth knowing

The framing-blind red team argued (A1) that the site gradient rests on the 0.305 ln(BYI) coefficient from the superseded covariates, (A2) that the BYI unit omits the fourfold subplot expansion, (A4, A8) that the level factor and ceilings are undisclosed. All four dispute standing decisions whose disclosures are present (2.4.2, 3.3.2, 4.6, 2.3 to S2.1, 3.3.3, 2.6). A2 remains the reader-comparison risk flagged on October 21. The 3.4 cm natural thinning gain is correct on unrounded values (38.111 − 34.748 = 3.363) even though Table S31 rounds to 3.3. The largest-tree diameters 56.4 and 57.7 cm and the 68.9 to 69.4 cm planted range were verified on firebreather (SC_trajectories.csv, DBHMAX at age 40).

## Numbers

Main text 9,896 words (v119 9,839), abstract 300, 8 keywords, 6 tables, 6 figures, 66 references, supplement 33 tables and 8 figures. Named 60 pages, blind 59, supplement 55. The cover letter's "about 9,900 words" still holds. md5: v120 named 9d4d3df78d2c9646b370caed707fc940, blind 2669b7dd37426250216c5e1a28095492, s113 named 4483eaea4d28ba1d52be9609dc67808c, blind 1d43fa56c8c7b82bb822fd2e1b07551c.

Blind sweep of both BLIND files: hits are only bibliographic citations of published work (Weiskittel et al. 2011 and 2016, Chen et al. 2023, Willson et al. 2019, Salas-Eljatib and Weiskittel 2020, Owen et al. 2022 author list), no affiliation, no company name, no DOI.

## Zenodo

The staged update package is rebuilt as `tools/2026-10-26_v120_zenodo/zen196_update_20261026.tgz` with s113 as koa_supplemental.docx (md5 4483eaea4d28ba1d52be9609dc67808c), MD5SUMS and SHA256SUMS regenerated, and description.html naming s113 and v120. The script is unchanged and still never publishes. Replace the October 21 extraction on Cardinal with this one before running it.

## Still yours

1. Postal addresses for Forest Solutions Inc. and Midgard Natural Resources LLC (guide requires full postal addresses). A US Department of Labor job order lists Forest Solutions, Inc. at Kailua-Kona, HI 96740 (https://seasonaljobs.dol.gov/jobs/H-400-26001-523702); confirm with Irene or Aviva before use. Nothing public was found for Midgard; Ben supplies it.
2. Kulani plot 12 and Waiakea plot 24 coordinates. The disclosures stand in 3.1, 3.3.2, 4.3, 4.6, and S6.2. A coordinate correction would mean re-extracting covariates, refitting, and rerunning projections, which is a new release, not a pre-submission fix.
3. Zenodo: extract the new tgz on Cardinal, run zen196_update.py with your token, review draft 23399505, publish.
4. Merge PRs 9, 10, and 13; submit.
