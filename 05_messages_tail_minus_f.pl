#!/usr/bin/perl
use warnings;
use strict;
use POE qw/Wheel::FollowTail/;

my $sessions = {};

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
      got_line => sub {
         print "ONREAD:".$_[ARG0]."\n";
         if ($_[ARG0] =~ m,reset(\d+),) {
            my $id = $1;
            if (exists($sessions->{"loop".$id})) {
               print "resetting loop ".$id."\n";
               $_[KERNEL]->post($sessions->{"loop".$id} => "reset");
            } else {
               print "nonexisting loop ".$id.": cannot reset!\n";
            }
         }
      },
      got_error => sub { warn "$_[ARG0]\n" }, 
      got_log_rollover => sub { print "RESETTED\n"; },
   },
   args => ["/root/test.log"],
);

my $loop = 0;

for ( 1 .. 2 ) {
   POE::Session->create(
      inline_states => {
         _start => sub {
            $sessions->{"loop".$loop++} = $_[SESSION]->ID;
            print "Session ".$_[SESSION]->ID." has started.\n";
            $_[HEAP]->{count} = 0;
            $_[KERNEL]->yield("count");
         },
         _stop => sub {
            foreach my $curloop (keys %$sessions) {
               delete $sessions->{$curloop}
                  if ($sessions->{$curloop} eq $_[SESSION]->ID);
            }
            print "Session ", $_[SESSION]->ID, " has stopped.\n";
         },
         count => sub {
            my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
            my $session_id = $_[SESSION]->ID;
            print "Session $session_id has counted to ".++$heap->{count}.".\n";
            $kernel->delay("count" => 1) if $heap->{count} < 30;
         },
         reset => sub {
            my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
            $heap->{count} = 0;
         },
      }
   );
}

print "Starting POE::Kernel.\n";
POE::Kernel->run();
print "POE::Kernel's run() method returned.\n";
exit;
