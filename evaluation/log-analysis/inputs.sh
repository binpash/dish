#!/bin/bash

cd "$(realpath $(dirname "$0"))"
mkdir -p inputs
cd inputs
hdfs dfs -mkdir /log-analysis

# download the input for the nginx logs and populate the dataset
if [ ! -d log_data ]; then
    wget -q https://atlas-group.cs.brown.edu/data/nginx.zip --no-check-certificate
    unzip -q nginx.zip
    rm nginx.zip
    # generating full analysis logs
    mkdir -p log_data
	LOG_DATA_FILES=252 # 84 * 3
    # Loop over each file in nginx-logs/
    for j in nginx-logs/*; do
        # Get the base name of the file
        n=$(basename "$j")
        
        # Loop to concatenate the file into log_data/log*.log
        for ((i = 1; i <= LOG_DATA_FILES; i++)); do
            cat "$j" >> log_data/${n}.log
        done
    done
    hdfs dfs -put log_data /log-analysis/log_data
    rm -rf log_data
    echo "Nginx logs Generated"

	# generating small analysis logs
    mkdir -p log_data_small
	LOG_DATA_FILES=6
    for (( i = 1; i <=$LOG_DATA_FILES; i++)) do
        for j in nginx-logs/*;do
            n=$(basename $j)
            cat $j > log_data_small/log${i}_${n}.log; 
        done
    done
    hdfs dfs -put log_data_small /log-analysis/log_data_small
    rm -rf log_data_small
    echo "Nginx logs (small) Generated"
fi


if [ ! -d pcap_data ]; then
  wget -q https://atlas-group.cs.brown.edu/data/pcaps.zip --no-check-certificate
  unzip -q pcaps.zip
  rm pcaps.zip
  # generates 20G
  mkdir -p pcap_data/
  PCAP_DATA_FILES=15
  for (( i = 1; i <= $PCAP_DATA_FILES; i++ )) do
      for j in pcaps/*;do
          n=$(basename $j)
          cat $j > pcap_data/pcap${i}_${n};
      done
  done
  hdfs dfs -put pcap_data/ /log-analysis/pcap_data
  rm -rf pcap_data
  echo "Pcaps Generated"

  # generates small inputs
  mkdir -p pcap_data_small/
  PCAP_DATA_FILES=1
  for (( i = 1; i <= $PCAP_DATA_FILES; i++ )) do
      for j in pcaps/*;do
          n=$(basename $j)
          cat $j > pcap_data_small/pcap${i}_${n}; 
      done
  done
  hdfs dfs -put pcap_data_small/ /log-analysis/pcap_data_small
  rm -rf pcap_data_small
  echo "Pcaps_small Generated"
fi
