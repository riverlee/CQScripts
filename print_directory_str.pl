#!/usr/bin/perl
use strict;
use warnings;

use File::Find;
use File::Spec::Functions qw(splitdir);
use Data::Dumper;
my %hash;
find(sub{
  return if $_ eq '.' or $_ eq '..';
	my $cursor = \%hash;
	$cursor = $cursor->{$_}||={} for $File::Find::dir;
	-d $_ ?
		$cursor->{$_}={"."=>[]}:
		push @{$cursor->{"."}},$_;
},@ARGV);

#print Dumper \%hash;

foreach my $key (sort keys %hash){
	my @a = split "/", $key;
	my $space="----|" x (scalar(@a)-1);
	my $space2="----|" x (scalar(@a));
	print $space."/".$a[$#a]."\n";
	if(exists($hash{$key}->{"."}) && scalar(@{$hash{$key}->{"."}})>0){
		foreach my $f (@{$hash{$key}->{"."}}){
			print $space2."/".$f."\n";
		}	
	}
}
