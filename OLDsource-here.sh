#!/bin/bash

# Save the current directory
THIS_DIR=$PWD

# Set up the environment
folder="verbose-dev" # folder where local products are

compile=false
add_targets=false

# Function to print help message
print_help() {
    echo "*****************************************************************************"
    echo "Usage: ./computeBaselineValues.sh [-c] [-z] [-h]"
    echo "  -c                 compile the code"
    echo "  -z                 add targets to the build"
    echo "  -f 		       folder where the local products are"
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
      -f)
	folder="$2"
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

# setting folder, should throw an error if it was not set
source /afs/cern.ch/work/e/evilla/private/dune/dunesw/${folder}/localProducts_larsoft_v09_79_00d02_prof_e26/setup

# Change to the MRB build directory
cd $MRB_BUILDDIR

# Perform the "mrb z" operation, if add_targets is true
if [ "$add_targets" = true ]; then
  echo ""
  echo "Clean and add targets to the build"
  mrb zd
fi

# Set up the mrb environment
echo ""
echo "Setting up mrb environment in $PWD"
mrbsetenv

# do mrb i -j8 only if compile is true
if [ "$compile" = true ]; then
  echo ""
  echo "Compiling code"
  # mrb b -j10
  mrb i -j10
fi

#mrbslp # only when installing
# Return to the original directory
cd $THIS_DIR
