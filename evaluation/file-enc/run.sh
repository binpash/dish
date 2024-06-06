#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$1" == "--small" ]]; then
    echo "Using small input"
    # input_file="/file-enc/in_small.csv"
else
    echo "Using default input"
    input="/file-enc/"
fi

scripts=(
    "compress_files"
    "encrypt_files"
)

mkdir -p "outputs"
all_res_file="./outputs/file-enc.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
file-enc() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/file-enc.res"
    > $mode_res_file

    echo executing file-enc $1 $(date) | tee -a $mode_res_file $all_res_file

    for script in ${scripts[@]}
    do
        script_file="./scripts/$script.sh"
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input $output_dir > $output_file ) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--ft"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input $output_dir > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}

# file-enc_hadoopstreaming() {
#     # used by run_all.sh, adjust as required
#     jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
#     outputs_dir="/outputs/hadoop-streaming/file-enc"

#     hdfs dfs -rm -r "$outputs_dir"
#     hdfs dfs -mkdir -p "$outputs_dir"
#     mkdir -p "outputs/hadoop"
#     cd scripts/hadoop-streaming
#     mode_res_file="../../outputs/hadoop/file-enc.res"
#     > $mode_res_file
#     all_res_file="../../outputs/file-enc.res"

#     echo executing file-enc hadoop $(date) | tee -a $mode_res_file $all_res_file
#     while IFS= read -r line; do
#         name=$(cut -d "#" -f2- <<< "$line")
#         name=$(sed "s/ //g" <<< $name)

#         # output_file="../../outputs/hadoop/$name.out"
#         time_file="../../outputs/hadoop/$name.time"
#         log_file="../../outputs/hadoop/$name.log"

#         (time eval $line &> $log_file) 2> $time_file

#         cat "${time_file}" >> $all_res_file
#         echo "./scripts/hadoop-streaming/$name.sh $(cat "$time_file")" | tee -a $mode_res_file

#     done <"run_all.sh"

#     cd "../.."
# }

# adjust the debug flag as required
d=0

file-enc "bash"
file-enc "pash"        "--width 8 --r_split -d $d --parallel_pipelines --profile_driven"
file-enc "dish"        "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24"

# file-enc "naive"       "--width 8 --r_split -d $d --distributed_exec --ft naive"
# file-enc "naive-m"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill merger"
# file-enc "naive-r"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill regular"

# file-enc "base"        "--width 8 --r_split -d $d --distributed_exec --ft base"
# file-enc "base-m"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill merger"
# file-enc "base-r"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill regular"

# file-enc "optimized"   "--width 8 --r_split -d $d --distributed_exec --ft optimized"
# file-enc "optimized-m" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill merger"
# file-enc "optimized-r" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill regular"

# file-enc_hadoopstreaming

