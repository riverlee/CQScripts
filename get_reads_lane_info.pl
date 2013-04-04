#!/usr/bin/perl
#############################################
#Author: Jiang Li
#email: riverlee2008@gmail.com
#Creat Time: Sat 07 Jul 2012 09:20:30 PM CDT 
#Vanderbilt Center for Quantitative Sciences
#############################################
use strict;
use warnings;
use Getopt::Long;

=head main
Parse the header in the fastq format file to get the 
run and lane information for illumina sequences
=cut

my ($in,$casava18,$help)=(undef,0,undef);
GetOptions(
	"i|input=s"=>\$in,
	"c|casava18"=>\$casava18,
	"h|help"=>\$help
);

my $usage = <<USAGE;

Usage: perl get_reads_lane_info.pl -i/--input <inputfile> -c/--casava18 -h/--help
     -i/--input    input fastq file
     -c/--casava18 indicate the header is in Casava 1.8 format 
     -h/--help     help page
     
Default header format(see at http://en.wikipedia.org/wiki/FASTQ_format)

\@HWUSI-EAS100R:6:73:941:1973#0/1
HWUSI-EAS100R	the unique instrument name
6      flowcell lane
73     tile number within the flowcell lane
941    'x'-coordinate of the cluster within the tile
1973   'y'-coordinate of the cluster within the tile
#0     index number for a multiplexed sample (0 for no indexing)
/1     the member of a pair, /1 or /2 (paired-end or mate-pair reads only)


Casava1.8 format

\@EAS139:136:FC706VJ:2:2104:15343:197393 1:Y:18:ATCACG
EAS139    the unique instrument name
136       the run id
FC706VJ   the flowcell id
2         flowcell lane
2104      tile number within the flowcell lane
15343     'x'-coordinate of the cluster within the tile
197393    'y'-coordinate of the cluster within the tile
1         the member of a pair, 1 or 2 (paired-end or mate-pair reads only)
Y         Y if the read fails filter (read is bad), N otherwise
18        0 when none of the control bits are on, otherwise it is an even number
ATCACG    index sequence

USAGE



#######################
# Main program
#1) Check
if($help){
	print $usage;
	exit(0);
}

if(!defined($in)){
	print "[Error]: Input fastq file is not provided yet\n";
	print $usage;
	exit (1);
}

if(! -e $in){
	print "[Error]: Input fastq file '$in' is not exist\n";
	print $usage;
	exit (1);
}

open(IN,$in) or die $!;
my $firstheader=<IN>;<IN>;<IN>;<IN>;
$firstheader=~s/\r|\n//g;
my %info;
#Check illumina default header pattern
if($casava18){
	if($firstheader=~/(.*?):(.*?):(.*?):(.*?):(.*?):(.*?):(.*?)\s+(.*?):(.*?):(.*?):(.*?)/){
		my($instrument,$runid,$flowcellid,$lane,$tilenumber,$x,$y,$pair,$failed,$n,$index)=
			($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);
		$info{$instrument}->{$runid}->{$lane}->{'total'}++;
		if($failed eq 'Y'){
			$info{$instrument}->{$runid}->{$lane}->{'fail'}++;
		}
	}else{
		print "[Warning]: It seems like the sequences are not with Casava 1.8, ".
		                  "will try to parse them using previous Illumina pipeline(<=1.4)\n";
		                  
		$casava18=0;
		if($firstheader=~/(.*?):(.*?):(.*?):(.*?):(.*?)#(.?)\/(.*?)/){
			my($instrument,$lane,$tilenumber,$x,$y,$index,$pair)=
				($1,$2,$3,$4,$5,$6,$7);
			$info{$instrument}->{$lane}->{'total'}++;
		}else{
			print "[Error]: The sequences format is not recognized\n";
			print $usage;
			close IN;
			exit(1);
		}
	}
}else{
	if($firstheader=~/(.*?):(.*?):(.*?):(.*?):(.*?)#(.?)\/(.*?)/){
		my($instrument,$lane,$tilenumber,$x,$y,$index,$pair)=
			($1,$2,$3,$4,$5,$6,$7);
		$info{$instrument}->{$lane}->{'total'}++;
	}else{
		print "[Warning]: It seems like the sequences are not with previous Illumina pipeline(<=1.4), ".
		                  "will try to parse them using Casava 1.8 \n";
		$casava18=1;
		if($firstheader=~/(.*?):(.*?):(.*?):(.*?):(.*?):(.*?):(.*?)\s+(.*?):(.*?):(.*?):(.*?)/){
			my($instrument,$runid,$flowcellid,$lane,$tilenumber,$x,$y,$pair,$failed,$n,$index)=
				($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);
			$info{$instrument}->{$runid}->{$lane}->{'total'}++;
			if($failed eq 'Y'){
				$info{$instrument}->{$runid}->{$lane}->{'fail'}++;
			}
		}else{
			print "[Error]: The sequences format is not recognized\n";
			print $usage;
			close IN;
			exit(1);
		}              
	}
}

#############
#loop

while($firstheader=<IN>){
	<IN>;<IN>;<IN>;
	$firstheader=~s/\r|\n//g;
	if($casava18){
		if($firstheader=~/(.*?):(.*?):(.*?):(.*?):(.*?):(.*?):(.*?)\s+(.*?):(.*?):(.*?):(.*?)/){
			my($instrument,$runid,$flowcellid,$lane,$tilenumber,$x,$y,$pair,$failed,$n,$index)=
				($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);
			$info{$instrument}->{$runid}->{$lane}->{'total'}++;
			if($failed eq 'Y'){
				$info{$instrument}->{$runid}->{$lane}->{'fail'}++;
			}
		}
	}else{
		if($firstheader=~/(.*?):(.*?):(.*?):(.*?):(.*?)#(.?)\/(.*?)/){
			my($instrument,$lane,$tilenumber,$x,$y,$index,$pair)=
				($1,$2,$3,$4,$5,$6,$7);
			$info{$instrument}->{$lane}->{'total'}++;
		}
	}	
}
close IN;


##############################33
#PRINT out 
if($casava18){
	print join "\t",("#Instrument","RunID","LaneID","TotalReads","FailedReads\n");
	foreach my $instrument(sort keys %info){
		foreach my $runid(sort keys %{$info{$instrument}}){
			foreach my $laneid(sort keys %{$info{$instrument}->{$runid}}){
				my $total=0;
				my $fail=0;
				if(exists($info{$instrument}->{$runid}->{$laneid}->{'total'})){
					$total=$info{$instrument}->{$runid}->{$laneid}->{'total'};
				}
				if(exists($info{$instrument}->{$runid}->{$laneid}->{'fail'})){
					$fail=$info{$instrument}->{$runid}->{$laneid}->{'fail'};
				}
				print join "\t",($instrument,$runid,$laneid,$total,$fail);
				print "\n";
			}
		}
	}
}else{
	print join "\t",("#Instrument","LaneID","TotalReads\n");
	foreach my $instrument(sort keys %info){
		foreach my $laneid(sort keys %{$info{$instrument}}){
			print join "\t",($instrument,$laneid,$info{$instrument}->{$laneid});
			print "\n";
		}
	}
}



