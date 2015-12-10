#!/usr/bin/perl
use strict;

sub readCpuStats
{
   my $used = "Used ";
   my $elap = "Elap ";
   my $numCores;

   my $res = `vsish -e get /hardware/cpu/cpuInfo`;
   chomp($res);

   if ($res =~ m/Number of CPUs.*:(\d+)/) {
      $numCores = $1;
   } elsif ($res =~ m/Number of cores:(\d+)/) {
      $numCores = $1;
   }

   for(my $i=0; $i < $numCores; $i++) {
      $res = `vsish -e get /sched/pcpus/$i/stats`;
      if($res =~ m/used-time:(\d+).*elapsed-time:(\d+)/s) {
         $used .= "$1 ";
         $elap .= "$2 ";
      } else {
         print "Host Error: Cannot get vsish node /sched/pcpus/$i/stats\n";
         return "FAILURE";
      }
   }
   return ($used,$elap);
}

sub main {
   my ($used, $elap) = readCpuStats();
   print $used."\n";
   print $elap."\n";
}

main;
