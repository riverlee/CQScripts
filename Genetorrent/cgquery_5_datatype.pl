#!/usr/bin/perl
use strict;
use warnings;

#Use cgquery to get samples with data available for downloading which have DNA tumor exon sequencing, DNA blood normal exon sequencing and RNA tumor blood sequencing.

#my @disease_abbr=()

my $usage=<<USAGE;
usage: perl $0 disease_abbr

USAGE

die $usage if (@ARGV<1);
my $disease_abbr=$ARGV[0];

my $cgquery="/workspace/guoy1/GeneTorrent/usr/bin/cgquery";

#
#sample_type  01 means primary solid tumor
#library_strategy  WXS means whole exon sequencing, RNA-Seq means RNA sequencing
#analyte_code R means RNA D=DNA
#platform
#state  live means users can download the data
#


#Download DNA tumor
print "Download DNA tumor (01) \n";
my $query="disease_abbr=$disease_abbr&sample_type=01&library_strategy=WXS&analyte_code=D&platform=ILLUMINA&state=live";
my $comm = "$cgquery -a \"$query\"";
print $comm,"\n\n";
my $output = `$comm`;

open(OUT,">".$ARGV[0]."_DNA_exon_TP_raw.txt");
print OUT $output;

#Download DNA blood normal
print "Download DNA blood normal(10) \n";
$query="disease_abbr=$disease_abbr&sample_type=10&library_strategy=WXS&analyte_code=D&platform=ILLUMINA&state=live";
$comm = "$cgquery -a \"$query\"";
print $comm,"\n\n";
$output = `$comm`;

open(OUT,">".$ARGV[0]."_DNA_exon_NB_raw.txt");
print OUT $output;

#Download DNA SOLID tissue normal
print "Download DNA solid tissue normal(11) \n";
$query="disease_abbr=$disease_abbr&sample_type=11&library_strategy=WXS&analyte_code=D&platform=ILLUMINA&state=live";
$comm = "$cgquery -a \"$query\"";
print $comm,"\n\n";
$output = `$comm`;

open(OUT,">".$ARGV[0]."_DNA_exon_NT_raw.txt");
print OUT $output;

#Download RNA tumor
print "Download RNA tumor(01) \n";
$query="disease_abbr=$disease_abbr&sample_type=01&library_strategy=RNA-Seq&analyte_code=R&platform=ILLUMINA&state=live";
$comm = "$cgquery -a \"$query\"";
print $comm,"\n\n";
$output = `$comm`;

open(OUT,">".$ARGV[0]."_RNA_RNA-Seq_TP_raw.txt");
print OUT $output;

#Download RNA solid tissue normal
print "Download RNA solid tissue normal (11) \n";
$query="disease_abbr=$disease_abbr&sample_type=11&library_strategy=RNA-Seq&analyte_code=R&platform=ILLUMINA&state=live";
$comm = "$cgquery -a \"$query\"";
print $comm,"\n\n";
$output = `$comm`;

open(OUT,">".$ARGV[0]."_RNA_RNA-Seq_NT_raw.txt");
print OUT $output;


#convert DNA tumor to table
print "Convert raw data to table format \n";
my %dnatumor=raw2table($ARGV[0]."_DNA_exon_TP_raw.txt",$ARGV[0]."_DNA_exon_TP_table.txt");
my %dnablood=raw2table($ARGV[0]."_DNA_exon_NB_raw.txt",$ARGV[0]."_DNA_exon_NB_table.txt");
my %rnatumor=raw2table($ARGV[0]."_RNA_RNA-Seq_TP_raw.txt",$ARGV[0]."_RNA_RNA-Seq_TP_table.txt");

my %dnanormal=raw2table($ARGV[0]."_DNA_exon_NT_raw.txt",$ARGV[0]."_DNA_exon_NT_table.txt");
my %rnanormal=raw2table($ARGV[0]."_RNA_RNA-Seq_NT_raw.txt",$ARGV[0]."_RNA_RNA-Seq_NT_table.txt");

#Get sample with three datasets

#Get sample with three datasets
print "Get samples with 5 data available \n";
my @o = overlapFive(\%dnatumor,\%dnablood,\%rnatumor,\%dnanormal,\%rnanormal);
open(OUT,">".$ARGV[0]."_five_table.txt") or die $!;
print OUT join "\t",("sample","DNA_NB-legacy_sample_id","DNA_NB-filename","DNA_NB-filesize","DNA_NB-analysis_data_uri",
                    "DNA_NT-legacy_sample_id","DNA_NT-filename","DNA_NT-filesize","DNA_NT-analysis_data_uri", 
                    "DNA_TP-legacy_sample_id","DNA_TP-filename","DNA_TP-filesize","DNA_TP-analysis_data_uri",
                   
                    "RNA_NT-legacy_sample_id","RNA_NT-filename","RNA_NT-filesize","RNA_NT-analysis_data_uri", 
                    "RNA_TP-legacy_sample_id","RNA_TP-filename","RNA_t-filesize","RNA_TP-analysis_data_uri\n");
foreach my $s (@o){
    print OUT join "\t",($s,@{$dnablood{$s}}, @{$dnanormal{$s}}, @{$dnatumor{$s}},@{$rnanormal{$s}},@{$rnatumor{$s}});
    print OUT "\n";
}





sub overlapFive{
    my ($ref1,$ref2,$ref3,$ref4,$ref5) = @_;
    my @o12 = grep {exists($ref2->{$_})} keys %{$ref1};  #overlap between ref1 and ref2
    my @o123 = grep {exists($ref3->{$_})} @o12;
    my @o1234 = grep {exists($ref4->{$_})} @o123;
    my @o12345 = grep {exists($ref5->{$_})} @o1234;
    return @o12345;
}

sub raw2table{
    my ($in,$out) = @_;
    my %hash;
    open(IN, "sed -n '/Result /,\$p' $in |") or die $!;
    open(OUT,">$out") or die $!;
    print OUT join "\t",("Sample","legacy_sample_id","filename","filesize","analyte_code","sample_type","analysis_data_uri\n");
    my @lines=<IN>;

    if(@lines){
        for(my $i=0;$i<@lines;){
            my @tmp=@lines[$i..($i+28)];
            $i+=29;
            my ($sample,$legacy_sample_id,$filename,$filesize,$analyte_code,$sample_type,$analysis_data_uri) =( "","","","","","","","");
            my $string=join "" ,@tmp;
            if($string=~/analysis_data_uri\s+: (.*?)\n/){
                $analysis_data_uri=$1;
            }

            if($string=~/legacy_sample_id\s+: (.*?)\n/){
                $legacy_sample_id=$1;
            }

            if($string=~/analyte_code\s+: (.*?)\n/){
                $analyte_code=$1;
            }

            if($string=~/sample_type\s+: (.*?)\n/){
                $sample_type=$1;
            }

            if($string=~/filename\s+: (.*?)\n/){
                $filename=$1;
            }
            if($string=~/filesize\s+: (.*?)\n/){
                $filesize=$1;
            }

            if($legacy_sample_id=~/(TCGA\-\w{2}\-\w{4})/){
                $sample=$1;
            }

            print OUT join "\t",($sample,$legacy_sample_id,$filename,$filesize,$analyte_code,$sample_type,$analysis_data_uri);
            $hash{$sample}=[$legacy_sample_id,$filename,$filesize,$analysis_data_uri];
            print OUT "\n";
        }
    }
    return %hash;
}





