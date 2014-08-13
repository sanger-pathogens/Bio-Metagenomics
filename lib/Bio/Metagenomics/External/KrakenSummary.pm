package Bio::Metagenomics::External::KrakenSummary;

# ABSTRACT: Package for summarising many kraken reports into one file

=head1 SYNOPSIS

Package for summarising many kraken reports into one file

=cut

use Moose;
use List::Util qw(max);
use Bio::Metagenomics::Exceptions;
use Bio::Metagenomics::External::KrakenReport;
use Data::Dumper;

has 'reports_fofn'      => ( is => 'ro', isa => 'Maybe[Str]');
has 'report_files'      => ( is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'reports'           => ( is => 'rw', isa => 'HashRef', default => sub { {} });
has 'outfile'           => ( is => 'rw', isa => 'Str', required => 1);
has 'taxon_level'       => ( is => 'ro', isa => 'Str', required => 1);
has 'counts'            => ( is => 'ro', isa => 'Bool', default => 0);
has 'assigned_directly' => ( is => 'ro', isa => 'Bool', default => 0);
has 'transpose'         => ( is => 'ro', isa => 'Bool', default => 0);
has 'min_cutoff'        => ( is => 'ro', isa => 'Num', default => 0);
has 'output_data'       => ( is => 'ro', isa => 'ArrayRef');


sub BUILD {
    my ($self) = @_;
    defined($self->report_files) or $self->report_files([]);
    $self->_load_reports_fofn();
    scalar @{$self->report_files} > 0 or Bio::Metagenomics::Exceptions::KrakenSummaryBuild->throw(error => "No report files given");
    my %allowed_levels = map {$_ => 1} qw/ D P C O F G S T/;
    defined $allowed_levels{$self->taxon_level} or Bio::Metagenomics::Exceptions::KrakenSummaryBuild->throw(error => "Bad taxon level:" . $self->taxon_level);
}


sub _load_reports_fofn {
    my ($self) = @_;
    defined($self->reports_fofn) or return;
    open F, $self->reports_fofn or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "filename: '" . $self->reports_fofn . "'");
    while (<F>) {
        chomp;
        push @{$self->report_files}, $_;
    }
    close F or die $!;
}


sub _combine_files_data {
    my ($self) = @_;
    foreach my $fname (@{$self->report_files}) {
        my $report = Bio::Metagenomics::External::KrakenReport->new(filename => $fname);
        $self->reports->{$fname} = $report;
    }
}



sub _gather_output_data {
    my ($self) = @_;
    my %hits;
    my %name_counts;
    foreach my $fname (keys %{$self->reports}) {
        my $level_hits = $self->reports->{$fname}->hits_from_level($self->taxon_level);
        $hits{$fname} = {};
        foreach (@{$level_hits}) {
            $name_counts{$_->{name}} += $_->{node_reads};
            $hits{$fname}{$_->{name}} = $_;
        }
    }

    my @names = reverse sort { $name_counts{$a} <=> $name_counts{$b} } keys(%name_counts);
    my @files = sort @{$self->report_files};
    my %levels = (
        D => 'Domain',
        P => 'Phylum',
        C => 'Class',
        O => 'Order',
        F => 'Family',
        G => 'Genus',
        S => 'Species',
        T => 'Strain',
    );
    my @rows = [($levels{$self->taxon_level}, @files)];
    my @totals = map {$self->reports->{$_}->total_reads} @files;
    push (@rows, [('Total', @totals)]);

    my @unclassified;
    if ($self->counts) {
        @unclassified = map {$self->reports->{$_}->unclassified_reads} @files;
    }
    else {
        @unclassified = map {sprintf("%.2f", 100 * $self->reports->{$_}->unclassified_reads / $self->reports->{$_}->total_reads)} @files;
    }
    push (@rows, [('Unclassified', @unclassified)]);

    foreach my $name (@names) {
        my @row;
        foreach my $file (@files) {
            my $key = $self->assigned_directly ? 'node_reads' : 'clade_reads';
            my $stat = defined $hits{$file}{$name} ? $hits{$file}{$name}{$key} : 0;
            $stat = sprintf("%.2f", 100 * $stat / $self->reports->{$file}->total_reads) unless $self->counts;
            push(@row, $stat);
        }
        next if max(@row) < $self->min_cutoff;
        unshift(@row, $name);
        push(@rows, \@row);

    }
    return \@rows;
}


sub _transpose {
    my $in = shift;
    my @out;
    foreach my $j (0 .. scalar(@{$in->[0]}) - 1) {
        my @column;
        foreach my $i (0 .. scalar(@{$in}) - 1) {
            push(@column, $in->[$i][$j]);
        }
        push(@out, \@column);
    }
    return \@out;
}


sub run {
    my ($self) = @_;
    $self->_combine_files_data();
    my $rows = $self->_gather_output_data();
    $rows = _transpose($rows) if $self->transpose;
    open F, ">" . $self->outfile or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "filename: '" . $self->outfile . "'");
    foreach my $row (@{$rows}) {
        print F join("\t", @{$row}), "\n";
    }
    close F or die $!;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
