package POE::Component::RemoteTail::Engine::Default;

use strict;
use warnings;
use POE::Component::IKC::ClientLite;

sub new {
    my $class = shift;
    my %args  = @_;

    return bless {%args}, $class;
}

sub process_entry {
    my $class = shift;
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
    my $tail     = "tail -f $path";

    my $fh;
    my $pre = 0;
    my $logs;
    my $cmd = "ssh -A $host $tail";

    local $SIG{'INT'} = $SIG{'HUP'} = $SIG{'QUIT'} = $SIG{'TERM'} = sub {
        my $killcmd = 'pkill -f "' . $cmd . '"';
        system($killcmd);
        close($fh);
    };

    open( $fh, "$cmd |" );
    while (<$fh>) {
        my $now = time;
        unless ( $now == $pre ) {
            my $ret =
              $remote->post_respond( 'tailer/_ikc_logger', [ $host, $logs ] );
            unless ($ret) {
                close($fh);
                exit;
            }
            $pre  = $now;
            $logs = "";
        }
        else {
            $logs .= $_;
        }
    }
    close($fh);
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail::Engine::Default - Default engine

=head1 SYNOPSIS

  use POE::Component::RemoteTail::Engine::Default;
  # this module is called on backend as default engine  


=head1 DESCRIPTION

POE::Component::RemoteTail::Engine::Default is

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
