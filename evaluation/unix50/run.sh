#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$@" == *"--small"* ]]; then
    scripts_inputs=(
        "1;1_1M"
        "2;1_1M"
        "3;1_1M"
        "4;1_1M"
        "5;2_1M"
        "6;3_1M"
        "7;4_1M"
        "8;4_1M"
        "9;4_1M"
        "10;4_1M"
        "11;4_1M"
        "12;4_1M"
        "13;5_1M"
        "14;6_1M"
        "15;7_1M"
        "16;7_1M"
        "17;7_1M"
        "18;8_1M"
        "19;8_1M"
        "20;8_1M"
        "21;8_1M"
        # "22;8_1M"
        "23;9.1_1M"
        "24;9.2_1M"
        "25;9.3_1M"
        "26;9.4_1M"
        # "27;9.5_1M"
        "28;9.6_1M"
        "29;9.7_1M"
        "30;9.8_1M"
        "31;9.9_1M"
        "32;10_1M"
        "33;10_1M"
        "34;10_1M"
        "35;11_1M"
        "36;11_1M"
    )
else
        scripts_inputs=(
        "1;1_3G"
        "2;1_3G"
        "3;1_3G"
        "4;1_3G"
        "5;2_3G"
        "6;3_3G"
        "7;4_3G"
        "8;4_3G"
        "9;4_3G"
        "10;4_3G"
        "11;4_3G"
        "12;4_3G"
        "13;5_3G"
        "14;6_3G"
        "15;7_3G"
        "16;7_3G"
        "17;7_3G"
        "18;8_3G"
        "19;8_3G"
        "20;8_3G"
        "21;8_3G"
        # "22;8_3G"
        "23;9.1_3G"
        "24;9.2_3G"
        "25;9.3_3G"
        "26;9.4_3G"
        # "27;9.5_3G"
        "28;9.6_3G"
        "29;9.7_3G"
        "30;9.8_3G"
        "31;9.9_3G"
        "32;10_3G"
        "33;10_3G"
        "34;10_3G"
        "35;11_3G"
        "36;11_3G"
    )
fi

mkdir -p "outputs"

unix50() {
    echo executing unix50 $1 $(date)

    mkdir -p "outputs/$1"

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_file="./scripts/${parsed[0]}.sh"
        input_file="/unix50/${parsed[1]}.txt"
        output_file="./outputs/$1/${parsed[0]}.out"
        time_file="./outputs/$1/${parsed[0]}.time"
        log_file="./outputs/$1/${parsed[0]}.log"

        if [[ "$1" == "bash" ]]; then
            (time $script_file $input_file > $output_file) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--ft optimized"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file > $output_file) 2> $time_file
            # diff $output_file "./outputs/bash/${parsed[0]}.out"

            if [[ $2 == *"--kill"* ]]; then
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        echo "$script_file $(cat "$time_file")" 
    done
}

unix50_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    basepath="/unix50"
    outputs_dir="/outputs/hadoop-streaming/unix50"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"

    source ./scripts/bi-gram.aux.sh
    cd scripts/hadoop-streaming

    echo executing unix50 hadoop $(date)
    while IFS= read -r line; do
        name=$(cut -d "#" -f2- <<< "$line")
        name=$(sed "s/ //g" <<< $name)

        # output_file="../../outputs/hadoop/$name.out"
        time_file="../../outputs/hadoop/$name.time"
        log_file="../../outputs/hadoop/$name.log"

        (time eval $line &> $log_file) 2> $time_file

        echo "./scripts/hadoop-streaming/$name.sh $(cat "$time_file")" 
    done <"run_all.sh"

    cd "../.."
}

unix50 "bash"

# unix50 "pash" "--width 8 --r_split"

# unix50 "dish" "--width 8 --r_split --distributed_exec"

# unix50 "fish" "--width 8 --r_split --ft optimized --distributed_exec"

# unix50 "fish-m" "--width 8 --r_split --ft optimized --kill merger --distributed_exec"

# unix50 "fish-r" "--width 8 --r_split --ft optimized --kill regular --distributed_exec"

# unix50_hadoopstreaming
