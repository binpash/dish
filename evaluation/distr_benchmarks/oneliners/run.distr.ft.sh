if [[ "$@" == *"debug"* ]]; then
  PASH_FLAGS='--width 8 --r_split -d 1'
else
  PASH_FLAGS='--width 8 --r_split'
fi
export TIMEFORMAT=%R
source $DISH_TOP/evaluation/eval_utils.sh


# export dict="$PASH_TOP/evaluation/distr_benchmarks/oneliners/input/dict.txt"
# curl -sf 'http://ndr.md/data/dummy/dict.txt' | sort > $dict

# USAGE: see readme under oneliners
# for checking correctness, specify [correctness] in the args


# scripts_inputs=(
#       "nfa-regex;1G.txt"
#       "sort;1G.txt"
#       "top-n;1G.txt"
#       "wf;1G.txt"
#       "spell;1G.txt"
#       "diff;1G.txt"
#       "bi-grams;1G.txt"
#       "set-diff;1G.txt"
#       "sort-sort;1G.txt"
#       "shortest-scripts;all_cmdsx100.txt"
#   )

# For debugging this automation script
scripts_inputs=(
      "nfa-regex;1M.txt"
      "sort;1M.txt"
      "top-n;1M.txt"
      "wf;1M.txt"
      "spell;1M.txt"
      "diff;1M.txt"
      "bi-grams;1M.txt"
      "set-diff;1M.txt"
      "sort-sort;1M.txt"
      "shortest-scripts;all_cmdsx100.txt"
  )


oneliners_run_bash_script() {
  prefix="seq"
  outputs_dir=${1:-outputs}
  script_input=${2:-"N/A"}

  times_file="$prefix.res"
  outputs_suffix="$prefix.out"
  time_suffix="$prefix.time"

  if [ ! -d "$outputs_dir" ]; then
    mkdir -p "$outputs_dir"
  fi

  touch "$times_file"
  cat $times_file >> $times_file.d
  echo executing one-liners with bash with data $(date) | tee -a "$times_file" "$timefile"
  echo '' >> "$times_file"


  IFS=";" read -r -a script_input_parsed <<< "${script_input}"
  script="${script_input_parsed[0]}"
  input="${script_input_parsed[1]}"
  echo "$script" >> "$timefile"

  export IN="/oneliners/$input"
  export dict=

  printf -v pad %30s
  padded_script="${script}.sh:${pad}"
  padded_script=${padded_script:0:30}

  outputs_file="${outputs_dir}/${script}.${outputs_suffix}"
  single_time_file="${outputs_dir}/${script}.${time_suffix}"

  echo -n "${padded_script}" | tee -a "$times_file"
  { time "bash" ${script}.sh > "$outputs_file"; } 2> "${single_time_file}"
  cat "${single_time_file}" | tee -a "$times_file" "$timefile"
  echo '' >> "$timefile"
}


oneliners_run_pash_script() {
  # USAGE: [flags..., prefix, outputs_dir, script_input]
  flags=${1:-$PASH_FLAGS}
  echo $flags
  prefix=${2:-par}
  prefix=$prefix
  outputs_dir=${3:-outputs}
  script_input=${4:-"N/A"}

  times_file="$prefix.res"
  outputs_suffix="$prefix.out"
  time_suffix="$prefix.time"
  pash_logs_dir="pash_logs_$prefix"

  if [ ! -d "$outputs_dir" ]; then
    mkdir -p "$outputs_dir"
  fi
  if [ ! -d "$pash_logs_dir" ]; then
    mkdir -p "$pash_logs_dir"
  fi

  touch "$times_file"
  cat $times_file >> $times_file.d
  echo executing one-liners with $prefix pash with data $(date) | tee -a "$times_file" "$timefile"
  echo '' >> "$times_file"
  # echo '' >> "$timefile"

  IFS=";" read -r -a script_input_parsed <<< "${script_input}"
  script="${script_input_parsed[0]}"
  input="${script_input_parsed[1]}"
  echo "$script" >> "$timefile"

  export IN="/oneliners/$input"
  export dict=

  printf -v pad %30s
  padded_script="${script}.sh:${pad}"
  padded_script=${padded_script:0:30}

  outputs_file="${outputs_dir}/${script}.${outputs_suffix}"
  pash_log="${pash_logs_dir}/${script}.pash.log"
  single_time_file="${outputs_dir}/${script}.${time_suffix}"

  echo -n "${padded_script}" | tee -a "$times_file"
  { time "$PASH_TOP/pa.sh" $flags --log_file "${pash_log}" ${script}.sh > "$outputs_file"; } 2> "${single_time_file}"
  cat "${single_time_file}" | tee -a "$times_file" "$timefile"
  echo '' >> "$timefile"

  # TODO: get time input to one file instead of .d
  # cat $times_file >> $times_file.d

}



