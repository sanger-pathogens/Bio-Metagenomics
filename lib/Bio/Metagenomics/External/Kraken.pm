package Bio::Metagenomics::External::Kraken;

# ABSTRACT: Wrapper for Kraken https://ccb.jhu.edu/software/kraken/

=head1 SYNOPSIS

Wrapper for Kraken https://ccb.jhu.edu/software/kraken/

=cut

use Moose;
use Bio::Metagenomics::Exceptions;

has 'clean'              => ( is => 'ro', isa => 'Bool', default => 1 );
has 'database'           => ( is => 'ro', isa => 'Str', required => 1 );
has 'kraken_exec'        => ( is => 'ro', isa => 'Str', default => 'kraken' );
has 'kraken_build_exec'  => ( is => 'ro', isa => 'Str', default => 'kraken-build' );
has 'kraken_report_exec' => ( is => 'ro', isa => 'Str', default => 'kraken-report' );
has 'max_db_size'        => ( is => 'ro', isa => 'Int', default => 4);
has 'minimizer_len'      => ( is => 'ro', isa => 'Int', default => 13);
has 'preload'            => ( is => 'ro', isa => 'Bool', default => 0 );
has 'reads_1'            => ( is => 'ro', isa => 'Str');
has 'reads_2'            => ( is => 'ro', isa => 'Maybe[Str]');
has 'threads'            => ( is => 'ro', isa => 'Int', default => 1 );


sub _download_taxonomy_command {
    my ($self) = @_;
    return join(
        ' ',
        (
            $self->kraken_build_exec,
            '--download-taxonomy',
            '--db', $self->database,
        )
    );
}


sub _download_domain_command {
    my ($self, $domain) = @_;
    my %allowed_domains = map {$_ => 1} ('bacteria', 'viruses', 'human');
    exists $allowed_domains{$domain} or Bio::Metagenomics::Exceptions::KrakenDomainNotFound->throw(error => "Domain not allowed: $domain");

    return join(
        ' ',
        (
            $self->kraken_build_exec,
            '--download-library', $domain,
            '--db', $self->database,
        )
    );
}


sub _add_to_library_command {
    my ($self, $filename) = @_;
    return join(
        ' ',
        (
            $self->kraken_build_exec,
            '--add-to-library', $filename,
            '--db', $self->database,
        )
    );
}


sub _build_command {
    my ($self) = @_;
    return join(
        ' ',
        (
            $self->kraken_build_exec,
            '--build',
            '--db', $self->database,
            '--threads', $self->threads,
            '--max-db-size', $self->max_db_size,
            '--minimizer-len', $self->minimizer_len,
        )
    );
}


sub _clean_command {
    my ($self) = @_;
    return join(
        ' ',
        (
            $self->kraken_build_exec,
            '--clean',
            '--db', $self->database,
        )
    );
}


sub build {
    my ($self) = @_;
    my @commands = (
        $self->_download_taxonomy_command(),
        $self->_download_domain_command('viruses'),
        $self->_download_domain_command('bacteria'),
        $self->_download_domain_command('human'),
        $self->_build_command(),
    );

    if ($self->clean) {
        push @commands, $self->_clean_command();
    }

    foreach my $command (@commands) {
        system($command) and Bio::Metagenomics::Exceptions::SystemCallError->throw(error => "Command: $command");
    }
}


sub _run_kraken_command {
    my ($self, $outfile) = @_;
    my $cmd = join(
        ' ',
        (
            $self->kraken_exec,
            '--db', $self->database,
            '--threads', $self->threads,
            '--output', $outfile,
        )
    );

    if ($self->preload) {
        $cmd .= " --preload";
    }

    if (defined($self->reads_2)) {
        $cmd .= " --paired " . $self->reads_1 . " " . $self->reads_2;        
    }
    else {
        $cmd .= " " . $self->reads_1;
    }

    return $cmd;
}


sub _kraken_report_command {
    my ($self, $infile, $outfile) = @_;
    return join(
        ' ',
        (
            $self->kraken_report_exec,
            '--db', $self->database,
            $infile,
            '>', $outfile,
        )
    );
}


sub run_kraken {
    my ($self, $outfile) = @_;
    my $tmp_out = "$outfile.kraken_out";
    my @commands = (
        $self->_run_kraken_command($tmp_out),
        $self->_kraken_report_command($tmp_out, $outfile)
    );
    foreach my $command (@commands) {
        system($command) and Bio::Metagenomics::Exceptions::SystemCallError->throw(error => "Command: $command");
    }
    if ($self->clean) {
        unlink $tmp_out;
    }
}


no Moose;
1;
