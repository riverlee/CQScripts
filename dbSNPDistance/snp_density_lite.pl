#!/usr/bin/env perl
###################################
# Author: Jiang (River) Li
# Email:  riverlee2008@gmail.com
# Date:   Tue Feb  5 10:23:05 2013
###################################
use strict;
use warnings;

my ($vcf,$sample) = @ARGV;

my $usage=<<USAGE;
Usage: perl snp_density_1000g.pl 1000gvcf samplename
1000gvcf    vcf file of 1000g project, each chromosome has each vcf file
samplename  sample name in the vcf header

USAGE

if(!defined($vcf) || !defined($sample) || ! -e $vcf){
    die $usage;
}


my %hash;
my %samples;
open(IN,$vcf) or die $!;
my $count=0;
while(<IN>){
    s/\r|\n//g;
    next if (/^##/);
    if(/^#/){
        my ($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@samples) = split "\t";
        for(my $i=0;$i<@samples;$i++){
            $samples{$samples[$i]}=$i;
        }
        #Do a quick check
        if(!exists($samples{$sample})){
            close IN;
            die "Sample '$sample' does not exists in the vcf file \n\n";
        }
        next;
    }
    
    my ($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@genotypes) = split "\t";
    #if not a SNP skip
    next if(length($ref)!=1 || length($alt)!=1 || $ref eq "." || $alt eq ".");
    my ($geno)=split ":",$genotypes[$samples{$sample}];
    if($geno ne "0|0" && $geno ne "0/0"){
        $hash{$pos}++;
    }
    $count++;
    if($count>=1000){
        last;
    }
}

# Determine the average density
my @a = sort {$a<=>$b} keys %hash;
%hash = ();

my $total=abs($a[0]-$a[1]);
for(my $i=1;$i<$#a;$i++){
    my $a1=abs($a[$i]-$a[$i-1]);
    my $a2=abs($a[$i]-$a[$i+1]);
    my $b=$a1;
    if($a2<$a1){
        $b=$a2;
    }
    $total+=$b;
}
my $j=$#a;
$total+=abs($a[$j-1]-$a[$j]);
my $av=$total/scalar(@a);
#print "Total SNPs: ",scalar(@a),"\n";

#print "Average density: ",$av,"\n";
print join "\t",($sample,$av);
print "\n";
