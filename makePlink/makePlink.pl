#!/usr/bin/env perl
###################################
# Author: Jiang (River) Li
# Email:  riverlee2008@gmail.com
# Date:   Thu Mar 14 15:16:42 2013
###################################
use strict;
use warnings;
use Storable;
use Getopt::Long qw(:config no_ignore_case);

my ($genotypefile,$snpfile,$samplefile);
my $prefix="plink";
my $isvcf=0;
my $help=0;

unless(
    GetOptions(
        "g=s"=>\$genotypefile,
        "snp=s"=>\$snpfile,
        "s=s"=>\$samplefile,
        "prefix=s"=>\$prefix,
        "vcf"=>\$isvcf,
        "h"=>\$help
    )
){
    print $!,"\n";
    usage(1);
}

#1) Check parameter
info("Checking parameters...");
check();

#2) Load SNP information
info("Loading SNP information ...");
my $dbsnpref=loadsnp($snpfile,$isvcf);

#3) If exists sample file, load sample
my %sample2sex;
if(defined($samplefile)){
    info("Loading sample information (for sex encoding) ...");
    getsamplesex($samplefile,\%sample2sex);
}

#4) Print out ped and map file
open(IN,$genotypefile) or die $!;
open(PED,">${prefix}.ped") or die $!;
open(MAP,">${prefix}.map")or die $!;
open(UNMAP,">${prefix}_removed_SNPs.txt") or die $!;

my $line=<IN>; $line=~s/\r|\n//g;
my %keep;
my @SNPS = split ",",$line; 
shift(@SNPS);

#Load the genotype data
my %dbsnp2sample;
my %samples;

while(<IN>){
    s/\r|\n//g;
    my($samplename,@a) = split ",";
    my $sex="-9";
    if(exists($sample2sex{$samplename})){
        if($sample2sex{$samplename}=~/^m$/i ||
           $sample2sex{$samplename}=~/^male$/i ||
           $sample2sex{$samplename} eq "1"){
            $sex=1;  #male
       }
        if($sample2sex{$samplename}=~/^f$/i ||
           $sample2sex{$samplename}=~/^female$/i ||
           $sample2sex{$samplename} eq "2"){
            $sex=2;  #female
       }
    }
    
    my $samplekey=join "\t",("F_".$samplename,$samplename,0,0,$sex,"-9");
    $samples{$samplekey}++;

    for(my $i=0;$i<@a;$i++){
        my $snp=$SNPS[$i];
        my($geno)=$a[$i];
        $geno="" unless(defined($geno));
        $geno="" if ($geno eq 'Undetermined');
        my $formatgeno="";
        if($geno=~/DEL/){
            $geno=~s/DEL//g;
            if($geno eq ""){
                $formatgeno="D\tD";
            }elsif($geno=~/^[ATCG]$/){
                $formatgeno="$geno\tD";
            }else{
                $formatgeno="D\tD";
            }
        }elsif($geno eq "" || $geno eq "0"){
            $formatgeno="0\t0";
        }else{
            my($a,$b)=split "",$geno;
            if($b){
                $formatgeno="$a\t$b";
            }else{
                $formatgeno="$a\t$a";
            }
        }
        $dbsnp2sample{$snp}->{$samplekey}=$formatgeno;
    }
}

# Whether it has dbsnp rs id
for(my $i=0;$i<@SNPS;$i++){
    if(!exists($dbsnpref->{$SNPS[$i]})){
        print UNMAP $SNPS[$i],"\t","No rsid matched\n";
        delete($dbsnp2sample{$SNPS[$i]});
    }
}

# Check wether there has snp with 2> alleles
foreach my $snp (keys %dbsnp2sample){
    my %tmphash;
    foreach my $s (keys %{$dbsnp2sample{$snp}}){
        my($a,$b)=split "\t",$dbsnp2sample{$snp}->{$s};
        $tmphash{$a}++ if ($a ne "0");
        $tmphash{$b}++ if ($b ne "0");
    }
    if(scalar(keys %tmphash)>2){
        print UNMAP $snp,"\tallles>2\n";
        delete($dbsnp2sample{$snp});
    }
}

#Write the the ped and map
my @snps=sort keys %dbsnp2sample;
my @samples=sort keys %samples;
foreach my $snp (@snps){
    my ($chr,$pos)=split "\t",$dbsnpref->{$snp};
    print MAP join "\t",($chr,$snp,0,$pos."\n");
}


foreach my $s (@samples){
    print PED $s;
    foreach my $snp (@snps){
        print PED "\t",$dbsnp2sample{$snp}->{$s};
    }
    print PED "\n";
}

close PED;
close IN;
close MAP;
close UNMAP;




sub getsamplesex{
    my($in,$ref) = @_;
    open(IN,$in) or die $!;
    my $header=<IN>;
    $header=~s/\r|\n//g;
    my @header=split "\t",$header;
    my %map;
    map {$map{$header[$_]}=$_} 0..$#header;
    if(exists($map{'CASE_STUDY_ID_RUID'}) && exists($map{'SEX'})){
        while(<IN>){
            s/\r|\n//g;
            my @a = split "\t";
            $ref->{$a[$map{'CASE_STUDY_ID_RUID'}]} = $a[$map{'SEX'}];
        }
        close IN;
    }
}


sub loadsnp{
    my($snpfile,$isvcf)=@_;
    my $ref={};
    if($isvcf){
        open(VCF,$snpfile) or die $!;
        while(<VCF>){
            next if (/^#/);
            my($chr,$pos,$rs) = split "\t";
            $ref->{$rs}="$chr\t$pos";
        }
        close VCF;
    }else{
        $ref=retrieve($snpfile);
    }
    return $ref;
}
sub info{
    my $s=shift;
    print "[",scalar(localtime),"] $s\n";
}


sub check{
    usage(1) if ($help);
    
    my $msg="";
    if(!defined($genotypefile)){
        $msg.="-g not provided\n";
    }elsif(! -e $genotypefile){
        $msg.="-g=$genotypefile not exists\n";
    }

    if(! defined($snpfile)){
        $msg.="-snp not provided\n";
    }elsif(! -e $snpfile){
        $msg="-snp=$snpfile not exists\n";
    }

    if(defined($samplefile) && ! -e $samplefile){
        $msg="-s=$samplefile not exists\n";
    }

    if($msg ne ""){
        print $msg;
        usage(1);
    }
}

sub usage{
    my ($flag) = @_;
    print <<USAGE;
   Usage: perlPlink.pl -g <genotypefile> -snp <dbsnpfile> -s [sample description file] -prefix [prefix] -h
         -g       genotype file in csv format(fist column is the SAMPLE_NAME, while the left are SNP ids)
         -snp     dbsnp file either in vcf format or perl storable format, see script serializeDBSNP.pl to 
                  how to make a perl storable format file from a vcf file, default is perl stroable format, use
                   -vcf to indicate it as vcf format
        -s        sample description file, seperated by 'tab', two columns are necessary, CASE_STUDY_ID_RUID 
                  corresponds to SAMPLE_NAME in the genotype file, SEX column will be used in the output ped file(M=>1,F=>2)
        -vcf      indicate the input snp file is in vcf format
        -prefix   will generate ped file and map file, named as prefix.ped and prefix.map, default is -prefix=plink
        -h        print out this help
USAGE
    if($flag){
        exit(1);
    }
}

