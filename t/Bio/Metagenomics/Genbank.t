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

throws_ok{$obj->_download_record_url('notafiletype', 'outfile')} 'Bio::Metagenomics::Exceptions::GenbankUnknownFiletype', 'Throw error if unknwon filetype given';

is($obj->_download_record_url(Bio::Metagenomics::Genbank::FASTA, 'OUT'), 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=fasta&retmode=text&id=OUT', 'Generate download URL OK for fasta file');
is($obj->_download_record_url(Bio::Metagenomics::Genbank::GENBANK, 'OUT'), 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=gb&retmode=text&id=OUT', 'Generate download URL OK for genbank file');

is($obj->_filetype('t/data/genbank_get_output_filetype.fa'), Bio::Metagenomics::Genbank::FASTA, 'Detect FASTA filetype OK');
is($obj->_filetype('t/data/genbank_get_output_filetype.gb'), Bio::Metagenomics::Genbank::GENBANK, 'Detect GENBANK filetype OK');
is($obj->_filetype('t/data/genbank_get_output_filetype.unknown'), Bio::Metagenomics::Genbank::UNKNOWN, 'Detect UNKNOWN filetype OK');

done_testing();
