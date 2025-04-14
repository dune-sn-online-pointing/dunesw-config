#!/bin/bash

# Initialize env variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
source $SCRIPT_DIR/init.sh

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
delete_root_files=false
clean_folder=false

# fcls, just some casual defaults
GEN_FCL='prodmarley_nue_spectrum_dune10kt_1x2x2'
# GEN_FCL='prodmarley_nue_spectrum_radiological_decay0_dune10kt_1x2x2' 
G4_FCL='supernova_g4_dune10kt_1x2x2'
DETSIM_FCL='detsim_dune10kt_1x2x2_notpcsigproc'   # check noise
RECO_FCL='triggerana_tree_1x2x2_simpleThr_simpleWin_simpleWin'       

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
    echo "  -m, --marley           Run Generation, historically marley  but can be anything"
    echo "  -M, --Marley           Parse gen fcl, without (re)running this step"
    echo "  --custom-direction Run Generation with custom random direction"
    echo "  --custom-energy        Run Generation with custom energy binning, requires two arguments (min and max)"
    echo "  -g, --g4               Run Geant4 simulation"
    echo "  -G, --G4               Parse g4 fcl, without (re)running this step"
    echo "  -d, --detsim           Run detector simulation"
    echo "  -D, --Detsim           Parse detsim fcl, without (re)running this step"
    echo "  -r, --reconstruction   Run event reconstruction"
    echo "  -R, --Reconstruction   Parse reco fcl, without (re)running this step"
    echo "  -n, --n-events         Number of events, default is 1"
    echo "  -s, --source           Parse to NOT source dunesw and local products"
    echo "  -f, --folder-ending    Ending of the name of the output folder"
    echo "  --clean-folder         Clean the folder after simulation. Default is false"
    echo "  --delete-root          Delete root files after simulation, to save space. Default is false"
    echo "  -h, --help             Print this help message"
    echo " "
    echo "Example: ./$1 -j settings.json -m myconfig.fcl --custom-energy 2 70 -g -d -r -s -n 1000 -f test --clean-folder false --delete-root false"
    echo "*****************************************************************************"
    exit 0
}


# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --home-config)       REPO_HOME="${2%/}"; shift 2 ;;
        -j|--json-settings)  JSON_SETTINGS="$2"; shift 2 ;;
        -m|--marley)         run_marley=true; [[ "$2" != -* ]] && GEN_FCL="${2%.fcl}" && shift; shift ;;
        -M|--Marley)         GEN_FCL="${2%.fcl}"; shift 2 ;;
        --custom-direction)  custom_direction=true; shift ;;
        --custom-energy)     custom_energy=true; 
                                energy_min="$2"; 
                                energy_max="$3"; 
                                [[ ! "$energy_min" =~ ^[0-9]+$ || ! "$energy_max" =~ ^[0-9]+$ ]] && echo "Energy range must be two numbers. Exiting..." && exit 1; 
                                shift 3 ;;
        -g|--g4)             run_g4=true; [[ "$2" != -* ]] && G4_FCL="${2%.fcl}" && shift; shift ;;
        -G|--G4)             G4_FCL="${2%.fcl}"; shift 2 ;;
        -d|--detsim)         run_detsim=true; [[ "$2" != -* ]] && DETSIM_FCL="${2%.fcl}" && shift; shift ;;
        -D|--Detsim)         DETSIM_FCL="${2%.fcl}"; shift 2 ;;
        -r|--reconstruction) run_reconstruction=true; [[ "$2" != -* ]] && RECO_FCL="${2%.fcl}" && shift; shift ;;
        -R|--Reconstruction) RECO_FCL="${2%.fcl}"; shift 2 ;;
        -n|--n-events)       number_events="$2"; shift 2 ;;
        -s|--source)         source_flag=false; shift ;;
        -f|--folder-ending)  OUTFOLDER_ENDING="$2"; shift 2 ;;
        --clean-folder)      clean_folder="$2"; shift 2 ;;
        --delete-root)       delete_root_files="$2"; shift 2 ;;
        -h|--help)           print_help ;;
        *) shift ;;
    esac
