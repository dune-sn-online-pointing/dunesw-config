# load ups products
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

export DUNESW_VERSION=v09_78_03d01;
export DUNESW_QUALIFIER=e20:prof;
echo 'Setting up dunesw version' $DUNESW_VERSION', qualifier' $DUNESW_QUALIFIER '...'
setup dunesw $DUNESW_VERSION -q $DUNESW_QUALIFIER
echo 'Done!'
