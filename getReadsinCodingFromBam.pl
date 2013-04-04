#!/usr/bin/perl
#############################################
#Author: Jiang Li
#email: riverlee2008@gmail.com
#Creat Time: Tue 15 May 2012 11:24:53 AM CDT 
#Vanderbilt Center for Quantitative Sciences
#############################################
use strict;
use warnings;
use Getopt::Long;

#in is a bam file
#out is the output which store total Reads, mapped reads and reads in coding
#
#Aim: This code is not suitalbe for tophat output since tophat only output mapped reads in the bam file
#and will also output serveral line for reads mapping to multiple position of genome.
#The code works well for bwa output

my($in,$codingBedFile,$out,$help);
GetOptions("i|in=s"=>\$in,
			"o|out=s"=>\$out,
			"b|bed=s"=>\$codingBedFile,
			"h|help"=>\$help);
			
if($help){
	&help;
	exit 1;
}

if(!$in || ! -e $in || !$out){
	&help;
	exit 0;
}

open(TMPOUT,">$out") or die $!;
close TMPOUT;

#1) Read coding region info
my %coding;
if(defined($codingBedFile) && -e $codingBedFile){
	open(IN,$codingBedFile) or die $!;
	print info(),"Reading coding region \n";
	while(<IN>){
		s/\r|\n//;
		my($chr,$start,$end) = split "\t";
		($start,$end)=sort {$start<=>$end} ($start,$end);
		for(my $i=$start;$i<=$end;$i++){
			$coding{$chr}->{$i}=1;
		}
	}
	close IN;
}

#2) Read bam files and get the total reads, mapped reads, and reads in coding region
print info(),"Read bam file \n";
my $flag_paired=0x0001;
my $flag_properly_paired=0x0002;
my $flag_read_unmapped = 0x0004;
my $flag_reverse_strand= 0x0010;
my $flag_next_read_unmapped = 0x0008;
my $flag_first_fragment=0x0040;
my $flag_second_fragment=0x080;

if($in=~/\.sam$/){
  open(IN,$in) or die $!;
}else{
  open(IN,"samtools view $in |") or die $!;
}

my $total=0;   #total Reads

my $total1=0;  #paired1 total Reads
my $total2=0;  #paired2 total Reads

my $mapped=0;  #mapped Reads;
my $mapped1=0; #mapped Reads of paired 1
my $mapped2=0; #mapped reads of paired 2
my $mapped12=0;#both the paired are mapped 

my $coding=0; #total reads in provided region
my $coding1=0;#total reads of paired 1 in provided region
my $coding2=0;

my $paired=0; #whether paired or not determined by first read in the bam file


while(<IN>){
	my @line = split "\t", $_;
	#check for basic line format
	next unless (scalar(@line) >=11);
	next unless (/^@/);

	my $flag = $line[1];
	if(! $paired){
		$paired=$flag & $flag_paired;
	}

    $total++;

	if($flag & $flag_first_fragment){
		$total1++;
	}

	if($flag & $flag_second_fragment){
		$total2++;
	}

	#Whether mapped or not
    my $unaligned = ( ($flag & $flag_read_unmapped) ? 1 : 0 );
    next if ($unaligned);
	
    $mapped++;
    
    if($flag & $flag_first_fragment){
		$mapped1++;
    }
	
    if($flag & $flag_second_fragment){
    	$mapped2++;
    }
    
    if(!($flag & $flag_next_read_unmapped)){
      $mapped12++;
    }

    my $query_id = $line[0];
    my $subject_id = $line[2];
    my $subject_start = $line[3];
    my $cigar = $line[5];
    my $seq = $line[9];
    my $read_length = length($seq);

        
   # my $cig_info = &parseCigar('-cigar'=>$cigar, '-subject_start'=>$subject_start, '-read_length'=>$read_length);
   # my $subject_end = $cig_info->{'subject_end'};
   # ($subject_start,$subject_end) = sort {$a<=>$b} ($subject_start,$subject_end);
   # for(my $i=$subject_start;$i<=$subject_end;$i++){
   #An easy way to determine the start and end of mappped region
   if( defined($codingBedFile) && -e $codingBedFile && %coding){
	   for(my $i=$subject_start;$i<=($subject_start+$read_length);$i++){
			if(exists($coding{$subject_id}->{$i})){
				$coding++;
				if($flag & $flag_first_fragment){
					$coding1++;
				}
			
				if($flag & $flag_second_fragment){
					$coding2++;
				}
			
				last;
			}
		}
    }
}
close IN;


