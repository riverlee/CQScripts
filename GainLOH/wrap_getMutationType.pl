#!/usr/bin/perl
use strict;
use warnings;

my @vcfs = </data/cqs/guoy1/1894/bwa/SNPindel/snp/1894_*_snp.vcf>;

my $pairfile = "normal_tumor";
my $com = "perl getMutationType.pl  $pairfile 10";
foreach my $f (@vcfs){
    $com.=" $f ";
}

print $com;
system($com);

