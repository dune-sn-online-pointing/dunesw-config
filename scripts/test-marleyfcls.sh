#!/bin/bash

# This script is used to test the dune trigger fcls
# Currently (Feb 18th) there are fcls only for protodunehd, 1x2x2 and 1x2x6
# There need to be simulation running for the different geometries, using trigger-sim.sh

# Initialize env variables
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPTS_DIR
source $SCRIPTS_DIR/init.sh

echo "________________________________________________________"
echo "Starting $0"
success=true
timeout=200
flat=false
gkvm=true
livermore=true
garching=true


marley_gen_fcls_flat=(
    "prodmarley_nue_cc_flat_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_flat_dune10kt_1x2x6.fcl"
    "prodmarley_nue_cc_flat_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_flat_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_cc_flat_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
    "prodmarley_nue_es_flat_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_flat_dune10kt_1x2x6.fcl"
    "prodmarley_nue_es_flat_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_flat_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_es_flat_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
    # "prodnuescatter_flat_dune10kt_1x2x6.fcl"
    # "prodnuescatter_flat_radiological_dune10kt_1x2x6.fcl"
)

marley_gen_fcls_gkvm=(
    "prodmarley_nue_cc_gkvm_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_gkvm_dune10kt_1x2x6.fcl"
    "prodmarley_nue_cc_gkvm_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_gkvm_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_cc_gkvm_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
    "prodmarley_nue_es_gkvm_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_gkvm_dune10kt_1x2x6.fcl"
    "prodmarley_nue_es_gkvm_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_gkvm_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_es_gkvm_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
)

marley_gen_fcls_livermore=(
    "prodmarley_nue_cc_livermore_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_livermore_dune10kt_1x2x6.fcl"
    "prodmarley_nue_cc_livermore_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_livermore_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_cc_livermore_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
    "prodmarley_nue_es_livermore_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_livermore_dune10kt_1x2x6.fcl"
    "prodmarley_nue_es_livermore_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_livermore_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_es_livermore_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
)

marley_gen_fcls_garching=(
    "prodmarley_nue_cc_garching_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_garching_dune10kt_1x2x6.fcl"
    "prodmarley_nue_cc_garching_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_cc_garching_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_cc_garching_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
    "prodmarley_nue_es_garching_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_garching_dune10kt_1x2x6.fcl"
    "prodmarley_nue_es_garching_radiological_decay0_dune10kt_1x2x2.fcl"
    "prodmarley_nue_es_garching_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl"
    "prodmarley_nue_es_garching_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl"
)

if [ "$flat" = true ]; then
    marley_gen_fcls=("${marley_gen_fcls_flat[@]}")
    for gen_fcl in ${marley_gen_fcls[@]}; do
        command_gen=". ${HOME_DIR}/scripts/triggersim.sh -m ${gen_fcl} -j 100407.json -f testFcl"
        echo " Running command: ${command_gen}"
        ${command_gen} 
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_gen}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${gen_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

if [ "$gkvm" = true ]; then
    marley_gen_fcls=("${marley_gen_fcls_gkvm[@]}")
    for gen_fcl in ${marley_gen_fcls[@]}; do
        command_gen=". ${HOME_DIR}/scripts/triggersim.sh -m ${gen_fcl} -j 100407.json -f testFcl"
        echo " Running command: ${command_gen}"
        ${command_gen} 
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_gen}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${gen_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

if [ "$livermore" = true ]; then
    marley_gen_fcls=("${marley_gen_fcls_livermore[@]}")
    for gen_fcl in ${marley_gen_fcls[@]}; do
        command_gen=". ${HOME_DIR}/scripts/triggersim.sh -m ${gen_fcl} -j 100407.json -f testFcl"
        echo " Running command: ${command_gen}"
        ${command_gen} 
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_gen}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${gen_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

if [ "$garching" = true ]; then
    marley_gen_fcls=("${marley_gen_fcls_garching[@]}")
    for gen_fcl in ${marley_gen_fcls[@]}; do
        command_gen=". ${HOME_DIR}/scripts/triggersim.sh -m ${gen_fcl} -j 100407.json -f testFcl"
        echo " Running command: ${command_gen}"
        ${command_gen} 
        if [ $? -ne 0 ]; then
            echo " PROBLEM!!!! While running ${command_gen}"
            success=false
            sleep $timeout
        fi
        echo -e "FINISHED TESTING ${gen_fcl}\n"
        echo -e "________________________________________________________\n\n"
    done
fi

if [ $success = true ]; then
    echo "All tests passed!"
else
    echo "Some tests failed, look back at output or rerun."
fi

echo "________________________________________________________"