oneliners_hadoopstreaming(){
  jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar" # Adjust as required
  basepath="" # Adjust as required
  times_file="hadoopstreaming.res"
  outputs_suffix="hadoopstreaming.out"
  outputs_dir="/outputs/hadoop-streaming/oneliners"
  . bi-gram.aux.sh

  cd "hadoop-streaming/"

  hdfs dfs -rm -r "$outputs_dir"
  hdfs dfs -mkdir -p "$outputs_dir"

  touch "$times_file"
  cat "$times_file" >> "$times_file".d
  echo executing oneliners with hadoop streaming $(date) | tee -a "$times_file" "$timefile"
  echo '' >> "$times_file"

  while IFS= read -r line; do
      printf -v pad %20s
      name=$(cut -d "#" -f2- <<< "$line")
      name=$(sed "s/ //g" <<< $name)
      echo "$name" >> "$timefile"
      padded_script="${name}.sh:${pad}"
      padded_script=${padded_script:0:20} 
      echo "${padded_script}" $({ time { eval $line &> /dev/null; } } 2>&1) | tee -a "$times_file" "$timefile"
  done <"run_all.sh"
  echo '' >> "$timefile"
  cd ".."
  mv "hadoop-streaming/$times_file" .
}

run() {
  outputs_dir="outputs"

  if [ ! -d "$outputs_dir" ]; then
    echo $outputs_dir
    mkdir -p "$outputs_dir"
  fi

  # Get 2 worker names from dspash_config.json
  for script_input in ${scripts_inputs[@]}
  do
    IFS=";" read -r -a script_input_parsed <<< "${script_input}"
    script="${script_input_parsed[0]}"

    if [[ "$@" == *"bash"* ]]; then
      # Run bash
      oneliners_run_bash_script "$outputs_dir" "$script_input"
    fi


    if [[ "$@" == *"pash"* ]]; then
      # Run PaSh
      oneliners_run_pash_script "$PASH_FLAGS" "par" "$outputs_dir" "$script_input"
    fi

    if [[ "$@" == *"correctness"* ||  "$@" == *"dish"* ]]; then
      # Run DiSh first to set up baseline
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec" "distr" "$outputs_dir" "$script_input"
    fi
    if [[ "$@" == *"naive"* ]]; then
      # Naive ft no faults
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --ft naive" "ft_naive_faultless" "$outputs_dir" "$script_input"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_naive_faultless.out" $@ 
      
      # Naive ft
      # Inject fault on merger node (default to be "$(get_merger_worker_host)")
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill "$(get_merger_worker_host)" --ft naive" "ft_naive_merger" "$outputs_dir" "$script_input"
      # Bring back "$(get_merger_worker_host)"
      # python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect "$(get_merger_worker_host)"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_naive_merger.out" $@
      # Wait for the crashed datanode image to exit and hdfs restarts a new image
      wait_for_update_config $num_datanodes "${old_datanodes[@]}"
      old_datanodes=($(get_active_nodes))
      
      # Naive ft
      # Inject fault on non-merger node (default to be "$(get_regular_worker_host)")
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill "$(get_regular_worker_host)" --ft naive" "ft_naive_regular" "$outputs_dir" "$script_input"
      # python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect "$(get_regular_worker_host)"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_naive_regular.out" $@
      # Wait for the crashed datanode image to exit and hdfs restarts a new image
      echo "${old_datanodes[@]}"
      wait_for_update_config $num_datanodes "${old_datanodes[@]}"
      old_datanodes=($(get_active_nodes))
    fi

    if [[ "$@" == *"base"* ]]; then
      # Base ft no faults
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --ft base" "ft_base_faultless" "$outputs_dir" "$script_input"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_base_faultless.out" $@

      # Base ft
      # Inject fault on merger node (default to be "$(get_merger_worker_host)")
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill "$(get_merger_worker_host)" --ft base" "ft_base_merger" "$outputs_dir" "$script_input"
      # Bring back "$(get_merger_worker_host)"
      # python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect "$(get_merger_worker_host)"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_base_merger.out" $@
      
      # Wait for the crashed datanode image to exit and hdfs restarts a new image
      wait_for_update_config $num_datanodes "${old_datanodes[@]}"
      old_datanodes=($(get_active_nodes))

      # Base ft
      # Inject fault on non-merger node (default to be "$(get_regular_worker_host)")
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill "$(get_regular_worker_host)" --ft base" "ft_base_regular" "$outputs_dir" "$script_input"
      # Bring back "$(get_regular_worker_host)"
      # python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect "$(get_regular_worker_host)"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_base_regular.out" $@

      # Wait for the crashed datanode image to exit and hdfs restarts a new image
      wait_for_update_config $num_datanodes "${old_datanodes[@]}"
      old_datanodes=($(get_active_nodes))
    fi

    if [[ "$@" == *"optimized"* ]]; then
      # Optimized ft no faults
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --ft optimized" "ft_optimized_faultless" "$outputs_dir" "$script_input"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_optimized_faultless.out" $@

      # Optimized ft
      # Inject fault on merger node (default to be "$(get_merger_worker_host)")
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill "$(get_merger_worker_host)" --ft optimized" "ft_optimized_merger" "$outputs_dir" "$script_input"
      # Bring back "$(get_merger_worker_host)"
      # python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect "$(get_merger_worker_host)"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_optimized_merger.out" $@
  
      # Wait for the crashed datanode image to exit and hdfs restarts a new image
      wait_for_update_config $num_datanodes "${old_datanodes[@]}"
      old_datanodes=($(get_active_nodes))

      # Optimized ft
      # Inject fault on non-merger node (default to be "$(get_regular_worker_host)")
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill "$(get_regular_worker_host)" --ft optimized" "ft_optimized_regular" "$outputs_dir" "$script_input"
      # Bring back "$(get_regular_worker_host)"
      # python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect "$(get_regular_worker_host)"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_optimized_regular.out" $@
    
      # Wait for the crashed datanode image to exit and hdfs restarts a new image
      wait_for_update_config $num_datanodes "${old_datanodes[@]}"
      old_datanodes=($(get_active_nodes))
    fi
  done

  
}

