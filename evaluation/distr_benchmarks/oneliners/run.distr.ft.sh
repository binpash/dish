PASH_FLAGS='--width 8 --r_split'
export TIMEFORMAT=%R
# export dict="$PASH_TOP/evaluation/distr_benchmarks/oneliners/input/dict.txt"
# curl -sf 'http://ndr.md/data/dummy/dict.txt' | sort > $dict

# USAGE: see readme under oneliners
# for checking correctness, specify [correctness] in the args


# scripts_inputs=(
#       "nfa-regex;1G.txt"
#       "sort;3G.txt"
#       "top-n;3G.txt"
#       "wf;3G.txt"
#       "spell;3G.txt"
#       "diff;3G.txt"
#       "bi-grams;3G.txt"
#       "set-diff;3G.txt"
#       "sort-sort;3G.txt"
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

outputs_dir="outputs"

# Clean up repo
if [[ "$@" == *"clean"* ]]; then
  rm *.res *.d
  rm -rf "$outputs_dir"
fi
rm oneliners.run.time
touch oneliners.run.time
timefile="oneliners.run.time"


check_correctness() {
  script_name="$1"
  out_baseline="$2"
  out_target="$3"
  echo "📝  Checking output for $script_name: $out_baseline and $out_target"

  # Check if out files exist
  if [ ! -f "$out_baseline" ]; then
      echo "    Error: $out_baseline not found"
      exit 1
  fi
  if [ ! -f "$out_target" ]; then
      echo "    Error: $out_target not found"
      exit 1
  fi

  
  # Perform diff between current configuration file and seq.out
  diff_result=$(diff "$out_baseline" "$out_target")
  
  # Check if there are differences
  if [ -n "$diff_result" ]; then
      echo "$diff_result"
      echo "    ❌ Differences found:"
      return 1
  else
      echo "    ✅ No differences found"
      return 0
  fi
}

# If option "correctness" is specified, check for out_baseline vs out_target
#       if no diff, removing out_target
#       if diff, don't remove out_target for debugging
# else, remove out_target to save SSD
handle_outputs() {
  script_name="$1"
  out_baseline="$2"
  out_target="$3"
  if [[ "$@" == *"correctness"* ]]; then
    check_correctness "$script_name" "$out_baseline" "$out_target"
    if [[ "$?" == 1 ]]; then
      echo "    Output file "$out_baseline" is not removed for debugging"
      # Return on the first diff
      exit 1
    else
      echo "    Output file "$out_target" is removed"
    fi
  else
    echo "Output file "$out_target" is removed"
  fi
}

oneliners_bash() {
    outputs_dir="outputs"
    seq_times_file="seq.res"
    seq_outputs_suffix="seq.out"

    mkdir -p "$outputs_dir"

    touch "$seq_times_file"
    cat "$seq_times_file" >> "$seq_times_file.d"
    echo "executing one-liners $(date)" | tee -a "$seq_times_file" "$timefile"
    echo '' >> "$seq_times_file"
    echo '' >> "$timefile"

    for script_input in "${scripts_inputs[@]}"
    do
        IFS=";" read -r -a script_input_parsed <<< "${script_input}"
        script="${script_input_parsed[0]}"
        input="${script_input_parsed[1]}"
        echo "executing one-liners [bash] for ${script}"
        echo "$script" >> $timefile
        export IN="/oneliners/$input"
        export dict=

        printf -v pad %30s
        padded_script="${script}.sh:${pad}"
        padded_script=${padded_script:0:30}

        seq_outputs_file="${outputs_dir}/${script}.${seq_outputs_suffix}"

        { time ./${script}.sh > "$seq_outputs_file"; } 2>&1 | tee -a "$seq_times_file" "$timefile"
    done
    cat "$seq_times_file" >> "$seq_times_file.d"
    echo '' >> "$timefile"
}

