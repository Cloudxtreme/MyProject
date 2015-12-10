########################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Suites::TAHI;
#
# This class captures all method to setup, execute and cleanup all tests
# in TAHI Suite
#

use strict;
use warnings;
use FindBin;
use Data::Dumper;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

#
# TAHI base directory where the suite is installed (currently, freebsd is the
# only supported VM to launch TAHI tests
#
use constant TAHIBASEDIR => "/usr/local/v6eval";

#
# Capture all the modules in the TAHI suite here
#
my $tahiModuleHash = {
   "ipv6ready_p2_host_spec" => {
      'modulePath' => "/usr/local/Self_Test_5-0-0/spec.p2",
      'duration'   => 3600,
   },
   "ipv6ready_p2_host_nd" => {
      'modulePath' => "/usr/local/Self_Test_5-0-0/nd.p2",
      'duration'   => 14400,
   },
   "ipv6ready_p2_host_pmtu" => {
      'modulePath' => "/usr/local/Self_Test_5-0-0/pmtu.p2",
      'duration'   => 3600,
   },
   "ipv6ready_p2_host_icmp" => {
      'modulePath' => "/usr/local/Self_Test_5-0-0/icmp.p2",
      'duration'   => 3600,
   },
   "ipv6ready_p2_host_addr" => {
      'modulePath' => "/usr/local/Self_Test_5-0-0/addr.p2",
      'duration'   => 18000,
   },
   "ipv6ready_p2_end_node" => {
      'modulePath'   => "/usr/local/IPsec_Self_Test_P2_1-10-0/ipsec.p2",
      'duration'     => 3600,
   },
   "ipv6ready_p2_client_rfc3315" => {
      'modulePath'   => "/usr/local/DHCPv6_Self_Test_P2_1_1_3/rfc3315",
      'duration'     => 14400,
   },
};


