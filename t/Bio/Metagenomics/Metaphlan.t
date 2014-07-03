#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::External::Metaphlan');
}


throws_ok{Bio::Metagenomics::External::Metaphlan->new(outfile => 'x')} 'Bio::Metagenomics::Exceptions::MetaphlanBuild' , 'Metaphlan BUILD throws exception if no filenames given';
throws_ok{Bio::Metagenomics::External::Metaphlan->new(outfile => 'x', 'names_list'=>[])} 'Bio::Metagenomics::Exceptions::MetaphlanBuild' , 'Metaphlan BUILD throws exception if no names given';

my $obj;
my @names = ('1','2','3');

ok($obj = Bio::Metagenomics::External::Metaphlan->new(
    'names_list' => \@names,
    'names_file' => 't/data/metaphlan_load_names_from_file.txt',
    'outfile' => 'metaphlan_test.png',
), 'initialize object');


my @expected_names = ('1', '2', '3', 'file1', 'file2', 'file3');
is_deeply($obj->names_list, \@expected_names, 'Names got from list and file OK');

done_testing();
