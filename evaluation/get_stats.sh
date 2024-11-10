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

    # Count evaluation scripts LOC
    find scripts -name "*.sh" -exec grep -v '^\s*#' {} + | grep -v '^\s*$' | wc -l

    cd ..
done

# Define repositories and their respective commit hashes
repos=(
    "current_repo 425e296"
    "../pash 5dee7dd9"
    "../docker-hadoop 4e09b77"
)

# Temporary file to store all modifications
all_mods="/tmp/all_mods.tsv"
> "$all_mods"  # Clear the file if it exists

for entry in "${repos[@]}"; do
    set -- $entry
    repo="$1"
    commit_hash="$2"
    
    if [ "$repo" != "current_repo" ]; then
        cd "$repo" || exit
    fi

    git diff --numstat "$commit_hash" HEAD | \
    awk 'index($3, "evaluation") == 0 {
        n = split($3, a, /\./);
        ext = a[n];
        if (ext == "" || ext == $3) ext = "no_ext";
        ins[ext] += $1;
        del[ext] += $2;
    } END {
        for (e in ins)
            printf "%s\t%d\t%d\n", e, ins[e], del[e];
    }' >> "$all_mods"

    if [ "$repo" != "current_repo" ]; then
        cd - || exit
    fi
done

# Sum the modifications per extension
awk -F'\t' '{
    ext = $1;
    ins[ext] += $2;
    del[ext] += $3;
} END {
    for (e in ins)
        printf "%s: %d insertions(+), %d deletions(-)\n", e, ins[e], del[e];
}' "$all_mods"

# Temporary file to store all modifications
all_mods="/tmp/all_mods.tsv"
> "$all_mods"  # Clear the file if it exists

for entry in "${repos[@]}"; do
    set -- $entry
    repo="$1"
    commit_hash="$2"
    
    if [ "$repo" != "current_repo" ]; then
        cd "$repo" || exit
    fi

    git diff --numstat "$commit_hash" HEAD | \
    awk 'index($3, "evaluation") != 0 {
        n = split($3, a, /\./);
        ext = a[n];
        if (ext == "" || ext == $3) ext = "no_ext";
        ins[ext] += $1;
        del[ext] += $2;
    } END {
        for (e in ins)
            printf "%s\t%d\t%d\n", e, ins[e], del[e];
    }' >> "$all_mods"

    if [ "$repo" != "current_repo" ]; then
        cd - || exit
    fi
done

# Sum the modifications per extension
awk -F'\t' '{
    ext = $1;
    ins[ext] += $2;
    del[ext] += $3;
} END {
    for (e in ins)
        printf "%s: %d insertions(+), %d deletions(-)\n", e, ins[e], del[e];
}' "$all_mods"
