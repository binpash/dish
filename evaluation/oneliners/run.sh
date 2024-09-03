#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$@" == *"--small"* ]]; then
    scripts_inputs=(
        "nfa-regex;1M"
        # "sort;1M"
        # "top-n;1M"
        # "wf;1M"
        # "spell;1M"
        # "diff;1M"
        # "bi-grams;1M"
        # "set-diff;1M"
        # "sort-sort;1M"
        # "shortest-scripts;all_cmds"
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
        "shortest-scripts;all_cmdsx1000"
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

kill() {
    sleep_time=$1
    target_node=$2
    echo "Will inject failure to $target_node after $sleep_time"
    sleep $sleep_time
    python3 "$DISH_TOP/evaluation/notify_worker.py" kill $target_node
}

resurrect() {
    target_node=$1
    sleep 10
    python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect $target_node
}

get_datanode1_ip() {
    hostname=$(hdfs dfsadmin -report | grep -m 1 "Hostname:" | sed 's/Hostname: //')
    ip=$(nslookup "$hostname" | grep 'Address:' | awk '{print $2}' | tail -n1)
    echo "$ip"
}

oneliners_hadoopstreaming() {
    hadoop_normal_dir="outputs/hadoop-streaming-normal"
    mode_name="hadoop-streaming-$1"
    # Make sure hadoop normal was run before hadoop fail runs
    # So that we can run the normal exec time and inject failure at ~50% exec time
    if [ "$1" == "fail" ]; then
        if [ ! -d "$hadoop_normal_dir" ]; then
            echo "Directory $hadoop_normal_dir does not exist."
            exit 1
        fi
    fi

    mkdir -p "outputs/$mode_name"

    # Set hdfs paths
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    basepath="/oneliners"
    outputs_dir="/outputs/$mode_name/oneliners"
    if hdfs dfs -test -d "$outputs_dir"; then
        hdfs dfs -rm -r "$outputs_dir"
    fi
    
    hdfs dfs -mkdir -p "$outputs_dir"

    # Set local paths
    mkdir -p "outputs/hadoop"
    source ./scripts/bi-gram.aux.sh
    cd scripts/hadoop-streaming
    mode_res_file="../../outputs/$mode_name/oneliners.res"
    > $mode_res_file
    all_res_file="../../outputs/oneliners.res"

    echo executing oneliners $mode_name $(date) | tee -a $mode_res_file $all_res_file
    while IFS= read -r line; do
        if [[ $line == \#* ]]; then
            continue
        fi
        echo $line
        name=$(cut -d "#" -f2- <<< "$line")
        name=$(sed "s/ //g" <<< $name)
        # echo $name
        output_file="../../outputs/$mode_name/$name.out"
        time_file="../../outputs/$mode_name/$name.time"
        log_file="../../outputs/$mode_name/$name.log"
        hash_file="../../outputs/$mode_name/$name.hash"

        if [ "$1" == "fail" ]; then
            # Read exec time under normal case
            time_file_normal="../../outputs/hadoop-streaming-normal/$name.time"
            exec_time_normal=$(cat $time_file_normal | tr -d '[:space:]')

            # Ensure the value is indeed a float
            if ! [[ "$exec_time_normal" =~ ^[+-]?[0-9]*[.][0-9]+([eE][+-]?[0-9]+)?$ ]]; then
                echo "Error: The file does not contain a valid float."
                exit 1
            fi

            # Inject failure at ~50% of exec_time_normal
            kill_after=$(echo "scale=2; $exec_time_normal / 2" | bc)
            
            # NOTE: target is set to datanode 1 for now
            target_ip=$(get_datanode1_ip)
            echo $target_ip
            
            kill $kill_after $target_ip &
        fi
        

        (time eval $line &> $log_file) 2> $time_file

        cat "${time_file}" >> $all_res_file
        echo "./scripts/hadoop-streaming/$name.sh $(cat "$time_file")" | tee -a $mode_res_file

        if [[ $1 == *"fail"* ]]; then
            echo "Resurrecting $target_ip"
            resurrect $target_ip
        fi

        # Combine outputs from partitions on hdfs
        hadoop fs -cat $outputs_dir/$name/part-* > $output_file
        # Remove tabs 
        # tr -d '\t' < $output_file.tmp > $output_file
        # rm $output_file.tmp

        # Generate SHA-256 hash and delete output file
        shasum -a 256 "$output_file" | awk '{ print $1 }' > "$hash_file"
        rm "$output_file"
        
    done <"run_all.sh"

    cd "../.."
}

# adjust the debug flag as required
d=1

# oneliners "bash"
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

# oneliners_hadoopstreaming "normal"
oneliners_hadoopstreaming "fail" "--kill"
