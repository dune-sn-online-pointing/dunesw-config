#!/bin/bash

TRIGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TRIGGER_DIR
export REPO_HOME="$(dirname "$TRIGGER_DIR")"
source $REPO_HOME/scripts/init.sh

list_of_jobs=$REPO_HOME"/dat/triggerValidation_fcls.dat"
output_file="${REPO_HOME}/trigger_production/footprintSummary.txt"

n_events=10
user_name=$(whoami)
print_header=true # python bool

# skipping first two lines, header
n_lines=$(wc -l < $list_of_jobs)
n_simulations=$((n_lines-2)) # header
echo "In the file $list_of_jobs there are $n_simulations simulations"

# clean every time this script is run
rm -rf $output_file
echo "Cleaning $output_file, new results will be written to it"

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
    job_printout="${REPO_HOME}/trigger_production/${user_name}_validationTest_${sim_name}_${n_events}events.txt"

    echo ""
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Reading output of simulation $sim_name"
    echo "Job printout for: ${sim_name}" >> $output_file
    print_command="python $PYTHON_DIR/computeFootprint.py -f ${job_printout} -n $n_events -o $output_file"
    # if the print_header is True, add the header to the output file
    if [ "$print_header" = true ]; then
        print_command="$print_command --print-header"
        echo "Header will be printed to the output file"
    fi
    echo "Command: $print_command"
    # run the command   
    $print_command
    echo " " >> $output_file
    print_header=false # only once
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo ""

done

echo "Done with all simulation, results should be in $output_file"

  