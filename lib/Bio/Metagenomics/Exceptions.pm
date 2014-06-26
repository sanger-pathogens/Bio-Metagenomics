package Bio::Metagenomics::Exceptions;

# ABSTRACT: Exceptions for input data

=head1 SYNOPSIS

Exceptions for input data

=cut


use Exception::Class (
    Bio::Metagenomics::Exceptions::KrakenDomainNotFound => { description => 'Domain not found. Must be one of bacteria, viruses, human' },
    Bio::Metagenomics::Exceptions::SystemCallError => { description => 'Error running system call.' },
    Bio::Metagenomics::Exceptions::GenbankBuild => { description => 'Invalid attributes when building Genbank object' },
    Bio::Metagenomics::Exceptions::GenbankUnknownFiletype => { description => 'Unknown type of file. Must be FASTA or GENBANK' },
    Bio::Metagenomics::Exceptions::GenbankDownload => { description => 'Unable to download file from Genbank' },
    Bio::Metagenomics::Exceptions::TaxonRank => { description => 'Taxon rank not allowed' },
    Bio::Metagenomics::Exceptions::TaxonRankTooHigh => { description => 'Taxon rank too high to be assigned' },
);


1;

