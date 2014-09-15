#!/usr/bin/perl
use warnings;
use strict;

my ($input,$output)=@ARGV;
open IN,"$input" or die;
open OUT,">$output" or die;
my $mode = (stat($input))[2];
printf OUT "begin %03o %s\n",$mode & 07777, $input;
while (read IN,my $data,45){
        my $text = pack("u*",$data);
        print OUT "$text";

}
print OUT "`\nend\n";
close OUT;
close IN;
