#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
# changeHostname.pl
# This script is used to change the hostname/computer name of a windows
# machine. The syntax to run this script is:
# perl changeHostname.pl -n <newComputerName>
#
# This script edits few registry keys with the new computer name specified
# and restarts services "DNS CLIENT", "SERVER", "MRXSMB" and "WORKSTATION"
# that would avoid the necessity to reboot the windows machine and
# successfully mount network shares over SMB.
#

use strict;
use warnings;
use Getopt::Long;

BEGIN {
   eval "use Win32::TieRegistry";  # use Win32::TieRegistry only on windows
}
if ($@) {
   print "Failed to load Win32::TieRegistry\n";
   exit -1;
}

my $Registry = $Win32::TieRegistry::Registry;   # update $Registry value to the
                                                # global value exported by
                                                # Win32::TieRegistry
my $compName;

GetOptions("hostname|n=s" => \$compName);
if (not defined $compName) {
   print "New computer name not specified\n";
   exit -1;
}

# remove any existing mount points on M: and G:
system("net use M: /delete");
system("net use G: /delete");
my $controlSetKey = $Registry->{"LMachine\\SYSTEM\\CurrentControlSet\\"};
my $winNTKey = $Registry->{"LMachine\\SOFTWARE\\Microsoft\\Windows NT\\"};
my $mediaKey = $Registry->{"HKEY_USERS\\.Default\\Software\\Microsoft\\Windows Media"};
my $restart;
my @services = ();

#
# "DNS CLIENT", "SERVER" and "WORKSTATION" services have to be restarted in the
# same order on both old and modern windows.
#
push(@services, 'dns client');
push(@services, 'server');

#
# Modern windows introduced two new SMB related services MRXSMB10 and MRXSMB20.
# MRXSMB is wrapper service over these two services. These services need to be
# restarted in order to successfully mount SMB shares.
#
if (defined $controlSetKey->{"Services\\mrxsmb10"}) {
   push(@services, 'mrxsmb');
   push(@services, 'workstation');
} else {
   push(@services, 'workstation');
}
push(@services, 'dhcp client');

@services = (); # disabling any service restart until this script is
                # tested on Win7
# First stop all the services
foreach my $service (@services) {
   print "stopping service:$service\n";
   if(ChangeServiceState($service, 'stop')) {
      $restart = 1;
   }
}

# Edit the registry with the new computer name
$controlSetKey->{"Control\\Computername\\Computername\\Computername"} =
                 [$compName, "REG_SZ"];
$controlSetKey->{"Control\\Computername\\ActiveComputername\\Computername"} =
                 [$compName, "REG_SZ"];
$controlSetKey->{"Services\\Tcpip\\Parameters\\Hostname"} =
                 [$compName, "REG_SZ"];
$controlSetKey->{"Services\\Tcpip\\Parameters\\NV Hostname"} =
                 [$compName, "REG_SZ"];

$winNTKey->{"CurrentVersion\\Winlogon\\AltDefaultDomainName"} =
            [$compName, "REG_SZ"];
$winNTKey->{"CurrentVersion\\Winlogon\\DefaultDomainName"} =
            [$compName, "REG_SZ"];
$mediaKey->{"WMSDK\\General\\Computername"} =
            [$compName, "REG_SZ"];


# Running the command 'hostname' should now show the new computer name
my $newName = `hostname`;

if ($newName !~ /$compName/i) {
      print "hostname not changed\n";
      exit 2;
}
exit 2; # send exit code 2 to restart the guest
        # remove this after testing on Win7-64

# Restart the services that were stopped in the first step
foreach my $service (@services) {
   print "starting service:$service\n";
   if(ChangeServiceState($service, 'start')) {
      $restart = 1;
   }
}

# Verify whether mounting a network share over SMB work correctly
#
my $command = "net use g: \\\\scm-trees.eng.vmware.com\\trees !123vdtest " .
              "/user:vmwarem\\vdtest";

print "Running command:$command\n";

if (system($command)) {
    print "Mount Error :$?\n";
    exit 2;
}

system("net use g: /delete");
system("ipconfig /release");
system("ipconfig /renew");
print "Hostname changed to $newName\n";
exit 0;

# End of MAIN routine

########################################################################
#
# ChangeServiceState --
#      Routine to change the status (start/stop) the given the service.
#
# Input:
#      service : name of the service
#      action  : 'start' or 'stop'
#
# Results:
#      0 - if the given service will be started or stopped successfully
#      1 - in case of any error
#
# Side effects:
#      Stopping any service would affect all its dependent applications.
#
########################################################################

sub ChangeServiceState {
   my $service = shift;
   my $action  = shift;

   my $command = 'net ' . $action . ' "'. $service . '" ' . '/Y';
   if (system($command)) {
      print "Failed to $action $service:$?\n";
      return 1;
   }
   return 0;
}
