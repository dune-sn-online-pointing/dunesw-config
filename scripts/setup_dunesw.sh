#!/bin/bash

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

# $1 needs to be the full version in the form vXX_YY_ZZdAA
# e.g. v10_04_05d00

echo "Setting up dunesw $1"

IFS='d' read -r -a array <<< "$1"
version=${array[0]}
extension=d${array[1]}

# version="v10_04_05"
# extension="d00" 
export DUNESW_VERSION=$version$extension;
qualifier="e26"
specifier="prof"
export DUNESW_QUALIFIER=${qualifier}:${specifier}

#source /exp/dune/app/users/emvilla/$DUNESW_VERSION/localProducts_larsoft_${version}_${qualifier}_${specifier}/setup # this will be the setup in your local installation
THIS_PWD=$PWD
#cd $MRB_BUILDDIR
#mrbslp

echo 'Setting up dunesw version' $DUNESW_VERSION', qualifier' $DUNESW_QUALIFIER '...'
setup dunesw $DUNESW_VERSION -q $DUNESW_QUALIFIER

echo 'Done!'

cd $THIS_PWD # go back where we were
