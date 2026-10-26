# Repair attack, round 1 (v119 to v120, s112 to s113, cover letter, title page)

Attacker had no stake in the result. Inputs: the four diffs and four new full texts in `scratchpad/koa_run/v120/`, old texts in `scratchpad/koa_run/real/`. Checks run with `python3 -I scratchpad/koa_run/attack_work/frame_check.py` (output in `frame_check_output.txt` beside it). Established facts from the system of record were taken as given and not re-flagged.

## 1. Frame check (numeric multisets, old versus new)

After stripping pandoc image-size attributes (present only in the new Markdown) and serial-comma suffixes, every multiset difference is accounted for by an intended repair:

Manuscript, removed: `04469` (duplicate affiliation line), `158` x2 (Table 5 note, Section 4.6), `6,209`, `0.88` (Table 6 DOFAW ratio; the basal-area slope 0.88 in 3.4 is kept), `21081014` ([dataset] entry). Added: `4,715`, `109` x2, `0.44`, `23399505`, `500` x2 and `8.0` x2 (uneven-aged start, Section 2.6 and Fig. 5 caption), `-1.43`, `-1.68`, `-1.20`, `0.99`, `95` (Reineke clause), `4,911` (Table 6), `1` (1 − BA.perc), `40` (QMD at age 40), and pointer tokens `2.4`/`2` (Section 2.4.2), `23` (Table S23), `31` (Table S31), `15` (Table S15), `7.2` (Section S7.2), `-1` x2 (ha⁻¹ in the two new 500-stem phrases).

Supplement, removed: `21081014`, `-22` (hyphen in 19-22°N). Added: `23399505`, `22` (19 to 22°N), `500`, `8.0`, `0.6`, `2` (Eq. 2 in the uneven-aged start), `1` (1 − BA.perc), `8` x2 (Section S8 in Table S20), `3`, `9`, `3.1` (Eq. 3, Table S9, Section S3.1 in the Table S16 note).

Cover letter: date only (21 to 26). Title page: none.

Arithmetic behind the new numbers: 4,971 − 101 − 155 = 4,715; Table S12 gives 0.961/2.193 = 0.44 (DOFAW planted) and 3.026/2.193 = 1.38 (KMR PSP), and the old 0.88 "DOFAW" ratio matches nothing in Table S12 (DOFAW natural is 0.97), so its removal is a correction; thinning gains 3.3, 7.5, 3.4 (unrounded) and 2.4 to 5.9 at age 100, and yield losses 6%, 10%, 10% all reproduce from Table S31; stem counts 172 to 263 and 204 to 346 reproduce. No analyzed population or unintended number changed.

## 2. Ranked findings

### F1. SHOULD. Section 2.6 cites an original-covariate result without the qualifier
Quoted (2.6, Eq. 9 paragraph): "so the limiting line implies a Reineke slope of −1.92, steeper than the −1.43 (95% interval −1.68 to −1.20) boundary fitted at τ = 0.99 to the plot record (Section S7.2)."
Evidence: S7.2 says "On the original covariates a maximum size-density line was fitted ... to the 471 live plot-measures ... At τ = 0.99 the slope was −1.43 (95% interval −1.68 to −1.20)". The supplement preface commits to marking every original-covariate result, and the main text does so everywhere else ("In sensitivity fits on the original intervals", "In a candidate comparison on the original covariates", "Only the diameter site term fitted on the original covariates"). The new clause is the one place where an original-covariate number enters the main text unmarked, and the comparison pairs a recomputed allometry (−1.92) with an original-covariate boundary.
Minimal fix: "... steeper than the −1.43 (95% interval −1.68 to −1.20) boundary fitted at τ = 0.99 to the plot record on the original covariates (Section S7.2)."

### F2. SHOULD. Self-referential pointer inside Section 2.4.2
Quoted (2.4.2, after Eq. 4): "which the origin calibration of Section 2.4.2 reconciles iteratively with the annual steps of the simulator".
Evidence: the sentence sits in Section 2.4.2 (heading at line 65, sentence at line 71 of the new manuscript). The origin calibration is described two paragraphs later in the same section. Pointing a reader to the section they are in is a wording defect the old "the calibration below" did not have.
Minimal fix: "which the origin calibration described below reconciles iteratively ..." or "... of Section S3.2 ...".

### F3. SHOULD. Table S20 pointer to Section S8 is not backed by S8
Quoted (Table S20, two rows): "carried from the original simulator rather than estimated from the data (Section S8)".
Evidence: the provenance itself is established (koa_survival_calibrated.R of the original engine). Section S8 (Reproducibility) does not mention the background floors, koa_survival_calibrated.R, or any mortality floor; it names HiGy_engine_v053_mortality.R as the carrier of the original engine and says threshold provenance for Eq. 9 lives in the companion forensics document in the deposit. A reader following the pointer finds nothing about the floors.
Minimal fix: either add one clause to S8 ("the background floors of Table S20 are carried from the original engine's koa_survival_calibrated.R and were not estimated on the data") or change the pointer to "(original engine, Weiskittel et al., 2026)".

