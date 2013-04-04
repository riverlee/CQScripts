#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $currentdir=getcwd;

my $usage="usage: perl $0 fivefile disease\n\n";

die $usage if (@ARGV<2);
my ($in,$disease) = @ARGV;
die $usage if (! -e $in);
mkdir $disease if (! -d $disease);
mkdir "$disease/DNA_TP" if (! -d "$disease/DNA_TP");
mkdir "$disease/DNA_NB" if (! -d "$disease/DNA_NB");
mkdir "$disease/DNA_NT" if (! -d "$disease/DNA_NT");
mkdir "$disease/RNA_TP" if (! -d "$disease/RNA_TP");
mkdir "$disease/RNA_NT" if (! -d "$disease/RNA_NT");

open(IN,$in) or die $!;
open(LOG,">$disease/download.log") or die $!;

<IN>;
while(<IN>){
    s/\r|\n//g;
    my ($sample,
        undef,undef,undef,$dna_nb_url,
        undef,undef,undef,$dna_nt_url,
        undef,undef,undef,$dna_tp_url,
        undef,undef,undef,$rna_nt_url,
        undef,undef,undef,$rna_tp_url)=split "\t";
        
        print LOG info()," $sample\n";
        download($dna_nb_url,"DNA_NB");
        download($dna_nt_url,"DNA_NT");
        download($dna_tp_url,"DNA_TP");
        download($rna_nt_url,"RNA_NT");
        download($rna_tp_url,"RNA_TP");
        print LOG "\n";

}

sub download{
    my($url,$name) = @_;
    print LOG "\t",info()," Dowloading $name ...\n";
    my $comm = "/workspace/guoy1/GeneTorrent/usr/bin/GeneTorrent -d $url -c /workspace/guoy1/GeneTorrent/mykey.pem -p $disease/$name -C /workspace/guoy1/GeneTorrent/usr/share/GeneTorrent/";
    print $comm,"\n";
    `$comm`;
}


sub info{
    return "[".scalar(localtime),"]";
}
