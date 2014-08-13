package Bio::Metagenomics::External::KrakenReport;

# ABSTRACT: Package for reading Kraken report files

=head1 SYNOPSIS

Package for reading Kraken report files

=cut

use Moose;
use Bio::Metagenomics::Exceptions;

has 'filename'           => ( is => 'ro', isa => 'Str', required => 1 );
has 'total_reads'        => ( is => 'rw', isa => 'Int');
has 'unclassified_reads' => ( is => 'rw', isa => 'Int');
has 'hits'               => ( is => 'ro', isa => 'ArrayRef', default => sub { [] });


sub BUILD {
    my ($self) = @_;
    $self->_load_info_from_file();
}


sub _parse_report_line {
    my $line = shift;
    chomp $line;
    $line =~ s/^\s+//;
    my (undef, $clade_reads, $node_reads, $taxon_letter, undef, $name) = split(/\t/, $line);
    $name =~ /^(\s*)/;
    my $indent_level = length($1);
    $name =~ s/^\s+//;
    return ($clade_reads, $node_reads, $taxon_letter, $name, $indent_level);
}


sub _load_info_from_file {
    my ($self) = @_;
    $self->total_reads(0);

    my %indent_to_taxon = (
        0 => 'U',
        2 => 'D',
        4 => 'P',
        6 => 'C',
        8 => 'O',
        10 => 'F',
        12 => 'G',
        14 => 'S',
    );

    my %taxon_to_indent = reverse %indent_to_taxon;

    open F, $self->filename or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "filename: '" . $self->filename . "'" );
    while (my $line = <F>) {
        my ($clade_reads, $node_reads, $taxon_letter, $name, $indent_level) = _parse_report_line($line);
        $self->total_reads($self->total_reads + $node_reads);
        if ($taxon_letter ne '-' and $taxon_to_indent{$taxon_letter} != $indent_level) {
            Bio::Metagenomics::Exceptions::KrakenReportIndentLevel(error => "expected indent level:" . $taxon_to_indent{$taxon_letter} .". got:$indent_level. Line: $line");
        }

        if ($taxon_letter eq 'U' and $name eq 'unclassified') {
            $self->unclassified_reads($clade_reads);
        }
        elsif (defined $taxon_to_indent{$taxon_letter} or  ($taxon_letter eq '-' and $taxon_to_indent{'S'} + 2 == $indent_level)) {
            my %hit = (
                clade_reads => $clade_reads,
                node_reads => $node_reads,
                taxon => $taxon_letter eq '-' ? 'T' : $taxon_letter,
                name => $name
            );
            push (@{$self->hits}, \%hit);
        }
    }
    close F;
}


sub hits_from_level {
    my ($self) = shift;
    my $level = shift;
    my @hits = grep { $_->{taxon} eq $level } @{$self->hits};
    return \@hits;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
