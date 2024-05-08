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


# Adjust input sizes
if [[ "$@" == *"small"* ]]; then
  scripts_inputs=(
      "nfa-regex;1M.txt"
      "sort;1M.txt"
      # "top-n;1M.txt"
      "wf;1M.txt"
      "spell;1M.txt"
      "diff;1M.txt"
      "bi-grams;1M.txt"
      "set-diff;1M.txt"
      "sort-sort;1M.txt"
      "shortest-scripts;all_cmdsx100.txt"
  )
else
  scripts_inputs=(
        "nfa-regex;1G.txt"
        "sort;3G.txt"
        "top-n;3G.txt"
        "wf;3G.txt"
        "spell;3G.txt"
        "diff;3G.txt"
        "bi-grams;3G.txt"
        "set-diff;3G.txt"
        "sort-sort;3G.txt"
        "shortest-scripts;all_cmdsx100.txt"
    )
fi

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
  hashed_outputs_dir="hashed_outputs"

  if [ ! -d "$outputs_dir" ]; then
    mkdir -p "$outputs_dir"
  fi
  if [ ! -d "$hashed_outputs_dir" ]; then
    mkdir -p "$hashed_outputs_dir"
  fi

  # Get 2 worker names from dspash_config.json
  for script_input in ${scripts_inputs[@]}
  do
    IFS=";" read -r -a script_input_parsed <<< "${script_input}"
    script="${script_input_parsed[0]}"

    if [[ "$@" == *"bash"* ]]; then
      # Run bash
      echo "$outputs_dir" "$script_input"
      run_bash_script "$outputs_dir" "$script_input" "oneliners"
      if [[ "$@" == *"update_hash"* ]]; then
        output_file="$outputs_dir/$script.seq.out"
        hashed_output_file="$hashed_outputs_dir/$script.hash"
        get_output_hash $output_file > $hashed_output_file
      fi
    fi


    if [[ "$@" == *"pash"* ]]; then
      # Run PaSh
      run_pash_script "$PASH_FLAGS" "par" "$outputs_dir" "$script_input" "oneliners"
    fi

    if [[ "$@" == *"correctness"* ||  "$@" == *"dish"* ]]; then
      # Run DiSh first to set up baseline
      run_pash_script "$PASH_FLAGS --distributed_exec" "distr" "$outputs_dir" "$script_input" "oneliners"
    fi

    ft_configs=("naive" "base" "optimized")
    for ft_config in ${ft_configs[@]}; do
      if [[ "$@" == *"$ft_config"* ]]; then
        ###########################################################################
        #                             No Fault                                    #
        ###########################################################################        
        run_pash_script "$PASH_FLAGS --distributed_exec --ft $ft_config" "ft_${ft_config}_faultless" "$outputs_dir" "$script_input" "oneliners"
        # Check output correctness and removing outputs file accordingly
        handle_outputs "$script" "$hashed_outputs_dir/$script.hash" "$outputs_dir/$script.ft_${ft_config}_faultless.out" $@
        
        ###########################################################################
        # Inject fault on merger node (determined during run-time now!)           #
        ###########################################################################
        run_pash_script "$PASH_FLAGS --distributed_exec --kill merger --ft $ft_config" "ft_${ft_config}_merger" "$outputs_dir" "$script_input" "oneliners"
        # Check output correctness and removing outputs file accordingly
        handle_outputs "$script" "$hashed_outputs_dir/$script.hash" "$outputs_dir/$script.ft_${ft_config}_merger.out" $@
        # Restore worker
        if [[ "$@" == *"local"* ]]; then
          # Run locally
          python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
        else
          # Run on cloudlab
          # Wait for the crashed datanode image to exit and hdfs restarts a new image
          wait_for_update_config $num_datanodes "${old_datanodes[@]}"
          old_datanodes=($(get_active_nodes))
        fi
        
        ###########################################################################
        # Inject fault on merger node (determined during run-time now!)           #
        ###########################################################################
        run_pash_script "$PASH_FLAGS --distributed_exec --kill regular --ft $ft_config" "ft_${ft_config}_regular" "$outputs_dir" "$script_input" "oneliners"
        # Check output correctness and removing outputs file accordingly
        handle_outputs "$script" "$hashed_outputs_dir/$script.hash" "$outputs_dir/$script.ft_${ft_config}_regular.out" $@
        if [[ "$@" == *"local"* ]]; then
          # Run locally
          python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
        else
          # Run on cloudlab
          # Wait for the crashed datanode image to exit and hdfs restarts a new image
          wait_for_update_config $num_datanodes "${old_datanodes[@]}"
          old_datanodes=($(get_active_nodes))
        fi
      fi
    done
  done
}



if [[ "$@" != *"local"* ]]; then
  # Make sure the cluster is stable
  num_datanodes=$(get_num_active_nodes)
  echo "This experiment has $num_datanodes datanodes"
  update_config
  old_datanodes=($(get_active_nodes))
fi


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