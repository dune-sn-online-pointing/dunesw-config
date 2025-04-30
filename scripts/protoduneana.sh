#!/bin/bash

# Initialize env variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
source $SCRIPT_DIR/init.sh

# Default values for simulation stages
run_convert=false
run_reconstruction=false
source_flag=true  # Flag for -s option
delete_root_files=false
clean_folder=false

# fcls, just some casual defaults
CONVERT_FCL='run_pdhd_tpc_decoder'   
# RECO_FCL='triggerana_tpc_infodisplay_protodunehd_simpleThr_simpleWin_simpleWin'           
RECO_FCL='triggerana_tpc_infocomparator_protodunehd_simpleThr_simpleWin_simpleWin'     
HDF5_TESTER="/exp/dune/app/users/emvilla/np04hd_raw_run029424_0003_dataflow0_datawriter_0_20241004T174144.hdf5"      
# HDF5_TESTER="/exp/dune/app/users/dpullia/trigger_dev_test/np04hd_raw_run029424_0011_dataflow0_datawriter_0_20241004T175209.hdf5"

# other params that is better to initialize
JSON_SETTINGS="settings_template.json"
OUTFOLDER_ENDING=""
number_events=1

# Function to source scripts and print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./$0 -j <yoursettings.json> [options]"
    echo "Options:"
    echo "  -j, --json-settings    JSON file with paths and settings. It has to be in the dunesw-config/json folder"
    echo "  --home-config          Path to the dunesw-config folder. Default is the current folder, but it won't work  in Condor"
    echo "  -c, --convert          Convert raw data to root"
    echo "  -C, --convert          Without running"
    echo "  -r, --reconstruction   Run event reconstruction"
    echo "  -R, --Reconstruction   Parse reco fcl for the folder, without (re)running this step"
    echo "  -n, --n-events         Number of events, default is 1"
    echo "  -s, --source           Parse to NOT source dunesw and local products"
    echo "  -f, --folder-ending    Ending of the name of the output folder"
    echo "  --clean-folder         Clean the folder after simulation. Default is false"
    echo "  --delete-root          Delete root files after simulation, to save space. Default is false"
    echo "  -h, --help             Print this help message"
    echo " "
    echo "Example: ./run-sn-simulation.sh -m myconfig.fcl --custom-energy 2 70 -g -c -r -s -n 1000 -f test --clean-folder false --celete-root false"
    echo "*****************************************************************************"
    exit 0
}


# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --home-config)       REPO_HOME="${2%/}"; shift 2 ;;
        -j|--json-settings)  JSON_SETTINGS="$2"; shift 2 ;;
        -c|--convert)        run_convert=true; [[ "$2" != -* ]] && CONVERT_FCL="${2%.fcl}" && shift; shift ;;
        -C|--convert)        CONVERT_FCL="${2%.fcl}"; shift 2 ;;
        -r|--reconstruction) run_reconstruction=true; [[ "$2" != -* ]] && RECO_FCL="${2%.fcl}" && shift; shift ;;
        -R|--Reconstruction) RECO_FCL="${2%.fcl}"; shift 2 ;;
        -n|--n-events)       number_events="$2"; shift 2 ;;
        -s|--source)         source_flag=false; shift ;;
        -f|--folder-ending)  OUTFOLDER_ENDING="$2"; shift 2 ;;
        --clean-folder)      clean_folder="$2"; shift 2 ;;
        --celete-root)       delete_root_files="$2"; shift 2 ;;
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
echo "Expecting the software to be in: $DUNESW_FOLDER_NAME. (If empty or not valid, no local products are sourced)"
# check if the folder exists
if [ -d "$DUNESW_FOLDER_NAME" ]; then
    echo "Folder $DUNESW_FOLDER_NAME exists"
    GLOBAL_OUTPUT_FOLDER="${DUNESW_FOLDER_NAME}output/"
