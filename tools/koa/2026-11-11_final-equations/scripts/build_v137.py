"""build_v137.py  Builds koa manuscript v137 (blind and named), supplement v129 (blind and named), title page and cover letter v137.

Floor: Aaron's edited blind manuscript of November 18, 2026 (koa_manuscript_v136_DRAFT_BLIND.docx, paragraph merges and one deleted
sentence), the named manuscript v136, and supplement v128. Changes, all presentation:
  1. Aaron's paragraph merges and his deleted sentence are carried into the named manuscript (text identity checked against the blind file).
  2. Tables may break across pages: the keep-with-next chain that held each table on one page is removed, the caption stays with the
     header row and first data row, the header row repeats on each page, rows do not split, and the last two rows stay with the notes.
  3. Figs. 3 to 5, S2, S3 and S4 are replaced with the November 18 drawings (relative density axes stop at 1.0; no overlapping tags or
     ticks; the extrapolated years are marked by a dashed vertical line), and the captions of Figs. 3, 5, S2, S3 and S4 say so.
  4. On Aaron's decision of November 18, the relative density rule (script 58) is reported as a sensitivity: one sentence in Results 3.5,
     one paragraph at the end of supplement Section S6, and Table S39. It is not part of the system.
No other number, equation, table cell or reference changes.

Usage: python3 build_v137.py
"""
import sys, zipfile, shutil, io, re, copy
sys.path.insert(0, '/tmp/koa2/build')
from docx import Document
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import docedit as de

SRC = '/tmp/koa2/src/'; OUT = '/tmp/koa2/out/'; FIG = '/mnt/user-data/uploads/Koa/tools/2026-11-18_v137-build/'; FIGS = '/tmp/koa2/figs/'
LOG = []


def body_pars(doc):
    return [p for p in doc.paragraphs if p.text.strip()]


def merge_into(a, b):
    """Append paragraph b's content to paragraph a after one space, then remove b."""
    r = OxmlElement('w:r'); t = OxmlElement('w:t'); t.text = ' '; t.set(qn('xml:space'), 'preserve')
    first = a._p.findall(qn('w:r'))
    if first and first[-1].find(qn('w:rPr')) is not None:
        r.append(copy.deepcopy(first[-1].find(qn('w:rPr'))))
        for tag in ('w:vertAlign', 'w:i', 'w:b'):
            for e in r.find(qn('w:rPr')).findall(qn(tag)):
                r.find(qn('w:rPr')).remove(e)
    r.append(t); a._p.append(r)
    for ch in list(b._p):
        if ch.tag != qn('w:pPr'):
            a._p.append(ch)
    b._p.getparent().remove(b._p)


def apply_aaron_merges(named, blind):
    """Bring the named manuscript's body paragraphs into Aaron's paragraphing."""
    def region(doc):
        ps = body_pars(doc)
        i = [k for k, p in enumerate(ps) if p.text.strip() == '1 Introduction'][0]
        j = [k for k, p in enumerate(ps) if p.text.strip().startswith('Acknowledg')][0]
        return ps[i:j]
    N = lambda x: ' '.join(x.split())
    A = region(named); B = [N(p.text) for p in region(blind)]
    i = 0; n_merge = 0; n_del = 0
    for target in B:
        cur = A[i]
        if N(cur.text) == 'Results follow the order of the methods.' and target != N(cur.text):
            cur._p.getparent().remove(cur._p); n_del += 1; i += 1; cur = A[i]
        while N(cur.text) != target:
            nxt = A[i + 1]
            assert target.startswith(N(cur.text)), ('no match', N(cur.text)[-80:], target[len(N(cur.text))-80:len(N(cur.text))+20])
            merge_into(cur, nxt); A.pop(i + 1); n_merge += 1
        i += 1
    assert i == len(A), (i, len(A))
    LOG.append('named: %d paragraph merges and %d deleted sentence carried from Aaron\'s blind file' % (n_merge, n_del))
    assert [N(p.text) for p in region(named)] == B


