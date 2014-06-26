package Bio::Metagenomics::TaxonRank;

# ABSTRACT: Class for storing axonomy ranks

=head1 SYNPOSIS

Class for storing axonomy ranks

=cut


use Moose;
use Bio::Metagenomics::Exceptions;


has '_ranks' => ( is => 'ro', isa => 'HashRef', builder => '_build_ranks', init_arg => undef );
has '_values' => ( is => 'rw', isa => 'ArrayRef[Str]', init_arg => undef, default => sub { [] } );
has '_metaphlan_strings' => (is => 'ro', isa => 'ArrayRef[Str]', builder => '_build_metaphlan_strings', init_arg => undef );


sub _build_ranks {
    my %ranks = (
        'domain' => 0,
        'phylum' => 1,
        'class' => 2,
        'order' => 3,
        'family' => 4,
        'genus' => 5,
        'species' => 6
    );
    return \%ranks;
}


sub _build_metaphlan_strings {
    my @strings = (
        'k__',
        'p__',
        'c__',
        'o__',
        'f__',
        'g__',
        's__',
    );
    return \@strings;
}


sub set_rank {
    my ($self, $rank, $value) = @_;
    defined ($self->_ranks->{$rank}) or  Bio::Metagenomics::Exceptions::TaxonRank->throw(error => "rank:$rank");
    my $index = $self->_ranks->{$rank};
    $index <= scalar(@{$self->_values}) or Bio::Metagenomics::Exceptions::TaxonRankTooHigh->throw();
    while (scalar(@{$self->_values}) > $index) {
        pop @{$self->_values};
    }
    push @{$self->_values}, $value;
}


sub to_metaphlan_string {
    my ($self) = @_;
    if (scalar(@{$self->_values}) == 0) {
        return '';
    }

    my @strings;
    for my $i (0 .. scalar @{$self->_values} - 1){
        my $value = $self->_values->[$i];
        $value =~ s/\s+/_/g;
        push @strings, $self->_metaphlan_strings->[$i] . $value;
    }
    return join '|', @strings;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
