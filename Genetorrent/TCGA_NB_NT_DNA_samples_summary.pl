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

my $cgquerybin          = "/workspace/guoy1/GeneTorrent/usr/bin/cgquery";

open(OOO,">samples_summary_of_each_cancer.txt");
print OOO join "\t",("Abbr","#Samples","Name\n");

print "Total ",scalar(keys %cancer), " Cancers\n";
my $count =1;
foreach my $cancer (sort keys %cancer){
        print "[",scalar(localtime),"]",$count++," Doing $cancer ...\n";
        my $cgqueryoutput = cgquerysearching($cancer);
        my $table = "cgquery_table_output_${cancer}.txt";
        my $n= raw2table($cgqueryoutput,$table); 
        print OOO join "\t",($cancer,$n,$cancer{$cancer});
        print OOO "\n";
        
}

#Convert cgquery output to tab sperated format
sub raw2table{
    my ($in,$out) = @_;

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
    # return (\@samples,\%hash);
    return scalar(keys %hash);
}
sub cgquerysearching{
    my ($cancer) = @_;
    my $cgqueryoutput = "cgquery_raw_output_${cancer}.txt";
    my $sample_type_NB=10;  #normal blood;
    my $sample_type_NT=11;  #solid tissue normal
    my $library_strategy = "WXS";  #details at http://www.ebi.ac.uk/ena/about/sra_library_strategy
    my $query = "disease_abbr=$cancer&sample_type=($sample_type_NB OR $sample_type_NT)&library_strategy=$library_strategy&analyte_code=D&platform=ILLUMINA&state=live";
    my $comm = "$cgquerybin -a \"$query\" > $cgqueryoutput";

    if(system($comm) !=0){
        print STDERR "Cgquery error: $?\n";
        print STDERR "Command: $comm\n";
        exit(1);
    }
    return $cgqueryoutput;
}



sub initcancer{
    while(<DATA>){
        s/\r|\n//g;
        my ($abbre,$name) = split (/\s+/,$_,2);
        $cancer{$abbre} = $name;
        #print $abbre,"\n";
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
