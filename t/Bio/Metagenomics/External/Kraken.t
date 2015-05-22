#!/usr/bin/env perl
use strict;
use warnings;
use File::Compare;
use File::Copy 'cp';
use File::Path 'remove_tree';
#use File::Touch;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::External::Kraken');
}

my $obj;
my $db = 'DB';
my $tmp_csv = "tmp.$$.csv";

ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => $db,
    reads_1 => 't/data/non_standard_read_names_1.fastq',
    reads_2 => 't/data/non_standard_read_names_2.fastq',
    
), 'initialize object where fastqs have non standard and mismatching names');
is($obj->_fix_fastq_headers_command(), 'fastaq enumerate_names --suffix /1 t/data/non_standard_read_names_1.fastq t/data/.renamed.non_standard_read_names_1.fastq && fastaq enumerate_names --suffix /2 t/data/non_standard_read_names_2.fastq t/data/.renamed.non_standard_read_names_2.fastq','Relabel sequences in fastq');


ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => $db,
    reads_1 => 't/data/non_standard_read_names_1.fastq',
    
), 'initialize object where its single ended');
is($obj->_fix_fastq_headers_command(), 'fastaq enumerate_names --suffix /1 t/data/non_standard_read_names_1.fastq t/data/.renamed.non_standard_read_names_1.fastq','Relabel sequences in fa single ended');


ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => $db,
    reads_1 => 't/data/non_standard_read_names_1.fastq.gz',
    reads_2 => 't/data/non_standard_read_names_2.fastq.gz',
    
), 'initialize object with non standard and mismatching names gzipped');
is($obj->_fix_fastq_headers_command(), 'fastaq enumerate_names --suffix /1 t/data/non_standard_read_names_1.fastq.gz t/data/.renamed.non_standard_read_names_1.fastq.gz && fastaq enumerate_names --suffix /2 t/data/non_standard_read_names_2.fastq.gz t/data/.renamed.non_standard_read_names_2.fastq.gz','Relabel sequences in fastq thats been gzipped');


ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => $db,
    threads  => 42,
    minimizer_len => 11,
    max_db_size => 2,
    reads_1 => 'reads_1.fastq',
    csv_fasta_to_add => 't/data/Kraken_fasta_to_add.csv',
    csv_fasta_to_add_out => $tmp_csv,
), 'initialize object');


is($obj->_download_taxonomy_command(), "kraken-build --download-taxonomy --db $db", 'Construct download-taxonomy command');
is($obj->_download_domain_command('viruses'), "kraken-build --download-library viruses --db $db", 'Construct download-library command');
throws_ok{$obj->_download_domain_command('notallowed')} 'Bio::Metagenomics::Exceptions::KrakenDomainNotFound' , 'download-library throws exception if bad domain given';
is($obj->_add_to_library_command('filename'), "kraken-build --add-to-library filename --db $db", 'Construct add-to-library command');
is($obj->_add_to_library_command('filename.gz'), "gunzip -c filename.gz > filename.gz.tmp && kraken-build --add-to-library filename.gz.tmp --db $db && rm filename.gz.tmp", 'Construct add-to-library command, gzipped file');
is($obj->_build_command(), "kraken-build --build --db $db --threads 42 --max-db-size 2 --minimizer-len 11", 'Construct build command');
is($obj->_clean_command(), "kraken-build --clean --db $db", 'Construct clean command');
is($obj->_run_kraken_command('out'), "kraken --db $db --threads 42 --output out reads_1.fastq", 'Construct kraken command');
is($obj->_kraken_report_command('in', 'out'), "kraken-report --db $db --print_header in > out", 'Construct kraken report command');

my @expected_fasta_to_add = (
    {
        'filename' => 't/data/Kraken_fa_to_add.1.fa',
        'name' => 'name 1',
        'parent_taxon_id' => '1',
    },
    {
        'filename' => 't/data/Kraken_fa_to_add.2.fa',
        'name' => 'name 2',
        'parent_taxon_id' => '2',
    }
);
is_deeply($obj->fasta_to_add, \@expected_fasta_to_add, 'Load fasta to add info from CSV file');
is($obj->gi_taxid_dmp_file, $obj->database . "/taxonomy/gi_taxid_nucl.dmp", 'gi_taxid_nucl.dmp filename OK');
is($obj->names_dmp_file, $obj->database . "/taxonomy/names.dmp", 'names.dmp filename OK');
is($obj->nodes_dmp_file, $obj->database . "/taxonomy/nodes.dmp", 'nodes.dmp filename OK');


# need to make expeced directory structure to test appending to taxon files
mkdir $db;
mkdir "$db/taxonomy";
$obj->_add_fastas_to_db();
for my $name ('gi_taxid_nucl.dmp', 'names.dmp', 'nodes.dmp') {
    ok(compare("$db/taxonomy/$name", "t/data/Kraken_add_fastas_to_db.$name") == 0, "add_fastas_to_db file $name OK");
}
remove_tree $db;
ok(compare("t/data/Kraken_add_fastas_to_db.out.csv", $tmp_csv) == 0, "CSV of info about added fastas OK");
unlink $tmp_csv;


my $outfile = 'tmp.kraken_test';
$obj->_replace_fasta_headers('t/data/Kraken_replace_fasta_headers.in.fa', $outfile, 42);
ok(compare('t/data/Kraken_replace_fasta_headers.out.fa', $outfile) == 0, '_replace_fasta_headers() OK');
unlink $outfile;

my $infile = 't/data/Kraken_append_line.in';
cp $infile, $outfile;
$obj->_append_line_to_file($outfile, "new line");
ok(compare('t/data/Kraken_append_line.out', $outfile) == 0,  '_append_line_to_file() OK');
unlink $outfile;



ok($obj = Bio::Metagenomics::External::Kraken->new(
    database => 'DB',
    reads_1 => 'reads_1.fastq',
    reads_2 => 'reads_2.fastq',
    preload => 1,
), 'initialize object with read pairs');
is($obj->_run_kraken_command('out'), 'kraken --db DB --threads 1 --output out --preload --paired reads_1.fastq reads_2.fastq', 'Construct kraken command with read pairs and preload');

done_testing();
