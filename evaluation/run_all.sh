#!/bin/bash

# Loop through each directory in the current folder
for dir in */; do
    # Remove trailing slash from the directory name
    dir=${dir%/}
    
    # Skip the 'distr_benchmarks' directory
    if [ "$dir" == "distr_benchmarks" ]; then
        continue
    fi

    # # Skip the 'log-analysis' for now
    # if [ "$dir" == "log-analysis" ]; then
    #     continue
    # fi
    
    # Change to the directory
    cd "./$dir" || continue

    # Run the evaluation scripts
    ./cleanup.sh
    ./inputs.sh
    sleep 30
    ./run.sh

    # Generate and verify hashes
    rm -rf hashes/
    mkdir -p "../outputs/$dir"
    ./verify.sh --generate --dish > ../outputs/$dir/verify.out

    # Move the outputs to the corresponding directory in ../outputs
    mv outputs/* "../outputs/$dir"

    # Cleanup
    ./cleanup.sh
    sleep 30

    # Go back to the parent directory
    cd ..
done
