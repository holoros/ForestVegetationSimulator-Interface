# -*- coding: utf-8 -*-
"""s105 supplement (named and BLIND) from s104. Rerunnable.

RT7 M7 (published -> original, revision-log language), ST4 D4 (S2.2 BYI skill), RT7 S7 (retention rules in S1.3),
ST4 D12 / RT7 S11 (S1.3 body paragraphs restyled from Heading 2 to body), ST4 D10/D11 (dataset reference moved),
ST4 D7 (first-citation claim softened), BLIND package cleanup (customXml, docProps/custom.xml).
Every text edit is an explicit anchored replacement; no numbers, equations or table numbers are touched.
"""
import sys, re, copy, zipfile, shutil, os, collections
sys.path.insert(0, '/tmp/s105/work')
import docx
import docedit as E
from upars import upars
from docx.oxml.ns import qn

IN = '/tmp/rt7/in/'
OUT = '/tmp/s105/out/'
LOG = OUT + 'change_log.txt'

# ---------------------------------------------------------------- edit list
# Each entry: paragraph anchor (start of the s104 paragraph text, or ('=', exact text) for table cells)
# and a list of (old, new, category). old must occur exactly once in the paragraph when applied.
FS_NAMED = 'Forest Solutions Inc.'
FS_BLIND = 'The project sponsor'
def s7(sponsor_subject):
    return (' ' + sponsor_subject + ' set the record retention rules before any refit, namely that at a doubled visit '
            'the later record set is kept rather than the earlier, that at a visit whose tree status conflicts between '
            'record sets the later record set is kept, and that PSP 202 to 204 keep their 2012 diameters recorded on '
            'trees shorter than breast height, flagged as a limitation rather than dropped.')

