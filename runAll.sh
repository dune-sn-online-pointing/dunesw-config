echo "GENIA";./scripts/triggersim.sh -m prodgenie_nue_dune10kt_1x2x6.fcl -g standard_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f genieNuE_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > genienue.txt

echo "CENTRALAPA";./scripts/triggersim.sh -m prodbackground_radiological_decay0_dune10kt_1x2x6_centralAPA.fcl -g supernova_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f radBkgCentralAPA_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > radBkgCentralAPA.txt


echo "LATERALAPA";./scripts/triggersim.sh -m prodbackground_radiological_decay0_dune10kt_1x2x6_lateralAPA.fcl -g supernova_g4_halfActiveVol_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f radBkgLateralAPA_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > radBkgLateralAPA.txt

echo "SINGLEE";./scripts/triggersim.sh -m prod_eminus_1-500MeV_dune10kt_1x2x6.fcl -g standard_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f singleElectrons_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > singleElectrons.txt

echo "SINGLEGAMMA";./scripts/triggersim.sh -m prod_gamma_1-500MeV_dune10kt_1x2x6.fcl -g standard_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f singleGammas_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > singleGammas.txt

echo "SINGLEMUONS";./scripts/triggersim.sh -m prod_muminus_1-500MeV_dune10kt_1x2x6.fcl -g standard_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f singleMuons_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > singleMuons.txt

echo "SINGLEPROTONS";./scripts/triggersim.sh -m prod_p_1-500MeV_dune10kt_1x2x6.fcl -g standard_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f singleProtons_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > singleProtons.txt

echo "SNCC";./scripts/triggersim.sh -m prodmarley_nue_flat_CC_dune10kt_1x2x6_dump.fcl -g supernova_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f supernovaCC_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > supernovaCC.txt

echo "SNES";./scripts/triggersim.sh -m prodmarley_nue_flat_ES_dune10kt_1x2x6_dump.fcl -g supernova_g4_dune10kt_1x2x6.fcl -d detsim_dune10kt_1x2x6_notpcsigproc.fcl -r triggerana_tree_1x2x6_simpleThr_simpleWin_simpleWin.fcl -j 100405.json -f supernovaES_triggerValidationTest -n 5 --home-config /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config > supernovaES.txt
