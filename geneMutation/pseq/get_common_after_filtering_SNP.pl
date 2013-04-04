use strict;
use warnings;

my $gq=20;
my $roden67="/data/cqs/guoy1/roden/geneMutation/PSEQ/another/roden67_GQ20_non-synonymous.vcf";
my $g1k="/data/cqs/guoy1/roden/geneMutation/PSEQ/another/1K379_non-synonymous.vcf";

my %rodenhash=getpos($roden67);
my %g1khash=getpos($g1k);

our %common;

map {if(exists($g1khash{$_})){$common{$_}++}} keys %rodenhash;
print "There are ",scalar(keys %common)," common snps ..\n";

subprint($roden67,"roden67_GQ20_non-synonymous_common.vcf",1);
print "There are ",scalar(keys %common)," common snps ..\n";
subprint($g1k,"1K379_non-synonymous_common.vcf",1);

sub getpos{
    my ($infile) = @_;
    open(IN,$infile) or die $!;
    print info(),"Reading $infile ..\n";
    my %hash;
    while(<IN>){
        next if (/^#/);
        my @a=split "\t";
        next if ($a[6] ne 'PASS');
        #skip indel
        next if (length($a[3])!=1 || length($a[4])!=1);
        my $key = join "\t",($a[0],$a[1]);
        $hash{$key}=1;
    }
    return %hash;
}

sub subprint{
    my($in,$out,$flag)=@_;
    open(IN,$in) or die $!;
    print info(),"Print out $out ..\n";
    open(OUT,">$out") or die $!;
    while(<IN>){
        if(/^#/){
            print OUT $_;
        }else{
            my @a = split "\t";
            my $key = join "\t",($a[0],$a[1]);
            next if (length($a[3])!=1 || length($a[4])!=1);
            if (exists($common{$key})){
               if($flag){
                    print OUT $_;
                }else{
                    my $format=$a[8];
                    my @format=split ":", $format;
                    my @genos=@a[9..$#a];
                    my $missing=0;
                    my @new;
                    foreach my $k (@genos){
                        my %map;
                        @map{@format}=split ":",$k;
                        if($map{'GT'}=~/\./ || $map{'GQ'}<$gq){
                            $missing++;
                            push @new, "./.";
                        }else{
                            push @new, $k;
                        }
                    }
                    #To see whether the genotype is missing among all samples
                    if($missing == scalar(@genos)){
                        delete  $common{$key};
                    }else{
                        my $str=join "\t",@new;
                        if($str!~/0\/1/ && $str!~/1\/0/ && $str!~/1\/1/){
                            delete $common{$key};
                        }else{
                            print OUT join "\t",(@a[0..8],@new);
                        }
                    }
                }
            }
        }
    
    }
}


sub info{
    return "[",scalar(localtime),"] @ ";
}

