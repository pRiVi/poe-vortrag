#!/usr/bin/perl
use warnings;
use strict;
use POE;

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
            print "Session $session_id has counted to ".++$heap->{count}."\n";
            $kernel->delay("count" => 1) if $heap->{count} < 10;
         }
      }
   );
}

print "Starting POE::Kernel.\n";
POE::Kernel->run();
print "POE::Kernel's run() method returned.\n";
exit;

# $ perl 02_multiple_loops.pl
# Session 1 has started.
# Session 2 has started.
# Starting POE::Kernel.
# Session 1 has counted to 1
# Session 2 has counted to 1
# Session 1 has counted to 2
# Session 2 has counted to 2
# Session 1 has counted to 3
# Session 2 has counted to 3
# Session 1 has counted to 4
# Session 2 has counted to 4
# Session 1 has counted to 5
# Session 2 has counted to 5
# Session 1 has counted to 6
# Session 2 has counted to 6
# Session 1 has counted to 7
# Session 2 has counted to 7
# Session 1 has counted to 8
# Session 2 has counted to 8
# Session 1 has counted to 9
# Session 2 has counted to 9
# Session 1 has counted to 10
# Session 2 has counted to 10
# Session 2 has stopped.
# Session 1 has stopped.
# POE::Kernel's run() method returned.
# $
