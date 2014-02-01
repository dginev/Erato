package Erato::WordFrequency;

use strict;
use warnings;

use File::Slurp;
use File::Spec::Functions qw(catdir catfile);

my ($resource_dir) = grep { -d $_ } map {catdir($_,'Erato','resources'); } @INC;
our $List = { map {split(/\s/,$_)} split("\n",read_file(catfile($resource_dir,'en.txt'))) };

# Pre-compute the 90% threshold for hipsterness - that suggests 42.
# We will be lenient and set a threshold of 50. Computed via:
# 
# Uncomment below and execute: $perl -Ilib -e 'use Erato::WordFrequency;'
#
# sub hashValueDescendingNum {
#    $List->{$b} <=> $List->{$a}; }
# my $counter = 0;
# my $cutoff = 45000;
# foreach my $key (sort hashValueDescendingNum (keys(%$List))) {
#   $counter++;
#    print "\t$List->{$key} \t\t $key\n";
#    exit if $counter > $cutoff;
# }
our $hipsterness_cutoff = 50;

1;