#!/bin/bash

# number of jobs in hundreds
start_hundred=29
end_hundred=29
# n_jobs=100 + 10

# start_tens=1
# end_tens=9

for i in $(seq $start_hundred $end_hundred)
do
    # for tens in $(seq $start_tens $end_tens)
    # do
    echo "Creating sub scripts for 100 jobs from Id ${i}00, ES events, highE"

    # generate a submit file for condor 
    submit_file="submit_highE_XYZ_ES_${i}00_times10_script.sub"
    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = emanuele.villa@cern.ch
    notification        = Error

    JOBNAME             = sn-high-energy-script-hundreds-$i-afs
    executable          = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/run-sn-simulation.sh
    arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_ES --custom-direction --custom-energy 30 70 -g -d -r -n 200 -f ${i}\$(ProcId)
    output              = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
    error               = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).err
    log                 = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).log
    # request_cpus        = 1
    # request_memory      = 2000

    #requirements = (OpSysAndVer =?= "CentOS7")
    MY.WantOS = "el7"
    +JobFlavour         = "workday"

    queue 100
EOF

    # submit the job to the grid
    echo "Submitting job ${submit_file} to the grid"
    cat $submit_file
    condor_submit $submit_file

    # LAST 10
    echo "Creating sub scripts for 10 jobs from Id ${i}00, ES events, highE"

    # generate a submit file for condor 
    submit_file="submit_highE_XYZ_ES_${i}00_tens_script.sub"
    cat <<EOF > $submit_file
    # script to submit jobs to the grid for sn simulation

    notify_user         = emanuele.villa@cern.ch
    notification        = Error

    JOBNAME             = sn-high-energy-script-tens-${i}00-afs
    executable          = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/run-sn-simulation.sh
    arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_ES --custom-direction --custom-energy 30 70 -g -d -r -n 200 -f ${i}0\$(ProcId)
    output              = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
    error               = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).err
    log                 = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).log
    # request_cpus        = 1
    # request_memory      = 2000

    #requirements = (OpSysAndVer =?= "CentOS7")
    MY.WantOS = "el7"
    +JobFlavour         = "workday"

    queue 10    
EOF

    # submit the job to the grid
    echo "Submitting job ${submit_file} to the grid"
    cat $submit_file
    condor_submit $submit_file

    # done
    # sleep 4000
done

# the ones 0-9 will fail, run separately

# for i in $(seq $start_hundred $end_hundred)
# do
#     echo "Creating sub scripts for 10 jobs from Id ${i}00, ES events, highE"

#     # generate a submit file for condor 
#     submit_file="submit_highE_XYZ_ES_${i}00_tens_script.sub"
#     cat <<EOF > $submit_file
#     # script to submit jobs to the grid for sn simulation

#     notify_user         = emanuele.villa@cern.ch
#     notification        = Error

#     JOBNAME             = sn-high-energy-script-tens-${i}00-afs
#     executable          = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/run-sn-simulation.sh
#     arguments           = -m prodmarley_nue_flat_clean_dune10kt_1x2x6_ES --custom-direction --custom-energy 30 70 -g -d -r -n 200 -f ${i}0\$(ProcId)
#     output              = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).out
#     error               = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).\$(ProcId).err
#     log                 = /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/job_output/job.\$(JOBNAME).\$(ClusterId).log
#     # request_cpus        = 1
#     # request_memory      = 2000

#     #requirements = (OpSysAndVer =?= "CentOS7")
#     MY.WantOS = "el7"
#     +JobFlavour         = "workday"

#     queue 10    
# EOF

#     # submit the job to the grid
#     echo "Submitting job ${submit_file} to the grid"
#     cat $submit_file
#     condor_submit $submit_file

# done

mv submit_highE_XYZ_ES_*_script.sub /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/submit_files/
