package POE::Component::RemoteTail::Job;

use strict;
use warnings;

my $id = 0;
sub new {
    my $class = shift;
    my $ID = $$ . '_'. ++$id;
    my $self = bless {@_, id => $ID}, $class;
}

sub ID {
    my $self= shift;
    return $self->{id};
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail::Job - Job class. 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHOD

=head2 new()

=head2 ID()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

