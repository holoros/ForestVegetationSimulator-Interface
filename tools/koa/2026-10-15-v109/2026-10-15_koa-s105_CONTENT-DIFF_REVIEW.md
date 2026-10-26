# Koa supplement s105 content diff (named and BLIND, built from s104)

Date: October 15, 2026. Internal build record. Nothing was sent, uploaded or published.

Build: `/tmp/s105/work/build_s105.py` is rerunnable and rebuilds both files from the s104 inputs. Each text edit is an explicit anchored replacement. The script resolves every target paragraph on the s104 text before editing. Each old fragment must occur exactly once in its paragraph and must not cross a formatting boundary, and the replacement keeps the run properties of the text it replaces. The full list of edits with sentence context is in `/tmp/s105/out/change_log.txt` (142 edits per file plus 4 restyles and 1 reference move). I read every NEW fragment for grammar, and one comma was added as a result ("after the recomputation, variant (ii) holds").

Integrity checks (both files): 3,128 paragraphs and 33 tables before and after. The supplement holds no OMML equations, and no table number, equation number or numeric value changed. The only numbers added are 1.9.0 (three times, from "deposit versions before 1.9.0"), S33 and S7 (D7 and D4 wording) and 202, 204 and 2012 (the S7 retention sentence). The only numbers removed are the deviation codes A1-D1 and A1-D6. There are no em dashes. BLIND and named received identical edits, except for the subject of the S7 sentence (see Changed).

## Added

1. **S1.3, retention rules (RT7 S7).** One sentence at the end of the copied-remeasurement paragraph. Named: "Forest Solutions Inc. set the record retention rules before any refit, namely that at a doubled visit the later record set is kept rather than the earlier, that at a visit whose tree status conflicts between record sets the later record set is kept, and that PSP 202 to 204 keep their 2012 diameters recorded on trees shorter than breast height, flagged as a limitation rather than dropped." BLIND: the same sentence, with "The project sponsor" as the subject, because "Forest Solutions" is a blind sweep term.
2. **Preamble (ST4 D7).** A clause: "and Table S33, which reconciles the increment frames, is placed last".

## Changed (counts are edits per file; word-level counts in parentheses)

| Category | Edits | Words replaced | Replacement used |
|---|---|---|---|
| "published" about the authors' own equations, vectors, form, coefficients and fit (M7a) | 34 | 35 | "original" (includes 6 table cells: "Original terms and competition", "Original terms", "Original equation refitted", "Original coefficients", "Stage 1/Stage 2, original form") |
| "repaired" / "repair" / "unrepaired" (M7b) | 59 | 39 / 20 / 5 | "recomputed", "recomputation", "the calibration on the recomputed frame", "the refit on the recomputed covariates"; "unrepaired" to "original" (frame, intervals, inputs, covariates) |
| "earlier system" / "earlier engine" / "earlier calibration" (M7b) | 34 | 19 / 10 / 5 | "on the original covariates" (where results were produced on the original frames) or "the original calibration" (where a system is compared or acts as subject); "the simulator under the original calibration" once (Section S3.3) |
| "this revision" (M7b) | 5 | 5 | "this study", including "The analysis of this study was rebuilt on recomputed inputs" (S8) |
| "previous revision" / "previous deposit" / "previous projection engine" (M7b) | 4 | 2 / 1 / 1 | "deposit versions before 1.9.0" (3); "the original projection engine" (1) |
| Deviation codes (M7b) | 2 | 2 | "(deviation A1-D1)" and "(deviation A1-D6)" deleted (S3.2) |
| "harness" (M7) | 6 | 6 | "test set" in 3 (S3.6 retired single-cohort harness, S3.7 Monte Carlo perturbations, S7.2 gates); see Not applied for the other 3 |
| Front matter (M7, S12e) | 1 | 1 | "the data and their quality control" |
| S1.3 heading (RT7 S11) | 1 | 1 | "S1.3 Stand covariate recomputation and copied remeasurements". No other place quotes the S1.3 title, so no title reference was changed. "Section S1.3" references are unchanged |
| S2.2 BYI skill (ST4 D4) | 1 | 1 | "...the surface separates forest from nonforest but shows no demonstrated skill among forested plots, even on Hawaii Island (Table S7)." (replaces "assigns coarse productivity classes on Hawaii Island rather than predicting plot productivity"). This matches the manuscript wording in 3.2 and 4.2. No other claim of skill among forested plots appears in the supplement |
| Preamble first-citation claim (ST4 D7) | 1 | 1 | "follow the text in order of first citation" became "are numbered broadly in order of first citation, and Table S33, ... is placed last". No renumbering |
| S1.3 paragraph style (ST4 D12, RT7 S11) | 4 restyles | n/a | The four body paragraphs went from Heading 2 to normal1, with the pPr copied from the S1.2 body paragraph (first-line indent 432, after 120, keepNext off). The PDF shows them as indented body text |
| Reference order (ST4 D11) | 1 move | n/a | The paragraph was moved, not retyped. Named: "[dataset] Weiskittel, Sprecher, Gottesman, Rice, 2026" now follows Weiskittel, Kuehne et al. 2016, after the 2011 and 2016 multi-author entries. BLIND: "[dataset] Authors, 2026" now comes first (alphabetical A). This also removes the surname hint that ST4 noted for its position between Weiskittel 2011 and Willson. The rest of the list was already in order |

