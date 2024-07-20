#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

names_scripts=(
    "MediaConv1;img_convert"
    "MediaConv2;to_mp3"
  )

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
all_res_file="./outputs/media-conv.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
media-conv() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/media-conv.res"
    > $mode_res_file

    echo executing media-conv $1 $(date) | tee -a $mode_res_file $all_res_file
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


        if [[ "$1" == "bash" ]]; then
            (time $script_file $input_file $output_dir > $output_file) 2> $time_file
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

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}


# adjust the debug flag as required
d=0

media-conv "bash"
media-conv "pash"        "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24"
media-conv "dish"        "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec"

# media-conv "naive"       "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft naive"
# media-conv "naive-m"     "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft naive --kill merger"
# media-conv "naive-r"     "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft naive --kill regular"

# media-conv "base"        "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft base"
# media-conv "base-m"      "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft base --kill merger"
# media-conv "base-r"      "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft base --kill regular"

# media-conv "optimized"   "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft optimized"
# media-conv "optimized-m" "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft optimized --kill merger"
# media-conv "optimized-r" "--width 8 --r_split -d $d --parallel_pipelines --parallel_pipelines_limit 24 --distributed_exec --ft optimized --kill regular"
