#!/bin/bash

# variables
source /data/cqs/bin/path.txt
source /home/lij17/.bashrc

probefile=/scratch/cqs/lij17/cnv/SureSelect_XT_Human_All_Exon_V4_withoutchr_lite.bed
bamfilesdir=/scratch/cqs/guoy1/2110/bwa/firstalignment
conifier=/data/cqs/bin/conifer_v0.2.1/conifer.py

if [ ! -d RPKM ]
then
    mkdir RPKM
fi

#1 calucate rpkm
echo "[Calculate rpkm]" `date`
for bam in `ls $bamfilesdir | grep -P '.bam$'`
do
#    echo $bam
    s=${bam%%_sorted.bam}
    echo $s `date`
    python $conifier rpkm --probes $probefile --input $bamfilesdir/$bam --output RPKM/${s}.txt
done

echo ""

#2 analysis
echo "[Confier analysis step]" `date`
python $conifier analyze --probes $probefile --rpkm_dir RPKM/ --output analysis.hdf5 --svd 6 --write_svals singular_values.txt

#3 call cnv

echo "[Call cnv]" `date`
python $conifier call --input analysis.hdf5 --output calls.txt


