package Bio::Metagenomics::External::Metaphlan;

# ABSTRACT: Wrapper for Metaphlan http://huttenhower.sph.harvard.edu/metaphlan

=head1 SYNOPSIS

Wrapper for Metaphlan http://huttenhower.sph.harvard.edu/metaphlan

=cut

use Moose;
use Bio::Metagenomics::Exceptions;
use Bio::Metagenomics::FileConvert;
use File::Temp qw/ tempdir /;
use Cwd;

has 'hclust_heatmap_options'      => ( is => 'ro', isa => 'Str', default => '-c bbcry --top 25 --minv 0.1 -s log');
has 'hclust_heatmap_exec'         => ( is => 'ro', isa => 'Str', default => 'metaphlan_hclust_heatmap.py' );
has 'merge_metaphlan_tables_exec' => ( is => 'ro', isa => 'Str', default => 'merge_metaphlan_tables.py' );
has 'names_file'                  => ( is => 'ro', isa => 'Maybe[Str]' );
has 'names_list'                  => ( is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'outfile'                     => ( is => 'ro', isa => 'Str', required => 1);


sub BUILD {
    my ($self) = @_;

    unless ( (defined($self->names_list) and scalar (@{$self->names_list})) or defined($self->names_file) ) {
        Bio::Metagenomics::Exceptions::MetaphlanBuild->throw(error => 'Must provide names_file and/or names_list');
    }
    $self->_load_names_from_file();
}


sub _load_names_from_file {
    my ($self) = @_;
    defined($self->names_file) or return;
    defined($self->names_list) or $self->names_list([]);
    open F, $self->names_file or die $!;
    while (<F>) {
        chomp;
        push @{$self->names_list}, $_;
    }
    close F or die $!;
}


sub make_taxon_heatmap {
    my ($self) = @_;
    my $tmpdir = tempdir(CLEANUP => 1, DIR => getcwd());
    my @new_files;
    foreach (@{$self->names_list}) {
        my $new_file = "$tmpdir/$_.metaphlan";
        my $convert = Bio::Metagenomics::FileConvert->new(infile=>$_, outfile=>$new_file, informat=>'kraken', outformat=>'metaphlan');
        $convert->convert();
        push @new_files, $new_file;
    }

    my $merged_file = "$tmpdir/merged.txt";
    my $cmd = join(
        ' ',
        (
           $self->merge_metaphlan_tables_exec,
           join(' ',  @new_files),
           "> $merged_file"
        )
    );
    system($cmd) and Bio::Metagenomics::Exceptions::SystemCallError->throw(error => "$cmd");

    $cmd = join(
        ' ',
        (
            $self->hclust_heatmap_exec,
            $self->hclust_heatmap_options,
            "--in $merged_file",
            "--out " . $self->outfile
        )
    );
    system($cmd) and Bio::Metagenomics::Exceptions::SystemCallError->throw(error => "$cmd");
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
