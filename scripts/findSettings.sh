#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
source $SCRIPT_DIR/init.sh

settingsFile=""

print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./findSettings.sh -s <settings_file> [-h]"
    echo "  -s | --settings-file   json settings file in any format (global path, local path, only the name, with or without .json)"
    echo "  -h | --help            print this help message"
    echo "*****************************************************************************"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--settings-file) settingsFile="$2"; shift 2;;
        -h|--help) print_help;;
        *) shift;;
    esac
done

if [ -z "$settingsFile" ]
then
    echo "Please specify the settings file, using flag -s <settings_file>. Stopping execution."
    echo "" # need this so that the scripts using this one will fail if the settings file is not provided
    exit 1
fi

# if absolute path, all good. If path starting with settings, just add REPO_HOME.
# if it's a local path, add the current directory path
if [[ ! "$settingsFile" == /* ]]
then
    if [[ "$settingsFile" == json/* ]] # contains relative path
    then
        settingsFile="$REPO_HOME/$settingsFile"
    else # no path 
        settingsFile="$JSON_DIR/$settingsFile"
    fi
fi

# If missing .json extension, add it
if [[ ! "$settingsFile" == *.json ]]
then
    settingsFile="$settingsFile.json"
fi

echo "Looking for settings file $settingsFile."

# if the file does not exist or is not an absolute path, print a warning
if [ ! -f "$settingsFile" ]
then
    echo "WARNING: The settings file $settingsFile does not exist. Stopping execution."
    echo "" # need this so that the scripts using this one will fail if the settings file is not found
    exit 1
fi

# last line of the output is the full path of the settings file, to be used by the calling script
echo "Settings file found:"
echo $settingsFile
