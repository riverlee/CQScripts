#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $pbs=<<PBS;
#!/bin/bash
#Beginning of PBS bash script
#PBS -M jiang.river.li\@vanderbilt.edu
#Status/Progress Emails to be sent
#PBS -m bae
#Email generated at b)eginning, a)bort, and e)nd of jobs
#PBS -l mem=10000mb
#Total job memory required (specify how many megabytes)
#PBS -l walltime=48:00:00
#You must specify Wall Clock time (hh:mm:ss) [Maximum allowed 30 days = 720:00:00]
#PBS -q batch
PBS

my $currentdir=getcwd;

if(! -d "pbs"){ mkdir "pbs";}
if(! -d "vat"){ mkdir "vat";}

my $samplefile="/data/cqs/guoy1/roden/geneMutation/sample_list_67.txt";
open(IN,$samplefile) or die $!;
while(<IN>){
    s/\r|\n//g;
    next unless($_);
    my $infile="/data/cqs/guoy1/roden/geneMutation/VAAST/newdata/roden/rawgvf/".$_.".gvf";
    my $outfile=$_.".vat.gvf";
    if( ! -e $infile ){
        print $_,"\n";
    }
    my $pbsfile=$currentdir."/pbs/vat_".$_.".pbs";
    open(OUT,">$pbsfile") or die $!;
    print OUT $pbs;
    print OUT "#PBS -N vat".$_."\n";
    print OUT "cd ${currentdir}/vat\n";
    print OUT  "source /data/cqs/bin/path.txt \n";
    print OUT "VAT -c 500000000 --build GRCh37 -f /data/cqs/guoy1/reference/vaast/hg19/features/refGene_hg19.gff3 -a /data/cqs/guoy1/reference/vaast/hg19/fasta/vaast_hsap_chrs_hg19.fa $infile >$outfile \n";
    close OUT;
      `qsub $pbsfile`;


}
