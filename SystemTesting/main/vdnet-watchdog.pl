#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################

########################################################################
#
# vdnet-watchdog.pl --
#     This perl script is the tool to clean up VDNet related processes
#     after test is finished or VDNet is aborted.
#
########################################################################

# Load all the modules necessary
use strict;
use warnings;
use Getopt::Long;

use constant INTERVAL=> 10;
use constant PREFIX=> "vdnet-watchdog:";
use constant LOGFILE=> "watchdog-log";

my ($exists, $ID_FILEP, $LOG_FILEP);
my ($help, $vdnet_pid, $processListFile, $logFileName);

# Ignore SIGINT sent to this process. watchdog should
# only exit on its own
$SIG{'INT'} = "IGNORE";

my $usage =
"./vdnet-watchdog.pl -i <inputfile> -p <process id>
     where options are ...
         -h|-help                 Displays this usage message
         -i|-inputfile            Inputfile for process list which need
                                  to kill if VDNet.pl not running.
         -p|-process_id           Process ID for VDNet.pl

Examples:
   ./vdnet-watchdog.pl -i idfile -p 12345            Kill processes that
                                  listed in idfile
";

####### help and usage ######
die "$!$usage\n" unless GetOptions(
   'h|help' => \$help,
   'p|process_id=i' => \$vdnet_pid,
   'i|inputfile=s'   => \$processListFile,
);

if ($help) {print "$usage"; exit(1); }
####### help and usage ######

# check parameters  #
if (!(-e $processListFile)) {
   print "File $processListFile does NOT exist.\n";
   exit(1);
}

# Get log file name
my $lastIndex = rindex($processListFile, '/');
if ($lastIndex < 0) {
    $logFileName = LOGFILE;
} else {
    $logFileName = substr($processListFile, 0, $lastIndex+1) . LOGFILE;
}

# if vdnet process exists, wait
# if vdnet proces not eixsts, read file and kill process whose ID is saved in
# each line
while (1) {
   $exists = kill 0, $vdnet_pid;
   if ($exists) {
      sleep(INTERVAL);
   } else {
      if (!open ($LOG_FILEP, ">> " . $logFileName)) {
         die "Could not open $logFileName: $!";
      }
      if (!open ($ID_FILEP, $processListFile)) {
         close $LOG_FILEP;
         die "Could not open $processListFile: $!";
      }
      print $LOG_FILEP PREFIX . "Begin to clean up as VDNet process ";
      print $LOG_FILEP "$vdnet_pid is aborted or finished.\n";
      while( my $line = <$ID_FILEP>)  {
         # check pid validation
         chomp($line);
         if ($line !~ m/^\d+$/) {
            print $LOG_FILEP PREFIX . "Invalid pid $line\n";
            next;
         }
         $exists = kill (0, $line);
         if ($exists) {
            print $LOG_FILEP PREFIX . $line . " will be killed\n";
            # log the process information which will be killed
            print $LOG_FILEP PREFIX . $line . " process information:\n";
            my $oneProcess = `ps -f -p $line`;
            print $LOG_FILEP $oneProcess ;
            print $LOG_FILEP &KillProcessWithChild($line);
         } else {
            print $LOG_FILEP PREFIX . $line . " is not running\n";
         }
      }

     close $ID_FILEP;
     close $LOG_FILEP;
     # send kill to vdNet anyway in case it becomes zombie
     kill ('TERM', $vdnet_pid);
     last;
   }
}


########################################################################
#
#  KillProcessWithChild--
#     Method to kill process and its child processes.
#
# Input:
#     pid : Parent process ID
#
# Results:
#     logString: A string to show kill status
#
# Side effects:
#
########################################################################

sub KillProcessWithChild
{
   my $pid = shift;
   my $logString = "";

   if (not defined $pid) {
      return "Kill proces without PID defined\n";
   }

   my $pString = `ps ax -f | grep -v grep | grep $pid`;
   my @pList = split(/\n/, $pString);

   foreach my $childProcess (@pList) {
      my @procInfo = split(/\s+/, $childProcess);
      if ($procInfo[1] =~ /\d+/ and $procInfo[2] =~  /\d+/ and
          $procInfo[2] == $pid) {
         $logString = $logString . PREFIX . "$procInfo[1] is child of $pid\n";
         $logString = $logString . PREFIX . "$procInfo[1] process info:\n";
         $logString = $logString . "$childProcess\n";
         #kill child process
         kill('TERM',$procInfo[1]);
      }
   }
   kill('TERM',$pid);
   $logString = $logString . PREFIX . "Kill process $pid has been done.\n\n";
   return $logString;
}

