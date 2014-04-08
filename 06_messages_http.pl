#!/usr/bin/perl
use warnings;
use strict;
use POE qw/Component::Server::HTTP/;

my $sessions = {};

POE::Component::Server::HTTP->new(
   Port           => 8080,
   Address        => "0.0.0.0",
   ContentHandler => {
      '/reset0' => \&sendReset,
      '/reset1' => \&sendReset,
      #'/'      => \&sendReset,
   },
);

sub sendReset {
   my ($request, $response) = @_;
   if ($request->uri =~ m,reset(\d+),) {
      my $id = $1;
      if (exists($sessions->{"loop".$id})) {
         print "resetting loop ".$id."\n";
         $poe_kernel->post($sessions->{"loop".$id} => "reset");
      } else {
         print "nonexisting loop ".$id.": cannot reset!\n";
      }
   }
}

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
