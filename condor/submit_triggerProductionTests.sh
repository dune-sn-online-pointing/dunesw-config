#!/bin/bash

CONDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONDOR_DIR
export REPO_HOME=$(dirname $CONDOR_DIR)
source $REPO_HOME/scripts/init.sh

# parser
print_help() {
    echo "****************************************************************************************"
    echo "Usage: $0 -j <json-settings> [-d false] [-n <n-events>] [-h]"
    echo "  -j, --json-settings         Path to json settings file, expected to be under json/"
    echo "  -n, --n-events              Number of events to submit for each job"
    echo "  -d, --delete-submit-files   Delete submit files after submission. Default is false"
    echo "  -h                          Display this help message"
    echo "****************************************************************************************"
    exit 1
}

# init
delete_submit_files=false
json_settings=""
first=""
last=""
n_events=10
list_of_jobs=$REPO_HOME"/dat/triggerValidation_fcls.dat"


# parse
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--json-settings) json_settings="$2"; shift ;;
        -n|--n-events) n_events="$2"; shift ;;
        -d|--delete-submit-files) delete_submit_files="$2"; shift ;;
        -h|--help) print_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Looking for settings file $JSON_SETTINGS. If execution stops, it means that the file was not found."
findSettings_command="$SCRIPT_DIR/findSettings.sh -s $JSON_SETTINGS"
# last line of the output of findSettings.sh is the full path of the settings file
JSON_SETTINGS=$( $findSettings_command | tail -n 1)
echo -e "Settings file found, full path is: $JSON_SETTINGS \n"

# read email from json settings file
user_name=$(whoami)
user_email=$user_name"@cern.ch"

# for output of condor jobs
output_folder="${REPO_HOME}/condor/job_output/"

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
    echo "Creating .sub script for gen fcl ${gen_fcl}"

    # generate a submit file for condor 
    job_name="${user_name}_validationTest_${sim_name}_${n_events}events"
    submit_file="${output_folder}${job_name}.sub"
    now=$(date +"%Y%m%d_%H%M%S")
    echo "Creating submit file: $submit_file"

    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = ${user_email}
    notification        = Always

    JOBNAME             = ${job_name}
    executable          = ${REPO_HOME}/scripts/triggersim.sh
    arguments           = -m ${gen_fcl} -g ${g4_fcl} -d ${detsim_fcl} -r ${reco_fcl} -j ${json_settings} -f ${sim_name}_triggerValidationTest -n ${n_events} --home-config ${REPO_HOME}
    output              = ${REPO_HOME}/condor/job_output/${now}_job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
    error               = ${REPO_HOME}/condor/job_output/${now}_job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
    log                 = ${REPO_HOME}/condor/job_output/${now}_job.\$(JOBNAME).\$(ClusterId).log
    # request_cpus        = 1
    # request_memory      = 2000

    MY.WantOS = "el7"
    +JobFlavour         = "workday"
    #+MaxRunTime        = 1800

    queue
EOF

    # submit the job to the grid
    echo "Submitting $submit_file to condor"
    condor_submit $submit_file
    if [ "$delete_submit_files" = true ]; then
        rm $submit_file
        rm $list_of_jobs
    fi
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
done