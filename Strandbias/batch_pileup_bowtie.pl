#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my ($mdata,$mmethod) = @ARGV; #if provide dataset and alignemt method
my $currentdir=getcwd;

my $ref="/data/cqs/guoy1/reference/hg19/hg19_chr.fa";

#my @data=("1000G","TrueSeq","SureSelect");
my @data = ("SureSelect","1000G","TrueSeq");

my @methods=("bowtie");

#my $listFile="list.bed";
my %listFile=("1000G"=>"/workspace/StrandBias/lij17/gwas/1000G_hg19.position",
    "TrueSeq"=>"/workspace/StrandBias/lij17/gwas/TrueSeq_hg19.position",
    "SureSelect"=>"/workspace/StrandBias/lij17/gwas/SureSelect_hg19.position");

my $dirname="pileup";

foreach my $data (@data){
    next  if($mdata && $mdata ne $data);
    print "Entering $data ...\n";
#    my $list = $currentdir."/".$data."/".$listFile;
    my $list=$listFile{$data};
    
    #/workspace/StrandBias/lij17/1000G
    chdir($data);
    if(! -d $dirname){
        mkdir $dirname;
    }

    #/workspace/StrandBias/lij17/1000G/pileup
    chdir ($dirname);

    foreach my $m (@methods){
        next if ($mmethod && $mmethod ne $m);
        print "\tMethod: $m..\n";

        if(! -d $m){
            mkdir $m;
        }
        #/workspace/StrandBias/lij17/1000G/pileup/firstalignment
        chdir $m;

        #running mpileup
        my @bamfiles = ();
        
        if($m eq "bowtie"){
            @bamfiles = <$currentdir/$data/align/$m/*.bam>;
        }
        
        #print `ls -l *pileup`;
        #print join "\n", @bamfiles;
        #print "\n";
        foreach my $bam (@bamfiles){
           my $name=$bam;
           $name=~s/.*\///g;
           $name=~s/\.bam//g;
           print "\t\tPileup: $name ..\n";
           
            `rm ${name}.atnow`;
            open(OUT,">${name}.atnow") or die $!;
            print OUT "echo 'running $data|$m|$name' \`date\`\n";
            #pileup command
            my $str="samtools mpileup -B -l $list -f $ref $bam > ${name}.pileup";
            print "\t\t\t $str \n";
            print OUT $str,"\n";
            print OUT "date\n";
            close OUT;
            #`at now -f ${name}.atnow`;

        }

        chdir ("../");

    }

    #back to the /workspace/StrandBias
    chdir ($currentdir)
}

