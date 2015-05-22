package Bio::Metagenomics::CommandLine::ConvertFastaToKrakenFormat;

# ABSTRACT: Take in a FASTA file and convert it to a Kraken format

=head1 synopsis

Take in a FASTA file and convert it to a Kraken format

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Bio::Metagenomics::CreateLibrary;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'taxon'       => ( is => 'rw', isa => 'Int',      default  => 32630 );
has 'input_filename'  => ( is => 'rw', isa => 'Str' );
has 'output_filename' => ( is => 'rw', isa => 'Str', default => 'output_file.fa' );
has 'help'            => ( is => 'rw', isa => 'Bool' );

sub BUILD {
    my ($self) = @_;
    my ( $help, $taxon, $input_filename, $output_filename );
    my $options_ok = GetOptionsFromArray(
        $self->args,
        't|taxon=i'           => \$taxon,
        'o|output_filename=s' => \$output_filename,
        'h|help'              => \$help,
    );

    if ( !($options_ok) or scalar( @{ $self->args } ) != 1 or $help or ( -e $self->args->[0] ) ) {
        $self->usage_text;
    }

    $self->input_filename( $self->args->[0] );
    $self->taxon($taxon)                     if ( defined($taxon) );
    $self->output_filename($output_filename) if ( defined($output_filename) );
}

sub run {
    my ($self) = @_;
    Bio::Metagenomics::CreateLibrary->new(
        taxon           => $self->taxon,
        output_filename => $self->output_filename,
        input_filename  => $self->input_filename
    )->convert();

}

sub usage_text {
    my ($self) = @_;

    print $self->script_name . " [options] input_file.fa

Take in a FASTA file and convert it to a Kraken formated file.

Options:

-t, --taxon
    Taxon ID for the sequences. Defaults to 32630 (synthetic construct).

-o, --output_filename
    Output filename. Defaults to output_file.fa

-h, -help
    Show this help and exit

";

    exit(1);

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
