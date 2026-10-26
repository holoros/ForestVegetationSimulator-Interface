# Koa v109 content diff: manuscript (named and BLIND), title page, cover letter

Date: October 15, 2026. Built by `/tmp/v109/work/build_v109.py` from the v108 package in `/tmp/rt7/in/` (read only), applying red team 7 (RT7) and stress test 4 (ST4) fixes as scoped. Nothing was sent, uploaded or published. No equation or `w:sdt` content control was edited; every anchor matched exactly one paragraph, so no XML forcing was needed.

## Sources

| Output | Built from | Input md5 |
|---|---|---|
| koa_manuscript_v109_DRAFT.docx | koa_manuscript_v108_DRAFT.docx | c2a87270323eaf5ba08d311a1790eed3 |
| koa_manuscript_v109_DRAFT_BLIND.docx | koa_manuscript_v108_DRAFT_BLIND.docx (same text edits; withheld blocks kept withheld) | 23825d818f03f24a7061c0e04235e295 |
| koa_title_page_v109.docx | koa_title_page_v108.docx | 72cb96ef54e0cf7803b379fe2b4435e7 |
| koa_cover_letter_v109.docx | koa_cover_letter_v107_FINAL.docx | 0248cb16fc4508482913b988b2aed2eb |

## Changed: manuscript (named and BLIND unless marked)

