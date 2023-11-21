# dunesw-config
Config to run the simulation to generate TPs from offline.

Still work in progress, and this is ok only if you installed the local products. 
I'll link the instructions.

However, the idea is:
- use `source source-dunesw.sh` to source the environment in every new bash session
- use `source source-here.sh` to compile and link the local repos. Flag -c also compiles, -z adds new targets you might have added under srcs/
- use `run-sn-simulation.sh' (executable) with the different flags to run different steps of the analysis.