EDITS = [
 ('This file supports the manuscript named above.', [
   ('the data and their repair,', 'the data and their quality control,', 'FRONT'),
   ('follow the text in order of first citation.',
    'are numbered broadly in order of first citation, and Table S33, which reconciles the increment frames, is placed last.', 'D7'),
 ]),
 ('Tree data were compiled from eight monitoring programs', [
   ('were recomputed in this revision from', 'were recomputed in this study from', 'THIS_REVISION'),
 ]),
 ('The deposited survival table carries 280 raw death records', [
   ('4,871 records after the repair of Section S1.3', '4,871 records after the recomputation of Section S1.3', 'REPAIR'),
   (' before the repair).', ' before the recomputation).', 'REPAIR'),
 ]),
 ('S1.3 Stand covariate repair and copied remeasurements', [
   ('Stand covariate repair and', 'Stand covariate recomputation and', 'HEADING'),
 ]),
 ('The repair rules were written into the job record', [
   ('The repair rules were written into the job record before any repair or fit was run.',
    'The recomputation rules were written into the job record before any recomputation or fit was run.', 'REPAIR'),
   ('After the repair the source maxima', 'After the recomputation the source maxima', 'REPAIR'),
 ]),
 ('Copied remeasurements were screened on every installation', [
   ('and the ingrowth frame from 358 to 357 plot-periods.', 'and the ingrowth frame from 358 to 357 plot-periods.@@S7@@', 'S7'),
 ]),
 ('The deposited FIA stand values were one quarter', [
   ('the validation of this revision pools', 'the validation in this study pools', 'THIS_REVISION'),
 ]),
 ('The repair moved at least one covariate', [
   ('The repair moved at least one covariate', 'The recomputation moved at least one covariate', 'REPAIR'),
   ('every published increment coefficient of the earlier fit inherits the unrepaired covariates',
    'every increment coefficient of the original fit inherits the original covariates', 'PUBLISHED+REPAIR'),
 ]),
 ('Aboveground biomass for each FIA subplot visit', [
   ('a decision of this revision.', 'a decision of this study.', 'THIS_REVISION'),
 ]),
 ('Blocked cross-validation lowered the pooled', [
   ('the surface separates forest from nonforest and assigns coarse productivity classes on Hawaii Island rather than predicting plot productivity.',
    'the surface separates forest from nonforest but shows no demonstrated skill among forested plots, even on Hawaii Island (Table S7).', 'D4'),
 ]),
 ('Table S8 gives fit statistics for the height equation', [
   ('on the repaired data (0.318', 'on the recomputed data (0.318', 'REPAIR'),
   ('refitted on the repaired covariates (8,914', 'refitted on the recomputed covariates (8,914', 'REPAIR'),
 ]),
 ('Installation-cluster bootstrap of the height equation.', [
   ('not repeated on the repaired frame,', 'not repeated on the recomputed frame,', 'REPAIR'),
 ]),
 ('The deployed crown base vector, carried by', [
   ('throughout the recursion of the repaired calibration,', 'throughout the recursion of the calibration on the recomputed frame,', 'REPAIR'),
 ]),
 ('Table S10 gives the complete increment estimates', [
   ('and on the repaired data the consecutive frames', 'and on the recomputed data the consecutive frames', 'REPAIR'),
   ('Under the earlier calibration, restoring them', 'Under the original calibration, restoring them', 'EARLIER'),
 ]),
 ('Selection rule. Before any increment was fitted', [
   ('recursion) from the published vector.', 'recursion) from the original vector.', 'PUBLISHED'),
   ('on the calibration frame (deviation A1-D1). Diameter', 'on the calibration frame. Diameter', 'DEVIATION'),
   ('Diameter increment deploys the published vector', 'Diameter increment deploys the original vector', 'PUBLISHED'),
   ('under the live-list BAL (deviation A1-D6), which scored', 'under the live-list BAL, which scored', 'DEVIATION'),
 ]),
 ('Back-transformation and calibration.', [
   ('deviations of the published fit (weighted', 'deviations of the original fit (weighted', 'PUBLISHED'),
   ('where the earlier system deployed the conditional factor', 'where the original calibration deployed the conditional factor', 'EARLIER'),
   ('On the repaired calibration frame the calibrated diameter', 'On the recomputed calibration frame the calibrated diameter', 'REPAIR'),
   ('Under the earlier calibration, refitting the equation', 'Under the original calibration, refitting the equation', 'EARLIER'),
   ('refit exists for the repaired calibration.', 'refit exists for the calibration on the recomputed frame.', 'REPAIR'),
 ]),
 ('Solved within each data source on the repaired calibration frame', [
   ('on the repaired calibration frame (Table S12)', 'on the recomputed calibration frame (Table S12)', 'REPAIR'),
   ('Under the earlier calibration, with one source', 'Under the original calibration, with one source', 'EARLIER'),
 ]),
 ('Respecifications and interval length.', [
   ('under the earlier calibration, the calibrated diameter', 'under the original calibration, the calibrated diameter', 'EARLIER'),
   ('On the repaired calibration frame, pooled', 'On the recomputed calibration frame, pooled', 'REPAIR'),
 ]),
 ('BAL is stand basal area allocated by a stem-count percentile', [
   ('and the published diameter fit,', 'and the original diameter fit,', 'PUBLISHED'),
   ('The repaired frames carry three definitions on the repaired BAPH',
    'The recomputed frames carry three definitions on the recomputed BAPH', 'REPAIR'),
 ]),
 ('On the 4,790 diameter increment records of the deposited frame', [
   ('Under the published coefficients the live-list', 'Under the original coefficients the live-list', 'PUBLISHED'),
   ('On the repaired frames the fraction', 'On the recomputed frames the fraction', 'REPAIR'),
 ]),
 ('Re-solved constants. Holding the published diameter vector', [
   ('Holding the published diameter vector fixed', 'Holding the original diameter vector fixed', 'PUBLISHED'),
   ('re-solved on the repaired calibration frame under each', 're-solved on the recomputed calibration frame under each', 'REPAIR'),
   ('the 0.555 of the earlier engine (', 'the 0.555 of the original calibration (', 'EARLIER'),
   ('since the repair and the change', 'since the recomputation and the change', 'REPAIR'),
   ('The multipliers recomputed in the previous revision for the unrepaired frame',
    'The multipliers recomputed in deposit versions before 1.9.0 for the original frame', 'PREVIOUS+REPAIR'),
 ]),
 ('Weighted percentile in the simulator.', [
   ('and the earlier engine ranked records without weights', 'and the simulator under the original calibration ranked records without weights', 'EARLIER'),
 ]),
 ('The archived survival table (AK_SURV.csv) was built', [
   ('The published equation, a complementary', 'The original equation, a complementary', 'PUBLISHED'),
   ('Refitted on the 4,871 repaired records it does not survive the repair,',
    'Refitted on the 4,871 recomputed records it does not survive the recomputation,', 'REPAIR'),
 ]),
 ('Recovery. On every interval ending in a zero-dimension', [
   ('and after the repair variant (ii)', 'and after the recomputation, variant (ii)', 'REPAIR'),
   ('the published form expects', 'the original form expects', 'PUBLISHED'),
   ('(1,319 before the repair)', '(1,319 before the recomputation)', 'REPAIR'),
 ]),
 ('Respecification. Three forms were fitted', [
   ('Refitted on the repaired sample,', 'Refitted on the recomputed sample,', 'REPAIR'),
   ('and to the published term set,', 'and to the original term set,', 'PUBLISHED'),
   ('The published coefficients order deaths', 'The original coefficients order deaths', 'PUBLISHED'),
   ('whose signs the repaired refit keeps,', 'whose signs the refit on the recomputed covariates keeps,', 'REPAIR'),
 ]),
 ('Table S16 gives the performance of the five component', [
   ('of the fitted components under the earlier system.', 'of the fitted components on the original covariates.', 'EARLIER'),
 ]),
 ('The ln(SDI) coefficient on occurrence is +0.166', [
   ('(0.629 before the repair)', '(0.629 before the recomputation)', 'REPAIR'),
   ('standard errors with the repair.', 'standard errors with the recomputation.', 'REPAIR'),
   ('On the unrepaired intervals occurrence', 'On the original intervals occurrence', 'REPAIR'),
 ]),
 ('Because the probability that a plot records at least one death', [
   ('refitted on the unrepaired intervals', 'refitted on the original intervals', 'REPAIR'),
   ('not repeated after the repair, which moved the published-form coefficient',
    'not repeated after the recomputation, which moved the original-form coefficient', 'REPAIR+PUBLISHED'),
 ]),
 ('Candidate stand rates differing only in how Stages 1 and 2', [
   ('were scored under the earlier engine against criteria', 'were scored on the original covariates against criteria', 'EARLIER'),
   (' under the earlier engine and delivers', ' on the original covariates and delivers', 'EARLIER'),
   ('natural levels of the repaired system.', 'natural levels of the recomputed system.', 'REPAIR'),
   ('Under the earlier engine, removing the Stage 1 gate', 'On the original covariates, removing the Stage 1 gate', 'EARLIER'),
   ('not repeated on the repaired system.', 'not repeated on the recomputed system.', 'REPAIR'),
 ]),
 ('The natural rate was calibrated in engine space', [
   ('which under the earlier engine emptied natural stands', 'which on the original covariates emptied natural stands', 'EARLIER'),
   ('because under the earlier engine its counterpart', 'because on the original covariates its counterpart', 'EARLIER'),
 ]),
 ('Each annual step (1) computes BAL by Eq. 7', [
   ('a retired single-cohort harness and', 'a retired single-cohort test set and', 'HARNESS'),
 ]),
 ('Monte Carlo uncertainty. The 500 replicates', [
   ('in the earlier harness are inert.', 'in the original test set are inert.', 'HARNESS'),
 ]),
 ('Each of the 17 remeasured plots', [
   ('Under the earlier system, on the 23-unit set', 'With the original covariates, on the 23-unit set', 'EARLIER'),
   ('on that set the repaired system projects', 'on that set the recomputed system projects', 'REPAIR'),
 ]),
 ('FIA 15-1-1-2628 lost about 60% of its koa basal area', [
   ('and the earlier system returned', 'and the original calibration returned', 'EARLIER'),
   ('on them the repaired system projects', 'on them the recomputed system projects', 'REPAIR'),
   ('for the earlier system, whereas', 'for the original calibration, whereas', 'EARLIER'),
 ]),
 ('Coverage of the nominal 95% Monte Carlo intervals', [
   ('was checked under the earlier system by projecting each of its 23 validation units',
    'was checked on the original covariates by projecting each of the 23 original validation units', 'EARLIER'),
   ('plot-level units of this revision.', 'plot-level units of this study.', 'THIS_REVISION'),
 ]),
 ('Because the level factor was solved on intervals', [
   ('rerun under the earlier system with', 'rerun on the original covariates with', 'EARLIER'),
 ]),
 ('Stand-level calibration was tested under the earlier system', [
   ('tested under the earlier system by scaling', 'tested on the original covariates by scaling', 'EARLIER'),
   ('not repeated on the repaired system.', 'not repeated on the recomputed system.', 'REPAIR'),
 ]),
 ('Table S30 gives the full projection grid', [
   ('Against the earlier system (percent', 'Against the original calibration (percent', 'EARLIER'),
 ]),
 ('Independent limiting line.', [
   ('Under the earlier system a maximum size-density line', 'On the original covariates a maximum size-density line', 'EARLIER'),
   ('implied by the repaired allometry', 'implied by the recomputed allometry', 'REPAIR'),
   ('Under the earlier system no point projection', 'On the original covariates no point projection', 'EARLIER'),
 ]),
 ('Bakuzis matrix. The modified Bakuzis matrix', [
   ('three of nine under the earlier system.', 'three of nine under the original calibration.', 'EARLIER'),
   ('(one site under the earlier system)', '(one site under the original calibration)', 'EARLIER'),
   ('Under the earlier system the natural slopes', 'Under the original calibration the natural slopes', 'EARLIER'),
   ('No gate in the harness checks', 'No gate in the test set checks', 'HARNESS'),
 ]),
 ('Planted diameter ceiling.', [
   ('Under the earlier system, with a 90 cm', 'Under the original calibration, with a 90 cm', 'EARLIER'),
   ('describe the harness as much as koa growth', 'describe the simulator as much as koa growth', 'HARNESS'),
 ]),
 ('The behavior scenarios run the deployed engine', [
   ('Under the earlier system the same pattern', 'Under the original calibration the same pattern', 'EARLIER'),
 ]),
 ('Net MAI culmination. The initial list', [
   ('Under the earlier system, deterministic runs', 'Under the original calibration, deterministic runs', 'EARLIER'),
 ]),
 ('Reproducibility forensics are a companion document', [
   ('The previous deposit ships one R carrier', 'Deposit versions before 1.9.0 ship one R carrier', 'PREVIOUS'),
   ('reproduced the previous projection engine end to end', 'reproduced the original projection engine end to end', 'PREVIOUS'),
   ('This revision was rebuilt on repaired inputs', 'The analysis of this study was rebuilt on recomputed inputs', 'THIS_REVISION+REPAIR'),
   ('its predecessor on the unrepaired inputs', 'its predecessor on the original inputs', 'REPAIR'),
   ('and the published increment vectors to', 'and the original increment vectors to', 'PUBLISHED'),
   ('the refitted published survival equation is unstable', 'the refitted original survival equation is unstable', 'PUBLISHED'),
   ('Table 3, the repaired calibration, the weighted', 'Table 3, the calibration on the recomputed frame, the weighted', 'REPAIR'),
 ]),
 ('Table S2. Summary statistics of the koa data by source', [
   ('after the repair of Section S1.3', 'after the recomputation of Section S1.3', 'REPAIR'),
 ]),
 ('Table S8. Fit statistics of the height equation', [
   ('on the repaired covariates and', 'on the recomputed covariates and', 'REPAIR'),
   ('single data source before the repair,', 'single data source before the recomputation,', 'REPAIR'),
 ]),
 ('Fitted in nlme with random intercepts on data source and installation within source (ΔHT also', [
   ('The ΔDBH column is the published vector', 'The ΔDBH column is the original vector', 'PUBLISHED'),
   ('to 4,033 repaired intervals', 'to 4,033 recomputed intervals', 'REPAIR'),
 ]),
 ('Table S12. Origin constants of the deployed diameter', [
   ('subsets of the repaired calibration frame', 'subsets of the recomputed calibration frame', 'REPAIR'),
   ('check of the earlier calibration is summarized', 'check of the original calibration is summarized', 'EARLIER'),
 ]),
 ('Table S13. Installation-cluster bootstrap of the deployed', [
   ('bootstrap of the published vector', 'bootstrap of the original vector', 'PUBLISHED'),
 ]),
 ('Table S14. On the original covariates, not repeated', [
   ('coefficients of the published koa survival equation', 'coefficients of the original koa survival equation', 'PUBLISHED'),
   ('After the repair the published equation refitted', 'After the recomputation the original equation refitted', 'REPAIR+PUBLISHED'),
 ]),
 ('Table S15. Respecified koa survival equations', [
   ('sample (ii) after the repair (4,223', 'sample (ii) after the recomputation (4,223', 'REPAIR'),
   ('compared with the published equation refitted and with its published coefficients.',
    'compared with the original equation refitted and with its original coefficients.', 'PUBLISHED'),
 ]),
 (('=', 'Published terms and competition'), [('Published terms and competition', 'Original terms and competition', 'PUBLISHED')]),
 (('=', 'Published terms'), [('Published terms', 'Original terms', 'PUBLISHED')]),
 (('=', 'Published equation refitted, alive response'), [('Published equation refitted', 'Original equation refitted', 'PUBLISHED')]),
 (('=', 'Published coefficients'), [('Published coefficients', 'Original coefficients', 'PUBLISHED')]),
 ('Notes. Out-of-installation AUCs pool leave-one-installation-out folds', [
   ('Refitting on the repaired sample gives', 'Refitting on the recomputed sample gives', 'REPAIR'),
 ]),
 ('Table S16. Performance of the five koa component equations', [
   ('with the value of the previous revision in parentheses.', 'with the value from deposit versions before 1.9.0 in parentheses.', 'PREVIOUS'),
   ('(ΔDBH from the published fit', '(ΔDBH from the original fit', 'PUBLISHED'),
   ('origin constants on the repaired calibration frames', 'origin constants on the recomputed calibration frames', 'REPAIR'),
   ('Survival rows score the published equation', 'Survival rows score the original equation', 'PUBLISHED'),
 ]),
 ('Koa values are conditional in-sample statistics', [
   ('apparent value of the published equation', 'apparent value of the original equation', 'PUBLISHED'),
 ]),
 ('Stage 2 stand-level survival exponent, García (2009)', [
   ('the check fit on the repaired regular intervals', 'the check fit on the recomputed regular intervals', 'REPAIR'),
 ]),
 ('Fitted line through the observed (N, H_QMD) envelope', [
   ('envelope under the earlier system (', 'envelope on the original covariates (', 'EARLIER'),
 ]),
 ('H_QMD = exp((ln QMD', [
   ('of the repaired pair table', 'of the recomputed pair table', 'REPAIR'),
 ]),
 ('Relative-diameter weight exp(', [
   ('scored under the earlier engine against', 'scored on the original covariates against', 'EARLIER'),
 ]),
 ('Table S21. On the original covariates', [
   ('After the repair the published-form pooled', 'After the recomputation the original-form pooled', 'REPAIR+PUBLISHED'),
 ]),
 (('=', 'Stage 1, published form'), [('published form', 'original form', 'PUBLISHED')]),
 (('=', 'Stage 2, published form'), [('published form', 'original form', 'PUBLISHED')]),
 ('Table S23. Mortality level candidates', [
   ('not projected on the repaired system.', 'not projected on the recomputed system.', 'REPAIR'),
 ]),
 (('=', 'Rejected (stands emptied under the earlier engine)'), [('under the earlier engine', 'on the original covariates', 'EARLIER')]),
 (('=', 'Not deployed (planted order broken under the earlier engine)'), [('under the earlier engine', 'on the original covariates', 'EARLIER')]),
 ('Notes. By origin, projected minus observed mean differences', [
   ('The earlier system on the same plots returned', 'The original calibration on the same plots returned', 'EARLIER'),
   ('the repaired system returns', 'the recomputed system returns', 'REPAIR'),
 ]),
 ('Table S27. Trajectory validation errors', [
   ('errors of the repaired koa system', 'errors of the recomputed koa system', 'REPAIR'),
 ]),
 ('Table S30. Projected koa stand development', [
   ('HT is not tabulated by the uneven-aged harness (n/a).', 'HT is not tabulated for the uneven-aged scenario (n/a).', 'HARNESS'),
   ('within 1.5 cm of a harness diameter ceiling', 'within 1.5 cm of a simulator diameter ceiling', 'HARNESS'),
 ]),
 ('Table S31. Behavior scenarios of the repaired koa system', [
   ('scenarios of the repaired koa system', 'scenarios of the recomputed koa system', 'REPAIR'),
 ]),
 ('Table S32. Net mean annual increment', [
   ('age of the repaired koa projections', 'age of the recomputed koa projections', 'REPAIR'),
 ]),
 ('Figure S1. Diagnostics for the koa height', [
   ('and published survival equations on the repaired frames.', 'and original survival equations on the recomputed frames.', 'PUBLISHED+REPAIR'),
   ('survival under the published equation in ten', 'survival under the original equation in ten', 'PUBLISHED'),
 ]),
 ('Figure S2. Diagnostics for the deployed koa diameter', [
   ('on the repaired calibration frames.', 'on the recomputed calibration frames.', 'REPAIR'),
 ]),
 ('Figure S3. Sampling recovery and inference instability', [
   ('of the refitted published koa survival', 'of the refitted original koa survival', 'PUBLISHED'),
   ('On the repaired frames the turning', 'On the recomputed frames the turning', 'REPAIR'),
 ]),
 ('Figure S4. Why the refitted published koa survival', [
   ('Why the refitted published koa', 'Why the refitted original koa', 'PUBLISHED'),
   ('mortality under the published equation and', 'mortality under the original equation and', 'PUBLISHED'),
 ]),
]

