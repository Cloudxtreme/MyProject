#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::OldVerification::dvPortStatsVerification;

#
# This module gives object of dvPortStats verification of Unicast, Mulitcast
# and Broadcast packets. It deals with gathering initial and final stats before
# a test is executed and then taking a diff between the two stats.
#

# Design:
# Input Values:
# 1. Port Number.
# 2. Verifcation type such as InUnicast, OutUnicast, InMulticast, OutMulticast, InBroadcast or OutBroadcast.

# VM-A ----------------------> VM-B
# VM's send different types of (Unicast, Multicast and Broadcast) packets.
# Find the ESX host IP and DVS port number of the VM.
# Get the Unicast, Multicast and Broadcast packet information using the following commands:
# net-dvs -l | grep -A 34 "port 131:" | grep pktsOutUnicast | awk '{print $3}'
# net-dvs -l | grep -A 34 "port 117:" | grep pktsInUnicast | awk '{print $3}'
#
# In the above command port number should be the DVS port number to which the VM is connected.
#

# ########################  Usage  #################################
# Just provide verification => dvPortStats in Traffic Workload. E.g.
# WORKLOADS => {
#     "NetperfTraffic" => {
#            Type           => "Traffic",
#            ToolName       => "ping",
#            TestDuration   => "60",
#            Verification   => 'dvPortStats',
#            dvPortNum      => "5",
#            statstype      => "InUnicast,OutUnicast,InMulticast,OutMulticast,InBroadcast,OutBroadcast",
#            },
# }
# ##################################################################


# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::OldVerification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;

use VDNetLib::Common::Utilities;

use PLSTAF;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Host::HostOperations;

