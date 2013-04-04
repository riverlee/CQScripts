#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $pbsDesc=<<PBS;
#!/bin/bash
#Beginning of PBS bash script
#PBS -M jiang.river.li\@vanderbilt.edu
#Status/Progress Emails to be sent
#PBS -m bae
#Email generated at b)eginning, a)bort, and e)nd of jobs
#PBS -l mem=15000mb
#Total job memory required (specify how many megabytes)
#PBS -l walltime=100:00:00
#You must specify Wall Clock time (hh:mm:ss) [Maximum allowed 30 days = 720:00:00]
#PBS -q batch
PBS

#Do the  the analysis
my $currentdir=getcwd;
my $gff="/data/cqs/guoy1/reference/vaast/hg19/features/refGene_hg19.gff3";
my $backgroud="/data/cqs/guoy1/roden/geneMutation/VAAST/1Kgvf/cdr/background294.cdr";
my $target="/data/cqs/guoy1/roden/geneMutation/VAAST/rodengvf/cdr/target67.cdr";

my $pbsfile="runVaast67_294.pbs";
open(IN,">$pbsfile") or die $!;

my $command="VAAST --mode lrt --rate 0.01 --codon_bias --gp 10000 --fast_gp --mp2 8 -o 67_294 $gff $backgroud $target";
print IN $pbsDesc;
print IN "#PBS -N vaast\n";
print IN "cd $currentdir \n";
print IN $command;
close IN;
