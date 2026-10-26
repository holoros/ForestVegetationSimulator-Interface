# ADJUDICATION_R1: koa GY manuscript, round 1

Adjudicated against the REAL files in `real/` (ms.md, supp.md, cover.md, title.md) and the guide extract `/mnt/user-data/uploads/Koa/2026-09-01_FOREST_ECOSYSTEMS_GUIDE_EXTRACT.md`. Arithmetic and text checks: `adjud_work/adjud_checks.py` (python3 -I), output quoted below where used. Canary items (abstract "85%", the "−0.182 and −0.431" order in 3.3.2, "Woollons, 2008") were verified absent from the real files and are not adjudicated. Standing author decisions (i) to (iv) were applied as instructed.

Line numbers refer to `real/ms.md`, `real/supp.md`, `real/title.md`, `real/cover.md`.

## 1. Ruling table

| ID | Source | Ruling | Reason (one line) | Fix |
|---|---|---|---|---|
| V-C4 | VERIFY C4 | CONFIRMED | Planted-record BYI floor is 158 in Table 5 caption and 4.6 but 109 in 3.1 and Table 6 | Table 5 caption and 4.6: "158" to "109" (exact text in §2) |
| V-C5 | VERIFY C5 | CONFIRMED | "0.88 (DOFAW)" is not in Table S12; the DOFAW ratios are 0.97 (natural) and 0.44 (planted) | Table 6: "Source ratios 0.44 (DOFAW planted) to 1.38 (KMR PSP) (Table S12)" |
| V-C6 | VERIFY C6 | CONFIRMED | Table S31 QMD at age 40 falls 250 to 500 natural (−0.4) and 300 to 1,200 planted (−3.4); S7.3 says "not ordered by density" | 3.5: "QMD at age 40 is not ordered by initial density, because ... (Table S31)." |
| V-C7 | VERIFY C7 | CONFIRMED | 38.1 − 34.8 = 3.3, not 3.4 (planted 3.3 and 7.5 reproduce) | 3.5: "3.3, 7.5, and 3.3 cm" (or needs analysis: unrounded difference ≥ 3.35 would justify 3.4, then Table S31 needs a second decimal) |
| V-6209 | VERIFY U2 / RT-B 7 | CONFIRMED | "6,209" appears nowhere in supp.md, is not a Table S33 frame, and exceeds the 4,790-record original fit; 557 mm is also untabulated | Needs analysis: identify the frame (or recompute on the 4,971-record calibration frame of Table 2 without Kulani 12 and Waiakea 24) and add it to Table S33 |
| A1 | RT-A 1 | REJECTED | Author decision (iv); departure and the halved refit are disclosed in 2.4.2, 3.3.2, Abstract and 4.6 | none |
| A2 | RT-A 2 | REJECTED | Author decision (i); the 2.3 clause "(Section S2.1)" exists and S2.1 states the fourfold omission | none |
| A3a | RT-A 3 (initial list) | CONFIRMED | Uneven-aged initial stems ha−1 and QMD appear nowhere in ms.md or supp.md (2.6, S5, Fig. 5, Table 5, Table S30 all silent) | Needs analysis: the initial list (stems ha−1, QMD) from the deposited projector configuration, stated in 2.6, S5 and the Fig. 5 caption |
| A3b | RT-A 3 (shielding mechanism) | REJECTED | The "recomputation" is the identity BA = N π/4 QMD²; the mechanism is conjecture; 3.3.4 already says the rows "demonstrate model structure only" | none (optional analysis, not forced) |
| A4 | RT-A 4 | REJECTED | Author decision (ii); direction of the out-of-sample error is stated in 4.4 and 4.6; 3.4 does not cite Table S28 nor claim held-out trajectory errors on the deployed engine | none |
| A5 | RT-A 5 | WORDING | S4.3 and Table S23 state the planted multiplier was rejected on the original covariates and "not run" on the recomputed system; 2.6 omits this | 2.6 clause (§2) |
| A6a | RT-A 6 (Stage 1 inert) | REJECTED | 2.6 is true as written; 0.378 to 0.403 is a reviewer-added quantification, not a textual defect | none |
| A6b | RT-A 6 (−1.92 vs −1.43) | WORDING | S7.2 states the deployed slope is steeper than the τ = 0.99 boundary interval; 2.6 gives −1.92 without that comparison | 2.6 clause (§2) |
| A6c | RT-A 6 (floors) | CONFIRMED | 0.003 and 0.006 yr−1 have no stated provenance anywhere in the package (Table S20 gives values only; S8 points to an external forensics document) | Needs analysis: state their origin in the Table S20 description |
| A7 | RT-A 7 | REJECTED | 2.6 lists what is drawn, what is fixed and what is excluded; the Wald understatement is in the Table 4 caption and S5; the ±12% form factor is in 4.5 and Conclusions (CF inertness: optional needs analysis) | none |
| A8 | RT-A 8 | REJECTED | Author decision (iii); 2.6 says the projections (not only limits) "are conditional on them"; Table 5 note says intervals carry parameter and sampling uncertainty only | none |
| A9 | RT-A 9 | REJECTED | (a) disclosed in the cited Table S32 caption; (b) disclosed in 2.6 and 4.5; (c) the solve is defined through the simulator's annual update, which S5 states includes the clip | none |
| A10 | RT-A 10 | WORDING | Table S15 note: deployed vector fitted to the 4,911-record pre-deduplication sample; Table 6 attributes 4,223/877/51 to the deployed Stage 3 | Table 6 cells (§2); confirm which vector produced 877.5 and 0.78 |
| A11 | RT-A 11 | REJECTED | All four points disclosed (Table 4 caption, Table S13, Table S33 caption, Table S8 caption); presentation preference | none |
| A12 | RT-A 12 | WORDING | Table 6 BA cell omits the slope and origin failures stated in 3.4 and Conclusions; smallest passing region not forced | Table 6 cell (§2) |
| A13 | RT-A 13 | WORDING | Table S16 caption labels population-average as "(deployed)" but its HCB row (0.407) is the mixed fit, not the deployed vector (0.244, Table S9); S3.1 acknowledges this for S8/S3.5 only | Table S16 note (§2) |
| A-struct | RT-A structural note | REJECTED | 2.6 already states V uses Eq. 2 at the list QMD (Eq. 10); S5 step 3 states no blending with static height | none |
| B2 | RT-B 2 | CONFIRMED | 2.6 and S3.3 define the simulator BA.perc as the share of other stems "at least as large", the exact complement of the fitting percentile (strictly smaller); "reduces to the rule of record" is false as written | Needs analysis: one check of koa_projector.py/HiGy.R; candidate text in §2 |
| B4 | RT-B 4 | CONFIRMED | [dataset] Weiskittel 2026 sits after Wiedenbeck (line 379); alphabetical-chronological order puts it after Weiskittel 2011 (line 373) | Move the entry to follow line 373 |
| B5 | RT-B 5 | CONFIRMED | Guide: "affiliations with full postal addresses"; b and c carry only state and country | Needs author input: city, state, postal code for Forest Solutions Inc. and Midgard Natural Resources LLC (title.md 9, 11; ms.md 7, 9) |
| B6 | RT-B 6 | CONFIRMED | Guide extract line 9: Acknowledgements "never on the title page"; title.md lines 23 to 25 carry them; ms.md line 225 already has them | Delete title.md lines 23 to 25 |
| B7 | RT-B 7 | CONFIRMED | Same item as V-6209 | see V-6209 |
| B9 | RT-B 9 | WORDING | cover.md is unhedged where ms.md says "to our knowledge"; "original simulator" (ms 117) is identified only in S8 | cover.md and 2.6 (§2) |
| B10 | RT-B 10 | REJECTED | Supplement-cited figures in the Discussion are a style judgment; none is a new unsupported result | none |
| B11 | RT-B 11 | REJECTED | Author decision (ii); 3.3.3 states 2.40 "without one interval that spans a recorded removal year (Section S1.1)" and 2.6 states the Stage 1 frame excludes removals | none |
| B12 | RT-B 12 | WORDING | The entry pairs "Version 1.9.6" with the concept DOI; the version DOI is in the package (Data availability) | [dataset] entry (§2); "earlier versions" pointer optional needs analysis |
| B13 | RT-B 13 | REJECTED | 300 whitespace tokens, no markup-induced token difference; 300 lies within "200 to 300" | none |
| B14 | RT-B 14 | CONFIRMED | supp S7.2 "highest published koa basal area, 42" contradicts ms 3.5's Scowcroft et al. (2010) 35.7 to 78.8 | S7.2 sentence (§2) |
| B15 | RT-B 15 | REJECTED | Whether the cited sources support "one of the steepest ... on Earth" cannot be checked from the package; no demonstrated defect | none (author source check advised) |
| B16 | RT-B 16 | REJECTED | Same: not checkable from the package | none |
| B17 | RT-B 17 | REJECTED | "Five individual-tree equations" is accurate; Eqs. 6 and 9 are stand-level and are named in 2.6 | none |
| B18 | RT-B 18 | CONFIRMED | ms.md line 81 "**2.4.3 Survival equation**" is bold text; 2.4.1, 2.4.2, 2.4.4 are "### " headings | Apply Heading 3 style |
| B19 | RT-B 19 | REJECTED | Checklist for the blinded sibling, which is not in the package; not a defect of these files | none |
| B20 | RT-B 20 | REJECTED | The sponsor-role sentence is a role-of-funding-source statement, which belongs in Funding; the competing interest declaration already names the commission and use | none |
| B21 | RT-B 21 | WORDING | AI declarations differ between title.md line 37 and ms.md line 253 | title.md (§2) |
| B22 | RT-B 22 | WORDING | CRediT formatting differs between title.md line 21 and ms.md line 231 | Use the ms.md form in title.md |
| B23 | RT-B 23 | WORDING | ms.md line 13 repeats the affiliation of line 5 | Delete ms.md line 13 |
| B24 | RT-B 24 | REJECTED | Prices per board foot are a quoted trade unit from the cited source, not a measurement | none |
| B25 | RT-B 25 | WORDING | "the calibration below" is a positional cross-reference; guide requires numbered ones | ms.md line 73 (§2) |
| B26 | RT-B 26 | REJECTED | The journal title is "Small-scale Forestry" (lowercase s); DOIs are case-insensitive | none |
| B27 | RT-B 27 | WORDING | Table 1 header uses "Mg ha⁻¹" (Unicode) where every other table uses "ha^−1^" | ms.md line 420 (§2) |
| B28 | RT-B 28 | REJECTED | Image files are not in the package; cannot be adjudicated (verify before upload) | none |
| B29 | RT-B 29 | REJECTED | No defect asserted | none |