# Make sure the cluster is stable
num_datanodes=$(get_num_active_nodes)
echo "This experiment has $num_datanodes datanodes"
update_config
old_datanodes=($(get_active_nodes))



outputs_dir="outputs"
timefile="oneliners.run.time"

# Clean up repo
if [[ "$@" == *"clean"* ]]; then
  if [ -f "$timefile" ]; then
    rm "$timefile"
    touch "$timefile"
  fi
  rm *.res *.d
  rm -rf "$outputs_dir"
fi
if [ ! -f "$timefile" ]; then
  touch "$timefile"
fi

if [[ "$@" == *"sanity"* ]]; then
  # Run bash as groundtruth and also DiSh
  run "bash dish"
  # Check correctness
  for script_input in ${scripts_inputs[@]}
  do
    IFS=";" read -r -a script_input_parsed <<< "${script_input}"
    script="${script_input_parsed[0]}"
    check_correctness "$script" "$outputs_dir/$script.seq.out" "$outputs_dir/$script.distr.out"
  done
  # Sanity option is run by itself
  exit 0
fi

if [[ "$@" == *"hadoop-streaming"* ]]; then
  # Run hadoop streaming
  oneliners_hadoopstreaming
fi

run "$@"



# TODO: add support for small inputs?
# $PASH_TOP/pa.sh spell.sh --width 8 --r_split --distributed_exec --ft naive -d 1 | wc -l
# $PASH_TOP/pa.sh spell.sh --width 8 --r_split --distributed_exec --ft naive -d 1 --kill "$(get_merger_worker_host)" | wc -l
# python3 $DISH_TOP/evaluation/notify_worker.py resurrect "$(get_merger_worker_host)"


# tmux new-session -s test "./run.distr.ft.sh clean bash correctness naive | tee test_log"