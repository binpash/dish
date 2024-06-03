hadoop jar $jarpath -files 1.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/1_$size.txt -output $outputs_dir/unix501 -mapper 1.sh # 1
hadoop jar $jarpath -files 2.sh -D dfs.checksum.type=NULL -input $basepath/1_$size.txt -output $outputs_dir/unix502 -mapper 2.sh # 2
hadoop jar $jarpath -files 3.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/1_$size.txt -output $outputs_dir/unix503 -mapper 3.sh && hadoop fs -cat $outputs_dir/unix503/part-* | head -n 2 | cut -d ' ' -f 2 > unix503_out.txt # 3
hadoop jar $jarpath -files 4_map.sh,4_reduce.sh -D dfs.checksum.type=NULL -input $basepath/1_$size.txt -output $outputs_dir/unix504 -mapper 4_map.sh -reducer 4_reduce.sh # 4
hadoop jar $jarpath -files 5.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/2_$size.txt -output $outputs_dir/unix505 -mapper 5.sh # 5
hadoop jar $jarpath -files 6.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/3_$size.txt -output $outputs_dir/unix506 -mapper 6.sh # 6
hadoop jar $jarpath -files 7_map.sh,7_reduce.sh -D dfs.checksum.type=NULL -input $basepath/4_$size.txt -output $outputs_dir/unix507 -mapper 7_map.sh -reducer 7_reduce.sh # 7
hadoop jar $jarpath -files 8_map.sh,8_reduce.sh -D dfs.checksum.type=NULL -input $basepath/4_$size.txt -output $outputs_dir/unix508 -mapper 8_map.sh -reducer 8_reduce.sh # 8
hadoop jar $jarpath -files 9_map.sh,9_reduce.sh -D dfs.checksum.type=NULL -input $basepath/4_$size.txt -output $outputs_dir/unix509 -mapper 9_map.sh -reducer 9_reduce.sh # 9
hadoop jar $jarpath -files 10_map.sh,10_reduce.sh -D dfs.checksum.type=NULL -input $basepath/4_$size.txt -output $outputs_dir/unix5010 -mapper 10_map.sh -reducer 10_reduce.sh # 10
hadoop jar $jarpath -files 11_map.sh,11_reduce.sh -D dfs.checksum.type=NULL -input $basepath/4_$size.txt -output $outputs_dir/unix5011 -mapper 11_map.sh -reducer 11_reduce.sh # 11
hadoop jar $jarpath -files 12_map.sh,12_reduce.sh -D dfs.checksum.type=NULL -input $basepath/4_$size.txt -output $outputs_dir/unix5012 -mapper 12_map.sh -reducer 12_reduce.sh # 12
hadoop jar $jarpath -files 13.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/5_$size.txt -output $outputs_dir/unix5013 -mapper 13.sh # 13
hadoop jar $jarpath -files 14_map.sh,14_reduce.sh -D dfs.checksum.type=NULL -input $basepath/6_$size.txt -output $outputs_dir/unix5014 -mapper 14_map.sh -reducer 14_reduce.sh # 14
hadoop jar $jarpath -files 15_map.sh,15_reduce.sh -D dfs.checksum.type=NULL -input $basepath/7_$size.txt -output $outputs_dir/unix5015 -mapper 15_map.sh -reducer 15_reduce.sh # 15
hadoop jar $jarpath -files 16_map.sh,16_reduce.sh -D dfs.checksum.type=NULL -input $basepath/7_$size.txt -output $outputs_dir/unix5016 -mapper 16_map.sh -reducer 16_reduce.sh # 16
hadoop jar $jarpath -files 17_map.sh,17_reduce.sh -D dfs.checksum.type=NULL -input $basepath/7_$size.txt -output $outputs_dir/unix5017 -mapper 17_map.sh -reducer 17_reduce.sh # 17
hadoop jar $jarpath -files 18_map.sh,18_reduce.sh -D dfs.checksum.type=NULL -input $basepath/8_$size.txt -output $outputs_dir/unix5018 -mapper 18_map.sh -reducer 18_reduce.sh # 18
hadoop jar $jarpath -files 19.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/8_$size.txt -output $outputs_dir/unix5019 -mapper 19.sh # 19
hadoop jar $jarpath -files 20.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/8_$size.txt -output $outputs_dir/unix5020 -mapper 20.sh && hadoop fs -cat $outputs_dir/unix5020/part-* | head -n 1 > unix5020_out.txt # 20
hadoop jar $jarpath -files 21_map.sh,21_reduce.sh -D dfs.checksum.type=NULL -input $basepath/8_$size.txt -output $outputs_dir/unix5021 -mapper 21_map.sh -reducer 21_reduce.sh # 21
# 22 Commented out in PaSh
hadoop jar $jarpath -files 23.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.1_$size.txt -output $outputs_dir/unix5023_tmp -mapper 23.sh && hadoop fs -mkdir -p $outputs_dir/unix5023 && hadoop fs -cat $outputs_dir/unix5023_tmp/part-00000 $outputs_dir/unix5023_tmp/part-00001 | sed 's/[[:space:]]*$//' | tr -d '\n' | cut -c 1-4 > unix5023_out.txt # 23
hadoop jar $jarpath -files 24.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.2_$size.txt -output $outputs_dir/unix5024 -mapper 24.sh # 24
hadoop jar $jarpath -files 25.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.3_$size.txt -output $outputs_dir/unix5025 -mapper 25.sh # 25
hadoop jar $jarpath -files 26.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.4_$size.txt -output $outputs_dir/unix5026 -mapper 26.sh # 26
# 27 Commented out in PaSh
hadoop jar $jarpath -files 28.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.6_$size.txt -output $outputs_dir/unix5028 -mapper 28.sh # 28
hadoop jar $jarpath -files 29.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.7_$size.txt -output $outputs_dir/unix5029 -mapper 29.sh # 29
hadoop jar $jarpath -files 30.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.8_$size.txt -output $outputs_dir/unix5030 -mapper 30.sh # 30
hadoop jar $jarpath -files 31.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/9.9_$size.txt -output $outputs_dir/unix5031 -mapper 31.sh # 31
hadoop jar $jarpath -files 32_map.sh,32_reduce.sh -D dfs.checksum.type=NULL -input $basepath/10_$size.txt -output $outputs_dir/unix5032 -mapper 32_map.sh -reducer 32_reduce.sh # 32
hadoop jar $jarpath -files 33.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/10_$size.txt -output $outputs_dir/unix5033 -mapper 33.sh # 33
hadoop jar $jarpath -files 34.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/10_$size.txt -output $outputs_dir/unix5034 -mapper 34.sh && hadoop fs -cat $outputs_dir/unix5034/part-* | head -n 1 | fmt -w1 | cut -c 1-1 | tr -d '\n' | tr '[A-Z]' '[a-z]' > unix5034_out.txt # 34
hadoop jar $jarpath -files 35.sh -D mapred.reduce.tasks=0 -D dfs.checksum.type=NULL -input $basepath/11_$size.txt -output $outputs_dir/unix5035 -mapper 35.sh # 35
hadoop jar $jarpath -files 36_map.sh,36_reduce.sh -D dfs.checksum.type=NULL -input $basepath/11_$size.txt -output $outputs_dir/unix5036 -mapper 36_map.sh -reducer 36_reduce.sh # 36
