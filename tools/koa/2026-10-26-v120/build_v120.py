"""Build koa manuscript v120, supplement s113, cover letter v120 and title page v120 from v119/s112.

Applies the confirmed fixes of the October 26, 2026 verification round (ADJUDICATION_R1) and the
non-RISK voice edits (VOICE_R1), under the frozen-content rule. Every edit is anchored on text that
must occur exactly once in exactly one paragraph (docedit.replace_in), so a miss raises.

Usage: python3 build_v120.py
"""
import sys, copy, shutil
sys.path.insert(0, '/tmp/koa/build')
from docx import Document
from docx.oxml.ns import qn
import docedit as de

SRC = '/tmp/koa'
OUT = '/tmp/koa/out'
LOG = []

def allpars(doc):
    return list(de.iter_all_pars(doc))

def rep(doc, old, new, count=1, where=None):
    pars = [p for p in allpars(doc) if old in p.text]
    if where is not None:
        pars = [p for p in pars if where in p.text]
    if len(pars) != 1:
        raise ValueError('anchor %r matched %d paragraphs' % (old[:70], len(pars)))
    de.replace_in(pars[0], old, new, count=count)
    LOG.append((old[:60], new[:60]))

def rep_all(doc, old, new):
    """Replace in every paragraph that holds old (all occurrences). Returns n paragraphs."""
    n = 0
    for p in allpars(doc):
        c = p.text.count(old)
        if c:
            de.replace_in(p, old, new, count=c); n += c
    LOG.append((old[:60], new[:60], n))
    return n

