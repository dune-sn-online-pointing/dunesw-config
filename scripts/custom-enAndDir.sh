#!/bin/bash

# This script generates a random direction for the neutrino SN explosion
# and overwrites the energy range in the gen fcl file to a custom one

# this script is meant to be run from inside the dunesw-config repository
# or git might have problems
REPO_HOME="$(git rev-parse --show-toplevel)"
# catch errors and say that the script must be run from its location
echo "If you see a git error, it is because the script must be run from inside the dunesw-config repository."

# Default values
min_energy=2
max_energy=70
original_fcl=""
x=""
y=""
z=""

# Function to print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --fcl-file       Fcl file to be modified"
    echo "  -m, --min-energy     Minimum energy for the neutrino"
    echo "  -M, --max-energy     Maximum energy for the neutrino"
    echo "  -o, --output         Output folder for the fcl file"
    echo "  -v, --verbose        Print verbose output" 
    echo "  -h, --help           Print this help message"
    echo "*****************************************************************************"
    exit 0
}

verbose=false
output_folder="./" # by default, here

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fcl-file) original_fcl="$2"; shift; shift;; 
        -m|--min-energy) min_energy="$2"; shift; shift;; 
        -M|--max-energy) max_energy="$2"; shift; shift;; 
        -o|--output) output_folder="$2"; shift; shift;; 
        -v|--verbose) verbose=true; shift;; 
        -h|--help) print_help;; 
        *) echo "Unknown option: $1"; print_help;;
    esac
done

if [[ "$verbose" == "true" ]]; then
    echo "REPO_HOME for script custom-enAndDir.sh: $REPO_HOME"
fi

# If no fcl file is provided, stop execution
if [[ -z "$original_fcl" ]]; then
    echo "No fcl file provided. Exiting..."
    print_help
    exit 1
fi

# If the fcl file has the extension, remove it
if [[ "$original_fcl" == *".fcl" ]]; then
    original_fcl="${original_fcl%.*}"
fi

# Check if the fcl name contains "flat"
if [[ "$original_fcl" != *"flat"* ]]; then
    echo "The fcl file provided does not contain 'flat', for the moment this works only on flat distributions. Exiting..."
    exit 1
fi

# if output folder does not finish with /, add it
if [[ ! -z "$output_folder" ]]; then
    if [[ "$output_folder" != */ ]]; then
        output_folder="${output_folder}/"
    fi
fi

# Generate random direction
echo "Generating random direction, all three directions..."
direction=$(python3 $REPO_HOME/scripts/generate_direction.py)
x=$(echo $direction | awk '{print $1}')
y=$(echo $direction | awk '{print $2}')
z=$(echo $direction | awk '{print $3}')

if [[ "$verbose" == true ]]; then
    echo "Generated random direction: x=$x, y=$y, z=$z"
fi


# print this in a text file, but delete it first in case it already exists
rm -f ${output_folder}customDirection.txt
echo "$x" >> customDirection.txt
echo "$y" >> customDirection.txt
echo "$z" >> customDirection.txt 

# Generate custom energy range
echo "Generating fcl with custom energy range: $min_energy to $max_energy MeV"

# Create the .fcl file with the random values
filename="${output_folder}${original_fcl%.*}_${min_energy}to${max_energy}MeV_customDirection.fcl"
cat <<EOF > $filename
#include "${original_fcl}.fcl"

physics.producers.marley.marley_parameters.direction.x: $x
physics.producers.marley.marley_parameters.direction.y: $y
physics.producers.marley.marley_parameters.direction.z: $z

physics.producers.marley.marley_parameters.source.Emin: $min_energy
physics.producers.marley.marley_parameters.source.Emax: $max_energy

source.maxEvents: -1

EOF

if [[ "$verbose" == true ]]; then
    echo "Generated file: $filename"
fi