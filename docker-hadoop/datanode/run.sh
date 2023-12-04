#!/bin/bash

# pull latest changes (added for convenience) and start worker
cd $PASH_TOP
git pull
cd -
# TODO: set up logrotate
bash $PASH_TOP/compiler/dspash/worker.sh &> worker.log &

datadir=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
if [ ! -d $datadir ]; then
  echo "Datanode data directory not found: $datadir"
  exit 2
fi

$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode
