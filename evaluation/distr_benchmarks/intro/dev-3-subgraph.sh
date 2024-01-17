IN=${IN:-/intro/300M.txt}
hdfs dfs -cat -ignoreCrc $IN | grep Gutenberg | wc -l