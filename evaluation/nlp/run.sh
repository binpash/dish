#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

if [[ "$1" == "--full" ]]; then
   echo "Using full input"
  export ENTRIES=1060
else
  echo "Using small input"
  export ENTRIES=120
fi

names_scripts=(
    "1syllable_words;6_4"
    "2syllable_words;6_5"
    "4letter_words;6_2"
    "bigrams_appear_twice;8.2_2"
    "bigrams;4_3"
    "compare_exodus_genesis;8.3_3"
    "count_consonant_seq;7_2"
    "count_morphs;7_1"
    "count_trigrams;4_3b"
    "count_vowel_seq;2_2"
    "count_words;1_1"
    "find_anagrams;8.3_2"
    "merge_upper;2_1"
    "sort;3_1"
    "sort_words_by_folding;3_2"
    "sort_words_by_num_of_syllables;8_1"
    "sort_words_by_rhyming;3_3"
    # "trigram_rec;6_1"
    "uppercase_by_token;6_1_1"
    "uppercase_by_type;6_1_2"
    "verses_2om_3om_2instances;6_7"
    "vowel_sequencies_gr_1K;8.2_1"
    "words_no_vowels;6_3"
  )

mkdir -p "outputs"


nlp() {
    echo executing nlp $1 $(date)

    mkdir -p "outputs/$1"

    for name_script in ${names_scripts[@]}
    do
        IFS=";" read -r -a name_script_parsed <<< "${name_script}"
        name="${name_script_parsed[0]}"
        script="${name_script_parsed[1]}"
        script_file="./scripts/$script.sh"
        # input for all nlp scripts is ./inputs/pg, which is already default for each script
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"
        # output_file contains "done" when run successfully. The real outputs are under output_dir/
        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $output_dir > $output_file ) 2> $time_file
        else
            (time $PASH_TOP/pa.sh $2 --log_file $log_file $script_file $output_dir > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
                sleep 10
            fi
        fi

        echo "$name $script_file $(cat "$time_file")" 
    done

}

# None of the scripts in NLP,
# MediaConv, or LogAnalysis can be implemented in AHS as
# they perform processing in loops, the iterations of which de-
# pend on the files in a statically indeterminable directory (see
# Fig. 5) and are therefore not expressible in AHS. We attempted
# to replace the body of the loop with an AHS invocation but
# the startup overhead ended up dwarfing the execution time by
# a factor of ten on average. (source: nsdi 2023 DiSh paper)


# nlp "bash"

# nlp "pash" "--width 8 --r_split"

# nlp "dish" "--width 8 --r_split --distributed_exec"

nlp "fish" "--width 8 --r_split --ft optimized --distributed_exec"

#nlp "fish-r" "--width 8 --r_split --ft optimized --kill regular --kill_delay 100 --distributed_exec"

#nlp "fish-m" "--width 8 --r_split --ft optimized --kill merger --kill_delay 100 --distributed_exec"

# nlp_hadoopstreaming
