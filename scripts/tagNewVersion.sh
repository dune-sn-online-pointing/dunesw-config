#!/bin/bash

# This script is used to tag a new version of the software.
echo "Script tagNewVersion.sh started"

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/initialize.sh

print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./tagNewVersion.sh -v <version_number> [-h]"
    echo "  -v | --version-number  version number to tag the new version"
    echo "  -h | --help            print this help message"
    echo "*****************************************************************************"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version-number) versionNumber="$2"; shift 2;;
        -h|--help) print_help;;
        *) shift;;
    esac
done

if [ -z "$versionNumber" ]
then
    echo "Please specify the version number, using flag -v <version_number>. Stopping execution."
    exit 0
fi

# Update the version number in the version file
version_file="${REPO_HOME}/docs/dunesw-config-version.txt"
echo "$versionNumber" > $version_file
git add $version_file; git commit -m "Update version number to $versionNumber"; git push

# If not in the main branch, print a warning TODO add more severe handling, require input to continue
currentBranch=$(git branch --show-current)
if [ "$currentBranch" != "main" ]
then
    echo "WARNING: You are not in the main branch. You are in $currentBranch branch."
fi

# pull, just to make sure to have all remote changes
git pull

# TODO add tests here?

# Tag the new version
git tag -a $versionNumber

# here there should be nano opening to write the message

git push origin $versionNumber

echo "Tagged version $versionNumber successfully"

exit 0