done

echo "Looking for settings file $JSON_SETTINGS. If execution stops, it means that the file was not found."
findSettings_command="$SCRIPT_DIR/findSettings.sh -s $JSON_SETTINGS"
# last line of the output of findSettings.sh is the full path of the settings file
JSON_SETTINGS=$( $findSettings_command | tail -n 1)
echo -e "Settings file found, full path is: $JSON_SETTINGS \n"

# If REPO_HOME is not set, stop the script
if [ -z "$REPO_HOME" ]; then
    echo "Path to the dunesw-config folder is required, give it through the flag --home-folder. Exiting..."
    exit 1
fi

# Where the dunesw is installed
export DUNESW_VERSION=$(awk -F'[:,]' '/duneswVersion/ {gsub(/"| /, "", $2); print $2}' "$JSON_SETTINGS")
export DUNESW_FOLDER_NAME=$(awk -F'[:,]' '/duneswInstallPath/ {gsub(/"| /, "", $2); print $2}' "$JSON_SETTINGS")
echo "Setting up dunesw version $DUNESW_VERSION"
echo "Expecting the software to be in: $DUNESW_FOLDER_NAME. (If empty, no local products are sourced)"
setup_dunesw="${REPO_HOME}/scripts/setup_dunesw.sh" 

# Source the required scripts for execution
if [ "$source_flag" = true ]; then
    # extract dunesw version from filename, it assumes there is a local install
    # and the location is the one in the json file
    source $setup_dunesw $DUNESW_VERSION
fi

# Add flux files to the path
export FW_SEARCH_PATH=$FW_SEARCH_PATH:"$DAT_DIR"

# if none of the run commands are true, stop script
if [ "$run_marley" = false ] && [ "$run_g4" = false ] && [ "$run_detsim" = false ] && [ "$run_reconstruction" = false ]; then
    echo "No simulation stage selected. "
    print_help
    exit 0
fi

# Default path for data
if [ -n "$DUNESW_FOLDER_NAME" ]; then
    GLOBAL_OUTPUT_FOLDER="${DUNESW_FOLDER_NAME}output/"
else
    GLOBAL_OUTPUT_FOLDER="$(cd "$REPO_HOME/.." && pwd)/${DUNESW_VERSION}/output/"
fi
echo "Output folder is $GLOBAL_OUTPUT_FOLDER, creating it in case it does not exist"
mkdir -p "$GLOBAL_OUTPUT_FOLDER"

GEN_FCL_CHANGED=$GEN_FCL # default value, but will always be changed 
if [ "$custom_direction" = false ] && [ "$custom_energy" = false ]; then
    SIMULATION_CATEGORY="standard"
    GEN_FCL_CHANGED="${GEN_FCL}_standard"
elif [ "$custom_direction" = true ] && [ "$custom_energy" = false ]; then
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
FCL_FOLDER="$REPO_HOME/fcl/" 

export FHICL_FILE_PATH="$FCL_FOLDER":$FHICL_FILE_PATH # in this way lar will find the fcls under ../fcl/
export FHICL_FILE_PATH="$DATA_PATH":$FHICL_FILE_PATH # some fcls are going to be here

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

# dump the original gen fcl to the folder, it is used by the GEN_FCL_CHANGED
fhicl-dump ${GEN_FCL}.fcl > $DATA_PATH/${GEN_FCL}_dump.fcl
fhicl-dump ${G4_FCL}.fcl > $DATA_PATH/${G4_FCL}_dump.fcl
fhicl-dump ${DETSIM_FCL}.fcl > $DATA_PATH/${DETSIM_FCL}_dump.fcl
fhicl-dump ${RECO_FCL}.fcl > $DATA_PATH/${RECO_FCL}_dump.fcl

# If standard, generate new fcl using standard-fcl.sh
if [ "$SIMULATION_CATEGORY" = "standard" ]; then
    echo "Generating fcl file with standard values..."
    . $REPO_HOME/scripts/standard-fcl.sh -f "$GEN_FCL" -v -o "$DATA_PATH"
    echo " "
fi

