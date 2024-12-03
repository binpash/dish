#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$@" == *"--small"* ]]; then
    scripts_inputs=(
        "temp-analytics;temperatures_small"
    )
else
    scripts_inputs=(
        "temp-analytics;temperatures"
    )
fi

mkdir -p "outputs"
all_res_file="./outputs/max-temp.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
max-temp() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/max-temp.res"
    > $mode_res_file

    echo executing max-temp $1 $(date) | tee -a $mode_res_file $all_res_file

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_file="./scripts/${parsed[0]}.sh"
        input_file="/max-temp/${parsed[1]}.txt"
        output_file="./outputs/$1/${parsed[0]}.out"
        time_file="./outputs/$1/${parsed[0]}.time"
        log_file="./outputs/$1/${parsed[0]}.log"
        output_dir="./outputs/$1"

        # Print input size
        hdfs dfs -du -h -s "$input_file"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input_file $output_dir > $output_file) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--distributed_exec"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file $output_dir > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        # Generate SHA-256 hash
        for file in "$output_dir"/*.out; do
            hashfile="${file%.out}.hash"
            sha256sum "$file" | awk '{print $1}' > "$hashfile"
        done

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}

max-temp_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    export jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    export infile="/max-temp/temperatures.txt"
    export outputs_dir="/outputs/hadoop-streaming/max-temp"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"
    cd scripts/hadoop-streaming
    mode_res_file="../../outputs/hadoop/max-temp.res"
    > $mode_res_file
    all_res_file="../../outputs/max-temp.res"

    echo executing max-temp hadoop $(date) | tee -a $mode_res_file $all_res_file

    # output_file="../../outputs/hadoop/temp-analytics.out"
    time_file="../../outputs/hadoop/temp-analytics.time"
    log_file="../../outputs/hadoop/temp-analytics.log"

    (time eval "./run_all.sh" &> $log_file) 2> $time_file

    cat "${time_file}" >> $all_res_file
    echo "./scripts/hadoop-streaming/temp-analytics.sh $(cat "$time_file")" | tee -a $mode_res_file

    cd "../.."
}

# adjust the debug flag as required
d=1

max-temp "bash"
max-temp "dish"             "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec"

max-temp "dynamic"          "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic"
max-temp "dynamic-m"        "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic --kill merger"
max-temp "dynamic-r"        "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic --kill regular"

# For microbenchmarks
# max-temp "dynamic-on-m"     "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic --dynamic_switch_force on --kill merger"
# max-temp "dynamic-off-m"    "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft dynamic --dynamic_switch_force off --kill merger"

max-temp_hadoopstreaming
