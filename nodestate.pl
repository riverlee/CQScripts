#!/usr/bin/perl
#############################################
#Author: Jiang Li
#email: riverlee2008@gmail.com
#Creat Time: 
#Vanderbilt Center for Quantitative Sciences
#############################################
use strict;
use warnings;

open(IN,"pbsnodes|") or die $!;
#open(IN,"all.nodes") or die $!;

my $s = "";

while(<IN>){
    if(/^$/){
       if($s ne ""){
            print doit($s);
            print "\n";

       }

       $s="";
    }else{
        $s.=$_;
    }
}

sub doit{
    my $s = $_[0];
    my ($host,$state,$jobs,$mem,$nodes,$pro)=("","","","","","","","");
    if($s=~/(vmp.*?)\n/){
        $host=$1;
    }
    if($s=~/state = (.*?)\n/){$state = $1};
    if($s=~/jobs = (.*?)\n/){my @a = split ",",$1; $jobs=scalar(@a);}
    if($s=~/physmem=(.*?),/){$mem=$1;}
    if($s=~/np = (.*?)\n/){$nodes=$1;}
    if($s=~/properties = (.*?)\n/){$pro=$1;}
    if($jobs eq ""){$jobs=0;}
    return join "\t", ($host,$state,$jobs,$mem,$nodes,$pro);
}

