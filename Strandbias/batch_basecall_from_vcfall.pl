#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my ($mdata,$mmethod) = @ARGV; #if provide dataset and alignemt method
my $currentdir=getcwd;

my @data=("1000G","TrueSeq","SureSelect");

my @methods=("vcf_realignment");

my $script="check_base_updated.pl";
my $BQcut=20;


my $dirname="basecall"; #to create thisfolde if not exists

foreach my $data (@data){
    next  if($mdata && $mdata ne $data);
    print "Entering $data ...\n";
#    my $list = $currentdir."/".$data."/".$listFile;
    # my $list=$listFile{$data};
    
    #/workspace/StrandBias/lij17/1000G
    chdir($data);
    if(! -d $dirname){
        mkdir $dirname;
    }

    #/workspace/StrandBias/lij17/1000G/pileup
    chdir ("pileup");

    foreach my $m (@methods){
        next if ($mmethod && $mmethod ne $m);
        print "\tMethod: $m..\n";

        if(! -d "$currentdir/$data/$dirname/$m"){
            mkdir "$currentdir/$data/$dirname/$m";
        }
        #/workspace/StrandBias/lij17/1000G/pileup/firstalignment
        chdir $m or die $!;
        
        #copy the $script to this directory
        `cp $currentdir/$script ./`;

        my $command="perl $script $BQcut $currentdir/$data/$dirname/$m";
        print "\t\tPWD:",`pwd`;
        print "\t\t$command\n";
         `$command`;
        chdir ("../");
    }
    #chdir ("../");
    
    #back to the /workspace/StrandBias
    chdir ($currentdir)
}

