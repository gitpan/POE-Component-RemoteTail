use strict;
use POE;
use POE::Component::RemoteTail;

my $alias = "tailer";

my @hosts    = qw( www1 www2 www3 ); 
my $path     = '/home/httpd/vhost/hoge/logs/access_log';
my $user     = 'hoge';
my $password = 'fuga';

POE::Component::RemoteTail->spawn( alias => $alias );

POE::Session->create(
    inline_states => {
        _start => sub {
            my ( $kernel, $session ) = @_[ KERNEL, SESSION ];
            my $postback = $session->postback("mypostback");
            for my $host (@hosts) {
                my $job = POE::Component::RemoteTail->job(
                    host     => $host,
                    path     => $path,
                    user     => $user,
                    password => $password,
                    process_class =>
                      "POE::Component::RemoteTail::Engine::Default",
                );
                $kernel->post(
                    $alias,
                    "execute" => {
                        postback => $postback,
                        job      => $job
                    }
                );
                $kernel->delay_add( "stop_job", 10, $job );
            }
        },
        mypostback => sub {
            my ( $kernel, $session, $data ) = @_[ KERNEL, SESSION, ARG1 ];
            my $host = $data->[0];
            my $log  = $data->[1];
            for ( split( /\n/, $log ) ) {
                print $host, "\t", $_, "\n";
            }
        },
        stop_job => sub {
            my ( $kernel, $job ) = @_[ KERNEL, ARG0 ];
            $kernel->post( $alias, "stop_tail" => $job );
        },
    },
);

POE::Kernel->run();
