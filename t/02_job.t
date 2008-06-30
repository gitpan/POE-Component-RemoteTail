use strict;
use warnings;
use POE::Component::RemoteTail;
use YAML;
use List::Util qw(reduce);
use Data::Dumper;
use Test::More tests => 2;

my $test_data = YAML::Load( join '', <DATA> );

my $host     = 'www1';
my $path     = '/home/httpd/vhost/www1/logs/access_log';
my $user     = 'hoge';
my $password = 'fuga';

{
    my $job = POE::Component::RemoteTail->job(
        host          => $host,
        path          => $path,
        user          => $user,
        password      => $password,
        process_class => "POE::Component::RemoteTail::Engine::Default",
    );
    delete $job->{id};
    my $obj;
    eval( $test_data->{obj} );
    is_deeply( $job, $obj, "object is deeply matched" );
}


{
    my @array;
    for(1..10){
        my $job = POE::Component::RemoteTail->job(
            host          => $host,
            path          => $path,
            user          => $user,
            password      => $password,
            process_class => "POE::Component::RemoteTail::Engine::Default",
        );
        push( @array, [split(/_/, $job->{id})]->[1] );
    }
    no warnings;
    my $flag = 0; 
    reduce {
        $flag = 1 if $a + 1 != $b; 
        $b;
    } @array;
    is($flag, 0, "job-id's incremental check OK");
}


__DATA__
---
obj: |
  $obj = bless(
      {
          'password'      => 'fuga',
          'process_class' => 'POE::Component::RemoteTail::Engine::Default',
          'user'          => 'hoge',
          'path'          => '/home/httpd/vhost/www1/logs/access_log',
          'host'          => 'www1'
      },
      'POE::Component::RemoteTail::Job'
  );
