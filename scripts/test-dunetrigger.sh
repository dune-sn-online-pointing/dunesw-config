#!/bin/bash

# This script is used to test the dune trigger fcls
# Currently (Feb 18th) there are fcls only for protodunehd, 1x2x2 and 1x2x6
# There need to be simulation running for the different geometries, using trigger-sim.sh

echo "________________________________________________________"
echo "Starting test-dunetrigger.sh"
success=true
timeout=200000

# protodunehd
# echo " protodunehd"
# protodune_gen_fcl="prodsinglep_protodunehd.fcl"
# protodune_reco_fcls=("triggersim_protodunehd_simpleThr_simpleWin_simpleWin.fcl", 
#     "triggerana_tpc_infocomparator_protodunehd.fcl",
#     "triggerana_tpc_infodisplay_protodunehd.fcl",
#     "triggerana_tree_protodunehd.fcl")

# for reco_fcl in ${protodune_reco_fcls[@]}; do
#     command_protodune="./triggersim.sh -m ${protodune_gen_fcl} -g -d -r ${reco_fcl} -j trig.json -f testPdune"
#     echo " Running command: ${command_protodune}"
#     ${command_protodune} 
#     if [ $? -ne 0 ]; then
#         echo " PROBLEM!!!!"
#         success=false
#         sleep 200
#     fi
# done

# 1x2x6
echo " 1x2x6 geometry"
onetwosix_gen_fcl="prodmarley_nue_flat_dune10kt_1x2x6_dump.fcl"
onetwosix_g4_fcl="supernova_g4_dune10kt_1x2x6.fcl"
onetwosix_detsim_fcl="detsim_dune10kt_1x2x6_notpcsigproc"
onetwosix_reco_fcls=("triggersim_1x2x6_simpleThr_simpleWin_simpleWin.fcl" 
    "triggerana_tree_1x2x6.fcl")

for reco_fcl in ${onetwosix_reco_fcls[@]}; do
    command_1x2x6="./triggersim.sh -m ${onetwosix_gen_fcl} -g $onetwosix_g4_fcl -d $onetwosix_detsim_fcl -r ${reco_fcl} -j trig.json -f test1x2x6"
    echo " Running command: ${command_1x2x6}"
    ${command_1x2x6}
    if [ $? -ne 0 ]; then
        echo " PROBLEM!!!!"
        success=false
        sleep $timeout
    fi
done

# 1x2x2
echo " 1x2x2 geometry"
onetwotwo_gen_fcl="prodmarley_nue_flat_dune10kt_1x2x2_dump.fcl"
onetwotwo_g4_fcl="supernova_g4_dune10kt_1x2x2.fcl"
onetwotwo_detsim_fcl="detsim_dune10kt_1x2x2_notpcsigproc"
onetwotwo_reco_fcls=("triggersim_1x2x2_simpleThr_simpleWin_simpleWin.fcl" 
    "triggerana_tree_1x2x2.fcl")

for reco_fcl in ${onetwotwo_reco_fcls[@]}; do
    command_1x2x2="./triggersim.sh -m ${onetwotwo_gen_fcl} -g $onetwotwo_g4_fcl -d $onetwotwo_detsim_fcl -r ${reco_fcl} -j trig.json -f test1x2x2"
    echo " Running command: ${command_1x2x2}"
    ${command_1x2x2}
    if [ $? -ne 0 ]; then
        echo " PROBLEM!!!!"
        success=false
        sleep $timeout
    fi
done

if [ $success = true ]; then
    echo "All tests passed!"
else
    echo "Some tests failed, look back at output or rerun."
fi

echo "________________________________________________________"