# word-level counts per category for the review (each old/new pair may carry several words)
WORD_PAT = {
 'published': r'\b[Pp]ublished\b', 'this revision': r'\b[Tt]his revision\b', 'previous revision': r'\bprevious revision\b',
 'previous deposit': r'\b[Pp]revious deposit\b', 'previous projection engine': r'\bprevious projection engine\b',
 'repaired': r'\brepaired\b', 'repair': r'\brepair\b', 'unrepaired': r'\bunrepaired\b', 'earlier system': r'\bearlier system\b',
 'earlier engine': r'\bearlier engine\b', 'earlier calibration': r'\bearlier calibration\b', 'deviation code': r'deviation A\d-D\d',
 'harness': r'\bharness\b', 'coarse productivity classes': r'coarse productivity classes',
}

# ---------------------------------------------------------------- helpers
def key(rpr):
    return E._rpr_key(rpr)

def rep(p, old, new):
    """Replace old by plain text new, keeping the run properties of the first replaced character."""
    model = E.chars(p)
    text = ''.join(c for c, _ in model)
    n = text.count(old)
    if n != 1:
        raise ValueError('expected 1 of %r, found %d in: %s' % (old, n, text[:90]))
    i = text.index(old)
    ks = {key(model[j][1]) for j in range(i, i + len(old))}
    if len(ks) != 1:
        raise ValueError('old span crosses formatting: %r' % old)
    rpr = model[i][1]
    model = model[:i] + [[c, rpr] for c in new] + model[i + len(old):]
    E.write_chars(p, model)
    return text, i

