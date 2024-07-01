#!/bin/bash

REPO_HOME="$(git rev-parse --show-toplevel)"
echo "REPO_HOME for script run-sn-simulation.sh: $REPO_HOME"

# read email from json settings file
user_email=$(awk -F'"' '/userEmail/ {print $4}' $REPO_HOME/settings.json)

# define an array containing the values 2,5,10,15,20,30,40,50,60,70
bins=(2 5 10 15 20 30 40 50 60 70)
n_jobs=100
delete_submit_files=true

# ES events

# cycle over length of bins -1, since last value wiill not have a following bin
for i in $(seq 0 $((${#bins[@]}-2)))
do
    echo "Creating sub scripts for energy range ${bins[i]} to ${bins[i+1]} MeV, ES events"

    # generate a submit file for condor 
    submit_file="submitEnergyBins${bins[i]}_to_${bins[i+1]}_ES.sub"
    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = $user_email
    notification        = Error

    JOBNAME             = sn-custom-energy-ranges-${bins[i]}_to_${bins[i+1]}-ES-clean
    executable          = ${REPO_HOME}/scripts/run-sn-simulation.sh
    arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_ES --custom-energy ${bins[i]} ${bins[i+1]} -g -d -r -n 50 -f ${bins[i]}-to-${bins[i+1]}-MeV_\$(ProcId)
    output              = ${REPO_HOME}/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
    error               = ${REPO_HOME}/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).err
    log                 = ${REPO_HOME}/job_output/job.\$(JOBNAME).\$(ClusterId).log
    # request_cpus        = 1
    # request_memory      = 2000

    #requirements = (OpSysAndVer =?= "CentOS7")
    MY.WantOS = "el7"
    +JobFlavour         = "longlunch"
    #+MaxRunTime        = 1800

    queue $n_jobs    
EOF

    # submit the job to the grid
    echo "Submitting jobs for energy range ${bins[i]} to ${bins[i+1]} MeV, ES events"
    condor_submit $submit_file
    if [ "$delete_submit_files" = true ]; then
        rm $submit_file
    fi

done


# CC events

# cycle over length of bins -1, since last value will not have a following bin
for i in $(seq 0 $((${#bins[@]}-2)))
do
    echo "Creating sub scripts for jobs for energy range ${bins[i]} to ${bins[i+1]} MeV"

    # generate a submit file for condor 
    submit_file="submitEnergyBins${bins[i]}_to_${bins[i+1]}_CC.sub"
    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = $user_email
    notification        = Error

    JOBNAME             = sn-custom-energy-ranges-${bins[i]}_to_${bins[i+1]}-CC-clean
    executable          = ${REPO_HOME}/scripts/run-sn-simulation.sh
    arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_CC --custom-energy ${bins[i]} ${bins[i+1]} -g -d -r -n 50 -f ${bins[i]}-to-${bins[i+1]}-MeV_\$(ProcId)
    output              = ${REPO_HOME}/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
    error               = ${REPO_HOME}/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).err
    log                 = ${REPO_HOME}/job_output/job.\$(JOBNAME).\$(ClusterId).log
    # request_cpus        = 1
    # request_memory      = 2000

    #requirements = (OpSysAndVer =?= "CentOS7")
    MY.WantOS = "el7"
    +JobFlavour         = "longlunch"
    #+MaxRunTime        = 1800

    queue $n_jobs   
EOF

    # submit the job to the grid
    echo "Submitting jobs for energy range ${bins[i]} to ${bins[i+1]} MeV, CC events"
    condor_submit $submit_file
    if [ "$delete_submit_files" = true ]; then
        rm $submit_file
    fi

done
