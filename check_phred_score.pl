#!/usr/bin/perl
use strict;
use warnings;

open(IN,$ARGV[0]) or die "perl $0 input [n]\n";

my $n=10;
if($ARGV[1] && $ARGV[1]=~/^\d/){$n=$ARGV[1];}
my %hash;
my $count=0;
while(<IN>){
    my $seq=<IN>;
    <IN>;
    my $qual=<IN>;
    $count++;
    if($count>=$n){
        last;
    }

    $qual=~s/\r|\n//g;
    foreach my $t (split  "",$qual){
        $hash{ord($t)}++;
    }
}

close IN;
print "Letter\tASCII\tTimes\n";
foreach my $t(sort {$a<=>$b} keys %hash){
    print join "\t",(chr($t),$t,$hash{$t});
    print "\n";

}