def resolve(P, anchor):
    if isinstance(anchor, tuple):
        hits = [p for p in P if p.text.strip() == anchor[1]]
    else:
        hits = [p for p in P if p.text.lstrip().startswith(anchor)]
    if len(hits) != 1:
        raise ValueError('anchor %r matched %d paragraphs' % (anchor, len(hits)))
    return hits[0]

def ctx(text, i, n, w=45):
    return '...' + text[max(0, i - w):i] + '[' + text[i:i + n] + ']' + text[i + n:i + n + w] + '...'

def build(src, out, blind, log):
    d = docx.Document(src)
    P = upars(d)
    sponsor = FS_BLIND if blind else FS_NAMED
    targets = [(resolve(P, a), a, eds) for a, eds in EDITS]   # resolve on the s104 text first
    cats = collections.Counter(); words = collections.Counter(); nedit = 0
    for p, a, eds in targets:
        for old, new, cat in eds:
            new = new.replace('@@S7@@', s7(sponsor))
            for w, pat in WORD_PAT.items():
                words[w] += len(re.findall(pat, old)) - len(re.findall(pat, new))
            text, i = rep(p, old, new)
            after = E.chars(p); atext = ''.join(c for c, _ in after)
            log.write('[%s] %s\n  OLD %s\n  NEW %s\n\n' % (cat, a if isinstance(a, str) else a[1], ctx(text, i, len(old)),
                                                         ctx(atext, i, len(new))))
            for c in cat.split('+'):
                cats[c] += 1
            nedit += 1
    # D12 / S11: restyle the four S1.3 body paragraphs as body text, copying the pPr of the S1.2 body paragraph
    body_ppr = resolve(P, 'On the 683 duplicated live tree-measurement cells')._p.pPr
    restyled = 0
    for a in ['The recomputation rules were written into the job record', 'The deposited FIA stand values were one quarter',
              'Copied remeasurements were screened on every installation', 'The recomputation moved at least one covariate']:
        p = resolve(P, a)
        assert p.style.name == 'Heading 2', (a, p.style.name)
        old = p._p.pPr
        p._p.replace(old, copy.deepcopy(body_ppr))
        for r in p._p.findall(qn('w:r')):           # body neighbours carry no explicit bold; drop any heading residue
            rp = r.find(qn('w:rPr'))
            if rp is not None:
                for t in ('w:b', 'w:bCs'):
                    el = rp.find(qn(t))
                    if el is not None:
                        rp.remove(el)
        restyled += 1
        log.write('[RESTYLE] %s: Heading 2 -> normal1 (pPr of the S1.2 body paragraph)\n' % a)
    # D10/D11: move the dataset reference (named: after Weiskittel 2016; BLIND: "Authors" first in the list)
    ds = resolve(P, '[dataset] ')
    if blind:
        first = resolve(P, 'Bermejo, I., Cañellas, I.')
        first._p.addprevious(ds._p)
        log.write('[REFORDER] BLIND: "[dataset] Authors, 2026" moved before Bermejo et al. 2004 (alphabetical, A first)\n')
    else:
        last = resolve(P, 'Weiskittel, A.R., Kuehne, C., McTague')
        last._p.addnext(ds._p)
        log.write('[REFORDER] named: "[dataset] Weiskittel, Sprecher, Gottesman, Rice, 2026" moved after Weiskittel, Kuehne et al. 2016\n')
    d.save(out)
    return nedit, cats, words, restyled

