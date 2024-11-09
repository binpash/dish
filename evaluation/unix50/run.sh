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
        "1;1_20G"
        "2;1_20G"
        "3;1_20G"
        "4;1_20G"
        "5;2_20G"
        "6;3_20G"
        "7;4_20G"
        "8;4_20G"
        "9;4_20G"
        "10;4_20G"
        "11;4_20G"
        "12;4_20G"
        "13;5_20G"
        "14;6_20G"
        "15;7_20G"
        "16;7_20G"
        "17;7_20G"
        "18;8_20G"
        "19;8_20G"
        "20;8_20G"
        "21;8_20G"
        # "22;8_20G"
        "23;9.1_20G"
        "24;9.2_20G"
        "25;9.3_20G"
        "26;9.4_20G"
        # "27;9.5_20G"
        "28;9.6_20G"
        "29;9.7_20G"
        "30;9.8_20G"
        "31;9.9_20G"
        "32;10_20G"
        "33;10_20G"
        "34;10_20G"
        "35;11_20G"
        "36;11_20G"
    )
fi

mkdir -p "outputs"
all_res_file="./outputs/unix50.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
unix50() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/unix50.res"
    > $mode_res_file

    echo executing unix50 $1 $(date) | tee -a $mode_res_file $all_res_file

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_file="./scripts/${parsed[0]}.sh"
        input_file="/unix50/${parsed[1]}.txt"
        output_file="./outputs/$1/${parsed[0]}.out"
        time_file="./outputs/$1/${parsed[0]}.time"
        log_file="./outputs/$1/${parsed[0]}.log"
        hash_file="./outputs/$1/${parsed[0]}.hash"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input_file > $output_file) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--distributed_exec"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        # Generate SHA-256 hash and delete output file
        shasum -a 256 "$output_file" | awk '{ print $1 }' > "$hash_file"
        rm "$output_file"

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}

unix50_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    basepath="/unix50"
    outputs_dir="/outputs/hadoop-streaming/unix50"
    size="20G"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"
    cd scripts/hadoop-streaming
    mode_res_file="../../outputs/hadoop/unix50.res"
    > $mode_res_file
    all_res_file="../../outputs/unix50.res"

    echo executing unix50 hadoop $(date) | tee -a $mode_res_file $all_res_file
    while IFS= read -r line; do
        if [[ ! $line =~ ^hadoop ]]; then
            continue
        fi

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
d=1

# unix50 "bash"
# unix50 "pash"        "--width 8 --r_split -d $d"
unix50 "dish"        "--width 8 --r_split -d $d --distributed_exec"

unix50 "dynamic"       "--width 8 --r_split -d $d --distributed_exec --ft dynamic"
unix50 "dynamic-m"     "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill merger"
unix50 "dynamic-r"     "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill regular"

# unix50 "naive"       "--width 8 --r_split -d $d --distributed_exec --ft naive"
# unix50 "naive-m"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill merger"
# unix50 "naive-r"     "--width 8 --r_split -d $d --distributed_exec --ft naive --kill regular"

# unix50 "base"        "--width 8 --r_split -d $d --distributed_exec --ft base"
# unix50 "base-m"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill merger"
# unix50 "base-r"      "--width 8 --r_split -d $d --distributed_exec --ft base --kill regular"

# unix50 "optimized"   "--width 8 --r_split -d $d --distributed_exec --ft optimized"
# unix50 "optimized-m" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill merger"
# unix50 "optimized-r" "--width 8 --r_split -d $d --distributed_exec --ft optimized --kill regular"

# unix50_hadoopstreaming
