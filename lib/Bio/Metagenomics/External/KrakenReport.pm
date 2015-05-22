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
    if ($self->total_reads == 0) {
        warn "Warning: zero total reads from file " . $self->filename . "\n";
    }
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
    my $species_indent_level = -42;
    my $under_species = 0;
    my %taxons = map { $_ => 1 } qw/U D K P C O F G S -/;

    open F, $self->filename or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "filename: '" . $self->filename . "'" );
    while (my $line = <F>) {
        next if($line =~ /^\#/ || $line =~ /^\s*$/);
        my ($clade_reads, $node_reads, $taxon_letter, $name, $indent_level) = _parse_report_line($line);
        $self->total_reads($self->total_reads + $node_reads);
        if (!defined $taxons{$taxon_letter}) {
            Bio::Metagenomics::Exceptions::KrakenReportTaxonUnknown->throw(error => "Unknown taxon from this line:$line\n");
        }
        elsif ($taxon_letter eq 'U' and $name eq 'unclassified') {
            $self->unclassified_reads($clade_reads);
        }
        elsif ($taxon_letter ne '-' or ($under_species and $species_indent_level + 2 <= $indent_level)) {
            my %hit = (
                clade_reads => $clade_reads,
                node_reads => $node_reads,
                taxon => $taxon_letter eq '-' ? 'T' : $taxon_letter,
                name => $name
            );
            push (@{$self->hits}, \%hit);
            if ($taxon_letter eq 'S') {
                $under_species = 1;
                $species_indent_level = $indent_level;
            }
            if ($indent_level < $species_indent_level) {
                $under_species = 0;
            }
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
