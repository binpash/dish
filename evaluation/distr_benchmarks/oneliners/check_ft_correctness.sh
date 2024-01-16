#!/bin/bash

# Specify the folder where the .out files are located
folder="$DISH_TOP/evaluation/distr_benchmarks/oneliners/outputs"

# Loop through the files in the folder
for script_faults_out in "$folder"/*faults.out; do
    # Extract the script name without the extension
    script_name=$(basename "$script_faults_out" .faults.out)

    # Check if there is a corresponding .distr.out file
    script_distr_out="$folder/$script_name.distr.out"

    if [ -f "$script_distr_out" ]; then
        # Perform a diff between the two files
        echo "Comparing faults_out and distr_out for script $script_name.sh"
        if diff -q "$script_faults_out" "$script_distr_out"; then
            echo "Outputs are identical"
        else
            echo "Files are different. Differences are as follows:"
            diff -y "$script_faults_out" "$script_distr_out"
        fi
        echo "-------------------------------------------"
    fi
done
