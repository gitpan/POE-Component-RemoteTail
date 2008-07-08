use ABC;

use strict;
use warnings;
use Net::SSH::Perl;

sub new {
    my $class = shift;
    my %args  = @_;

    return bless {%args}, $class;
}

sub process_entry {
    my $self  = shift;
    my $arg   = shift;

    my $host     = $arg->{host};
    my $path     = $arg->{path};
    my $user     = $arg->{user};
    my $password = $arg->{password};
    my $cmd      = "tail -f $path";

    my $ssh = Net::SSH::Perl->new( $host, protocol => "2,1" );
    $ssh->login($user);
    $ssh->register_handler(
        "stdout",
        sub {
            my ( $channel, $buffer ) = @_;
            my $log = $buffer->bytes;
            print $log;
            unless ($log) { exit; }
        }
    );
    my ( $stdout, $stderr, $exit ) = $ssh->cmd($cmd);
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail::Engine::NetSSHPerl - Pure Perl SSH engine

=head1 SYNOPSIS

  use POE::Component::RemoteTail::Engine::NetSSHPerl;
  # this module is called on backend as default engine  


=head1 DESCRIPTION

POE::Component::RemoteTail::Engine::NetSSHPerl is

=head1 METHOD

=head2 new()

=head2 process_entry()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
