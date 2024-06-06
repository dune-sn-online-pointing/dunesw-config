#!/bin/bash

jobs=["9869931", "9869932", "9869933", "9869934", "9869935", "9869936", "9869937", "9869938"]

for job in $jobs
do
	echo "condor_rm $job"
	eval condor_rm $job
done
