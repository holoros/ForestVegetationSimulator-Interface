"""Character-level docx editing with a small markup.

Markup: **bold**, *italic*, ^sup^, ~sub~. Macros in braces are expanded first.
A backslash escapes a literal markup character: \\* \\^ \\~ \\\\ (for formulas such as SDI = N(Dq/25.4)\\^1.605).
Every edit is anchored on text that must match exactly one paragraph.

Opaque content (drawings, fields, hyperlinks, content controls, math) is kept as one placeholder
character (U+FFFC) per element, so text around it can be edited and the element is written back intact.

Condensation-build helpers (October 31, 2026): replace_in(keep_format=True) keeps the replaced span's own
formatting when the new text has no markup, and warns when italic or superscript text would be lost;
delete_par, insert_after, move_after, move_table_with_caption, and renumber_labels.
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
        if s[i] == '\\' and i + 1 < len(s):
            out.append((s[i + 1], frozenset(st))); i += 2; continue
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

OBJ = '\ufffc'
_SKIP = ('pPr', 'bookmarkStart', 'bookmarkEnd', 'proofErr', 'commentRangeStart', 'commentRangeEnd')


def chars(p):
    """Character model of a paragraph: list of [char, rPr]; opaque elements become [OBJ, element]."""
    out = []
    for child in p._p:
        tag = etree.QName(child).localname
        if tag in _SKIP:
            continue
        if tag != 'r':
            out.append([OBJ, ('elem', child)])  # hyperlink, sdt, oMath, fldSimple, ins/del: kept whole
            continue
        if any(etree.QName(sub).localname in ('drawing', 'pict', 'object', 'fldChar', 'instrText') for sub in child):
            out.append([OBJ, ('elem', child)])  # figure or field run: kept whole
            continue
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
        if etree.QName(child).localname not in _SKIP or etree.QName(child).localname == 'proofErr':
            p._p.remove(child)
    groups = []
    for c, rpr in model:
        if c == OBJ and isinstance(rpr, tuple):
            groups.append(['__obj__', rpr[1], None])
            continue
        k = _rpr_key(rpr)
        if groups and groups[-1][0] == k:
            groups[-1][2].append(c)
        else:
            groups.append([k, rpr, [c]])
    for k, rpr, cs in groups:
        if k == '__obj__':
            p._p.append(rpr)  # the original element, moved back in order
            continue
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
    if isinstance(rpr, tuple):
        rpr = None
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
        if isinstance(r, tuple):
            continue
        if r is None or r.find(qn('w:b')) is None:
            rpr = r; break
    if rpr is None and model:
        rpr = model[0][1]
    base = _base(rpr)
    new = [[c, _fmt(base, f)] for c, f in parse(markup)]
    write_chars(p, new)

def _flags_of(rpr):
    if rpr is None or isinstance(rpr, tuple):
        return set()
    f = set()
    if rpr.find(qn('w:i')) is not None:
        f.add('i')
    va = rpr.find(qn('w:vertAlign'))
    if va is not None:
        f.add('sup' if va.get(qn('w:val')) == 'superscript' else 'sub')
    return f


def replace_in(p, old, new_markup, count=1, keep_format=False):
    """Replace `old` with `new_markup`. With keep_format=True and plain new text, each new character takes
    the formatting of the replaced span's first character. Warns when italic or super/subscript text in the
    replaced span would be lost, since species names and unit exponents are the usual casualties."""
    model = chars(p)
    text = ''.join(c for c, _ in model)
    n = text.count(old)
    if n != count:
        raise ValueError('expected %d of %r, found %d in: %s' % (count, old, n, text[:90]))
    pos = 0
    plain = not re.search(r'(?<!\\)[*^~]', expand(new_markup))
    for _ in range(count):
        i = text.index(old, pos)
        span = model[i:i + len(old)]
        lost = set().union(*[_flags_of(r) for _, r in span]) if span else set()
        ow, nw = set(re.findall(r"\w+", old)), set(re.findall(r"\w+", expand(new_markup)))
        rewrite = len(ow) > 0 and len(ow & nw) / len(ow) >= 0.5  # a rewrite of the span, not a deletion or a move
        if lost and plain and not keep_format and rewrite:
            print('docedit WARNING: replacing formatted text (%s) with plain text: %r' % (','.join(sorted(lost)), old[:60]))
        if keep_format and plain and span and not isinstance(span[0][1], tuple):
            new = [[c, copy.deepcopy(span[0][1])] for c, f in parse(new_markup)]
        else:
            base = _base(model[i][1] if model else None)
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


def delete_par(p):
    """Remove a whole paragraph (python-docx Paragraph)."""
    p._p.getparent().remove(p._p)


def insert_after(anchor_par, markup, style_from=None):
    """Insert a new paragraph after anchor_par, copying paragraph properties from style_from (default anchor)."""
    src = style_from if style_from is not None else anchor_par
    new_p = copy.deepcopy(src._p)
    for child in list(new_p):
        if etree.QName(child).localname != 'pPr':
            new_p.remove(child)
    anchor_par._p.addnext(new_p)
    from docx.text.paragraph import Paragraph
    para = Paragraph(new_p, anchor_par._parent)
    set_par(para, markup) if markup else None
    return para


def move_after(element, anchor_element):
    """Move any body element (paragraph or table; pass p._p or table._tbl) to just after anchor_element."""
    anchor_element.addnext(element)


def move_table_with_caption(caption_par, after_element, caption_above=True):
    """Move a table with its caption (caption above the table by house style; notes paragraph below, if any,
    starting with 'Note') to just after after_element. Returns the moved elements in order."""
    cap = caption_par._p
    tbl = cap.getnext() if caption_above else cap.getprevious()
    if tbl is None or etree.QName(tbl).localname != 'tbl':
        raise ValueError('no table adjacent to caption: ' + caption_par.text[:60])
    seq = [cap, tbl] if caption_above else [tbl, cap]
    nxt = seq[-1].getnext()
    if nxt is not None and etree.QName(nxt).localname == 'p':
        t = ''.join(x.text or '' for x in nxt.iter(qn('w:t'))).strip()
        if re.match(r'^(Notes?|Abbreviations?)\b', t):
            seq.append(nxt)
    anchor = after_element
    for el in seq:
        anchor.addnext(el)
        anchor = el
    return seq


def renumber_labels(pars, mapping, kinds=('Table', 'Figure', 'Fig.', 'Section', 'Note', 'Eq.')):
    """Renumber labels in one pass through placeholders, so chains (S5->S4, S4->S5) cannot collide.
    mapping keys and values are label suffixes, e.g. {'S5': 'S4', 'S4': 'S5'} or {'3.2': '3.1'}.
    Text inside opaque elements is not touched. Returns the number of replacements."""
    n = 0
    pat = re.compile(r'\b(%s)(\s*)(%s)(?![0-9]|\.[0-9])' % ('|'.join(re.escape(k) for k in kinds),
                                                     '|'.join(re.escape(k) for k in sorted(mapping, key=len, reverse=True))))
    for p in pars:
        try:
            model = chars(p)
        except ValueError:
            continue
        text = ''.join(c for c, _ in model)
        hits = list(pat.finditer(text))
        if not hits:
            continue
        for m in reversed(hits):
            i, j = m.start(3), m.end(3)
            fmt = model[i][1]
            new = [[c, copy.deepcopy(fmt) if not isinstance(fmt, tuple) else None] for c in mapping[m.group(3)]]
            model = model[:i] + new + model[j:]
            n += 1
        write_chars(p, model)
    return n
