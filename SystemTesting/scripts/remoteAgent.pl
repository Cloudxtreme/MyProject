#!/usr/bin/perl
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
# remoteAgent.pl
# This is a helper program which calls appropriate methods/functions
# in a package based on the user input.
# It can be extended to any other packages for remote sub-routine exectution.
#
# This code works along with /automation/features/Networking/lib/localAgent.pm
# to execute remote sub-routines/methods. This agent code resides on the
# machine where a method has to be called. localAgent.pm resides on the machine
# where remote methods are called.
# The return values, error codes from a method are sent back to localAgent.pm
# using shared variable provided by STAF's VAR service.
#
# If --local option is specified, this code works in standalone mode and does
# not updated any shared variables using STAF, rather prints the return value
# and error code, if any, of the method being called.


BEGIN {
   push(@INC, "/Library/staf/lib/perl510");
};


use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;


eval "use PLSTAF";
if ($@) {
   use lib "$FindBin::Bin/../VDNetLib/Common";
   use PLSTAF;
}
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use VDNetLib::NetAdapter::NetDiscover;
use VDNetLib::Common::Utilities;
use VDNetLib::VM::VMOperations;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Getopt::Long;
use VDNetLib::Common::VDErrorno qw( VDSetLastError VDGetLastError );
use VDNetLib::Common::EsxUtils;

if ($^O =~ /linux/i) {
      use lib "/usr/local/staf/bin";
} elsif ($^O =~ /win/i) {
      use lib "C:\\STAF\\bin";
} elsif ($^O =~ /darwin/i) {
      use lib "/Library/staf/bin";
}

use constant EXIT_SUCCESS => 0;
use constant EXIT_FAILURE => 1;


my $usage;
my $methodName;
my $params;
my $local;
my $return;
my $sub_ref;
my @paramArray;

$usage = "-m methodName -p \"<param1>, <param2>, ...,<paramN>\"\n" .
"command-options:
   Short        Long       Takes
   form         form       value?         Description
   -m      --methodName      y      Sub-routine to call.
   -p      --params          y      Parameters to pass to the sub-routine.
   -l      --local           y      To disable sending results to a remote
                                    process using STAF
   -h      --help            n      This help message

";
my $result;
$result = GetOptions (
                   "methodName|m=s"   => \$methodName,
                   "params|p=s"       => \$params,
                   "local|l"          => \$local,
                   "help|h"           => sub { print $usage;
                                               exit EXIT_FAILURE;},
           );

unless (defined $methodName)
{
   print STDERR "$0: Invalid options\n";
   print STDERR "Usage:\n $0 $usage\n";
   exit EXIT_FAILURE;
}