# If custom direction is selected, generate a random direction and create a new fcl file
if [ "$SIMULATION_CATEGORY" = "directions" ]; then
    # generate the direction and print it in the fcl and in a txt file
    . $REPO_HOME/scripts/custom-direction.sh -f "$GEN_FCL" -v -o "$DATA_PATH"
    echo " "
fi

# If custom energy is selected, generate energy bins and create a new fcl file
if [ "$SIMULATION_CATEGORY" = "energies" ]; then
    echo "Generating fcl file with custom energy range, $energy_min to $energy_max..."
    . $REPO_HOME/scripts/custom-energy.sh -f "$GEN_FCL" -m "$energy_min" -M "$energy_max" -v -o "$DATA_PATH"
    echo " "
fi

if [ "$SIMULATION_CATEGORY" = "customEandD" ]; then
    echo "Generating fcl file with custom energy range and direction..."
    . $REPO_HOME/scripts/custom-enAndDir.sh -f "$GEN_FCL" -m "$energy_min" -M "$energy_max" -v -o "$DATA_PATH"
    echo " "
fi


cd "$DATA_PATH"
echo "We are now in $(pwd)"
echo "Items here are $(ls -l)"

start_time=$(date +%s)
echo "Starting simulation at $start_time"

# Execute simulations based on options
if [ "$run_marley" = true ]; then

    echo "Starting Generation..."
    gen_start_time=$(date +%s)
    echo "Starting generation at $gen_start_time"

    command_marley="lar -c ${DATA_PATH}${GEN_FCL_CHANGED}.fcl -n $number_events -o ${DATA_PATH}${GEN_FCL}.root"
    echo "Executing command: $command_marley"
    $command_marley

    # if returns 0, then it was successful
    if [ $? -eq 0 ]; then
        echo -e " Generation done!\n"
        echo -e " In the folder now we have"
        echo -e " $(ls -l) \n"
    else
        echo " Generation failed. Exiting..."
        exit 1
    fi

    gen_end_time=$(date +%s)
    echo "Ending generation at $gen_end_time"
    gen_exec_time=$(($gen_end_time - $gen_start_time))
    echo "Generation took $gen_exec_time seconds"
    echo "$gen_exec_time" > "${DATA_PATH}execTime.txt"

fi

if [ "$run_g4" = true ]; then
    
    echo "Starting Geant4 simulation..."
    detsim_start_time=$(date +%s)
    echo "Starting detector simulation at $detsim_start_time"

    command_g4="lar -c ${G4_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}.root -o ${DATA_PATH}${GEN_FCL}_g4.root"
    echo "Executing command: $command_g4"
    $command_g4
    
    # if returns 0, then it was successful
    if [ $? -eq 0 ]; then
        echo -e " Geant4 simulation done!"
        # remove the root file to save memory
        if [ "$delete_root_files" = true ]; then
            rm "${DATA_PATH}${GEN_FCL}.root"
        fi
    else
        echo " Geant4 simulation failed. Exiting..."
        exit 1
    fi
    echo ""

    detsim_end_time=$(date +%s)
    echo "Ending detector simulation at $detsim_end_time"
    detsim_exec_time=$(($detsim_end_time - $detsim_start_time))
    echo "G4 simulation took $detsim_exec_time seconds"
    echo "$detsim_exec_time" > "${DATA_PATH}execTime.txt"

fi

if [ "$run_detsim" = true ]; then
    
    detsim_start_time=$(date +%s)
    echo "Starting detector simulation at $detsim_start_time"

    command_detsim="lar -c ${DETSIM_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}_g4.root -o ${DATA_PATH}${GEN_FCL}_g4_detsim.root"
    echo "Executing command: $command_detsim"
    $command_detsim
    
    if [ $? -eq 0 ]; then
        echo -e " Detector simulation done!\n"
        echo -e " In the folder now we have"
        echo -e " $(ls -l) \n"
        # remove the root file to save memory
        if [ "$delete_root_files" = true ]; then
            rm "${DATA_PATH}${GEN_FCL}_g4.root"
        fi
    else
        echo " Detector simulation failed. Exiting..."
        exit 1
    fi

    detsim_end_time=$(date +%s)
    echo "Ending detector simulation at $detsim_end_time"
    detsim_exec_time=$(($detsim_end_time - $detsim_start_time))
    echo "Detsim took $detsim_exec_time seconds"
    echo "$detsim_exec_time" > "${DATA_PATH}execTime.txt"

