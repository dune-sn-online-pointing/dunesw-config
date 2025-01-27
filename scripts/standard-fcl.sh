#!/bin/bash

# This script just updates the maxEvents variable and creates a new fcl file

# this script is meant to be run from inside the dunesw-config repository
# or git might have problems
REPO_HOME="$(git rev-parse --show-toplevel)"
# catch errors and say that the script must be run from its location
echo "If you see a git error, it is because the script must be run from inside the dunesw-config repository."

function print_help() {
    echo "*****************************************************************************"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --fcl-file                Fcl file to be modified"
    echo "  -v, --verbose                 Print verbose output"
    echo "  -o, --output                  Output folder for the fcl file"
    echo "  -h, --help                    Print this help message"
    echo "*****************************************************************************"
    exit 0
}

verbose=false
output_folder="./" # by default, here

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fcl-file) original_fcl="$2"; shift; shift ;; 
        -v|--verbose) verbose=true; shift ;; 
        -o|--output) output_folder="$2"; shift; shift ;; 
        -h|--help) print_help ;; 
        *) echo "Unknown option: $1"; print_help ;;
    esac
done

if [[ "$verbose" == "true" ]]; then
    echo "REPO_HOME for script custom-enAndDir.sh: $REPO_HOME"
fi

# if no fcl file is provided, stop execution
if [[ -z "$original_fcl" ]]; then
    echo "No fcl file provided. Exiting..."
    exit 1
fi

# if the fcl file has the extension, remove it
if [[ "$original_fcl" == *".fcl" ]]; then
    original_fcl="${original_fcl%.*}"
fi

# if output folder does not finish with /, add it
if [[ ! -z "$output_folder" ]]; then
    if [[ "$output_folder" != */ ]]; then
        output_folder="${output_folder}/"
    fi
fi

# Create the .fcl file with the random values, adding a suffix and .fcl to original_fcl
filename="${output_folder}${original_fcl}_standard.fcl"
cat <<EOF > $filename
#include "${original_fcl}.fcl"

source.maxEvents: -1

EOF

if [[ "$verbose" == true ]]; then
    echo "Generated file: $filename"
fi