BLIND_PATTERNS = ['Weiskittel', 'Sprecher', 'Gottesman', 'Rice', 'Maine', 'Forest Solutions', 'Midgard', 'CRSF', 'orcid',
                  'zenodo.21081014', 'zenodo.22997704', 'holoros', 'MidgardNaturalResources']

def strip_blind_package(path):
    """Remove customXml parts and docProps/custom.xml, with their relationships and content-type overrides."""
    tmp = path + '.tmp'
    zin = zipfile.ZipFile(path)
    zout = zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED)
    removed = []
    for it in zin.infolist():
        n = it.filename
        if n.startswith('customXml/') or n == 'docProps/custom.xml':
            removed.append(n); continue
        data = zin.read(n)
        if n == '[Content_Types].xml':
            s = data.decode('utf-8')
            s = re.sub(r'<Override PartName="/customXml/[^"]+"[^>]*/>', '', s)
            s = re.sub(r'<Override PartName="/docProps/custom.xml"[^>]*/>', '', s)
            data = s.encode('utf-8')
        elif n == 'word/_rels/document.xml.rels':
            data = re.sub(rb'<Relationship [^>]*Target="\.\./customXml/[^"]+"[^>]*/>', b'', data)
        elif n == '_rels/.rels':
            data = re.sub(rb'<Relationship [^>]*Target="docProps/custom.xml"[^>]*/>', b'', data)
        zout.writestr(it, data)
    zout.close(); zin.close()
    shutil.move(tmp, path)
    return removed

