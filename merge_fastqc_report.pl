#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
#############################################
#Merge the fastq report into one page

my $fastqdir=".";
my $output="index.html";
my $help;
my $result = GetOptions('d|dir=s' => \$fastqdir,
						'help' => \$help,
						'o|out'=>\$output
					 );
if ($help) {
	# Just print the help and exit
	print <<HELP;
perl merge_fastqc_report.pl -d fastqcdir -o outputfile(default index.html) -h

HELP
	exit;
}

unless(-e $fastqdir and -d $fastqdir) {
	die "Specified fastq report directory '$fastqdir' does not exist\n";
}

########################################
#Read each fastq report directory and store the information
my %fastqc;
my %passwarnfail;
opendir(DIR,$fastqdir) or die $!;
foreach my $dir (readdir DIR){
	#check whether it is a validated fastqc report directory
	next unless (-e "$fastqdir/$dir/fastqc_data.txt" && 
				 -e "$fastqdir/$dir/summary.txt" && 
				 -e "$fastqdir/$dir/fastqc_report.html" && 
				 -d "$fastqdir/$dir/Images" && 
				 -d "$fastqdir/$dir/Icons");
	#print $dir,"\n";
	
	#Just get the 1)filename, 2)file type, 
	#3)encoding, 4)total sequences, 5) filtered sequences, 
	#6) sequence length and 7)%GC from the fastqc_data.txt file
	my ($filename,$filetype,$encoding,$totalsequences,
		$filteredsequences,$sequencelength,$gcpercentage) = getSevenStat("$fastqdir/$dir/fastqc_data.txt");
	$fastqc{$dir}->{'filename'}=$filename;
	$fastqc{$dir}->{'filetype'}=$filetype;
	$fastqc{$dir}->{'encoding'}=$encoding;
	$fastqc{$dir}->{'totalsequences'}=$totalsequences;
	$fastqc{$dir}->{'filteredsequences'}=$filteredsequences;
	$fastqc{$dir}->{'sequencelength'}=$sequencelength;
	$fastqc{$dir}->{'gcpercentage'}=$gcpercentage;
	
	##Read the pass,warn,fail foreach section
	open(IN,"$fastqdir/$dir/summary.txt") or die $!;
	while(<IN>){
		next if(/^$/);
		my($type,$section,undef) = split "\t";
		$passwarnfail{$section}->{$type}++;
		$fastqc{$dir}->{$section}=$type;
	}
	close IN;
}

if(scalar(keys %fastqc)==0){
	die "It seems there is no single fastqc report result in the directory '$fastqdir' \n\n";
}

##################################
#Start to write out the html output
my @samples = sort keys %fastqc;
my $totalfastqcreport=scalar(keys %fastqc);

my %mappingtoimg=("PASS"=>"tick.png",
				   "WARN"=>"warning.png",
				   "FAIL"=>"error.png");
my %sectiontotype;
foreach my $section (keys %passwarnfail){
	my($type)=sort {$passwarnfail{$section}->{$b}<=>$passwarnfail{$section}->{$a}} keys %{$passwarnfail{$section}};
	$sectiontotype{$section}=$type;
}


open(HTML,">$fastqdir/$output") or die $!;
print HTML <<HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Strict//EN">
<html>
<head><title>$totalfastqcreport samples FastQC Report</title>
<style type="text/css">
HERE

print HTML <DATA>;
print HTML <<HERE;
</style>
</head>
<body>
<div class="header">
<div id="header_title"><img src="$samples[0]/Icons/fastqc_icon.png" alt="FastQC">$totalfastqcreport samples' FastQC Report</div>
<div id="header_filename">
HERE
#foreach my $s (@samples){
#	print HTML "<a href='$s/fastqc_report.html'>$s</a><br/>\n";
#}


my $string = generateString($passwarnfail{'Basic Statistics'});
print HTML <<HERE;
</div></div>
<div class="summary">
<h2>Summary</h2>
<ul>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Basic Statistics'}}" alt="[$sectiontotype{'Basic Statistics'}]"> <a href="#M0">Basic Statistics</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Per base sequence quality'}}" alt="[$sectiontotype{'Per base sequence quality'}]"> <a href="#M1">Per base sequence quality</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Per sequence quality scores'}}" alt="[$sectiontotype{'Per sequence quality scores'}]"> <a href="#M2">Per sequence quality scores</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Per base sequence content'}}" alt="[$sectiontotype{'Per base sequence content'}]"> <a href="#M3">Per base sequence content</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Per base GC content'}}" alt="[$sectiontotype{'Per base GC content'}]"> <a href="#M4">Per base GC content</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Per sequence GC content'}}" alt="[$sectiontotype{'Per sequence GC content'}]"> <a href="#M5">Per sequence GC content</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Per base N content'}}" alt="[$sectiontotype{'Per base N content'}]"> <a href="#M6">Per base N content</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Sequence Length Distribution'}}" alt="[$sectiontotype{'Sequence Length Distribution'}]"> <a href="#M7">Sequence Length Distribution</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Sequence Duplication Levels'}}" alt="[$sectiontotype{'Sequence Duplication Levels'}]"> <a href="#M8">Sequence Duplication Levels</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Overrepresented sequences'}}" alt="[$sectiontotype{'Overrepresented sequences'}]"> <a href="#M9">Overrepresented sequences</a></li>
<li><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Kmer Content'}}" alt="[$sectiontotype{'Kmer Content'}]"> <a href="#M10">Kmer Content</a></li>
</ul>
</div>
<div class="main">
<div class="module"><h2 id="M0"><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{'Basic Statistics'}}" alt="[$sectiontotype{'Basic Statistics'}]"> Basic Statistics ($string) </h2>
<table>
	<tr>
		<th>Filename</th>
		<th>File Type</th>
		<th>Encoding</th>
		<th>Total Sequences</th>
		<th>Filtered Sequences</th>
		<th>Sequence length</th>
		<th>%GC</th>
		<th>Evaluation </th>
	</tr>
