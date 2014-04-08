#!/usr/bin/perl
use warnings;
use strict;
use POE qw/Wheel::FollowTail/;

POE::Session->create(
   inline_states => {
      _start => sub {
         $_[HEAP]->{wheel} = POE::Wheel::FollowTail->new(
            Filename   => $_[ARG0],
            InputEvent => "got_line",
            ErrorEvent => "got_error",
            ResetEvent => "got_log_rollover",
            SeekBack   => 1024,
            PollInterval => 0.1,
         );
         $_[HEAP]->{first} = 0;
      },
      got_line => sub { print "ONREAD:".$_[ARG0]."\n"; },
      got_error => sub { print "ERROR:".$_[ARG0]."\n" }, 
      got_log_rollover => sub { print "RESETTED\n"; },
   },
   args => ["/root/test.log"],
);

for ( 1 .. 2 ) {
   POE::Session->create(
      inline_states => {
         _start => sub {
            print "Session ", $_[SESSION]->ID, " has started.\n";
            $_[HEAP]->{count} = 0;
            $_[KERNEL]->yield("count");
         },
         _stop => sub {
            print "Session ", $_[SESSION]->ID, " has stopped.\n";
         },
         count => sub {
            my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
            my $session_id = $_[SESSION]->ID;
            print "Session $session_id has counted to ".++$heap->{count}.".\n";
            $kernel->delay("count" => 1) if $heap->{count} < 30;
         }
      }
   );
}

print "Starting POE::Kernel.\n";
POE::Kernel->run();
print "POE::Kernel's run() method returned.\n";
exit;
