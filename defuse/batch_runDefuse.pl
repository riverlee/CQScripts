#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $currentdir =getcwd;
my $pbs= <<PBS;
#!/bin/bash
#Beginning of PBS bash script
#PBS -M jiang.river.li\@vanderbilt.edu
#Status/Progress Emails to be sent
#PBS -m bae
#Email generated at b)eginning, a)bort, and e)nd of jobs
#PBS -l mem=60000mb
#Total job memory required (specify how many megabytes)
#PBS -l walltime=200:00:00
#You must specify Wall Clock time (hh:mm:ss) [Maximum allowed 30 days = 720:00:00]
#PBS -l nodes=1:ppn=12
#PBS -q batch
PBS

my @files=</scratch/cqs/guoy1/cleveland/rawdata2/download3/*.fastq>;

my %samples;
foreach my $f (@files){
    $f=~s/.*download3\/(.*?)_\d.fastq/$1/g;
    $samples{$f}++;
}
foreach my $s (keys %samples){
    print $s,"\n";
    
    `cp config_mytemplate.txt $s.config`;
    `sed -i 's/replacesample/$s/g' $s.config`;
    open(PBS,">${s}.pbs") or die $!;
    print PBS $pbs;
    print PBS "#PBS -N defuse_${s}\n";
    print PBS "cd $currentdir\n";
    print PBS "source ~/.bashrc\n";
    print PBS "/data/cqs/bin/defuse-0.5.0//scripts/defuse.pl -c ${s}.config -d /gpfs21/scratch/cqs/guoy1/cleveland/rawdata2/download3 -o $s -p 12\n";
    close PBS;
}




