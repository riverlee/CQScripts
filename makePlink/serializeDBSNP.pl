#!/usr/bin/env perl
###################################
# Author: Jiang (River) Li
# Email:  riverlee2008@gmail.com
# Date:   Thu Mar 14 15:00:49 2013
###################################
use strict;
use warnings;
use Storable;

#1) read dbsnp ref
open(IN,"/data/cqs/guoy1/reference/dbsnp137/00-All.vcf") or die $!;
my %dbsnp;
print "[",scalar(localtime),"] Start reading dbsnp ...\n";
while(<IN>){
    next if (/^#/);#skip header
    my ($chr,$pos,$rs) = split "\t";
    $dbsnp{$rs}="$chr\t$pos";
}
close IN;

# Serialize data
print "[",scalar(localtime),"] Start store dbsnp ...\n";
store \%dbsnp, "dbsnp.perl.data";
print "[",scalar(localtime),"] Finished\n";