HERE
#basic statistics table
foreach my $s (@samples){
	print HTML "\t<tr>\n".
			   "\t\t<td><a href='$s/fastqc_report.html##M0'>".$fastqc{$s}->{'filename'}."</a></td>\n".
			   "\t\t<td>".$fastqc{$s}->{'filetype'}."</td>\n".
			   "\t\t<td>".$fastqc{$s}->{'encoding'}."</td>\n".
			   "\t\t<td>".$fastqc{$s}->{'totalsequences'}."</td>\n".
			   "\t\t<td>".$fastqc{$s}->{'filteredsequences'}."</td>\n".
			   "\t\t<td>".$fastqc{$s}->{'sequencelength'}."</td>\n".
			   "\t\t<td>".$fastqc{$s}->{'gcpercentage'}."</td>\n".
			   "\t\t<td>".$fastqc{$s}->{'Basic Statistics'}."</td>\n".
			   "\t</tr>\n";
}

print HTML <<HERE;
</table>
</div>
HERE

#Per base sequence quality
printFigures("per_base_quality.png","Per base sequence quality","M1");

#Per sequence quality scores
printFigures("per_sequence_quality.png","Per sequence quality scores","M2");

#Per base sequence content
printFigures("per_base_sequence_content.png","Per base sequence content","M3");

#Per base GC content
printFigures("per_base_gc_content.png","Per base GC content","M4");

#Per sequence GC content
printFigures("per_sequence_gc_content.png","Per sequence GC content","M5");

#Per base N content
printFigures("per_base_n_content.png","Per base N content","M6");

#Sequence Length Distribution
printFigures("sequence_length_distribution.png","Sequence Length Distribution","M7");

#Sequence Duplication Levels
printFigures("duplication_levels.png","Sequence Duplication Levels","M8");

#Overrepresented sequences
printFigures("aa","Overrepresented sequences","M9");

#Kmer Content
printFigures("kmer_profiles.png","Kmer Content","M10");

close HTML;



sub printFigures{
	my($figurename,$section,$module) = @_;
	my $string = generateString($passwarnfail{$section});
	print HTML <<HERE;
<div class="module"><h2 id="$module"><img src="$samples[0]/Icons/$mappingtoimg{$sectiontotype{$section}}" alt="[$sectiontotype{$section}]"> $section ($string) </h2>
	<ul id="image-container">
HERE
	foreach my $s (@samples){
		#print $fastqc{$s}->{$section},"\n";
		if(-e "$fastqdir/$s/Images/$figurename"){
			print HTML "\t\t<li><img src='$s/Images/$figurename' alt='$section graph'><a href='$s/fastqc_report.html#$module'>$s ($fastqc{$s}->{$section})</a></li>\n"
		}else{
			print HTML "\t\t<li><div>Not available</div><a href='$s/fastqc_report.html#$module'>$s ($fastqc{$s}->{$section})</a></li>\n"
		}
	}
	print HTML "\t</ul>\n";
	print HTML "</div>\n\n";
}



sub generateString{
	my ($ref) = @_;
	my $str="";
	if(exists($ref->{'PASS'})){
		$str=$ref->{'PASS'}." PASS | ";
	}else{
		$str="0 PASS | ";
	}
	
	if(exists($ref->{'WARN'})){
		$str.=$ref->{'WARN'}." WARNING | ";
	}else{
		$str.="0 WARNING | ";
	}
	
	if(exists($ref->{'FAIL'})){
		$str.=$ref->{'FAIL'}." FAIL";
	}else{
		$str.="0 FAIL";
	}
	
	return $str;
	
}

