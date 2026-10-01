# Red team 6 and stress test 3, koa Forest Ecosystems package, October 1, 2026

Floor: `koa_manuscript_v106_DRAFT.docx`, `koa_supplemental_v104.docx`, `koa_cover_letter_v106.docx`, `koa_title_page_v106.docx`. Output: `koa_manuscript_v107_DRAFT.docx` and `_BLIND`, `koa_cover_letter_v107.docx`, each with a `_REVIEW.pdf`. The supplement (s104) and title page (v106) are unchanged, so Zenodo 1.9.5 (which carries s104) stays the version of record and no new deposit version is needed.

The red team ran as a hostile reviewer under manuscript-review Module 2 (G, S, V, Q, DD and PD audits) with the settled modeling decisions off the table. The stress test re-derived 47 numbers by script from the documents' own tables, checked all 45 supplement cross references, the eleven main figure and table citations, the abstract against the body, the cover letter against the manuscript, and the abstract and keyword limits. Every re-derivation agreed and every reference resolved. The findings below are therefore about what the text claims, not about arithmetic.

## Lead finding, and whether the abstract survives it

The deployed natural mortality level is framed in 3.3.3 and 4.4 as realizing one fifth to one third of "the observed natural rate," but the 5.6% yr⁻¹ it is compared against is the pooled rate over all 282 Stage 1 intervals, 267 of them planted. On the natural units outside the calibration frame the supplement reports the opposite error direction. S6.1 gives 0.063 against 0.049 yr⁻¹ in the high density FIA tertile, survival 0.181 below observation on the two independent FIA plots, and 0.103 against 0.215 on the burned plot, so the calibrated rate removed more trees in nine years than the fire did. The v106 abstract reported only the QMD error on the independent plots. v107 adds the survival error to the abstract, restates the comparison rate correctly in 3.3.3 and 4.4, and says in 4.4 that the rate overprojects mortality at high density on the FIA subplots. The abstract survives with those edits.

## MUST FIX, all applied in v107

1. Abstract, 3.3.3, 4.4. Pooled rate mislabeled as the natural rate; independent plot survival error omitted from the abstract; fire plot framed as under projected when it was over projected. Edits as above.
2. Abstract and 4.2. "indicates broad productivity differences" and "assigns coarse site classes on Hawaii Island only (Section S2.2)" were not supported, since 3.2 reports an out of bag R² of −0.48 on the 235 forested plots and S2.2 holds no site class test. Abstract now reads "separates forest from nonforest but not productivity among forested plots"; 4.2 now says the surface shows no demonstrated skill among forested plots even on Hawaii Island (Section 3.2; Table S7).
3. Section 2.5. Claimed leave-one-installation-out refitting of the increment equations, but S3.2 states no such refit exists for the repaired calibration. Now reads "by holding out data sources and, under the earlier calibration only, by leave-one-installation-out refitting (Section S3.2)".
4. Fig. 6 caption. "standing plus thinned and dead volume divided by age" contradicted Table S31 (standing plus thinned only) and would have put the figure 25% below the gross MAI of Table 5 for the same scenario. Now "standing plus thinned volume divided by age, excluding dead volume".

## SHOULD FIX, applied

5. Section 2.6 named six natural plots as setting the mortality level; 3.3.3 says seven plots. PSP 122 added.
6. Table 5 note pointed at a basal area column Table 5 does not have. Now points at Table S30.

## SHOULD FIX and NOTE, deferred with reasons

7. Section 3.5 and Fig. 4. Planted projections at age 20 reach 41 to 50 m² ha⁻¹ and SDI 790 to 862 against a PSP mean BAPH of 19.6 (Table S2). The claim that planted projections leave the record "beyond about age 18" may be generous. Deferred because the maximum observed plantation BAPH and SDI are not in the documents and need a frame query on firebreather; one sentence to add at proof or in revision.
8. Section 3.3.1 and abstract. The LOIO height R² of 0.798 with bias −0.053 beats the population average form (0.788, −0.395), which implies the held out predictions keep the data source intercept. Deferred pending a read of the LOIO script; if confirmed, one clause in 3.3.1.
9. Section 4.1. The Leary (1997) sentence on mean size and density is already placed among the limitations; left as is.
10. Section 4.4. Planted mortality left unscaled: S4.3 gives the operative reason (the 3.50 factor broke validation survival and volume ordering under the earlier engine, not rerun). One sentence in 4.4 would help; deferred as a revision item.
11. Fig. 5(c). Waikamoi 25 projected basal area rises 28 to 33 m² ha⁻¹ in two years then falls; an initialization transient the text does not mention. Deferred.
12. Section 4.4. Baker and Scowcroft (2005) stocking guideline not compared against the projected SDI cap of 430. Deferred to revision.
13. Items on interval interpretation (2.4.2), the deployed survival vector not being the cross validated one (2.4.3), the 69.7 cm planted ceiling rationale (2.6), and the duplicate 354 mean BYI in Table 1 (DOFAW and PSP) are noted for the response to reviewers. The 354 duplicate should be checked against the Table 1 build script before submission; the weighted mean of the column reproduces the 318 total within 1.3 units, so a copy error is unlikely but not excluded.

## Stress test record

Forty seven re-derivations, all agree: Table 1 sums (158, 9,164) and weighted mean BYI (318); occurrence 117 of 282 (41.5%); R² of 0.381 and 0.264 from RMSE and the Table 2 SDs; thirteen net MAI cells of Table 5 as volume over age; stemwood carbon 38 and 47 Mg C ha⁻¹ from 160 and 197 m³ ha⁻¹; the 2.9% koa only constant difference; 2.193 × 1.38 = 3.03; Reineke −1.92 from kHD 1.0411; volume ordering by BYI at 40 and 100 in all three stand types; the three equivalence regions as 25% of the implied observed means; the three pooled 17 plot errors from the 6 and 11 plot origin means; the abstract 3.9 against 3.85; the height R² ordering; the level factor inside its bootstrap and jackknife intervals. Not re-derivable from the documents: the 9.1 million stems and 3.8 million m³ FIA figures, the 877 and 4,223 record counts, the 25 of 51 fold count, and the 1.2 to 1.8% yr⁻¹ realized rate.

One extraction artifact worth recording. Fifteen text fragments in the manuscript sit inside Google Docs content controls (w:sdt), including the b6 √(BAPH×size) term of Eq. 4, so a python-docx paragraph dump omits them. The red team flagged Eq. 4 as missing the term on that basis; the rendered PDF carries it. A first attempt to insert the term duplicated it and was reverted before saving; the v107 render shows the equation once and correct. Future text dumps of this file should read w:sdt content.

## Content inventory, v106 to v107

Added: survival error in the abstract; qualifier on the LOIO claim in 2.5; PSP 122 in 2.6; interval frame qualifier in 3.3.3; high density overprojection and fire plot direction in 4.4. Changed: abstract BYI claim; 4.2 site class claim; Fig. 6 caption MAI definition; Table 5 note cross reference; one word cut in the abstract (299 words). Removed: nothing. Cover letter v107 changes two counts (about 8,400 words, 299 word abstract). Title page, supplement, figures unchanged.