# This code remoteAgent.pl will be called on the system under test machine.
# In order to call the correct sub-routine, the sub-routine name has to be
# passed as command-line argument to this code.
# The following hash 'functionsHash' contains the reference to a sub-routine
# corresponding to the sub-routine name.
# This approach is used since it is not straight forward to
# call a sub-routine or method via a script (.pl file).
#
# Reference to any function to be called in VDNetLib::NetAdapter::NetDiscover.pm
# should be updated here, otherwise this code will throw error
#
my %functionsHash = (
   "GetAdapters" => \&VDNetLib::NetAdapter::NetDiscover::GetAdapters,
   "GetDeviceStatus" => \&VDNetLib::NetAdapter::NetDiscover::GetDeviceStatus,
   "SetDeviceStatus" => \&VDNetLib::NetAdapter::NetDiscover::SetDeviceStatus,
   "GetDriverName" => \&VDNetLib::NetAdapter::NetDiscover::GetDriverName,
   "GetMTU" => \&VDNetLib::NetAdapter::NetDiscover::GetMTU,
   "SetMTU" => \&VDNetLib::NetAdapter::NetDiscover::SetMTU,
   "GetIPv4" => \&VDNetLib::NetAdapter::NetDiscover::GetIPv4,
   "GetNetworkAddr" => \&VDNetLib::NetAdapter::NetDiscover::GetNetworkAddr,
   "GetVLANId" => \&VDNetLib::NetAdapter::NetDiscover::GetVLANId,
   "SetVLAN" => \&VDNetLib::NetAdapter::NetDiscover::SetVLAN,
   "RemoveVLAN" => \&VDNetLib::NetAdapter::NetDiscover::RemoveVLAN,
   "SetIPv4" => \&VDNetLib::NetAdapter::NetDiscover::SetIPv4,
   "GetOffload" => \&VDNetLib::NetAdapter::NetDiscover::GetOffload,
   "SetOffload" => \&VDNetLib::NetAdapter::NetDiscover::SetOffload,
   "GetNDISVersion" => \&VDNetLib::NetAdapter::NetDiscover::GetNDISVersion,
   "GetMACAddress" => \&VDNetLib::NetAdapter::NetDiscover::GetMACAddress,
   "GetInterfaceName" => \&VDNetLib::NetAdapter::NetDiscover::GetInterfaceName,
   "EnableDHCP" => \&VDNetLib::NetAdapter::NetDiscover::EnableDHCP,
   "GetLinkState" => \&VDNetLib::NetAdapter::NetDiscover::GetLinkState,
   "GetIPv6Local" => \&VDNetLib::NetAdapter::NetDiscover::GetIPv6Local,
   "GetIPv6Global" => \&VDNetLib::NetAdapter::NetDiscover::GetIPv6Global,
   "SetIPv6" => \&VDNetLib::NetAdapter::NetDiscover::SetIPv6,
   "SetWoL" => \&VDNetLib::NetAdapter::NetDiscover::SetWoL,
   "GetWoL" => \&VDNetLib::NetAdapter::NetDiscover::GetWoL,
   "GetInterruptModeration" => \&VDNetLib::NetAdapter::NetDiscover::GetInterruptModeration,
   "SetInterruptModeration" => \&VDNetLib::NetAdapter::NetDiscover::SetInterruptModeration,
   "GetOffloadTCPOptions" => \&VDNetLib::NetAdapter::NetDiscover::GetOffloadTCPOptions,
   "SetOffloadTCPOptions" => \&VDNetLib::NetAdapter::NetDiscover::SetOffloadTCPOptions,
   "GetOffloadIPOptions" => \&VDNetLib::NetAdapter::NetDiscover::GetOffloadIPOptions,
   "SetOffloadIPOptions" => \&VDNetLib::NetAdapter::NetDiscover::SetOffloadIPOptions,
   "GetRSS" => \&VDNetLib::NetAdapter::NetDiscover::GetRSS,
   "SetRSS" => \&VDNetLib::NetAdapter::NetDiscover::SetRSS,
   "SetPriorityVLAN" => \&VDNetLib::NetAdapter::NetDiscover::SetPriorityVLAN,
   "GetPriorityVLAN" => \&VDNetLib::NetAdapter::NetDiscover::GetPriorityVLAN,
   "GetMaxTxRxQueues" => \&VDNetLib::NetAdapter::NetDiscover::GetMaxTxRxQueues,
   "SetMaxTxRxQueues" => \&VDNetLib::NetAdapter::NetDiscover::SetMaxTxRxQueues,
   "IntrModParams" => \&VDNetLib::NetAdapter::NetDiscover::IntrModParams,
   "GetDriverVersion" => \&VDNetLib::NetAdapter::NetDiscover::GetDriverVersion,
   "GetRxBuffers" => \&VDNetLib::NetAdapter::NetDiscover::GetRxBuffers,
   "SetRxBuffers" => \&VDNetLib::NetAdapter::NetDiscover::SetRxBuffers,
   "GetRingSize" => \&VDNetLib::NetAdapter::NetDiscover::GetRingSize,
   "SetRingSize" => \&VDNetLib::NetAdapter::NetDiscover::SetRingSize,
   "DriverLoad" => \&VDNetLib::NetAdapter::NetDiscover::DriverLoad,
   "DriverUnload" => \&VDNetLib::NetAdapter::NetDiscover::DriverUnload,
   "UpdateDefaultGW" => \&VDNetLib::NetAdapter::NetDiscover::UpdateDefaultGW,
   "SetMACAddr" => \&VDNetLib::NetAdapter::NetDiscover::SetMACAddr,
   "EditFile" => \&VDNetLib::Common::Utilities::EditFile,
   "SendMagicPkt" => \&VDNetLib::Common::Utilities::SendMagicPkt,
   "AddARPEntry" => \&VDNetLib::Common::Utilities::AddARPEntry,
   "GetAdapterStats" => \&VDNetLib::NetAdapter::NetDiscover::GetAdapterStats,
   "GetAdapterEEPROMDump" => \&VDNetLib::NetAdapter::NetDiscover::GetAdapterEEPROMDump,
   "GetRegisterDump" => \&VDNetLib::NetAdapter::NetDiscover::GetRegisterDump,
   "GetNetworkConfig" => \&VDNetLib::NetAdapter::NetDiscover::GetNetworkConfig,
   "GetRouteConfig"   => \&VDNetLib::NetAdapter::NetDiscover::GetRouteConfig,
   "SetLRO"   => \&VDNetLib::NetAdapter::NetDiscover::SetLRO,
   "SetNetdumpConfig" =>
		\&VDNetLib::VM::VMOperations::SetNetdumpConfig,
   "CheckNetdumpStatus" =>
		\&VDNetLib::VM::VMOperations::CheckNetdumpStatus,
   "VerifyNetdumpConfig" =>
		\&VDNetLib::VM::VMOperations::VerifyNetdumpConfig,
   "InstallNetdumpServer" =>
		\&VDNetLib::VM::VMOperations::InstallNetdumpServer,
   "CleanNetdumpLogs" =>
		\&VDNetLib::VM::VMOperations::CleanNetdumpLogs,
   "SetReadWritePermissions" =>
		\&VDNetLib::VM::VMOperations::SetReadWritePermissions,
   "ConfigureService" =>
		\&VDNetLib::VM::VMOperations::ConfigureService,
   "GetPortEntitlement" =>
      \&VDNetLib::Common::EsxUtils::GetPortEntitlement,
   "GetPortEntitlementStatus" =>
      \&VDNetLib::Common::EsxUtils::GetPortEntitlementStatus,
   "ConfigureRoute" => \&VDNetLib::NetAdapter::NetDiscover::ConfigureRoute,
  );
