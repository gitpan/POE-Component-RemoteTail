use strict;
use warnings;
use POE;
use POE::Component::RemoteTail;
use lib qw( t/lib );
use Test::More tests => 1;


my ($i,$j) = (0,0);

my $alias = "tailer";
my @hosts    = qw( test01 );
my $path     = '/home/httpd/test01/anemone/logs/access_log.20080630';
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
                      "MyTestEngine",
                );
                $kernel->post(
                    $alias,
                    "execute" => {
                        postback => $postback,
                        job      => $job
                    }
                );
                $kernel->delay_add( "stop_job", 5, $job );
            }
        },
        mypostback => sub {
            my ( $kernel, $session, $data ) = @_[ KERNEL, SESSION, ARG1 ];
            my $host = $data->[0];
            my $log  = $data->[1];
            for ( split( /\n/, $log ) ) {
                check($_);
                print $host, "\t", $_, "\n";
            }
        },
        stop_job => sub {
            my ( $kernel, $job ) = @_[ KERNEL, ARG0 ];
            $kernel->post( $alias, "stop_tail" => $job );
            is($j,1000,"loop OK");
            $kernel->stop();
        },
    },
);

POE::Kernel->run();

sub check{
    my $log = shift; 
    $log =~ s/logloglog_//;
    
    if($log == ++$i){
        $j++;
    }
}

