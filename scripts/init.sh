#!/bin/bash

# don't rerun if variables are already defined. TODO decide about this...?
# the problem is that when sourcing scripts inside others, the env variables are not accessible to 
# the lower level one. Verbose output does not seem like to bad at the moment
# if [ -n "$REPO_HOME" ]; then
#     exit 0
# fi

echo "init.sh script started"

# strict error handling, TODO add as option somewhere, to leave it on is too much
# It could be set for example in the testing script 
# set -euo pipefail

# Some variables to export at the beginning of scripts and execution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

export REPO_HOME=$(dirname $SCRIPT_DIR)
echo " Repository home is $REPO_HOME"

export DAT_DIR="$REPO_HOME/dat/"
export FCL_DIR="$REPO_HOME/fcl/"
export JSON_DIR="$REPO_HOME/json/"
export DOCS_DIR="$REPO_HOME/docs/"
export PYTHON_DIR="$REPO_HOME/python/"
echo "Set up local directories"

# export REPO_VERSION=""
# if [ -z "$PRINTED_VERSION_WARNING" ]; then
#     export PRINTED_VERSION_WARNING=false
# fi
# export GIT_DESCRIBE=$(git describe --tags --always)

# read version from docs/tof-reco-version.dat
# if [ -f $REPO_HOME/docs/version.txt ]; then
#     export REPO_VERSION=$(cat $REPO_HOME/docs/tof-reco-version.txt)
#     echo " Found version file, tof-reco version is $REPO_VERSION"
#     if [ "$REPO_VERSION" != "$GIT_DESCRIBE" ] && [ "$PRINTED_VERSION_WARNING" == false ]; then
#         echo " WARNING: The version file does not match the git tag: $GIT_DESCRIBE. This indicates that you have local changes."
#         echo " Please make sure that your changes don't change the output of the code, or products in output folder will differ."
#         PRINTED_VERSION_WARNING=true
#     fi
# else 
#     echo " No version file found, something went wrong the last time the repo was tagged"
# fi

echo "init.sh script finished"
echo ""
