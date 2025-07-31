#!/bin/bash

HOME_DIR="$(git rev-parse --show-toplevel)"
echo "HOME_DIR for script submit_pointing_training_ES_70MeV_noiseless.sh: $HOME_DIR"

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
delete_submit_files=true
json_settings=""
first=""
last=""
n_events=10 # as agreed, no need to pass from command line


# parse
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--json-settings) json_settings="$2"; shift ;;
        -n|--n-events) n_events="$2"; shift ;;
        -f|--first) first="$2"; shift ;;
        -l|--last) last="$2"; shift ;;
        -d|--delete-submit-files) delete_submit_files="$2"; shift ;;
        -h|--help) print_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# if options are null, print help and stop execution
if [ -z "$json_settings" ] || [ -z "$first" ] || [ -z "$last" ]; then
    echo "Error: Missing required parameters"
    print_help
fi

# read email from json settings file
username=$(awk -F'"' '/username/ {print $4}' $HOME_DIR/json/${json_settings})
user_email=$(awk -F'"' '/userEmail/ {print $4}' $HOME_DIR/json/${json_settings})

output_folder="${HOME_DIR}/condor/${username}/"
list_of_jobs="${output_folder}list_of_jobs.txt"

# gen fcl
gen_fcl="prodmarley_nue_spectrum_radiological_decay0_dune10kt_refactored_1x2x6_CC_modifiedBkgRate"
# these are always standard at the moment
# g4_fcl=""
# detsim_fcl=""
# reco_fcl="TPdump_standardHF_noiseless_MCtruth"

# generate list of arguments and put them in a file, but delete the file first to avoid issues
rm -f $list_of_jobs
for i in $(seq $first $last); do
    echo "-j ${json_settings} --home-config ${HOME_DIR} -m ${gen_fcl} -g -d -r -n $n_events -f $i" >> ${list_of_jobs}
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
executable          = ${HOME_DIR}/scripts/dunetrigger.sh
# using the arguments from below, not this line
# arguments           = -m ${gen_fcl} -g -d -r -n 10 -f \$(ProcId)
output              = ${HOME_DIR}/condor/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
error               = ${HOME_DIR}/condor/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).err
log                 = ${HOME_DIR}/condor/job_output/job.\$(JOBNAME).\$(ClusterId).log
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