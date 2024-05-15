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

oneliners() {
    echo executing oneliners $1 $(date)

    mkdir -p "outputs/$1"

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
            (time $PASH_TOP/pa.sh $2 --log_file $log_file $script_file $input_file > $output_file) 2> $time_file
            # diff $output_file "./outputs/bash/${parsed[0]}.out"

            if [[ $2 == *"--kill"* ]]; then
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
                sleep 10
            fi
        fi

        echo "$script_file $(cat "$time_file")" 
    done
}

# For testing purposes
# hdfs dfs -rm -r "/outputs/hadoop-streaming/oneliners"
# hadoop jar "/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar" -files nfa-regex.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input "/oneliners/1G.txt" -output "/outputs/hadoop-streaming/oneliners/nfa-regex" -mapper nfa-regex.sh # nfa-regex
oneliners_hadoopstreaming(){
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar" # Adjust as required
    basepath="/oneliners" # Adjust as required
    times_file="hadoopstreaming.res"
    outputs_suffix="hadoopstreaming.out"
    outputs_dir="/outputs/hadoop-streaming/oneliners"
    . bi-gram.aux.sh

    cd "hadoop-streaming/"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"

    touch "$times_file"
    cat "$times_file" >> "$times_file".d
    echo executing oneliners $(date) | tee "$times_file"
    echo '' >> "$times_file"

    while IFS= read -r line; do
        printf -v pad %20s
        name=$(cut -d "#" -f2- <<< "$line")
        name=$(sed "s/ //g" <<< $name)
        padded_script="${name}.sh:${pad}"
        padded_script=${padded_script:0:20} 
        echo "${padded_script}" $({ time { eval $line &> /dev/null; } } 2>&1) | tee -a "$times_file"
    done <"run_all.sh"
    cd ".."
    mv "hadoop-streaming/$times_file" .
}

oneliners "bash"

# oneliners "pash" "--width 8 --r_split"

# oneliners "dish" "--width 8 --r_split --distributed_exec"

# oneliners "fish" "--width 8 --r_split --ft optimized --distributed_exec"

# oneliners "fish-r" "--width 8 --r_split --ft optimized --kill regular --kill_delay 100 --distributed_exec"

# oneliners "fish-m" "--width 8 --r_split --ft optimized --kill merger --kill_delay 100 --distributed_exec"

# oneliners_hadoopstreaming
