#!/bin/bash

# define an array containing the values 2,5,10,15,20,30,40,50,60,70
bins=(2 5 10 15 20 30 40 50 60 70)


# ES events

# cycle over length of bins -1, since last value wiill not have a following bin
for i in $(seq 0 $((${#bins[@]}-1)))
do
    echo "Creating sub scripts for energy range ${bins[i]} to ${bins[i+1]} MeV, ES events"

    # generate a submit file for condor 
    submit_file="submitEnergyBins${bins[i]}_to_${bins[i+1]}_ES.sub"
    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = emanuele.villa@cern.ch
    notification        = Error

    JOBNAME             = sn-custom-energy-ranges-${bins[i]}_to_${bins[i+1]}-ES-clean
    executable          = /afs/cern.ch/work/e/evilla/private/dune/dunesw/verbose-dev/run-sn-simulation.sh
    #arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_ES --custom-energy ${bins[i]} ${bins[i+1]} -g -d -r -n 50 -f ${bins[i]}_to_${bins[i+1]}_MeV_$(ProcId)
    output              = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.$(JOBNAME).$(ClusterId).$(ProcId).out
    error               = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.$(JOBNAME).$(ClusterId).$(ProcId).err
    log                 = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.$(JOBNAME).$(ClusterId).log
    request_cpus        = 1
    # request_memory      = 2000

    #requirements = (OpSysAndVer =?= "CentOS7")
    MY.WantOS = "el7"
    +JobFlavour         = "microcentury"
    #+MaxRunTime        = 1800

    queue 100    
EOF

    # submit the job to the grid
    echo "Submitting jobs for energy range ${bins[i]} to ${bins[i+1]} MeV, ES events"
    condor_submit $submit_file

done


# CC events

# cycle over length of bins -1, since last value will not have a following bin
for i in $(seq 0 $((${#bins[@]}-1)))
do
    echo "Creating sub scripts for jobs for energy range ${bins[i]} to ${bins[i+1]} MeV"

    # generate a submit file for condor 
    submit_file="submitEnergyBins${bins[i]}_to_${bins[i+1]}_CC.sub"
    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = emanuele.villa@cern.ch
    notification        = Error

    JOBNAME             = sn-custom-energy-ranges-${bins[i]}_to_${bins[i+1]}-CC-clean
    executable          = /afs/cern.ch/work/e/evilla/private/dune/dunesw/verbose-dev/run-sn-simulation.sh
    #arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_CC --custom-energy ${bins[i]} ${bins[i+1]} -g -d -r -n 50 -f ${bins[i]}_to_${bins[i+1]}_MeV_$(ProcId)
    output              = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.$(JOBNAME).$(ClusterId).$(ProcId).out
    error               = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.$(JOBNAME).$(ClusterId).$(ProcId).err
    log                 = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.$(JOBNAME).$(ClusterId).log
    request_cpus        = 1
    # request_memory      = 2000

    #requirements = (OpSysAndVer =?= "CentOS7")
    MY.WantOS = "el7"
    +JobFlavour         = "microcentury"
    #+MaxRunTime        = 1800

    queue 100    
EOF

    # submit the job to the grid
    echo "Submitting jobs for energy range ${bins[i]} to ${bins[i+1]} MeV, CC events"
    condor_submit $submit_file

done