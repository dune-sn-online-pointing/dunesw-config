#!/bin/bash

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
    echo "  -h, --help           Print this help message"
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
        -m|--min-energy)
            min_energy="$2"
            shift
            shift
            ;;
        -M|--max-energy)
            max_energy="$2"
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

# Generate random direction
echo "Generating random direction, all three directions..."
direction=$(python3 /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/generate_direction.py)
x=$(echo $direction | awk '{print $1}')
y=$(echo $direction | awk '{print $2}')
z=$(echo $direction | awk '{print $3}')

echo "Generated random direction: x=$x, y=$y, z=$z"

# print this in a text file, but delete it first in case it already exists
rm customDirection.txt
echo "$x" >> customDirection.txt
echo "$y" >> customDirection.txt
echo "$z" >> customDirection.txt 

# Generate custom energy range
echo "Generating custom energy range: $min_energy to $max_energy MeV"

# Create the .fcl file with the random values
cp /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/fcl/${original_fcl}.fcl .
filename="${original_fcl%.*}_${min_energy}to${max_energy}MeV_customDirection.fcl"
cat <<EOF > $filename
#include "${original_fcl}.fcl"

physics.producers.marley.marley_parameters.direction.x: $x
physics.producers.marley.marley_parameters.direction.y: $y
physics.producers.marley.marley_parameters.direction.z: $z

physics.producers.marley.marley_parameters.source.Emin: $min_energy
physics.producers.marley.marley_parameters.source.Emax: $max_energy

EOF

echo "Generated file: $filename"