### F4. SHOULD. Supplement [dataset] entry was not moved with the manuscript entry
Quoted (supplement reference list): the `[dataset] Weiskittel, A.R., Sprecher, I., Gottesman, A., Rice, B., 2026 ...` entry is the last entry, after Wilton et al. 2015.
Evidence: the manuscript entry now sits between Weiskittel et al. 2011 and Whitesell 1990 (lines 371 to 375), which is the alphabetical position; the supplement entry only had its DOI changed and still sits out of order after Wilton. The two reference lists now follow different conventions for the same entry.
Minimal fix: move the supplement entry to between Weiskittel et al. 2016 and Wilton et al. 2015.

### F5. WORDING. Section 4.6 "remain untested" after reporting a test (pre-existing tension, value changed)
Quoted (4.6): "At a BYI of 25 Mg ha⁻¹ and 52 years after its first measurement, it is projected at 43.8 against an observed 13.6 m² ha⁻¹ of koa basal area. Planted rows below a BYI of 109 Mg ha⁻¹ remain untested against plantation observations."
Evidence: 109 is the floor of planted increment support (KMR PSP, Section 3.1), whereas the planted benchmark plots are the ten PSP plots (BYI 158 to 561) and Kulani (BYI 25). The sentence that precedes it reports the Kulani test at BYI 25, so "remain untested" below 109 reads against its own neighbor, and the 109 floor describes increment support, not benchmarking. The same tension existed with 158 in v119; the repair did not create it, and 109 is consistent with Table 5 and Table 6. Not a factual error if "plantation observations" is read as "plantation records".
Minimal fix: "Apart from Kulani, planted rows below a BYI of 109 Mg ha⁻¹ have no plantation observations to be tested against."

### F6. WORDING. "For the same reason" adds a causal link the original did not state
Quoted (4.3): "... since removing it moved the diameter level shift from 0.41 to 1.02 (Section S3.2). For the same reason, the equations should not be driven by measured crowns without refitting."
Evidence: v119 joined the two with "and". The causal reading is supportable, since the paragraph opens "Because crown ratio is predicted in the increment sample from competition variables already in Eq. 4" and S3.1 states the same consequence ("at the cost that the equations cannot be driven by measured crowns without refitting"). No contradiction, but the connector is manufactured.
Minimal fix: drop the connector: "The equations should not be driven by measured crowns without refitting."

### F7. WORDING. "Not ordered by initial density" understates what Table S31 shows
Quoted (3.5): "QMD at age 40 is not ordered by initial density, because density-dependent mortality allocated by Eq. 5 removes the smallest stems fastest (Table S31)."
Evidence: Table S31 natural QMD at age 40 is 35.2, 34.8, 36.3, 40.5 cm from 250 to 2,000 stems (rises except the 250 to 500 dip) and at age 100 is strictly increasing, 59.0, 60.0, 65.6, 79.0 cm; planted at age 40 is 47.9, 45.1, 44.5, 47.8. The statement is true as worded and now matches S7.3 ("QMD at age 40 is not ordered by density"), but the old "QMD does not fall with density" was the more informative description of the natural series. Optional.
Minimal fix (optional): "QMD at age 40 does not fall with initial density and is not monotone in it".

### F8. WORDING. "Not retested on the recomputed system" is broader than Table S23
Quoted (2.6): "whereas the planted rate is left unscaled, a choice made on the original covariates and not retested on the recomputed system (Section S4.3; Table S23)."
Evidence: Table S23 shows the planted multiplier was solved on the corrected engine (3.50, 2.58 to 4.88, held-out deaths 1.01), and marks only its 100-year mortality, Reineke slope and validation as "not run" on the recomputed system, with the outcome "planted order broken on the original covariates". So the multiplier was re-solved; its deployment test was not rerun. The sentence is defensible but slightly over-broad.
Minimal fix: "... a choice made on the original covariates whose validation effect was not rerun on the recomputed system (Section S4.3; Table S23)."

### F9. WORDING. Cover letter repeats "to our knowledge" in consecutive sentences
Quoted: "yet, to our knowledge, it has had no growth and yield model. This study delivers the first linked ... to our knowledge the most extensive koa remeasurement record compiled to date."
Evidence: the added hedge now matches the Introduction ("to our knowledge none has been developed for koa"), which is correct, but the phrase appears twice in two sentences.
Minimal fix: keep the first and change the second to "the most extensive koa remeasurement record we know of".

### F10. WORDING. Heading style of 2.4.3
Quoted: `### 2.4.3 Survival equation` against siblings `### **2.4.1 ...**`, `### **2.4.2 ...**`, `### **2.4.4 ...**`.
Evidence: the repair promoted a bold paragraph to a level-3 heading (correct) but without the bold the siblings carry. Formatting only; 2.4 and the 3.3.x headings are also unbolded, so the document is already mixed.
Minimal fix: match the sibling style in the docx.

