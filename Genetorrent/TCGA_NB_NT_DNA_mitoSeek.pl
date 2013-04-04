#!/usr/bin/env perl
###################################
# Author: Jiang (River) Li
# Email:  riverlee2008@gmail.com
# Date:   Tue Dec 18 10:57:16 2012
###################################
use strict;
use warnings;

=head1 SYNOPSIS

  perl TCGA_NB_NT_DNA_mitoSeek.pl BRCA

=head1 DESCRIPTION

Download normal blood (NB) and solid tissue normal samples' DNA-Seq of different cancers if available and
run MitoSeek on it to discorver heteroplasmy

=cut


my %cancer;
initcancer();
usage() if (@ARGV !=1 || ! exists($cancer{$ARGV[0]}));

my $cancer              = $ARGV[0];
my $cgquerybin          = "/workspace/guoy1/GeneTorrent/usr/bin/cgquery";
my $cgqueryoutput       = "cgquery.output.txt";
my $cgqueryoutputtable  = "cgquery.table.txt";
my $genetorrentbin      = "/workspace/guoy1/GeneTorrent/usr/bin/GeneTorrent";
my $genetorrentshare    = "/workspace/guoy1/GeneTorrent/usr/share/GeneTorrent";
my $genetorrentkey      = "/workspace/guoy1/GeneTorrent/mykey.pem";
my $mylogfile           = "run.log";
my $mitoseek            = "/workspace/lij17/mitoSeek/MitoSeek/mitoSeek.pl";

mkdir $cancer if(! -d $cancer);
chdir $cancer or die $!;
#Step 1), Usage cgquery searching
open(LOG,">$mylogfile") or die $!;
cgquerysearching();

   print LOG "\n";
   print "\n";
#Step 2) convert raw output
my ($sample_array_ref,$sample_hash_ref) = raw2table($cgqueryoutput,$cgqueryoutputtable);

   print LOG "\n";
   print "\n";
#Step 3) Download a sample and mitoseek on it and then delete the downloaded file
my $count=0;
foreach my $s (@{$sample_array_ref}){
   $count++;
   print LOG "Doing $count \n";
   print "Doing $count \n";
   my $bam = genetorrent($s,$sample_hash_ref->{$s});
   next if ($bam eq "FAIL");
   mitoSeek($bam); #no mether fail or success, always move to next step
   clean($bam);
   print LOG "\n";
   print "\n";
}


sub clean{
    my($bam) = @_;
    mylog("Starting delete $bam \n");
    if(-e $bam ){
        my $comm="rm -rf $bam";
        if(system($comm) !=0){
            mylog("Delete Finished (Error: $?)\n");
        }else{
            mylog("Delete Finished (Success)\n");
        }
    }else{
        mylog("Delete Finished (Error: $bam not exists)\n");
    }
}

sub mitoSeek{
    my ($bam) = @_;
    mylog("Starting MitoSeek on '$bam'...\n");
    my $inref = "rCRS";
    my $comm = "perl $mitoseek -i $bam -r $inref -R rCRS -t 1 -hp 1 -ha 0 -d 20 -sb 0 -str 4";
    mylog("MitoSeek Command: $comm\n");
    if(system($comm) !=0){
        mylog("MotiSeek Finished (Error:$?)\n");
    }else{
        mylog("MotiSeek Finished (Success)\n");
    }
}

#Download sample
sub genetorrent{
    my($samplename,$url) = @_;
    mylog("Downloading '$samplename' with url='$url' ...\n");
    my $comm = "$genetorrentbin -d $url -c $genetorrentkey -p . -C $genetorrentshare";
    mylog("Download command: $comm\n");
    
    if(system($comm) !=0){
        mylog("Download Finished (Error:$?)\n");
        return "FAIL";
    }else{
        mylog("Download Finished (Success)\n");
        #rename the download file
        my @tmp = <*.gto>;
        my $id=$tmp[0];
        $id=~s/\.gto//g;
        $comm="mv $id/*.bam $samplename.bam; rm -rf $id*";
        mylog("Staring move and rename file: $comm \n");
        if(system($comm) !=0){
           mylog("Move and rename Finished (Error: $?)\n");
           return "FAIL";
        }else{
            mylog("Move and rename Finished (Success)\n");
            return "$samplename.bam";
        }
    }
}

