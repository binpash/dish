#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$1" == "--small" ]]; then
    echo "Using small input"
    # input_file="/log-analysis/in_small.csv"
else
    echo "Using default input"
    input_file="/log-analysis/network.pcap"
fi

scripts=(
    "pcaps_analysis"
)

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

    for script in ${scripts[@]}
    do
        script_file="./scripts/$script.sh"
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input_file > $output_file ) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--ft"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file > $output_file) 2> $time_file

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

# log-analysis_hadoopstreaming() {
#     # used by run_all.sh, adjust as required
#     jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
#     outputs_dir="/outputs/hadoop-streaming/log-analysis"

#     hdfs dfs -rm -r "$outputs_dir"
#     hdfs dfs -mkdir -p "$outputs_dir"
#     mkdir -p "outputs/hadoop"
#     cd scripts/hadoop-streaming
#     mode_res_file="../../outputs/hadoop/log-analysis.res"
#     > $mode_res_file
#     all_res_file="../../outputs/log-analysis.res"

#     echo executing log-analysis hadoop $(date) | tee -a $mode_res_file $all_res_file
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

log-analysis "bash"
log-analysis "pash"        "--width 8 --r_split -d $d"
log-analysis "dish"        "--width 8 --r_split -d $d --distributed_exec"

# log-analysis "naive"       "--width 8 --r_split -d $d --distributed_exec --ft naive"
# log-analysis "naive-m"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill merger"
# log-analysis "naive-r"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill regular"

# log-analysis "base"        "--width 8 --r_split -d $d --distributed_exec --ft base"
# log-analysis "base-m"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill merger"
# log-analysis "base-r"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill regular"

# log-analysis "optimized"   "--width 8 --r_split -d $d --distributed_exec --ft optimized"
# log-analysis "optimized-m" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill merger"
# log-analysis "optimized-r" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill regular"

# log-analysis_hadoopstreaming

