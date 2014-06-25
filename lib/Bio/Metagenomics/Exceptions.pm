package Bio::Metagenomics::Exceptions;

# ABSTRACT: Exceptions for input data

=head1 SYNOPSIS

Exceptions for input data

=cut


use Exception::Class (
    Bio::Metagenomics::Exceptions::KrakenDomainNotFound => { description => 'Domain not found. Must be one of bacteria, viruses, human' },
    Bio::Metagenomics::Exceptions::SystemCallError => { description => 'Error running system call.' },
);

1;

