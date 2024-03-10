#!/bin/bash
lealea
IN=${IN:-/oneliners/200M.txt}


hdfs dfs -cat -ignoreCrc $IN | grep Gutenberg


