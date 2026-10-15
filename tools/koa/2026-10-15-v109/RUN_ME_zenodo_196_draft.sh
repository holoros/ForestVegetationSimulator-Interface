#!/bin/bash
# Koa deposit 1.9.6: build stage, run gates, upload a DRAFT new version of 1.9.5. Never publishes.
# Run on firebreather from ~/jobs/koa_zenodo_180/v196/:   bash RUN_ME_zenodo_196_draft.sh          (build + gates only)
#                                                        DRAFT=1 bash RUN_ME_zenodo_196_draft.sh  (and upload the draft)
set -u
cd "$(dirname "$0")"
[ -f koa_supplemental_v105.docx ] || { echo "STOP: copy koa_supplemental_v105.docx into this folder"; exit 1; }
python3 build_v196.py || { echo "STOP: build or gates failed, see ../work_v196/gate_v196.log"; exit 1; }
[ "${DRAFT:-0}" = "1" ] || { echo "Gates pass. Rerun with DRAFT=1 to upload the draft."; exit 0; }
TOK=""
for t in "$HOME/jobs/koa_zenodo_180/.zenodo_token" "$HOME/.zenodo_token"; do [ -s "$t" ] && { TOK="$t"; break; }; done
[ -n "$TOK" ] || { echo "STOP: no Zenodo token at ~/jobs/koa_zenodo_180/.zenodo_token or ~/.zenodo_token"; exit 1; }
echo "token file: $TOK"
NV="$(find "$HOME/jobs/koa_zenodo_180" -maxdepth 3 -name new_version.py | head -1)"
[ -n "$NV" ] || { echo "STOP: new_version.py not found under ~/jobs/koa_zenodo_180"; exit 1; }
S6="$HOME/jobs/koa_zenodo_180/stage_v196"
SUMS=""; [ -f "$S6/SHA256SUMS" ] && SUMS="--sha256sums $S6/SHA256SUMS"
setsid nohup python3 "$NV" --token-file "$TOK" --parent-doi 10.5281/zenodo.21081014 --expect-latest 22997704 \
  --metadata "$S6/zenodo_metadata.json" --files-list "$S6/files_to_upload.txt" $SUMS \
  --result "$HOME/jobs/koa_zenodo_180/zenodo_dois_v196.json" > "$HOME/jobs/koa_zenodo_180/upload_v196.log" 2>&1 < /dev/null &
echo "draft upload started, pid $!; tail -f ~/jobs/koa_zenodo_180/upload_v196.log"