## 2. Evidence and fixes per item

### V-C4. Planted support lower bound 158 vs 109 (CONFIRMED)

Quotes (ms.md):
- 3.1, line 127: "PSP intervals make up 3,433 of the 3,900 planted diameter records of the calibration frame, almost all from stands younger than 18 years at a BYI of 158 to 561 Mg ha^−1^. The KMR PSP installation extends planted support down to a BYI of 109 Mg ha^−1^"
- Table 5 caption, line 515: "Every planted row lies beyond the plantation record, which holds stands younger than about 18 years on a BYI of 158 to 561 Mg ha^−1^"
- Table 5 Notes, line 557: "planted rows at a BYI of 100 Mg ha^−1^ (below the PSP BYI range of 158 to 561 Mg ha^−1^) are extrapolation"
- 4.6, line 213: "Planted rows below a BYI of 158 Mg ha^−1^ remain untested against plantation observations."
- Table 6, line 568: "Planted support below about age 18 on a BYI of 109 to 561 Mg ha^−1^"

Checked: Table S12 shows KMR PSP planted with 366 calibration records, so the KMR PSP installation is part of the plantation record used in calibration; 3.1's "109 to 691" without Kulani 12 (BYI 25) and Waiakea 24 (BYI 93, S6.2 "next lowest 92.7") is consistent with 109 being the KMR PSP minimum. The 158 floor is correct only for the PSP network; the Table 5 caption and 4.6 attach it to the "plantation record" and to "plantation observations", which per 3.1 and Table 6 extend to 109.