# Set $vdLogger
#
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel' => $ENV{VDNET_LOGLEVEL},
                                             'logToFile' => $ENV{VDNET_LOGTOFILE},
                                             'verbose'  => $ENV{VDNET_VERBOSE});

# check if parameters are passed for the method/sub-routine to be called
if (defined $params) {
   @paramArray = split(',',$params);
}

if (!($sub_ref = $functionsHash{$methodName})) {
   warn "$methodName:No Such Method Defined";
   warn "$methodName:Method names are case-sensitive";
   exit EXIT_FAILURE;
}

# Gets the methodName as user input and calls the appropriate
# function in VDNetLib::NetAdapter::NetDiscover.pm

if ((defined $sub_ref) && (defined $params)) {
   $return  =  &{$sub_ref}(@paramArray);
} elsif (defined $sub_ref) {
   $return  =  &{$sub_ref};
}


my $returnRef = $return;

if (defined $local) {
   print STDOUT "Result " . Dumper($returnRef) . "\n";
   print VDGetLastError() . "\n";
} else {
   # Gets the shared variable name from parent process and
   # updates the return value from VDNetLib::NetAdapter::NetDiscover.pm in the shared
   # variable. That way, the parent process can know the return
   # value of the function called in VDNetLib::NetAdapter::NetDiscover.pm
   my $parentSharedVar;
   my $handle = STAF::STAFHandle->new("utility");

   if ($handle->{rc} != $STAF::kOk) {
      print "Error registering with STAF, RC: $handle->{rc}\n";
      exit $handle->{rc};
   }
   if (!($parentSharedVar = $ENV{PARENT_SHARED_VAR})) {
      warn "Parent Shared Variable Name not set";
      exit EXIT_FAILURE;
   }

   my $message = STAF::STAFMarshall($returnRef);
   my $writeToSharedVarCmd = "set SHARED var " . $parentSharedVar . "=". $message;
   $result = $handle->submit('local', "var", $writeToSharedVarCmd);
   if ($result->{rc} != $STAF::kOk) {
      print "Expected RC: 0\n";
      print "Received RC: $result->{rc}\n";
      exit EXIT_FAILURE;
   }

   $message = STAF::STAFMarshall(VDGetLastError());

   if (!($parentSharedVar = $ENV{PARENT_SHARED_ERR})) {
      warn "Parent Shared Error Variable Name not set";
      exit EXIT_FAILURE;
   }

   # put message within double quotes, otherwise the string will be passed as
   # such. Therefore, if the string has a word 'set', it will be treated as a
   # separate command
   $writeToSharedVarCmd = "set SHARED var " . $parentSharedVar . "=" . $message;
   $result = $handle->submit('local', "var", $writeToSharedVarCmd);

   if ($result->{rc} != $STAF::kOk) {
      print "Expected RC: 0\n";
      print "Received RC: $result->{rc}\n";
      exit EXIT_FAILURE;
   }
}

exit EXIT_SUCCESS;
