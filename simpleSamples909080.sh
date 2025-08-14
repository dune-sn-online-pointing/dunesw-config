clear; 

./scripts/triggersim.sh -m prodmarley_nue_es_flat_dune10kt_1x2x2 --custom-energy 29 30 -g -d -r  -j ev.json -n 10 -f cleanES60

./scripts/triggersim.sh -m prodmarley_nue_cc_flat_dune10kt_1x2x2 --custom-energy 29 30 -g -d -r  -j ev.json -n 10 -f cleanCC60

./scripts/triggersim.sh -m prodmarley_nue_es_flat_radiological_decay0_dune10kt_1x2x2_centralAPA --custom-energy 29 30 -g -d -r  -j ev.json -n 10 -f bkgES60

./scripts/triggersim.sh -m prodmarley_nue_cc_flat_radiological_decay0_dune10kt_1x2x2_centralAPA --custom-energy 29 30 -g -d -r  -j ev.json -n 10 -f bkgCC60
