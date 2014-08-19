package Bio::Metagenomics::Exceptions;

# ABSTRACT: Exceptions for input data

=head1 SYNOPSIS

Exceptions for input data

=cut


use Exception::Class (
    Bio::Metagenomics::Exceptions::FileOpen => { description => 'Error opening file' },
    Bio::Metagenomics::Exceptions::FileConvertTypes => { description => 'Cannot convert between given filetypes' },
    Bio::Metagenomics::Exceptions::FileConvertReadKraken => { description => 'Error reading Kraken report file' },
    Bio::Metagenomics::Exceptions::KrakenDomainNotFound => { description => 'Domain not found. Must be one of bacteria, viruses, human' },
    Bio::Metagenomics::Exceptions::KrakenReportTaxonUnknown => { description => 'Taxon letter code not recognised' },
    Bio::Metagenomics::Exceptions::KrakenReportBuild => { description => 'Invalid attributes when building KrakenReport object' },
    Bio::Metagenomics::Exceptions::KrakenSummaryBuild => { description => 'Invalid attributes when building KrakenSummary object' },
    Bio::Metagenomics::Exceptions::SystemCallError => { description => 'Error running system call.' },
    Bio::Metagenomics::Exceptions::GenbankBuild => { description => 'Invalid attributes when building Genbank object' },
    Bio::Metagenomics::Exceptions::GenbankUnknownFiletype => { description => 'Unknown type of file. Must be FASTA or GENBANK' },
    Bio::Metagenomics::Exceptions::GenbankDownload => { description => 'Unable to download file from Genbank' },
    Bio::Metagenomics::Exceptions::MetaphlanBuild => { description => 'Invalid attributes when building Metaphlan object' },
    Bio::Metagenomics::Exceptions::TaxonRank => { description => 'Taxon rank not allowed' },
);


1;

