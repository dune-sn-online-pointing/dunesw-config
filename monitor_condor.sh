#!/bin/bash

# repeat 100 times
for i in {1..1000}
do
    # see status
    condor_q
    # wait for 5 seconds
    sleep 5;
done