def _set_flag(pPr, tag, on):
    for e in pPr.findall(qn(tag)):
        pPr.remove(e)
    if on:
        e = OxmlElement(tag)
        # keepNext and keepLines sit near the top of pPr; insert after pStyle if present
        ps = pPr.find(qn('w:pStyle'))
        if ps is not None:
            ps.addnext(e)
        else:
            pPr.insert(0, e)


def fmt_tables(doc):
    body = doc.element.body; els = list(body); nt = 0
    for i, el in enumerate(els):
        if el.tag != qn('w:tbl'):
            continue
        nt += 1
        rows = el.findall(qn('w:tr')); n = len(rows)
        for k, tr in enumerate(rows):
            trPr = tr.find(qn('w:trPr'))
            if trPr is None:
                trPr = OxmlElement('w:trPr'); tr.insert(0 if tr.find(qn('w:tblPrEx')) is None else 1, trPr)
            if trPr.find(qn('w:cantSplit')) is None:
                trPr.append(OxmlElement('w:cantSplit'))
            if k == 0 and trPr.find(qn('w:tblHeader')) is None:
                trPr.append(OxmlElement('w:tblHeader'))
            keep = (k <= 1) or (k >= n - 2)          # caption + header + first row together; last two rows with the notes
            for p in tr.iter(qn('w:p')):
                pPr = p.find(qn('w:pPr'))
                if pPr is None:
                    pPr = OxmlElement('w:pPr'); p.insert(0, pPr)
                _set_flag(pPr, 'w:keepNext', keep)
        # caption: the paragraph before the table keeps with it; notes: lines kept together
        prev = els[i - 1]
        if prev.tag == qn('w:p'):
            pPr = prev.find(qn('w:pPr'))
            if pPr is None:
                pPr = OxmlElement('w:pPr'); prev.insert(0, pPr)
            _set_flag(pPr, 'w:keepNext', True)
        nxt = els[i + 1] if i + 1 < len(els) else None
        if nxt is not None and nxt.tag == qn('w:p') and ''.join(t.text or '' for t in nxt.iter(qn('w:t'))).startswith('Notes'):
            pPr = nxt.find(qn('w:pPr'))
            if pPr is None:
                pPr = OxmlElement('w:pPr'); nxt.insert(0, pPr)
            _set_flag(pPr, 'w:keepLines', True); _set_flag(pPr, 'w:keepNext', False)
    LOG.append('tables reformatted to break across pages: %d' % nt)


def rep(doc, old, new):
    pars = [p for p in de.iter_all_pars(doc) if old in p.text]
    assert len(pars) == 1, (old[:60], len(pars))
    de.replace_in(pars[0], old, new, count=1)


def set_image(doc, partname, png, width_mm=None, new_page=False):
    """Replace an embedded image's bytes, set the drawing to the image's own aspect ratio (optionally at a stated width),
    keep the image paragraph with its caption, and optionally start it on a new page."""
    from PIL import Image
    w, h = Image.open(png).size; done = 0
    for s in doc.inline_shapes:
        rid = s._inline.graphic.graphicData.pic.blipFill.blip.embed
        part = doc.part.related_parts[rid]
        if str(part.partname) == partname:
            part._blob = open(png, 'rb').read()
            if width_mm: s.width = int(width_mm * 36000)
            s.height = int(s.width * h / w); done += 1
            p = s._inline.getparent()
            while p.tag != qn('w:p'): p = p.getparent()
            pPr = p.find(qn('w:pPr'))
            if pPr is None:
                pPr = OxmlElement('w:pPr'); p.insert(0, pPr)
            _set_flag(pPr, 'w:keepNext', True)
            if new_page: _set_flag(pPr, 'w:pageBreakBefore', True)
    assert done == 1, (partname, done)