fi

if [ "$run_reconstruction" = true ]; then
    
    start_recotime=$(date +%s)
    echo "Starting reconstruction at $start_recotime"

    RECO_OUTPUT="${DATA_PATH}${GEN_FCL}_g4_detsim_reco1.root"
    command_reco="lar -c ${RECO_FCL}.fcl -n $number_events -s ${DATA_PATH}${GEN_FCL}_g4_detsim.root -o "$RECO_OUTPUT""
    echo "Executing command: $command_reco"
    $command_reco
    
    if [ $? -eq 0 ]; then
        echo -e " Reconstruction done! \n"
        echo -e " In the folder now we have"
        echo "$(ls -l) \n"
        # remove the root file to save memory
        if [ "$delete_root_files" = true ]; then
            rm "${DATA_PATH}${GEN_FCL}_g4_detsim.root"
        fi
    else
        echo " Reconstruction failed. Exiting..."
        exit 1
    fi

    end_recotime=$(date +%s)
    echo "Ending reconstruction at $end_recotime"
    reco_exec_time=$(($end_recotime - $start_recotime))
    echo "Reconstruction took $reco_exec_time seconds"
    echo "$reco_exec_time" > "${DATA_PATH}execTime.txt"
    echo "Size of the reco file is $(du -h $RECO_OUTPUT | awk '{print $1}')"
fi


end_time=$(date  +%s)
echo "Ending simulation at $end_time"
exec_time=$(($end_time - $start_time))
echo "Simulation took $exec_time seconds"

# print to a file the time it took
echo "$exec_time" > "${DATA_PATH}execTime.txt"

echo "Currently in ${PWD}"
echo "Items here are $(ls -l)"

# Delete root files
if [ "$delete_root_files" = true ]; then
    echo "Deleting root files to save memory..."    
    rm -f "${DATA_PATH}*.root"
    rm -f ./-_detsim_hist.root # Sometimes there is this product, remove it
fi

if [ "$run_reconstruction" = true ] && [[ "$RECO_FCL" == *"trigger"* ]] && [[ $(whoami) == "*villa" ]]; then
    EOS_FOLDER="/eos/user/e/evilla/dune/sn-tps/"       # standard, for now. Subfolders are selected automatically
    # Move all products to the folder
    FINAL_FOLDER="${EOS_FOLDER}${SIMULATION_CATEGORY}/aggregated_${SIMULATION_NAME}/" # TODO grep threshold from somewhere
    echo "Creating final folder $FINAL_FOLDER"
    mkdir -p "$FINAL_FOLDER"
    echo "Moving custom direction and TPs to $FINAL_FOLDER"
    TP_FILE="triggersim_hist.root" # TODO make this absolute or grep it
    moving_tps="cp ${TP_FILE} ${FINAL_FOLDER}tpstream_${OUTFOLDER_ENDING}.root"
    echo "$moving_tps"
    $moving_tps

    if [ "$custom_direction" = true ]; then
        # move the custom direction file
        moving_custom_direction="cp ${DATA_PATH}customDirection.txt ${FINAL_FOLDER}customDirection_${OUTFOLDER_ENDING}.txt"
        echo "$moving_custom_direction"
        $moving_custom_direction
    fi
fi

if [ "$clean_folder" = true ]; then
    echo "Cleaning folder..."
    rm -r "$DATA_PATH"
fi

# Print the data path
echo "Moving back to $REPO_HOME/scripts"
cd "$REPO_HOME/scripts"
echo "If it has not been cleaned, all products are in $DATA_PATH"

if [ "$run_reconstruction" = true ] && [[ "$RECO_FCL" == *"trigger"* ]] && [[ $(whoami) == "*villa" ]]; then
    echo "TPs are in $FINAL_FOLDER"
fi
