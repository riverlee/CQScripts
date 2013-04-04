#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $currentdir=getcwd;

my $tophat2="/scratch/cqs/lij17/clip-seq/tophat-2.0.5.Linux_x86_64/tophat";
my $ref="/data/cqs/guoy1/reference/hg19/bowtie2_index/hg19";
my $gtf="/data/cqs/guoy1/reference/annotation/hg19/Homo_sapiens.GRCh37.63_chr1-22-X-Y-M.gtf";
my $gtfindex="/scratch/cqs/lij17/bowtie2_gtf_index/Homo_sapiens.GRCh37.63_chr1-22-X-Y-M";
my $pbsDesc=<<PBS;
#!/bin/bash
#Beginning of PBS bash script
#PBS -M jiang.river.li\@vanderbilt.edu
#Status/Progress Emails to be sent
#PBS -m bae
#Email generated at b)eginning, a)bort, and e)nd of jobs
#PBS -l mem=40000mb
#Total job memory required (specify how many megabytes)
#PBS -l walltime=150:00:00
#You must specify Wall Clock time (hh:mm:ss) [Maximum allowed 30 days = 720:00:00]
#PBS -q batch

PBS

my @files=</data/cqs/chenx/colon/*.txt>;

foreach my $f (@files){
    my $s="";
    if($f=~/colon\/(.*?)_1_sequence\.txt/){
        $s=$1;
    }
    print "Doing $s\n";

    my $pbsfile="${s}.pbs";
    open(OUT,">$pbsfile");
    print OUT $pbsDesc;
    
    print OUT "#PBS -N $s\n";
    print OUT "cd $currentdir \n";

    print OUT "source /data/cqs/bin/path.txt \n";

    print OUT "$tophat2 -o ${s}_tophat -p 8  --transcriptome-index $gtfindex  $ref $f \n";
    #print OUT "$tophat2 -o ${s}_tophat -p 8 -G $gtf --transcriptome-index $gtfindex  $ref $f \n";

    close OUT;

}
