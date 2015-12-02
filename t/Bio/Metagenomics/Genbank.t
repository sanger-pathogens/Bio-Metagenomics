#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::Genbank');
}


throws_ok{Bio::Metagenomics::Genbank->new(output_dir => 'x')} 'Bio::Metagenomics::Exceptions::GenbankBuild' , 'Genkbank BUILD throws exception if no ids given';
throws_ok{Bio::Metagenomics::Genbank->new(output_dir => 'x', 'ids_list'=>[])} 'Bio::Metagenomics::Exceptions::GenbankBuild' , 'Genkbank BUILD throws exception if no ids given';

my $obj;
my @ids = ('1','2','3');

ok($obj = Bio::Metagenomics::Genbank->new(
    'ids_list' => \@ids,
    'ids_file' => 't/data/genbank_load_ids_from_file.txt',
    'output_dir' => 'genbank_test',
), 'initialize object');

my @expected_ids = ('1', '2', '3', 'file_id1', 'file_id2');
is_deeply($obj->ids_list, \@expected_ids, 'IDs got from list and file OK');

throws_ok{$obj->_download_record_url('notafiletype', 'outfile')} 'Bio::Metagenomics::Exceptions::GenbankUnknownFiletype', 'Throw error if unknown filetype given';

is($obj->_download_record_url(Bio::Metagenomics::Genbank::FASTA, 'OUT'), 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=fasta&retmode=text&id=OUT', 'Generate download URL OK for fasta file');
is($obj->_download_record_url(Bio::Metagenomics::Genbank::GENBANK, 'OUT'), 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=gb&retmode=text&id=OUT', 'Generate download URL OK for genbank file');

is($obj->_filetype('t/data/genbank_get_output_filetype.fa'), Bio::Metagenomics::Genbank::FASTA, 'Detect FASTA filetype OK');
is($obj->_filetype('t/data/genbank_get_output_filetype.gb'), Bio::Metagenomics::Genbank::GENBANK, 'Detect GENBANK filetype OK');
is($obj->_filetype('t/data/genbank_get_output_filetype.unknown'), Bio::Metagenomics::Genbank::UNKNOWN, 'Detect UNKNOWN filetype OK');

is($obj->_fasta_to_number_of_sequences('t/data/genbank_fasta_to_number_of_sequences.42.fa'), 42, '_fasta_to_number_of_sequences() OK non-empty file');
is($obj->_fasta_to_number_of_sequences('t/data/genbank_fasta_to_number_of_sequences.0.fa'), 0, '_fasta_to_number_of_sequences() OK empty file');

@expected_ids = qw/CU329670.1 CU329671.1 CU329672.1 X54421.1/;
my $got_ids = $obj->_assembly_report_to_genbank_ids('t/data/genbank_example_assembly_report.txt');
is_deeply($got_ids, \@expected_ids, 'Get IDs from assembly report file OK');

is($obj->_fasta_is_ok('t/data/genbank_fasta_is_ok.ok.fa'), 1, '_fasta_is_ok on OK file');
is($obj->_fasta_is_ok('t/data/genbank_fasta_is_ok.not_ok.fa'), 0, '_fasta_is_ok on bad file');


done_testing();
