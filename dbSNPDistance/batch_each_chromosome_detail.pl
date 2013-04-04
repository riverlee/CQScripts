for my $i (1..22){
    my $vcf="/data/cqs/guoy1/reference/1000g/ALL.chr${i}.integrated_phase1_v3.20101123.snps_indels_svs.genotypes.vcf";
    my $bashfile="details_chr${i}.sh";
    open(OUT,">$bashfile") or die $!;
    print OUT "echo doing $i \`date\`\n";
    print OUT "perl snp_density_1000g_details.pl $vcf HG00096 >HG00096_chr${i}.txt\n";
    print OUT "date\n";
    close OUT;

}
