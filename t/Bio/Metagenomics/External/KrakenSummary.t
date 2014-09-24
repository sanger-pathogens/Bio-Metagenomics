#!/usr/bin/env perl
use strict;
use warnings;
use File::Compare;

BEGIN { unshift( @INC, './lib' ) }

use Bio::Metagenomics::External::KrakenReport;
BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::External::KrakenSummary');
}

throws_ok{Bio::Metagenomics::External::KrakenSummary->new(outfile => 'x', taxon_level => 'D')} 'Bio::Metagenomics::Exceptions::KrakenSummaryBuild' , 'KrakenSummary BUILD throws exception if no filenames given';


throws_ok{Bio::Metagenomics::External::KrakenSummary->new(report_files => ['x'], outfile => 'x', taxon_level => 'A')} 'Bio::Metagenomics::Exceptions::KrakenSummaryBuild' , 'KrakenSummary BUILD throws exception if bad taxon level given';

my $obj;
ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => 'kraken_summary_report',
    taxon_level => 'D',
), 'initialize object');


my %expected_reports = (
    't/data/KrakenReport.report1' => Bio::Metagenomics::External::KrakenReport->new(filename => 't/data/KrakenReport.report1'),
    't/data/KrakenReport.report2' => Bio::Metagenomics::External::KrakenReport->new(filename => 't/data/KrakenReport.report2'),
);

$obj->_combine_files_data();
is_deeply($obj->reports, \%expected_reports, 'Kraken reports loaded OK');


ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => 'kraken_summary_report',
    taxon_level => 'D',
    counts => 1,
), 'initialize object');
$obj->_combine_files_data();
my $data = $obj->_gather_output_data();
my @expected_data = (
    ['Domain', 't/data/KrakenReport.report1', 't/data/KrakenReport.report2'],
    ['Total', 209, 1705],
    ['Unclassified', '10', '210'],
    ['Domain1', '40', '240'],
    ['Domain2', '50', '150'],
);
is_deeply($data, \@expected_data, '_gather_output_data OK, no cutoff');


ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => 'kraken_summary_report',
    taxon_level => 'D',
    counts => 1,
    min_cutoff => 200,
), 'initialize object');
$obj->_combine_files_data();
$data = $obj->_gather_output_data();
@expected_data = (
    ['Domain', 't/data/KrakenReport.report1', 't/data/KrakenReport.report2'],
    ['Total', 209, 1705],
    ['Unclassified', '10', '210'],
    ['Domain1', '40', '240'],
);
is_deeply($data, \@expected_data, '_gather_output_data OK, with cutoff');


ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1', 't/data/KrakenReport.report.empty'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => 'kraken_summary_report',
    taxon_level => 'D',
    counts => 1,
), 'initialize object');
$obj->_combine_files_data();
$data = $obj->_gather_output_data();
@expected_data = (
    ['Domain', 't/data/KrakenReport.report1', 't/data/KrakenReport.report2'],
    ['Total', 209, 1705],
    ['Unclassified', '10', '210'],
    ['Domain1', '40', '240'],
    ['Domain2', '50', '150'],
);
is_deeply($data, \@expected_data, '_gather_output_data OK, with one empty kraken report file');

my @two_d_array = (
    [1, 2, 3],
    [4, 5, 6]
);
@expected_data = (
    [1, 4],
    [2, 5],
    [3, 6]
);
my $transposed = Bio::Metagenomics::External::KrakenSummary::_transpose(\@two_d_array);
is_deeply($transposed, \@expected_data, '_transpose OK');


my $outfile = 'kraken_summary_report';
ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => $outfile,
    taxon_level => 'D',
    counts => 1,
), 'initialize object, counts=1');
$obj->run();
ok(compare('t/data/KrakenSummary.out.report.counts', $outfile) == 0, 'Summary report with counts=1 OK');


ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => $outfile,
    taxon_level => 'D',
    counts => 0,
), 'initialize object, counts=0');
$obj->run();
ok(compare('t/data/KrakenSummary.out.report.not_counts', $outfile) == 0, 'Summary report with counts=0 OK');


ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => $outfile,
    taxon_level => 'D',
    counts => 1,
    transpose => 1,
), 'initialize object, transpose=1');
$obj->run();
ok(compare('t/data/KrakenSummary.out.report.counts.transposed', $outfile) == 0, 'Summary report transposed OK');


ok($obj = Bio::Metagenomics::External::KrakenSummary->new(
    report_files => ['t/data/KrakenReport.report1'],
    reports_fofn => 't/data/KrakenSummary.fofn',
    outfile => $outfile,
    taxon_level => 'D',
    counts => 1,
), 'initialize object, counts=1');
$obj->run();
ok(compare('t/data/KrakenSummary.out.report.counts', $outfile) == 0, 'Summary report with counts=1 OK');


done_testing();
