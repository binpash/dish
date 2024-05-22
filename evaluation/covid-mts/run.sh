#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"


if [[ "$1" == "--small" ]]; then
    echo "Using small input"
    input_file="/covid-mts/in_small.csv"
else
    echo "Using default input"
    input_file="/covid-mts/in.csv"
fi

mkdir -p "outputs"


covid-mts() {
    echo executing covid-mts $1 $(date)

    mkdir -p "outputs/$1"

    for number in `seq 4` ## initial: FIXME 5.sh is not working yet
    do
        script="${number}"
        script_file="./scripts/$script.sh"
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input_file > $output_file ) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--ft optimized"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
                sleep 10
            fi
        fi

        echo "$name $script_file $(cat "$time_file")" 
    done
}

# Havn't tried this yet
# covid-mts_hadoopstreaming(){
#   jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar" # Adjust as required
#   times_file="hadoopstreaming.res"
#   outputs_suffix="hadoopstreaming.out"
#   outputs_dir="/outputs/hadoop-streaming/analytics-mts"

#   cd "hadoop-streaming/"

#   hdfs dfs -rm -r "$outputs_dir"
#   hdfs dfs -mkdir -p "$outputs_dir"

#   touch "$times_file"
#   cat "$times_file" >> "$times_file".d
#   echo executing covid-mts $(date) | tee "$times_file"
#   echo '' >> "$times_file"

#   COUNTER=1
#   while IFS= read -r line; do
#       printf -v pad %20s
#       padded_script="${COUNTER}.sh:${pad}"
#       padded_script=${padded_script:0:20}

#       echo "${padded_script}" $({ time { eval $line &> /dev/null; } } 2>&1) | tee -a "$times_file"
#       COUNTER=$(( COUNTER + 1 ))
#   done <"run_all.sh"
#   cd ".."
#   mv "hadoop-streaming/$times_file" .
# }


covid-mts "bash"

covid-mts "pash" "--width 8 --r_split"

covid-mts "dish" "--width 8 --r_split --distributed_exec"

covid-mts "fish" "--width 8 --r_split --ft optimized --distributed_exec"

covid-mts "fish-r" "--width 8 --r_split --ft optimized --kill regular --distributed_exec"

covid-mts "fish-m" "--width 8 --r_split --ft optimized --kill merger --distributed_exec"

# tmux new-session -s covid_mts "./run.sh | tee covid_mts_log"