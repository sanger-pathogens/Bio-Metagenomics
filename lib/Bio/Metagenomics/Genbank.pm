package Bio::Metagenomics::Genbank;

# ABSTRACT: Downloads genbank records

=head1 SYNPOSIS

Download genbank records using GI or Genbank IDs

=cut


use Moose;
use LWP::Simple;
use Bio::Metagenomics::Exceptions;

use constant {
    FASTA => 0,
    GENBANK => 1,
    UNKNOWN => 2,
};


has 'delay'      => ( is => 'ro', isa => 'Int', default => 3 );
has 'ids_list'   => ( is => 'ro', isa => 'ArrayRef[Str]');
has 'ids_file'   => ( is => 'ro', isa => 'Str' );
has 'max_tries'  => ( is => 'ro', isa => 'Int', default => 5 );


sub BUILD {
    my ($self) = @_;
    
    unless ( (defined($self->ids_list) and scalar (@{$self->ids_list})) or defined($self->ids_file) ) {
        Bio::Metagenomics::Exceptions::GenbankBuild->throw(error => 'Must provide ids_file and/or ids_list');
    }
    $self->_load_ids_from_file();
}


sub _load_ids_from_file {
    my ($self) = @_;
    defined($self->ids_file) or return;
    defined($self->ids_list) or $self->ids_list = [];
    open F, $self->ids_file or die $!;
    while (<F>) {
        chomp;
        push @{$self->ids_list}, $_;
    }
    close F or die $!;
}


sub _download_record_url {
    my ($self, $filetype, $id) = @_;
    my %h = (FASTA, 'fasta', GENBANK, 'gb');
    defined($h{$filetype}) or Bio::Metagenomics::Exceptions::GenbankUnknownFiletype->throw(error => "Given filetype was $filetype");
    return "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=" . $h{$filetype} . "&retmode=text&id=$id";
}


sub _filetype {
    my ($self, $filename) = @_;
    open F, $filename or die $!;
    my $line = <F>;
    close F or die $!;
    if ($line =~ /^>/) {
        return FASTA;
    }
    elsif ($line =~ /^LOCUS/) {
        return GENBANK;
    }
    else {
        return UNKNOWN;
    }
}


sub _download_from_genbank {
    my ($self, $outfile, $filetype, $id) = @_;
    foreach my $i (1..$self->max_tries) {
        getstore($self->_download_record_url($filetype, $id), $outfile);
        if ($self->_filetype($outfile) == $filetype) {
            return;
        }
        else {
            unlink $outfile;
            sleep($self->delay);
        }

    }
    Bio::Metagenomics::Exceptions::Genbank::GenbankDownload->throw(error => "Filetype=$filetype, ID=$id");
}


no Moose;
1;

