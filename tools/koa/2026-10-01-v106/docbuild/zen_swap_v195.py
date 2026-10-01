#!/usr/bin/env python3
"""Swap the s104 supplement into the 1.9.5 slot and add the Kahikinui identifier disclosure. Backs up every edited file."""
import json, os, shutil, hashlib, re
H = os.path.expanduser('~/jobs/koa_zenodo_180')
S, W, I = H + '/stage_v195', H + '/work_v195', H + '/incoming_v195'
TAG = '_PREV_20261001'
md5 = lambda p: hashlib.md5(open(p, 'rb').read()).hexdigest()
OLD, NEW = '9a188e2077bee4d453d19ba142260929', md5(H + '/koa_supplemental_v104.docx')
assert md5(I + '/koa_supplemental.docx') == OLD
shutil.copy2(I + '/koa_supplemental.docx', W + '/koa_supplemental_s103' + TAG + '.docx')
shutil.move(H + '/koa_supplemental_v104.docx', I + '/koa_supplemental.docx')
for f in ['check_deposit.py', 'FILE_MAP_1.9.5.tsv', 'DEPOSIT_CHANGELOG.md', 'README.md', 'zenodo_metadata.json', 'INTEGRITY_REPORT.md']:
    b, e = os.path.splitext(f)
    shutil.copy2(S + '/' + f, W + '/' + b + TAG + e)

DISC = ("Disclosure (October 1, 2026). Published versions 1.4.0, 1.9.0, 1.9.1, 1.9.2 and 1.9.3 of this record identify "
        "the 64 Kahikinui installations by strings built from their plot longitude and latitude, in the Install and ID "
        "columns of AK_TREE.csv, AK_PLT.csv and AK_PLT_GEO.csv. Those strings reveal plot locations that the deposit "
        "otherwise withholds. Version 1.9.5 replaces them with KFRP-nn pseudonyms and carries no coordinate in any field. "
        "Please work from version 1.9.5 or later and do not redistribute the Kahikinui identifiers of the earlier versions.")

def edit(f, fn):
    p = S + '/' + f
    t = open(p).read(); n = fn(t)
    assert n != t, f
    open(p, 'w').write(n)

edit('check_deposit.py', lambda t: t.replace('(the v103 supplement, md5 ' + OLD + ')', '(the s104 supplement of manuscript v106, md5 ' + NEW + ')'))
edit('FILE_MAP_1.9.5.tsv', lambda t: t.replace('koa_supplemental.docx\t~/jobs/koa_v103_20260930/a3/koa_supplemental_v103.docx\tREPLACED in 1.9.5: v103 supplement, md5 ' + OLD,
     'koa_supplemental.docx\tKoa/submission_v102/koa_supplemental_v104.docx (manuscript v106)\tREPLACED in 1.9.5: s104 supplement, md5 ' + NEW + ' (supersedes the s103 slot file md5 ' + OLD + ')'))
edit('INTEGRITY_REPORT.md', lambda t: t.replace('every XML part of the v103 supplement', 'every XML part of the supplement (s103 when this report was written; the slot now holds s104, md5 ' + NEW + ', swept again on October 1, 2026)'))
edit('README.md', lambda t: re.sub(r'\A(# [^\n]*\n)', lambda m: m.group(1) + '\n**' + DISC + '**\n', t, count=1))
edit('DEPOSIT_CHANGELOG.md', lambda t: t.replace('## 2026-09-30 (deposit 1.9.5): the v103 rebuild\n',
     '## 2026-09-30 (deposit 1.9.5): the v103 rebuild\n\n**' + DISC + '**\n\n**Supplement slot, October 1, 2026.** The slot `koa_supplemental.docx` now holds the s104 supplement that accompanies manuscript v106 (md5 ' + NEW + '), replacing s103 (md5 ' + OLD + '). s104 changes text, captions and sign conventions, adds Table S33 (increment frame reconciliation) and changes no deposited data value.\n', 1))
m = json.load(open(S + '/zenodo_metadata.json'))
md = m.get('metadata', m)
md['description'] = '<p><strong>' + DISC + '</strong></p>' + md['description']
md['notes'] = DISC + ' ' + md['notes']
json.dump(m, open(S + '/zenodo_metadata.json', 'w'), indent=2, ensure_ascii=False)
# leak sweep on edited text: no coordinate-shaped strings introduced
for f in ['README.md', 'DEPOSIT_CHANGELOG.md', 'zenodo_metadata.json']:
    t = open(S + '/' + f).read()
    assert not re.search(r'-15\d\.\d{3,}-?\d{1,2}\.\d{3,}', t), 'coordinate-shaped string in ' + f
print('swapped', OLD, '->', NEW)