Fix (two sentences):
- Table 5 caption: "Every planted row lies beyond the plantation record, which holds stands younger than about 18 years on a BYI of 109 to 561 Mg ha^−1^, so the planted rows describe the behavior of the calibrated equations, and their origin constants come almost entirely from the plantation permanent sample plot and Keauhou--Mauna Loa Restoration networks."
- 4.6: "Planted rows below a BYI of 109 Mg ha^−1^ remain untested against plantation observations."
(If the authors intend the PSP benchmark plots specifically, the alternative that keeps 158 is "Planted rows below the PSP BYI range of 158 to 561 Mg ha^−1^ remain untested against plantation observations", matching the Table 5 note; either way the Table 5 caption must read 109 because it says "plantation record".)

### V-C5. Table 6 "0.88 (DOFAW)" (CONFIRMED)

Quote (ms.md Table 6, line 568): "Source ratios 0.88 (DOFAW) to 1.38 (KMR PSP)".
Table S12 "Within over pooled", ΔDBH: All but FIA natural 0.98; DOFAW natural 0.97; FIA natural 1.27; DOFAW planted 0.44; KMR PSP planted 1.38; PSP planted 1.00. Script: min = DOFAW planted 0.44, max = KMR PSP planted 1.38. The four other "0.88" strings in supp.md (lines 105, 388, 848, 1108) are a Ligot AUC range, a Spearman interval, a published AUC and a Table S29 cell, none a source ratio. Discussion 4.3 (line 195) is consistent with 0.44: "the planted diameter constant ranges from 0.96 on the DOFAW planting to 2.19 on PSP and 3.03 on KMR PSP" (0.961/2.193 = 0.44).

Fix (Table 6, diameter increment row, Boundary of use): "Source ratios 0.44 (DOFAW planted) to 1.38 (KMR PSP) (Table S12)".

### V-C6. "QMD does not fall with density" (CONFIRMED)

Quote (ms.md 3.5, line 173): "QMD does not fall with density, because density-dependent mortality allocated by Eq. 5 removes the smallest stems fastest."
Table S31 QMD 40 (cm): natural 250/500/1,000/2,000 stems = 35.2, 34.8, 36.3, 40.5; planted 300/600/1,200/2,400 = 47.9, 45.1, 44.5, 47.8. QMD 100: natural 59.0, 60.0, 65.6, 79.0; planted 62.0, 58.8, 57.3, 57.8. Script: natural age 40 falls 250 to 500 (−0.4); planted age 40 falls 300 to 600 (−2.8) and 600 to 1,200 (−0.6); planted age 100 falls 300 to 600 (−3.2) and 600 to 1,200 (−1.5). Section S7.3 (line 177): "The largest tree reaches nearly the same diameter whatever the initial density, whereas QMD at age 40 is not ordered by density." The paragraph in 3.5 covers both origins (Fig. 6), so the planted rows alone contradict the sentence.

Fix (3.5): "QMD at age 40 is not ordered by initial density, because density-dependent mortality allocated by Eq. 5 removes the smallest stems fastest (Table S31)."

### V-C7. Natural thinning QMD gain 3.4 vs 3.3 (CONFIRMED)

Quote (ms.md 3.5, line 173): "raised QMD by 3.3, 7.5, and 3.4 cm, a gain that shrinks to 2.4 to 5.9 cm by age 100 (Table S31)".
Table S31: natural unthinned QMD 40 = 34.8, thinned to 250 at age 15 = 38.1; script 38.1 − 34.8 = 3.3. Planted 47.8 − 44.5 = 3.3 and 52.0 − 44.5 = 7.5 reproduce; age 100 gains 2.4, 2.6, 5.9 reproduce "2.4 to 5.9".

Fix (3.5): "raised QMD by 3.3, 7.5, and 3.3 cm". Rounding of unrounded values could reach 3.4 only if the unrounded difference is at least 3.35 (the tabulated pair allows 3.20 to 3.40); if the registry holds such a value, keep 3.4 and give Table S31 a second decimal for that pair. Otherwise 3.3.

### V-6209 / B7. "6,209 diameter increment records of the original frame" (CONFIRMED, needs analysis)

Quote (ms.md 3.1, line 127): "Without these two plots, the 6,209 diameter increment records of the original frame span 557 to 6,339 mm yr^−1^, 10.8 to 19.5 °C, and a BYI of 109 to 691 Mg ha^−1^."
Script: "6,209" absent from supp.md; "557" absent from supp.md; Table S33 frames are 13,122 / 5,420 / 4,813 / 4,792 / 4,971 / 4,992 / 4,790 / 4,670, none 6,209; 6,209 > 4,790 (the "Deployed fit" original frame), so it cannot be that frame minus two plots. ms.md line 73 says "Table S33 reconciles every frame size reported here", which this count breaks. Table 2's 400 mm / 9.4 °C / BYI 25 minima are on the 4,971-record calibration frame.