#Convert cgquery output to tab sperated format
sub raw2table{
    my ($in,$out) = @_;
    mylog("Convert cgquery rawouput to tab separted format (Output: $out)\n");

    my %hash;
    my @samples;
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
            $hash{$legacy_sample_id}=$analysis_data_uri;
            push @samples,$legacy_sample_id;
            print OUT "\n";
        }
    }
    mylog("Convert cgquery finished (Total records:".scalar(@samples).")\n");
    return (\@samples,\%hash);
}

sub mylog{
    my ($str) = @_;
    my $time=scalar(localtime);
    print LOG "[$time] $str";
    print "[$time] $str";
}
sub cgquerysearching{
    mylog("Starting cgquery ...\n");
    my $sample_type_NB=10;  #normal blood;
    my $sample_type_NT=11;  #solid tissue normal
    my $library_strategy = "WXS";  #details at http://www.ebi.ac.uk/ena/about/sra_library_strategy
    my $query = "disease_abbr=$cancer&sample_type=($sample_type_NB OR $sample_type_NT)&library_strategy=$library_strategy&analyte_code=D&platform=ILLUMINA&state=live";
    my $comm = "$cgquerybin -a \"$query\" > $cgqueryoutput";

    mylog("cqguery command: $comm\n");
    if(system($comm) !=0){
        mylog("cqguery error: $?\n");
        print STDERR "Cgquery error: $?\n";
        print STDERR "Command: $comm\n";
        exit(1);
    }
    mylog("cgquery finished\n");
}


sub usage{
    print "Usage:\n\tperl $0 cancer_abbr \n";
    print "=" x 100,"\n";
    print "Current availabe cancers from TCGA \n(https://tcga-data.nci.nih.gov/datareports/codeTablesReport.htm) are:\n";
    print '-' x 100, "\n";
    printf "%-15s%-20s\n","Abbreviation","Name";
    foreach my  $k (sort keys %cancer){
        printf "%-15s%-20s\n",$k,$cancer{$k};
    }
    exit(1);
}

sub initcancer{
    while(<DATA>){
        s/\r|\n//g;
        my ($abbre,$name) = split (/\s+/,$_,2);
        $cancer{$abbre} = $name;
    }
}
__DATA__
LAML    Acute Myeloid Leukemia
BLCA    Bladder Urothelial Carcinoma
LGG Brain Lower Grade Glioma
BRCA    Breast invasive carcinoma
CESC    Cervical squamous cell carcinoma and endocervical adenocarcinoma
LCLL    Chronic Lymphocytic Leukemia
COAD    Colon adenocarcinoma
CNTL    Controls
ESCA    Esophageal carcinoma 
GBM Glioblastoma multiforme
HNSC    Head and Neck squamous cell carcinoma
KICH    Kidney Chromophobe
KIRC    Kidney renal clear cell carcinoma
KIRP    Kidney renal papillary cell carcinoma
LIHC    Liver hepatocellular carcinoma
LUAD    Lung adenocarcinoma
LUSC    Lung squamous cell carcinoma
DLBC    Lymphoid Neoplasm Diffuse Large B-cell Lymphoma
MESO    Mesothelioma
OV  Ovarian serous cystadenocarcinoma
PAAD    Pancreatic adenocarcinoma
PRAD    Prostate adenocarcinoma
READ    Rectum adenocarcinoma
SARC    Sarcoma
SKCM    Skin Cutaneous Melanoma
STAD    Stomach adenocarcinoma
THCA    Thyroid carcinoma
UCS Uterine Carcinosarcoma
UCEC    Uterine Corpus Endometrioid Carcinoma
