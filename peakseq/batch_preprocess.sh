#!/bin/bash

for i in `seq 1 8`
do
    echo $i
    mkdir s${i}
    /data/cqs/bin/web_release/bin/PeakSeq -preprocess SAM chr_id_list.txt ../bwa/firstalignment/1668-WPT-${i}_sequence_sorted.sam s${i} 
done