| Item | Location | Change |
|---|---|---|
| S10 b (named) | Byline, corresponding author line, CRediT | "Aaron Weiskittel" to "Aaron R. Weiskittel" |
| S10 b (named) | Affiliation c | "Midgard Natural Resources" to "Midgard Natural Resources LLC" |
| S12 d (named) | Running head, header2 and header3 | "Weiskittel et al. – Koa G&Y model" to "Weiskittel et al., Koa G&Y model". BLIND header stays "Koa G&Y model" (it never had a dash). |
| N11 | Abstract | "by a random forest" to "by random forests" |
| S1 | Abstract | occurrence "rises with stand density in the short planted intervals that dominate the record" |
| S2 | Abstract, last sentence | "projections beyond the 52-year record, for sites off Hawaii Island, for low-productivity sites and for planted stands older than about 18 years rely on extrapolation, and planted volume is more likely overstated." The RT7 text ended "overstated than understated"; "than understated" was dropped to hold the limit. |
| S2 cuts | Abstract | removed "over seven decades", "a productivity index", ", with installations resampled within data sources", "and policy"; "differences among data sources" to "data-source differences"; "site term was not distinguishable from zero" to "site interval spans zero" |
| S15 | Introduction, end of paragraph 4 | new sentence: "Beyond koa, the study tests whether three devices can carry an individual-tree model where stand age and long remeasurements are missing, namely an age-free productivity index, a mortality structure that separates occurrence from magnitude, and linked-system evaluation on remeasured plots." |
| S6 | Introduction, end of paragraph 5 | FVS-HI now "a Hawaii variant ... built on the FVS framework (Crookston and Dixon, 2005). The variant implements the height, crown and increment equations but differs from the deposited simulator in crown recession, the height increment density term and the survival structure (Data and code availability)." The clause "can support further development for koa and extension to additional species" was removed. |
| S8 | 2.2 | "Table S1 defines every variable and its units, and Table 2 summarizes them." Table 2 is now cited before Tables 3 and 4. |
| S16 | End of 2.5 | "Analysis and simulator code was written with assistance from Claude (Anthropic), and every reported table and figure was regenerated from the archived scripts (Section S8)." RT7 had "every reported number"; changed to "table and figure" to match S8 and the S14 data statement, since S8 records open parity differences and not a regeneration of every number. |
| M6, S9 b (ST4 D8) | 3.3.3 | "the 5.6% yr^−1^ observed over the 282 Stage 1 intervals, most of them planted" (superscript fixed; 259 not asserted) |
| S5 | 3.5, paragraph 1 | new sentence: "Planted stands peak at 57.2 m^2^ ha^−1^ and an SDI of 889 (Section S7.1), above the largest DOFAW basal area and the highest published koa basal area of 42 m^2^ ha^−1^ (Harrington et al., 1995; Section S7.2)." Values checked against s104 S7.1 and S7.2. |
| M4 a, b | 4.1, paragraph 1 | support "is weak for every component, since only the diameter term fitted on the original covariates has an interval that excludes zero"; surface "separates forest from nonforest but has no demonstrated skill among forested plots, even on Hawaii Island (Section 3.2)" |
| S1 | 4.1, paragraph 2 | "In the planted record, mortality occurrence rose with stand density" |
| S4 | 4.1, paragraph 2 | slopes in the band "at the default initial densities", plus "whereas from the sparsest starts at BYI 264 the slopes are shallower (−0.81 natural, −0.93 planted)" |
| S1 | 4.4, paragraph 1 | "If the planted pattern extends to natural stands, koa mortality would arrive in episodes ..." |
| S4 | 4.4, paragraph 1 | low natural slope −1.02 "lies within the −0.9 to −1.2 range fitted to the upper boundary of the natural plot-measures (Section S7.2), although that boundary is sparsely populated, and is shallower than the slopes of long-term European plots (...), which may partly reflect the mortality level". Range checked against S7.2. |
| S13 | 4.4, paragraph 1 | "(Section 3.3.3)" to "(Section 3.5)" |
| M4 c | 4.5, paragraph 2 | "Where low productivity is established locally"; "At BYI levels above 250"; "supports comparison among BYI levels but not the screening of individual sites, since the mapped surface cannot separate the three levels at a single location (Section 3.2), and cannot underwrite ..." |
| S12 c, extended | 4.6 | "Every row of Table 5 at age 100, and of Table S30 at age 60 and beyond, is extrapolation" (same defect as the Table 5 note; Table 5 has no age 60 rows) |
| S3 | Conclusions, paragraph 1 | the "+0.194 to +0.041" clause replaced by "solved on the same natural intervals. On the 17 benchmark plots, all of which informed fitting or calibration, QMD was equivalent to observation in both origins, whereas natural survival and basal area in either origin were not." |
| S3 | Conclusions, paragraph 2 | "160 to 197 m^3^ ha^−1^ (95% Monte Carlo ranges 57 to 231 and 70 to 285), or about 38 to 47 Mg C ha^−1^ of stemwood carbon (about 14 to 68), before the ±12% form-factor uncertainty". Checked: 56.8 × 0.51 × 0.47 = 13.6 and 284.6 × 0.2397 = 68.2. |
| M4 d | Conclusions, paragraph 3 | "a productivity surface with demonstrated skill among forested plots, on and off Hawaii Island" |
| M3 (named) | Funding | v108 text kept; "(Section S1.3)" added to the retention rule clause; appended "Forest Solutions Inc. employees took part as authors in data curation and analysis, and the decision to submit was made by all authors." Competing interest text unchanged ("A.R. Weiskittel declares no competing interests" kept). BLIND keeps "Withheld for double-blind review." |
| S14 | Data and code availability, paragraph 1 | "the scripts that produced every table and figure of the recomputed system (...), with the tables on the original covariates drawn from earlier versions of the deposit, are archived" |
| M5 | Data and code availability, paragraph 1 | appended "The deposit holds no plot coordinates, and true Forest Inventory and Analysis plot coordinates are not released." Fig. 1 caption ("no plot coordinates are deposited") kept as is. |
| S6 | Data and code availability, paragraph 2 | "Because the variant differs from the deposited simulator in crown recession, in the stand basal area of the height increment density term and in the survival structure, by up to 5.0 cm in DBH after ten years on a planted test list (Section S8), projections ..." S8 of s104 states the 5.0 cm difference. No commit hash added. BLIND keeps "[repository withheld for review]". |
| S9 d, S12 b | Fig. 6 caption | "stems ha^−1^ (logarithmic axis)"; "Breaks in the planted curves at about age 35 to 40" |
| M4 e | Table 5 header | "Site class (BYI)" to "BYI level" (bold kept) |
| S12 c | Table 5 notes | "Rows at age 60 and beyond" to "Rows at age 100" |
| S5, S9 c (ST4 D9) | Table 5 notes | "Point estimates in Table S30 reach 56.5 m^2^ ha^−1^ of basal area, and the planted trajectory peaks at 57.2 m^2^ ha^−1^ between grid ages (Section S7.1). Only the uneven-aged medium and high rows ..." (superscripts fixed) |

## Changed: title page v109

