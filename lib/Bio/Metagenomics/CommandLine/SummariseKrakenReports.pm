package Bio::Metagenomics::CommandLine::SummariseKrakenReports;

# ABSTRACT: Makes summary of a set of kraken reports

# PODNAME: metagm_summarise_kraken_reports

=head1 synopsis

Makes summary of a set of kraken reports

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Metagenomics::External::KrakenSummary;
use Data::Dumper;

has 'args'               => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'outfile'            => ( is => 'rw', isa => 'Str', required => 0 );
has 'assigned_directly' => ( is => 'rw', isa => 'Bool', default => 0);
has 'counts'            => ( is => 'rw', isa => 'Bool', default => 0);
has 'min_cutoff'        => ( is => 'rw', isa => 'Num', default => 0);
has 'report_files'      => ( is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'reports_fofn'      => ( is => 'rw', isa => 'Maybe[Str]');
has 'taxon_level'       => ( is => 'rw', isa => 'Str', required => 1, default => 'P');
has 'transpose'         => ( is => 'rw', isa => 'Bool', default => 0);


sub BUILD {
    my ($self) = @_;
    my (
        $help,
        $assigned_directly,
        $counts,
        $min_cutoff,
        $report_files,
        $reports_fofn,
        $taxon_level,
        $transpose,
    );

    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
        'a|assigned_drectly' => \$assigned_directly,
        'c|counts' => \$counts,
        'm|min_cutoff=f' => \$min_cutoff,
        'f|reports_fofn=s' => \$reports_fofn,
        'l|level=s' => \$taxon_level,
        't|transpose' => \$transpose,
    );

    $self->usage_text unless ($options_ok and (scalar @{$self->args} > 0));
    $self->outfile(shift @{$self->args});

    if (scalar @{$self->args} == 0 and not defined $reports_fofn) {
        print STDERR "Must provide filenames or use -f to give file of filenames. Cannot continue\n";
        exit(1);
    }

    if (scalar @{$self->args} > 0) {
        $self->report_files($self->args);
    }

    $self->assigned_directly($assigned_directly) if defined($assigned_directly);
    $self->counts($counts) if defined($counts);
    $self->min_cutoff($min_cutoff) if defined($min_cutoff);
    $self->reports_fofn($reports_fofn) if defined($reports_fofn);
    $self->taxon_level($taxon_level) if defined($taxon_level);
    $self->transpose($transpose) if defined($transpose);
}


sub run {
    my ($self) = @_;
    my $obj = Bio::Metagenomics::External::KrakenSummary->new(
        reports_fofn => $self->reports_fofn,
        report_files => $self->report_files,
        outfile => $self->outfile,
        taxon_level => $self->taxon_level,
        counts => $self->counts,
        assigned_directly => $self->assigned_directly,
        transpose => $self->transpose,
        min_cutoff => $self->min_cutoff,
    );
    $obj->run();
}


sub usage_text {
    my ($self) = @_;

    print $self->script_name . " [options] <outfile> [list of kraken report filenames]

Produces a sumary from many kraken report files.

Report filenames must be given to this script, which can be done using
one or both of:
    1. list them after the options
    2. use the option -f to give a file of filenames.


Options:

-h,help
    Show this help and exit

-f,reports_fofn
    Files of kraken report filenames

-l,level D|P|C|O|F|G|S|T
    Taxonomic level to output. Choose from:
      D (Domain), P (Phylum), C (Class), O (Order),
      F (Family), G (Genus), S (Species), T (Strain)
    Default: " . $self->taxon_level . "

-c,counts
    Report counts of reads instead of percentages of the total reads in each
    file.

-a,assigned_drectly
    Report reads assigned directly to this taxon, instead of the
    default of reporting reads covered by the clade rooted at this taxon.

-m,min_cutoff
    Cutoff minimum value in at least one report to include in output.
    Default: no cutoff.

-t,transpose
    Transpose output to have files in rows and matches in columns.
    Default is to have matches in rows and files in columns
";
    exit(1);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
