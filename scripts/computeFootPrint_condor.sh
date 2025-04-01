#!/bin/bash

REPO_HOME="$(git rev-parse --show-toplevel)"
echo "REPO_HOME for script submit_triggerProductionTests.sh: $REPO_HOME"

# parser
print_help() {
    echo "****************************************************************************************"
    echo "Usage: $0 -j <json-settings> [-d false] [-n <n-events>] [-h]"
    echo "  -j, --json-settings         Path to json settings file, expected to be under json/"
    echo "  -h                          Display this help message"
    echo "****************************************************************************************"
    exit 1
}

# init
delete_submit_files=false
json_settings=""
first=""
last=""
n_events=5 # default, sounds sensible
list_of_jobs=$REPO_HOME"/dat/triggerValidation_fcls.dat"

# parse
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--json-settings) json_settings="$2"; shift ;;
        -h|--help) print_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

user_name=$(whoami)

# for output of condor jobs, TODO make more general
condor_output_folder="${REPO_HOME}/condor/job_output/"

# count lines in triggerValidation_fcls.txt
n_lines=$(wc -l < $list_of_jobs)
n_simulations=$((n_lines-2)) # header
echo "In the file $list_of_jobs there are $n_simulations simulations"

# array to store the time of each simulation
times=()

# skipping first two lines, header
for i in $(seq 3 $n_lines); do
    echo ""
    echo "Reading line $i:"
    echo "$(sed -n "${i}p" $list_of_jobs)"
    # if the simulation name contains a "-" or it's the message, skip since it's just the separator
    if [ "$(sed -n "${i}p" $list_of_jobs | grep -c '\-\-')" -eq 1 ] || [ "$(sed -n "${i}p" $list_of_jobs | grep -c 'Under')" -eq 1 ]; then
        echo "Skipping this line, it's a separator or a comment"
        continue
    fi

    line=$(sed -n "${i}p" $list_of_jobs | tr -d '|')
    sim_name=$(echo $line | awk '{print $1}')
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Simulation: $sim_name"

    # find in condor/job_output/ the files that contain the simulation name and your username
    out_files=$(find $condor_output_folder -type f -name "*${user_name}*${sim_name}*.out")
    echo "Output files found: $out_files"

    # keep only the most recent one 
    most_recent_out_file=$(ls -t $out_files | head -n 1)
    echo "Most recent output file: $most_recent_out_file"

    # read lines and find "Simulation took" and "TimeReport CPU"
    tot_time=$(grep "Simulation took" $most_recent_out_file | awk '{print $3}')
    echo "Whole simulation took: $total_time"
    echo ""
    gen_time=$(grep "Generation took" $most_recent_out_file | awk '{print $3}')
    echo "Generation took: $gen_time"
    g4_time=$(grep "Geant4 took" $most_recent_out_file | awk '{print $3}')
    echo "G4 took: $g4_time"
    detsim_time=$(grep "DetSim took" $most_recent_out_file | awk '{print $3}')
    echo "Detsim took: $detsim_time"
    reco_time=$(grep "Reco took" $most_recent_out_file | awk '{print $3}')
    echo "Reconstruction took: $reco_time"

    stages=("gen" "g4" "detsim" "reco")
    avg_time=()
    vmhwm=()
    vmpeak=()

    for i in {0..3}; do
        # print the line where Full event first appears
        echo "Full event appears in line:"
        grep -n "Full event" "$most_recent_out_file" | awk "NR==$((i+1)) {print}"
        avg_time[i]=$(grep "Full event" "$most_recent_out_file" | awk "NR==$((i+1)) {print \$4}")
        echo "VmHWM event appears in line:"
        grep -n "VmHWM" "$most_recent_out_file" | awk "NR==$((i+1)) {print}"
        vmhwm[i]=$(grep "VmHWM" "$most_recent_out_file" | awk "NR==$((i+1)) {print \$NF}")
        echo "Vmpeak event appears in line:"
        grep -n "VmPeak" "$most_recent_out_file" | awk "NR==$((i+1)) {print}"
        vmpeak[i]=$(grep "VmPeak" "$most_recent_out_file" | awk "NR==$((i+1)) {print \$NF}")
        echo "${stages[i]}, time per event ${avg_time[i]}, hw memory ${vmhwm[i]}, memory peak ${vmpeak[i]}"
    done

    # store the times in the array, in columns, aligned
    times+=("$sim_name $total_time $cpu_time $gen_time $g4_time $detsim_time $reco_time")

    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
done

# echo "sim_short_name | tot time | Gen tot | Gen per event | G4 tot | G4 per event | Detsim tot | Detsim per event | Reco tot | Reco per event |"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
printf "%-20s | %-12s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s |  %-15s |  %-15s |  %-15s |  %-15s |\n" \
"Simulation" "tot Time" \
"Gen tot time" "Gen time/ev" "Gen peak mem" "Gen HW mem" \
"G4 tot time" "G4 time/ev" "G4 peak mem" "G4 HW mem" \
"Detsim tot time" "Detsim time/ev" "Detsim peak mem" "Detsim HW mem" \
"Reco tot time" "Reco time/ev" "Reco peak mem" "Reco HW mem"

printf "%-20s | %-12s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s |\n" \
"Simulation" "tot Time" \
"Gen tot time" "Gen time/ev" "Gen peak mem" "Gen HW mem" \
"G4 tot time" "G4 time/ev" "G4 peak mem" "G4 HW mem" \
"Detsim tot time" "Detsim time/ev" "Detsim peak mem" "Detsim HW mem" \
"Reco tot time" "Reco time/ev" "Reco peak mem" "Reco HW mem"> $REPO_HOME"/dat/triggerValidation_times.dat"

for time in "${times[@]}"; do
    echo " IT IS $time"
    printf "%-20s | %-12s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s |\n" $time
    printf "%-20s | %-12s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s | %-15s |\n" $time >> $REPO_HOME"/dat/triggerValidation_times.dat"
done

echo "Results printed also to $REPO_HOME/dat/triggerValidation_times.dat"
