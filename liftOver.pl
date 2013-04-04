use strict;
use warnings;

#input file and output file after liftOver
my $infile = "hg18_position.txt";  
my $outfile = "hg18_to_hg19_mapping.txt";

#temperate files will be used
my $tmp1 = "t1";
my $new  = "t2";
my $unmapped = "t3";

#chain file 
my $chainfile = "hg18ToHg19.over.chain";
#in order to change into bed format, this is used to be added at the start position
my $extendLen=100;

open(IN,$infile) or die $!;
my %mapping;
print "[ ",scalar(localtime)," ]Start to change into Bed format....\n";

my $count=0;
while(<IN>){
    $count++;
    s/\r|\n//g;
    my($chr,$pos) = split "\t";
    my $chrold = $chr;
    if($chr eq "23"){
        $chr = "chrX";
    }elsif($chr eq "24"){
        $chr = "chrY";
    }elsif($chr eq "26"){
        $chr = "chrM";
    }else{
        $chr="chr".$chr;
    }
    

    if($count % 1000 ==0){
        print "[ ",scalar(localtime)," ]RUNNING $count ...\n";
    }
    open(OUT,">${tmp1}") or die $!;
    my $end = $pos+$extendLen;
    print OUT join "\t",($chr,$pos,$end);
    print OUT "\n";
    close OUT;

    my $key = join "\t",($chrold,$pos);
    system("liftOver $tmp1 $chainfile $new $unmapped >/dev/null 2>&1");
    
    #if there are content for $new
    my $l = `head -n 1 $new`;
    if($l ne ""){
        my ($chr,$start,$end) = split "\t",$l;
        $mapping{$key}=join "\t",($chr,$start);
    }
}

open(OUT,">$outfile") or die $!;
foreach my $k (sort keys %mapping){
    print OUT join "\t",($k,$mapping{$k});
    print OUT "\n";
}

close OUT;

