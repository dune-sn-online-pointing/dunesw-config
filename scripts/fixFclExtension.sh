#!/bin/bash

# print help
function print_help() {
    echo "*****************************************************************************"
    echo "Usage: $0 -f fcl_file # (with or without extension)"
    echo "*****************************************************************************"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--fcl-file) fcl_file="$2"; shift ;;
        -h|--help) print_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# if no fcl file is provided, stop execution
if [[ -z "$fcl_file" ]]; then
    echo "No fcl file provided: $fcl_file. Exiting..."
    exit 1
fi

# if the fcl file has no extension, add it
if [[ "$fcl_file" != *".fcl" ]]; then
    fcl_file="${fcl_file}.fcl"
fi  

echo "Added extension in case it was not there:"
echo "$fcl_file"
