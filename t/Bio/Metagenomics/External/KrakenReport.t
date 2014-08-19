#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::External::KrakenReport');
}


my @test_lines = (
    "\t0.42\t42\t42\tU\t0\tUnclassified\n",
    "\t0.42\t1042\t43\tD\t42\t  Domain\n",
    "\t0.42\t3042\t45\tP\t43\t    Phylum\n",
    "\t0.42\t4042\t46\tC\t44\t      Class\n",
    "\t0.42\t5042\t47\tO\t45\t        Order\n",
    "\t0.42\t6042\t48\tF\t46\t          Family\n",
    "\t0.42\t7042\t49\tG\t47\t            Genus\n",
    "\t0.42\t8042\t50\tS\t48\t              Species\n",
    "\t0.42\t9042\t51\t-\t49\t                Strain\n",
);

my @expected = (
    [42,   42, 'U', 'Unclassified', 0],
    [1042, 43, 'D', 'Domain', 2],
    [3042, 45, 'P', 'Phylum', 4],
    [4042, 46, 'C', 'Class', 6],
    [5042, 47, 'O', 'Order', 8],
    [6042, 48, 'F', 'Family', 10],
    [7042, 49, 'G', 'Genus', 12],
    [8042, 50, 'S', 'Species', 14],
    [9042, 51, '-', 'Strain', 16],
);


foreach my $i (0 .. $#test_lines) {
    my @got = Bio::Metagenomics::External::KrakenReport::_parse_report_line($test_lines[$i]);
    is_deeply(\@got, $expected[$i]);
}


my $obj;
ok($obj = Bio::Metagenomics::External::KrakenReport->new(
    filename => 't/data/KrakenReport.report1'
), 'initialize object from t/data/KrakenReport.report1');


@expected = (
    {clade_reads => 40, node_reads => 10, taxon => 'D', name => 'Domain1'},
    {clade_reads => 39, node_reads => 10, taxon => 'P', name => 'Phylum1'},
    {clade_reads => 38, node_reads => 10, taxon => 'C', name => 'Class1'},
    {clade_reads => 37, node_reads => 2, taxon => 'O', name => 'Order1'},
    {clade_reads => 36, node_reads => 2, taxon => 'F', name => 'Family1'},
    {clade_reads => 35, node_reads => 2, taxon => 'G', name => 'Genus1'},
    {clade_reads => 34, node_reads => 2, taxon => 'S', name => 'Species1'},
    {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'Strain1'},
    {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'Strain2'},
    {clade_reads => 50, node_reads => 10, taxon => 'D', name => 'Domain2'},
    {clade_reads => 49, node_reads => 10, taxon => 'P', name => 'Phylum2'},
    {clade_reads => 48, node_reads => 10, taxon => 'C', name => 'Class2'},
    {clade_reads => 46, node_reads => 2, taxon => 'F', name => 'Family2'},
    {clade_reads => 45, node_reads => 2, taxon => 'G', name => 'Genus2'},
    {clade_reads => 44, node_reads => 2, taxon => 'S', name => 'Species2'},
    {clade_reads => 22, node_reads => 2, taxon => 'T', name => 'Strain3'},
    {clade_reads => 22, node_reads => 2, taxon => 'T', name => 'Strain4'},
);


is_deeply($obj->hits, \@expected);
is($obj->total_reads, 199);
is($obj->unclassified_reads, 10);


my @levels = qw/ D P C O F G S T/;
@expected = (
    [
        {clade_reads => 40, node_reads => 10, taxon => 'D', name => 'Domain1'},
        {clade_reads => 50, node_reads => 10, taxon => 'D', name => 'Domain2'},
    ],
    [
        {clade_reads => 39, node_reads => 10, taxon => 'P', name => 'Phylum1'},
        {clade_reads => 49, node_reads => 10, taxon => 'P', name => 'Phylum2'},
    ],
    [
        {clade_reads => 38, node_reads => 10, taxon => 'C', name => 'Class1'},
        {clade_reads => 48, node_reads => 10, taxon => 'C', name => 'Class2'},
    ],
    [
        {clade_reads => 37, node_reads => 2, taxon => 'O', name => 'Order1'},
    ],
    [
        {clade_reads => 36, node_reads => 2, taxon => 'F', name => 'Family1'},
        {clade_reads => 46, node_reads => 2, taxon => 'F', name => 'Family2'},
    ],
    [
        {clade_reads => 35, node_reads => 2, taxon => 'G', name => 'Genus1'},
        {clade_reads => 45, node_reads => 2, taxon => 'G', name => 'Genus2'},
    ],
    [
        {clade_reads => 34, node_reads => 2, taxon => 'S', name => 'Species1'},
        {clade_reads => 44, node_reads => 2, taxon => 'S', name => 'Species2'},
    ],
    [
        {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'Strain1'},
        {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'Strain2'},
        {clade_reads => 22, node_reads => 2, taxon => 'T', name => 'Strain3'},
        {clade_reads => 22, node_reads => 2, taxon => 'T', name => 'Strain4'},
    ],
);


for my $i (0..$#levels) {
    is_deeply($obj->hits_from_level($levels[$i]), $expected[$i]);
}


ok($obj = Bio::Metagenomics::External::KrakenReport->new(
    filename => 't/data/KrakenReport.report3'
), 'initialize object from t/data/KrakenReport.report3');

@expected = (
    {clade_reads => 40, node_reads => 10, taxon => 'D', name => 'Domain1'},
    {clade_reads => 39, node_reads => 10, taxon => 'P', name => 'Phylum1'},
    {clade_reads => 38, node_reads => 10, taxon => 'C', name => 'Class1'},
    {clade_reads => 37, node_reads => 2, taxon => 'O', name => 'Order1'},
    {clade_reads => 36, node_reads => 2, taxon => 'F', name => 'Family1'},
    {clade_reads => 35, node_reads => 2, taxon => 'G', name => 'Genus1'},
    {clade_reads => 34, node_reads => 2, taxon => 'S', name => 'Species1'},
    {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'Strain1'},
    {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'Strain2'},
    {clade_reads => 17, node_reads => 1, taxon => 'T', name => 'StrainX'},
    {clade_reads => 50, node_reads => 10, taxon => 'D', name => 'Domain2'},
    {clade_reads => 49, node_reads => 10, taxon => 'P', name => 'Phylum2'},
    {clade_reads => 48, node_reads => 10, taxon => 'C', name => 'Class2'},
    {clade_reads => 46, node_reads => 2, taxon => 'F', name => 'Family2'},
    {clade_reads => 45, node_reads => 2, taxon => 'G', name => 'Genus2'},
    {clade_reads => 44, node_reads => 2, taxon => 'S', name => 'Species2'},
    {clade_reads => 22, node_reads => 2, taxon => 'T', name => 'Strain3'},
    {clade_reads => 22, node_reads => 2, taxon => 'T', name => 'Strain4'},
);


is_deeply($obj->hits, \@expected);

done_testing();

