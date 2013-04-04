#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

#Store gene length
open ANN, "CCDS.current.txt" or die $!;
my %hash;
<ANN>;
while(<ANN>){
    my @tokens=split(/\t/, $_);
    my $name=$tokens[2];
    my $len=0;
    my $chr=$tokens[0];
    $tokens[9]=~s/]//;$tokens[9]=~s/\[//;
    my @pos=split(/,/,$tokens[9]);
    foreach my $value (@pos){
        my ($starts, $ends)=split(/-/ ,$value);
        ($starts,$ends) = sort {$a <=>$b } ($starts,$ends);
        my $dif=$ends-$starts+1;
        $len+=$dif;
    }
    $hash{$name}=$len;
}

open TN, "normal_tumor" or die $!;
while(<TN>){
    my ($normal,$tumor)=split;
    open OUT, ">$normal-$tumor-SNP".".gene";
    print OUT "Gene\t"."Nonsysnonymous\t"."stopgain\t"."stoploss\t"."deletion\t"."insertion\t"."total\t"."mut rate per 1000bp\n";
    my $id="$normal-$tumor";
    print "$id\n";
    my $file="$id.txt.exonic_variant_function";
    my %mut1;
    my %mut2;
    my %mut3;
    my %Indel1;
    my %Indel2;
    my %genes;
	open IN, $file;
	while(<IN>){
	    my @tokens=split(/\t/, $_);
	    $tokens[2]=~s/\"//;
	    my ($gene)=split(/:/, $tokens[2]);
	    if($tokens[1] =~ m/^nonsynonymous/){
		    $mut1{$gene}++;
		    $genes{$gene}=0;
	    }elsif($tokens[1] =~ m/^stopgain/){
		    $mut2{$gene}++;
		    $genes{$gene}=0;
	    }elsif($tokens[1] =~ m/^stoploss/){
		    $mut3{$gene}++;
		    $genes{$gene}=0;
	    }elsif($tokens[1] =~ m/deletion/){
			$Indel1{$gene}++;
	    	$genes{$gene}=0;
	    }elsif($tokens[1] =~ m/insertion/){
		    $Indel2{$gene}++;
		    $genes{$gene}=0;
	    }
	}   
    
    foreach my $key (keys %genes){
        if($key eq "ABCA3"){
            print "$key\n";
        }
        my $nonsyn=0;
        if(exists($mut1{$key})){
            $nonsyn=$mut1{$key};
        }
        
        my $stopgain=0;
        if(exists($mut2{$key})){
            $stopgain=$mut2{$key};
        }
        
        my $stoploss=0;
        if(exists($mut3{$key})){
            $stoploss=$mut3{$key};
        }

        my $frameshift_d=0;
        if(exists($Indel1{$key})){
            $frameshift_d=$Indel1{$key};
        }

        my $frameshift_i=0;
        if(exists($Indel2{$key})){
            $frameshift_i=$Indel2{$key};
        }
        
        
        my $total=$nonsyn+$stopgain+$stoploss+$frameshift_d+$frameshift_i;
        
        my $mrate='NA';
        if(exists($hash{$key})){
            $mrate=$total/$hash{$key}*1000;
        }
        print OUT "$key\t$nonsyn\t$stopgain\t$stoploss\t$frameshift_d\t$frameshift_i\t$total\t$mrate\n";
    }
}

