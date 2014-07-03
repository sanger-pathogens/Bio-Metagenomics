package Bio::Metagenomics::CommandLine::MakeMetaphlanHeatmap;

# ABSTRACT: Runs Metaphlan scripts to make heatmap

# PODNAME: metagm_make_metaphlan_heatmap

=head1 synopsis

Runs Metaphlan scripts to make heatmap

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Metagenomics::External::Metaphlan;

has 'args'                        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'                 => ( is => 'ro', isa => 'Str', required => 1 );
has 'hclust_heatmap_exec'         => ( is => 'rw', isa => 'Str', default => 'metaphlan_hclust_heatmap.py' );
has 'hclust_heatmap_options'      => ( is => 'rw', isa => 'Str', default => '-c bbcry --top 25 --minv 0.1 -s log');
has 'merge_metaphlan_tables_exec' => ( is => 'rw', isa => 'Str', default => 'merge_metaphlan_tables.py' );
has 'names_file'                  => ( is => 'rw', isa => 'Str' );
has 'names_list'                  => ( is => 'rw', isa => 'ArrayRef[Str]');
has 'outfile'                     => ( is => 'rw', isa => 'Str');


sub BUILD {
    my ($self) = @_;
    my (
        $help,
        $names_file,
        @names_list,
        $hclust_heatmap_exec,
        $hclust_heatmap_options,
        $merge_metaphlan_tables_exec,
        $outfile,
    );

    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
        'f|names_file=s' => \$names_file,
        'a|add_file=s' => \@names_list,
        'hclust_heatmap_exec=s' => \$hclust_heatmap_exec,
        'hclust_heatmap_options=s' => \$hclust_heatmap_options,
        'merge_metaphlan_tables_exec=s' => \$merge_metaphlan_tables_exec,
    );

    if (!($options_ok) or scalar(@{$self->args}) != 1 or $help){
        $self->usage_text;
    }

    $self->outfile($self->args->[0]);
    $self->names_file($names_file) if defined($names_file);
    $self->names_list(\@names_list) if scalar(@names_list);
    $self->hclust_heatmap_exec($hclust_heatmap_exec) if defined($hclust_heatmap_exec);
    $self->hclust_heatmap_options($hclust_heatmap_options) if defined($hclust_heatmap_options);
    $self->merge_metaphlan_tables_exec($merge_metaphlan_tables_exec) if defined($merge_metaphlan_tables_exec);
}


sub run {
    my ($self) = @_;
    my $metaphlan = Bio::Metagenomics::External::Metaphlan->new(
        names_file => $self->names_file,
        names_list => $self->names_list,
        hclust_heatmap_exec => $self->hclust_heatmap_exec,
        hclust_heatmap_options => $self->hclust_heatmap_options,
        merge_metaphlan_tables_exec => $self->merge_metaphlan_tables_exec,
        outfile => $self->outfile,
    );
    $metaphlan->make_taxon_heatmap;
}


sub usage_text {
    my ($self) = @_;

    print $self->script_name . " [options] <output_heatmap.png>

Makes a heatmap using Metaphlan scripts. Input is kraken report files.

Options:

-h,help
    Show this help and exit

-a,add_file FILENAME
    Use kraken report with FILENAME.
    This option can be used more than once to add as many files as you like.
    See also -names_file.

-f|names_file FILENAME
    Add filenames from file.  Format is one filename per line.

-hclust_heatmap_exec FILENAME
    metaphlan_hclust_heatmap.py executable [" . $self->hclust_heatmap_exec . "]

-hclust_heatmap_options \"Options in quotes\"
    Options to pass to metaphlan_hclust_heatmap.py. These are NOT sanity
    checked [" . $self->hclust_heatmap_options . "]

-merge_metaphlan_tables_exec FILENAME
    merge_metaphlan_tables.py executable [" . $self->merge_metaphlan_tables_exec . "]
";

    exit(1);

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
