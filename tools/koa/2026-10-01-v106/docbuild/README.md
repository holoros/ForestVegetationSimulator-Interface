# v106 / s104 build (October 1, 2026)

Anchored edit pass on koa_manuscript_v105_DRAFT.docx and koa_supplemental_v103.docx (python-docx 1.2, character-level run editing in docedit.py, markup **bold**, *italic*, ^sup^, ~sub~). Run in a sandbox with the v105 and s103 docx in /tmp/k6/src and the v106 Fig. 4 and Fig. 5 PNGs (Koa/figures_v106, from firebreather a3/pending/v106/figs):

    python3 build_ms_v106.py && python3 build_sup_v104.py && python3 make_blind_v106.py

Every anchor must match exactly one paragraph, so an edit cannot land by index. New numbers come from firebreather ~/jobs/koa_v103_20260930/a3/pending/v106 (compute_v106.py, compute_v106_addendum.py, cap_v106.R, fig4_v106.R, fig5_v106.R, stress/). The A3 tools folder could not be staged from this session (eight folders below the connected Documents root), so run_all.sh was not rerun.
