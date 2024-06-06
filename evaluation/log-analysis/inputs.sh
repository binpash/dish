#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs/pcaps_data
cd inputs/pcaps_data

# if [[ ! -f 201011271400.dump.gz ]]
# then
#     wget http://mawi.nezu.wide.ad.jp/mawi/samplepoint-F/2024/202406011400.pcap.gz
#     gunzip 202406011400.pcap.gz

#     wget http://mawi.wide.ad.jp/mawi/samplepoint-F/2010/201011271400.dump.gz
#     gunzip 201011271400.dump.gz
#     wget https://mcfp.felk.cvut.cz/publicDatasets/IoT-23-Dataset/IndividualScenarios/CTU-IoT-Malware-Capture-7-1/2018-07-20-17-31-20-192.168.100.108.pcap
# fi

# http://mawi.wide.ad.jp/mawi/samplepoint-G/2019/201912111400.html
wget http://mawi.nezu.wide.ad.jp/mawi/samplepoint-G/2019/201912111400.pcap.gz
gunzip 201912111400.pcap.gz
hdfs dfs -mkdir -p /log-analysis
hdfs dfs -put 201912111400.pcap /log-analysis/network.pcap


# To process large pcap file, usually it is better to split it into small chunks first, 
# then process every chunk in parallel.
INPUT=${INPUT:-$DISH_TOP/evaluation/log-analysis/inputs/201912111400.pcap}
OUTPUT=${OUTPUT:-$DISH_TOP/evaluation/log-analysis/inputs/network.pcap}
split_size=1000
output_index=1
loop_count=10
exit_flag=0


command() {
	echo "$1" "$2" 
}

# need -Z root to raise the priviledge
# https://serverfault.com/questions/478636/tcpdump-out-pcap-permission-denied
tcpdump -r ${INPUT} -w ${OUTPUT} -C ${split_size} -Z root

command ${OUTPUT}

while :
do
	loop_index=0
	while test ${loop_index} -lt ${loop_count}
	do
		if test -e ${OUTPUT}${output_index}
		then
			command ${OUTPUT} ${output_index} 
			output_index=$((output_index + 1))
			loop_index=$((loop_index + 1))
		else
			exit_flag=1
			break
		fi
	done
	wait

	if test ${exit_flag} -eq 1
	then
		exit 0
	fi
done

cd ..
hdfs dfs -mkdir -p /log-analysis
for f in *.pcap*; do
    echo $f
    hdfs dfs -put $f /log-analysis/$f
done
