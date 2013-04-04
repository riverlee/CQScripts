#!/usr/bin/perl
use strict;
use warnings;
use IO::File;

die "perl $0 pairfile dpfilter vcf1 vcf2 \n" if (@ARGV<3);

my ($pairfile,$dpfilter,@vcffiles) = @ARGV;

#Read pairfile
my %pair;
open(IN,$pairfile) or die $!;
while(<IN>){
    s/\r|\n//g;
    my($s1,$s2) = split /\s+/;
    my $key=join "-",($s1,$s2);
    $pair{$key}->{'name'}=[$s1,$s2];
}
close IN;

#Create file handle for each sample pair
foreach my $k (sort keys %pair){
    my $fh = new IO::File;
    $fh->open("> ${k}.txt");
    $pair{$k}->{'fhandle'}=$fh;
}

#######################################
#Read vcf file
foreach my $vcf (@vcffiles) {
    print "[",scalar(localtime),"]Doing $vcf now ....\n";
    open(IN,$vcf) or die $!;
    my %header;
    while(<IN>){
        s/\r|\n//g;
        next if (/^##/);
        if(/^#/){#the header line
            my (undef,undef,undef,undef,undef,undef,undef,undef,undef,@header) = split "\t";
            for(my $i=0;$i<@header;$i++){
                if($header[$i] eq '1769-DPC-X'){
                    $header{'1769-DPC-11'}=$i;
                }else{
                    $header{$header[$i]}=$i;
                }
            }
            next;
        }
        my($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@genotypes) = split "\t";
        my @formats = split ":",$format;

        #to get each pairs' genotype
        foreach my $k (sort keys %pair){
            my ($s1,$s2) = @{$pair{$k}->{name}};
            if(!exists($header{$s1}) || !exists($header{$s2})){
                next;
            }
            my $geno1 = $genotypes[$header{$s1}];
            my $geno2 = $genotypes[$header{$s2}];
            my %map1; my %map2;
            @map1{@formats} = split ":",$geno1;
            @map2{@formats} = split ":",$geno2;
            if($map1{'GT'} =~/\./ || $map2{'GT'} =~/\./){
                next;
            }
            if($map1{'DP'} <$dpfilter || $map2{'DP'}< $dpfilter){
                next;
            }

            my $type = mutationType($map1{'GT'},$map2{'GT'});
            if($type ne ""){#write out result
                my $fh = $pair{$k}->{'fhandle'};
                print $fh join "\t",($chr,$pos,$pos,$ref,$alt,$format,$geno1,$geno2,$type);
                print $fh "\n";
            }

        }


    }
}







#close the file handle
foreach my $k (sort keys %pair){
    $pair{$k}->{'fhandle'}->close;
}


sub mutationType{
    #the first one is normal sample
    #second is cancer sample
    my $type="";
    my ($geno1,$geno2) = @_;
    #Gain mutation
    if($geno1 eq '0/0' && $geno2 =~/1/){
        $type="Gain";
    }
    if($geno1 eq '1/1'&& $geno2 =~/0/){
        $type="Gain";
    }
    
    #Loss of heterozygous LOH
    if(($geno1 eq '0/1' || $geno1 eq '1/0') && ($geno2 eq '0/0' || $geno2 eq '1/1')){
        $type="LOH";
    }
    return $type;
}
