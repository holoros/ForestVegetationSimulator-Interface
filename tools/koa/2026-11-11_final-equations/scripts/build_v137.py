"""build_v137.py  Builds koa manuscript v137 (blind and named), supplement v129 (blind and named), title page and cover letter v137.

Floor: Aaron's edited blind manuscript of November 18, 2026 (koa_manuscript_v136_DRAFT_BLIND.docx, paragraph merges and one deleted
sentence), the named manuscript v136, and supplement v128. Changes, all presentation:
  1. Aaron's paragraph merges and his deleted sentence are carried into the named manuscript (text identity checked against the blind file).
  2. Tables may break across pages: the keep-with-next chain that held each table on one page is removed, the caption stays with the
     header row and first data row, the header row repeats on each page, rows do not split, and the last two rows stay with the notes.
  3. Figs. 3 to 5, S2, S3 and S4 are replaced with the November 18 drawings (relative density axes stop at 1.0; no overlapping tags or
     ticks; the extrapolated years are marked by a dashed vertical line), and the captions of Figs. 3, 5, S2, S3 and S4 say so.
No number, equation, table cell or reference changes.

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
    d.save(dst)


def build_supp(src, dst):
    d = Document(src)
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
    c = Document(SRC + 'koa_cover_letter_v136_DRAFT.docx'); rep(c, 'November 15, 2026', 'November 18, 2026'); c.save(OUT + 'koa_cover_letter_v137_DRAFT.docx')
    print('\n'.join(LOG))
