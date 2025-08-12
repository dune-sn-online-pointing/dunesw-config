#!/bin/bash

# Initialize env variables
CONDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONDOR_DIR
export HOME_DIR=$(dirname $CONDOR_DIR)
source $HOME_DIR/scripts/init.sh


# parser
print_help() {
    echo "Usage: $0 -j <json-settings> -f <first-job> -l <last-job> [-d false] [-n <n-events>] [-h]"
    echo "  -j, --json-settings        Path to json settings file, expected to be under json/"
    echo "  -n, --n-events               Number of jobs to submit for each job"
    echo "  -f, --first                 First job number"
    echo "  -l, --last                  Last job number" 
    echo "  -d, --delete-submit-files   Delete submit files after submission. Default is true"
    echo "  -h                          Display this help message"
    exit 1
}

# init
delete_submit_files=false
JSON_SETTINGS=""
first=""
last=""
n_events=100 # as agreed, no need to pass from command line


# parse
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--json-settings) JSON_SETTINGS="$2"; shift ;;
        -n|--n-events) n_events="$2"; shift ;;
        -f|--first) first="$2"; shift ;;
        -l|--last) last="$2"; shift ;;
        -d|--delete-submit-files) delete_submit_files="$2"; shift ;;
        -h|--help) print_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Looking for settings file $JSON_SETTINGS. If execution stops, it means that the file was not found."
findSettings_command="$SCRIPT_DIR/findSettings.sh -j $JSON_SETTINGS"
echo "Using command: $findSettings_command"
# last line of the output of findSettings.sh is the full path of the settings file
JSON_SETTINGS=$( $findSettings_command | tail -n 1)
echo -e "Settings file found, full path is: $JSON_SETTINGS \n"

# if options are null, print help and stop execution
if [ -z "$first" ] || [ -z "$last" ]; then
    echo "Error: Missing required parameters"
    print_help
fi

username=$(whoami | cut -d' ' -f1)
user_email="$username@cern.ch"

output_folder="$HOME_DIR/condor/${username}/"
mkdir -p $output_folder
echo "Output folder: $output_folder"
list_of_jobs="${output_folder}list_of_jobs.txt"

# gen fcl
gen_fcl="prodmarley_nue_es_flat_dune10kt_1x2x2"
# these are always standard at the moment
# g4_fcl=""
# detsim_fcl=""
# reco_fcl="TPdump_standardHF_noiseless_MCtruth"

# generate list of arguments and put them in a file, but delete the file first to avoid issues
rm -f $list_of_jobs
touch $list_of_jobs
for i in $(seq $first $last); do
    echo "-j ${JSON_SETTINGS} --home-config ${HOME_DIR} --delete-root -m ${gen_fcl} --custom-energy 69 70 -g -d -r -n $n_events -f $i" >> ${list_of_jobs}
done

echo "List of jobs:"
cat $list_of_jobs

# create the condor submit file
echo "Creating sub script for gen fcl ${gen_fcl}"

# generate a submit file for condor 
submit_file="${output_folder}submit_pointing_training_ES_70MeV_noiseless-from${first}to${last}.sub"
echo "Creating submit file: $submit_file"

cat <<EOF > $submit_file
# script to submit jobs to the grid for sn simulation

notify_user         = ${user_email}
notification        = Error

JOBNAME             = pointing_training_ES_70MeV_noiseless-from${first}to${last}
executable          = ${HOME_DIR}/scripts/triggersim.sh
# using the arguments from below, not this line
# arguments           = -m ${gen_fcl} --custom-energy 70 70 -g -d -r -n 100 -f \$(ProcId)
output              = ${HOME_DIR}/condor/job_output/job.\$(ClusterId).\$(ProcId).\$(JOBNAME).out
error               = ${HOME_DIR}/condor/job_output/job.\$(ClusterId).\$(ProcId).\$(JOBNAME).err
log                 = ${HOME_DIR}/condor/job_output/job.\$(ClusterId).\$(JOBNAME).log
# request_cpus        = 1
# request_memory      = 2000

#requirements = (OpSysAndVer =?= "CentOS7")
MY.WantOS = "el7"
+JobFlavour         = "longlunch"
#+MaxRunTime        = 1800

queue arguments from ${list_of_jobs}
EOF

# submit the job to the grid
echo "Submitting jobs from ${first} to ${last} for gen fcl ${gen_fcl}"
condor_submit $submit_file
if [ "$delete_submit_files" = true ]; then
    rm $submit_file
    rm $list_of_jobs
fi