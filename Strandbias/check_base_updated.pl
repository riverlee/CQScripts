#!/usr/bin/perl
#############################################
#Author: Jiang Li
#email: riverlee2008@gmail.com
#Creat Time: Thu 15 Sep 2011 08:41:43 AM CDT 
#Vanderbilt Center for Quantitative Sciences
#############################################
use strict;
use warnings;
use File::Basename;
#Usage: perl check_base_updated.pl 0 /home/lij17/pileup2
my $BQcut = $ARGV[0];
my $resultdir = $ARGV[1];
if($BQcut eq "" || $BQcut!~/^\d+$/ || $resultdir eq "" || !-d $resultdir){
	die "Usage:\n\tperl $0 BQcut resultdir\n\n";
}

my @FILES=<*.pileup>;
foreach my $file (@FILES){
	my($name,$dir,$ext) = fileparse($file,'\..*');
	my $wname=$resultdir."/BAQ".$BQcut."_".$name."base.txt";
	
	open FILE, $file or die "error, can not open $file";
    open WFILE, '>', $wname or die "error can not open $wname to write";
    print WFILE "chr\t"."loc\t"."ref\t"."A\t"."T\t"."C\t"."G\t"."a\t"."t\t"."c\t"."g\n";
    print "[",scalar(localtime),"] Running $name...\n";
    
    #begin parsing
    #my %check=();
    #start the reading of the file
    while(<FILE>){
    	s/\r|\n//g;
    	my($chr,$loc,$ref,$dp,$bases,$bq) = split /\s+/;
    	$ref=uc($ref);
    	
    	#do some modificaton on $base to remove additional characters
    	#1,remove the ^. pattern
    	$bases=~s/\^.//g;
    	#2,remove the $ pattern
    	$bases=~s/\$//g;
    	#3,remove -[0-9]+[ACGTNacgtn]+ pattern
    	my %hash=();
    	while($bases=~/-(\d+)/g){
			$hash{$1}=1;
		}
		foreach my $k (keys %hash){
			$bases=~s/-$k[ACGTNacgtn]{$k}//g;
		}
		%hash=();
		while($bases=~/\+(\d+)/g){
			$hash{$1}=1;
		}
		foreach my $k (keys %hash){
			$bases=~s/\+$k[ACGTNacgtn]{$k}//g;
		}
		
		#Now @base and @bq have the same length
		my @base=split (//,$bases);
		my @bq=split(//,$bq);
		#I have check it
		#if(scalar(@base) ne scalar(@bq)){
		#	print $_,"\n";
		#}
		#foreach my $c (@base){
		#	$check{$c}++;
		#}
		my $A=0;
		my $T=0;
		my $C=0;
		my $G=0;
		my $a=0;
		my $t=0;
		my $c=0;
		my $g=0;
		
		#start the loop
		for(my $i=0;$i<@base;$i++){
			my $ch=$base[$i];
			my $score=ord($bq[$i])-32;
			if($score>=$BQcut){
				if($ch eq "A"){
					$A++;
				}elsif($ch eq "T"){
					$T++;
				}elsif($ch eq "C"){
					$C++;
				}elsif($ch eq "G"){
					$G++;
				}elsif($ch eq "a"){
					$a++;
				}elsif($ch eq "t"){
					$t++;
				}elsif($ch eq "c"){
					$c++;
				}elsif($ch eq "g"){
					$g++;
				}elsif($ch eq "."){
					if($ref eq "A"){
						$A++;
					}elsif($ref eq "T"){
						$T++;
					}elsif($ref eq "C"){
						$C++;
					}elsif($ref eq "G"){
						$G++;
					}
				}elsif($ch eq ","){
					if($ref eq "A"){
						$a++;
					}elsif($ref eq "T"){
						$t++
					}elsif($ref eq "C"){
						$c++;
					}elsif($ref eq "G"){
						$g++;
					}
				}
			}#end the condition  $score>=$BQcut
		}#end the loop		
		print WFILE "$chr\t$loc"."\t".$ref."\t".$A."\t".$T."\t".$C."\t".$G."\t".$a."\t".$t."\t".$c."\t".$g."\n";	    	
    }#end the reading of the file
    close FILE;
    close WFILE;
    
    #for check
    #foreach my $k(keys %check){
    #	print $k,"==>",$check{$k},"\n";
    #}
    print "\n\n";
}