# ---------------------------------------------------------------- relative density rule, added on Aaron's decision of November 18 (supplement sensitivity)
CAP_ROWS = [  # from out/rd_cap_table_58.csv (script 58, firebreather): planted scenarios, point (5th-95th percentile of 500 paired draws)
    ('121', '20',  '27.4 (14.2–41.3)', '27.4 (14.2–36.1)', '403 (292–447)', '403 (251–443)', '0.88 (0.49–1.24)', '0.88 (0.49–1.00)'),
    ('121', '40',  '36.5 (20.8–51.6)', '35.7 (20.8–41.3)', '271 (152–345)', '265 (139–339)', '1.02 (0.62–1.30)', '1.00 (0.62–1.00)'),
    ('121', '100', '38.1 (18.2–61.5)', '37.8 (18.6–46.8)', '105 (43–179)',  '105 (43–165)',  '0.88 (0.42–1.34)', '0.87 (0.43–1.00)'),
    ('156', '20',  '31.5 (18.0–45.2)', '31.5 (18.0–38.6)', '404 (320–446)', '404 (278–444)', '0.92 (0.59–1.22)', '0.92 (0.59–1.00)'),
    ('156', '40',  '41.1 (25.3–54.3)', '39.2 (25.3–43.6)', '267 (170–341)', '255 (154–332)', '1.05 (0.69–1.32)', '1.00 (0.69–1.00)'),
    ('156', '100', '41.4 (18.7–63.2)', '40.8 (18.7–49.6)', '101 (41–174)',  '101 (41–159)',  '0.87 (0.41–1.31)', '0.86 (0.40–1.00)'),
    ('309', '20',  '45.3 (26.3–62.1)', '44.3 (26.3–50.5)', '400 (308–451)', '392 (253–450)', '1.02 (0.68–1.29)', '1.00 (0.68–1.00)'),
    ('309', '40',  '54.8 (36.2–70.6)', '50.5 (36.2–56.1)', '247 (151–337)', '229 (137–327)', '1.08 (0.80–1.30)', '1.00 (0.80–1.00)'),
    ('309', '100', '49.7 (22.8–81.8)', '48.7 (22.8–62.9)', '87 (37–172)',   '88 (39–152)',   '0.82 (0.38–1.34)', '0.80 (0.38–1.00)'),
]
CAP_HEAD = ['BYI (Mg ha^{−1})', 'Year', 'Basal area, published (m^{2} ha^{−1})', 'Basal area, RD held (m^{2} ha^{−1})', 'Stems, published (ha^{−1})', 'Stems, RD held (ha^{−1})', 'RD, published', 'RD, RD held']
CAP_CAPTION = ('**Table S39.** Planted scenarios with the published system and with relative density (RD) held at or below one by a set rule, as point '
               'projections with the 5th to 95th percentile of 500 paired Monte Carlo draws in parentheses. Natural scenarios are identical under the rule at every year and are not shown. '
               'The rule is a sensitivity and is not part of the system (Section S6).')
CAP_NOTES = ('Notes: BYI is the Biomass Yield Index and RD the relative density, SDI/SDI_{max}. Under the rule a stand above its SDI_{max} at the end of an annual step has every expansion factor '
             'multiplied by SDI_{max}/SDI. The two arms share seeds and random numbers, and the draws are not those of Table S24, so the bands of the published arm differ from Table S24 in the last digits. '
             'QMD changed by 1.4% or less in every cell.')