# ---------------------------------------------------------------- manuscript
def build_ms(src, dst, blind):
    d = Document(src)
    # Confirmed defects
    rep(d, 'which holds stands younger than about 18 years on a BYI of 158 to 561',
           'which holds stands younger than about 18 years on a BYI of 109 to 561', where='Table 5.')            # V-C4
    rep(d, 'Planted rows below a BYI of 158 Mg ha−1 remain untested',
           'Planted rows below a BYI of 109 {Mgha} remain untested')                                             # V-C4
    rep(d, 'Source ratios 0.88 (DOFAW) to 1.38 (KMR PSP)',
           'Source ratios 0.44 (DOFAW planted) to 1.38 (KMR PSP)')                                               # V-C5
    rep(d, 'QMD does not fall with density, because density-dependent mortality allocated by Eq. 5 removes the smallest stems fastest.',
           'QMD at age 40 is not ordered by initial density, because density-dependent mortality allocated by Eq. 5 removes the smallest stems fastest (Table S31).')  # V-C6
    rep(d, 'Without these two plots, the 6,209 diameter increment records of the original frame span',
           'Without these two plots, the remaining 4,715 records of the diameter calibration frame span')          # V-6209
    rep(d, 'and uneven-aged stands from a single cohort that acquires structure through recruitment (Section S5)',
           'and uneven-aged stands from a single class of 500 {sph} at 8.0 cm DBH that acquires structure through recruitment (Section S5)')  # A3a
    rep(d, 'BA.perc is the expansion-weighted share of the other live stems at least as large as the subject, which matches',
           'The quantity 1 − BA.perc is the expansion-weighted share of the other live stems at least as large as the subject, which matches')  # B2
    rep(d, 'whereas the planted rate is left unscaled (Section S4.3).',
           'whereas the planted rate is left unscaled, a choice made on the original covariates and not revalidated on the recomputed system (Section S4.3; Table S23).')  # A5
    rep(d, 'so the limiting line implies a Reineke slope of −1.92.',
           'so the limiting line implies a Reineke slope of −1.92, steeper than the −1.43 (95% interval −1.68 to −1.20) boundary fitted at τ = 0.99 to the plot record on the original covariates (Section S7.2).')  # A6b
    rep(d, 'which the calibration below reconciles', 'which the origin calibration of Section S3.2 reconciles')   # B25
    rep(d, 'Stage 3: 4,223 records, 877 deaths, 51 installations',
           'Stage 3: deployed vector fitted to the 4,911-record sample before deduplication, with the refit on 4,223 records (877 deaths, 51 installations) keeping every sign (Table S15)')  # A10
    rep(d, 'Basal area equivalent when origins are pooled (−0.96 m2 ha−1; Table S25)',
           'Basal area equivalent in the mean but not in slope when origins are pooled (−0.96 {m2ha}; Table S25)')  # A12
    if not blind:
        rep(d, 'Version 1.9.6. Zenodo. https://doi.org/10.5281/zenodo.21081014 (concept DOI, which resolves to the current version).',
               'Version 1.9.6. Zenodo. https://doi.org/10.5281/zenodo.23399505')                                  # B12
    rep(d, 'and uneven-aged natural stands with ingrowth (columns)',
           'and uneven-aged natural stands with ingrowth (500 {sph} in a single 8.0 cm class at start) (columns)')  # A3a, Fig. 5
    # B4: move the [dataset] entry to follow Weiskittel et al. 2011
    pars = d.paragraphs
    ds = [p for p in pars if p.text.startswith('[dataset]')]
    w11 = [p for p in pars if p.text.startswith('Weiskittel, A.R., Hann, D.W.')]
    assert len(ds) == 1 and len(w11) == 1
    w11[0]._p.addnext(ds[0]._p)
    LOG.append(('move [dataset] entry after Weiskittel 2011',))
    # B18: heading style for 2.4.3
    h = [p for p in pars if p.text.strip() == '2.4.3 Survival equation']
    assert len(h) == 1
    ref = [p for p in pars if p.text.strip() == '2.4.4 Ingrowth'][0]
    h[0].style = ref.style
    for r in h[0].runs:
        r.bold = True
    LOG.append(('2.4.3 -> Heading 3',))
    # B23: duplicate corresponding affiliation line (named only)
    if not blind:
        dup = [p for p in pars[:15] if p.text.strip() == 'Center for Research on Sustainable Forests, University of Maine, Orono, ME 04469, USA']
        if len(dup) == 1:
            dup[0]._p.getparent().remove(dup[0]._p)
            LOG.append(('removed duplicate affiliation line',))
    # Voice edits (VOICE_R1, non-RISK)
    rep(d, "and produces one of the world's most valuable tropical timbers, with full-curl figured lumber selling for about USD 65 to 150 per board foot and stumpage for USD 3 to 4 per board foot (Wiedenbeck and Lowell, 2017).",
           "and produces one of the world's most valuable tropical timbers. Full-curl figured lumber sells for about USD 65 to 150 per board foot and stumpage for USD 3 to 4 per board foot (Wiedenbeck and Lowell, 2017).")  # M1
    rep(d, 'Claude (Anthropic) assisted in writing and checking analysis code. The authors reviewed and ran all code.',
           'Claude (Anthropic) assisted in writing and checking analysis code, and we reviewed and ran all code.')  # M4
    rep(d, 'depending on site, so projection ages understate stand age by at least these spans plus the time needed to reach 2.5 cm, and by more where natural stems grew under heavier competition.',
           'depending on site. Projection ages therefore understate stand age by at least these spans plus the time needed to reach 2.5 cm, and by more where natural stems grew under heavier competition.')  # M5
    rep(d, 'and peak height increment near 7 and 3 m, and at the stand basal area of 30 m2 ha−1 in Fig. 3a, b the diameter peaks',
           'and peak height increment near 7 and 3 m. At the stand basal area of 30 {m2ha} in Fig. 3a, b the diameter peaks')  # M8
    rep(d, 'bootstrap interval 0.032 to 3.887), a crossover that the origin constants remove in the calibrated forms, where',
           'bootstrap interval 0.032 to 3.887). The origin constants remove this crossover in the calibrated forms, where')  # M9
    rep(d, '(plot-clustered 95% interval +0.019 to +0.318), and in sensitivity fits on the original intervals',
           '(plot-clustered 95% interval +0.019 to +0.318). In sensitivity fits on the original intervals')  # M10
    rep(d, 'the self-thinning response expected of crowded stands, but no detectable response in the planted intervals',
           'the self-thinning response expected of crowded stands. In contrast, it gave no detectable response in the planted intervals')  # M11
    rep(d, 'is 2.54 (2.00 to 5.18 from a plot-cluster bootstrap) and ranged from 2.36 to 3.03',
           'is 2.54 (2.00 to 5.18 from a plot-cluster bootstrap) and ranges from 2.36 to 3.03')  # M12
    rep(d, 'mean planted survival is equivalent (+0.030) whereas mean natural survival is not',
           'mean planted survival is equivalent (+0.030), whereas mean natural survival is not')  # M13
    rep(d, 'basal area and volume rise with density before age 60, and in projection the largest tree',
           'basal area and volume rise with density before age 60. In projection the largest tree')  # M14
    rep(d, 'which is consistent with a site effect expressed in diameter and biomass, although the height terms are weakly identified and part of the contrast',
           'which is consistent with a site effect expressed in diameter and biomass. However, the height terms are weakly identified, and part of the contrast')  # M16
    rep(d, 'when the shape was re-estimated (Table S6), so it is best read as a productivity index',
           'when the shape was re-estimated (Table S6). It is therefore best read as a productivity index')  # M17
    rep(d, 'and the log transform make this approximate, and the width of their installation-cluster intervals',
           'and the log transform make this approximate. The width of their installation-cluster intervals')  # M18
    rep(d, 'The site response is weakly identified, and below a BYI of 150 Mg ha−1 the natural increment records',
           'The site response is weakly identified. Below a BYI of 150 {Mgha} the natural increment records')  # M20
    rep(d, 'overpredicts the few intervals of 11 to 20 years about threefold, so a refit that removes the large-tree shortfall of the height increment and the competition gradient of the diameter increment, scored against the recalibrated diameter vector on identical covariates, is the first task for the next release.',
           'overpredicts the few intervals of 11 to 20 years about threefold. A refit that removes the large-tree shortfall of the height increment and the competition gradient of the diameter increment, scored against the recalibrated diameter vector on identical covariates, is therefore the first task for the next release.')  # M21
    rep(d, 'whose mapped covariates are themselves suspect (Section S6.2), and which at a BYI of 25 Mg ha−1 and 52 years after its first measurement is projected at',
           'whose mapped covariates are themselves suspect (Section S6.2). At a BYI of 25 {Mgha} and 52 years after its first measurement, it is projected at')  # M22
    if not blind:
        rep(d, 'in the collection, analysis or interpretation of data,', 'in the collection, analysis, or interpretation of data,')  # M23
    rep(d, 'carry the recomputed stand covariates used here, is the version of record',
           'carry the recomputed stand covariates used in this analysis, is the version of record')  # M24
    rep(d, 'with correction factors and origin constants, bands on them are 95% installation-cluster bootstrap intervals',
           'with correction factors and origin constants. Bands on them are 95% installation-cluster bootstrap intervals')  # M25
    rep(d, 'where only the Kulani plantation is older, dotted lines the diameter ceilings',
           'where only the Kulani plantation is older. Dotted lines mark the diameter ceilings')  # M26
    rep(d, 'is not distinguishable from zero at the installation level, and it was not repeated on the recomputed covariates (Section S3.1).',
           'is not distinguishable from zero at the installation level. The bootstrap was not repeated on the recomputed covariates (Section S3.1).')  # M27
    d.save(dst)

