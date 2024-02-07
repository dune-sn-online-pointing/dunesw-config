#!/bin/bash

# This script generates a random direction for the neutrino SN explosion

function print_help() {
    echo "*****************************************************************************"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --fcl-file                Fcl file to be modified"
    echo "  -h, --help                    Print this help message"
    echo "*****************************************************************************"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fcl-file)
            original_fcl="$2"
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

# sample theta and phi from a uniform distribution, using generate_theta.py
echo "Generating random theta and phi..."
x=$(python3 /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/generate_direction.py | head -n 1)
y=$(python3 /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/generate_direction.py | tail -n +2 | head -n -1 | tail -n 1)
z=$(python3 /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/generate_direction.py | tail -n 1)

echo "Generated random direction..."
echo "x: $x"
echo "y: $y"
echo "z: $z"

# Create the .fcl file with the random values, adding a suffix and .fcl to original_fcl
# move that file to here just to avoid parsing problems
cp /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/fcl/${original_fcl}.fcl .
filename="${original_fcl%.*}_customDirection.fcl"
cat <<EOF > $filename
#include "${original_fcl}.fcl"


physics.producers.marley.marley_parameters.direction.x: $x
physics.producers.marley.marley_parameters.direction.y: $y
physics.producers.marley.marley_parameters.direction.z: $z

EOF

echo "Generated file: $filename"
