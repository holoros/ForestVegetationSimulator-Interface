#!/bin/bash
# keep the first backup of each file edited for v105d as *_PREV_20261102d (same convention as v105c/backup_c.sh)
for f in "$@"; do [ -e "$f" ] || continue; [ -d "$f" ] && continue; ext="${f##*.}"; base="${f%.*}"; bk="${base}_PREV_20261102d.${ext}"; [ -e "$bk" ] || cp -p "$f" "$bk"; done
