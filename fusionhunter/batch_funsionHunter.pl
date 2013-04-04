#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $currentdir=getcwd;
my $pbs= <<PBS;
#!/bin/bash
#Beginning of PBS bash script
#PBS -M jiang.river.li\@vanderbilt.edu
#Status/Progress Emails to be sent
#PBS -m bae
#Email generated at b)eginning, a)bort, and e)nd of jobs
#PBS -l mem=30000mb
#Total job memory required (specify how many megabytes)
#PBS -l walltime=72:00:00
#You must specify Wall Clock time (hh:mm:ss) [Maximum allowed 30 days = 720:00:00]
#PBS -q batch
PBS

###########################
#read files
my $dir1="/scratch/cqs/guoy1/cleveland/rawdata4/download4/";
#my $dir2="/scratch/cqs/guoy1/cleveland/rawdata2/download2/";

my %files;

foreach my $dir ($dir1){
    #print $dir,"\n";
    while(my $f = <$dir/*.fastq>){
        print $f,"\n";
        #get file name with out path
        my $name=$f;
        $name=~s/.*\///g;
        print $name,"\n";
        $name=~/(.*?)_(\d)\.fastq/;
        my $paired="first";
        if($2 eq "2"){
            $paired="second";
        }
        $files{$1}->{$paired}=$f;
        print join "\t",$1,$2,$name,"\n";
    }
}


#loop each samples, and generate pbs file

my $result="FusionHunterResult";
if( ! -d $result){
    mkdir $result;
}

chdir $result;
foreach my $sample (sort keys %files){
   if($sample eq "062211_JC_EAC"){
        print "Skip 062211_JC_EAC \n";
        next;
    }
   if( ! -d $sample){
        mkdir $sample;
   }

   my $pbsfile="$currentdir/$result/$sample/${sample}.pbs";
   open(OUT,">$pbsfile") or die $!;
   print OUT $pbs;
   
   print OUT "#PBS -N FusionHunter_${sample}\n";
   print OUT "source /data/cqs/bin/path.txt \n";
   print OUT "cd $currentdir/$result/$sample\n";
   print OUT "/data/cqs/bin/FusionHunter-v1.4-Linux_x86_64/bin/FusionHunter.pl FusionHunter.cfg \n";
   close OUT;

   #replace FusionHunter.cfg.sample content
   `cp ../FusionHunter.cfg.sample $sample/FusionHunter.cfg`;
    
   my $s=$files{$sample}->{'first'};
   $s=~s/\//\\\//g;
   ` sed -i 's/L = .*/L = $s/' $sample/FusionHunter.cfg`;
   $s=$files{$sample}->{'second'};
   $s=~s/\//\\\//g;
   `sed -i 's/R = .*/R = $s/' $sample/FusionHunter.cfg`;
   #  print $com,"\n";
   #`qsub $pbsfile`;

}
