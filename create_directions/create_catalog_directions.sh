#!/bin/bash

# This script generates a catalog of random directions for the neutrino SN explosion

function print_help() {
    echo "*****************************************************************************"
    echo "Usage: $0 -f your_fcl_file -n number_of_directions [-o output_folder] [-v]"
    echo "Options:"
    echo "  -f, --fcl-file                Fcl file to start from"
    echo "  -v, --verbose                 Print verbose output of script that creates directions"
    echo "  -o --output                   Output folder for the fcl files. Default is ./output"
    echo "  -n, --number-of-directions    Number of directions to be generated"
    echo "  -h, --help                    Print this help message"
    echo "*****************************************************************************"
    exit 0
}

HOME_DIR="$(git rev-parse --show-toplevel)"
verbose=false
output_folder="${HOME_PATH}/create_directions/output" # by default, can be overwritten

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fcl-file)
            original_fcl="$2"
            shift
            shift
            ;;
        -n|--number-of-directions)
            number_of_directions="$2"
            shift
            shift
            ;;
        -o|--output)
            output_folder="$2"
            shift
            shift
            ;;
        -v|--verbose)
            verbose=true
            shift
            ;;
        -h|--help)
            print_help
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            ;;
    esac
done


# if no fcl file is provided, stop execution
if [[ -z "$original_fcl" ]]; then
    echo "No fcl file provided. Exiting..."
    exit 1
fi

# if the fcl file has the extension, remove it
if [[ "$original_fcl" == *".fcl" ]]; then
    original_fcl="${original_fcl%.*}"
fi

# if the file ends in _customDirection, remove this part
if [[ "$original_fcl" == *"_customDirection" ]]; then
    original_fcl="${original_fcl%_*}"
fi

# if no number of directions is provided, stop execution
if [[ -z "$number_of_directions" ]]; then
    echo "No number of directions provided. Exiting..."
    exit 1
fi

# generate the catalog of random directions
for i in $(seq 1 $number_of_directions); do

    command_to_run="sh ${HOME_DIR}/scripts/custom-direction.sh -f ${original_fcl}.fcl -o ${output_folder}"

    if [ "$verbose" = true ]; then
        echo "Generating direction $i..."
        command_to_run="${command_to_run} -v"
    fi
    
    eval ${command_to_run}

    mv ${output_folder}/${original_fcl}_customDirection.fcl ${output_folder}/${original_fcl}_customDirection_${i}.fcl
    mv ${output_folder}/customDirection.txt ${output_folder}/customDirection_${i}.txt
    
    echo "Direction $i generated. Files ${original_fcl}_customDirection_${i}.fcl and customDirection_${i}.txt created."
    echo ""
done

echo ""
echo "Catalog of $number_of_directions random directions generated."
echo "The files are in ${output_folder}."