# ---------------------------------------------------------------- supplement
OXFORD = [
    ('Equations, tables, figures and sections', 'Equations, tables, figures, and sections'),
    ('natural forests, managed plantations, dryland restoration sites and agroforestry trials', 'natural forests, managed plantations, dryland restoration sites, and agroforestry trials'),
    ('BAPH, SDI and QMD', 'BAPH, SDI, and QMD'),
    ('May 2018, June 2019, November 2020 and March 2021', 'May 2018, June 2019, November 2020, and March 2021'),
    ('Kahikinui, KMR CAR, Kualoa, Mauka and Kap', 'Kahikinui, KMR CAR, Kualoa, Mauka, and Kap'),
    ('BAPH, trees ha−1, QMD and SDI', 'BAPH, trees ha^−1^, QMD, and SDI'),
    ('KMR PSP, Kualoa, Mauka and PSP sources', 'KMR PSP, Kualoa, Mauka, and PSP sources'),
    ('Oahu, Maui County and Kauai', 'Oahu, Maui County, and Kauai'),
    ('100, 264 and 450 Mg ha−1', '100, 264, and 450 Mg ha^−1^'),
    ('a documented sample, independence from current stocking and invariance', 'a documented sample, independence from current stocking, and invariance'),
    ('g1 (0.019 to 0.102) and g2', 'g~1~ (0.019 to 0.102), and g~2~'),
    ('b0, b1, b3, b4 and b5', 'b~0~, b~1~, b~3~, b~4~, and b~5~'),
    ('as in FVS, its Acadian variant and ORGANON, the crown, increment and mortality submodels', 'as in FVS, its Acadian variant, and ORGANON, the crown, increment, and mortality submodels'),
    ('0.292, 0.368, 0.246, 0.335 and 0.245', '0.292, 0.368, 0.246, 0.335, and 0.245'),
    ('BAL2, ln(CR) and ln(BYI)', 'BAL^2^, ln(CR), and ln(BYI)'),
    ('source, installation, plot and year', 'source, installation, plot, and year'),
    ('(live list) and 0.996 and 2.390 (conventional)', '(live list), and 0.996 and 2.390 (conventional)'),
    ('PSP, KMR PSP, Kualoa and Mauka', 'PSP, KMR PSP, Kualoa, and Mauka'),
    ('terminal diameter, height and expansion factor', 'terminal diameter, height, and expansion factor'),
    ('0.93, 0.74 and 0.59 over one, five and ten years', '0.93, 0.74, and 0.59 over one, five, and ten years'),
    ('Waikamoi 2.45 and PSP 122 2.40', 'Waikamoi 2.45, and PSP 122 2.40'),
    ('origin multipliers, planted guards and 2 m yr−1 height clip', 'origin multipliers, planted guards, and 2 m yr^−1^ height clip'),
    ('every volume, increment and carbon figure', 'every volume, increment, and carbon figure'),
    ('0.806 and 0.808 to 0.351, 0.365, 0.648 and 0.644', '0.806, and 0.808 to 0.351, 0.365, 0.648, and 0.644'),
    ('0.977, 0.962 and 0.988', '0.977, 0.962, and 0.988'),
    ('0.055, 0.126 and 0.071', '0.055, 0.126, and 0.071'),
    ('0.016 and 0.026 yr−1 against 0.018, 0.021 and 0.046', '0.016, and 0.026 yr^−1^ against 0.018, 0.021, and 0.046'),
    ('0.020 and 0.063 yr−1 against 0.018, 0.023 and 0.049', '0.020, and 0.063 yr^−1^ against 0.018, 0.023, and 0.049'),
    ('the process, BYI and initialization errors', 'the process, BYI, and initialization errors'),
    ('2.44 without Waiakea and 2.53 without Waikamoi', '2.44 without Waiakea, and 2.53 without Waikamoi'),
    ('20, 40, 60 and 100 yr', '20, 40, 60, and 100 yr'),
    ('57.2 planted and 50.4 uneven-aged', '57.2 planted, and 50.4 uneven-aged'),
    ('429, 889 and 624', '429, 889, and 624'),
    ('Laupahoehoe 41 and Waikamoi 25', 'Laupahoehoe 41, and Waikamoi 25'),
    ('911, 776 and 634', '911, 776, and 634'),
    ('20, 30 and 50 cm', '20, 30, and 50 cm'),
    ('low, medium and high sites', 'low, medium, and high sites'),
    ('−1.61 and −1.70 for planted', '−1.61, and −1.70 for planted'),
    ('98, 87 and 72', '98, 87, and 72'),
    ('19.4 and 25.2% higher, QMD 8.3, 12.8 and 15.6% larger and stems 9.8, 15.0 and 15.7% fewer', '19.4, and 25.2% higher, QMD 8.3, 12.8, and 15.6% larger, and stems 9.8, 15.0, and 15.7% fewer'),
    ('105, 84 and 77 years to 111, 101 and 97 years', '105, 84, and 77 years to 111, 101, and 97 years'),
    ('181, 164 and 155', '181, 164, and 155'),
    ('37, 25 and 20', '37, 25, and 20'), ('12, 8 and 7', '12, 8, and 7'), ('30, 20 and 17', '30, 20, and 17'),
    ('62, 41 and 33, 15, 11 and 9, and 58, 37 and 29', '62, 41, and 33, 15, 11, and 9, and 58, 37, and 29'),
    ('120, 230, 340 and 450', '120, 230, 340, and 450'),
    ('4.4, 3.1 and 2.3', '4.4, 3.1, and 2.3'), ('1.1, 0.76 and 0.58', '1.1, 0.76, and 0.58'),
    ('threshold provenance for Eq. 9 and figure provenance', 'threshold provenance for Eq. 9, and figure provenance'),
    ('S7.2 Self-thinning, biological consistency and the diameter ceiling', 'S7.2 Self-thinning, biological consistency, and the diameter ceiling'),
]

