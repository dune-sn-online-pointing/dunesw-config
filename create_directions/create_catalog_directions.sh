#!/bin/bash

# This script generates a catalog of random directions for the neutrino SN explosion

function print_help() {
    echo "*****************************************************************************"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --fcl-file                Fcl file to start from"
    echo "  -v, --verbose                 Print verbose output of script that creates directions"
    echo "  -n, --number-of-directions    Number of directions to be generated"
    echo "  -h, --help                    Print this help message"
    echo "*****************************************************************************"
    exit 0
}

REPO_HOME='git rev-parse --show-toplevel'

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
    if [[ -n "$verbose" ]]; then
        echo "Generating direction $i..."
        . $REPO_HOME/scripts/custom-direction.sh -f $original_fcl -v
    fi
    else
        . $REPO_HOME/scripts/custom-direction.sh -f $original_fcl 
    fi
    mv ${original_fcl}_customDirection.fcl ${original_fcl}_customDirection_${i}.fcl
    mv customDirection.txt customDirection_${i}.txt
    
    echo "Direction $i generated. Files ${original_fcl}_customDirection_${i}.fcl and customDirection_${i}.txt created."
done

echo ""
echo "Catalog of $number_of_directions random directions generated."
echo "The files are in the current directory, that is $(pwd)."




