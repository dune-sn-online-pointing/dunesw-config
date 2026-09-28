#!/bin/bash
# Submit one generation wave for SN burst catalogs (cats): for each cat in
# [first,last], queue 10 ES jobs (i=0..9) and 100 CC jobs (i=0..99), 40 events each,
# through eosTrigSim.sh with --catalog-direction <cat>.
#
# Modeled on condor/submit_ES_eos.sh + submit_CC_eos.sh (catalog.sh flow), but:
#  - one condor cluster per wave (ES+CC together) instead of 2 clusters/cat
#  - stdout/stderr -> /dev/null, condor event log -> /tmp (protects AFS quota)
#  - optional args-file input for resubmission of missing jobs (from check_gen.py)
#
# Usage:
#   ./gen_wave.sh -f <first_cat> -l <last_cat> [-p]
#   ./gen_wave.sh --args-file <file> [-p]        # resubmit specific jobs

CONDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export HOME_DIR=$(dirname $CONDOR_DIR)

first=""
last=""
args_file=""
print_only=false
n_events=40
json_settings="/afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/json/v10_10_05d00.json"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--first) first="$2"; shift ;;
        -l|--last) last="$2"; shift ;;
        --args-file) args_file="$2"; shift ;;
        -p|--print-only) print_only=true ;;
        -h|--help) echo "Usage: $0 -f <first_cat> -l <last_cat> [-p] | --args-file <file> [-p]"; exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

user_email="$(whoami)@cern.ch"
out_dir="$CONDOR_DIR/evilla"
log_dir="/tmp/$(whoami)/snop_gen_logs"
mkdir -p "$log_dir"

gen_fcl_es="prodmarley_nue_es_gkvm_dune10kt_1x2x2"
gen_fcl_cc="prodmarley_nue_cc_gkvm_dune10kt_1x2x2"

if [[ -n "$args_file" ]]; then
    list_of_jobs="$args_file"
    tag="resubmit_$(date +%Y%m%d_%H%M%S)"
else
    if [[ -z "$first" || -z "$last" ]]; then
        echo "Error: need -f and -l (or --args-file)"; exit 1
    fi
    tag="cats${first}to${last}"
    list_of_jobs="${out_dir}/wave_${tag}.args"
    # build in a temp file and move atomically: an interrupted build must never
    # leave a partial args file that a later condor_submit could pick up
    tmp_list="${list_of_jobs}.tmp.$$"
    rm -f "$list_of_jobs" "$tmp_list"
    for cat in $(seq $first $last); do
        # catalog direction fcls must exist
        if [[ ! -f "$HOME_DIR/create_directions/output/${gen_fcl_es}_customDirection_${cat}.fcl" ]]; then
            echo "ERROR: missing catalog fcl for direction $cat"; rm -f "$tmp_list"; exit 1
        fi
        {
        for i in $(seq 0 9); do
            echo "-j ${json_settings} --home-config ${HOME_DIR} --delete-root true -m ${gen_fcl_es} --catalog-direction $cat -g -d -r -n $n_events -f $i"
        done
        for i in $(seq 0 99); do
            echo "-j ${json_settings} --home-config ${HOME_DIR} --delete-root true -m ${gen_fcl_cc} --catalog-direction $cat -g -d -r -n $n_events -f $i"
        done
        } >> "$tmp_list"
    done
    expected=$(( (last - first + 1) * 110 ))
    actual=$(wc -l < "$tmp_list")
    if [[ "$actual" -ne "$expected" ]]; then
        echo "ERROR: args file has $actual lines, expected $expected"; rm -f "$tmp_list"; exit 1
    fi
    mv "$tmp_list" "$list_of_jobs"
fi

n_jobs=$(wc -l < "$list_of_jobs")
submit_file="${out_dir}/wave_${tag}.sub"

cat > "$submit_file" <<EOF
notify_user         = ${user_email}
notification        = Never

JOBNAME             = snop_gen_${tag}
executable          = ${HOME_DIR}/scripts/eosTrigSim.sh
output              = /dev/null
error               = /dev/null
log                 = ${log_dir}/wave_${tag}.\$(ClusterId).log

MY.WantOS           = "el7"
request_disk        = 12 GB
+JobFlavour         = "workday"

queue arguments from ${list_of_jobs}
EOF

echo "Wave ${tag}: ${n_jobs} jobs"
if [ "$print_only" = true ]; then
    cat "$submit_file"
else
    condor_submit "$submit_file"
fi
