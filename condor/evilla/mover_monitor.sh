#!/bin/bash
# Periodically move completed tpstreams from staging into sn-burst-samples and
# emit one status line whenever REPORT_STEP more cats become fully complete
# (110/110 tpstreams in final location). Exits when all cats in range are done.
FIRST=${FIRST:-623}
LAST=${LAST:-1223}
REPORT_STEP=${REPORT_STEP:-50}
POLL_SECONDS=${POLL_SECONDS:-1800}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST=/eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples

last_reported=0
while :; do
    python3 "$HERE/move_new_cats.py" --first $FIRST --last $LAST --cleanup > /dev/null 2>&1
    n_complete=0
    for cat in $(seq $FIRST $LAST); do
        d=$(printf "$DEST/cat%06d/tpstreams" $cat)
        [ -d "$d" ] && [ "$(ls "$d" 2>/dev/null | wc -l)" -ge 110 ] && n_complete=$((n_complete+1))
    done
    total=$((LAST - FIRST + 1))
    if [ $n_complete -ge $total ]; then
        echo "ALL_CATS_MOVED: ${n_complete}/${total} cats complete in sn-burst-samples"
        exit 0
    fi
    if [ $((n_complete - last_reported)) -ge $REPORT_STEP ]; then
        echo "BATCH_READY: ${n_complete}/${total} cats complete in sn-burst-samples ($(date '+%F %T'))"
        last_reported=$n_complete
    fi
    sleep $POLL_SECONDS
done
