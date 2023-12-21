IN=${IN:-/intro/500M.txt}
hdfs dfs -cat -ignoreCrc $IN | grep Gutenberg | wc -l
