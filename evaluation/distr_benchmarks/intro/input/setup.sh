#!/bin/bash

PASH_TOP=${PASH_TOP:-$(git rev-parse --show-toplevel)}
. "$PASH_TOP/scripts/utils.sh"
cd $(dirname $0)
input_files=("100M.txt" "200M.txt" "300M.txt" "500M.txt")
local_fils=("dict.txt")

[ "$1" = "-c" ] && rm-files 100M.txt 200M.txt 300M.txt 500M.txt words sorted_words

hdfs dfs -mkdir -p /intro

if [ ! -f ./100M.txt ]; then
  curl -sf --connect-timeout 10 'ndr.md/data/dummy/100M.txt' > 100M.txt
  if [ $? -ne 0 ]; then
    # Pipe curl through tac (twice) in order to consume all the output from curl.
    # This way, curl can write the whole page and not emit an error code.
    curl -fL 'http://www.gutenberg.org/files/2600/2600-0.txt' | tac | tac | head -c 1M > 1M.txt
    [ $? -ne 0 ] && eexit 'cannot find 1M.txt'
    touch 100M.txt
    for (( i = 0; i < 100; i++ )); do
      cat 1M.txt >> 100M.txt
    done
  fi
  append_nl_if_not ./100M.txt
fi

if [ ! -f ./200M.txt ]; then
    touch 200M.txt
    for (( i = 0; i < 2; i++ )); do
        cat 100M.txt >> 200M.txt
    done
fi

if [ ! -f ./300M.txt ]; then
    touch 300M.txt
    for (( i = 0; i < 3; i++ )); do
        cat 100M.txt >> 300M.txt
    done
fi

if [ ! -f ./500M.txt ]; then
    touch 500M.txt
    for (( i = 0; i < 5; i++ )); do
        cat 100M.txt >> 500M.txt
    done
fi

if [ ! -f ./words ]; then
  curl -sf --connect-timeout 10 'http://ndr.md/data/dummy/words' > words
  if [ $? -ne 0 ]; then
    curl -sf 'https://zenodo.org/record/7650885/files/words' > words
    if [ $? -ne 0 ]; then
      if [ $(uname) = 'Darwin' ]; then
        cp /usr/share/dict/web2 words || eexit "cannot find dict file"
      else
        # apt install wamerican-insane
        cp /usr/share/dict/words words || eexit "cannot find dict file"
      fi
    fi
  fi
  append_nl_if_not words
fi

## Re-sort words for this machine
if [ ! -f ./sorted_words ]; then
  sort words > sorted_words
fi

# Add files with different replication factors
for file in "${input_files[@]}"; do
    hdfs dfs -put $file /intro/$file
    rm -f $file
done