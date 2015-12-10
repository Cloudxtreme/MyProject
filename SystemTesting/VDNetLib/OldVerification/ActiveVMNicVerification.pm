#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::OldVerification::ActiveVMNicVerification;

#
# This package inherits VDNetLib::Verification::Verification class.
# This is used for verifying active uplink of a virtual nice
# using the load balancing options set the virtual switch.
# Sample workflow:
#  The load balancing option is set on a virtual switch. The source
#  virtual adapter is connected to this switch. The switch is uplinked
#  to 1 or more phy nics.
#  Before running traffic through the virtual adapter, the active uplink
#  of this adapter is computed. Then, the tx/rx stats are collected from the
#  phy uplink and saved as Starting point.
#  Traffic workload is now between the source virtual adapter and other
#  destination (should be different host). Once traffic is stopped, the
#  tx/rx stats of the phy uplink is computed once again and then the difference
#  is found between the start and end value.
#  Based on the traffic throughput, a decision is made whether traffic went
#  through the active phy uplink.
#
#  NOTE: No parallels sessions of traffic should be run through this phy
#  uplink at the same time. This is avoid false positive in tx stats
#  calculation when external sources send traffic through same vmnic as the
#  virtual adapter under test.
#

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
use VDNetLib::Switch::Switch;


###############################################################################
#
# new -
#       This method reads the verification hash provided. Fetch required
#       details from verification hash like src/dst ip, src/dst mac address.
#
# Input:
#       verification hash (required) - a specificaton in form of hash which
#       contains traffic details as well as testbed details.
#
# Results:
#       Obj of ActiveVMNicVerification module, if successful;
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

   #
   # The client (Tx) information of traffic is important for this
   # verification process.
   #
   if (not defined $veriWorkload->{client}) {
      $vdLogger->Error("Testbed information missing in Verification ".
                       "hash provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self = {
      testduration => $veriWorkload->{testduration},
      srcmachine   => $veriWorkload->{client},
      dstmachine   => $veriWorkload->{server},
      activevmnic  => $veriWorkload->{activevmnic},
   };


   bless ($self, $class);
   return $self;
}


###############################################################################
#
# StartVerification -
#       Method to collect the load balancing options on the virtual switch,
#       compute active uplink based on the load balancing algorithms.
#       Then, collect starting values of "Tx Bytes" on the active uplink.
#
# Input:
#      None
#
# Results:
#      SUCCESS - in case everything goes well.
#      FAILURE - in case of error
#
# Side effects:
#      None
#
###############################################################################

