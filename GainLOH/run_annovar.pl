#!/usr/bin/perl
use strict;
use warnings;

my $scriptfile="/data/cqs/bin/annovar/annotate_variation.pl";
my $dbfile = "/data/cqs/guoy1/reference/annovar";

my @files = <1894*.txt>;
foreach my $f (@files){
    print "[",scalar(localtime),"]Reading $f ...\n";
    `perl $scriptfile $f $dbfile --buildver hg19 `;
}