CAP_PAR = ('Relative density held at or below one. Projected planted stands pass a relative density of one (Table S24; Fig. S2). As a sensitivity, the scenarios, the benchmark, and the gates were rerun with a rule '
           'written before the run: at the end of each annual step a stand above its SDI_{max} has every expansion factor multiplied by SDI_{max}/SDI, which returns it to a relative density of one with no size '
           'preference in the stems removed (script 58). Natural scenarios were identical. In the planted point projections the rule acted in years 33 to 47, 27 to 47, and 19 to 42 at low, median, and high BYI, '
           'basal area at 40 years was 2.2, 4.5, and 7.7% lower, and the upper limit of its 90% band fell by 10 to 15 m^{2} ha^{−1} (Table S39). On the benchmark the rule acted on 1 of the 53 plots, and RMSE was 0.125 '
           'for survival, 2.78 cm for QMD, and 6.80 m^{2} ha^{−1} for basal area, against 0.124, 2.78 cm, and 6.76 m^{2} ha^{−1}, with every equivalence test unchanged. The yield-density gate failed under the rule, '
           'so four of the six gates passed where the published system passes five. The rule is not part of the system.')


def _runs(p_el, text, base_rpr):
    """Rebuild a paragraph's runs from text with **bold**, ^{superscript} and _{subscript} markers."""
    for r in p_el.findall(qn('w:r')):
        p_el.remove(r)
    for m in re.finditer(r'\*\*(.+?)\*\*|\^\{(.+?)\}|_\{(.+?)\}|([^*^_]+|[*^_])', text):
        b, sup, sub, plain = m.groups(); t = b or sup or sub or plain
        r = OxmlElement('w:r'); rpr = copy.deepcopy(base_rpr) if base_rpr is not None else OxmlElement('w:rPr')
        for tag in ('w:b', 'w:bCs', 'w:vertAlign', 'w:i', 'w:iCs'):
            for e in rpr.findall(qn(tag)): rpr.remove(e)
        if b: rpr.append(OxmlElement('w:b')); rpr.append(OxmlElement('w:bCs'))
        if sup or sub:
            v = OxmlElement('w:vertAlign'); v.set(qn('w:val'), 'superscript' if sup else 'subscript'); rpr.append(v)
        r.append(rpr); te = OxmlElement('w:t'); te.text = t; te.set(qn('xml:space'), 'preserve'); r.append(te); p_el.append(r)


def _plain_rpr(p_el):
    for r in p_el.findall(qn('w:r')):
        rp = r.find(qn('w:rPr'))
        if rp is not None and rp.find(qn('w:b')) is None and rp.find(qn('w:vertAlign')) is None:
            return rp
    r = p_el.find(qn('w:r')); return r.find(qn('w:rPr')) if r is not None else None


