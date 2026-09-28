#!/bin/bash
# Orchestrate generation waves for cats [FIRST,LAST] in chunks of WAVE_SIZE cats.
# Submits the next wave only when the user's condor queue has fewer than
# QUEUE_THRESHOLD jobs, so the scheduler is never flooded.
# Log: one line per action (parsed by the session driving the campaign).

FIRST=${FIRST:-624}
LAST=${LAST:-1223}
WAVE_SIZE=${WAVE_SIZE:-50}
QUEUE_THRESHOLD=${QUEUE_THRESHOLD:-2000}
POLL_SECONDS=${POLL_SECONDS:-600}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STOP_FILE="$HERE/STOP_WAVES"
rm -f "$STOP_FILE"
echo "[$(date '+%F %T')] orchestrator PID $$ (touch $STOP_FILE to stop)"

start=$FIRST
while [ $start -le $LAST ]; do
    end=$((start + WAVE_SIZE - 1))
    [ $end -gt $LAST ] && end=$LAST

    # throttle on queue occupancy
    while :; do
        if [ -f "$STOP_FILE" ]; then
            echo "[$(date '+%F %T')] STOP_WAVES found, exiting before wave ${start}-${end}"
            exit 0
        fi
        n_queued=$(condor_q -totals -nobatch 2>/dev/null | awk '/Total for '"$(whoami)"'/ {print $4}')
        [ -z "$n_queued" ] && n_queued=999999  # condor_q failed; be conservative, retry
        # never submit into an exhausted file-count quota (jobs would lose output)
        ino_avail=$(getfattr --absolute-names --only-values -n eos.quota /eos/project-e/ep-nu 2>/dev/null | awk '/^project-e/ {print $5}')
        [ -z "$ino_avail" ] && ino_avail=0
        if [ "$n_queued" -lt "$QUEUE_THRESHOLD" ] && [ "$ino_avail" -gt 30000 ]; then
            break
        fi
        if [ "$ino_avail" -le 30000 ]; then
            echo "[$(date '+%F %T')] holding: ep-nu ino-avail=$ino_avail (<=30000)"
        fi
        sleep $POLL_SECONDS
    done

    echo "[$(date '+%F %T')] submitting wave cats ${start}-${end} (queue was ${n_queued})"
    if ! "$HERE/gen_wave.sh" -f $start -l $end 2>&1 | tail -2; then
        echo "[$(date '+%F %T')] ERROR submitting wave ${start}-${end}, aborting orchestrator"
        exit 1
    fi
    start=$((end + 1))
done

echo "[$(date '+%F %T')] all waves submitted (cats ${FIRST}-${LAST})"

# wait for the queue to fully drain before declaring generation finished
while :; do
    n_queued=$(condor_q -totals -nobatch 2>/dev/null | awk '/Total for '"$(whoami)"'/ {print $4}')
    [ -z "$n_queued" ] && n_queued=999999
    [ "$n_queued" -eq 0 ] && break
    sleep $POLL_SECONDS
done
echo "[$(date '+%F %T')] GENERATION QUEUE DRAINED for cats ${FIRST}-${LAST}"
