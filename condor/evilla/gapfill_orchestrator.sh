#!/bin/bash
# Resubmit all missing generation files for cats [FIRST,LAST] in chunks of
# CHUNK_JOBS, guarded by queue occupancy AND ep-nu inode availability.
# Regenerates the missing-file list before each chunk (so it never resubmits
# files that landed meanwhile). STOP_WAVES file stops it.
FIRST=${FIRST:-623}
LAST=${LAST:-1223}
CHUNK_JOBS=${CHUNK_JOBS:-5500}
QUEUE_THRESHOLD=${QUEUE_THRESHOLD:-3000}
MIN_INO=${MIN_INO:-30000}
POLL_SECONDS=${POLL_SECONDS:-600}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOP_FILE="$HERE/STOP_WAVES"
rm -f "$STOP_FILE"
echo "[$(date '+%F %T')] gapfill orchestrator PID $$ (touch $STOP_FILE to stop)"

while :; do
    # wait for capacity
    while :; do
        [ -f "$STOP_FILE" ] && echo "[$(date '+%F %T')] STOP_WAVES found, exiting" && exit 0
        n_queued=$(condor_q -totals -nobatch 2>/dev/null | awk '/Total for '"$(whoami)"'/ {print $4}')
        [ -z "$n_queued" ] && n_queued=999999
        ino_avail=$(getfattr --absolute-names --only-values -n eos.quota /eos/project-e/ep-nu 2>/dev/null | awk '/^project-e/ {print $5}')
        [ -z "$ino_avail" ] && ino_avail=0
        if [ "$n_queued" -lt "$QUEUE_THRESHOLD" ] && [ "$ino_avail" -gt "$MIN_INO" ]; then
            break
        fi
        sleep $POLL_SECONDS
    done

    # regenerate missing list; exclude what this run already submitted
    full_args="$HERE/gapfill_full.args"
    marker="$HERE/gapfill_submitted.args"
    touch "$marker"
    python3 "$HERE/check_gen.py" --first $FIRST --last $LAST --resubmit-args "$full_args" > /dev/null 2>&1
    [ -f "$full_args" ] || : > "$full_args"
    if [ ! -s "$full_args" ]; then
        echo "[$(date '+%F %T')] GAPFILL COMPLETE: no missing files in $FIRST-$LAST"
        exit 0
    fi
    candidates="$HERE/gapfill_candidates.args"
    grep -Fxv -f "$marker" "$full_args" > "$candidates" || true
    if [ ! -s "$candidates" ]; then
        # everything missing is already in flight; when queue empties, reset the
        # marker so persistent failures get one more sweep
        if [ "$n_queued" -eq 0 ]; then
            echo "[$(date '+%F %T')] queue empty but $(wc -l < "$full_args") files still missing; resetting marker for retry sweep"
            : > "$marker"
        fi
        sleep $POLL_SECONDS
        continue
    fi
    chunk="$HERE/gapfill_chunk.args"
    head -n $CHUNK_JOBS "$candidates" > "$chunk"
    n_chunk=$(wc -l < "$chunk")
    echo "[$(date '+%F %T')] submitting chunk of $n_chunk jobs ($(wc -l < "$full_args") missing total, ino_avail=$ino_avail)"
    if "$HERE/gen_wave.sh" --args-file "$chunk" 2>&1 | grep -E "submitted|ERROR"; then
        cat "$chunk" >> "$marker"
    fi
    sleep $POLL_SECONDS
done
