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
has 'noclean'            => ( is => 'rw', isa => 'Bool', default => 1 );
has 'database'           => ( is => 'rw', isa => 'Str' );
has 'kraken_build_exec'  => ( is => 'rw', isa => 'Str', default => 'kraken-build' );
has 'max_db_size'        => ( is => 'rw', isa => 'Int', default => 4);
has 'minimizer_len'      => ( is => 'rw', isa => 'Int', default => 13);
has 'threads'            => ( is => 'rw', isa => 'Int', default => 1);


sub BUILD {
    my ($self) = @_;
    my (
        $help,
        $kraken_build_exec,
        $max_db_size,
        $minimizer_len,
        $noclean,
        $threads,
    );

    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
        'n|noclean' => \$noclean,
        'kraken_build' => \$kraken_build_exec,
        'max_db_size=i' => \$max_db_size,
        'minimizer_len=i' => \$minimizer_len,
        't|threads=i' => \$threads,
    );

    if (!($options_ok) or scalar(@{$self->args}) != 1 or $help){
        $self->usage_text;
    }

    $self->database($self->args->[0]);
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
        database => $self->database,
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

-h,help
    Show this help and exit

-kraken_build FILENAME
    kraken-build executable [" . $self->kraken_build_exec . "]

-max_db_size INT
    Value used --max-db-size when running kraken-build [" . $self->max_db_size . "]

-minimizer_len INT
    Value used --minimizer-len when running kraken-build [" . $self->minimizer_len . "]

-n,-noclean
    Do not clean up database afterwards. Default is to clean by running:
    kraken-build --clean

-t,-threads INT
    Number of threads [" . $self->threads . "]
";

    exit(1);

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