###############################################################################
#
# new -
#       This method reads the verification hash provided. Fetch required
#       details from verification hash like controlip testip, os,
#       interface on which to run the capture.
#
# Input:
#       verification hash (required) - a specificaton in form of hash which
#       contains traffic details as well as testbed details.
#
# Results:
#       Obj of dvPortStatsVerification module - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $veriWorkload = $options{workload};
   my $machine;

   if (not defined $veriWorkload->{server}) {
      $vdLogger->Error("Testbed information missing in Verification ".
                       "hash provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $machine = "server";
   my $self = {
      machine => $veriWorkload->{$machine},
   };

   $self->{statstype} = $veriWorkload->{statstype};

   if ((not defined $self->{statstype}) ||
       ($self->{statstype} eq "")) {
      $vdLogger->Error("StatsType key is mandatory for dvportstats.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   bless ($self, $class);
   return $self;
}


###############################################################################
#
# ProcessTestbed -
#       To process information from the testbed, check for required data
#       find mac address of test interface if required.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessTestbed
{

   my $self = shift;
   my $mac;
   my $hostObj;
   my $dvport;

   $self->{os} = $self->{machine}->{os};
   $self->{testip} = $self->{machine}->{testip};
   $self->{controlip} = $self->{machine}->{controlip};
   $self->{esxip} = $self->{machine}->{esxip};
   $mac = $self->{machine}->{macaddress};
   if (not defined $mac) {
      $mac = $self->{staf}->GetMACFromIP($self->{controlip},
                                         $self->{testip});
      if ($mac eq FAILURE) {
         $vdLogger->Error("Unable to get mac for $self->{testip} ".
			  "on $self->{controlip}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   $hostObj = VDNetLib::Host::HostOperations->new($self->{esxip});
   # now get the dvport.
   $dvport = $hostObj->GetvNicDVSPortID($mac);
   if ($dvport eq FAILURE) {
      $vdLogger->Error("Failed to get the dvport Id");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $self->{dvport} = $dvport;
   return SUCCESS;
}

###############################################################################
#
# BuildCommand -
#       This method builds the command(binary) for gathering statistics.
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub BuildCommand
{
   my $self = shift;

   $self->{bin} = "net-dvs -l | grep -A 43 \"port $self->{dvport}:\" | grep ";

   $vdLogger->Trace("Built command:$self->{bin} for : $self->{esxip}");
   return SUCCESS;
}


###############################################################################
#
# StartVerification -
#       Gathers Unicast, Multicast and Broadcast statistics of DVPort using
#       net-dvs command.
#
# Input:
#       state/tag - which one wants to apply to results so that they can take
#                   a diff between various results later on.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub StartVerification
{
   my $self = shift;
   my $state = shift ;

   if (not defined $state){
      $state = "Initial";
   }

   my ($command, $result, $tag);
   my $host = $self->{esxip};

   # Taking in/out packets stats
   $tag = "dvportpkts" . $state;
   $command = $self->{bin} . "-i pkts" . $self->{statstype} . "|awk '{print \$3}'";

   $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif(defined $result->{stderr} &&
           $result->{stderr} =~ /(bad command|not found|invalid)/i) {
      $vdLogger->Error("net-dvs command in StatsVerification failed with: ".
                       "$result->{stderr}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $self->{statsBucket}->{$tag} = $result->{stdout};

   # Taking in/out bytes stats
   $tag = "dvportbytes" . $state;
   $command = $self->{bin} . "-i bytes" . $self->{statstype} . "|awk '{print \$3}'";

   $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif(defined $result->{stderr} &&
           $result->{stderr} =~ /(bad command|not found|invalid)/i) {
      $vdLogger->Error("net-dvs command in StatsVerification failed with: ".
                       "$result->{stderr}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $self->{statsBucket}->{$tag} = $result->{stdout};

   return SUCCESS;
}


###############################################################################
#
# StopVerification -
#       This method just takes another snapshot of all the stats so that both
#       stats can be compared.
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub StopVerification
{
   my $self = shift;
   # We just call the same method which gather stats from every place
   # and attach this tag final to it.
   # Then we take a diff of initial and final stats.
   if ($self->StartVerification("Final") ne SUCCESS)
   {
      $vdLogger->Error("StartVerification did not return SUCCESS ".
                       "in StatsVerification");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GetResult -
#       This method calls the appropriate method which will do the diff between
#       initial and final stats and returns the result.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#
#
# Results:
#       integer value of the information to be extract from Stats
#       FAILURE in case something goes wrong.
#
# Side effects:
#
###############################################################################

sub GetResult
{
   my $self = shift;

   # Check if initial and final stats are available for Packets and Bytes.
   if (defined $self->{statsBucket}->{dvportpktsInitial} &&
   defined $self->{statsBucket}->{dvportpktsFinal} &&
   defined $self->{statsBucket}->{dvportbytesInitial} &&
   defined $self->{statsBucket}->{dvportbytesFinal}) {
      # Check if Final counters are updated.
      if (($self->{statsBucket}->{dvportpktsFinal} <= $self->{statsBucket}->{dvportpktsInitial}) ||
         ($self->{statsBucket}->{dvportbytesFinal} <= $self->{statsBucket}->{dvportbytesInitial})) {
            $vdLogger->Error("dvPort Statistics failed for: $self->{statstype}.");
            $self->DisplayStats();
            return FAILURE;
      }
   }

   $vdLogger->Info("dvPort Statistics successfully verified for: $self->{statstype}.");
   $self->DisplayStats();

   return SUCCESS;
}


###############################################################################
#
# DisplayStats -
#       This method will display the Packets and Bytes information.
#
# Input:
#       None.
#
# Results:
#       SUCCESS.
#
# Side effects:
#       None.
#
###############################################################################

sub DisplayStats
{
   my $self = shift;

   $vdLogger->Info("\n==========================================\n");
   $vdLogger->Info("$self->{statstype}:Initial Packets :=> $self->{statsBucket}->{dvportpktsInitial}\n");
   $vdLogger->Info("$self->{statstype}:Final Packets   :=> $self->{statsBucket}->{dvportpktsFinal}\n");

   $vdLogger->Info("$self->{statstype}:Initial Bytes   :=> $self->{statsBucket}->{dvportbytesInitial}\n");
   $vdLogger->Info("$self->{statstype}:Final Bytes     :=> $self->{statsBucket}->{dvportbytesFinal}\n".
                   "==========================================\n");

   return SUCCESS;
}


###############################################################################
#
# ProcessVerificationKeys -
#       Complying with parent interface.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessVerificationKeys
{
   return SUCCESS;
}

###############################################################################
#
# AppendTestOptions -
#       Complying with parent interface.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub AppendTestOptions
{

   return SUCCESS;
}


###############################################################################
#
# DESTROY -
#       This method is destructor for this class.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#
###############################################################################

sub DESTROY
{
   return SUCCESS;
}

1;
