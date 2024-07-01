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

## run-sn-simulation.sh

This script is the only interface that is needed in order to run a simulation and print TPs to file.
The only thing that needs to be changed is the file `scripts/settings.json`, which contains the local path and the email of the user (needed to generate the submit files).

All the rest is taken care of by the different scripts. 