package Bio::Metagenomics::Genbank;

# ABSTRACT: Downloads genbank records

=head1 SYNPOSIS

Download genbank records using GI or Genbank IDs

=cut

use Moose;
use LWP::Simple;
use Bio::Metagenomics::Exceptions;
use Bio::Metagenomics::FileConvert;
use File::Spec;
use File::Path;

use constant {
    FASTA => 0,
    GENBANK => 1,
    UNKNOWN => 2,
};


has 'cat_fastas' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'cat_Ns'     => ( is => 'ro', isa => 'Int', default => 20 );
has 'delay'      => ( is => 'ro', isa => 'Int', default => 3 );
has 'downloaded' => ( is => 'rw', isa => 'Maybe[Str]' );
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
    $self->downloaded(File::Spec->rel2abs($self->downloaded)) if defined $self->downloaded;
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


sub _fasta_is_ok {
    my ($slef, $filename) = @_;
    open F, $filename or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "Error opening file $filename");

    while (my $line = <F>) {
        next if ($line =~ /^>/);
        chomp $line;
        if ($line =~ /[^acgtnryswkmbdhv]/i) {
            close F or die $!; 
            return 0;
        }
    }

    close F or die $!; 
    return 1;
}


sub _get_with_getstore {
    my ($self, $outfile, $filetype, $id) = @_;
    my $download_url = $self->_download_record_url($filetype, $id);
    foreach my $i (1..$self->max_tries) {
        print "\tgetstore('" . $download_url . "', '$outfile');\n";
        getstore($download_url, $outfile);
        if (-e $outfile and $self->_filetype($outfile) == $filetype) {
            # There is an empty line at the end of each FASTA record
            # in the file. Remove all empty lines.
            system("sed -i '/^\$/d' $outfile") and die $!;
            # Sometimes 404 error messages get put into the output file.
            # So for FASTA files check that it looks like a fasta file throughout
            return 1 if ( $filetype != FASTA or ($filetype == FASTA and $self->_fasta_is_ok($outfile)) );
        }

        unlink $outfile if -e $outfile;
        sleep($self->delay);
    }
    print "ID $id\tWARNING: Could not download $id from '$download_url'. Skipping\n";
    return 0;
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
        my $download_success = $self->_get_with_getstore($tmpfile, FASTA, $ids);
        if $download_success {
            my $cmd = "cat $tmpfile >> $outfile";
            system($cmd) and die "Error running:\n$cmd\n";
            unlink $tmpfile;
        }
    }
}


sub _fasta_to_number_of_sequences {
    my ($self, $infile) = @_;
    open F, $infile or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "Error opening file " . $infile);
    my $sequences = 0;
    while (<F>) {
        $sequences++ if /^>/;
    }
    close F;
    return $sequences;
}


sub _download_from_genbank {
    my ($self, $outfile, $filetype, $id) = @_;
    my $original_id = $id;
    my $expected_sequences;
    my $download_success;

    # If it's an assembly ID, then we need to get the sequence record ID
    # of each sequence of the assembly. This is in the assembly report file
    if ($id =~ /^GCA_/) {
        print "ID $id\t... looks like an assembly ID. Getting assembly report file\n";
        my $assembly_report = "$outfile.tmp.assembly_report";
        $self->_download_assembly_report($id, $assembly_report);
        my $all_ids = $self->_assembly_report_to_genbank_ids($assembly_report, $id);
        unlink $assembly_report;
        if (scalar @{$all_ids} == 0) {
            print "ID $id\tWARNING: no sequences found in assembly report file. Skipping\n";
            return 0;
        }
        # The 'id='...' in efetch can be a comma-separated list of IDs, so
        # use this to download the sequences in chunks. Limit each chunk to
        # 100 sequences, otherwise download may fail.
        my $ids = $self->_ids_to_chunks($all_ids, 100); 
        $self->_download_chunks_from_genbank($ids, $outfile);
        $expected_sequences = scalar @{$all_ids};
    }
    else {
        $self->_get_with_getstore($outfile, FASTA, $id);
        $expected_sequences = 1;
    }

    my $got_sequences = $self->_fasta_to_number_of_sequences($outfile);
    if ($got_sequences == 0) {
        print "ID $id\tWARNING: no sequences downloaded!\n";
        unlink $outfile if -e $outfile;
        return 0;
    }
    elsif ($expected_sequences != $got_sequences) {
        print "ID $id\tWARNING: wrong number of sequences in final FASTA file. Expected:$expected_sequences. Got:$got_sequences\n";
    }
    return 1;
}


sub _download_assembly_report {
    my ($self, $id, $filename) = @_;
    my $cmd = "wget -q -O $filename ftp://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/All/$id.assembly.txt";
    print "ID $id\t$cmd\n";
    system($cmd) and Bio::Metagenomics::Exceptions::GenbankDownload->throw(error => "Error getting assembly report file:\n$cmd\n");
}


sub _assembly_report_to_genbank_ids {
    my ($self, $report_file, $id) = @_;
    open F, $report_file or Bio::Metagenomics::Exceptions::FileOpen->throw(error => "Error opening file " . $report_file);
    my @ids;
    while (my $line = <F>) {
        next if $line =~ /^#/;
        my @fields = split(/\t/, $line);
        if ($fields[4] eq "na") {
            print "ID $id\t\tWARNING: skipping ID 'na' found in report file\n";
        }
        else {
            push(@ids, $fields[4]);
        }
    }
    close F or die $!;
    return \@ids;
}


sub download {
    my ($self) = @_;
    my @filenames;
    mkdir($self->output_dir);
    -e $self->output_dir or die $!;

    for my $id (@{$self->ids_list}) {
        my $filename = File::Spec->catfile($self->output_dir, "$id.fasta");
        my $filename_gz = "$filename.gz";
        my $already_downloaded = defined $self->downloaded ? File::Spec->catfile($self->downloaded, "$id.fasta.gz") : '';

        if (-e $filename_gz) {
            print "ID $id\tSkip download because file found: $filename_gz\n";
            push(@filenames, $filename_gz);
        }
        elsif (defined $self->downloaded and -e $already_downloaded) {
            print "ID $id\tSkip download because file found: $already_downloaded\n";
            push(@filenames, $already_downloaded);
        }
        else {
            print "ID $id\tDownloading to file $filename\n";
            if ($self->_download_from_genbank($filename, FASTA, $id)) {
                if ($self->cat_fastas) {
                    my $obj =  Bio::Metagenomics::FileConvert->new(
                        infile     => $filename,
                        informat   => 'fasta',
                        outfile    => $filename_gz,
                        outformat  => 'catted_fasta',
                        spacing_Ns => $self->cat_Ns,
                    );
                    $obj->convert();
                    unlink $filename;
                }
                else {
                    system("gzip -9 $filename") and die "Error running: gzip -9 $filename";
                }
                push(@filenames, $filename_gz);
            }
        }
    }
    return \@filenames;
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

