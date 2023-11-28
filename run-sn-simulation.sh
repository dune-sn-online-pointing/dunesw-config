#!/bin/bash

# Default values for simulation stages
run_marley=false
run_g4=false
run_detsim=false
run_reconstruction=false
source_flag=false  # Flag for -s option
source_dunesw="/afs/cern.ch/work/e/evilla/private/dune/dunesw/duneana-dev/source-dunesw.sh"
source_here="/afs/cern.ch/work/e/evilla/private/dune/dunesw/duneana-dev/source-here.sh"

# fcls
FCL_FOLDER="/afs/cern.ch/work/e/evilla/private/dune/dunesw/duneana-dev/fcl/"
OUTFOLDER_ENDING=""
GEN_FCL='prodmarley_nue_spectrum_radiological_decay0_dune10kt_refactored_1x2x6_modified'
# GEN_FCL='prodmarley_nue_flat_dune10kt_1x2x6_dump_modified'
G4_FCL='supernova_g4_dune10kt_1x2x6_modified'
DETSIM_FCL='DAQdetsim_v5' # get rid of modified
RECO_FCL='TPdump_standardHF_noiseless_labels'
number_events=1

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
    echo "  -s, --source           Source required scripts before execution. Not the best to do"
    echo "  -e, --ending           Ending of the file folder"
    echo "  -h, --help             Print this help message"
    echo "*****************************************************************************"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--marley)
            run_marley=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                GEN_FCL="$2"
                shift
            fi
            shift
            ;;
        -g|--g4)
            run_g4=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                G4_FCL="$2"
                shift
            fi
            shift
            ;;
        -d|--detsim)
            run_detsim=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                DETSIM_FCL="$2"
                shift
            fi
            shift
            ;;
        -r|--reconstruction)
            run_reconstruction=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                RECO_FCL="$2"
                shift
            fi
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
        -e|--ending)
            OUTFOLDER_ENDING="$2"
            shift 2
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

# if none of the run commands are true, stop script
if [ "$run_marley" = false ] && [ "$run_g4" = false ] && [ "$run_detsim" = false ] && [ "$run_reconstruction" = false ]; then
    echo "No simulation stage selected. "
    print_help
    exit 0
fi

# Default path for data
DATA_PATH="/eos/user/e/evilla/dune/sn-data/${GEN_FCL}-${RECO_FCL}-${number_events}events_${OUTFOLDER_ENDING}/"
mkdir -p "$DATA_PATH"
echo "We are in $(pwd)"
echo "Data will be saved in $DATA_PATH"


# Execute simulations based on options
if [ "$run_marley" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${GEN_FCL}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
    lar -c "${FCL_FOLDER}${GEN_FCL}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"
    echo "Marley generation done!"
    echo ""
fi

if [ "$run_g4" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${G4_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}.root -o ${DATA_PATH}${GEN_FCL}_g4.root"
    lar -c "${FCL_FOLDER}${G4_FCL}.fcl" -n "$number_events" -s "${DATA_PATH}${GEN_FCL}.root" -o "${DATA_PATH}${GEN_FCL}_g4.root"
    echo "Geant4 simulation done!"
    echo ""
fi

if [ "$run_detsim" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${DETSIM_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}_g4.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    lar -c "${FCL_FOLDER}${DETSIM_FCL}.fcl" -n "$number_events" -s "${DATA_PATH}${GEN_FCL}_g4.root" -o "${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    echo "Detector simulation done!"
    echo ""
fi

if [ "$run_reconstruction" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${RECO_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}_g4_detsim.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    lar -c "${FCL_FOLDER}${RECO_FCL}.fcl" -n "$number_events" -s "${DATA_PATH}${GEN_FCL}_g4_detsim.root" -o "${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    echo "Event reconstruction done!"
    echo ""
fi

# Sometimes there is this product, remove it
rm ./-_detsim_hist.root

# Move all products to the folder
mv *.root *.log *.txt "$DATA_PATH"

# Print the data path
echo "Data is in $DATA_PATH"
