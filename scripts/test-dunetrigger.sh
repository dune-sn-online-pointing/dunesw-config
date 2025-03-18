#!/bin/bash

# This script is used to test the dune trigger fcls
# Currently (Feb 18th) there are fcls only for protodunehd, 1x2x2 and 1x2x6
# There need to be simulation running for the different geometries, using trigger-sim.sh

echo "________________________________________________________"
echo "Starting test-dunetrigger.sh"
success=true
timeout=200
only_reco=true
pdune=false
pdune_data=true
onetwosix=false
onetwotwo=false

# initialize TODO make a script
REPO_HOME="$(git rev-parse --show-toplevel)"
echo "REPO_HOME for script run-sn-simulation.sh: $REPO_HOME"
echo "When running in condor, this won't work. Use the --home-config flag to set the path to the dunesw-config folder"
# this script has to be run from the dunesw-config area 

# protodunehd
# echo " protodunehd"
protodune_gen_fcl="prodsinglep_protodunehd.fcl"
protodune_g4_fcl="standard_g4_protodunehd.fcl"
protodune_detsim_fcl="standard_detsim_protodunehd.fcl"
protodune_reco_fcls=("triggerana_tree_protodunehd_simpleThr_simpleWin_simpleWin.fcl"
    "triggersim_protodunehd_simpleThr_simpleWin_simpleWin")

# pdune_decoder="run_pdhd_wibeth3_tpc_decoder" 
pdune_decoder="run_pdhd_tpc_decoder.fcl" 
protodune_data_reco_fcls=( "triggersim_protodunehd_simpleThr_simpleWin_simpleWin"
    "triggerana_tree_protodunehd_simpleThr_simpleWin_simpleWin.fcl"
    "triggerana_tpc_infodisplay_protodunehd_simpleThr_simpleWin_simpleWin.fcl"
    "triggerana_tpc_infocomparator_protodunehd_simpleThr_simpleWin_simpleWin.fcl")


if [ $pdune = true ]; then
    for reco_fcl in ${protodune_reco_fcls[@]}; do
        command_protodune=". ${REPO_HOME}/scripts/triggersim.sh -m ${protodune_gen_fcl} -g ${protodune_g4_fcl} -d ${protodune_detsim_fcl} -r ${reco_fcl} -j trig.json -f testPdune"
        if [ $only_reco = true ]; then
            command_protodune=". ${REPO_HOME}/scripts/triggersim.sh -M ${protodune_gen_fcl} -G ${protodune_g4_fcl} -D ${protodune_detsim_fcl} -r ${reco_fcl} -j trig.json -f testPdune"
        fi
        echo " Running command: ${command_protodune}"
        ${command_protodune} 
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_protodune}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${reco_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

if [ $pdune_data = true ]; then
    # pdune_decoder="run_pdhd_tpc_decoder" # repo one
    for reco_fcl in ${protodune_data_reco_fcls[@]}; do
        command_protodune=". ${REPO_HOME}/scripts/protoduneana.sh -c ${pdune_decoder} -r ${reco_fcl} -j trig.json -f testPduneData"
        echo " Running command: ${command_protodune}"
        ${command_protodune} 
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_protodune}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${reco_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

# 1x2x6
echo " 1x2x6 geometry"
onetwosix_gen_fcl="prodmarley_nue_flat_dune10kt_1x2x6.fcl"
onetwosix_g4_fcl="supernova_g4_dune10kt_1x2x6.fcl"
onetwosix_detsim_fcl="detsim_dune10kt_1x2x6_notpcsigproc"
onetwosix_reco_fcls=("triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl"
    "triggersim_1x2x6_simpleThr_simpleWin_simpleWin")

# "james_triggerana_dump.fcl"

if [ $onetwosix = true ]; then
    for reco_fcl in ${onetwosix_reco_fcls[@]}; do
        command_1x2x6=". ${REPO_HOME}/scripts/triggersim.sh -m ${onetwosix_gen_fcl} -g $onetwosix_g4_fcl -d $onetwosix_detsim_fcl -r ${reco_fcl} -j trig.json -f test1x2x6"
        if [ $only_reco = true ]; then
            command_1x2x6=". ${REPO_HOME}/scripts/triggersim.sh -M ${onetwosix_gen_fcl} -G $onetwosix_g4_fcl -D $onetwosix_detsim_fcl -r ${reco_fcl} -j trig.json -f test1x2x6"
        fi
        echo " Running command: ${command_1x2x6}"
        ${command_1x2x6}
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_1x2x6}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${reco_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

# 1x2x2
echo " 1x2x2 geometry"
onetwotwo_gen_fcl="prodmarley_nue_spectrum_dune10kt_1x2x2.fcl"
onetwotwo_g4_fcl="supernova_g4_dune10kt_1x2x2.fcl"
onetwotwo_detsim_fcl="detsim_dune10kt_1x2x2_notpcsigproc"
onetwotwo_reco_fcls=("triggerana_tree_1x2x2_simpleThr_simpleWin_simpleWin.fcl"
    "triggersim_1x2x2_simpleThr_simpleWin_simpleWin.fcl")

if [ $onetwotwo = true ]; then
    for reco_fcl in ${onetwotwo_reco_fcls[@]}; do
        command_1x2x2=". ${REPO_HOME}/scripts/triggersim.sh -m ${onetwotwo_gen_fcl} -g $onetwotwo_g4_fcl -d $onetwotwo_detsim_fcl -r ${reco_fcl} -j trig.json -f test1x2x2"
        if [ $only_reco = true ]; then
            command_1x2x2=". ${REPO_HOME}/scripts/triggersim.sh -M ${onetwotwo_gen_fcl} -G $onetwotwo_g4_fcl -D $onetwotwo_detsim_fcl -r ${reco_fcl} -j trig.json -f test1x2x2"
        fi
        echo " Running command: ${command_1x2x2}"
        ${command_1x2x2}
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_1x2x2}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${reco_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

if [ $success = true ]; then
    echo "All tests passed!"
else
    echo "Some tests failed, look back at output or rerun."
fi

echo "________________________________________________________"