sub StartVerification
{
   my $self = shift;
   $vdLogger->Info("Starting ActiveVMNicVerification for " .
                   $self->{srcmachine}{testip});
   my $controlIP  = $self->{srcmachine}{controlip};
   my $hostIP     = $self->{srcmachine}{esxip};
   my $srcIP      = $self->{srcmachine}{testip};
   my $dstIP      = $self->{dstmachine}{testip};

   # GetSwitchObj() updates $self->{srcmachine}{switchObj} value
   my $result     = $self->GetSwitchObj();

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create switch object for $srcIP on " .
                       "$controlIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $switchObj = $self->{srcmachine}{switchObj};


   #
   # Collect the teaming policies of the src virtual switch.
   #
   my $teamPolicy = $switchObj->GetTeamingPolicies($self->{srcmachine}{portgroup});
   if ($teamPolicy eq FAILURE) {
      $vdLogger->Error("Failed to get teaming policy of $srcIP switch on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Debug("Team policy : " . Dumper($teamPolicy));

   #
   # From the teaming policies, retrieve the load balancing option set on the
   # switch.
   #
   my $loadBalancing = $teamPolicy->{'Load Balancing'};
   $vdLogger->Info("Load balancing option on $srcIP is $loadBalancing");

   my $activeVMNIC;
   my $esxTopData;
   $vdLogger->Debug("Port id:$self->{srcmachine}{portid}");
   $vdLogger->Debug("Src MAC:$self->{srcmachine}{macaddress}");
   $vdLogger->Debug("Src and Dst IP:$srcIP, $dstIP");

   if ($loadBalancing =~ /srcport/) {
      $activeVMNIC =
      $vdLogger->Info("Using srcport algorithm to find active vmnic");
      $activeVMNIC =
         $switchObj->GetActiveVMNic($self->{srcmachine}{portid}, undef,
                                    $self->{srcmachine}{portgroup});
   } elsif ($loadBalancing =~ /srcmac/i) {
      $vdLogger->Info("Using srcmac algorithm to find active vmnic");
      $activeVMNIC =
         $switchObj->GetActiveVMNic($self->{srcmachine}{macaddress}, undef,
                                    $self->{srcmachine}{portgroup});
   } elsif ($loadBalancing =~ /iphash/i) {
      $vdLogger->Info("Using iphash algorithm to find active vmnic");
      $activeVMNIC =
         $switchObj->GetActiveVMNic($srcIP, $dstIP,
                                    $self->{srcmachine}{portgroup});
   } else {
      $vdLogger->Info("Using explicit/teamUplink method to find active vmnic");
      $activeVMNIC =
         $switchObj->{hostOpsObj}->GetActiveVMNicOfvNic($self->{srcmachine}{macaddress});
         #$switchObj->GetTeamUplink($self->{srcmachine}{portid});
         $esxTopData = $activeVMNIC; # active uplink shown on esxtop/vsish is
                                     # needed at multiple places, so saving it.
   }

   if ((not defined $activeVMNIC) ||
      ($activeVMNIC eq "") ||
      ($activeVMNIC eq FAILURE)) {
      $vdLogger->Error("Failed to find the active vmnic for $srcIP on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($activeVMNIC =~ /dvuplink/i) {
      $activeVMNIC = $switchObj->{hostOpsObj}->GetActiveDVUplinkPort($self->{srcmachine}{switchName},
                                                                     $activeVMNIC);
   }
   $vdLogger->Info("Active vmnic computed for $srcIP is $activeVMNIC");
   if ($activeVMNIC eq FAILURE) {
      $vdLogger->Error("Failed to get active vmnic of $srcIP on $controlIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{srcmachine}{activenic} = $activeVMNIC;

   if (defined $teamPolicy->{'Standby Adapters'}) {
      #
      # If standby adapters are defined in the switch's teaming policy,
      # then it is important to ensure that the active uplink shown on
      # esxtop is not any of the standby adapters.
      #
      $vdLogger->Info("Standby adapters:$teamPolicy->{'Standby Adapters'}");
      if (not defined $esxTopData) {
         $esxTopData = $switchObj->GetTeamUplink($self->{srcmachine}{portid});
         if ($esxTopData eq FAILURE) {
            $vdLogger->Error("Failed to get active vmnic of $srcIP on $controlIP");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      #
      # Check if the number of active adapters is greater than or equal to 1.
      # If true, then verify that the active uplink is not any of the adapters
      # under standby mode.
      #
      if (scalar(@{$teamPolicy->{'ActiveAdapters'}})) {
         if ($esxTopData =~ /$teamPolicy->{'Standby Adapters'}/) {
            $vdLogger->Error("Active VMNic computed should not be part of " .
                            "standby adapters $teamPolicy->{'Standby Adapters'}");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }

   } else {
      $vdLogger->Info("No standby adapters configured");
   }

   #
   # Once the active uplink is known, create NetAdapter object for that
   # and collect the NICStats from this adapter.
   #
   my $netObj = VDNetLib::NetAdapter::NetAdapter->new(controlIP => $hostIP,
                                                      interface => $activeVMNIC,
                                                      intType   => "vmnic",
                                                     );
   if ($netObj eq FAILURE) {
      $vdLogger->Error("Failed to create vmnic object for $activeVMNIC");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{srcmachine}{netobj} = $netObj;

   #
   # This verification is primarily to verify the outgoing active uplink.
   # So, collecting "Tx Bytes" information.
   #
   my $stats = $self->{srcmachine}{netobj}->GetNICStats();
   if ($stats eq FAILURE) {
      $vdLogger->Error("Failed to get stats for $activeVMNIC on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{srcmachine}{txbytesStart} = $stats->{'Tx Bytes'};
   $vdLogger->Info("Start:Tx Bytes of $activeVMNIC on $hostIP " .
                   $self->{srcmachine}{txbytesStart});

   return SUCCESS;
}


###############################################################################
#
# StopVerification -
#      This method just takes another snapshot of active uplinks' stats.
#
# Input:
#      None
#
# Results:
#      SUCCESS - in case everything goes well.
#      FAILURE - in case of error
#
# Side effects:
#      None
#
###############################################################################

sub StopVerification
{
   my $self = shift;
   $vdLogger->Info("Starting ActiveVMNicVerification for " .
                   $self->{srcmachine}{testip});

   #
   # Collect the "Tx Bytes" value of the active uplink.
   #
   my $stats = $self->{srcmachine}{netobj}->GetNICStats();
   if ($stats eq FAILURE) {
      $vdLogger->Error("Failed to get stats for " .
                       "$self->{srcmachine}{activenic} on " .
                       $self->{srcmachine}{esxip});
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{srcmachine}{txbytesEnd} = $stats->{"Tx Bytes"};

   $vdLogger->Info("END:Tx Bytes of " .
                   $self->{srcmachine}{activenic} .
                   " on $self->{srcmachine}{esxip} " .
                   $self->{srcmachine}{txbytesEnd});
   return SUCCESS;
}


###############################################################################
#
# GetResult -
#      This method which will do the diff between the initial and final stats
#      and compare the result with traffic throughput data.
#
# Input:
#      None
#
# Results:
#      SUCCESS, if the active uplink computed is really used by the virtual
#                adapter;
#      FAILURE in case something goes wrong.
#
# Side effects:
#
###############################################################################

sub GetResult
{
   my $self = shift;

   #
   # Take a diff of starting and ending "Tx Bytes" on the active uplink
   my $diff = int($self->{srcmachine}{txbytesEnd}) - int($self->{srcmachine}{txbytesStart});

   #
   # Collect the throughput from the traffic result.
   #
   my $tput = $self->{dstmachine}{throughput};

   $vdLogger->Info("VMNic Stats: Total bytes sent in this session = $diff");
   if (not defined $tput) {
      $vdLogger->Error("Session throughput is not given");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $duration = $self->{testduration};
   $vdLogger->Debug("Session throughput = $tput");

   #
   # From throughput and test duration, get rx data in bytes.
   # TODO: Traffic results 2/13/11 gives only server throughput,
   # so using that value for verification. Since rx cannot be greater
   # than tx, it is expected the "Tx Bytes" diff is greater than rx bytes.
   #
   my $rxBytes = (int($duration) * int ($tput) * (10 ** 6)) / 8;
   $rxBytes = int($rxBytes);
   $vdLogger->Info("Total bytes received = $rxBytes");

   if ((int($diff) == 0) ||
       ($rxBytes > int($diff))) {
      $vdLogger->Error("$self->{srcmachine}{activenic} is NOT used " .
                       "correctly in this session");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GetSwitchObj --
#      Method to get the switch object of the source virtual adapter.
#
# Input:
#      None
#
# Results:
#      Updates $self->{srcmachine}{switchObj}, if successful;
#      FAILURE, in case of any error
#
# Side effects:
#      None
#
###############################################################################


sub GetSwitchObj
{
   my $self = shift;
   my $controlIP = $self->{srcmachine}{controlip};
   my $hostIP = $self->{srcmachine}{esxip};
   my $srcIP = $self->{srcmachine}{testip};
   my $hostObj = VDNetLib::Host::HostOperations->new($hostIP);

   if ($hostObj eq FAILURE) {
      $vdLogger->Error("Failed to create HostOperation object for $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{srcmachine}{hostObj} = $hostObj;

   # First, get the mac address of the given ip address.
   my $mac = $self->{srcmachine}{macaddress};

   if(not defined $mac) {
      $mac =
         VDNetLib::Common::Utilities::GetMACFromIP($srcIP, $hostObj->{stafHelper},
                                                   $controlIP);
      if ($mac eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{srcmachine}{macaddress} = $mac;
   }

   #
   # The VSI port id of the virtual adapter need to be obtained.
   #
   my $port = $hostObj->GetvNicVSIPort($mac);

   if ($port eq FAILURE) {
      $vdLogger->Error("Error getting pts port for given adapter $mac");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("VSI port for $srcIP is $port");
   my $switchName;
   if ($port =~ /\/net\/portsets\/(.*?)\/ports\/(.*)/i) {
      $switchName = $1;
      $self->{srcmachine}{switchName} = $switchName;
      $self->{srcmachine}{portid} = $2;
   }
   if ((not defined $switchName) ||
       (not defined $self->{srcmachine}{portid})) {
      $vdLogger->Error("Error getting switchname or portid " .
                       "for $srcIP on $controlIP");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $type = "vswitch";
   if ($switchName =~ /portset/i) {
      #
      # In case of vdswitch, the vsish tree has switch names as
      # portset names (which is different from what is seen on VC).
      # Since, this verification module makes use of both esxcli/staf sdk
      # related APIs as well as vsish, all different aliases of the switch
      # corresponding to the src adapter need to be found.
      #
      $switchName = $hostObj->GetDVSNameFromPortset($switchName);
      if ($switchName eq FAILURE) {
         $vdLogger->Error("Failed to get switch name from portset");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{srcmachine}{switchName} = $switchName;

      my $command = "vsish -e get $port/status";
      my $result = $hostObj->{stafHelper}->STAFSyncProcess($hostObj->{hostIP},
                                                           $command);

      # check for success or failure of the command executed using staf
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to obtain the portset info");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      #
      # Similar to switch name, the portgroups in a switch is also represented
      # with different forms such port ids, portgroup names (vc), portgroup
      # keys. Each alias is with respect to host/vc/esxcli.
      #
      # For this verification process, the port id (integer) corresponding to
      # the source adapter's portgroup need to be found.
      #
      my $dvPortGroupID;
      if ($result->{stdout} =~ /dvportid:(\d+)/i) {
         $dvPortGroupID = $1;
      }

      $self->{srcmachine}{portgroup} = $dvPortGroupID;
      #
      # TODO: Fix this!
      # Using 'vdswitch' as switch since it requires vcobj
      # and datacenter names. At this point, these variables are unknown,
      # meaning the caller of this package (Session.pm) does not have details
      # about the vc object and datacenter names. So, creating a switch obj
      # which would still make use of many methods where VC or datacenter names
      # not required.
      #
      $type = "dvswitch"; # use vswitch for now.

   }

   $vdLogger->Info("Virtual switch name of $srcIP is $switchName");
   $vdLogger->Info("Port id of $srcIP on $hostIP is " .
                   $self->{srcmachine}{portid});

   my $switchObj = VDNetLib::Switch::Switch->new('switch' => $switchName,
                                                 'switchType' => $type,
                                                 'host' => $hostIP,
                                                 'hostOpsObj' => $hostObj,
                                                );
   if ($switchObj eq FAILURE) {
      $vdLogger->Error("Failed to create switch object for ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{srcmachine}{switchObj} = $switchObj;
   return SUCCESS;
}
#
# Dummy methods.
# TODO: to be removed when dependencies are handled in parent class itself
#
sub BuildCommand { return SUCCESS };
sub ProcessVerificationKeys { return SUCCESS };
sub ProcessTestbed { return SUCCESS };


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
   my $self = shift;
   return SUCCESS;
}
1;