oneliners_run_pash_script() {
  # USAGE: [flags..., prefix, outputs_dir, script_input]
  flags=${1:-$PASH_FLAGS}
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


oneliners_pash(){
  flags=${1:-$PASH_FLAGS}
  prefix=${2:-par}
  prefix=$prefix

  times_file="$prefix.res"
  outputs_suffix="$prefix.out"
  time_suffix="$prefix.time"
  outputs_dir="outputs"
  pash_logs_dir="pash_logs_$prefix"

  mkdir -p "$outputs_dir"
  mkdir -p "$pash_logs_dir"

  for script_input in ${scripts_inputs[@]}
  do
    oneliners_run_pash_script "$flags" "$prefix" "$outputs_dir" "$script_input"
  done
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
  echo executing oneliners $(date) | tee -a "$times_file" "$timefile"
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

oneliners_faults() {
  outputs_dir="outputs"

  if [ ! -d "$outputs_dir" ]; then
    echo $outputs_dir
    mkdir -p "$outputs_dir"
  fi

  for script_input in ${scripts_inputs[@]}
  do
    IFS=";" read -r -a script_input_parsed <<< "${script_input}"
    script="${script_input_parsed[0]}"
    if [[ "$@" == *"correctness"* ]]; then
      # Run dish first to set up baseline
      oneliners_pash "$PASH_FLAGS --distributed_exec" "distr"
    fi
    if [[ "$@" == *"naive"* ]]; then
      # Naive ft no faults
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --ft naive" "ft_naive_faultless" "$outputs_dir" "$script_input"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_naive_faultless.out" $@ 
      
      # Naive ft
      # Inject fault on merger node (default to be datanode1)
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill datanode1 --ft naive" "ft_naive_merger" "$outputs_dir" "$script_input"
      # Bring back datanode1
      python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect datanode1
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_naive_merger.out" $@
      
      # Naive ft
      # Inject fault on non-merger node (default to be datanode2)
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill datanode2 --ft naive" "ft_naive_regular" "$outputs_dir" "$script_input"
      python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect datanode2
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_naive_regular.out" $@
    fi

    if [[ "$@" == *"base"* ]]; then
      # Base ft no faults
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --ft base" "ft_base_faultless" "$outputs_dir" "$script_input"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_base_faultless.out" $@

      # Base ft
      # Inject fault on merger node (default to be datanode1)
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill datanode1 --ft base" "ft_base_merger" "$outputs_dir" "$script_input"
      # Bring back datanode1
      python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect datanode1
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_base_merger.out" $@
      
      # Base ft
      # Inject fault on non-merger node (default to be datanode2)
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill datanode2 --ft base" "ft_base_regular" "$outputs_dir" "$script_input"
      # Bring back datanode2
      python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect datanode2
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_base_regular.out" $@
    fi

    if [[ "$@" == *"optimized"* ]]; then
      # Optimized ft no faults
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --ft optimized" "ft_optimized_faultless" "$outputs_dir" "$script_input"
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_optimized_faultless.out" $@

      # Optimized ft
      # Inject fault on merger node (default to be datanode1)
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill datanode1 --ft optimized" "ft_optimized_merger" "$outputs_dir" "$script_input"
      # Bring back datanode1
      python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect datanode1
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_optimized_merger.out" $@
  
      # Optimized ft
      # Inject fault on non-merger node (default to be datanode2)
      oneliners_run_pash_script "$PASH_FLAGS --distributed_exec --kill datanode2 --ft optimized" "ft_optimized_regular" "$outputs_dir" "$script_input"
      # Bring back datanode2
      python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect datanode2
      # Check output correctness and removing outputs file accordingly
      handle_outputs "$script" "$outputs_dir/$script.distr.out" "$outputs_dir/$script.ft_optimized_regular.out" $@
    fi
  done

  
}



# ./check_ft_correctness.sh
if [[ "$@" == *"sanity"* ]]; then
  # Run bash as groundtruth
  oneliners_bash
  # dish
  oneliners_pash "$PASH_FLAGS --distributed_exec" "distr"
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

if [[ "$@" == *"bash"* ]]; then
  # bash
  oneliners_bash
fi

if [[ "$@" == *"hadoop-streaming"* ]]; then
  # hadoop streaming
  oneliners_hadoopstreaming
fi

if [[ "$@" == *"pash"* ]]; then
  # pash
  oneliners_pash "$PASH_FLAGS" "par"
fi

if [[ "$@" == *"dish"* ]]; then
  # TODO: add frozen dish (with no overhead)
  # This below is defaulted to optimized ft
  oneliners_pash "$PASH_FLAGS --distributed_exec" "distr"
fi


# for debugging this automation script:
# oneliners_bash
# oneliners_pash "$PASH_FLAGS --distributed_exec" "distr"
oneliners_faults "$@"



# TODO: add support for small inputs?
# $PASH_TOP/pa.sh spell.sh --width 8 --r_split --distributed_exec --ft naive -d 1 | wc -l
# $PASH_TOP/pa.sh spell.sh --width 8 --r_split --distributed_exec --ft naive -d 1 --kill datanode1 | wc -l
# python3 $DISH_TOP/evaluation/notify_worker.py resurrect datanode1