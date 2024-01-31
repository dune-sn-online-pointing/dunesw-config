#!/bin/bash

# This script generates a random direction for the neutrino SN explosion

# Function to generate a random number between 0 and 1
function generate_random_number() {
    echo $(awk -v min=0 -v max=1 -v seed=$RANDOM 'BEGIN{srand(seed); print min+rand()*(max-min)}')
}

# Generate random numbers for x, y, and z
random_x=$(generate_random_number)
echo $random_x
random_y=$(generate_random_number)
echo $random_y
random_z=$(generate_random_number)
echo $random_z

# Normalize the vector to ensure its total length is 1
echo "Normalizing vector..."
length=$(awk "BEGIN {print sqrt($random_x^2 + $random_y^2 + $random_z^2)}")
normalized_x=$(awk "BEGIN {print $random_x / $length}")
echo $normalized_x
normalized_y=$(awk "BEGIN {print $random_y / $length}")
echo $normalized_y
normalized_z=$(awk "BEGIN {print $random_z / $length}")
echo $normalized_z

# Create an output textfile with these three numbers
echo "Saving normalized vector to file..."
echo "$normalized_x $normalized_y $normalized_z" > this_custom_direction.txt

# read the argument from command line and save it as original_fcl. If no argument, stop execution
if [[ "$1" != -* ]]; then
    original_fcl="$1"
    echo "Generating custom direction fcl using fcl file: $original_fcl"
else
    echo "No fcl file provided. Exiting..."
    exit 1
fi

# Create the .fcl file with the random values, adding a suffix and .fcl to original_fcl
# move that file to here just to avoid parsing problems
cp /afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config/fcl/${original_fcl}.fcl .
filename="${original_fcl%.*}_customDirection.fcl"
cat <<EOF > $filename
#include "${original_fcl}.fcl"

physics: {
    producers: {
        marley: {
            marley_parameters: {
                direction: {
                    x: $normalized_x
                    y: 0
                    z: $normalized_z
                }
            }
        }
    }
}
EOF

echo "Generated file: $filename"