def build_supp(src, dst):
    d = Document(src)
    if 'BLIND' not in src:
        rep(d, 'Version 1.9.6. Zenodo. https://doi.org/10.5281/zenodo.21081014 (concept DOI, which resolves to the current version).',
               'Version 1.9.6. Zenodo. https://doi.org/10.5281/zenodo.23399505')  # B12 propagation
    rep(d, 'The highest published koa basal area, 42 m2 ha−1 (Harrington et al., 1995), maps',
           'The 42 {m2ha} reported for natural koa stands (Harrington et al., 1995) maps')  # B14
    p = [p for p in allpars(d) if p.text.startswith('Notes. c Leave-one-installation-out bias, since the in-sample origin bias')]
    assert len(p) == 1
    de.replace_in(p[0], 'published ranges for comparison (Section S3.5).',
                  'published ranges for comparison (Section S3.5). The HCB rows are the mixed-effects fit of Eq. 3 on the deposited covariates, not the deployed crown vector, whose statistics are in Table S9 (Section S3.1).')  # A13
    rep(d, 'Density-independent annual mortality, natural origin',
           'Density-independent annual mortality, natural origin, carried from the original simulator (koa_survival_calibrated.R in the deposit) rather than estimated from the data')  # A6c
    rep(d, 'Density-independent annual mortality, planted origin',
           'Density-independent annual mortality, planted origin, carried from the original simulator (koa_survival_calibrated.R in the deposit) rather than estimated from the data')  # A6c
    rep(d, 'The simulator now returns BA.perc as (W≥,i − wi)/(W − wi), the expansion-factor share of the other stems at least as large as stem i, which reduces',
           'The simulator now returns 1 − BA.perc as (W~≥,i~ − w~i~)/(W − w~i~), the expansion-factor share of the other stems at least as large as stem i, which reduces')  # B2
    rep(d, 'Uneven-aged stands start as a single cohort and acquire structure through recruitment.',
           'Uneven-aged stands start as a single class of 500 {sph} at 8.0 cm DBH with crown ratio 0.6 and height from Eq. 2, and acquire structure through recruitment.')  # A3a
    # Voice
    rep(d, 'at 19–22°N', 'at 19 to 22°N')  # S2
    rep(d, 'The treatment sheet lists PSP 122 as untreated. Without that interval the natural level factor is 2.40 instead of 2.54.',
           'The treatment sheet lists PSP 122 as untreated, and without that interval the natural level factor is 2.40 instead of 2.54.')  # S3
    rep(d, 'becomes a true 2014 to 2016 row, the height frame stays at 3,857 rows, the Stage 1 input falls from 326 to 318 plot intervals (290 to 282 fitted), the M1 pair table from 415 to 407 intervals and the ingrowth frame',
           'becomes a true 2014 to 2016 row. The height frame stays at 3,857 rows, the Stage 1 input falls from 326 to 318 plot intervals (290 to 282 fitted), the M1 pair table from 415 to 407 intervals, and the ingrowth frame')  # S5
    rep(d, 'matched the free estimate to 5 × 10−4, which indicates that b5 was fixed',
           'matched the free estimate to 5 × 10^−4^. This indicates that b~5~ was fixed')  # S6
    rep(d, 'b5 > 0, b6 < 0, and height', 'b~5~ > 0, b~6~ < 0, and height')  # S7 markup slip
    rep(d, 'on the calibration frame was at most 0.25, with conventional BAL preferred unless another eligible candidate was more than 2% lower in RMSE and with the candidate whose widest equivalence region was narrowest as the fallback.',
           'on the calibration frame was at most 0.25. Conventional BAL was preferred unless another eligible candidate was more than 2% lower in RMSE, and the candidate whose widest equivalence region was narrowest was the fallback.')  # S7
    rep(d, '2.19 on PSP and 3.03 on KMR PSP, and the natural constant 0.80 on DOFAW and 1.04 on FIA, while the planted height constant runs from 0.43 (DOFAW) to 4.71 (KMR PSP) and the natural one from 0.17 (FIA) to 0.46 (DOFAW), so the pooled planted constant is in effect the PSP constant',
           '2.19 on PSP, and 3.03 on KMR PSP, and the natural constant 0.80 on DOFAW and 1.04 on FIA, while the planted height constant runs from 0.43 (DOFAW) to 4.71 (KMR PSP) and the natural one from 0.17 (FIA) to 0.46 (DOFAW). The pooled planted constant is therefore in effect the PSP constant')  # S8
    rep(d, 'on a scale where the network offset is 1.03, and a stem density term (ln TPH)',
           'on a scale where the network offset is 1.03. A stem density term (ln TPH)')  # S9
    rep(d, 'falls from 0.813 to 0.633 and 7 of its 62 leave-one-installation-out refits fail to converge, because the FIA crown ratios',
           'falls from 0.813 to 0.633, and 7 of its 62 leave-one-installation-out refits fail to converge. The reason is that the FIA crown ratios')  # S10
    rep(d, 'was initialized from its own tree list and projected over its own length without ingrowth, deaths were counted on the initial cohort',
           'was initialized from its own tree list and projected over its own length without ingrowth. Deaths were counted on the initial cohort')  # S12
    rep(d, 'BAL up to 5 and BAPH up to 10 m2 ha−1, so projection ages understate stand age by at least these spans',
           'BAL up to 5, and BAPH up to 10 {m2ha}. Projection ages therefore understate stand age by at least these spans')  # S13
    rep(d, 'uses tree basal area in the height increment density term and applies the Stage 1 gate inside its own allocation, so a planted test list differs by up to 5.0 cm in DBH after ten years, the Stage 1 record carries',
           'uses tree basal area in the height increment density term, and applies the Stage 1 gate inside its own allocation, so a planted test list differs by up to 5.0 cm in DBH after ten years. The Stage 1 record carries')  # S14
    rep(d, 'Open differences are recorded rather than hidden.', 'Open differences are recorded.')  # S15
    ds = [p for p in d.paragraphs if p.text.startswith('[dataset]')]
    wil = [p for p in d.paragraphs if p.text.startswith('Wilton, I.A.')]
    assert len(ds) == 1 and len(wil) == 1, (len(ds), len(wil))
    wil[0]._p.addprevious(ds[0]._p)
    LOG.append(('supp: move [dataset] entry before Wilton',))
    miss = []
    for old, new in OXFORD:
        n = rep_all(d, old, new)
        if n == 0:
            miss.append(old)
    print('OXFORD segments not found:', miss)
    d.save(dst)

