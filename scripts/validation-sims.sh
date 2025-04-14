#!/bin/bash

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
source $SCRIPT_DIR/init.sh

# parser
print_help() {
    echo "****************************************************************************************"
    echo "Usage: $0 -j <json-settings> [-d false] [-n <n-events>] [-h]"
    echo "  -j, --json-settings         Path to json settings file, expected to be under json/"
    echo "  -n, --n-events              Number of events to submit for each job"
    echo "  -p, --print-only            Print the command to be executed, but do not execute it"
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
output_folder="${REPO_HOME}/trigger_production/"

# parse
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--json-settings) json_settings="$2"; shift ;;
        -n|--n-events)      n_events="$2"; shift ;;
        -p|--print-only)    print_only=true; shift ;;
        -h|--help)          print_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# if options are null, print help and stop execution
if [ -z "$json_settings" ] ; then
    echo "Error: Missing json settings"
    print_help
fi

user_name=$(whoami)

# count lines in triggerValidation_fcls.txt
n_lines=$(wc -l < $list_of_jobs)
n_simulations=$((n_lines-2)) # header
echo "In the file $list_of_jobs there are $n_simulations simulations"

# skipping first two lines, header
for i in $(seq 3 $n_lines); do
    
    # if the simulation name containts a "-", stop the execution 
    if [ "$(sed -n "${i}p" $list_of_jobs | grep -c '\--')" -eq 1 ]; then
        echo "Reached end of valid area in the file containing the list of simulations, stopping execution."
        break
    fi

    line=$(sed -n "${i}p" $list_of_jobs | tr -d '|')
    # split the line
    sim_name=$(echo $line | awk '{print $1}')
    gen_fcl=$(echo $line | awk '{print $2}')
    g4_fcl=$(echo $line | awk '{print $3}')
    detsim_fcl=$(echo $line | awk '{print $4}')
    reco_fcl=$(echo $line | awk '{print $5}')
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Simulation: $sim_name"
    echo "gen fcl: $gen_fcl"
    echo "g4 fcl: $g4_fcl"
    echo "detsim fcl: $detsim_fcl"
    echo "reco fcl: $reco_fcl"
    echo ""
    echo "About to run simulation for ${gen_fcl}"

    output_file="${user_name}_validationTest_${sim_name}_${n_events}events.txt"
    now=$(date +"%Y%m%d_%H%M%S") 
    
    # script to submit jobs to the grid for sn simulation

    executable="${REPO_HOME}/scripts/triggersim.sh"
    arguments="-m ${gen_fcl} -g ${g4_fcl} -d ${detsim_fcl} -r ${reco_fcl} -j ${json_settings} -f ${sim_name}_triggerValidationTest -n ${n_events} --home-config ${REPO_HOME}"
    # adding path
    output_file="${output_folder}${output_file}"

    run_command="${executable} ${arguments} > ${output_file} 2>&1"
    echo "Running command: ${run_command}"
    if [ "$print_only" = false ]; then
        eval "${run_command}"
    else
        echo "WARNING: Not actually executing it, because print-only is set to true"
    fi
    echo "Command finished with exit code: $?"

    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
done