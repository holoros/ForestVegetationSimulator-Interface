"""Build the 1.12.2 text files from the published 1.12.1 copies. Run in ~/jobs/koa_zen1122_20261107 with s123 PDF at ./koa_supplemental_v123_FINAL.pdf."""
import os, shutil, hashlib
SRC = os.path.expanduser('~/jobs/koa_sqlite_zenodo_20261106/zen1121/files/'); F = 'files/'; os.makedirs(F, exist_ok=True)
for n in ['README.md', 'CITATION.cff', 'DEPOSIT_CHANGELOG.md', 'SHA256SUMS']: shutil.copy(SRC + n, F + n)
shutil.copy(SRC + 'FILE_MAP_1.12.1.tsv', F + 'FILE_MAP_1.12.2.tsv')
shutil.copy('koa_supplemental_v123_FINAL.pdf', F + 'koa_supplemental.pdf')
M120 = '96d1440059a92488d8479f7c77a28a16'; M = hashlib.md5(open(F + 'koa_supplemental.pdf', 'rb').read()).hexdigest()
assert M == '0262e9b58360d31e6cf7dab6777f8a3a', M
NEWDOI = '10.5281/zenodo.24039072'
def sub(path, pairs):
    t = open(F + path, encoding='utf-8').read()
    for o, n in pairs:
        assert t.count(o) == 1, (path, o[:70]); t = t.replace(o, n)
    open(F + path, 'w', encoding='utf-8').write(t)
SEC = ('## VERSION 1.12.2 (November 7, 2026): supplement of the submitted manuscript\n\n'
       'This version replaces `koa_supplemental.pdf` with supplement v123 of the manuscript as submitted to Forest Ecosystems (manuscript v132), '
       'md5 ' + M + ', replacing supplement v120 (md5 ' + M120 + '). The supplement changes are reporting corrections only: the simulator stand density index in Section S5 now uses the 25 cm index diameter of the deposited engine (`koa_params.py`, INDEX_DIAMETER_CM = 25.0), '
       'the Elevitch and Wilkinson (2000) reference lists the authors as editors, the recommended use in Table S35 is limited to comparing mean development across BYI levels, Section S3.2 reports the calibrated diameter ratio for the 88 calibration intervals longer than 20 years (1.29), and the data reference cites this version. '
       'The engine, parameters, frames, figures and numbers are those of 1.12.0 and 1.12.1. Version DOI ' + NEWDOI + '.\n\n')
sub('README.md', [
 ('**Version 1.12.1 (2026-11-06) adds the frames as one SQLite file; see the 1.12.1 section below. Everything else is 1.12.0.**',
  '**Version 1.12.2 (2026-11-07) replaces the supplement PDF with the one submitted with the manuscript; see the 1.12.2 section below. Version 1.12.1 (2026-11-06) adds the frames as one SQLite file. Everything else is 1.12.0.**'),
 ('## VERSION 1.12.1 (November 6, 2026): the frames as one SQLite file', SEC + '## VERSION 1.12.1 (November 6, 2026): the frames as one SQLite file'),
])
sub('CITATION.cff', [
 ('version: "1.12.1"\ndate-released: "2026-11-06"', 'version: "1.12.2"\ndate-released: "2026-11-07"'),
 ('identifiers:\n  - type: doi\n    value: "10.5281/zenodo.24013562"\n    description: "Version DOI of deposit 1.12.1 (reserved by draft 24013562; the version cited by the submitted manuscript)"',
  'identifiers:\n  - type: doi\n    value: "' + NEWDOI + '"\n    description: "Version DOI of deposit 1.12.2 (the version cited by the submitted manuscript; supplement v123)"\n  - type: doi\n    value: "10.5281/zenodo.24013562"\n    description: "Version DOI of deposit 1.12.1 (published 2026-11-07; supplement v120)"'),
 ('# 1.9.4 was staged', '# Version 1.12.2 (2026-11-07) replaces koa_supplemental.pdf with supplement v123, the supplement submitted with manuscript v132;\n# its version DOI ' + NEWDOI + ' is reserved by draft 24039072.\n# 1.9.4 was staged'),
])
m = open(F + 'FILE_MAP_1.12.2.tsv', encoding='utf-8').read().split('\n')
i = [k for k, l in enumerate(m) if l.startswith('koa_supplemental.pdf\t')]; assert len(i) == 1
m[i[0]] = ('koa_supplemental.pdf\tsubmission/koa_supplemental_v123_FINAL.pdf (supplement v123, md5 ' + M + ') (1.12.2, 2026-11-07)\t'
           'Manuscript supplement v123, final, matching manuscript v132 as submitted (replaces v120, md5 ' + M120 + '; reporting corrections only)')
open(F + 'FILE_MAP_1.12.2.tsv', 'w', encoding='utf-8').write('\n'.join(m))
sub('DEPOSIT_CHANGELOG.md', [('# Deposit changelog\n\n', '# Deposit changelog\n\n## 2026-11-07 (deposit 1.12.2): new version of the published 1.12.1 (record 24013562)\n\n'
  'Created with the Zenodo new-version action from 1.12.1 (draft 24039072, version DOI ' + NEWDOI + '). Replaced: `koa_supplemental.pdf` with supplement v123 (md5 ' + M + '), the supplement of manuscript v132 as submitted to Forest Ecosystems; '
  '`README.md` (1.12.2 section), `CITATION.cff` (version and DOI), `DEPOSIT_CHANGELOG.md`, `SHA256SUMS`. Renamed: `FILE_MAP_1.12.1.tsv` to `FILE_MAP_1.12.2.tsv` (supplement row updated). Engine, parameters, frames and outputs unchanged.\n\n')])
s = open(F + 'SHA256SUMS').read().split('\n'); out = []
for l in s:
    p = l.split('  ', 1)
    if len(p) == 2 and p[1] == 'FILE_MAP_1.12.1.tsv': p[1] = 'FILE_MAP_1.12.2.tsv'
    if len(p) == 2 and p[1] in ('README.md', 'CITATION.cff', 'FILE_MAP_1.12.2.tsv', 'koa_supplemental.pdf', 'DEPOSIT_CHANGELOG.md'):
        l = hashlib.sha256(open(F + p[1], 'rb').read()).hexdigest() + '  ' + p[1]
    out.append(l)
assert any(l.endswith('  FILE_MAP_1.12.2.tsv') for l in out)
open(F + 'SHA256SUMS', 'w').write('\n'.join(out)); print('texts ok', M)