else
    echo "Folder $DUNESW_FOLDER_NAME does not exist, no local products being sourced."
    echo "A folder with the dunesw version will be created for the outputs"
    export DUNESW_FOLDER_NAME="" # empty it
    GLOBAL_OUTPUT_FOLDER="$(cd "$REPO_HOME/.." && pwd)/${DUNESW_VERSION}/output/"
fi

echo "Output folder is $GLOBAL_OUTPUT_FOLDER, creating it in case it does not exist"
mkdir -p "$GLOBAL_OUTPUT_FOLDER"

setup_dunesw="${REPO_HOME}/scripts/setup_dunesw.sh" 

# Source the required scripts for execution
if [ "$source_flag" = true ]; then
    # extract dunesw version from filename, it assumes there is a local install
    # and the location is the one in the json file
    source $setup_dunesw $DUNESW_VERSION
fi


EOS_FOLDER="/eos/user/e/evilla/dune/sn-tps/"       # standard, for now. Subfolders are selected automatically


# Add flux files to the path
export FW_SEARCH_PATH=$FW_SEARCH_PATH:"$REPO_HOME/dat/"

# if none of the run commands are true, stop script
if [ "$run_convert" = false ] && [ "$run_reconstruction" = false ]; then
    echo "No simulation stage selected. "
    print_help
    exit 0
fi


SIMULATION_NAME="${CONVERT_FCL}-${RECO_FCL}-${number_events}events"
DATA_PATH="${GLOBAL_OUTPUT_FOLDER}/${SIMULATION_NAME}_${OUTFOLDER_ENDING}/"
FCL_FOLDER="$REPO_HOME/fcl/" 

export FHICL_FILE_PATH="$FCL_FOLDER":$FHICL_FILE_PATH # in this way lar will find the fcl without needing the path
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
fhicl-dump ${CONVERT_FCL}.fcl > $DATA_PATH/${CONVERT_FCL}_dump.fcl
fhicl-dump ${RECO_FCL}.fcl > $DATA_PATH/${RECO_FCL}_dump.fcl

cd "$DATA_PATH"
echo "We are now in $(pwd)"
echo "Items here are $(ls)"

start_time=$(date +%s)
echo "Starting simulation at $start_time"


if [ "$run_convert" = true ]; then
    converted_file="${DATA_PATH}TESTFILE_converted"
    command_convert="lar -c ${CONVERT_FCL}.fcl -n ${number_events} -s ${HDF5_TESTER} -o  ${converted_file}.root"
    echo "Executing command: $command_convert"
    $command_convert
    
    if [ $? -eq 0 ]; then
        echo -e " Conversion done!\n"
        echo -e " In the folder now we have"
        echo -e " $(ls) \n"
    else
        echo " Conversion failed. Exiting..."
        exit 1
    fi
fi

if [ "$run_reconstruction" = true ]; then
    RECO_OUTPUT="${converted_file}_reco1"
    command_reco="lar -c ${RECO_FCL}.fcl -s ${converted_file}.root -o ${RECO_OUTPUT}.root"
    echo "Executing command: $command_reco"
    $command_reco
    
    if [ $? -eq 0 ]; then
        echo -e " Reconstruction done! \n"
        echo -e " In the folder now we have"
        echo "$(ls) \n"
        # remove the root file to save memory
        if [ "$delete_root_files" = true ]; then
            rm ${converted_file}
        fi
    else
        echo " Reconstruction failed. Exiting..."
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

# Delete root files
if [ "$delete_root_files" = true ]; then
    echo "Deleting root files to save memory..."    
    rm -f "${DATA_PATH}*.root"
    rm -f ./-_detsim_hist.root # Sometimes there is this product, remove it
fi

if [ "$clean_folder" = true ]; then
    echo "Cleaning folder..."
    rm -r "$DATA_PATH"
fi

# go back here
cd $REPO_HOME

# Print the data path
echo "If it has not been cleaned, all products are in $DATA_PATH"
