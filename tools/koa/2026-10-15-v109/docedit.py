"""Character-level docx editing with a small markup.

Markup: **bold**, *italic*, ^sup^, ~sub~. Macros in braces are expanded first.
Every edit is anchored on text that must match exactly one paragraph.
"""
import copy, re
from docx.oxml.ns import qn
from lxml import etree

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
MAC = {
    '{m2ha}': 'm^2^ ha^−1^', '{m3ha}': 'm^3^ ha^−1^', '{ha}': 'ha^−1^', '{yr}': 'yr^−1^',
    '{cmyr}': 'cm yr^−1^', '{myr}': 'm yr^−1^', '{m3hayr}': 'm^3^ ha^−1^ yr^−1^',
    '{Mgha}': 'Mg ha^−1^', '{MgCha}': 'Mg C ha^−1^', '{R2}': 'R^2^', '{tph}': 'trees ha^−1^',
    '{sph}': 'stems ha^−1^', '{kgm3}': 'kg m^−3^', '{mmyr}': 'mm yr^−1^',
}

def expand(s):
    for k, v in MAC.items():
        s = s.replace(k, v)
    return s

def parse(markup):
    """Return list of (char, flags) with flags a frozenset of b,i,sup,sub."""
    s = expand(markup)
    out, st, i = [], set(), 0
    while i < len(s):
        if s.startswith('**', i):
            st ^= {'b'}; i += 2; continue
        c = s[i]
        if c == '*':
            st ^= {'i'}; i += 1; continue
        if c == '^':
            st ^= {'sup'}; i += 1; continue
        if c == '~':
            st ^= {'sub'}; i += 1; continue
        out.append((c, frozenset(st))); i += 1
    if st:
        raise ValueError('unbalanced markup: ' + markup[:80])
    return out

def _rpr_key(rpr):
    return b'' if rpr is None else etree.tostring(rpr)

def _set_flag(rpr, tag, on, val=None):
    el = rpr.find(qn(tag))
    if on:
        if el is None:
            el = etree.SubElement(rpr, qn(tag))
        if val is not None:
            el.set(qn('w:val'), val)
        elif el.get(qn('w:val')) is not None:
            del el.attrib[qn('w:val')]
    elif el is not None:
        rpr.remove(el)

def _fmt(base, flags):
    r = copy.deepcopy(base) if base is not None else etree.Element(qn('w:rPr'))
    _set_flag(r, 'w:b', 'b' in flags)
    _set_flag(r, 'w:bCs', 'b' in flags)
    _set_flag(r, 'w:i', 'i' in flags)
    _set_flag(r, 'w:iCs', 'i' in flags)
    va = r.find(qn('w:vertAlign'))
    if va is not None:
        r.remove(va)
    if 'sup' in flags or 'sub' in flags:
        _set_flag(r, 'w:vertAlign', True, 'superscript' if 'sup' in flags else 'subscript')
    # schema order: keep vertAlign near the end is tolerated by Word; reorder minimal
    return r

def chars(p):
    """Character model of a plain-run paragraph: list of [char, rPr]."""
    out = []
    for child in p._p:
        tag = etree.QName(child).localname
        if tag in ('pPr', 'bookmarkStart', 'bookmarkEnd', 'proofErr', 'commentRangeStart', 'commentRangeEnd'):
            continue
        if tag != 'r':
            raise ValueError('non-run child %s in paragraph: %s' % (tag, p.text[:60]))
        rpr = child.find(qn('w:rPr'))
        for sub in child:
            st = etree.QName(sub).localname
            if st == 'rPr':
                continue
            if st == 't':
                for c in (sub.text or ''):
                    out.append([c, rpr])
            elif st == 'tab':
                out.append(['\t', rpr])
            elif st == 'br':
                out.append(['\n', rpr])
            elif st in ('lastRenderedPageBreak',):
                continue
            else:
                raise ValueError('run child %s in: %s' % (st, p.text[:60]))
    return out

