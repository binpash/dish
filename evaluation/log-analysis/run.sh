#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

names_scripts=(
    "LogAnalysis1;nginx"
    "LogAnalysis2;pcaps"
  )

if [[ "$@" == *"--small"* ]]; then
    scripts_inputs=(
        "nginx;/log-analysis/log_data_small"
        "pcaps;/log-analysis/pcap_data_small"
    )
    scripts_outputs=(
        "nginx;/log-analysis/nginx_analysis_small"
        "pcaps;/log-analysis/pcap_analysis_small"
    )
else
    scripts_inputs=(
        "nginx;/log-analysis/log_data"
        "pcaps;/log-analysis/pcap_data"
    )
    scripts_outputs=(
        "nginx;/log-analysis/nginx_analysis"
        "pcaps;/log-analysis/pcap_analysis"
    )
fi

parse_directories() {
    local script_name=$1
    local scripts_array=("${!2}")
    for entry in "${scripts_array[@]}"; do
        IFS=";" read -r -a parsed <<< "${entry}"
        if [[ "${parsed[0]}" == "${script_name}" ]]; then
            echo "${parsed[1]}"
            return
        fi
    done
}

mkdir -p "outputs"
all_res_file="./outputs/log-analysis.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
log-analysis() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/log-analysis.res"
    > $mode_res_file

    echo executing log-analysis $1 $(date) | tee -a $mode_res_file $all_res_file
    for name_script in ${names_scripts[@]}
    do
        IFS=";" read -r -a name_script_parsed <<< "${name_script}"
        name="${name_script_parsed[0]}"
        script="${name_script_parsed[1]}"
        script_file="./scripts/$script.sh"
        input_dir=$(parse_directories "$script" scripts_inputs[@])
        output_dir=./outputs/$1$(parse_directories "$script" scripts_outputs[@])
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"
        hash_file="./outputs/$1/$script.hash"
        mkdir -p $output_dir

        # Print input size
        hdfs dfs -du -h -s "$input_dir"

        if [[ "$1" == "bash" ]]; then
            (time $script_file $input_dir $output_dir > $output_file) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--distributed_exec"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_dir $output_dir > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        # For every file in output_dir, generate a hash and delete the file
        for file in "$output_dir"/*.out
        do
            # Extract the filename without the directory
            filename=$(basename "$file")

            # Generate SHA-256 hash and delete output file
            shasum -a 256 "$file" | awk '{ print $1 }' > "$output_dir/$filename.hash"
            rm "$file"
        done

        # Delete the output directory, this is useful because otherwise the 
        # output files will be appended to the existing files, if we don't delete manually
        rm -r $output_dir

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}


# adjust the debug flag as required
d=1

log-analysis "bash"
log-analysis "dish"          "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec"

log-analysis "dynamic"       "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic"
log-analysis "dynamic-m"     "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic --kill merger"
log-analysis "dynamic-r"     "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic --kill regular"
