#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $currentdir=getcwd;
my $fastqdir="/data/cqs/lij17/1668/rawdata";
my $refseq="/data/cqs/guoy1/reference/sacCer3/sacCer3.fa";
opendir(DIR,$fastqdir) or die $!;
my @files = grep {$_ ne "." && $_ ne ".." } readdir DIR; close DIR;

my $des=<<PBS;
#!/bin/bash
#Beginning of PBS bash script
#PBS -M jiang.river.lii\@vanderbilt.edu
#Status/Progress Emails to be sent
#PBS -m bae
#Email generated at b)eginning, a)bort, and e)nd of jobs
#PBS -l mem=10000mb
#Total job memory required (specify how many megabytes)
#PBS -l walltime=72:00:00
#You must specify Wall Clock time (hh:mm:ss) [Maximum allowed 30 days = 720:00:00]
#PBS -q batch
PBS

foreach my $f (@files){
    my $id="";
    if($f=~/(.*?)\.txt/){$id=$1;}
    my $pbsfile="${currentdir}/pbs/${id}.pbs";
    open(PBS,">$pbsfile") or die $!;
    print PBS $des;
    print PBS "#PBS -N $id \n";
    print PBS "cd $currentdir \n";
    print PBS "source /data/cqs/bin/path.txt \n";
    print PBS "bwa aln -q 35 $refseq $fastqdir/$f > ${id}.sai \n";
    print PBS "bwa samse -r '\@RG\tID:$id\tLB:$id\tSM:$id\tPL:ILLUMINA' -n 3 $refseq ${id}.sai $fastqdir/$f > ${id}.sam \n";
    print PBS "samtools view -bS ${id}.sam > ${id}.bam \n";
    print PBS "samtools sort ${id}.bam ${id}_sorted \n";
    print PBS "samtools index ${id}_sorted.bam \n";
    close PBS;
    `qsub $pbsfile`;
    #

}
