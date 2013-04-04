#!/usr/bin/perl
use strict;
use warnings;

#get gene related 
my $rodenfile="/home/lij17/Documents/projects/guoyan1/roden/newvcf/myannovar/dilqt.filtered.annovar.exonic_variant_function";
#my $kfile="/data/cqs/guoy1/roden/geneMutation/PSEQ/another/annovar/1K294.annovar.exonic_variant_function";
open(LOG,">runing.log") or die $!; select(LOG);$|=1;

my $gene2snpref={};
my $snp2generef={};
print LOG "[",scalar(localtime),"Parsing Roden Exonic...\n";
parseExonic($rodenfile,$gene2snpref,$snp2generef);
#print LOG "[",scalar(localtime),"Parsing 1k Exonic...\n";
#parseExonic($kfile,$gene2snpref,$snp2generef);

#
my $rodenvcf="/home/lij17/Documents/projects/guoyan1/roden/newvcf/newAnalysis/pseq/data/dilqt.67_gq10_dp3_without_chrXY_non-synonymous.vcf";
my $kvcf = "/home/lij17/Documents/projects/guoyan1/roden/newvcf/newAnalysis/pseq/data/1K379_without_chrXY_overlapped_non-synonymous.vcf";
my %result;

#read roden
print LOG "[",scalar(localtime),"] Reading roden ..\n";
my %roden;
open(IN,$rodenvcf) or die $!;
while(<IN>){
    s/\r|\n//g;
    next if (/^#/ || /^$/);
    my ($chr,$start,$id,$ref,$alt,$score,$pass,$info,$format,@genotypes) = split "\t";
    my $key = join "_",($chr,$start);
    if(exists($snp2generef->{$key})){
        $roden{$key}->{'ref'}=$ref;
        $roden{$key}->{'alt'}=$alt;
        my @value;
        foreach my $geno (@genotypes){
            my ($g) = split ":",$geno;
            if($g=~/\./){
                push @value,0;
            }elsif($g eq '0/0'){
                push @value,0;
            }elsif($g eq '0/1' || $g eq '1/0'){
                push @value,1;
            }elsif ($g eq '1/1'){
                push @value,2;
            }else{
                push @value,0;
            }
        }
        $roden{$key}->{'value'}=[@value];
    }
}
close IN;
print LOG "[",scalar(localtime),"]Reading 1k..\n";
open(IN,$kvcf) or die $!;
my %chrom;
my %k379;

while(<IN>){
    s/\r|\n//g;
    next if (/^#/ || /^$/);
    my ($chr,$start,$id,$ref,$alt,$score,$pass,$info,$format,@genotypes) = split "\t";
    my $key = join "_",($chr,$start);
    unless($chrom{$chr}++){
        print LOG "[",scalar(localtime),"]Doing $chr ...\n";
    }
    if(exists($snp2generef->{$key})){
        $k379{$key}->{'ref'}=$ref;
        $k379{$key}->{'alt'}=$alt;
        my @value;
        foreach my $geno (@genotypes){
            my ($g) = split ":",$geno;
            if($g=~/\./){
                push @value,0;
            }elsif($g eq '0/0'){
                push @value,0;
            }elsif($g eq '0/1' || $g eq '1/0'){
                push @value,1;
            }elsif ($g eq '1/1'){
                push @value,2;
            }else{
                push @value,0;
            }
        }
        $k379{$key}->{'value'}=[@value];
    }
}

print LOG "[",scalar(localtime),"]Write out...\n";
#chdir("/scratch/cqs/guoy1/SBCS/lij17");
##Print OUT the result;
if (! -d "genes"){
    mkdir "genes";
}
chdir("genes");
foreach my $g (sort keys %{$gene2snpref}){
    if($g eq "A1BG"){
        print "af";
    }
    my %result;
    foreach my $key(sort keys %{$gene2snpref->{$g}} ){
        #roden;
        my @tmprodenvalue;
        foreach (1..67){
            push @tmprodenvalue,0;
        }
        my @tmpk379value;
        foreach (1..379){
            push @tmpk379value,0;
        }
        my @value;
        if(exists($roden{$key})){
            push @value, @{$roden{$key}->{'value'}};
        }else{
            push @value,@tmprodenvalue;
        }
        
        if(exists($k379{$key})){
            push @value, @{$k379{$key}->{'value'}};
        }else{
            push @value,@tmpk379value;
        }
         $result{$key}=[@value];
    }
    
    
    my @snps=sort keys %result;
    open(OUT,">${g}.txt") or die $!;
    print OUT join "\t",("STATUS",@snps);
    print OUT "\n";
    for(my $i=0;$i<67;$i++){
        print OUT "1";
        foreach my $snp(@snps){
            print OUT "\t",$result{$snp}->[$i];
        }
        print OUT "\n";
    }
    for(my $i=67;$i<67+379;$i++){
        print OUT "0";
       foreach my $snp(@snps){
            print OUT "\t",$result{$snp}->[$i];
        }
        print OUT "\n";
    }
    close OUT;
}







sub parseExonic{
    my ($infile,$gene2snpref,$snp2generef) = @_;
    open(IN,$infile)  or die $!;
    while(<IN>){
        my($line,$type,$genes,$chr,$start,$end,$ref,$alt,@others) = split "\t";
        if($type eq 'nonsynonymous SNV'||
      $type eq "stopgain SNV" ||
      $type eq "stoploss SNV"){
            my ($gene) = split (/:/,$genes);
            my $snp = join "_",($chr,$start);
            $gene2snpref->{$gene}->{$snp}=1;
            $snp2generef->{$snp}->{$gene}=1;
        }
    }
    close IN;
}

