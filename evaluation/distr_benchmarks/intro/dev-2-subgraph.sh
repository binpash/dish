IN=${IN:-/intro/200M.txt}
hdfs dfs -cat -ignoreCrc $IN | grep Gutenberg | wc -l