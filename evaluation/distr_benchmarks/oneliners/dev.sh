#!/bin/bash

IN=${IN:-/intro/200M.txt}
# IN=${IN:-/oneliners/10M.txt}


hdfs dfs -cat -ignoreCrc $IN | grep Gutenberg


