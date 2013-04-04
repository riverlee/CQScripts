#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use IO::File;

my ($mdata) = @ARGV; #if provide dataset and alignemt method
my $currentdir=getcwd;

my $ref="/data/cqs/guoy1/reference/hg19/hg19_chr.fa";

#my @data=("1000G","TrueSeq","SureSelect");
#Three datasets
my @data = ("SureSelect","1000G","TrueSeq");

#my @methods=("realignment");

#The result will be put here
my $dirname="pileup";

foreach my $data (@data){
    next  if($mdata && $mdata ne $data);
    print "Entering $data ...\n";
    #my $list = $currentdir."/".$data."/".$listFile;
    # my $list=$listFile{$data};
    
    #/workspace/StrandBias/lij17/1000G
    chdir($data);
    if(! -d $dirname){
        mkdir $dirname;
    }

    #/workspace/StrandBias/lij17/1000G/pileup
    chdir ($dirname);

    #foreach my $m (@methods){
    #next if ($mmethod && $mmethod ne $m);
    my $m="vcf_realignment";
    print "\tMethod: $m..\n";

    if(! -d $m){
        mkdir $m;
    }
    #/workspace/StrandBias/lij17/1000G/pileup/firstalignment
    chdir $m;

     #running mpileup
    my @bamfiles = ();
        
    @bamfiles = <$currentdir/$data/align/realignment/*_sorted_realign_recal_markdup.bam>;
    
    
    #Generate will calling position for each sample
    my %positionlist=getPositionFromEachSampleFromVCF("$currentdir/$data/vcfall/realignment/realignment_snp.vcf","$currentdir/$data/pileup/$m/");

        
     #print `ls -l *pileup`;
     #print join "\n", @bamfiles;
     #print "\n";
    foreach my $bam (@bamfiles){
        my $name=$bam;
        $name=~s/.*\///g;
        $name=~s/_sorted_realign_recal_markdup\.bam//g;
        print "\t\tPileup: $name ..\n";
           
        #  `rm ${name}.atnow`;
        open(OUT,">${name}.atnow") or die $!;
        print OUT "echo 'running $data|$m|$name' \`date\`\n";
        #pileup command
        my $str="samtools mpileup -B -l $positionlist{$name} -f $ref $bam > ${name}.pileup";
        print "\t\t\t $str \n";
        print OUT $str,"\n";
        print OUT "date\n";
        close OUT;
        `at now -f ${name}.atnow`;

    }

    chdir ("../");

    #}

    #back to the /workspace/StrandBias
    chdir ($currentdir)
}


sub getPositionFromEachSampleFromVCF{
    my($vcffile,$outputdir) = @_;
    open(IN,$vcffile) or dir $!;
    my @header;
    my %result;
    my %filehandles;
    while(<IN>){
        next if (/^##/);
        s/\r|\n//g;
        if(/^#/){
            (undef,undef,undef,undef,undef,undef,undef,undef,undef,@header) = split "\t";
            foreach my $s(@header){
                my $fh=new IO::File "> $outputdir/${s}_snp.position";
                $filehandles{$s}=$fh;
                $result{$s}="$outputdir/${s}_snp.position";
            }
            next;
        }

         my($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@genotypes) = split "\t";
         next if( $filter ne "PASS");
         my @formats = split ":",$format;
         for(my $i=0;$i<@genotypes;$i++){
            my $sample=$header[$i];
            my $geno = $genotypes[$i];
            next if ($geno eq "./.");
            my %map;
            @map{@formats}=split ":",$geno;
            next if ($map{'DP'} <20);  #filter those depth less  than 20
            my ($a,$b) = split /\//,$map{'GT'};
            next if ($a eq $b);  #if genotype is not heterzygous

            #Now print this position out for this sample
            my $fh = $filehandles{$sample};
            print $fh join "\t",($chr,$pos);
            print $fh "\n";
         }
    }
    close IN;

    foreach my $fh (values %filehandles){
        $fh->close;
    }
    return %result;
}