Fix: needs analysis. Either name the frame to which 6,209 belongs and add it to Table S33, or recompute the count and the three ranges on the 4,971-record calibration frame of Table 2 without Kulani plot 12 and Waiakea plot 24 and replace the sentence with those values.

### A1. Site gradient conditional on the retained diameter vector (REJECTED, author decision iv)

Quotes (ms.md): 2.4.2, line 79: "The diameter vector is the original fit to 4,790 consecutive intervals, which was not among the named candidates, so its deployment departs from the pre-specified rule." 3.3.2, line 145: "A live-list diameter refit halved the diameter coefficient to 0.140 (−0.167 to 0.417) (Section S3.2)." Abstract, line 17: "an effect whose interval only just excluded zero and whose coefficient halved when refitted with the projection competition index". 4.6, line 213: "Only the diameter site term fitted on the original covariates has an installation-level interval that excludes zero (Section 3.3.2)." 4.1, line 179: "as its positive site terms imply, ordered projected volume by BYI".
Checked: the departure from the selection rule is disclosed in 2.4.2 as decision (iv) requires; the 58% is attributed to "the deployed equation"; the halving is stated. The requested conditioning sentences dispute the decision, not the disclosure. Script: 4.5^0.305 = 1.582, 4.5^0.140 = 1.234 (reviewer's 1.23 is right but changes nothing textual).

### A2. BYI unit (REJECTED, author decision i)

Quote (ms.md 2.3, line 51): "taken as BYI in Mg ha^−1^ on the scale of the Eq. 1 biomass frame (Section S2.1)". Script confirms the clause exists. supp.md S2.1, line 43: "BYI is reported in Mg ha^−1^ on the scale of the Eq. 1 frame, whose subplot biomass sums apply the whole-plot expansion factor without the fourfold subplot expansion". Both halves of decision (i) are in place.

### A3a. Uneven-aged initial list not stated (CONFIRMED, needs analysis)

Quotes: ms.md 2.6, line 105: "uneven-aged stands from a single cohort that acquires structure through recruitment (Section S5)". supp.md S5, line 129: "Uneven-aged stands start as a single cohort and acquire structure through recruitment." Fig. 5 caption (line 409) gives 500 and 1,200 stems ha−1 for the even-aged columns and nothing for the uneven-aged column. Table 5 caption (line 515) gives even-aged starts only. Table S30 caption (line 1127) and Table S24 are silent. Grep of ms.md and supp.md for any stems ha−1 or QMD attached to "uneven-aged" or "single cohort" returns nothing (script). Methods must allow independent reproduction (guide line 13).

Fix: needs analysis (read the initial list from the deposited projector configuration). Then 2.6: "and uneven-aged stands from a single cohort of [N] stems ha^−1^ at a QMD of [x] cm that acquires structure through recruitment (Section S5)", the same values in S5 line 129, and in the Fig. 5 caption "uneven-aged natural stands with ingrowth ([N] stems ha^−1^ at start)".

### A3b. Shielding mechanism (REJECTED)

Script: 94 × π/4 × 0.798² = 47.0 m² ha−1 against the tabulated 46.8; this is the definition of QMD and says nothing about recruits. The mechanism is a hypothesis. 3.3.4 (line 157): "the uneven-aged rows of Table 5 demonstrate model structure only." No textual misstatement.

### A4. Out-of-sample direction and Table S28 provenance (REJECTED)

Quotes (ms.md): 4.4, line 201: "On the FIA subplots, however, the deployed rate overprojects mortality at high density (Section S6.1)." 4.6, line 213: "the system overpredicts QMD by 3.9 cm and underpredicts survival by 0.18." 3.4, line 165: "The level factor solved without each natural installation ranges from 2.36 to 3.03 against 2.54 pooled (Section S4.3)." Script: Table S28 is not cited anywhere in ms.md; 2.6 line 121 separately says the held-out solve was done (Section S4.3) and that stand-level calibration "was tested on the original covariates (Section S6.2)". supp.md S4.3 line 125 confirms 2.36 to 3.03 are corrected-engine values. The 3.4 sentence claims nothing about held-out trajectory errors. Decision (ii) governs the level.

### A5. Planted rate unscaled: decision made on the original covariates (WORDING)

Quotes: ms.md 2.6, line 117: "whereas the planted rate is left unscaled (Section S4.3)." supp.md S4.3, line 125: "The planted multiplier (3.50, 2.58 to 4.88) was not deployed, because on the original covariates its counterpart moved planted validation survival from equivalent to 0.243 below observed and broke the site ordering of planted volume". Table S23 (line 975), planted multiplier row: "not run ... not run ... not run ... Not deployed (planted order broken on the original covariates)", with "Not run marks a candidate that was not projected on the recomputed system." The planted unscaled choice is not among the standing decisions, and the main text gives only the establishment-loss reason (4.4, line 203).

Fix (2.6): "Projected over the 24 natural plot intervals, the scaled rate underpredicts observed deaths, so the natural rate carries a level factor solved on those intervals, whereas the planted rate is left unscaled, a choice made on the original covariates and not retested on the recomputed system (Section S4.3; Table S23)."

### A6a. Stage 1 density channel (REJECTED)

Quote (ms.md 2.6, line 115): "Density therefore enters both through occurrence and through the approach to the self-thinning limit." Script with Table S24 coefficients (−1.668, +0.166, planted −0.219): occurrence 0.378 at SDI 260, 0.403 at SDI 430 (6.7% relative rise); planted 0.368 at 790, 0.372 at 862. The reviewer's numbers reproduce, but the sentence is true as written and 3.3.3 reports the +0.166 coefficient with its interval; the magnitude statement would be an addition.

### A6b. −1.92 against the fitted boundary (WORDING)

Quotes: ms.md 2.6, line 113: "so the limiting line implies a Reineke slope of −1.92." supp.md S7.2, line 167: "At τ = 0.99 the slope was −1.43 (95% interval −1.68 to −1.20), consistent with Reineke's −1.605 and shallower than the −1.92 implied by the recomputed allometry". 4.4 (line 201) gives only the −0.9 to −1.2 natural boundary and "no maximum stand density index is identifiable". The comparison is in the supplement only; adding it repeats S7.2 and adds no claim.

Fix (2.6): "so the limiting line implies a Reineke slope of −1.92, steeper than the −1.43 (95% interval −1.68 to −1.20) boundary fitted at τ = 0.99 to the plot record (Section S7.2)."

### A6c. Floor provenance (CONFIRMED, needs analysis)

Quote (supp.md Table S20, lines 906, 908): "Background mortality, natural | base_nat | 0.003 yr^−1^ | Density-independent annual mortality, natural origin"; planted 0.006 likewise. Grep for the values and for "floor" in supp.md finds no source; S8 (line 185) refers "threshold provenance for Eq. 9" to the external forensics document. ms.md 2.6 (line 115) states the values with no source. Fix: needs analysis (fitted, assumed, or carried from the original engine); add that phrase to the two Table S20 descriptions.

### A7. Monte Carlo description (REJECTED)

Quotes (ms.md 2.6, line 119): "draw the increment, height, Stage 1, level-factor, García exponent, and diameter correction factor parameters, holding the self-thinning anchor and Eq. 5 fixed (Section S5; Table S24) ... Process, BYI, and initialization errors are excluded, so the intervals describe parameter and sampling uncertainty only". Table 4 caption (line 489) states the 1.5 to 6.3 and 2.1 to 4.5 bootstrap-to-Wald ratios; S5 (line 137) states the re-solve R² of 0.990 to 0.962; 4.5 (line 209) and Conclusions (line 221) state the ±12% form factor "in addition to"/"before" the Monte Carlo intervals. The main text does list fixed items (anchor, Eq. 5) and excluded errors; the remaining asks restate the supplement. Whether the CF draw is inert under the per-row re-solve (Table S24: multiplier "re-solved per row as observed over predicted increment") cannot be settled from the text; optional needs analysis, not a defect.

### A8. Ceilings (REJECTED, author decision iii)

Quotes (ms.md 2.6, line 117): "The planted ceiling is the largest QMD observed on a natural plot-year with at least five live stems. Both ceilings lie below diameters observed in koa, which reach 230 cm, so planted projections beyond about age 40 (Section S7.2) and uneven-aged natural projections near age 100, whose upper QMD limits reach within 1.5 cm of 90 cm (Table 5), are conditional on them." Table 5 (line 554): "88.0 (62.0--88.8^a^)"; note (line 557): "The intervals carry parameter and sampling uncertainty only"; Table S24: beta_anchored "Fixed, not perturbed". The projections, not only the limits, are already stated to be conditional; the Whitesell sentence stands as decision (iii) requires; the extra flagging is a preference.

### A9. Culmination intervals, planted ages, cap placement (REJECTED)

(a) Table S32 caption (line 1237): "computed under the interior rule among replicates with an interior maximum within 100 years"; "Share without interior maximum" column 0.272/0.202/0.216 natural. 3.5 (line 169) cites Table S32 and says intervals "overlap widely", which is true. (b) 2.6 (line 105): "ages and culmination ages are relative to the start of projection"; 4.5 (line 209): "these culminations cannot be compared directly with the 40 to 60 years that sawlog quality requires". (c) 2.4.2 (line 77): the constant is "solved within origin so that the total annual increment projected through the simulator's annual crown and competition update equals the observed total"; S5 (line 131) step (2) applies "the 2 m yr^−1^ height clip" inside that annual update. The placement is therefore stated by composition; if the authors wish, one clause "with the 2 m yr^−1^ cap applied inside the solve" after confirming in code.

### A10. Table 6 Stage 3 attribution (WORDING)

Quotes: ms.md Table 6, line 572: "Stage 3: 4,223 records, 877 deaths, 51 installations" and "Eq. 5 expects 877.5 of 877 deaths and orders them at an AUC of 0.78 (Table S15)". ms.md 2.4.3, line 87: "the equation was refitted on the death response of 4,223 records carrying 877 deaths ... and the refit changed no sign of the deployed coefficients". supp.md Table S15 note (line 763): "The deployed coefficients were fitted on September 16, 2026 to the 4,911-record sample that preceded deduplication, c~0~ = −2.135 ... Refitting on the recomputed sample gives −2.454, −1.244, −0.246, 0.802, 0.164, with every sign unchanged". Table S15 row "Size and competition (adopted, Eq. 5)" carries AIC 2,992.6, out-of-installation AUC 0.787/0.776 and expected deaths 877.5 on the 4,223-record sample; an AIC requires a fit on that sample, so these are the refit's statistics (Table S16 repeats them for "4,223 ... 877 events"). The Data cell attributes the refit sample to the deployed vector.

Fix (Table 6, survival row):
- Data cell: "Stage 1: 282 plot intervals on 54 plots. Stage 3: deployed vector fitted to the 4,911-record sample before deduplication; refit on 4,223 records (877 deaths, 51 installations) keeps every sign (Table S15)"
- Key performance: "Eq. 5, refitted on the 4,223-record sample, expects 877.5 of 877 deaths and orders them at an out-of-installation AUC of 0.78 (Table S15)."
Confirm from the Table S15 job record that 877.5 and 0.78 come from the refit coefficients; if they were instead scored with the September 16 vector on the 4,223 sample, change only the Data cell.

### A11. Wald P values, tree intercept, double counting, LOIO estimator (REJECTED)

Table 4 caption (line 489) states the bootstrap-to-Wald SE ratios and points to Table S13, which holds the intervals; Table S33 caption (line 1261) states the 179/176 double contributions; Table S8 caption explains the 79.8% estimator; S3.2 (line 81) states the tree-intercept result. 3.3.1 (line 141) "79.8% ... under leave-one-installation-out cross-validation (86.2% with random intercepts)" is accurate. Adding a column to Table 4 is a presentation choice.

### A12. Equivalence regions and the Table 6 basal area cell (WORDING)

Quotes: ms.md 3.4, line 161: "Basal area was equivalent in the mean when both origins were pooled (−0.96 m^2^ ha^−1^, 90% interval −5.46 to +3.93, against ±6.77), although large plot-level errors of both signs offset (RMSE 11.9 m^2^ ha^−1^), and its slope is not equivalent (0.88, 0.11 to 2.04)." Conclusions, line 219: "basal area was equivalent in the mean, but not in slope, when origins were pooled." Table 6, line 574: "Basal area equivalent when origins are pooled (−0.96 m^2^ ha^−1^; Table S25)." The cell drops the slope qualifier the text and Conclusions carry. The smallest passing region is not in the package and is not forced.

Fix (Table 6, simulator row, Key performance): "Basal area equivalent in the mean but not in slope when origins are pooled (−0.96 m^2^ ha^−1^; Table S25)."

### A13. Crown vector and Table S16 label (WORDING)

Quotes: ms.md 2.4.1, line 65: "The deployed crown vector (RMSE 2.38 m) was retained over refits that reversed signs (Section S3.1; Table S9)." 3.3.1, line 141: "The deployed crown vector explains 24.4% of HCB variation (n = 360; Table S9)." supp.md S3.1, line 63: "The deployed crown base vector ... is not the unweighted least-squares fit of Eq. 3 (Table S9) ... Fig. S1 scores the deployed vector, whereas the HCB statistics of Table S8 and of the performance summary (Section S3.5) are the mixed-effects fit of the same form on the deposited covariates." Table S16 caption (line 765): "at the conditional (random intercepts retained) and population-average (deployed) levels", HCB population-average R² 0.407 against the deployed 0.244 (Table S9, 3.3.1). The main text is correct and points to S3.1; the mislabel is confined to Table S16.

Fix (Table S16 Notes, append): "The HCB rows are the mixed-effects fit of Eq. 3 on the deposited covariates, not the deployed crown vector, whose statistics are in Table S9 (Section S3.1)."

### A-structural. Static height in volume (REJECTED)

ms.md 2.6, line 117: "Stem volume is V = BAPH × H~Q~ × 0.40 (Eq. 10), where H~Q~ is Eq. 2 evaluated at the QMD of the list." supp.md S5, line 131: "(3) advances each height by its own increment (Eq. 8), with no blending with static height". Both facts the note asks for are stated.

### B2. Eq. 7 / BA.perc definition across 2.2, 2.6 and S3.3 (CONFIRMED, needs analysis)

Quotes:
- 2.2 (line 43): "Competition is BAL (m^2^ ha^−1^), stand basal area allocated by each stem's diameter percentile among the live stems of the plot-year (Eq. 7; Section S3.3)."
- 2.6 (line 107): "Competition is BAL = (1 − BA.perc) × BAPH (Eq. 7), stand basal area allocated by each stem's diameter percentile among the live stems of the plot-year. ... BA.perc is the expansion-weighted share of the other live stems at least as large as the subject, which matches the fitting definition when expansion factors are equal within a plot (Section S3.3)."
- S3.3 (line 85): "BA.perc is the number of records in the plot-year with a strictly smaller diameter divided by the number of records less one, (rank(DBH, ties.method = "min") − 1)/(n − 1) in R ... the deployed system uses the live-list percentile."
- S3.3 (line 91): "The simulator now returns BA.perc as (W~≥,i~ − w~i~)/(W − w~i~), the expansion-factor share of the other stems at least as large as stem i, which reduces to the rule of record when expansion factors are equal within a plot".
- Table S1 (line 258): "BAL = (1 − BA.perc) × BAPH"; line 241: "BA.perc the count percentile of Eq. 7".

Checked (script, 12 random diameters, equal weights): fitting BA.perc (strictly smaller / (n − 1)) and the "share of other stems at least as large" sum to exactly 1.000 for every stem; they are complements, not equal. 2.2 and the first sentence of 2.6 agree with the fitting definition (a percentile, so (1 − BA.perc) × BAPH is basal area in larger stems). The third sentence of 2.6 and the S3.3 "Weighted percentile in the simulator" paragraph state the complement and then claim it "matches"/"reduces to" the rule of record, which is false as written. Under that definition BAL would be basal area in smaller stems. Which text is wrong depends on the deposited code (koa_projector.py, HiGy.R), which is not in the package.

Fix: needs analysis (one check of the code). If the simulator's weight sum is over stems strictly smaller than i (the likely case, since the 0.48 to 0.50 BAL fraction and the DOFAW QMD bias correction are reported as working), the two sentences become: 2.6: "BA.perc is the expansion-weighted share of the other live stems smaller than the subject, which matches the fitting definition when expansion factors are equal within a plot (Section S3.3)." S3.3: "The simulator now returns BA.perc as W~<,i~/(W − w~i~), the expansion-factor share of the other stems strictly smaller than stem i, which reduces to the rule of record when expansion factors are equal within a plot". If the code instead sums stems at least as large, Eq. 7 in 2.6 and Table S1 must be rewritten as BAL = BA.perc × BAPH and the 2.2 wording checked against it.

### B4. Reference order (CONFIRMED)

Script: entries 58 to 63 are Weiskittel 2011, Whitesell 1990, Wiedenbeck 2017, [dataset] Weiskittel 2026, Willson 2019, Wilton 2015; the only order break in the list is Wiedenbeck → Weiskittel. Guide: "List alphabetical then chronological". Fix: move ms.md line 379 to immediately after line 373 (before Whitesell).

### B5. Affiliation postal addresses (CONFIRMED, needs author input)

Quotes (title.md lines 9, 11; ms.md lines 7, 9): "^b^ Forest Solutions Inc., Hawaii, USA", "^c^ Midgard Natural Resources LLC, New Hampshire, USA". Guide line 9: "affiliations with full postal addresses". Fix needs the city, state and postal code of each firm from the coauthors.

### B6. Acknowledgments on the title page (CONFIRMED)

Quote (title.md lines 23 to 25): "**Acknowledgments** / We thank the Hawaii Division of Forestry and Wildlife, ...". Guide extract line 9: "Acknowledgements (separate section before References, never on the title page)". ms.md line 225 to 227 carries the identical section before References. Fix: delete title.md lines 23 to 25.

### B9. Unqualified priority claim in the cover letter; "original simulator" (WORDING)

Quotes: cover.md line 7: "yet it has had no growth and yield model. This study delivers the first linked individual-tree equations and tree-list projection system for the species". ms.md line 29: "to our knowledge none has been developed for koa"; line 179: "what is, to our knowledge, the first linked individual-tree GY system"; line 219: "This study delivers, to our knowledge, the first linked individual-tree GY system". ms.md line 117: "carried from the original simulator rather than estimated from the data"; supp.md S8, line 185: "Deposit versions before 1.9.0 ship one R carrier of the engine, HiGy_engine_v053_mortality.R (VersionTag HiGyV0.5.3), which reproduced the original projection engine end to end". The "original simulator" is the authors' own earlier engine, identified in S8, not a prior koa model, so the priority claim is not contradicted, only unhedged relative to the manuscript.

Fix: cover.md line 7: "yet, to our knowledge, it has had no growth and yield model. This study delivers the first linked individual-tree equations and tree-list projection system for the species, ..." (the hedge carries to the second sentence). ms.md 2.6: "The natural ceiling, carried from the original simulator (deposit versions before 1.9.0; Section S8) rather than estimated from the data, is close to ...". ms.md line 25 ("yet no tool provides species-specific projections") may take the same hedge; not forced.

### B10. Results first reported in the Discussion (REJECTED)

Each cited number (15% = 4.5^0.0908 = 1.146 by script; 9,757; 0.41 to 1.02; 2.9%; 6.2 years; 2.0-/1.4-fold; 3.75/5.9/4.7; 161 vs 144) carries a supplement pointer (Table S18, S3.2, S3.3, S6.2, S7.3, S4.1). The guide's "without repeating results" is a style norm; nothing here is unsupported. Moving sentences is editorial.

### B11. 23 versus 24 natural intervals (REJECTED, author decision ii)

ms.md 3.3.3, line 153: "solved on the 24 natural intervals from seven plots in five installations, is 2.54 ... or is 2.40 without one interval that spans a recorded removal year (Section S1.1)"; 2.6, line 115: Stage 1 "fitted to 282 plot intervals that exclude thinning removals"; line 151: "19 of their 23 intervals record a death". supp.md S1.1 (line 19) and S4.3 (line 125) name PSP 122 2019 to 2023. The 2.40 sensitivity is disclosed as decision (ii) requires; naming the interval in the main text is optional.

### B12. Dataset reference DOI (WORDING)

Quote (ms.md line 379): "Version 1.9.6. Zenodo. https://doi.org/10.5281/zenodo.21081014 (concept DOI, which resolves to the current version)." ms.md line 247: "Version 1.9.6 of the deposit (https://doi.org/10.5281/zenodo.23399505) ... is the version of record". Guide line 23: "[dataset] before the entry with repository, version, year, and persistent identifier." The entry meets the letter of the guide, but its stated version and its identifier do not correspond; the version DOI is in the package.

Fix (ms.md line 379): "\[dataset\] Weiskittel, A.R., Sprecher, I., Gottesman, A., Rice, B., 2026. *Acacia koa* individual-tree growth and yield data and prediction functions (Hawaii, 1949--2025). Version 1.9.6. Zenodo. https://doi.org/10.5281/zenodo.23399505." The concept DOI stays in Data and code availability (line 247). Which earlier version holds the original-covariate tables is not in the package (S3.3 and S8 say only "before 1.9.0"); optional needs analysis.

### B13. Abstract word count (REJECTED)

Script: 300 whitespace tokens, 300 after stripping the ^ and * markup, so Word will count 300 as well (no hyphen-joined or markup-split tokens differ). The guide allows "200 to 300 words". Trimming is optional.

### B14. "Highest published koa basal area" (CONFIRMED, supplement)

Quotes: supp.md S7.2, line 169: "The highest published koa basal area, 42 m^2^ ha^−1^ (Harrington et al., 1995), maps through the Reineke identity to SDI 911, 776 and 634". ms.md 3.5, line 169: "the 42 m^2^ ha^−1^ reported for natural koa stands (Harrington et al., 1995) ... Three Hawaii Island plantations aged 18 to 27 years, however, carried 35.7 to 78.8 m^2^ ha^−1^ (Scowcroft et al., 2010)". The manuscript's own citation of 78.8 contradicts "highest published". The main text wording is already restricted to natural stands and is consistent. Whether Scowcroft et al. report those values is not checkable here.

Fix (supp.md S7.2): "The 42 m^2^ ha^−1^ reported for natural koa stands (Harrington et al., 1995) maps through the Reineke identity to SDI 911, 776 and 634 at QMD of 20, 30 and 50 cm, ..."

### B15, B16. Characterizations attributed to Harrington et al. (1995), Baker et al. (2009) (REJECTED)

ms.md line 27: "along one of the steepest environmental gradients on Earth (Harrington et al., 1995; Baker et al., 2009)"; line 171: "5.7 to 8.2 Mg ha^−1^ yr^−1^ ... (Baker et al., 2009)"; line 209: "40 to 60 years that sawlog quality requires (Baker et al., 2009)". The sources are not in the package and VERIFY U17 lists these as unverifiable; neither reviewer demonstrates a mismatch. Not a confirmed defect; an author check against the sources is advised before submission.

### B17. "Five linked individual-tree equations" (REJECTED)

ms.md line 31 lists the five (static height, HCB, ΔDBH, ΔHT, survival); line 105: "The five component equations were linked into an annual tree-list simulator in which each step ... three-stage mortality (Eqs. 5 and 9), and, in uneven-aged stands, ingrowth (Eq. 6)". Eqs. 6 and 9 are stand-level, not individual-tree, and are named. Accurate as written.

### B18. Heading 2.4.3 (CONFIRMED)

Script: ms.md line 81 is "**2.4.3 Survival equation**" (bold paragraph), whereas lines 55, 67 and 89 are "### **2.4.1 ...**", "### **2.4.2 ...**", "### **2.4.4 ...**". Fix: apply the Heading 3 style in the Word file.

### B19. Blinded sibling checklist (REJECTED)

The blinded files are not in the package; the list is a checklist for them, not a defect of ms.md/title.md, which are the named versions.

### B20. Funding statement content (REJECTED)

ms.md line 235 / title.md line 29 describe the sponsor's role (commissioning, data-retention rules, no USDA role), which is the role-of-funding-source statement Elsevier places under Funding. ms.md line 239 already discloses that Forest Solutions "commissioned this work and uses the resulting yield curves". No misplacement is demonstrated.

### B21. AI declarations differ (WORDING)

title.md line 37: "After using this tool, the authors reviewed and edited the content as needed and take full responsibility for the content of the published article." ms.md line 253: "The authors oversaw all use, reviewed and edited the content as needed, and take full responsibility for the content of the published article." Script confirms neither phrase appears in the other file. Fix (title.md line 37, second sentence): "The authors oversaw all use, reviewed and edited the content as needed, and take full responsibility for the content of the published article."

### B22. CRediT formatting (WORDING)

title.md line 21 uses prose lower case ("writing (original draft)"); ms.md line 231 uses "Writing -- original draft". Fix: replace the title.md paragraph with the ms.md line 231 paragraph.

### B23. Corresponding address printed twice (WORDING)

ms.md line 13 "Center for Research on Sustainable Forests, University of Maine, Orono, ME 04469, USA" repeats line 5. Fix: delete line 13.

### B24. Board-foot prices (REJECTED)

ms.md line 23 quotes a trade price from Wiedenbeck and Lowell (2017); the SI rule concerns measurements, and the quoted unit is the source's.

### B25. "the calibration below" (WORDING)

ms.md line 73: "which the calibration below reconciles iteratively with the annual steps of the simulator". Guide line 11: "Internal cross-references must use these numbers, never 'the text.'" Fix: "which the origin calibration of Section 2.4.2 reconciles iteratively with the annual steps of the simulator".

### B26. "Small-scale For." and DOI case (REJECTED)

The journal's title is "Small-scale Forestry" (lower-case s in the publisher's title), so "Small-scale For." is the correct LTWA form. DOIs are case-insensitive; harmonization is cosmetic.

