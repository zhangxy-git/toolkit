#!/usr/bin/perl
use warnings;
use strict;

my ($input,$output)=@ARGV;
open IN,"$input" or die;
open OUT,">$output" or die;
while (<IN>){
	my $data = unpack("u*",$_);
	print OUT "$data";

}
close OUT;
close IN;
