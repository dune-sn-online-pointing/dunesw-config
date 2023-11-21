#!/bin/bash

# Default values for simulation stages
run_marley=false
run_g4=false
run_detsim=false
run_reconstruction=false
source_flag=false  # Flag for -s option
source_dunesw="/afs/cern.ch/work/e/evilla/private/dune/dunesw/duneana-dev/source-dunesw.sh"
source_here="/afs/cern.ch/work/e/evilla/private/dune/dunesw/duneana-dev/source-here.sh"

GEN_FCL='prodmarley_nue_spectrum_radiological_decay0_dune10kt_refactored_1x2x6_modified'
# GEN_FCL='prodmarley_nue_flat_dune10kt_1x2x6_dump_modified'
G4_FCL='supernova_g4_dune10kt_1x2x6_modified'
DETSIM_FCL='DAQdetsim_v5'
RECO_FCL='TPdump_standardHF_noiseless_fixed'
number_events=2


# Function to source scripts and print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./run-sn-simulation.sh [options]"
    echo "Options:"
    echo "  -m, --marley           Run Marley generation"
    echo "  -g, --g4               Run Geant4 simulation"
    echo "  -d, --detsim           Run detector simulation"
    echo "  -r, --reconstruction   Run event reconstruction"
    echo "  -n, --n-events         Number of events"
    echo "  -s, --source           Source required scripts before execution"
    echo "  -h, --help             Print this help message"
    echo "*****************************************************************************"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--marley)
            run_marley=true
            shift
            ;;
        -g|--g4)
            run_g4=true
            shift
            ;;
        -d|--detsim)
            run_detsim=true
            shift
            ;;
        -r|--reconstruction)
            run_reconstruction=true
            shift
            ;;
        -n|--n-events)
            number_events="$2"
            shift 2
            ;;
        -s|--source)
            source_flag=true
            shift
            ;;
        -h|--help)
            print_help
            ;;
        *)
            shift
            ;;
    esac
done

# Source the required scripts if -s flag is parsed
if [ "$source_flag" = true ]; then
    source "$source_dunesw"
    source "$source_here"
fi

# Default path for data
DATA_PATH="/eos/user/e/evilla/dune/sn-data/${GEN_FCL}-${RECO_FCL}-${number_events}events/"
mkdir -p "$DATA_PATH"
echo "Data will be saved in $DATA_PATH"


# Execute simulations based on options
if [ "$run_marley" = true ]; then
    echo "Executing command: lar -c ${GEN_FCL}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
    lar -c "fcl/${GEN_FCL}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"
    echo "Marley generation done!"
    echo ""
fi

if [ "$run_g4" = true ]; then
    echo "Executing command: lar -c ${G4_FCL}.fcl -s ${DATA_PATH}${GEN_FCL}.root -o ${DATA_PATH}${GEN_FCL}_g4.root"
    lar -c "fcl/${G4_FCL}.fcl" -s "${DATA_PATH}${GEN_FCL}.root" -o "${DATA_PATH}${GEN_FCL}_g4.root"
    echo "Geant4 simulation done!"
    echo ""
fi

if [ "$run_detsim" = true ]; then
    echo "Executing command: lar -c ${DETSIM_FCL}.fcl -s ${DATA_PATH}${GEN_FCL}_g4.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    lar -c "fcl/${DETSIM_FCL}.fcl" -s "${DATA_PATH}${GEN_FCL}_g4.root" -o "${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    echo "Detector simulation done!"
    echo ""
fi

if [ "$run_reconstruction" = true ]; then
    echo "Executing command: lar -c ${RECO_FCL}.fcl -s ${DATA_PATH}${GEN_FCL}_g4_detsim.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    lar -c "fcl/${RECO_FCL}.fcl" -s "${DATA_PATH}${GEN_FCL}_g4_detsim.root" -o "${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    echo "Event reconstruction done!"
    echo ""
fi

# Sometimes there is this product, remove it
rm ./-_detsim_hist.root

# Move all products to the folder
mv *.root *.log *.txt "$DATA_PATH"

# Print the data path
echo "Data is in $DATA_PATH"
