#!/bin/bash

# it contains the fcls and the scripts that are called here
REPO_HOME="$(git rev-parse --show-toplevel)"
echo "REPO_HOME for script run-sn-simulation.sh: $REPO_HOME"
echo "When running in condor, this won't work. Use the --home-config flag to set the path to the dunesw-config folder"
# this script has to be run from the dunesw-config area 

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
delete_root_files=true
clean_folder=true

# fcls, just some casual defaults
GEN_FCL='prodmarley_nue_spectrum_clean_dune10kt_1x2x6_ES'
# GEN_FCL='prodmarley_nue_spectrum_radiological_decay0_dune10kt_refactored_1x2x6_ES_modifiedBkgRate' # just to not rerun
G4_FCL='supernova_g4_dune10kt_1x2x6_modified'
DETSIM_FCL='DAQdetsim_v5' 
RECO_FCL='TPdump_standardHF_noiseless_MCtruth'

# other params that is better to initialize
JSON_SETTINGS=""
OUTFOLDER_ENDING=""
number_events=1

# Function to source scripts and print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./run-sn-simulation.sh -j <yoursettings.json> [options]"
    echo "Options:"
    echo "  -j, --json-settings    JSON file with paths and settings. It has to be in the dunesw-config/json folder"
    echo "  --home-config          Path to the dunesw-config folder. Default is the current folder, but it won't work  in Condor"
    echo "  -m, --marley           Run Marley generation"
    echo "  --custom-direction Run Marley generation with custom random direction"
    echo "  --custom-energy        Run Marley generation with custom energy binning, requires two arguments (min and max)"
    echo "  -g, --g4               Run Geant4 simulation"
    echo "  -d, --detsim           Run detector simulation"
    echo "  -r, --reconstruction   Run event reconstruction"
    echo "  -n, --n-events         Number of events, default is 1"
    echo "  -s, --source           Parse to NOT source dunesw and local products"
    echo "  -f, --folder-ending    Ending of the name of the output folder"
    echo "  --clean-folder         Clean the folder after simulation. Default is true, set to false to keep it"
    echo "  --delete-root          Delete root files after simulation, to save space. Default is true, set to false to keep them"
    echo "  -h, --help             Print this help message"
    echo " "
    echo "Example: ./run-sn-simulation.sh -m myconfig.fcl --custom-energy 2 70 -g -d -r -s -n 1000 -f test --clean-folder false --delete-root false"
    echo "*****************************************************************************"
    exit 0
}


# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --home-config)
            REPO_HOME="$2"
            # if it has / at the end, remove it
            if [[ "$REPO_HOME" == */ ]]; then
                REPO_HOME="${REPO_HOME::-1}"
            fi
            shift 2
            ;;
        -j|--json-settings)
            JSON_SETTINGS="$2"
            shift 2
            ;;
        -m|--marley)
            run_marley=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                GEN_FCL="$2"
                # if it has the extension, remove it
                if [[ "$GEN_FCL" == *".fcl" ]]; then
                    GEN_FCL="${GEN_FCL%.*}"
                fi
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
                # if it has the extension, remove it
                if [[ "$G4_FCL" == *".fcl" ]]; then
                    G4_FCL="${G4_FCL%.*}"
                fi
                shift
            fi
            shift
            ;;
        -d|--detsim)
            run_detsim=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                DETSIM_FCL="$2"
                #if it has the extension, remove it
                if [[ "$DETSIM_FCL" == *".fcl" ]]; then
                    DETSIM_FCL="${DETSIM_FCL%.*}"
                fi
                shift
            fi
            shift
            ;;
        -r|--reconstruction)
            run_reconstruction=true
            # in case there is an argument, save it as the fcl
            if [[ "$2" != -* ]]; then
                RECO_FCL="$2"
                # if it has the extension, remove it
                if [[ "$RECO_FCL" == *".fcl" ]]; then
                    RECO_FCL="${RECO_FCL%.*}"
                fi
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
        --clean-folder)
            clean_folder="$2"
            shift 2
            ;;
        --delete-root)
            delete_root_files="$2"
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

# USER SPECIFIC
# If the JSON file is not provided, stop the script
if [ -z "$JSON_SETTINGS" ]; then
    echo "JSON file with paths and settings is required, give it through the flag -j. Exiting..."
    exit 1
fi

