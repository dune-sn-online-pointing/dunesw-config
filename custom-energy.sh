#!/bin/bash

# This script overwrites the energy range in the gen fcl file to a custom one

# default values
min_energy=2
max_energy=70

# print help
function print_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --fcl-file                Fcl file to be modified, only name of the file"
    echo "  -m, --min-energy              Minimum energy for the neutrino"
    echo "  -M, --max-energy              Maximum energy for the neutrino"
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

# if no fcl file is provided, stop execution
if [[ -z "$original_fcl" ]]; then
    echo "No fcl file provided. Exiting..."
    exit 1
fi

# if the fcl name does not contain "flat", stop execution
if [[ "$original_fcl" != *"flat"* ]]; then
    echo "The fcl file provided does not contain 'flat', for the moment this works only on flat distributions. Exiting..."
    exit 1
fi

# if no custom energy is provided, continue with warning
if [[ "$min_energy" -eq 2 || "$max_energy" -eq 70 ]]; then
    echo "No custom energy provided. Using default energy range: $min_energy - $max_energy MeV"
fi

# if the custom energy is not within the range, stop execution
if [[ "$min_energy" -lt 2 || "$max_energy" -gt 70 ]]; then
    echo "The custom energy range is not within the range of 2 - 70 MeV. Exiting..."
    exit 1
fi

# if min is equal or greater than max, stop execution
if [[ "$min_energy" -ge "$max_energy" ]]; then
    echo "The minimum energy is equal or greater than the maximum energy. Exiting..."
    exit 1
fi


# Create the .fcl file with the random values, adding a suffix and .fcl to original_fcl
# move that file to here just to avoid parsing problems
cp /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/fcl/${original_fcl}.fcl .
filename="${original_fcl%.*}_customEnergy.fcl"
cat <<EOF > $filename
#include "${original_fcl}.fcl"

physics: {
    producers: {
        marley: {
            marley_parameters: {
                direction: {
                    x: 0
                    y: 0
                    z: 1
                }
                source: {
                E_bin_lefts: [
                  4
                ]
                Emax: $max_energy
                Emin: $min_energy
                neutrino: "ve"
                type: "histogram"
                weight_flux: false
                weights: [
                    1
                ]
            }
            }
        }
    }
}
EOF

echo "Generated file: $filename"
