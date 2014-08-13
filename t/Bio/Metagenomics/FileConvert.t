#!/usr/bin/env perl
use strict;
use warnings;
use File::Compare;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::FileConvert');
}

throws_ok{Bio::Metagenomics::FileConvert->new(infile => 'in', outfile => 'out', informat => 'kraken', outformat => 'x')} 'Bio::Metagenomics::Exceptions::FileConvertTypes', 'FileConvert BUILD throws exception if bad output type given';
throws_ok{Bio::Metagenomics::FileConvert->new(infile => 'in', outfile => 'out', informat => 'x', outformat => 'metaphlan')} 'Bio::Metagenomics::Exceptions::FileConvertTypes', 'FileConvert BUILD throws exception if bad intput type given';

my $obj;
my $outfile = 'FileConvertTest.out';

ok($obj = Bio::Metagenomics::FileConvert->new(
    infile => 't/data/FileConvert.kraken',
    informat => 'kraken',
    outfile => $outfile,
    outformat => 'metaphlan',
), 'initialize object');


$obj->convert();
ok(compare('t/data/FileConvert.kraken_to_metaphlan', $outfile) == 0, 'Convert kraken to metaphlan');

done_testing();