### F11. none. Intro split leaves the value claim uncited in its own sentence
Quoted: "produces one of the world's most valuable tropical timbers. Full-curl figured lumber sells for about USD 65 to 150 per board foot and stumpage for USD 3 to 4 per board foot (Wiedenbeck and Lowell, 2017)."
Evidence: in v119 one citation covered both clauses. The price sentence still substantiates the claim immediately. No action needed.

### F12. none (pre-existing, noted for the record). Table 6 Stage 3 row now mixes deployed and refit statistics more visibly
The Data cell now says the deployed vector was fitted to the 4,911-record sample, whereas the Key performance cell (877.5 of 877 deaths, AUC 0.78) belongs to the refit on 4,223 records (Table S15 adopted-form row; the deployed coefficients score 0.496 within interval without refitting). Both facts are stated in Table S15 and Section 2.4.3, and the sentence "with the refit on 4,223 records ... keeping every sign" is accurate, so nothing false was introduced; a reader may still wonder which coefficients the 0.78 belongs to. Not a repair defect.

## 3. Items checked and found clean

- Propagation: no `6,209` anywhere; no `0.88` as a source ratio (remaining 0.88s are the basal-area slope in 3.4/Table S25 and unrelated values); no concept DOI inside a [dataset] entry (the concept DOI remains, correctly, in the Data and code availability text and title page); no "single cohort" for the uneven-aged start (the only remaining "single-cohort" is the retired test set in S5, a different object); `158` survives only in the installation count and the two PSP-only statements the caller said to keep (Table 5 note, 3.1); `109` appears consistently in 3.1, 4.6, Table 5 note and Table 6.
- New pointers resolve: Table S23 (planted multiplier row, "not run"), Table S31 (QMD and TPH by density and thinning at BYI 264), Table S15 note (4,911-record sample, signs kept on the refit), Section S7.2 (−1.43, −1.68 to −1.20, τ = 0.99), Section S3.3 (1 − BA.perc), Section S5 and the deposited script (500 stems ha⁻¹, 8.0 cm, CR 0.6, height from Eq. 2), Table S9 and Section S3.1 for the Table S16 note, which also agrees with the Table S8 caption ("The HCB column is the mixed-effects fit of Eq. 3 on 359 ... trees").
- Eq. 7 consistency: 2.2 (BAL allocated by diameter percentile among live stems), 2.6 (BAL = (1 − BA.perc) × BAPH; 1 − BA.perc = weighted share of other live stems at least as large), S3.3 (BA.perc of record = strictly-smaller count share with ties at the minimum rank; simulator returns 1 − BA.perc = (W≥,i − wi)/(W − wi)), and S5 step (1) all agree with the code fact BAL = BAPH × share of other stems with DBH ≥ subject, which with equal weights equals 1 − BA.perc. The v119 wording "BA.perc is the ... share ... at least as large" was the sign error and is gone from both documents.
- Sentence splits (Intro, 2.6 x2, 3.3.2 x2, 3.3.3 x2, 3.5 x2, 4.2 x3, 4.3 x2, 4.6, Fig. 3 and Fig. 5 captions, Table 3 note, S1.1, S1.3, S3.1, S3.2 x3, S3.4, S4.3, S5, S8): "therefore" replaces "so" (2.6, S5, 4.2, 4.3, S3.2), "However" replaces "although" (4.2), "In contrast" replaces "but" (3.3.3), "The reason is that" replaces "because" (S3.4); each preserves the original relation. The one manufactured connector is F6.
- Section 2.4.3 is now a level-3 heading between 2.4.2 and 2.4.4 (F10 is style only). Duplicate affiliation line removed; the remaining front matter is the full author block, which is the non-anonymized file. Manuscript [dataset] entry sits between Weiskittel et al. 2011 and Whitesell 1990 with the version DOI.
- Cover letter counts still hold: 66 reference entries, 33 supplementary tables, 8 supplementary figures.
- The supplement's "The 42 m² ha⁻¹ reported for natural koa stands (Harrington et al., 1995)" now matches the main text (3.5) word for word; the dropped superlative "highest published" removes an unverifiable claim. Whether Harrington et al. (1995) stands are natural was not verifiable from the system of record; the phrase was already in the main text in v119.
- Cover letter "and the first is ecological" and the AI declaration rewrite assert nothing new.

## 4. Statement

No new factual, sign, method, or disclosure defect was introduced by the repairs. The four SHOULD items are a missing "on the original covariates" qualifier on a newly imported number (F1, the closest to a disclosure slip, since the document's own convention is to mark such results), a self-referential section pointer (F2), a pointer to a section that does not contain the cited provenance (F3), and an inconsistency between the two reference lists (F4). Everything else is wording. The intended changes (158 to 109 twice, 0.88 to 0.44, 6,209 to 4,715, concept DOI to version DOI in both [dataset] entries, the Eq. 7 sign correction, the uneven-aged initialization, the Reineke boundary clause, the planted-rate disclosure, the floors' provenance, the Table S16 note) are each supported by the full texts or the established facts, and no number outside that set changed.
