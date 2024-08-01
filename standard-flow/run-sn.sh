# load ups products

# this is done in the other script called below, uncomment if needed
# source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
# export DUNESW_VERSION=v09_78_03d01;
# export DUNESW_QUALIFIER=e20:prof;
# echo 'Setting up dunesw version' $DUNESW_VERSION', qualifier' $DUNESW_QUALIFIER '...'
# setup dunesw $DUNESW_VERSION -q $DUNESW_QUALIFIER
# echo ' Done!'

DATA_PATH='./output/'
number_events=1

source source-dunesw.sh

# generation
lar -c gen_nuccrbkg.fcl -n $number_events -o ${DATA_PATH}hckgen_nuccrbkg.root

# g4
lar -c supernova_g4_dune10kt_1x2x2.fcl -n $number_events -s ${DATA_PATH}hckgen_nuccrbkg.root -o ${DATA_PATH}hckgen_nuccrbkg_g4.root

# detsim
lar -c detsim_dune10kt_1x2x2_notpcsigproc.fcl -n $number_events -s ${DATA_PATH}hckgen_nuccrbkg_g4.root -o ${DATA_PATH}hckgen_nuccrbkg_g4_detsim.root

# reco
lar -c reco_trigprim.fcl -n $number_events -s ${DATA_PATH}hckgen_nuccrbkg_g4_detsim.root -o ${DATA_PATH}hckgen_nuccrbkg_g4_reco1.root

# move all products to the folder
# mv *.root *.log ${DATA_PATH}
