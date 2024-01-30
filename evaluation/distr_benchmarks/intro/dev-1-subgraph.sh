IN=${IN:-/intro/100M.txt}
hdfs dfs -cat -ignoreCrc $IN | grep Gutenberg