package Bio::Metagenomics::CommandLine::BuildKrakenDb;

# ABSTRACT: Builds a kraken database

# PODNAME: metagm_build_kraken_db

=head1 synopsis

Builds a Kraken database

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Metagenomics::External::Kraken;

has 'args'               => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'database'           => ( is => 'rw', isa => 'Str' );
has 'downloaded'         => ( is => 'rw', isa => 'Str' );
has 'csv_to_add'         => ( is => 'rw', isa => 'Str' );
has 'csv_to_add_out'     => ( is => 'rw', isa => 'Str' );
has 'dbs_to_download'    => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub{['bacteria', 'viruses', 'human']});
has 'ids_file'           => ( is => 'rw', isa => 'Str' );
has 'ids_list'           => ( is => 'rw', isa => 'ArrayRef[Str]');
has 'kraken_build_exec'  => ( is => 'rw', isa => 'Str', default => 'kraken-build' );
has 'max_db_size'        => ( is => 'rw', isa => 'Int', default => 4);
has 'minimizer_len'      => ( is => 'rw', isa => 'Int', default => 13);
has 'noclean'            => ( is => 'rw', isa => 'Bool', default => 0 );
has 'threads'            => ( is => 'rw', isa => 'Int', default => 1);


sub BUILD {
    my ($self) = @_;
    my (
        $help,
        $csv_to_add,
        $csv_to_add_out,
        @dbs_to_download,
        $downloaded,
        $ids_file,
        @ids_list,
        $kraken_build_exec,
        $max_db_size,
        $minimizer_len,
        $noclean,
        $threads,
    );

    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
        'c|csv_to_add=s' => \$csv_to_add,
        'csv_to_add_out=s' => \$csv_to_add_out,
        'd|dbs_to_download=s' => \@dbs_to_download,
        'downloaded' => \$downloaded,
        'ids_file=s' => \$ids_file,
        'a|add_id=s' => \@ids_list,
        'n|noclean' => \$noclean,
        'kraken_build=s' => \$kraken_build_exec,
        'max_db_size=i' => \$max_db_size,
        'minimizer_len=i' => \$minimizer_len,
        't|threads=i' => \$threads,
    );

    if (!($options_ok) or scalar(@{$self->args}) != 1 or $help){
        $self->usage_text;
    }

    $self->csv_to_add($csv_to_add) if defined $csv_to_add;
    $self->csv_to_add_out($csv_to_add_out) if defined $csv_to_add_out;
    $self->database($self->args->[0]);
    $self->downloaded($self->downloaded) if defined $downloaded;
    $self->dbs_to_download(\@dbs_to_download) if scalar(@dbs_to_download);
    $self->ids_file($ids_file) if defined($ids_file);
    $self->ids_list(\@ids_list) if scalar(@ids_list);
    $self->threads($threads) if defined($threads);
    $self->kraken_build_exec($kraken_build_exec) if defined($kraken_build_exec);
    $self->max_db_size($max_db_size) if defined($max_db_size);
    $self->minimizer_len($minimizer_len) if defined($minimizer_len);
    $self->noclean($noclean) if defined($noclean);
}


sub run {
    my ($self) = @_;
    my $kraken = Bio::Metagenomics::External::Kraken->new(
        clean => !($self->noclean),
        csv_fasta_to_add => $self->csv_to_add,
        csv_fasta_to_add_out => $self->csv_to_add_out,
        database => $self->database,
        downloaded => $self->downloaded,
        dbs_to_download => $self->dbs_to_download,
        ids_file => $self->ids_file,
        ids_list => $self->ids_list,
        kraken_build_exec => $self->kraken_build_exec,
        max_db_size => $self->max_db_size,
        minimizer_len => $self->minimizer_len,
        threads => $self->threads,
    );
    $kraken->build;
}


sub usage_text {
    my ($self) = @_;

    print $self->script_name . " [options] <Output directory name>

Creates a new Kraken database in a new directory of the given name.

Options:

-h, -help
    Show this help and exit

-c, -csv_to_add
    Comma-separated file of genomes in FASTA files to add to the database.
    Each genome is added as a child of a user-specified NCBI taxon ID.
    File needs one line per genome with these three columns:
        1. Absolute path to FASTA file
        2. Name of organism to appear in Kraken report file
        3. NCBI taxon ID that will be the parent of this genome

-csv_to_add_out
    If -c is used, then write a new csv file that is the same
    is the input csv, but with two new columns:
        4. Taxon ID given to sample
        5. GI number given to sample

-d, -dbs_to_download
    Kraken databases to download and add to the database. Must be one of:
        bacteria, viruses, human.
    This option can be used more than once if you want to
    download more than one. Default is to use all three.

-downloaded
    Directory of FASTA files to use, that have already
    been downloaded using the script XXXXXX

-a, -add_id ID
    Add genbank record with ID to the database.  ID can be a genbank ID or a
    GI number.  This option can be used more than once to add as many
    genomes as you like.  See also -ids_file.

-ids_file FILENAME
    Add IDs from file to the database.  Format is one line per ID.
    ID can be a genbank ID or a GI number.

-kraken_build FILENAME
    kraken-build executable [" . $self->kraken_build_exec . "]

-max_db_size INT
    Value used --max-db-size when running kraken-build [" . $self->max_db_size . "]

-minimizer_len INT
    Value used --minimizer-len when running kraken-build [" . $self->minimizer_len . "]

-n, -noclean
    Do not clean up database afterwards. Default is to clean by running:
    kraken-build --clean

-t, -threads INT
    Number of threads [" . $self->threads . "]
";

    exit(1);

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