#Just get the 1)filename, 2)file type, 
#3)encoding, 4)total sequences, 5) filtered sequences, 
#6) sequence length and 7)%GC from the fastqc_data.txt file
sub getSevenStat{
	my ($in) = @_;
	my($filename,$filetype,$encoding,$totalsequences,$filteredsequences,$sequencelength,$gcpercentage);
	open(IN,$in) or die $!;
	#Skip the first three lines
	<IN>;<IN>;<IN>;
	my $line=<IN>;$line=~s/\r|\n//g;
	(undef,$filename) = split "\t",$line;
	$line=<IN>;$line=~s/\r|\n//g;
	(undef,$filetype) = split "\t",$line;
	$line=<IN>;$line=~s/\r|\n//g;
	(undef,$encoding) = split "\t",$line;
	$line=<IN>;$line=~s/\r|\n//g;
	(undef,$totalsequences) = split "\t",$line;
	$line=<IN>;$line=~s/\r|\n//g;
	(undef,$filteredsequences) = split "\t",$line;
	$line=<IN>;$line=~s/\r|\n//g;
	(undef,$sequencelength) = split "\t",$line;
	$line=<IN>;$line=~s/\r|\n//g;
	(undef,$gcpercentage) = split "\t",$line;
	close IN;
	return ($filename,$filetype,$encoding,$totalsequences,$filteredsequences,$sequencelength,$gcpercentage);
}




__DATA__
   @media screen {
  div.summary {
    width: 18em;
    position:fixed;
    top: 3em;
    margin:1em 0 0 1em;
  }
  
  div.main {
    display:block;
    position:absolute;
    overflow:auto;
    height:auto;
    width:auto;
    top:4.5em;
    bottom:2.3em;
    left:18em;
    right:0;
    border-left: 1px solid #CCC;
    padding:0 0 0 1em;
    background-color: white;
    z-index:1;
  }
  
  div.header {
    background-color: #EEE;
    border:0;
    margin:0;
    padding: 0.5em;
    font-size: 200%;
    font-weight: bold;
    position:fixed;
    width:100%;
    top:0;
    left:0;
    z-index:2;
  }

  div.footer {
    background-color: #EEE;
    border:0;
    margin:0;
	padding:0.5em;
    height: 1.3em;
	overflow:hidden;
    font-size: 100%;
    font-weight: bold;
    position:fixed;
    bottom:0;
    width:100%;
    z-index:2;
  }
  
  img.indented {
    margin-left: 3em;
  }
 }
 
 @media print {
	img {
		max-width:100% !important;
		page-break-inside: avoid;
	}
	h2, h3 {
		page-break-after: avoid;
	}
	div.header {
      background-color: #FFF;
    }
	
 }
 
 body {    
  font-family: sans-serif;   
  color: #000;   
  background-color: #FFF;
  border: 0;
  margin: 0;
  padding: 0;
  }
  
  div.header {
  border:0;
  margin:0;
  padding: 0.5em;
  font-size: 200%;
  font-weight: bold;
  width:100%;
  }    
  
  #header_title {
  display:inline-block;
  float:left;
  clear:left;
  }
  #header_filename {
  display:inline-block;
  float:right;
  clear:right;
  font-size: 25%;
  margin-right:2em;
  text-align: right;
  }

  div.header h3 {
  font-size: 50%;
  margin-bottom: 0;
  }
  
  div.summary ul {
  padding-left:0;
  list-style-type:none;
  }
  
  div.summary ul li img {
  margin-bottom:-0.5em;
  margin-top:0.5em;
  }
	  
  div.main {
  background-color: white;
  }
      
  div.module {
  padding-bottom:1.5em;
  padding-top:1.5em;
  }
	  
  div.footer {
  background-color: #EEE;
  border:0;
  margin:0;
  padding: 0.5em;
  font-size: 100%;
  font-weight: bold;
  width:100%;
  }


  a {
  color: #000080;
  }

  a:hover {
  color: #800000;
  }
      
  h2 {
  color: #800000;
  padding-bottom: 0;
  margin-bottom: 0;
  clear:left;
  }

  table { 
  margin-left: 3em;
  text-align: center;
  }
  
  th { 
  text-align: center;
  background-color: #000080;
  color: #FFF;
  padding: 0.4em;
  }      
  
  td { 
  font-family: monospace; 
  text-align: center;
  background-color: #EEE;
  color: #000;
  padding: 0.4em;
  }

  img {
  padding-top: 0;
  margin-top: 0;
  border-top: 0;
  }

  
  p {
  padding-top: 0;
  margin-top: 0;
  }
  
  #image-container { 
min-width:800px; /* width of 5 images (625px) plus images' padding and border (60px) plus images' margin (50px) */ 
height:47px; 
padding:10px 5px; 
margin:0; 
border:0px solid #ffffff; 
background-color:#ffffff; 
list-style-type:none; 
} 
  
#image-container li { 
width:33%; 
float:left; 
text-align: center;
margin-bottom:10px
} 
#image-container img { 
display:block; 
width:265px; 
height:200px; 
padding:5px; 
border:1px solid #d3d2d2; 
margin:auto; 
background-color:#fff; 
} 

#image-container div{
	display:block;
	width:265px; 
	height:200px;
	border:1px solid #d3d2d2; 
	margin:auto; 
	background-color:#fff; 
	text-align: center;
	font-size:150%;
}
