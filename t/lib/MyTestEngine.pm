package MyTestEngine;

use strict;
use warnings;
use POE::Component::IKC::ClientLite;


sub new {
    my $class = shift;
    my %args  = @_;

    return bless {%args}, $class;
}

sub process_entry {
    my $self = shift;
    my $arg  = shift;

    my $host     = $arg->{host};
    my $path     = $arg->{path};
    my $user     = $arg->{user};
    my $password = $arg->{password};

    my $client_name = "Client$$";
    my $remote      = create_ikc_client(
        port    => $arg->{port},
        name    => $client_name,
        timeout => 5
    );
    die $POE::Component::IKC::ClientLite::error unless $remote;

    for(1..1000){
        my $log = "logloglog_" . $_;
        my $ret = $remote->post_respond( 'tailer/_ikc_logger', [ $host, $log ] );
    }
}

1;
