package Bio::Metagenomics::CommandLine::RunKraken;

# ABSTRACT: Runs kraken, makes kraken report file. Does not keep intermediate files

# PODNAME: metagm_build_kraken_db

=head1 synopsis

Runs kraken, makes kraken report file. Does not keep intermediate files

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Metagenomics::External::Kraken;

has 'args'               => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'noclean'            => ( is => 'rw', isa => 'Bool', default => 0 );
has 'keep_readnames'     => ( is => 'rw', isa => 'Bool', default => 0 );
has 'database'           => ( is => 'rw', isa => 'Str' );
has 'kraken_exec'        => ( is => 'rw', isa => 'Str', default => 'kraken' );
has 'kraken_report_exec' => ( is => 'rw', isa => 'Str', default => 'kraken-report' );
has 'outfile'            => ( is => 'rw', isa => 'Str');
has 'preload'            => ( is => 'rw', isa => 'Bool', default => 0 );
has 'reads_1'            => ( is => 'rw', isa => 'Str');
has 'reads_2'            => ( is => 'rw', isa => 'Str');
has 'threads'            => ( is => 'rw', isa => 'Int', default => 1 );
has 'tmp_file'           => ( is => 'rw', isa => 'Str');


sub BUILD {
    my ($self) = @_;
    my (
        $help,
        $keep_readnames,
        $kraken_exec,
        $kraken_report_exec,
        $noclean,
        $preload,
        $threads,
        $tmp_file,
    );

    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
        'keep_readnames' => \$keep_readnames,
        'n|noclean' => \$noclean,
        'kraken_exec=s' => \$kraken_exec,
        'kraken_report=s' => \$kraken_report_exec,
        'preload' => \$preload,
        't|threads=i' => \$threads,
        'u|tmp_file=s' => \$tmp_file,
    );

    if (!($options_ok) or !(scalar(@{$self->args}) == 3 or scalar(@{$self->args}) == 4) or $help){
        $self->usage_text;
    }

    $self->database($self->args->[0]);
    $self->outfile($self->args->[1]);
    $self->reads_1($self->args->[2]);
    if (scalar(@{$self->args}) == 4) {
        $self->reads_2($self->args->[3]);
    }

    $self->keep_readnames($keep_readnames) if defined($keep_readnames);
    $self->kraken_exec($kraken_exec) if defined($kraken_exec);
    $self->kraken_report_exec($kraken_report_exec) if defined($kraken_report_exec);
    $self->noclean($noclean) if defined($noclean);
    $self->preload($preload) if defined($preload);
    $self->threads($threads) if defined($threads);
    $self->tmp_file($tmp_file) if defined($tmp_file);
}


sub run {
    my ($self) = @_;
    my $kraken = Bio::Metagenomics::External::Kraken->new(
        clean => !($self->noclean),
        database => $self->database,
        kraken_exec => $self->kraken_exec,
        kraken_report_exec => $self->kraken_report_exec,
        preload => $self->preload,
        reads_1 => $self->reads_1,
        reads_2 => $self->reads_2,
        threads => $self->threads,
        tmp_file => $self->tmp_file,
        fix_fastq_headers => !($self->keep_readnames),
    );
    $kraken->run_kraken($self->outfile);
}


sub usage_text {
    my ($self) = @_;

    print $self->script_name . " [options] <database dir> <out.report> <reads_1.fastq> [reads_2.fastq]

Runs Kraken, making report file. If a second file of reads is given, then they
are assumed to be mates of the first file and Kraken is run in --paired mode.

Options:

-h,help
    Show this help and exit

-keep_readnames
    Do not rename the sequences in input fastq file(s)
    (saves run time, but may break kraken)

-kraken_exec FILENAME
    kraken executable [" . $self->kraken_exec . "]

-kraken_report FILENAME
    kraken-report executable [" . $self->kraken_report_exec . "]

-n,-noclean
    Do not delete intermediate file made by Kraken

-preload
    Use the --preload option when running Kraken.

-t,-threads INT
    Number of threads [" . $self->threads . "]

-u,-tmp_file FILENAME
    Name of temporary file made when running kraken.
    (It's the output of kraken/input of kraken-report).
    This file is 1 line per read, so can be quite large.
    Default: <name_of_ouptput_report>.kraken_out
";

    exit(1);

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
