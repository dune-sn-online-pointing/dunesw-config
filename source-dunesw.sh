# load ups products
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

export DUNESW_VERSION=v09_79_00d02; # this is what Klaudia used to test the workflow
export DUNESW_QUALIFIER=e26:prof;
echo 'Setting up dunesw version' $DUNESW_VERSION', qualifier' $DUNESW_QUALIFIER '...'
setup dunesw $DUNESW_VERSION -q $DUNESW_QUALIFIER
echo 'Done!'
