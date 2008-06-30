use POE::Component::RemoteTail::Engine::NetSSHPerl;

use strict;
use warnings;
use Net::SSH::Perl;
use POE::Component::IKC::ClientLite;

sub new {
    my $class = shift;
    my %args  = @_;

    return bless {%args}, $class;
}

sub process_entry {
    my $self  = shift;
    my $arg   = shift;

    my $client_name = "Client$$";
    my $remote      = create_ikc_client(
        port    => $arg->{port},
        name    => $client_name,
        timeout => 5
    );
    die $POE::Component::IKC::ClientLite::error unless $remote;

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
            my $ret =
              $remote->post_respond( 'tailer/ikc_logger',
                [ $host, $buffer->bytes ] );
            unless ($ret) { exit; }
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