Kept as "published" because each refers to the literature (5): "Published mixed-species height models" (S3.5), "The highest published koa basal area" (Harrington et al., 1995; S7.2), "Published benchmark" (Table S16 column), "published ranges for comparison" (Table S16 notes) and "published individual-tree models" (Table S17 caption).

## Removed

- The deviation codes A1-D1 and A1-D6 (S3.2).
- BLIND package only: `customXml/item1.xml` (Google Docs round-trip payload, which decodes to 42 bytes with no names), `customXml/itemProps1.xml`, `customXml/_rels/item1.xml.rels`, `docProps/custom.xml` (empty), the customXml relationship in `word/_rels/document.xml.rels`, the custom-properties relationship in `_rels/.rels`, and both overrides in `[Content_Types].xml`. The zip tests clean.

## BLIND sweep (every zip part, base64 payloads decoded, plus the BLIND PDF text)

Patterns: Weiskittel, Sprecher, Gottesman, Rice, Maine, Forest Solutions, Midgard, CRSF, orcid, zenodo.21081014, zenodo.22997704, holoros, MidgardNaturalResources.

All 6 hits are allowed third-person citations of Weiskittel works: Weiskittel et al., 2011 (twice in the text), Weiskittel et al., 2016 (in the text), and the reference entries Chen et al. 2023, Weiskittel et al. 2011 and Weiskittel et al. 2016. There are no hits for the other patterns. The PDF text grep matched "maine" once inside "remained", which is a false positive. core.xml creator and lastModifiedBy are empty, and the PDF has no author metadata. Owen et al. (2022) is not cited in the supplement. The named file keeps its customXml parts, since stripping them was not requested for it.

## Not applied, with reasons

1. **"harness" in 3 projection contexts.** "Test set" would be wrong where harness means the projection setup, so these became: "describe the simulator as much as koa growth" (S7.2), "not tabulated for the uneven-aged scenario" and "a simulator diameter ceiling" (Table S30 notes).
2. **"previous deposit" in S8 [VERIFY].** It now reads "Deposit versions before 1.9.0 ship one R carrier of the engine, HiGy_engine_v053_mortality.R ..., and the three R carriers staged through version 1.8.0 were retired in version 1.9.0." The mapping follows the instruction. Confirm that the v053 carrier was in the versions before 1.9.0 and not only in the later ones.
3. **Other "earlier" phrases were left alone** because they were not in the M7 list: earlier fit (2), earlier validation, vector, height (2), trajectories, development sample, design, natural departure, value and bootstrap. Also left alone: "(earlier −0.097 ...)" in the Table S25 notes, "flagged for the next deposit version" (Data flags paragraph), and the deposit labels version 1.8.0, version 1.9.0 and DEPOSIT_CHANGELOG.md (RT7 N8). A follow-up pass could change "earlier fit" to "original fit" if wanted.
4. **ST4 D7 citation order.** Table S2 is still cited before S1 in S1.1, and S33 before S3 in S1.3. As instructed, nothing was renumbered or reordered, and only the preamble claim was softened.
5. **ST4 D10 (Pretzsch order).** This item is in the main manuscript, so it is out of scope here.
6. **Dataset reference.** It still reads Version 1.9.5 with the concept DOI. Under RT7 M7, s105 needs a new deposit version, and the version and version DOI have to be updated in the supplement, manuscript, title page and cover letter once that version exists.
7. **Orphan `word/media/image9.png`** (rId10, 332,785 bytes, a four-panel stand development plot). No `r:embed` points to it in either file. Report only, not removed.

## Outputs, md5 and page counts

| File | md5 | Pages |
|---|---|---|
| koa_supplemental_v104.docx (input) | edc052b9924b491cf505d94f862e5110 | 52 |
| koa_supplemental_v104_BLIND.docx (input) | 5e614b9b7b309baf97abd2c19b0bdce2 | 52 |
| koa_supplemental_v105.docx | e9c3d0ea713cd480358c94209a3f7bd1 | 52 |
| koa_supplemental_v105_BLIND.docx | dbc54309e4e06715792eb7de22a1bcbc | 52 |
| koa_supplemental_v105_REVIEW.pdf | 0c44bc0ffdd3fd6b21832aff1fc4c08b | 52 |
| koa_supplemental_v105_BLIND_REVIEW.pdf | 81c3b466f59acc090d7ce393ff8bfa2c | 52 |

Page counts come from LibreOffice renders of both versions. I viewed these pages at 70 dpi: 1 (preamble), 2 and 3 (S1.3 heading and restyled body, retention sentence), 4 (S2.2), 16 and 17 (S7.2 and S8), 17 and 18 (references, named and BLIND) and 30 (Table S15 cells). Text, superscripts and indents render correctly, and the dataset entry sits last (named) or first (BLIND).
