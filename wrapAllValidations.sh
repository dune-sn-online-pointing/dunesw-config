#!/bin/bash

# read from the file dat/triggerValidation_fcls.dat all the simulations 
# and create empty variables for each simulation

REPO_HOME="$(git rev-parse --show-toplevel)"

list_of_jobs=$REPO_HOME"/dat/triggerValidation_fcls.dat"
echo "In the file $list_of_jobs there are $n_simulations simulations"

# skipping first two lines, header
n_lines=$(wc -l < $list_of_jobs)
n_simulations=$((n_lines-2)) # header
echo "In the file $list_of_jobs there are $n_simulations simulations"

# create an array of size n_simulations called output_files, init all members to ""
# Initialize an array of size n_simulations with empty strings
output_files=()
for ((i=0; i<10; i++)); do
	output_files[i]=""
done

# this is not flexible, could be. Order is from excel:
# Radiological Sample, Central APA
# Radiological Sample, Lateral APA
# Radiological Sample, Central APA, low-rate processes with rate scaled by 500x
# Radiological Sample, Lateral APA, low-rate processes with rate scaled by 500x
# single electrons, isotropic and uniform in direction, 1-500MeV
# single muons, isotropic and uniform in direction, 1-500MeV
# single protons, isotropic and uniform in direction, 1-500MeV
# Marley Ar40CC events, 2-70MeV. Isotropic and uniform in direction
# Marley eES events, 2-70MeV. Isotropic and uniform in direction
# GENIE nu_e beam-like events. In beam direction, NuMI(?) beam profile/energy spectrum
# GENIE nu_mu beam-like events. In beam direction, NuMI(?) beam profile/energy spectrum

# radBkgCentralAPA
# output_files[0]="$REPO_HOME/validation/radBkgCentralAPA.txt"
output_files[0]="$REPO_HOME/condor/job_output/20250328_082605_job.evilla_validationTest_radBkgCentralAPA_5events.5041860.0.out"

# radBkgLateralAPA
# output_files[1]="$REPO_HOME/validation/radBkgLateralAPA.txt"
output_files[1]="$REPO_HOME/condor/job_output/20250328_082609_job.evilla_validationTest_radBkgLateralAPA_5events.5041861.0.out"

# radBkgCentralAPALowRate
output_files[2]="$REPO_HOME/validation/radBkgCentralAPALowRate.txt"

# radBkgLateralAPALowRate
output_files[3]="$REPO_HOME/validation/radBkgLateralAPALowRate.txt"

# singleElectrons
output_files[4]="$REPO_HOME/validation/singleElectrons.txt"

# singleMuons
output_files[5]="$REPO_HOME/validation/singleMuons.txt"

# singleProtons
output_files[6]="$REPO_HOME/validation/singleProtons.txt"

# marleyAr40CC
# output_files[7]="$REPO_HOME/validation/supernovaCC.txt"
output_files[7]="$REPO_HOME/condor/job_output/20250328_082603_job.evilla_validationTest_supernovaCC_5events.5041858.0.out"

# marleyES
# output_files[8]="$REPO_HOME/validation/supernovaES.txt"
output_files[8]="$REPO_HOME/condor/job_output/20250328_082604_job.evilla_validationTest_supernovaES_5events.5041859.0.out"

# genieNuE
output_files[9]="$REPO_HOME/validation/genienue.txt"


print_header="true"
# clean
rm footprintSummary.txt

# Loop through the simulations
for i in $(seq 0 $n_simulations); do
    echo ""
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Reading output of simulation $i"

    # print the filename to footprintSummary.txt
    echo "Output file: $(basename ${output_files[$i]})" >> footprintSummary.txt
    python $REPO_HOME/computeFootprint.py -f ${output_files[$i]} -ph $print_header
    echo " " >> footprintSummary.txt
    print_header="false" # only once
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo ""

done

echo "Done with all simulation, results should be in footprintSummary.txt"

  