- Byline superscript: "a," and "*" now both superscript (S10 c).
- Affiliation c: "Midgard Natural Resources LLC".
- Funding: same text as the v109 manuscript.
- Competing interest: unchanged (same as manuscript).
- Data availability: replaced with the two v109 manuscript paragraphs, so the "Plot positions in the deposit are fuzzed" sentence is gone and both statements now read the same (M5, S10 d).
- Section headings set keep-with-next (render fix: "Declaration of competing interest" had been stranded at the foot of page 1).
- No postal addresses added.

## Changed: cover letter v109 (new file from v107 FINAL)

- Date "October 15, 2026".
- N12: "Koa (*A. koa*) is the most valuable endemic hardwood".
- M4 f: contribution 1 ends "which separates forest from nonforest but not yet productivity among forested plots"; "The Discussion states what the projections can and cannot support for rotation and carbon decisions".
- S1: contribution 2 "rises with stand density in the short planted intervals that dominate the record".
- S15 mirror: "Beyond koa, the study tests whether these three devices, an age-free productivity index, a mortality structure that separates occurrence from magnitude and linked-system evaluation on remeasured plots, can carry an individual-tree model where stand age and long remeasurements are missing."
- M2: the "Every projection" sentence uses the RT7 corrected text (height equation of Table 3, height increment refitted on recomputed covariates, diameter vector on original covariates with origin constants re-solved, natural mortality level on 24 intervals, survival on 877 deaths, joint draws). No ingrowth refit claim.
- M5: "with fuzzed plot positions" to "with no plot coordinates".
- M1: "All authors have approved the submission. Competing interests are declared in the manuscript and on the title page: two authors are employees of Forest Solutions Inc., which commissioned this work and uses the resulting yield curves in a koa financial model, and one author is affiliated with Midgard Natural Resources LLC, which holds the scope of work under which the equations were developed." ("and on the title page" added because the BLIND manuscript withholds the declarations.)
- Counts sentence rebuilt by script from v109: "about 8,700 words with a 300-word abstract, eight keywords, five tables, six figures and 62 references, with a supplement of 33 tables and eight figures".
- Layout: the longer text ran to two pages, so margins were set to 0.5 in top and bottom and 0.85 in at the sides and Normal type to 11.5 pt; the letter renders on one page.

## Removed

| Removed | Reason |
|---|---|
| customXml/item1.xml, itemProps1.xml, _rels/item1.xml.rels, its relationship in word/_rels/document.xml.rels and its override in [Content_Types].xml, in BLIND | ST4 B1: Google Docs round-trip data naming "Aaron Weiskittel" and a Google account id |
| Same parts in the named manuscript | Harmless to remove (Google suggestion records only); the file opens and renders. |
| "+0.194 to +0.041" in Conclusions | S3: in-sample by construction |
| "can support further development for koa and extension to additional species" (Introduction) | S6 rewrite |
| "Plot positions in the deposit are fuzzed" (title page) | M5: the deposit holds no coordinates |
| "differed during development" (data statement) | S6: the difference is current |

docProps/custom.xml was kept: it is an empty Properties element in both manuscripts. Title page and cover letter customXml hold only an empty Word bibliography store and were left.

## Not applied, with reasons

- S8, Fig. 4 versus Fig. 5 order: no sentence in Methods 2.6 describes the 100-year projections (the closest are the Weibull start-list sentence and "Projection uncertainty was quantified from 500 Monte Carlo replicates"), so no Fig. 4 citation was added. Fig. 5 is still first cited (3.4) before Fig. 4 (3.5). Options: cite "(Fig. 4)" after the Monte Carlo sentence, or swap the Fig. 4 and 5 numbers and TIFFs.
- S9 a: the "US$50 per board foot" sentence was left unchanged, as instructed.
- S12 a: not changed. Table S2 gives the 320 growth-model plots a median of 203.6, so 3.2's "median 204" over 320 plots is correct. Table 1's "plot median 203 over the 311 plots with live records and a BYI value" is a different set of plots, and no document gives its median, so it cannot be confirmed or corrected from the documents.
- M6, paragraph 1 of 3.3.3: "within the 267 planted intervals" was left, since that sentence already says the sensitivity fits used the original intervals (290 frame). The 24 against 23 natural interval explanation (S4.3) is a supplement change.
- M3 bracketed items: no agreement number, no contract chain wording and no change to the Weiskittel competing interest sentence, as instructed.
- S7: Section S1.3 does not describe the "status-conflict" retention rule, so the new "(Section S1.3)" pointer lands on a section that covers duplicated visits only. The rule and its record count still need a sentence in S1.3 at the next supplement version.
- S10 a: no postal addresses, as instructed.
- M7, S11, S12 e, ST4 D7, D11, D12: supplement and deposit changes, out of scope.
- ST4 D2 (1.603 against 1.602), D10 (Pretzsch order), N1 to N10 and N13: not in the scope list.
- RT7 N10: the CRediT block still uses spaced en dashes ("Writing – original draft"); these are the 5 spaced en dashes left in the named manuscript.
- The named byline asterisk ("a*") is still not superscript in the manuscript (only the title page was in scope).

