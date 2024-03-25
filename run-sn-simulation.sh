#!/bin/bash

# Default values for simulation stages
run_marley=false
custom_direction=false
custom_energy=false
energy_min=0
energy_max=0
run_g4=false
run_detsim=false
run_reconstruction=false
source_flag=true  # Flag for -s option
source_dune="/afs/cern.ch/work/e/evilla/private/dune/dunesw/source-dune.sh"
setup_dune="/afs/cern.ch/work/e/evilla/private/dune/dunesw/setup-v79.sh"

# source_here="/afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/source-here.sh"
code_folder="verbose-dev" # WHEN CHANGING, MODIFY

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
    echo "  --custom-direction Run Marley generation with custom random direction"
    echo "  --custom-energy        Run Marley generation with custom energy binning"
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
        --custom-direction)
            custom_direction=true
            shift
            ;;
        --custom-energy)
            custom_energy=true
            # this has to have two arguments after it, the minimum and maximum energy
            energy_min="$2"
            energy_max="$3"
            # if they are not numbers, stop the script
            if ! [[ "$energy_min" =~ ^[0-9]+$ ]] || ! [[ "$energy_max" =~ ^[0-9]+$ ]]; then
                echo "Energy range must be two numbers. Exiting..."
                exit 1
            fi
            shift 3
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
FOLDER_PATH="/afs/cern.ch/work/e/evilla/private/dune/dunesw/verbose-dev/output/"
SIMULATION_CATEGORY="standard"
GEN_FCL_CHANGED=$GEN_FCL # default value, will be changed if custom direction or energy is selected
if [ "$custom_direction" = true ] && [ "$custom_energy" = false ]; then
    SIMULATION_CATEGORY="directions"
    GEN_FCL_CHANGED="${GEN_FCL}_customDirection"
elif [ "$custom_energy" = true ] && [ "$custom_direction" = false ]; then
    SIMULATION_CATEGORY="energies"
    GEN_FCL_CHANGED="${GEN_FCL}_${energy_min}to${energy_max}MeV"
elif [ "$custom_energy" = true ] && [ "$custom_direction" = true ]; then
    SIMULATION_CATEGORY="customEandD"
    GEN_FCL_CHANGED="${GEN_FCL}_${energy_min}to${energy_max}MeV_customDirection"
fi
# if two change at the same time, decide what to do

SIMULATION_NAME="${GEN_FCL_CHANGED}-${RECO_FCL}-${number_events}events"
DATA_PATH="${FOLDER_PATH}${SIMULATION_CATEGORY}/${SIMULATION_NAME}_${OUTFOLDER_ENDING}/"

mkdir -p "$DATA_PATH"
echo "We are in $(pwd)"
echo "Data will be saved in $DATA_PATH"
cd "$DATA_PATH"
echo "We are now in $(pwd)"

# If custom direction is selected, generate a random direction and create a new fcl file
if [ "$custom_direction" = true ] && [ "$custom_energy" = false ]; then
    . /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/custom-direction.sh -f "$GEN_FCL"
    echo "In this folder now we have"
    echo "$(ll)"
    echo " "
fi

# If custom energy is selected, generate energy bins and create a new fcl file
if [ "$custom_energy" = true ] && [ "$custom_direction" = false ]; then
    echo "Generating fcl file with custom energy range, $energy_min to $energy_max..."
    . /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/custom-energy.sh -f "$GEN_FCL" -m "$energy_min" -M "$energy_max"
    echo "In this folder now we have"
    echo "$(ll)"
    echo " "
fi

if [ "$custom_energy" = true ] && [ "$custom_direction" = true ]; then
    echo "Generating fcl file with custom energy range and direction..."
    . /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/custom-enAndDir.sh -f "$GEN_FCL" -m "$energy_min" -M "$energy_max"
    echo "In this folder now we have"
    echo "$(ls)"
    echo " "
fi

# Execute simulations based on options TODO simplofy, always copy fcl at this point
if [ "$run_marley" = true ]; then
    if [ "$custom_direction" = true ] ||  [ "$custom_energy" = true ]; then
        # in this case the fcl will be in this folder
        echo "Executing command: lar -c ${DATA_PATH}${GEN_FCL_CHANGED}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
        lar -c "${DATA_PATH}${GEN_FCL_CHANGED}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"
    else   
        # in this case the fcl will be in the fcl folder
        echo "Executing command: lar -c ${FCL_FOLDER}${GEN_FCL_CHANGED}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
        lar -c "${FCL_FOLDER}${GEN_FCL_CHANGED}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"
    fi

    if [ $? -eq 0 ]; then
        echo "Marley generation done!"
        echo ""
        echo "In the folder now we have"
        echo "$(ls)"
        echo " "
    else
        echo "Marley generation failed. Exiting..."
        exit 1
    fi
fi

if [ "$run_g4" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${G4_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}.root -o ${DATA_PATH}${GEN_FCL}_g4.root"
    lar -c "${FCL_FOLDER}${G4_FCL}.fcl" -n "$number_events" -s "${DATA_PATH}${GEN_FCL}.root" -o "${DATA_PATH}${GEN_FCL}_g4.root"
    # if returns 0, then it was successful
    if [ $? -eq 0 ]; then
        echo "Geant4 simulation done!"
        echo ""
        # remove the root file to save memory
        rm "${DATA_PATH}${GEN_FCL}.root"
    else
        echo "Geant4 simulation failed. Exiting..."
        exit 1
    fi
    echo ""
fi

if [ "$run_detsim" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${DETSIM_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}_g4.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    lar -c "${FCL_FOLDER}${DETSIM_FCL}.fcl" -n "$number_events" -s "${DATA_PATH}${GEN_FCL}_g4.root" -o "${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    if [ $? -eq 0 ]; then
        echo "Detector simulation done!"
        echo ""
        echo "In the folder now we have"
        echo "$(ls)"
        echo " "
        # remove the root file to save memory
        rm "${DATA_PATH}${GEN_FCL}_g4.root"
    else
        echo "Detector simulation failed. Exiting..."
        exit 1
    fi
fi

if [ "$run_reconstruction" = true ]; then
    echo "Executing command: lar -c ${FCL_FOLDER}${RECO_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}_g4_detsim.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    lar -c "${FCL_FOLDER}${RECO_FCL}.fcl" -n "$number_events" -s "${DATA_PATH}${GEN_FCL}_g4_detsim.root" -o "${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    if [ $? -eq 0 ]; then
        echo "Reconstruction done!"
        echo ""
        echo "In the folder now we have"
        echo "$(ls)"
        echo " "
        # remove the root file to save memory
        rm "${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    else
        echo "Reconstruction failed. Exiting..."
        exit 1
    fi
fi

# cd "/afs/cern.ch/work/e/evilla/private/dune/dunesw/${code_folder}/"
echo "Currently in ${PWD}"
echo "Items here are $(ls)"
# Delete root files
echo "Deleting root files to save memory..."
# Sometimes there is this product, remove it
rm ./-_detsim_hist.root
rm ${DATA_PATH}*.root # uncomment to reduce memory occupancy

# Move all products to the folder
EOS_FOLDER="/eos/user/e/evilla/dune/sn-data/"
FINAL_FOLDER="${EOS_FOLDER}${SIMULATION_CATEGORY}/${SIMULATION_NAME}_thr30/" # TODO grep from somewhere
mkdir -p "$FINAL_FOLDER"

echo "Moving custom direction and TPs to $FINAL_FOLDER"

if [ "$custom_direction" = true ]; then
    # move the custom direction file
    moving_custom_direction="mv ${DATA_PATH}customDirection.txt ${FINAL_FOLDER}customDirection_${OUTFOLDER_ENDING}.txt"
    echo "$moving_custom_direction"
    $moving_custom_direction
fi

TPFILE_NAME="tpstream_standardHF_thresh30_nonoise_MCtruth.txt" # TODO make this absolute or grep it
moving_tps="mv ${DATA_PATH}${TPFILE_NAME} ${FINAL_FOLDER}tpstream_${OUTFOLDER_ENDING}.txt"
echo "$moving_tps"
$moving_tps

# Print the data path
echo "Data is in $FINAL_FOLDER"
