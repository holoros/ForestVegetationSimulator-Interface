# koa October 15, 2026: v108 and v109 manuscript builds, s105 supplement, Zenodo 1.9.6

Build tooling for the koa Forest Ecosystems package of October 15, 2026. Nothing here ships in fvsOL.

- `build_v108.py`, `docedit.py`: v108 from v107 (funding, competing interest and FVS-HI availability paragraphs). `docedit.py` is the anchored character-level docx editor used by every build.
- `build_v109.py`, `counts.py`: v109 manuscript, title page and cover letter from v108 after red team 7 and stress test 4, including the post-build edits (Fig. 4 first citation, price per cubic meter, deposit 1.9.6 DOI).
- `build_s105.py`, `change_log.txt`: supplement s105 from s104 (revision-history wording, S1.3 record retention rules, S2.2 BYI skill wording, heading styles, reference order) with every replaced fragment logged.
- `zen196_cardinal.py`, `description_v196.html`: Zenodo 1.9.6 built as a new version of 1.9.5 (record 22997704) on Cardinal: supplement s105, koa_deposit_companion_v82.docx removed, FILE_MAP_1.9.6.tsv, README note, changelog entry with the archived 1.9.5 description. Draft only; publishing is done by hand.
- `build_v196.py`, `RUN_ME_zenodo_196_draft.sh`: the firebreather route for the same deposit, not used because firebreather was unreachable on October 15.
- `2026-10-15_koa-v109_CONTENT-DIFF_REVIEW.md`, `2026-10-15_koa-s105_CONTENT-DIFF_REVIEW.md`: content inventory diffs.

The build scripts read inputs from session paths under /tmp and are kept as a record of the edits, not as a general tool.
