package POE::Component::RemoteTail;

use strict;
use warnings;
use POE;
use POE::Component::RemoteTail::Job;
use POE::Component::IKC::Server;
use POE::Wheel::Run;
use POE::Filter::Reference;
use Class::Inspector;
use Data::Dumper;
use constant DEBUG => 0;
use UNIVERSAL::require;

our $VERSION = '0.00001_00';

*debug = DEBUG
  ? sub {
    my $mess = shift;
    print STDERR $mess, "\n";
  }
  : sub { };

sub spawn {
    my $class = shift;
    my $self  = $class->new(@_);

    $self->{alias} ||= "tailer";
    $self->{port}  ||= 9999;
    $self->{name}  ||= "RemoteTail";

    POE::Component::IKC::Server->spawn(
        port => $self->{port},
        name => $self->{name},
    );

    POE::Session->create(
        object_states => [ $self => Class::Inspector->methods($class) ], );

}

sub new {
    my $class = shift;
    my %args  = @_;

    return bless {%args}, $class;
}

sub job {
    my $self = shift;
    my %args = @_;

    my $job = POE::Component::RemoteTail::Job->new(%args);
    return $job;
}

sub execute {
    my ( $self, $kernel, $session, $heap, $arg ) =
      @_[ OBJECT, KERNEL, SESSION, HEAP, ARG0 ];

    $heap->{postback} = $arg->{postback};
    my $job = $arg->{job};
    $job->{port} = $self->{port};

    $kernel->post( $session, "_spawn_child" => $job );
}

sub stop_tail {
    my ( $self, $kernel, $session, $heap, $job ) =
      @_[ OBJECT, KERNEL, SESSION, HEAP, ARG0 ];

    debug("STOP:$job->{id}");
    my $task = $heap->{task}->{ $job->{id} };
    $task->kill;
    delete $heap->{task}->{ $job->{id} };
    undef $job;
}

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $kernel->alias_set( $self->{alias} );
    $kernel->call( IKC => publish => $self->{alias}, ["_ikc_logger"] );
}

sub _ikc_logger {
    my ( $self, $kernel, $heap, $request ) = @_[ OBJECT, KERNEL, HEAP, ARG0 ];

    my ( $data, $rsvp ) = @$request;
    my ( $host, $log )  = @$data;

    $heap->{postback}->( $host, $log );
    $kernel->call( IKC => post => $rsvp, 1 );
}

sub _spawn_child {
    my ( $self, $kernel, $session, $heap, $job, $sender ) =
      @_[ OBJECT, KERNEL, SESSION, HEAP, ARG0, SENDER ];

    # prepare ...
    my $class = $job->{process_class};
    $class->require or die(@!);
    $class->new();

    my %program = ( Program => sub { $class->process_entry($job) }, );
    $SIG{CHLD} = "IGNORE";

    # run wheel
    my $task = POE::Wheel::Run->new(
        %program,
        StdioFilter => POE::Filter::Line->new(),
        StdoutEvent => "_got_child_stdout",
        StderrEvent => "_got_child_stderr",
        CloseEvent  => "_got_child_close",
    );

    $heap->{task}->{ $task->ID } = $task;
    $job->{id} = $task->ID;
}

sub _got_child_stdout {
    my $stdout = $_[ARG0];
    debug("STDOUT:$stdout");
}

sub _got_child_stderr {
    my $stderr = $_[ARG0];
    debug("STDERR:$stderr");
}

sub _got_child_close {
    my ( $heap, $task_id ) = @_[ HEAP, ARG0 ];
    delete $heap->{task}->{$task_id};
    debug("CLOSE:$task_id");
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail -

=head1 SYNOPSIS

  use POE::Component::RemoteTail;
  
  my ( $host, $path, $user, $password ) = @target_host_info;
  my $alias = 'Remote_Tail';
  
  # spawn component
  POE::Component::RemoteTail->spawn( alias => $alias );
  
  # prepare the postback subroutine at main POE session
  POE::Session->create(
      inline_states => {
          _start => sub {
              my ( $kernel, $session ) = @_[ KERNEL, SESSION ];
  
              # create job
              my $job = POE::Component::RemoteTail->job(
                  host          => $host,
                  path          => $path,
                  user          => $user,
                  password      => $password,
                  process_class => "POE::Component::RemoteTail::Engine::Default",
              );
  
              # post to execute
              $kernel->post( $alias,
                  "execute" => { postback => "mypostback", job => $job } );
          },
  
          # return to here
          mypostback => sub {
              my ( $kernel, $session, $data ) = @_[ KERNEL, SESSION, ARG1 ];
              my $host = $data->[0];
              my $log  = $data->[1];
              ... do something ...
          },
      },
  );
  
  POE::Kernel->run();


=head1 DESCRIPTION

POE::Component::RemoteTail is

=head1 METHOD

=head2 spawn()

=head2 job()

=head2 execute()

=head2 stop_tail()

=head2 debug()

=head2 new()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
