#!/bin/bash
#remove 
folder=rodengvf
logfile=roden.log
if [ ! -d $folder ] 
then
    mkdir $folder
fi

rm -rf ${folder}/*
rm $logfile

for i in `seq 1 22`
do
    echo chr${i} at `date` >>$logfile
    /data/cqs/bin/VAAST_Code_1.0.1/bin/vaast_tools/vaast_converter -a  --build hg19 --path ./${folder} /data/cqs/guoy1/roden/SNPindel/snp/roden${i}_snp.vcf
done

i=X
echo chr${i} at `date` >>$logfile
/data/cqs/bin/VAAST_Code_1.0.1/bin/vaast_tools/vaast_converter -a --build hg19 --path ./${folder} /data/cqs/guoy1/roden/SNPindel/snp/roden${i}_snp.vcf
i=Y
echo chr${i} at `date` >>$logfile
/data/cqs/bin/VAAST_Code_1.0.1/bin/vaast_tools/vaast_converter -a  --build hg19 --path ./${folder} /data/cqs/guoy1/roden/SNPindel/snp/roden${i}_snp.vcf