def add_cap_sensitivity(d):
    ps = d.paragraphs
    # 1. paragraph at the end of Section S6
    h7 = [p for p in ps if p.text.strip().startswith('S7. Reproducibility')]; assert len(h7) == 1
    prev = h7[0]._p.getprevious(); assert prev.tag == qn('w:p')
    newp = copy.deepcopy(prev); _runs(newp, CAP_PAR, _plain_rpr(prev)); prev.addnext(newp)
    # 2. Table S39 after the notes of Table S38
    cap38 = [p for p in ps if p.text.startswith('Table S38.')]; assert len(cap38) == 1
    tbl38 = cap38[0]._p.getnext(); assert tbl38.tag == qn('w:tbl'); notes38 = tbl38.getnext(); assert notes38.tag == qn('w:p')
    cap = copy.deepcopy(cap38[0]._p); _runs(cap, CAP_CAPTION, _plain_rpr(cap38[0]._p))
    tbl = copy.deepcopy(tbl38); rows = tbl.findall(qn('w:tr'))
    for tr in rows[len(CAP_ROWS) + 1:]: tbl.remove(tr)
    rows = tbl.findall(qn('w:tr')); assert len(rows) == len(CAP_ROWS) + 1
    for tr, vals in zip(rows, [CAP_HEAD] + CAP_ROWS):
        tcs = tr.findall(qn('w:tc')); assert len(tcs) == 8, len(tcs)
        for tc, v in zip(tcs, vals):
            for e in tc.findall(qn('w:tcPr')):
                for vm in e.findall(qn('w:vMerge')): e.remove(vm)
            pp = tc.findall(qn('w:p'))
            for extra in pp[1:]: tc.remove(extra)
            r0 = pp[0].find(qn('w:r')); base = r0.find(qn('w:rPr')) if r0 is not None else None
            keep_bold = tr is rows[0]
            _runs(pp[0], ('**' + v + '**') if (keep_bold and '^{' not in v) else v, base)
            if keep_bold and '^{' in v:      # bold header with superscripts: set bold on every run
                for r in pp[0].findall(qn('w:r')):
                    r.find(qn('w:rPr')).insert(0, OxmlElement('w:b'))
    # column widths: two narrow key columns and six equal value columns across the same total width
    grid = tbl.find(qn('w:tblGrid')).findall(qn('w:gridCol')); tot = sum(int(g.get(qn('w:w'))) for g in grid)
    wk = [int(tot * 0.115), int(tot * 0.07)]; wv = (tot - sum(wk)) // 6; W = wk + [wv] * 6
    for g, w in zip(grid, W): g.set(qn('w:w'), str(w))
    for tr in rows:
        for tc, w in zip(tr.findall(qn('w:tc')), W):
            tcw = tc.find(qn('w:tcPr')).find(qn('w:tcW')); tcw.set(qn('w:w'), str(w)); tcw.set(qn('w:type'), 'dxa')
    notes = copy.deepcopy(notes38); _runs(notes, CAP_NOTES, _plain_rpr(notes38))
    notes38.addnext(cap); cap.addnext(tbl); tbl.addnext(notes)
    # 3. counts, pointers and the script inventory
    rep(d, 'Tables S1 to S38 and Figs. S1 to S4 are numbered', 'Tables S1 to S39 and Figs. S1 to S4 are numbered')
    rep(d, 'except that Tables S32 to S38 and Fig. S4, added with the crown base equation, the height increment forms, the stand-level mortality forms, the long-term assessment metrics, and ingrowth, follow the others.',
           'except that Tables S32 to S39 and Fig. S4, added with the crown base equation, the height increment forms, the stand-level mortality forms, the long-term assessment metrics, ingrowth, and the relative density rule, follow the others.')
    rep(d, 'and scripts 42 to 55 on November 15;', 'scripts 42 to 55 on November 15, and script 58 on November 18;')
    inv = [t for t in d.tables if '51_j1_items.R and log' in t._tbl.xml]; assert len(inv) == 1
    row = [r for r in inv[0].rows if r.cells[0].text.strip().startswith('54_fig3_figS4_v136.R')]; assert len(row) == 1
    c0 = row[0].cells[0].paragraphs[0]; de.replace_in(c0, '54_fig3_figS4_v136.R, 55_fig4_fig5_v136.R and logs', '57a_fig3_figS4_v137.R, 57b_fig4_fig5_v137.R and logs (scripts 54 and 55 redrawn)')
    new = copy.deepcopy(row[0]._tr); row[0]._tr.addnext(new)
    for tc, v in zip(new.findall(qn('w:tc')), ['58_rd_cap_sensitivity.R and log', 'Relative density held at or below one: scenarios, benchmark, and gates (Section S6; Table S39)', 'None']):
        pp = tc.findall(qn('w:p')); r0 = pp[0].find(qn('w:r')); _runs(pp[0], v, r0.find(qn('w:rPr')) if r0 is not None else None)
    LOG.append('supplement: relative density rule added (Section S6 paragraph, Table S39, script inventory)')

