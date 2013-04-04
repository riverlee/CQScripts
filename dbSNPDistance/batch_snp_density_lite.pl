
my ($vcf,$samplefile)=@ARGV;
open(SAM,$samplefile) or die $!;

while(<SAM>){
    s/\r|\n//g;
    next if (/^$/);
    my $s=    `perl snp_density_lite.pl $vcf $_`;
    print $s;
}
close SAM;


