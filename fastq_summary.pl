#!/usr/bin/env perl
###################################
# Author: Jiang (River) Li
# Email:  riverlee2008@gmail.com
# Date:   Fri Mar 29 12:09:49 2013
###################################
use strict;
use warnings;

my $usage="perl $0 fastqfile.list output\n";

# each line is a file name
my ($filelist,$output)=@ARGV;
die $usage if(!defined($filelist) or ! -e $filelist  or !defined($output));

open(OUT,">$output");
print OUT join "\t",("#Sample","Instrument","RunNumber","Flowcell","Lane",
                 "TotalReads","Reads(Y)","Reads(N)",
                 "BQ","BQ(Y)","BQ(N)",
                 "GC","GC(Y)","GC(N)\n");

open(IN,$filelist) or die $!;
while(my $f = <IN>){
    $f=~s/\r|\n//g;
    info("Processing $f ");
    my @metric=getmetric($f);
    print OUT join "\t",($f,@metric);
    print OUT "\n";
}

close IN;
close OUT;


sub getmetric{
    my ($in) = @_;
    open(IIN,$in) or die $!;
    my @r; #return values
    my $instrument="";
    my $run="";
    my $flowcell="";
    my $lane="";

    my $first=1;
    
    my $totalreads=0;
    my $totalreadsy=0;
    my $totalreadsn=0;
    
    my $bq=0;
    my $bqy=0;
    my $bqn=0;
    
    my $gc=0;
    my $gcy=0;
    my $gcn=0;
    
    my $totalnuclear=0;
    my $totalnucleary=0;
    my $totalnuclearn=0;

    my $offset=33;  #default;

    #will use the top 40 reads to guess the offset
    my $guessoffset=0;
    my @scores;

    while(my $line1=<IIN>){
        my $line2=<IIN>;
        my $line3=<IIN>;
        my $line4=<IIN>;
        if($line1=~/@(.*?):(.*?):(.*?):(.*?):(.*?):(.*?):(.*?)\s+(.*?):(.*?):(.*?):(.*?)/){
            my($instrument1,$runid,$flowcellid,$lane1,$tilenumber,$x,$y,$pair,$failed,$n,$index)= ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);
            if($first){
                $instrument=$instrument1;
                $run=$runid;
                $flowcell=$flowcellid;
                $lane=$lane1;
                $first=0;
            }
            $totalreads++;

            my $readlen=length($line2);
            
            $totalnuclear+=$readlen;

            my $gcnum=0;
            foreach my $s(split //,$line2){
                $gcnum++ if($s=~/c|g/i);
            }
            $gc+=$gcnum;

            my @tmpscores;
            foreach my $s (split //,$line4){
                push @tmpscores,ord($s);
            }
            my $tmpbq=mymean(@tmpscores);
            $bq+=$tmpbq;

            if($totalreads<10){
                push @scores,@tmpscores;
            }elsif(! $guessoffset){
                # guess the offset
                $offset=guessoffset(@scores);
                $guessoffset=1;
            }

            if($failed eq "Y"){
                $bqy+=$tmpbq;
                $gcy+=$gcnum;
                $totalreadsy++;
                $totalnucleary+=$readlen;
            }else{
                $bqn+=$tmpbq;
                $gcn+=$gcnum;
                $totalreadsn++;
                $totalnuclearn+=$readlen;
            }
        }else{
            print STDERR "Not in casava 1.8 format\n";
        }
    }
    close IIN;
    if(! $guessoffset){
        $offset=guessoffset(@scores)
    }
    push @r,($instrument,$run,$flowcell,$lane,$totalreads,$totalreadsy,$totalreadsn);
    #add bq
    push @r,($bq/$totalreads-$offset,$bqy/$totalreadsy-$offset,$bqn/$totalreadsn-$offset);

    #add gc
    push @r,($gc/$totalnuclear,$gcy/$totalnucleary,$gcn/$totalnuclearn);

    return @r;
}


sub mymean{
    my @a=@_;
    unless(scalar(@a)){
        return 0;
    }
    my $t=0;
    foreach my $tt(@a){
        $t+=$tt;
    }
    return $t/scalar(@a);
}
sub guessoffset{
    my (@a) = @_;
    @a=sort {$a<=>$b} @a;
    my $offset=33;
    my $lowest=$a[0];
    if($lowest<59){
        $offset=33;
    }elsif($lowest <64){
        $offset=59;
    }else{
        $offset=64;
    }
    return $offset;
}
sub info{
    my $s=shift;
    print "[",scalar(localtime),"] $s\n";
}
