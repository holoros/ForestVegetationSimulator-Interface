#!/bin/bash
# keep the first backup of each file edited for v105c as *_PREV_20261102c (same convention as repair_v105b/backup_b.sh)
for f in "$@"; do [ -e "$f" ] || continue; [ -d "$f" ] && continue; ext="${f##*.}"; base="${f%.*}"; bk="${base}_PREV_20261102c.${ext}"; [ -e "$bk" ] || cp -p "$f" "$bk"; done