### B27. Table 1 header superscript (WORDING)

ms.md line 420: "**Mean BYI (Mg ha⁻¹)**" (Unicode superscript); every other table and caption uses "ha^−1^" (script confirms the Unicode form occurs only here). Fix: "**Mean BYI (Mg ha^−1^)**".

### B28, B29 (REJECTED)

B28: media files are not in the package; the Fig. 4 / image5 and Fig. 5 / image4 binding must be checked at upload but cannot be ruled on. B29: the reviewer asserts no error.

## 3. Counts

- CONFIRMED: 14 (V-C4, V-C5, V-C6, V-C7, V-6209, A3a, A6c, B2, B4, B5, B6, B7 [duplicate of V-6209], B14, B18). Of these, 6 need analysis or author input before the text can be fixed (V-6209/B7, A3a, A6c, B2, B5) and 8 have exact replacement text.
- REJECTED: 22 (A1, A2, A3b, A4, A6a, A7, A8, A9, A11, A-struct, B10, B11, B13, B15, B16, B17, B19, B20, B24, B26, B28, B29). Of these, 5 rest on the standing author decisions (A1, A2, A4, A8, B11).
- WORDING: 12 (A5, A6b, A10, A12, A13, B9, B12, B21, B22, B23, B25, B27).

Items of particular attention, as requested: Eq. 7 across 2.2, 2.6 and S3.3 is NOT mutually consistent (B2, confirmed, code check needed); planted lower bound 109 is the plantation-record floor and 158 the PSP floor (V-C4, confirmed); Table 6's 0.88 is absent from Table S12 and the DOFAW ratios are 0.97/0.44 (V-C5, confirmed); "QMD does not fall with density" is contradicted by Table S31 in both origins (V-C6, confirmed); the uneven-aged initial density and QMD are stated nowhere, including S5 and the table notes (A3a, confirmed, needs the values); Table 6's Stage 3 record count is the refit sample, not the deployed vector's (A10, wording); the [dataset] entry is misplaced (B4, confirmed) and cites the concept DOI against a stated version (B12, wording; the guide requires version plus persistent identifier and does not say which); Acknowledgments appear on the title page against the guide extract (B6, confirmed).
