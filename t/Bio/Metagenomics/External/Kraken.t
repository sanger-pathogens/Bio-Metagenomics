#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::External::Kraken');
}

my $obj;

ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => 'DB',
    threads  => 42,
    minimizer_len => 11,
    max_db_size => 2,
    reads_1 => 'reads_1.fastq',
), 'initialize object');

is($obj->_download_taxonomy_command(), 'kraken-build --download-taxonomy --db DB', 'Construct download-taxonomy command');
is($obj->_download_domain_command('viruses'), 'kraken-build --download-library viruses --db DB', 'Construct download-library command');
throws_ok{$obj->_download_domain_command('notallowed')} 'Bio::Metagenomics::Exceptions::KrakenDomainNotFound' , 'download-library throws exception if bad domain given';
is($obj->_add_to_library_command('filename'), 'kraken-build --add-to-library filename --db DB', 'Construct add-to-library command');
is($obj->_build_command(), 'kraken-build --build --db DB --threads 42 --max-db-size 2 --minimizer-len 11', 'Construct build command');
is($obj->_clean_command(), 'kraken-build --clean --db DB', 'Construct clean command');
is($obj->_run_kraken_command('out'), 'kraken --db DB --threads 42 --output out reads_1.fastq', 'Construct kraken command');
is($obj->_kraken_report_command('in', 'out'), 'kraken-report --db DB in > out', 'Construct kraken report command');

ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => 'DB',
    reads_1 => 'reads_1.fastq',
    reads_2 => 'reads_2.fastq',
    preload => 1,
), 'initialize object with read pairs');
is($obj->_run_kraken_command('out'), 'kraken --db DB --threads 1 --output out --preload --paired reads_1.fastq reads_2.fastq', 'Construct kraken command with read pairs and preload');

done_testing();
