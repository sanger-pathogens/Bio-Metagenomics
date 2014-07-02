package Bio::Metagenomics::FileConvert;

# ABSTRACT: For converting from one file format to another

=head1 SYNPOSIS

For converting from one file format to another

=cut


use Moose;
use Bio::Metagenomics::Exceptions;
use Bio::Metagenomics::TaxonRank;

has '_kraken_rank_letter_to_word' => ( is => 'ro', isa =>'HashRef', builder => '_build_kraken_rank_letter_to_word', init_arg => undef, lazy => 1 );
has 'infile'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'informat'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'outfile'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'outformat' => ( is => 'ro', isa => 'Str', required => 1 );


sub _build_kraken_rank_letter_to_word {
    my %h = (
        'D' => 'domain',
        'P' => 'phylum',
        'C' => 'class',
        'O' => 'order',
        'F' => 'family',
        'G' => 'genus',
        'S' => 'species',
        'U' => 'unclassified',
        '-' => 'unknown',
    );
    return \%h;
}


sub BUILD {
    my ($self) = @_;
    unless ($self->informat eq "kraken" and $self->outformat eq "metaphlan") {
        Bio::Metagenomics::Exceptions::FileConvertTypes->throw(error => "informat:" . $self->informat . ". Outformat:" . $self->outformat);
    }
}


sub convert {
    my ($self) = @_;
    if ($self->informat eq "kraken" and $self->outformat eq "metaphlan") {
        $self->_kraken_report_to_metaphlan();
    }
    else {
        Bio::Metagenomics::Exceptions::FileConvertTypes->throw(error => "informat:" . $self->informat . ". Outformat:" . $self->outformat);
    }
}


sub _kraken_report_line_to_data {
    my ($self, $line) = @_;
    chomp $line;
    $line =~ s/^\s+//;
    my (undef, $count, undef, $rank, undef, $name) = split (/\t/, $line);
    $name =~ s/^\s+//;
    $name =~ s/\s+/_/g;
    return ($count, $self->_kraken_rank_letter_to_word->{$rank}, $name);
}


sub _kraken_report_to_metaphlan {
    my ($self) = @_;

    # Metaphlan has its percentages to more decimal places.
    # Not sure if this matters or not, so we'll figure ot how many reads
    # there are in total and recalculate the percentages
    open FIN, $self->infile or die $!;
    open FOUT, ">" . $self->outfile or die $!;
    # First two lines should be unclassified and classified as 'root' reads.
    # Sum of these is the total reads
    my $line = <FIN>;
    my ($unclassified_count, $rank, $name) = $self->_kraken_report_line_to_data($line);
    ($name eq 'unclassified' and $rank eq 'unclassified') or Bio::Metagenomics::Exceptions::FileConvertReadKraken->throw();
    my $root_count;
    $line = <FIN>;
    ($root_count, $rank, $name) = $self->_kraken_report_line_to_data($line);
    ($name eq 'root' and $rank eq 'unknown') or Bio::Metagenomics::Exceptions::FileConvertReadKraken->throw();
    my $total_reads = $unclassified_count + $root_count;
    my $pc = sprintf "%.5f", 100 * $unclassified_count / $total_reads;
    print FOUT "k__unclassified\t$pc\n";
    my $count;
    my $taxon_rank = Bio::Metagenomics::TaxonRank->new();

    while ($line = <FIN>) {
        ($count, $rank, $name) = $self->_kraken_report_line_to_data($line);
        next if ($rank eq 'unknown');
        $taxon_rank->set_rank($rank, $name);
        $pc = sprintf "%.5f", 100 * $count / $total_reads;
        print FOUT $taxon_rank->to_metaphlan_string() . "\t$pc\n";
    }

    close FOUT or die $!;
    close FIN or die $!;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
