#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs/pcaps_data
cd inputs/pcaps_data

if [ "$1" == "--small" ]; then
    PCAP_DATA_FILES=1
else
    LOG_DATA_FILES=84
    PCAP_DATA_FILES=15
fi

# if [[ ! -f 201011271400.dump.gz ]]
# then
#     wget http://mawi.nezu.wide.ad.jp/mawi/samplepoint-F/2024/202406011400.pcap.gz
#     gunzip 202406011400.pcap.gz

#     wget http://mawi.wide.ad.jp/mawi/samplepoint-F/2010/201011271400.dump.gz
#     gunzip 201011271400.dump.gz
#     wget https://mcfp.felk.cvut.cz/publicDatasets/IoT-23-Dataset/IndividualScenarios/CTU-IoT-Malware-Capture-7-1/2018-07-20-17-31-20-192.168.100.108.pcap
# fi

# http://mawi.wide.ad.jp/mawi/samplepoint-G/2019/201912111400.html
# wget http://mawi.nezu.wide.ad.jp/mawi/samplepoint-G/2019/201912111400.pcap.gz
# gunzip 201912111400.pcap.gz
# hdfs dfs -mkdir -p /file-enc
# hdfs dfs -put 201912111400.pcap /file-enc/network.pcap

# download the initial pcaps to populate the whole dataset
if [ ! -d ${IN}/pcap_data ]; then
    cd $IN
    hdfs dfs -mkdir /file-enc

    wget https://atlas-group.cs.brown.edu/data/pcaps.zip
    unzip pcaps.zip
    rm pcaps.zip
    mkdir ${IN}/pcap_data/
    # TODO: prepare small inputs and handle shared input across suites
    # hdfs dfs -put pcap_data /file-enc/pcap_data_small
    # generates 20G
    for (( i = 1; i <= $PCAP_DATA_FILES; i++ )) do
        for j in ${IN}/pcaps/*;do
            n=$(basename $j)
            cat $j > pcap_data/pcap${i}_${n}; 
        done
    done
    hdfs dfs -put pcap_data /file-enc/pcap_data
    echo "Pcaps Generated"
fi 

# To process large pcap file, usually it is better to split it into small chunks first, 
# then process every chunk in parallel.
# INPUT=${INPUT:-$DISH_TOP/evaluation/file-enc/inputs/201912111400.pcap}
# OUTPUT=${OUTPUT:-$DISH_TOP/evaluation/file-enc/inputs/network.pcap}
# split_size=1000
# output_index=1
# loop_count=10
# exit_flag=0


# command() {
# 	echo "$1" "$2" 
# }

# # need -Z root to raise the priviledge
# # https://serverfault.com/questions/478636/tcpdump-out-pcap-permission-denied
# tcpdump -r ${INPUT} -w ${OUTPUT} -C ${split_size} -Z root

# command ${OUTPUT}

# while :
# do
# 	loop_index=0
# 	while test ${loop_index} -lt ${loop_count}
# 	do
# 		if test -e ${OUTPUT}${output_index}
# 		then
# 			command ${OUTPUT} ${output_index} 
# 			output_index=$((output_index + 1))
# 			loop_index=$((loop_index + 1))
# 		else
# 			exit_flag=1
# 			break
# 		fi
# 	done
# 	wait

# 	if test ${exit_flag} -eq 1
# 	then
# 		exit 0
# 	fi
# done

# cd ..
# hdfs dfs -mkdir -p /file-enc
# for f in *.pcap*; do
#     echo $f
#     hdfs dfs -put $f /file-enc/$f
# done
