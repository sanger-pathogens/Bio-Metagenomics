package Bio::Metagenomics::CreateLibrary;

# ABSTRACT: Take in a FASTA file and format it for Kraken

=head1 SYNPOSIS

Take in a FASTA file and format it for Kraken

=cut

use Moose;
use Bio::SeqIO;
use Bio::Metagenomics::Exceptions;

has 'taxon'           => ( is => 'rw', isa => 'Int', required => 1 );
has 'input_filename'  => ( is => 'rw', isa => 'Str', required => 1 );
has 'output_filename' => ( is => 'rw', isa => 'Str', required => 1 );

sub convert {
    my ($self) = @_;
    my $in_seq_obj = Bio::SeqIO->new( -file => $self->input_filename, '-format' => 'Fasta' )
      or Bio::Metagenomics::Exceptions::FileOpen->thrown( error => "Error with input FASTA file " . $self->input_filename );
    my $out_seq_obj = Bio::SeqIO->new( -file => "+>" . $self->output_filename, '-format' => 'Fasta' )
      or Bio::Metagenomics::Exceptions::FileOpen->thrown( error => "Error with output FASTA file " . $self->output_filename );

    my $seq_counter = 1;
    while ( my $seq = $in_seq_obj->next_seq() ) {
        my $newseq = Bio::Seq->new( -seq => $seq->seq, -display_id => $self->_reformat_id($seq_counter), -desc => $seq->id );
        $out_seq_obj->write_seq($newseq);
        $seq_counter++;
    }
    return 1;
}

sub _reformat_id {
    my ( $self, $seq_counter ) = @_;
    return 'sequence_'.$seq_counter.'|kraken:taxid|' . $self->taxon ;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
