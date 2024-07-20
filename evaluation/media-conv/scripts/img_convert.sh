#!/bin/bash
# tag: resize image 
IN=${JPG:-/media-conv/jpg}
OUT=${OUT:-$DISH_TOP/evaluation/media-conv/outputs/jpg}
mkdir -p ${OUT}

pure_func () {
     convert -resize 70% "-" "-"
}
export -f pure_func

for i in $(hdfs dfs -ls -C ${IN}/*.jpg); 
do 
    out=$OUT/$(basename -- $i)
    hdfs dfs -cat -ignoreCrc $i | pure_func > $out; 
done

echo 'done';