# in case this is a relative path, add path
if [[ "$JSON_SETTINGS" != /* ]]; then
    JSON_SETTINGS="${REPO_HOME}/json/${JSON_SETTINGS}"
    echo "JSON settings file is $JSON_SETTINGS"
fi

# If REPO_HOME is not set, stop the script
if [ -z "$REPO_HOME" ]; then
    echo "Path to the dunesw-config folder is required, give it through the flag --home-folder. Exiting..."
    exit 1
fi

FCL_FOLDER="$REPO_HOME/fcl/"

# Where the dunesw is installed
# DUNESW_FOLDER_NAME="$(awk -F'""' '/duneswInstallPath/{print $4}' "$JSON_SETTINGS")"
DUNESW_FOLDER_NAME=$(awk -F'[:,]' '/duneswInstallPath/ {gsub(/"| /, "", $2); print $2}' "$JSON_SETTINGS")

echo "Expecting the software to be in: $DUNESW_FOLDER_NAME"
setup_dunesw="${DUNESW_FOLDER_NAME}setup-dunesw.sh"        # put this file in the code folder, selecting the correct version
EOS_FOLDER="/eos/user/e/evilla/dune/sn-data/"       # standard, for now. Subfolders are selected automatically


# Source the required scripts for execution
if [ "$source_flag" = true ]; then
    echo 'Setting up dune software...'
    source $setup_dunesw
fi

# if none of the run commands are true, stop script
if [ "$run_marley" = false ] && [ "$run_g4" = false ] && [ "$run_detsim" = false ] && [ "$run_reconstruction" = false ]; then
    echo "No simulation stage selected. "
    print_help
    exit 0
fi

# Default path for data
GLOBAL_OUTPUT_FOLDER="${DUNESW_FOLDER_NAME}output/"
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

SIMULATION_NAME="${GEN_FCL_CHANGED}-${RECO_FCL}-${number_events}events"
DATA_PATH="${GLOBAL_OUTPUT_FOLDER}${SIMULATION_CATEGORY}/${SIMULATION_NAME}_${OUTFOLDER_ENDING}/"

# in case there is a previous one, clean it
if [ "$clean_folder" = true ]; then
    echo "Cleaning folder..."
    rm -rf "$DATA_PATH"
fi

# going here to generate the fcl files for custom E and/or direction
cd "$REPO_HOME"
echo "We are in $(pwd)"

# create output folder
mkdir -p "$DATA_PATH"
echo "Data will be saved in $DATA_PATH"

# If custom direction is selected, generate a random direction and create a new fcl file
if [ "$custom_direction" = true ] && [ "$custom_energy" = false ]; then
    # generate the direction and print it in the fcl and in a txt file
    . $REPO_HOME/scripts/custom-direction.sh -f "$GEN_FCL" -v -o "$DATA_PATH"
    echo " "
fi

# If custom energy is selected, generate energy bins and create a new fcl file
if [ "$custom_energy" = true ] && [ "$custom_direction" = false ]; then
    echo "Generating fcl file with custom energy range, $energy_min to $energy_max..."
    . $REPO_HOME/scripts/custom-energy.sh -f "$GEN_FCL" -m "$energy_min" -M "$energy_max" -v -o "$DATA_PATH"
    echo " "
fi

if [ "$custom_energy" = true ] && [ "$custom_direction" = true ]; then
    echo "Generating fcl file with custom energy range and direction..."
    . $REPO_HOME/scripts/custom-enAndDir.sh -f "$GEN_FCL" -m "$energy_min" -M "$energy_max" -v -o "$DATA_PATH"
    echo " "
fi


cd "$DATA_PATH"
echo "We are now in $(pwd)"
echo "Items here are $(ls)"

# copying the original gen fcl to the folder, it is used by the GEN_FCL_CHANGED
cp $REPO_HOME/fcl/${GEN_FCL}.fcl $DATA_PATH

start_time=$(date +%s)
echo "Starting simulation at $start_time"

# Execute simulations based on options TODO simplofy, always copy fcl at this point
if [ "$run_marley" = true ]; then
    echo "Executing command: lar -c ${DATA_PATH}${GEN_FCL_CHANGED}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
    lar -c "${DATA_PATH}${GEN_FCL_CHANGED}.fcl" -n "$number_events" -o "${DATA_PATH}${GEN_FCL}.root"

    # if returns 0, then it was successful
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
        if [ "$delete_root_files" = true ]; then
            rm "${DATA_PATH}${GEN_FCL}.root"
        fi
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
        if [ "$delete_root_files" = true ]; then
            rm "${DATA_PATH}${GEN_FCL}_g4.root"
        fi
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
        if [ "$delete_root_files" = true ]; then
            rm "${DATA_PATH}${GEN_FCL}_g4_detsim.root"
        fi
    else
        echo "Reconstruction failed. Exiting..."
        exit 1
    fi
fi


end_time=$(date  +%s)
echo "Ending simulation at $end_time"
exec_time=$(($end_time - $start_time))
echo "Simulation took $exec_time seconds"

# print to a file the time it took
echo "$exec_time" > "${DATA_PATH}execTime.txt"

echo "Currently in ${PWD}"
echo "Items here are $(ls)"
echo ""

# Delete root files
if [ "$delete_root_files" = true ]; then
    echo "Deleting root files to save memory..."    
    rm -f "${DATA_PATH}*.root"
    rm -f ./-_detsim_hist.root # Sometimes there is this product, remove it
fi

# Move all products to the folder
FINAL_FOLDER="${EOS_FOLDER}${SIMULATION_CATEGORY}/aggregated_${SIMULATION_NAME}_thr30/" # TODO grep threshold from somewhere
echo "Creating final folder $FINAL_FOLDER"
mkdir -p "$FINAL_FOLDER"

echo "Moving custom direction, TPs and waveforms to $FINAL_FOLDER"

if [ "$custom_direction" = true ]; then
    # move the custom direction file
    moving_custom_direction="mv ${DATA_PATH}customDirection.txt ${FINAL_FOLDER}customDirection_${OUTFOLDER_ENDING}.txt"
    echo "$moving_custom_direction"
    $moving_custom_direction
fi

TP_FILE="tpstream_standardHF_thresh30_nonoise_MCtruth.txt" # TODO make this absolute or grep it
moving_tps="mv ${DATA_PATH}${TP_FILE} ${FINAL_FOLDER}tpstream_${OUTFOLDER_ENDING}.txt"
echo "$moving_tps"
$moving_tps

WF_FILE="waveforms.txt" # set in the TPStreamer module
moving_waveforms="mv ${DATA_PATH}${WF_FILE} ${FINAL_FOLDER}waveforms_${OUTFOLDER_ENDING}.txt"
echo "$moving_waveforms"
$moving_waveforms

if [ "$clean_folder" = true ]; then
    echo "Cleaning folder..."
    rm -r "$DATA_PATH"
fi

# Print the data path
echo "If it has not been cleaned, all products are in $DATA_PATH"
echo "TPs and waveforms are in $FINAL_FOLDER"
