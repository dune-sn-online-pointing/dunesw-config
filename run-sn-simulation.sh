#!/bin/bash

# Default values for simulation stages
run_marley=false
custom_direction=false
custom_energy=false
run_g4=false
run_detsim=false
run_reconstruction=false
source_flag=true  # Flag for -s option
source_dune="/afs/cern.ch/work/e/evilla/private/dune/dunesw/source-dune.sh"
setup_dune="/afs/cern.ch/work/e/evilla/private/dune/dunesw/setup-v79.sh"

# source_here="/afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/source-here.sh"
code_folder="verbose-dev" # WHEN CHANGING, MODIFY
running_folder=$PWD

# fcls
FCL_FOLDER="/afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/fcl/"
#GEN_FCL='prodmarley_nue_spectrum_radiological_decay0_dune10kt_refactored_1x2x6_CC'
# GEN_FCL='prodmarley_nue_flat_dune10kt_1x2x6_dump_modified'
GEN_FCL='prodmarley_nue_spectrum_clean_dune10kt_1x2x6_CC'
G4_FCL='supernova_g4_dune10kt_1x2x6_modified'
DETSIM_FCL='DAQdetsim_v5' # get rid of modified
RECO_FCL='TPdump_standardHF_noiseless_MCtruth'

# other params
OUTFOLDER_ENDING=""
number_events=1

# Function to source scripts and print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./run-sn-simulation.sh [options]"
    echo "Options:"
    echo "  -m, --marley           Run Marley generation"
    echo "  -c, --custom-direction Run Marley generation with custom random direction"
    echo "  -e, --custom-energy    Run Marley generation with custom energy binning"
    echo "  -g, --g4               Run Geant4 simulation"
    echo "  -d, --detsim           Run detector simulation"
    echo "  -r, --reconstruction   Run event reconstruction"
    echo "  -n, --n-events         Number of events"
    echo "  -s, --source           Parse to NOT source dunesw and local products"
    echo "  -f, --folder-ending           Ending of the file folder"
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
        -c|--custom-direction)
            custom_direction=true
            shift
            ;;
        -e|--custom-energy)
            custom_energy=true
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
            source_flag=false
            shift
            ;;
        -f|--folder-ending)
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

# Source the required scripts for execution
if [ "$source_flag" = true ]; then
    source "$source_dune"
    source /afs/cern.ch/work/e/evilla/private/dune/dunesw/${code_folder}/localProducts_larsoft_v09_79_00d02_prof_e26/setup
    cd $MRB_BUILDDIR
    mrbslp
    source "$setup_dune"
    cd .. # go back to code_folder to run, output will temporarily be there
fi

# if none of the run commands are true, stop script
if [ "$run_marley" = false ] && [ "$run_g4" = false ] && [ "$run_detsim" = false ] && [ "$run_reconstruction" = false ]; then
    echo "No simulation stage selected. "
    print_help
    exit 0
fi

# Default path for data
DATA_PATH="/eos/user/e/evilla/dune/sn-data/standard/${GEN_FCL}-${RECO_FCL}-${number_events}events_${OUTFOLDER_ENDING}/"
# If custom direction is selected, change the path and use folder directions/
if [ "$custom_direction" = true ]; then
    echo "Custom direction selected, results will be under directions/ folder"
    DATA_PATH="/eos/user/e/evilla/dune/sn-data/directions/${GEN_FCL}_customDirection-${RECO_FCL}-${number_events}events_${OUTFOLDER_ENDING}/"
fi
# If custom energy is selected, change the path and use folder energies/
if [ "$custom_energy" = true ]; then
    echo "Custom energy selected, results will be under energies/ folder"
    DATA_PATH="/eos/user/e/evilla/dune/sn-data/energies/${GEN_FCL}_customEnergy-${RECO_FCL}-${number_events}events_${OUTFOLDER_ENDING}/"
fi
# if two change at the same time, decide what to do

mkdir -p "$DATA_PATH"
echo "We are in $(pwd)"
echo "Data will be saved in $DATA_PATH"
cd "$DATA_PATH"
echo "We are now in $(pwd)"

# If custom direction is selected, generate a random direction and create a new fcl file
if [ "$custom_direction" = true ]; then
    . /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/custom-direction.sh "$GEN_FCL"
    echo "In this folder now we have"
    echo "$(ls)"
    echo " "
fi

# Execute simulations based on options
if [ "$run_marley" = true ]; then
    if [ "$custom_direction" = true ]; then
        # in this case the fcl will be in this folder
        echo "Executing command: lar -c ${DATA_PATH}${GEN_FCL}_customDirection.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
        lar -c "${DATA_PATH}${GEN_FCL}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"
    else    
        # in this case the fcl will be in the fcl folder
        echo "Executing command: lar -c ${FCL_FOLDER}${GEN_FCL}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
        lar -c "${FCL_FOLDER}${GEN_FCL}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"
    fi
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

# cd "/afs/cern.ch/work/e/evilla/private/dune/dunesw/${code_folder}/"
echo "Currently in ${PWD}"
echo "Items here are $(ls)"

# Sometimes there is this product, remove it
# rm ./-_detsim_hist.root

# Move all products to the folder
# mv *.log *.txt "$DATA_PATH"

# Delete root files
echo "Deleting root files to save memory..."
rm $DATA_PATH*.root # uncomment to reduce memory occupancy

# Print the data path
echo "Data is in $DATA_PATH"
