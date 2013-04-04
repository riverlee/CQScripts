use strict;
use warnings;
use Cwd;

my $fastqDir="/data/cqs/lij17/1668/rawdata/";

my $command="fastqc -o . -f fastq -t 8 ";
#foreach my $i (1..8){
foreach my $i (13..20){
    print "Runing $i ",scalar(localtime),"\n";
    my $f=$fastqDir."1668-WPT-${i}_sequence.txt";
        $command.=" $f ";
    } 

    `$command`;

