#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$@" == *"--small"* ]]; then
    scripts_inputs=(
        "nfa-regex;1M"
        "sort;1M"
        "top-n;1M"
        "wf;1M"
        "spell;1M"
        "diff;1M"
        "bi-grams;1M"
        "set-diff;1M"
        "sort-sort;1M"
        "shortest-scripts;all_cmds"
    )
else
    scripts_inputs=(
        "nfa-regex;1G"
        "sort;3G"
        "top-n;3G"
        "wf;3G"
        "spell;3G"
        "diff;3G"
        "bi-grams;3G"
        "set-diff;3G"
        "sort-sort;3G"
        "shortest-scripts;all_cmdsx100"
    )
fi

mkdir -p "outputs"
all_res_file="./outputs/oneliners.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
oneliners() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/oneliners.res"
    > $mode_res_file

    echo executing oneliners $1 $(date) | tee -a $mode_res_file $all_res_file

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_file="./scripts/${parsed[0]}.sh"
        input_file="/oneliners/${parsed[1]}.txt"
        output_file="./outputs/$1/${parsed[0]}.out"
        time_file="./outputs/$1/${parsed[0]}.time"
        log_file="./outputs/$1/${parsed[0]}.log"

        if [[ "$1" == "bash" ]]; then
            (time $script_file $input_file > $output_file) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--ft"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}

oneliners_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    basepath="/oneliners"
    outputs_dir="/outputs/hadoop-streaming/oneliners"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"
    mode_res_file="./outputs/hadoop/oneliners.res"
    > $mode_res_file

    source ./scripts/bi-gram.aux.sh
    cd scripts/hadoop-streaming

    echo executing oneliners hadoop $(date) | tee -a $mode_res_file $all_res_file
    while IFS= read -r line; do
        name=$(cut -d "#" -f2- <<< "$line")
        name=$(sed "s/ //g" <<< $name)

        # output_file="../../outputs/hadoop/$name.out"
        time_file="../../outputs/hadoop/$name.time"
        log_file="../../outputs/hadoop/$name.log"

        (time eval $line &> $log_file) 2> $time_file

        cat "${time_file}" >> $all_res_file
        echo "./scripts/hadoop-streaming/$name.sh $(cat "$time_file")" | tee -a $mode_res_file
    done <"run_all.sh"

    cd "../.."
}

# adjust the debug flag as required
d=0

oneliners "bash"
# oneliners "pash"        "--width 8 --r_split -d $d"
# oneliners "dish"        "--width 8 --r_split -d $d --distributed_exec"

# oneliners "naive"       "--width 8 --r_split -d $d --distributed_exec --ft naive"
# oneliners "naive-m"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill merger"
# oneliners "naive-r"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill regular"

# oneliners "base"        "--width 8 --r_split -d $d --distributed_exec --ft base"
# oneliners "base-m"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill merger"
# oneliners "base-r"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill regular"

# oneliners "optimized"   "--width 8 --r_split -d $d --distributed_exec --ft optimized"
# oneliners "optimized-m" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill merger"
# oneliners "optimized-r" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill regular"

# oneliners_hadoopstreaming
