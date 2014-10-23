package Bio::Metagenomics::Genbank;

# ABSTRACT: Downloads genbank records

=head1 SYNPOSIS

Download genbank records using GI or Genbank IDs

=cut

print "HELLO\n";

use Moose;
use LWP::Simple;
use Bio::Metagenomics::Exceptions;
use File::Spec;
use File::Path;

use constant {
    FASTA => 0,
    GENBANK => 1,
    UNKNOWN => 2,
};


has 'delay'      => ( is => 'ro', isa => 'Int', default => 3 );
has 'ids_file'   => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ids_list'   => ( is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'max_tries'  => ( is => 'ro', isa => 'Int', default => 5 );
has 'output_dir' => ( is => 'rw', isa => 'Str', required => 1 );


sub BUILD {
    my ($self) = @_;

    unless ( (defined($self->ids_list) and scalar (@{$self->ids_list})) or defined($self->ids_file) ) {
        Bio::Metagenomics::Exceptions::GenbankBuild->throw(error => 'Must provide ids_file and/or ids_list');
    }
    $self->_load_ids_from_file();
    $self->output_dir(File::Spec->rel2abs($self->output_dir));
}


sub _load_ids_from_file {
    my ($self) = @_;
    defined($self->ids_file) or return;
    defined($self->ids_list) or $self->ids_list([]);
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


sub _get_with_getstore {
    my ($self, $outfile, $filetype, $id) = @_;
    foreach my $i (1..$self->max_tries) {
        print "    getstore(" . $self->_download_record_url($filetype, $id) . ", $outfile);\n";
        getstore($self->_download_record_url($filetype, $id), $outfile);
        if (-e $outfile and $self->_filetype($outfile) == $filetype) {
            return;
        }
        else {
            unlink $outfile if -e $outfile;
            sleep($self->delay);
        }
    }
    Bio::Metagenomics::Exceptions::GenbankDownload->throw(error => "Error downloading $id from genbank. Cannot continue");
}


sub _ids_to_chunks {
    my ($self, $ids, $chunk_size) = @_;
    my @chunks;
    for (my $i=0; $i < @{$ids}; $i += $chunk_size) {
        my $end = $i + $chunk_size >= @{$ids} ? @{$ids} - 1 :  $i + $chunk_size - 1;
        my $ids_string = join(",", @{$ids}[$i .. $end]);
        push (@chunks, $ids_string);
    }
    return \@chunks;
}


sub _download_chunks_from_genbank {
    my ($self, $chunks, $outfile) = @_;
    for my $ids (@{$chunks}) {
        my $tmpfile = "$outfile.$$.tmp";
        $self->_get_with_getstore($tmpfile, FASTA, $ids);
        my $cmd = "cat $tmpfile >> $outfile";
        system($cmd) and die "Error running:\n$cmd\n";
        unlink $tmpfile;
    }
}


sub _download_from_genbank {
    my ($self, $outfile, $filetype, $id) = @_;
    print "_download_from_genbank($outfile, $filetype, $id)\n";
    my $original_id = $id;

    # If it's an assembly ID, then we need to get the sequence record ID
    # of each sequence of the assembly. This is in the assembly report file
    if ($id =~ /^GCA_/) {
        print "    ... looks like an assembly ID. Getting assembly report file\n";
        my $assembly_report = "$outfile.tmp.assembly_report";
        $self->_download_assembly_report($id, $assembly_report);
        my $all_ids = $self->_assembly_report_to_genbank_ids($assembly_report);
        unlink $assembly_report;
        # The 'id='...' in efetch can be a comma-separated list of IDs, so
        # use this to download the sequences in chunks. Limit each chunk to
        # 100 sequences, otherwise download may fail.
        my $ids = $self->_ids_to_chunks($all_ids, 100); 
        $self->_download_chunks_from_genbank($ids, $outfile);
    }
    else {
        $self->_get_with_getstore($outfile, FASTA, $id);
    }
}


sub _download_assembly_report {
    my ($self, $id, $filename) = @_;
    my $cmd = "wget -O $filename ftp://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/All/$id.assembly.txt";
    print "    $cmd\n";
    system($cmd) and Bio::Metagenomics::Exceptions::GenbankDownload->throw(error => "Error getting assembly report file:\n$cmd\n");
}


sub _assembly_report_to_genbank_ids {
    my ($self, $report_file) = @_;
    open F, $report_file or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "Error opening file " . $report_file);
    my @ids;
    while (my $line = <F>) {
        next if $line =~ /^#/;
        my @fields = split(/\t/, $line);
        push(@ids, $fields[4]);
    }
    close F or die $!;
    return \@ids;
}


sub download {
    my ($self) = @_;
    print "start of sub download\n";
    print "output_dir is '" . $self->output_dir . "'\n";
    my @downloaded;
    mkdir($self->output_dir) or die $!;
    for my $id (@{$self->ids_list}) {
        print "download(): main for loop. id='$id'\n";
        print "Making \$filename...\n";
        my $filename = File::Spec->catfile($self->output_dir, "$id.fasta");
        print "Downloading $id to file $filename ...\n";
        $self->_download_from_genbank($filename, FASTA, $id);
        push @downloaded, $filename;
    }
    return \@downloaded;
}


sub clean {
    my ($self) = @_;
    if (-e $self->output_dir and -d $self->output_dir) {
        File::Path->remove_tree($self->output_dir);
    }
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

