#!/usr/bin/env bash
# PUSH_fvshi_api.sh -- land one HiGy.R release on holoros/ForestVegetationSimulator-Interface
# (branch ClaudeDevelopment) as a new branch plus pull request, through the GitHub Git Data API.
#
# Replaces PUSH_fvshi_041_20260925.sh, which cloned with git and pushed with the token in the URL.
# That launcher failed three ways on 25 September 2026: firebreather has no git, the cloud container's
# git proxy refuses pushes outside its allow-list, and it named the repository "holoros/ClaudeDevelopment",
# which is the branch, not the repo. Its dry run stopped before the clone, so none of that was caught
# until PUSH=1. This wrapper's dry run exercises every remote read and every gate short of the write.
#
#   bash PUSH_fvshi_api.sh              dry run: parity check, base md5, branch free, nothing written
#   PUSH=1 bash PUSH_fvshi_api.sh       commit, branch, verify off the server, open the PR
#
# Configure per release (defaults are the 0.4.1 release that landed as PR 1):
#   ARTIFACT      local HiGy.R to ship                (HiGy_041.R)
#   NEW_MD5       its md5, from the parity run        (d0780204943c6c494f93e16a9459aebd)
#   BASE_MD5      md5 of HiGy.R on ClaudeDevelopment that the change was measured against
#   BRANCH        new branch name                     (koa/higy-0.4.1-bal-of-record)
#   NUMSTAT       "ADD DEL" expected by git numstat   ("44 12")
#   MSG_FILE      commit message                      (commit_msg_041.txt)
#   PR_TITLE      pull request title; empty = no PR, print the compare URL instead
#   VERIFY_R      parity script to run first          (verify_041.R); empty = skip
#   GH_TOKEN_FILE token path; searched: $GH_TOKEN_FILE, ./token, ~/.gh-holoros/token
# The token is never printed and never written anywhere but the Authorization header.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="holoros/ForestVegetationSimulator-Interface"
BASE_BRANCH="ClaudeDevelopment"
REPO_PATH="fvsOL/inst/extdata/HiGy.R"
ARTIFACT="${ARTIFACT:-HiGy_041.R}"
NEW_MD5="${NEW_MD5:-d0780204943c6c494f93e16a9459aebd}"
BASE_MD5="${BASE_MD5:-cde569e90c359df39a498cb01941d58b}"
BRANCH="${BRANCH:-koa/higy-0.4.1-bal-of-record}"
NUMSTAT="${NUMSTAT:-44 12}"
MSG_FILE="${MSG_FILE:-commit_msg_041.txt}"
PR_TITLE="${PR_TITLE:-}"
VERIFY_R="${VERIFY_R-verify_041.R}"
PUSH="${PUSH:-0}"
TS="$(date +%Y%m%d_%H%M%S)"
LOG="$HERE/push_api_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
echo "== FVS-HI API launcher  $(date -Is)  host $(hostname)  mode $([ "$PUSH" = 1 ] && echo PUSH || echo 'dry run')"

command -v python3 >/dev/null || { echo "STOP: no python3"; exit 2; }
python3 -c "import requests" 2>/dev/null || { echo "STOP: python3 module requests missing"; exit 2; }
[ -f "$HERE/gh_api_push.py" ] || { echo "STOP: gh_api_push.py not beside this script"; exit 2; }
[ -f "$HERE/$ARTIFACT" ] || { echo "STOP: artifact $ARTIFACT missing"; exit 2; }
[ -f "$HERE/$MSG_FILE" ] || { echo "STOP: commit message file $MSG_FILE missing"; exit 2; }

# gate A: the artifact is the parity-tested one
GOT="$(md5sum "$HERE/$ARTIFACT" | cut -d' ' -f1)"
[ "$GOT" = "$NEW_MD5" ] || { echo "STOP gate A: $ARTIFACT md5 $GOT, expected $NEW_MD5"; exit 1; }
echo "gate A: $ARTIFACT md5 matches the parity-tested build"

# gate B: re-run the parity check, do not trust yesterday's result
if [ -n "$VERIFY_R" ]; then
  command -v Rscript >/dev/null || { echo "STOP: no Rscript for $VERIFY_R"; exit 3; }
  Rscript "$HERE/$VERIFY_R" || { echo "STOP gate B: parity check failed. Nothing pushed."; exit 3; }
  echo "gate B: parity check passed"
fi

# token
TOKEN_FILE=""
for c in "${GH_TOKEN_FILE:-}" "$HERE/token" "$HOME/.gh-holoros/token"; do
  [ -n "$c" ] && [ -s "$c" ] && TOKEN_FILE="$c" && break
done
[ -n "$TOKEN_FILE" ] || { echo "STOP: no GitHub token. Looked in \$GH_TOKEN_FILE, ./token, ~/.gh-holoros/token"; exit 4; }
echo "token file: $TOKEN_FILE ($(wc -c < "$TOKEN_FILE") bytes, not shown)"

# shellcheck disable=SC2206
NS=($NUMSTAT)
ARGS=(--repo "$REPO" --base "$BASE_BRANCH" --branch "$BRANCH" --path "$REPO_PATH" --file "$HERE/$ARTIFACT"
      --expect-base-md5 "$BASE_MD5" --expect-new-md5 "$NEW_MD5" --expect-numstat "${NS[0]}" "${NS[1]}"
      --message-file "$HERE/$MSG_FILE" --token-file "$TOKEN_FILE" --result "$HERE/push_api_${TS}.json" --log "$LOG.api")
[ -n "$PR_TITLE" ] && ARGS+=(--pr-title "$PR_TITLE")
[ "$PUSH" = 1 ] || ARGS+=(--dry-run)
python3 "$HERE/gh_api_push.py" "${ARGS[@]}"
rc=$?
[ $rc -eq 0 ] || { echo "STOP: gh_api_push.py exited $rc. See $LOG"; exit $rc; }
[ "$PUSH" = 1 ] && echo "Result: $HERE/push_api_${TS}.json" || echo "Dry run complete. Re-run with PUSH=1 to commit, push and open the PR."