########################################################################
#
# new--
#     Constructor to create an instance of VDNetLib::Suites::TAHI
#
# Input:
#     nut : Node Under Test (NUT) (Required):
#           reference to VDNetLib::NetAdapter::NetAdapter object
#           which must have the following attiributes defined
#              controlIP:  management ip address of NUT
#              interface:  test interface, example vmk1, eth1
#                            (different  from management interface)
#              macAddress:  mac address of test interface
#
#     testNode  : Test Node (TN) (Required)
#                 reference to VDNetLib::NetAdapter::NetAdapter object
#     stafHelper: reference to VDNetLib::Common::STAFHelper object
#                 (Required)
#     logDir    : local log directory (Optional, default is /tmp)
#
#
# Results:
#
# Side effects:
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self;
   $self->{nut}        = $options{nut};        # esx host
   $self->{testNode}   = $options{testNode};   # freebsd
   $self->{stafHelper} = $options{stafHelper};
   $self->{logDir}     = $options{logDir} || "/tmp";

   $self->{environment} = undef; # will be set in Setup()
   $self->{testModules} = undef; # will be set in Setup()

   my @requiredKeys = ('controlIP', 'macAddress', 'interface');

   foreach my $key (@requiredKeys) {
      if ((not defined $self->{nut}{$key}) ||
         (not defined $self->{testNode}{$key})) {
         $vdLogger->Error("$key not defined for testNode or nut");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
   if (not defined $self->{stafHelper}) {
      $vdLogger->Error("STAFHelper not provided as parameter");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   bless ($self, $class);
   return $self;
}


########################################################################
#
# Setup--
#     Method to configure NUT and TN to run TAHI suite.
#     This involves:
#     - editing the tn.def and nut.def in TN (FreeBSD)
#     - calling "make clean" on all the given modules to be tested
#
# Input:
#     testModules : reference to an array of modules (Required)
#     pgName:  NUT portgroup Name
#     switch:  NUT vswitch Name
#     host:    NUT Name 
#
# Results:
#     SUCCESS, if all the test modules are configured to run;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub Setup
{
   my $self        = shift;
   my $testModules = shift;
   my $pgName      = shift;
   my $switch      = shift;
   my $host        = shift;

   if (not defined $testModules) {
      $vdLogger->Error("No module name given to tested/configured");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # disable Notify Switches in switch failover mode
   # vim-cmd hostsvc/net/portgroup_set --nictraming-notify-switch=false switch portgroup 
   #
   my ($command, $result);
   $command = "vim-cmd hostsvc/net/portgroup_set --nicteaming-notify-switch=false $switch $pgName";
   #  $vdLogger->Info("STAF command $command host=$host");
   $result = $self->{stafHelper}->STAFSyncProcess($host,$command);
   
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # set the testModules attribute
   $self->{testModules} = $testModules;

   #
   # Environment variables "TN_INTERFACE" "NUT_INTERFACE" "NUT_IP"
   # and "NUT_PORTGROUP need to be setup on TN before running TAHI
   # suite
   #
   my $tnInterface = $self->{testNode}->GetInterface();

   my $nutInterface = $self->{nut}->GetInterface();

   my $envVars = "TN_INTERFACE=$tnInterface " .
                 "NUT_INTERFACE=$nutInterface " .
                 "NUT_PORTGROUP=$pgName " .
                 "NUT_IP=$self->{nut}->{controlIP}";

   $self->{environment} = $envVars;

   #
   # Loop through all modules and configure them
   #
   foreach my $module (@{$testModules}) {
      my $modulePath = $tahiModuleHash->{$module}{'modulePath'};

      if (not defined $modulePath) {
         $vdLogger->Error("Module path not defined for $module");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $command = $envVars . " make -C $modulePath clean";
      $result = $self->{stafHelper}->STAFSyncProcess($self->{testNode}->{controlIP},
                                                     $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command $command failed:". Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   #
   # Configure nut.def
   #
   # These are entries required in nut.def in order to run TAHI
   #
   my $nutFile = TAHIBASEDIR . "/etc/nut.def";
   my $entry = "HostName $self->{nut}->{controlIP}\n";
   $entry = $entry . "Type host\n";
   $entry = $entry . "System tahics\n";
   $entry = $entry . "User $self->{nut}{hostObj}{userid}\n";
   $entry = $entry . "Password '$self->{nut}{hostObj}{password}'\n";
   $entry = $entry . "Link0 $nutInterface $self->{nut}->{macAddress}\n";
   $command =  "echo \"$entry\" > $nutFile";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{testNode}->{controlIP},
                                                  $command);
   if (($result->{rc} != 0) || ($result->{exitCode})) {
      $vdLogger->Error("STAF command $command failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Configure tn.def
   #
   # These are entries required in tn.def in order to run TAHI
   #
   # 00:00:00:00:01:00 is bogus IP which is needed in tn.def
   #
   my $tnFile = TAHIBASEDIR . "/etc/tn.def";
   $entry = "# tn.def\n";
   $entry = $entry . "RemoteMethod serial\n";
   $entry = $entry . "RemoteLog 1\n";
   $entry = $entry . "Link0 $tnInterface 00:00:00:00:01:00\n";

   $command =  "echo \"$entry\" > $tnFile";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{testNode}{controlIP},
                                                  $command);
   if (($result->{rc} != 0) || ($result->{exitCode})) {
      $vdLogger->Error("STAF command $command failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Configure router advertisement
   #
   $result = $self->ConfigureRouterAdvertisement();
   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;

}


########################################################################
#
# RunTests--
#     Method to execute all the test modules. This method takes care
#     of collecting logs and make a decision as well.
#     This method should be called only after Setup() method is called.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if all the tests in the given modules are executed
#                without any failures;
#     "FAILURE", in case of any error;
#
# Side effects:
#
########################################################################

sub RunTests
{
   my $self = shift;
   my $result;
   my $tstModule;

   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get local IP address");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($self->{stafHelper}->CheckSTAF($localIP) eq FAILURE) {
       $vdLogger->Error("STAF is not installed or running on $localIP");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   foreach my $module (@{$self->{testModules}}) {
      if ($module =~ /ipv6ready_p2_host/) {
         $tstModule = "ipv6ready_p2_host";
      } elsif ($module =~ /ipv6ready_p2_client/) {
         $tstModule = "ipv6ready_p2_client";
      } else {
         $tstModule = $module;
      };
      $vdLogger->Info("Running tests under $module module");

      my $modulePath = $tahiModuleHash->{$module}{'modulePath'};
      my $moduleDuration = $tahiModuleHash->{$module}{'duration'};

      my $command = $self->{environment} . " make -C $modulePath $tstModule";
      $vdLogger->Info("TAHI command:$command");
      $result = $self->{stafHelper}->STAFSyncProcess($self->{testNode}->{controlIP},
                                                     $command,
                                                     $moduleDuration);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command $command failed:". Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      #
      # Collect all the logs for decision making and debugging purposes
      #
      my @fileExtension =('html', 'pcap', 'dump');
      foreach my $ext (@fileExtension) {
         $vdLogger->Debug("Copy $ext from $self->{testNode}->{controlIP} : $modulePath" .
                          " to $localIP : $self->{logDir} \n");
         $result = $self->{stafHelper}->STAFFSCopyDirectory("$modulePath",
                                                            $self->{logDir},
                                                            $self->{testNode}->{controlIP},
                                                            $localIP,
                                                            "EXT $ext NAME *");
         if ($result == -1) {
            $vdLogger->Error("Failed to copy $ext files from $self->{testNode}->{controlIP}");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      }

      #
      # Analyze PASS/FAIL. TODO: HTML::Parser can be used if many fields from
      # summary.html needs to be retrieved
      #
      $result = `cat $self->{logDir}/summary.html | grep FAIL`;
      if ($result =~ /FAIL.*>(\d+)</) {
         my $failCount = $1;
         if (int($failCount)) {
            $vdLogger->Error("Number of failed tests:$1");
            return FAILURE;
         }
      }
      $vdLogger->Info("No tests failed in $module module");
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureRouterAdvertisement--
#     Method to configure router advertisement on NUT's test and
#     management interface
#
# Input:
#     None
#
# Results:
#     SUCCESS, if the configuration is successful;
#     FAILURE, in case of any error;
#
# Side effects:
#
########################################################################

sub ConfigureRouterAdvertisement
{
   my $self = shift;

   # Disable router advertisement on management interface vmk0
   my $command = "esxcli network ip interface ipv6 ".
                 "set -r false -i vmk0";

   $vdLogger->Debug("Executing SetRouterAdvertisement command: $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{nut}{controlIP},
                                                     $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to configure router advertisement of " .
                       " vmk0 on $self->{nut}{controlIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Enable router advertisement on management interface vmk0
   $result = $self->{nut}->SetRouterAdvertisement("true", "ipv6");
   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# Cleanup--
#     Method to do any cleanup after tests are executed
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub Cleanup
{
   return SUCCESS;
}
1;

