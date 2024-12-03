#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

cd "$(realpath $(dirname "$0"))"

mkdir -p hashes/small

if [[ "$@" == *"--small"* ]]; then
    hash_folder="hashes/small"
else
    hash_folder="hashes"
fi

if [[ "$@" == *"--generate"* ]]; then
    # Directory to iterate over
    if [[ "$@" == *"--dish"* ]]; then
        directory="outputs/dish"
    else
        directory="outputs/bash"
    fi

    # Loop through all .hash files in the directory
    find "$directory" -mindepth 2 -type f -name '*.hash' | while read -r file;
    do
        # Extract the dirname
        dirname=$(dirname "${file#$directory/}")

        # Create the directory in the hash folder
        mkdir -p "$hash_folder/$dirname"

        # Copy hash to the hash folder
        cp "$file" "$hash_folder/$dirname"
    done
fi

# Loop through all directories in the parent directory
for folder in "outputs"/*
do
    echo "Verifying folder: $folder"

    # Loop through all .hash files in the current directory
    find "$folder" -mindepth 2 -type f -name '*.hash' | while read -r file;
    do
        # Extract the filename and dirname
        filename=$(basename "$file" .hash)
        dirname=$(basename "$(dirname "$file")") # is the script_name
        dirname=$(dirname "${file#$folder/}")

        # Compare the hash with the hash in the hashes directory
        if ! diff "$hash_folder/$dirname/$filename.hash" "$folder/$dirname/$filename.hash";
        then
            # Print the filename and hash if they don't match
            echo "File: $dirname/$filename hash diff failed!"
        fi
    done
done
