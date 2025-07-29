#!/bin/bash

# Test a fcl by seeing if it dumps fine

print_help(){
    echo "Usage: $0 <fcl file>"
    echo "Test a fcl file by seeing if it dumps fine. 'all' dumps all fcls in the folder"
}

if [ $# -ne 1 ]; then
    print_help
    exit 1
fi

echo "Argument is $1"

success=true

# if argument is *, then test all fcl files in the folder
if [ $1 == "all" ]; then
    list_of_fcls=$(ls *.fcl)
    echo "Testing all fcl files in the folder:"
    echo $list_of_fcls
else
    list_of_fcls=$1
fi

check_success(){
    if [ $? -ne 0 ]; then
        success=false
        echo "Error in testing $fcl, pausing execution. CTRL+C to stop"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        sleep 20
    fi
}

for fcl in $list_of_fcls; do
    echo -e "\n====================="
    echo "Testing $fcl"
    command="fhicl-dump $fcl"
    $command
    check_success
    echo -e "=====================\n"
done

if [ $success = true ]; then
    echo "All fcls passed the test"
else
    echo "Some fcls failed the test"
fi