## Counts (same method for cover letter and manuscript)

Abstract: whitespace-split words of the paragraph after "Abstract". Body: run-level `w:t` text, content controls included, from "1 Introduction" through Conclusions, headings included, tables excluded (this method gives 8,405 for v108, which matches the v107 letter's "about 8,400").

| Count | v108 | v109 named | v109 BLIND | Cover letter v109 |
|---|---|---|---|---|
| Abstract words | 299 | 300 | 300 | 300 |
| Body words | 8,405 | 8,674 | 8,674 | about 8,700 |
| Keywords | 8 | 8 | 8 | eight |
| Tables | 5 | 5 | 5 | five |
| Figures | 6 | 6 | 6 | six |
| References | 62 | 62 | 62 | 62 |
| Supplement tables, figures (s104, unchanged) | 33, 8 | 33, 8 | 33, 8 | 33, eight |

The abstract sits at the 300-word limit; any added word breaks it. Letter numbers 9,164, 158 installations, 17 plots, 15 plots, 52 years, 3.9 cm, 877 deaths and 24 natural intervals all appear in v109. No em dash in any output.

## BLIND sweep (every part of the v109 BLIND docx, customXml base64 decode included)

Patterns: Weiskittel, Sprecher, Gottesman, Rice, Maine, Forest Solutions, Midgard, CRSF, orcid, zenodo.21081014, zenodo.22997704, holoros, MidgardNaturalResources. Thirteen hits, all in word/document.xml and all allowed: 12 third-person literature citations of Weiskittel (Weiskittel et al., 2011 four times; Salas-Eljatib and Weiskittel 2020 twice; the reference entries for Chen 2023, Hennigar 2017, Li 2011, Salas-Eljatib 2020, Weiskittel 2011 and Willson 2019) and Sprecher in Owen et al. (2022). No customXml part remains. Headers read "Koa G&Y model". The BLIND data statement still names the deposit files and version 1.9.5 (RT7 N8, not in scope).

## Rendering

LibreOffice PDFs, first page and every changed page rasterized and viewed: manuscript pages 1, 2, 5, 6, 20, 22, 23, 24, 26, 27, 29, 30, 31, 32, 33, 42, 43, 48 and 53; BLIND pages 1, 2, 32, 33, 41 and 52; title page pages 1 and 2; cover letter page 1. Table 5 notes checked at 150 dpi. Superscripts (yr^−1^, m^2^ ha^−1^, the title page a,*) render correctly. Defects found and fixed: cover letter spill to page 2 and a stranded title page heading.

## Outputs (final run)

| File | md5 | Pages |
|---|---|---|
| koa_manuscript_v109_DRAFT.docx | a7c57a617c28c774ea4aec87b08af35d | |
| koa_manuscript_v109_DRAFT_REVIEW.pdf | 296a8f04f378f431b7065dc103157a92 | 53 (v108: 52) |
| koa_manuscript_v109_DRAFT_BLIND.docx | 605f43411c0d615744df7ff0d79ad41f | |
| koa_manuscript_v109_DRAFT_BLIND_REVIEW.pdf | 4a18a841f7aa41e35daccd6cd0db084f | 52 (v108: 51) |
| koa_title_page_v109.docx | a0ab6c991dc9f9ef5f248fb4ca49d8a9 | |
| koa_title_page_v109_REVIEW.pdf | 7529308cd916e24ba10ae0c33de68757 | 2 (v108: 2) |
| koa_cover_letter_v109.docx | e79c1325efe3a3d59c242778fc97497b | |
| koa_cover_letter_v109_REVIEW.pdf | 2fae5becb81b93d3207248468e68c426 | 1 |

Rerunning the script produces the same content, but the md5 values change because zip timestamps change.
