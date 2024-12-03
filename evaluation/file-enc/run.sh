#!/bin/bash

export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"
eval_dir="./scripts"

if [[ "$1" == "--small" ]]; then
    echo "Using small input"
    input_dir="/file-enc/pcap_data_small"
else
    echo "Using default input"
    input_dir="/file-enc/pcap_data"
fi


names_scripts=(
    "FileEnc1;compress_files"
    "FileEnc2;encrypt_files"
  )

mkdir -p "outputs"
all_res_file="./outputs/file-enc.res"
> $all_res_file

file-enc() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/file-enc.res"
    > $mode_res_file

    echo executing file-enc $1 $(date) | tee -a $mode_res_file $all_res_file
    for name_script in ${names_scripts[@]}
    do
        IFS=";" read -r -a name_script_parsed <<< "${name_script}"
        name="${name_script_parsed[0]}"
        script="${name_script_parsed[1]}"
        script_file="./scripts/$script.sh"
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"
        hash_file="./outputs/$1/$script.hash"

        # Print input size
        hdfs dfs -du -h -s "$input_dir"

        # output_file contains "done" when run successfully. The real outputs are under output_dir/
        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input_dir $output_dir > $output_file ) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--ft"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_dir $output_dir > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        rm -rf "$output_dir"
        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}

d=1

file-enc "bash"
file-enc "dish"          "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24"

file-enc "dynamic"       "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic"
file-enc "dynamic-m"     "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic --kill merger"
file-enc "dynamic-r"     "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic --kill regular"