def write_chars(p, model):
    for child in list(p._p):
        if etree.QName(child).localname in ('r', 'proofErr'):
            p._p.remove(child)
    groups = []
    for c, rpr in model:
        k = _rpr_key(rpr)
        if groups and groups[-1][0] == k:
            groups[-1][2].append(c)
        else:
            groups.append([k, rpr, [c]])
    for _, rpr, cs in groups:
        r = etree.SubElement(p._p, qn('w:r'))
        if rpr is not None:
            r.append(copy.deepcopy(rpr))
        buf = []
        def flush():
            if buf:
                t = etree.SubElement(r, qn('w:t'))
                t.text = ''.join(buf)
                t.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
                buf.clear()
        for c in cs:
            if c == '\t':
                flush(); etree.SubElement(r, qn('w:tab'))
            elif c == '\n':
                flush(); etree.SubElement(r, qn('w:br'))
            else:
                buf.append(c)
        flush()

def _base(rpr):
    b = copy.deepcopy(rpr) if rpr is not None else etree.Element(qn('w:rPr'))
    for tag in ('w:b', 'w:bCs', 'w:i', 'w:iCs', 'w:vertAlign'):
        el = b.find(qn(tag))
        if el is not None:
            b.remove(el)
    return b

def set_par(p, markup, base_from=None):
    model = chars(p)
    # base formatting: first non-bold char (body text) of the paragraph
    rpr = None
    for c, r in model:
        if r is None or r.find(qn('w:b')) is None:
            rpr = r; break
    if rpr is None and model:
        rpr = model[0][1]
    base = _base(rpr)
    new = [[c, _fmt(base, f)] for c, f in parse(markup)]
    write_chars(p, new)

def replace_in(p, old, new_markup, count=1):
    model = chars(p)
    text = ''.join(c for c, _ in model)
    n = text.count(old)
    if n != count:
        raise ValueError('expected %d of %r, found %d in: %s' % (count, old, n, text[:90]))
    pos = 0
    for _ in range(count):
        i = text.index(old, pos)
        base = _base(model[i][1] if model else None)
        # keep italic if the replaced span started italic and markup has no italics
        new = [[c, _fmt(base, f)] for c, f in parse(new_markup)]
        model = model[:i] + new + model[i + len(old):]
        text = ''.join(c for c, _ in model)
        pos = i + len(new)
    write_chars(p, model)

def find_par(doc_pars, anchor, startswith=False):
    hits = [p for p in doc_pars if (p.text.lstrip().startswith(anchor) if startswith else anchor in p.text)]
    if len(hits) != 1:
        raise ValueError('anchor %r matched %d paragraphs' % (anchor, len(hits)))
    return hits[0]

UNIT_PAT = re.compile(r'(?<![A-Za-z])(m|cm|ha|yr|mm|kg|g|Mg)(2|3)?(?= ha|\b)')

def fix_superscripts(p):
    """Superscript plain unit exponents (m2, m3, −1 after a unit, R2). Idempotent."""
    model = chars(p)
    text = ''.join(c for c, _ in model)
    idx = set()
    for m in re.finditer(r'(?<![A-Za-z0-9])(m)([23])(?= ha| yr|\)| )', text):
        idx.add(m.start(2))
    for m in re.finditer(r'(?<=ha|yr|cm|mm)(−1)', text):
        idx.update(range(m.start(1), m.end(1)))
    for m in re.finditer(r'(?<=kg m)(−3)', text):
        idx.update(range(m.start(1), m.end(1)))
    for m in re.finditer(r'(?<![A-Za-z0-9])R(2)(?![0-9])', text):
        idx.add(m.start(1))
    changed = 0
    for i in sorted(idx):
        c, r = model[i]
        if r is not None and r.find(qn('w:vertAlign')) is not None:
            continue
        nr = copy.deepcopy(r) if r is not None else etree.Element(qn('w:rPr'))
        _set_flag(nr, 'w:vertAlign', True, 'superscript')
        model[i] = [c, nr]; changed += 1
    if changed:
        write_chars(p, model)
    return changed

def iter_all_pars(doc):
    for p in doc.paragraphs:
        yield p
    for t in doc.tables:
        for row in t.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    yield p