def sweep(path):
    import base64
    hits = []
    z = zipfile.ZipFile(path)
    for n in z.namelist():
        data = z.read(n)
        blobs = [('raw', data)]
        if n.endswith('.xml') or n.endswith('.rels'):
            for m in re.finditer(rb'>([A-Za-z0-9+/=]{16,})<', data):
                try:
                    blobs.append(('b64', base64.b64decode(m.group(1))))
                except Exception:
                    pass
        for kind, b in blobs:
            for pat in BLIND_PATTERNS:
                for m in re.finditer(re.escape(pat.encode()), b, re.I if pat == 'orcid' else 0):
                    s = b[max(0, m.start() - 70):m.end() + 50].decode('utf-8', 'replace')
                    s = re.sub(r'<[^>]+>', '', s)
                    hits.append((n, kind, pat, s))
    return hits

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    with open(LOG, 'w') as log:
        res = {}
        for tag, src, out, blind in [('named', IN + 'koa_supplemental_v104.docx', OUT + 'koa_supplemental_v105.docx', False),
                                     ('BLIND', IN + 'koa_supplemental_v104_BLIND.docx', OUT + 'koa_supplemental_v105_BLIND.docx', True)]:
            log.write('=' * 20 + ' ' + tag + ' ' + '=' * 20 + '\n')
            res[tag] = build(src, out, blind, log)
        removed = strip_blind_package(OUT + 'koa_supplemental_v105_BLIND.docx')
        log.write('\n[BLIND package] removed parts: %s\n' % removed)
    for tag, (n, cats, words, rs) in res.items():
        print(tag, 'edits', n, dict(cats), 'restyled', rs)
        print('   word-level removals', {k: v for k, v in words.items() if v})
    print('BLIND removed parts', removed)
    for h in sweep(OUT + 'koa_supplemental_v105_BLIND.docx'):
        print('BLIND HIT', h)

# Post-build edit 2026-10-15 (main session): dataset reference points at deposit version 1.9.6
import docx as _d, docedit as _E
_p = '/tmp/s105/out/koa_supplemental_v105.docx'
_doc = _d.Document(_p)
_E.replace_in(_E.find_par(_doc.paragraphs, 'Version 1.9.5. Zenodo.'), 'Version 1.9.5.', 'Version 1.9.6.')
_doc.save(_p)