#3 Write output
print info(),"Write out the result \n";
open(OUT,">$out") or die $!;

if($paired){
	print OUT join "\t",("#Total_Reads","Total_Paired1","Total_Paired2","Total_mapped","Total_mapped1","Total_mapped2","Total_mapped12");
	if(defined($codingBedFile) && -e $codingBedFile && %coding){
		print OUT "\t";
		print OUT join "\t",("Total_Region","Total_Region1","Total_Region2");
	}
	print OUT "\n";
	print OUT join "\t",($total,$total1,$total2,$mapped,$mapped1,$mapped2,$mapped12);
	if(defined($codingBedFile) && -e $codingBedFile && %coding){
		print OUT "\t";
		print OUT join "\t",($coding,$coding1,$coding2);
	}
	print OUT "\n";
}else{
	print OUT join "\t",("#Total_Reads","Total_mapped");
	if(defined($codingBedFile) && -e $codingBedFile && %coding){
		print OUT "\tTotal_Region";
	}
	print OUT "\n";
	
	print OUT join "\t",($total,$mapped);
	if(defined($codingBedFile) && -e $codingBedFile && %coding){
		print OUT "\t$coding";
	}
	print OUT "\n";
}

sub help{
	print <<HELP;
perl $0 <-i|--in inputbam> <-o|--out outfile> [-b|--bed bedregionfile] -h
-------------------------------------------------------------------------------
	-i/--in input bam filename
	-o/--out output filename
	-b/--bed bed format file, which is used to calculate how many reads are in this region
	-h/--help print out this	
	
HELP

}

sub getsubseq{
	my($s)=@_;
	#only fetch first 10 sequence
	my $n=length($s)<10?length($s):10;
	return substr($s,0,$n);
}
sub info{
    return "[",scalar(localtime),"] @ ";
}


sub parseCigar{
  my %args = @_;
  my $cigar = $args{'-cigar'};
  my $pos = $args{'-subject_start'};
  my $rlen = $args{'-read_length'};

  $cigar =~ s/(\d+)([MIDSN])/$1 $2\t/g;
  my $t_start = $pos;
  my $t_end = $pos-1;
  my $q_start = 1;
  my $q_end = 0;

  my $M_bases = 0;
  my $I_count = 0;
  my $I_bases = 0;
  my @I_bases;
  my $D_count = 0;
  my $D_bases = 0;
  my @D_bases;

  my $r_used = 0;
 my $DEBUG = 0;
  for my $c (split(/\t/,   $cigar)) {
    my ($len,  $op) = split(/ /,   $c);
    if($DEBUG && $r_used >= $rlen) { print STDERR "ERROR: more bases accounted for than read length! (rlen = $rlen, r_used = $r_used)\n"; }

    if($op eq 'M') { $t_end += $len; $q_end += $len; $r_used += $len; $M_bases += $len; }
    elsif($op eq 'D') { $t_end += $len; $D_bases += $len; $D_count++; push(@D_bases, $len);}
    elsif($op eq 'N') { $t_end += $len; }
    elsif($op eq 'I') { $q_end += $len; $r_used += $len; $I_bases += $len; $I_count++; push(@I_bases, $len);}
    elsif($op eq 'S') {
      if($q_start == 1 && $q_end == 0) { $q_start = $len+1; $r_used += $len;}
      else { $r_used += $len;}
    }
    else { print STDERR "ERROR: Unknown cigar op: $op\n"; }
  }
  if($r_used != $rlen) { print STDERR "ERROR: more bases accounted for than read length! (rlen = $rlen, r_used = $r_used)\n"; }

  #Return the query_start, query_end, subject_start, subject_end, matching_bases, deletion_count, deletion_bases, insertion_count, insertion_bases
  my %cig_info;
  $cig_info{query_start}=$q_start;
  $cig_info{query_end}=$q_end;
  $cig_info{subject_start}=$t_start;
  $cig_info{subject_end}=$t_end;
  $cig_info{matching_bases}=$M_bases;
  $cig_info{deletion_count}=$D_count;
  $cig_info{deletion_bases}=$D_bases;
  $cig_info{deletion_sizes}=\@D_bases;
  $cig_info{insertion_count}=$I_count;
  $cig_info{insertion_bases}=$I_bases;
  $cig_info{insertion_sizes}=\@I_bases;
  return(\%cig_info);
}

