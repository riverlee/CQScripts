#1, Setting up a project
echo create new project `date`
echo create new project `date`>run.log
pseq proj new-project --vcf data/*.vcf --metameta data/meta.meta --resources /data/cqs/guoy1/reference/qseq/hg19/hg19/


#2, load vcf files into project
echo load vcf `date`
echo load vcf `date` >>run.log
pseq proj load-vcf

#3, Load phenotype into project
echo load pheno `date`
echo load pheno `date` >> run.log
pseq proj load-pheno --file data/67_379.phe 

#4, adpative association for all methods
echo 10000 all association2 `date`
echo  10000 all association2 `date` >> run.log
#pseq proj assoc --phenotype phe1 --mask loc.group=refseq --options uniq vt fw calpha sumstat --perm -1 > adaptive_assoc.txt


#5, permutaion association for all methods
pseq proj assoc --phenotype phe1 --mask loc.group=refseq --options uniq vt fw calpha sumstat --perm 10000 > perm10000_assoc.txt

#pseq proj assoc --phenotype phe1 --mask loc.group=refseq maf=0.05 --options uniq vt fw calpha sumstat --perm 1000 > perm1000_maf005_assoc.txt



