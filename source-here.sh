#!/bin/bash

# Save the current directory
THIS_DIR=$PWD

# Set up the environment
source /afs/cern.ch/work/e/evilla/private/dune/dunesw/duneana-dev/localProducts_larsoft_v09_79_00_e26_prof/setup

compile=false
add_targets=false

# Function to print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./computeBaselineValues.sh [-c] [-z] [-h]"
    echo "  -c                 compile the code"
    echo "  -z                 add targets to the build"
    echo "  -h | --help        print this help message"
    echo "*****************************************************************************"
    exit 0 # not ok, change
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
      -c)
        compile=true
        shift
        ;;
      -z)
        add_targets=true
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


# Change to the MRB build directory
cd $MRB_BUILDDIR

# Perform the "mrb z" operation, if add_targets is true
if [ "$add_targets" = true ]; then
    mrb z
fi

# Set up the mrb environment
mrbsetenv

# do mrb i -j8 only if compile is true
if [ "$compile" = true ]; then
    mrb i -j8
fi

# Return to the original directory
cd $THIS_DIR
