#!/usr/bin/env perl
use strict;
use warnings;
use File::Compare;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::CreateLibrary');
}

ok(my $obj = Bio::Metagenomics::CreateLibrary->new(
    taxon           => 123,
    output_filename => 'output_filename.fa',
    input_filename  => 't/data/solexa-adapters.fasta'
),'initialise object ');

is('sequence_2|kraken:taxid|123', $obj->_reformat_id(2),'Check name formatted correctly');
is('sequence_5|kraken:taxid|123', $obj->_reformat_id(5),'Check name formatted correctly');

ok($obj->convert, 'Convert the file');
ok(-e 'output_filename.fa', 'output file exists');

ok(compare('output_filename.fa', 't/data/converted_solexa-adapters.fasta') == 0, 'Converted adapters file matches expected');

unlink('output_filename.fa');
done_testing();
