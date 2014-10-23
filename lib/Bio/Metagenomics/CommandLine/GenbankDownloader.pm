package Bio::Metagenomics::CommandLine::GenbankDownloader;

# ABSTRACT: Downloads fasta files from genbank

# PODNAME: metagm_genbank_downloader

=head1 synopsis

Downloads fasta files from genbank

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Metagenomics::Genbank;

has 'args'               => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'directory'          => ( is => 'rw', isa => 'Str' );
has 'ids_file'           => ( is => 'rw', isa => 'Str' );


sub BUILD {
    my ($self) = @_;
    my $help;
    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
    );

    if (!($options_ok) or scalar(@{$self->args}) != 2 or $help){
        $self->usage_text;
    }

    $self->ids_file($self->args->[0]);
    $self->directory($self->args->[1]);
}


sub run {
    my ($self) = @_;
    my $gb = Bio::Metagenomics::Genbank->new(
        ids_file => $self->ids_file,
        output_dir => $self->directory,
    );
    $gb->download();
}


sub usage_text {
    my ($self) = @_;

    print $self->script_name . " [options] <file of IDs to download> <Output directory name>

Downloads FASTA files from genbank.

The IDs file must have one ID per line.
Each ID must be a GenBank ID or a GI number.
If the ID starts with 'GCA_', then it is assumed to be an assembly ID and all
the corresponding contigs are downloaded and put into a single file.

Each FASTA file is gzipped and called ID.fasta.gz.
If that file already exists in the output
directory, then nothing new is downloaded for that ID.

Options:

-h, -help
    Show this help and exit

";

    exit(1);

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
