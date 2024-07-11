# dunesw-config
Config to run the simulation to generate TPs from offline, plus some other tools.

These are all bash and python scripts, no installation is needed.  

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
You can install following these [instructions](https://docs.google.com/document/d/14ORCEtpXWSIT_1hXJxtW2PMGMVWozzRK1GxgPKaptCk/edit).
For the TP SN analysis, you need to install locally the `duneana` repo and then check out to the branch `evilla/tpstream`.
In the code folder, also set up a script called `setup-dunesw.sh` that has to be similar to this one (remember to set your path):

```bash
#!/bin/bash

echo 'Setting up dune products...'
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

echo 'Setting up local products...'
source /your/install/path/localProducts_larsoft_v09_79_00d02_prof_e26/setup

cd $MRB_BUILDDIR
mrbslp

export DUNESW_VERSION=v09_79_00d02; 
export DUNESW_QUALIFIER=e26:prof;
echo 'Setting up dunesw version' $DUNESW_VERSION', qualifier' $DUNESW_QUALIFIER '...'
setup dunesw $DUNESW_VERSION -q $DUNESW_QUALIFIER
echo 'Done!'

cd .. # going back to the home directory
```
    
To run lar, you need a centos7 environment or run in condor (selecting the environment to run in). 
You can use a container by running:

```bash
/cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer shell --shell=/bin/bash -B /cvmfs,/opt,/run/user,/etc/hostname,/etc/hosts,/etc/krb5.conf, /eos/user/ --ipc --pid /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest
```

See the sub scripts or file under `condor/` for different examples or the ready-to-use scripts.

## run-sn-simulation.sh

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

An example of how to run is:
    
```bash
./run-sn-simulation.sh -j mySettings.json --home-config /my/dunesw-config/ -m --custom-direction -g -d -r -n 10 -f test
```

## Running in HTCondor

Running locally is ok for testing and small simulations, but for large ones always use HTCondor.
There are several examples here, but more scripts will be created in order to run different types of simulations in a more automated manner.

The script `condor/submit_pointing_training_ES_70MeV_noiseless.sh` is set up for what the name says.
See the usage with -h, it's should be simple to use. 
See the Google sheet to know what samples you are supposed to produce.