def build_ms(src, dst, blind_ref=None):
    d = Document(src)
    if blind_ref is not None:
        apply_aaron_merges(d, Document(blind_ref))
    fmt_tables(d)
    set_image(d, '/word/media/image3.png', FIG + 'Fig3_equations.png', width_mm=145, new_page=True)
    set_image(d, '/word/media/image4.png', FIG + 'Fig4_benchmark.png', new_page=True)
    set_image(d, '/word/media/image5.png', FIG + 'Fig5_projections.png', new_page=True)
    # Table 2: the 'Height (Eq. 3)' cell carried a larger font than its neighbours; give it the run format of 'Crown base (Eq. 4)'
    t2 = d.tables[1]; src_r = None; tgt = []
    for row in t2.rows:
        c = row.cells[0]
        if c.text.strip() == 'Crown base (Eq. 4)': src_r = c.paragraphs[0].runs[0]
        if c.text.strip() == 'Height (Eq. 3)': tgt = c.paragraphs[0].runs
    assert src_r is not None and tgt
    for r in tgt:
        old = r._r.find(qn('w:rPr'))
        if old is not None: r._r.remove(old)
        if src_r._r.find(qn('w:rPr')) is not None: r._r.insert(0, copy.deepcopy(src_r._r.find(qn('w:rPr'))))
    rep(d, 'with the 360 crown records, and (d) annual diameter increment against the same measure.',
           'with the 360 crown records (two above 1 not drawn), and (d) annual diameter increment against the same measure.')
    rep(d, 'The shaded years are beyond the benchmark record, after year 33 for natural stands and year 10 for planted stands,',
           'Dashed lines right of the vertical line are beyond the benchmark record, after year 33 for natural stands and year 10 for planted stands,')
    rep(d, '(Tables S1 to S38 and Figs. S1 to S4)', '(Tables S1 to S39 and Figs. S1 to S4)')
    rep(d, 'The survival bands and the bands for natural stands were too narrow.',
           'The survival bands and the bands for natural stands were too narrow. Planted stands passed a relative density of one (Table 4), and holding it at or below one by a set rule left natural stands unchanged, lowered planted basal area at 40 years by 2 to 8%, and failed the yield-density gate as well as the Sukachev gate (Table S39).')
    d.save(dst)


def build_supp(src, dst):
    d = Document(src)
    add_cap_sensitivity(d)
    fmt_tables(d)
    set_image(d, '/word/media/image12.png', FIGS + 'FigS2_rd_height_volume.png')
    set_image(d, '/word/media/image13.png', FIGS + 'FigS3_bands.png')
    set_image(d, '/word/media/image1.png', FIG + 'FigS4_more_responses.png')
    rep(d, 'Shading starts at year 33 for natural stands and year 10 for planted stands, as in Fig. 5 of the main text,',
           'The vertical dashed line marks the end of the benchmark record, year 33 for natural stands and year 10 for planted stands, as in Fig. 5 of the main text,')
    rep(d, 'Shading is as in Fig. S2.', 'The vertical dashed line is as in Fig. S2.')
    d.save(dst)


if __name__ == '__main__':
    build_ms(SRC + 'koa_manuscript_v136_DRAFT_BLIND.docx', OUT + 'koa_manuscript_v137_DRAFT_BLIND.docx')
    build_ms(SRC + 'koa_manuscript_v136_DRAFT.docx', OUT + 'koa_manuscript_v137_DRAFT.docx', blind_ref=SRC + 'koa_manuscript_v136_DRAFT_BLIND.docx')
    build_supp(SRC + 'koa_supplemental_v128_DRAFT_BLIND.docx', OUT + 'koa_supplemental_v129_DRAFT_BLIND.docx')
    build_supp(SRC + 'koa_supplemental_v128_DRAFT.docx', OUT + 'koa_supplemental_v129_DRAFT.docx')
    shutil.copy(SRC + 'koa_title_page_v136_DRAFT.docx', OUT + 'koa_title_page_v137_DRAFT.docx')
    c = Document(SRC + 'koa_cover_letter_v136_DRAFT.docx'); rep(c, 'November 15, 2026', 'November 18, 2026'); rep(c, 'a supplement of 38 tables and four figures', 'a supplement of 39 tables and four figures'); c.save(OUT + 'koa_cover_letter_v137_DRAFT.docx')
    print('\n'.join(LOG))
