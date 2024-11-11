#!/bin/bash

# Absolute path to the outputs directory
output_dir="$(pwd)/outputs"

# Remove and recreate the outputs directory
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"
fi
mkdir -p "$output_dir"

# List of directories to process, you can comment out any directory as needed
dirs=(
    "oneliners"
    "unix50"
    "covid-mts" 
    "nlp"
    "max-temp"
    "media-conv"
    "log-analysis"
    "file-enc"
)

# Initialize output files
exec > >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.out")
exec 2> >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.err" >&2)

# Start timing the script
start_time=$(date +%s)

# Loop through each directory in the list
for dir in "${dirs[@]}"; do
    # Change to the directory
    cd "./$dir" || continue

    # Run the evaluation scripts
    ./cleanup.sh
    sleep 10
    ./inputs.sh
    sleep 600
    ./run.sh

    # Generate and verify hashes
    rm -rf hashes/
    mkdir -p "$output_dir/$dir"
    ./verify.sh --generate --dish | tee "$output_dir/$dir/verify.out"

    # Move the outputs to the corresponding directory in $output_dir
    mv outputs/* "$output_dir/$dir"

    # Cleanup
    ./cleanup.sh
    sleep 600

    # Go back to the parent directory
    cd ..
done

# End timing the script
end_time=$(date +%s)
duration=$((end_time - start_time))

# Save the duration to run_all.time
echo "Total execution time: $duration seconds" | tee -a "$output_dir/run_all.time"