# ---------------------------------------------------------------- cover letter and title page
def build_cover(src, dst):
    d = Document(src)
    rep(d, 'October 21, 2026', 'October 26, 2026')
    rep(d, 'yet it has had no growth and yield model.', 'yet, to our knowledge, it has had no growth and yield model.')  # B9
    rep(d, 'Three contributions should interest the readership of the journal. The first is ecological.',
           'Three contributions should interest the readership of the journal, and the first is ecological.')  # C1
    rep(d, 'calibrated on 24 remeasured natural plot intervals and a survival equation',
           'calibrated on 24 remeasured natural plot intervals, and a survival equation')  # C2 (comma only)
    rep(d, 'The data, code and reproduction scripts', 'The data, code, and reproduction scripts')  # C3
    rep(d, 'has not been published elsewhere and is not under consideration', 'has not been published elsewhere, and is not under consideration')  # C4
    rep(d, 'Competing interests are declared in the manuscript and on the title page: two authors',
           'Competing interests are declared in the manuscript and on the title page. Two authors')  # C5
    d.save(dst)

def build_title(src, dst):
    d = Document(src)
    rep(d, 'After using this tool, the authors reviewed and edited the content as needed and take full responsibility for the content of the published article.',
           'The authors oversaw all use, reviewed and edited the content as needed, and take full responsibility for the content of the published article.')  # B21
    for old, new in [('visualization and supervision', 'visualization, and supervision'),
                     ('methodology (BYI modeling) and writing', 'methodology (BYI modeling), and writing'),
                     ('formal analysis (spatial) and writing', 'formal analysis (spatial), and writing'),
                     ('software (FVS-HI variant) and writing', 'software (FVS-HI variant), and writing')]:
        rep(d, old, new)  # B22, Oxford commas in the title-page CRediT prose
    d.save(dst)

if __name__ == '__main__':
    import os; os.makedirs(OUT, exist_ok=True)
    build_ms(f'{SRC}/koa_manuscript_v119_FINAL.docx', f'{OUT}/koa_manuscript_v120_FINAL.docx', blind=False)
    n1 = len(LOG)
    build_ms(f'{SRC}/koa_manuscript_v119_FINAL_BLIND.docx', f'{OUT}/koa_manuscript_v120_FINAL_BLIND.docx', blind=True)
    build_supp(f'{SRC}/koa_supplemental_v112_FINAL.docx', f'{OUT}/koa_supplemental_v113_FINAL.docx')
    build_supp(f'{SRC}/koa_supplemental_v112_FINAL_BLIND.docx', f'{OUT}/koa_supplemental_v113_FINAL_BLIND.docx')
    build_cover(f'{SRC}/koa_cover_letter_v119.docx', f'{OUT}/koa_cover_letter_v120.docx')
    build_title(f'{SRC}/koa_title_page_v119.docx', f'{OUT}/koa_title_page_v120.docx')
    print('edits logged:', len(LOG))
