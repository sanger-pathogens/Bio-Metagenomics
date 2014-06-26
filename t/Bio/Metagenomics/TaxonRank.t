#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Metagenomics::TaxonRank');
}


my $obj;
my @ids = ('1','2','3');

ok($obj = Bio::Metagenomics::TaxonRank->new(), 'initialize object');

is($obj->to_metaphlan_string(), '', 'Test to_string, no values');
throws_ok{$obj->set_rank('phylum', 'p')} 'Bio::Metagenomics::Exceptions::TaxonRankTooHigh', 'Throws error if add too high rank';
throws_ok{$obj->set_rank('notarank', 'p')} 'Bio::Metagenomics::Exceptions::TaxonRank', 'Throws error unknown rank';

$obj->set_rank('domain', 'do');
is($obj->to_metaphlan_string(), 'k__do', 'Test to_string, domain only');
$obj->set_rank('phylum', 'ph');
is($obj->to_metaphlan_string(), 'k__do|p__ph', 'Test to_string, phylum');
$obj->set_rank('class', 'cla ss');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss', 'Test to_string, class and replace spaces with underscores');
$obj->set_rank('order', 'or');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss|o__or', 'Test to_string, order');
$obj->set_rank('family', 'fa mi ly');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss|o__or|f__fa_mi_ly', 'Test to_string, family, more than one space');
$obj->set_rank('genus', 'ge');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss|o__or|f__fa_mi_ly|g__ge', 'Test to_string, genus');
$obj->set_rank('species', 'sp');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss|o__or|f__fa_mi_ly|g__ge|s__sp', 'Test to_string, species');
$obj->set_rank('species', 'sp2');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss|o__or|f__fa_mi_ly|g__ge|s__sp2', 'Test replace species');
$obj->set_rank('genus', 'ge2');
is($obj->to_metaphlan_string(), 'k__do|p__ph|c__cla_ss|o__or|f__fa_mi_ly|g__ge2', 'Test replace genus');
$obj->set_rank('domain', 'do2');
is($obj->to_metaphlan_string(), 'k__do2', 'Test replace domain');

done_testing();

