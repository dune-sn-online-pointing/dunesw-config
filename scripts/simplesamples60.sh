clear; 

# ./scripts/triggersim.sh -m prodmarley_nue_es_flat_dune10kt_1x2x2 --custom-energy 29 30 -g -d -r triggerana_tree_1x2x2_simpleThr60_allPlanes -j 101002d00.json -n 10 -f cleanES60

# ./scripts/triggersim.sh -m prodmarley_nue_cc_flat_dune10kt_1x2x2 --custom-energy 29 30 -g -d -r triggerana_tree_1x2x2_simpleThr60_allPlanes -j 101002d00.json -n 10 -f cleanCC60

# ./scripts/triggersim.sh -m esflatBkgCentral --custom-energy 29 30 -g -d -r triggerana_tree_1x2x2_simpleThr60_allPlanes -j 101002d00.json -n 10 -f bkgES60

./scripts/triggersim.sh -m ccflatBkgCentral --custom-energy 29 30 -g -d -r triggerana_tree_1x2x2_simpleThr60_allPlanes -j 101002d00.json -n 10 -f bkgCC60
