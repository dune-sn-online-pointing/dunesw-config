# dunesw-config
Config to run the simulation to generate TPs from offline, plus some other tools.

These are all bash and python scripts, no installation is needed.  

## Production footpring

These are some scripts to run some simulations to validate a pipeline in sight of a possible production.
This has been done for a trigger production, but things should be general enough to be adaptable to anything.

On FNAL cluster, the jobs don't take too long to run, so there is no need to submit jobs. 
The list of simulations is under `dat/triggerValidation_fcls.dat`. 
All jobs above the separator will be considered by the scripts, one can add or remove (by moving the separator) the jobs to run.
To run the simulations (recommended 10 events, default), one can use:

```bash
  ./trigger_production/validation-sims.sh -j <json_settings_file> [-n <number_of_events>]
```

This is a wrapper around the script `scripts/triggersims.sh`, using the fcls in the dat file.
The only thing to do is create a json settings file and put it under `json/`. 
It's enough to specify the dunesw version and, only if you installed a dunesw version locally, the local install path.
The printout during job execution will be in `trigger_production/`, which is the input folder for the next step.
You can also run the script to get a printout of the commands with -p, and run the commands separately if you want to do so.

To extract the footprint of the simulations from the txt files just produced, you can use the python script `scripts/computeFootprint.py` or, easier, the script to do it for all simulations automatically (looking again at the same dat file):

```bash
  ./trigger_production/allFootprints.sh 
```
The output will be in `trigger_production/footprintSummary.txt`.

## create_random_directions

In here there is a script that can create a catalog of random directions. 
It accepts the name of a fcl file as input, and it will create a new fcl that includes the original one and just overwrites the direction of the SN burst.
It also prints out the direction in a simple txt file, in case it's easier to have a catalog like that.
Usage, visible with the -h option, is
    
```bash
./create_random_directions.sh -f <fcl_file> -n <number_of_directions> [-o <output_dir>] [-v]
```

## dunesw (aka larsoft) and setting up

In order for this to run, you need to have a local install of the dune software and add the path of your install in the `scripts/settings.json` file.
You can install following these [instructions](https://docs.google.com/document/d/14ORCEtpXWSIT_1hXJxtW2PMGMVWozzRK1GxgPKaptCk/edit) or the larsoft tutorial from the workshop in Feb '25.
In the code folder, also set up a script called `setup.sh` that has to be similar to this one (remember to set your path):

```bash
#!/bin/bash

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

version="v10_04_04"
extension="d01" 
export DUNESW_VERSION=$version$extension; # this is what Klaudia used to test the workflow
qualifier="e26"
specifier="prof"
export DUNESW_QUALIFIER=${qualifier}:${specifier}

source /afs/cern.ch/work/e/evilla/private/dune/dunesw/$DUNESW_VERSION/localProducts_larsoft_${version}_${qualifier}_${specifier}/setup # this will be the setup in your local installation
THIS_PWD=$PWD
cd $MRB_BUILDDIR
mrbslp

echo 'Setting up dunesw version' $DUNESW_VERSION', qualifier' $DUNESW_QUALIFIER '...'
setup dunesw $DUNESW_VERSION -q $DUNESW_QUALIFIER

echo 'Done!'
cd $THIS_PWD # go back where we were
```
    
To run lar, you need a centos7 environment or run in condor (selecting the environment to run in). 
You can use a container by running:

```bash
/cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer shell --shell=/bin/bash -B /cvmfs,/opt,/run/user,/etc/hostname,/etc/hosts,/etc/krb5.conf,/eos --ipc --pid /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest
```

See the sub scripts or file under `condor/` for different examples or the ready-to-use scripts.

## Run the simulation 

This script is the only interface that is needed in order to run a simulation and print TPs to file.
The only thing that needs to be changed is a json settings file that you should create copying `json/settings_template.json`:
```bash
cp json/settings_template.json json/mySettings.json # or any name you like
```

It contains the local path, user and the email of the user (needed to generate the submit files). 
Your file will be gitignored, so don't worry about having your path in it.

I also set up some sub-folders in the `scripts` and `condor` directories, so that everybody can develop additional stuff without conflicting with others.

The script should be easy to read, but to summarize what it does:

- **Reads options from the command line**: Parses command-line arguments to determine which simulation stages to run and with what configurations.
- **Sets up the environment**: Sources necessary scripts and configurations to prepare the environment for the simulations.
- **Executes selected simulation stages**:
  - **Marley Generation**: Runs the Marley generation simulation.
  - **Geant4 Simulation**: Performs Geant4 simulations if specified.
  - **Detector Simulation**: Runs detector simulations as needed.
  - **Reconstruction**: Executes event reconstruction processes.
- **Handles custom configurations**:
  - **Custom Direction**: Generates a custom direction configuration if specified.
  - **Custom Energy**: Sets up custom energy binning if required.
  - **Combination of Custom Direction and Energy**: Configures both custom direction and energy ranges if both are selected.
- **Manages output directories**: Creates and organizes output directories, optionally cleaning them before starting.
- **Cleans up files**: Deletes intermediate files to save space if specified.
- **Saves results**: Moves the final results to a predefined directory for further analysis. The output is currently set to be `/eos/user/e/evilla/sn-data`, don't change it.

An example of how to run is (use -h to see all options):
    
```bash
./triggersim.sh -j mySettings.json --home-config /my/dunesw-config/ -m [<gen_fcl>] -g [<g4_fcl>] -d [<detsim_fcl>] -r [<reco1_fcl>] -n 10 -f test
```

There is also a `protoduneana.sh` that works similarly but in a simplified way and can accept also a data file as input.

## Running in HTCondor

Running locally is ok for testing and small simulations, but for large ones always use HTCondor.
There are several examples here, but more scripts will be created in order to run different types of simulations in a more automated manner.

The script `condor/submit_pointing_training_ES_70MeV_noiseless.sh` is set up for what the name says.
See the usage with -h, it's should be simple to use. 
