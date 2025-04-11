#!/bin/bash
# Usage: ./parse_simulation.sh -f <simulation_log_file>

usage() {
    echo "Usage: $0 -f <simulation_log_file>"
    exit 1
}

# Parse command-line options
while getopts "f:h" opt; do
    case $opt in
        f) logfile="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

nevents=5 # ugly

if [ -z "$logfile" ]; then
    usage
fi

if [ ! -f "$logfile" ]; then
    echo "Error: File '$logfile' not found."
    exit 1
fi

echo "Parsing simulation log file: $logfile"
echo "--------------------------------------------------"

# We expect 4 simulation stages. For each stage, the TimeTracker table contains a "Full event" line.
# Use grep and awk to extract the 4th column (Avg) from each occurrence.
mapfile -t avg_times < <(grep "Full event" "$logfile" | awk '{print $4}')

# Similarly, extract the VmPeak and VmHWM values from the MemoryTracker summary.
# We assume that for each simulation stage a separate MemoryTracker block is present.
mapfile -t vmpeak_vals < <(grep "(VmPeak)" "$logfile" | awk '{print $NF}')
mapfile -t vmhwm_vals < <(grep "(VmHWM)" "$logfile" | awk '{print $NF}')

# Check that we have exactly 4 values for each; if not, warn and exit.
if [ "${#avg_times[@]}" -ne 4 ] || [ "${#vmpeak_vals[@]}" -ne 4 ] || [ "${#vmhwm_vals[@]}" -ne 4 ]; then
    echo "Error: Expected 4 values for each metric but found:"
    echo "  Full event Avg times: ${#avg_times[@]}"
    echo "  VmPeak values: ${#vmpeak_vals[@]}"
    echo "  VmHWM values: ${#vmhwm_vals[@]}"
    exit 1
fi

# Define the stage labels.
stages=("gen" "g4" "detsim" "reco")

# Print a summary table.
# printf "%-8s | %-15s | %-12s | %-12s\n" "Stage" "Avg Time (sec)" "VmHWM (MB)" "VmPeak (MB)"
# echo "---------------------------------------------------------------"
# for i in {0..3}; do
#     printf "%-8s | %-15s | %-12s | %-12s | %-12s | %-12s \n" 
#     printf "${stages[$i]}" "${avg_times[$i]} ${vmhwm_vals[$i]}" "${vmpeak_vals[$i]}"
# done

# Extract the total simulation time from the final "Simulation took" line.
# We assume that the second-to-last field is the time (in seconds).
total_sim_time=$(grep "Simulation took" "$logfile" | tail -n 1 | awk '{print $(NF-1)}')
echo ""
echo "Total Simulation Time: ${total_sim_time} seconds"


# Print a summary table with aligned columns.
# Print CSV header
printf "%-10s %-10s %-10s %-10s %-20s %-10s %-20s %-10s %-20s %-10s %-20s %-30s %-30s %-10s\n" \
printf "%-10s %-10s %-10s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-30s %-30s %-10s\n" \
    "Stage" "Reco1" "Exec time Gen (s/evt)" "Exec time G4 (s/evt)" \
    "Exec time Detsim (s/evt)" "Time Reco1 (s/evt)" "Total exec time per event" \
    "Total exec time per request event" "Memory"
# Ensure variables are initialized
avg_times=(${avg_times[@]:-0 0 0 0})
vmhwm_vals=(${vmhwm_vals[@]:-0 0 0 0})


if [ "$nevents" -le 0 ]; then
    total_exec_time_per_event=$(awk "BEGIN {print (${avg_times[0]:-0} + ${avg_times[1]:-0} + ${avg_times[2]:-0} + ${avg_times[3]:-0})}")
    memory_usage=$(awk "BEGIN {print (${vmhwm_vals[0]:-0} > ${vmhwm_vals[1]:-0} ? (${vmhwm_vals[0]:-0} > ${vmhwm_vals[2]:-0} ? (${vmhwm_vals[0]:-0} > ${vmhwm_vals[3]:-0} ? ${vmhwm_vals[0]:-0} : ${vmhwm_vals[3]:-0}) : (${vmhwm_vals[2]:-0} > ${vmhwm_vals[3]:-0} ? ${vmhwm_vals[2]:-0} : ${vmhwm_vals[3]:-0})) : (${vmhwm_vals[1]:-0} > ${vmhwm_vals[2]:-0} ? (${vmhwm_vals[1]:-0} > ${vmhwm_vals[3]:-0} ? ${vmhwm_vals[1]:-0} : ${vmhwm_vals[3]:-0}) : (${vmhwm_vals[2]:-0} > ${vmhwm_vals[3]:-0} ? ${vmhwm_vals[2]:-0} : ${vmhwm_vals[3]:-0}))) }")
fi
# Calculate total execution time per event and memory usage
exec_time_gen_per_event=$(awk "BEGIN {print (${avg_times[0]:-0} / $nevents)}")
exec_time_g4_per_event=$(awk "BEGIN {print (${avg_times[1]:-0} / $nevents)}")
exec_time_detsim_per_event=$(awk "BEGIN {print (${avg_times[2]:-0} / $nevents)}")
exec_time_reco1_per_event=$(awk "BEGIN {print (${avg_times[3]:-0} / $nevents)}")
exec_time_gen_per_event=$(awk "BEGIN {print (${avg_times[0]} / $nevents)}")
exec_time_g4_per_event=$(awk "BEGIN {print (${avg_times[1]} / $nevents)}")
exec_time_detsim_per_event=$(awk "BEGIN {print (${avg_times[2]} / $nevents)}")
exec_time_reco1_per_event=$(awk "BEGIN {print (${avg_times[3]} / $nevents)}")

# Print header row with aligned columns
printf "%-10s %-10s %-10s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-30s %-30s %-10s\n" \
    "Stage" "Reco1" "Reco2" "Exec time Gen (s/evt)" "Exec time G4 (s/evt)" \
    "Exec time Detsim (s/evt)" "Exec time Reco1 (s/evt)" "Total exec time per event" \
    "Total exec time per request event" "Memory"

# Print data row with aligned columns
printf "%-10s %-10s %-10s %-20.2f %-20.2f %-20.2f %-20.2f %-20.2f %-20.2f %-30.2f %-30.2f %-10d\n" \
    "Reco1" "Reco2" "ana" "${exec_time_gen_per_event}" "${exec_time_g4_per_event}" \
    "${exec_time_detsim_per_event}" "${exec_time_reco1_per_event}" \
    "${total_exec_time_per_event}" "${total_exec_time_per_event}" "${memory_usage}"

# Append the summary to a file named footprintSummary.txt

printf "%-10s %-10s %-10s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-30s %-30s %-10s\n" \
    "Stage" "Reco1" "Reco2" "Exec time Gen (s/evt)" "Exec time G4 (s/evt)" \
    "Exec time Detsim (s/evt)" "Exec time Reco1 (s/evt)" "Total exec time per event" \
    "Total exec time per request event" "Memory" >> footprintSummary.txt
printf "%-10s %-10s %-10s %-20.2f %-20.2f %-20.2f %-20.2f %-20.2f %-20.2f %-30.2f %-30.2f %-10d\n" \
    "Reco1" "Reco2" "ana" "${exec_time_gen_per_event}" "${exec_time_g4_per_event}" \
    "${exec_time_detsim_per_event}" "${exec_time_reco1_per_event}" \
    "${total_exec_time_per_event}" "${total_exec_time_per_event}" "${memory_usage}" >> footprintSummary.txt
echo "--------------------------------------------------"


echo "Summary table has been written to footprintSummary.txt"