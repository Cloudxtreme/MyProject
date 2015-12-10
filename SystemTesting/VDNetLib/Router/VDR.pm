
########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Router::VDR;

use strict;
use warnings;
use Data::Dumper;

# Load modules
use FindBin;
use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

# Inherit the parent class.
use base qw(VDNetLib::Router::Router);


use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack );

use constant NET_VDR      => "net-vdr ";
use constant INSTANCE     => "--instance ";
use constant CONNECTION   => "--connection ";
use constant ROUTE        => "--route ";
use constant LIF          => "--lif ";
use constant ARP          => "--nbr ";
use constant BRIDGE       => "--bridge ";
use constant STATS        => "--stats ";
use constant CONTROLPLANE => "--cplane ";
use constant VDRPORT      => 8100;

use VDNetLib::Common::Utilities;
use VDNetLib::Router::Router;
use VDNetLib::Router::VDRComponents::LIF;
use VDNetLib::Router::VDRComponents::Route;
#use VDNetLib::Router::VDRComponents::Bridge;

########################################################################
#
# new -
#       This is the constructor module for VDR
#
# Input:
#       A named parameter (hash) with following keys:
#
# Results:
#       An instance/object of VDR class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;

   #
   # Creating Router Obj to inherit parent variables also.
   # Parent does one check, if the router name is defined.
   #
   if (not defined $args{vdrname}) {
      $args{vdrname} = VDNetLib::Common::Utilities::GenerateName("vdr-vdtest",
                                                              int(rand(10000)));
   }

   if (not defined $args{hostObj}) {
      $vdLogger->Error("Cannot create a VDR obj without hostObj:" .
                        Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $args{name} = $args{vdrname};
   my $parentObj = VDNetLib::Router::Router->new(%args);
   if ($parentObj eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::Router::Router object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # name is the only mandatory param, error checking for name is done by
   # Router.pm parent itself so no need to check here.
   #
   my $self = {
      'name'          => $args{vdrname},
      'vdrid'         => $args{'vdrid'},
      'controllerip'  => $args{'controllerip'},
      'lifs'          => undef,
      'routes'        => undef,
      'bridges'       => undef,
      'connection'    => {
         dvsname      => undef,
         vdrport      => VDRPORT,
         vdrvmac      => undef,
      },
      'tunableparams'      => {
         enableFrag          => undef,
         enableIcmpPMTU      => undef,
	     enableIcmpEcho      => undef,
	     enableBcastIcmpEcho => undef,
	     enableIcmpRateLimit => undef,
	     defaultTtl          => undef,
      },
      'hostObj'       => $args{hostObj},
      'dirtybit'         => {
         connectioninfo => 1,
         tunableparams => 1,
      }
   };

   # To inherit parent variables, use perl hash merge technique.
   $self = {%$self, %$parentObj};

   return bless ($self, $class);
}


########################################################################
#
# AddInstanceOnHost -
#       This method adds instance on host. i.e. on the host itself
#       We always have 2 creations, in vdnet and in product
#
# Input:
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub AddInstanceOnHost
{
   my $self = shift;
   # No user param. User has to give params while creating obj
   # this method will read fromt the obj
   my $vdrName      = $self->{'name'};
   my $vdrId        = $self->{'vdrid'};
   my $controllerIP = $self->{'controllerip'};
   my ($command, $result);

   # TODO: Stop gap solution untill product does this setup on its own.
   $self->DoVDRSetup();
   #TODO: Ask dev what will the default log level and use that here.
   $self->SetVDRLogLevel(2);


   #
   # To add an instance on host
   # --instance -a [-r vdrId] [-i controllerIp] vdrName
   # Add a new VDR instance
   #
   $command =  NET_VDR . INSTANCE  . " -a ";
   if (defined $vdrId) {
      $command = $command . " -r " . $vdrId;
   }
   if (defined $controllerIP) {
      $command = $command . " -i " . $controllerIP;
   }
   $command = $command . " " . $vdrName;


   my $host = $self->{hostObj}->{hostIP};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to add instance using command:$command ".
                       "on host:$host " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# DeleteInstanceOnHost -
#       This method deletes instance on host
#
# Input:
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub DeleteInstanceOnHost
{
   my $self = shift;
   my $vdrName = $self->{'name'};
   my $result;
   #
   # To delete an instance from host
   #  --instance -d vdrName
   # Delete a VDR instance
   #
   my $command =  NET_VDR . INSTANCE  . " -d ";
   $command = $command . " " . $vdrName;

   my $host = $self->{hostObj}->{hostIP};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to delete instance command:$command " .
                       "on host:$host " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetInstanceInfo -
#       This is to get information about this VDR Instance.
#       Example usage:
#       my $ret = $obj->GetInstanceInfo("Control Plane Active");
#       $ret will get Yes/No
#
# Input:
#       var in $self user wants to get.
#       Supported are:
#       VDR Instance:               vdr_test:3603003762
#       Vdr Name:                   vdr_test
#       Vdr Id:                     3603003762
#       Number of Lifs:             2
#       Number of Routes:           2
#       State:                      Enabled
#       Controller IP:              0.0.0.0
#       Control Plane Active:       No
#       Control Plane IP:           0.0.0.0
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetInstanceInfo
{
   my $self = shift;
   my $info = lc(shift);
   if (not defined $info) {
      $vdLogger->Error("Info to get is missing. Supported are" .
                        Dumper($self));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my ($command, $result);
   my $host = $self->{hostObj}->{hostIP};

   $command =  NET_VDR . INSTANCE . " -l " . $self->{'name'};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   my $hash = VDNetLib::Common::Utilities::ConvertRawDataToHash($result->{stdout});
   if ($hash->{'name'} !~ $self->{'name'}) {
      $vdLogger->Error("Got info of wrong vdr self:$self->{name} ".
                       "Got: $hash->{name}");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   $result = undef;;
   foreach my $key (keys %$hash) {
      my $value = $hash->{$key};
      $result->{lc($key)} = $value;
   }

   return $result->{$info};
}


########################################################################
#
# GetConnectionInfo -
#       This is to get information about VDR Connection Info
#       Example usage:
#       my $ret = $obj->GetConnectionInfo("vdrvmac");
#       $ret will get 00:50:56:fa:39:40
#
# Input:
#       var in $self->{connection} user wants to get.
#       Supported are:
#          dvsname      => undef,
#          vdrport      => undef,
#          vdrvmac      => undef,
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetConnectionInfo
{
   my $self = shift;
   my $info = lc(shift);
   if (not defined $info) {
      $vdLogger->Error("Info to get is missing. Supported are" .
                        Dumper($self->{connection}));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($self->{dirtybit}->{connectioninfo} == 1) {
      $self->ExtractConnectionInfo();
   }
   return $self->{connection}->{$info};
}

########################################################################
#
# GetTunableParams -
#       This is to get information about VDR Tunable Params
#       Example usage:
#       my $ret = $obj->GetTunableParams("defaultTtl");
#       $ret will 64
#       "defaultttl" will not work as its not in right case
#
# Input:
#       var in $self->{tunableparams} user wants to get.
#       Supported are
#       NOTE: They are case sensitive
#       enableFrag          => undef,
#       enableIcmpPMTU      => undef,
#       enableIcmpEcho      => undef,
#       enableBcastIcmpEcho => undef,
#       enableIcmpRateLimit => undef,
#       defaultTtl          => undef,
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetTunableParams
{
   my $self = shift;
   my $name = shift;

   if (not defined $name ||
       not defined $self->{tunableparams}->{$name}) {
      $vdLogger->Error("Wrong param statsname:$name passed. Supported are" .
                        Dumper($self->{tunableparams}));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($self->{dirtybit}->{tunableparams} == 1) {
      $self->ExtractTunableParams();
   }
   return $self->{tunableparams}->{$name};
}


########################################################################
#
# GetStats -
#       This is to get Stats about VDR
#       Example usage:
#       my $ret = $obj->GetStats("l3 packets rx");
#       $ret will 64
#
# Input:
#       var in $self->{tunableparams} user wants to get.
#       Supported are
#       L3 packets RX:               64
#       L3 packets TX:               0
#       L3 packets Forwarded:        0
#       L3 packets Consumed:         0
#       L3 packets Fragmented:       0
#       ARP REQ RX:                  0
#       ARP REQ TX:                  19
#       ARP RSP RX:                  0
#       ARP RSP TX:                  0
#       ARP REQ for Proxy RX:        0
#       ARP REQ for Proxy My IP RX:  0
#       ICMP ECHO RX:                0
#       ICMP ECHO TX:                0
#       TTL Zero Drops:              0
#       Bad Checksum Drops:          0
#       Packet Allocation Failure:   0
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetStats
{
   my $self = shift;
   my $statName = lc(shift);
   my ($command, $result);
   my $host = $self->{hostObj}->{hostIP};

   $command =  NET_VDR . INSTANCE . STATS . $self->{'name'};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   my $hash = VDNetLib::Common::Utilities::ConvertRawDataToHash($result->{stdout});
   $result = undef;
   foreach my $key (keys %$hash) {
      my $value = $hash->{$key};
      $result->{lc($key)} = $value;
   }

   if (not defined $statName ||
       not defined $result->{$statName}) {
      $vdLogger->Error("Wrong param statsname:$statName passed. Supported are" .
                        Dumper($self->{stats}));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return $result->{$statName};
}


########################################################################
#
# GetLIFInfo -
#       This is to get LIF information. i.e. var in LIF.pm class
#       user wants to get
#       Example usage:
#       my $ret = $obj->GetLIFInfo("LIF_NAME", "netmask");
#       $ret will get lifname
#       Supported are:
#      'name'
#      'dvsname'
#      'ip'
#      'netmask'
#      'type'
#      'networkId'
#      'designatedinstance'
#      'di ip'
#      'mode'
#      'state'
#
# Input:
#      lifname (mandatory)
#      info    (mandatory) -  var in LIF.pm class
#      host    (optional)
#
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetLIFInfo
{
   my $self    = shift;
   my $lifName = shift;
   my $info    = shift;
   my $host    = shift || $self->{hostObj}->{hostIP};
   my $result = FAILURE;

   if (not defined $lifName ||
       not defined $info ) {
      $vdLogger->Error("One or more param missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $self->{lifs}->{$lifName}) {
      $vdLogger->Error("No such lif exists on host:". $host);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $lifObj = $self->{lifs}->{$lifName};
   $result = $lifObj->ExtractLIFInfo();
   if (($result eq FAILURE) || (not defined $result->{$info})) {
      $vdLogger->Error("Info:$info is missing in " .
                        Dumper($lifName));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return $result->{$info};
}


########################################################################
#
# GetBridgeInfo -
#       This is to get bridge information.
# Input:
#      bridgeName (mandatory)
#      info       (optional)
#      host       (optional)
#
# Results:
#       Hash of bridge info or one particular value, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetBridgeInfo
{
   my $self       = shift;
   my $bridgeName = shift;
   my $info       = shift;
   my $host       = shift || $self->{hostObj}->{hostIP};
   my $result     = FAILURE;

   if (not defined $bridgeName) {
      $vdLogger->Error("Bridge name is missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $bridgeObjName = $host ."-" .$bridgeName;
   if (not defined $self->{bridges}->{$bridgeObjName}) {
      $vdLogger->Error("No such bridge exists on host:". $host);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $bridgeObj = $self->{bridges}->{$bridgeObjName};
   $result = $bridgeObj->ExtractBridgeInfo();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get bridge info for " .
                        Dumper($bridgeObjName));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (defined $info) {
      my $value = $bridgeObj->{'bridgeinfo'}->{$info};
      if (not defined $value) {
         $vdLogger->Error("Failed to get value for param $info in " .
                           Dumper($bridgeObjName));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      return $value;
   }
   return $bridgeObj->{'bridgeinfo'};
}


########################################################################
#
# GetMACInfo -
#       This is to get info from MAC address table.
# Input:
#      bridgeName (mandatory)
#      destAddress (optional, if the user wants to get one entry in the
#                   MAC address table)
#      info       (optional, if the user wants to get one particular field
#                  in one of the MAC address table entries)
#      host       (optional)
#
# Results:
#       Hash of MAC info or one particular value, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetMACInfo
{
   my $self        = shift;
   my $bridgeName  = shift;
   my $destAddress = shift;
   my $info        = shift;
   my $host        = shift || $self->{hostObj}->{hostIP};
   my $result      = FAILURE;

   my $bridgeObjName = $host ."-" .$bridgeName;
   if (not defined $self->{bridges}->{$bridgeObjName}) {
      $vdLogger->Error("No such bridge exists on host:". $host);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $bridgeObj = $self->{bridges}->{$bridgeObjName};
   $result = $bridgeObj->ExtractMACAddressTable($destAddress);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get entry(entries) in MAC address table for" .
                        Dumper($bridgeObjName));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (defined $destAddress) {
      if (defined $info) {
         my $value = $result->{$info};
         if (not defined $value) {
            $vdLogger->Error("Failed to get value for param $info in " .
                              "the MAC address table");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         return $value;
      }
      # This will be one level hash
      return $result;
   }
   # This is two level hash (the whole MAC address table)
   return $result;
}


########################################################################
#
# GetRouteInfo -
#       This is to get Route information. i.e. var in Route.pm class
#       user wants to get.
#       Example usage:
#       my $ret = $obj->GetRouteInfo("192.1.2.1", "flags");
#       $ret will get UGCIHFR as flags, depending on which flags are set
#       Supported are:
#      'destination'
#      'genmask'
#      'gateway'
#      'interface'
#      'flags'
#      'ref'
#      'origin'
#      'uptime'
#
# Input:
#      destination (mandatory)
#      info        (mandatory) -  var in Route.pm class
#      host        (optional)
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetRouteInfo
{
   my $self        = shift;
   my $destination = shift;
   my $info        = shift;
   my $host        = shift; # host on which to do this operation

   if (not defined $destination ||
       not defined $info ) {
      $vdLogger->Error("One or more param missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

      my $routeObjName = $host . "-" . $destination;
      if (not defined $self->{routes}->{$routeObjName}) {
         $vdLogger->Error("No such lif exists on host:". $host);
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      my $routeObj = $self->{routes}->{$routeObjName};
      my $result = $routeObj->ExtractRouteInfo();

      if (not defined $result->{$info}) {
         $vdLogger->Error("Info:$info is missing in " .
                           Dumper($routeObjName));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      return $result->{$info};
}


########################################################################
#
# GetARPInfo -
#       This is to get ARP information. i.e. var in ARP.pm class
#       user wants to get.
#       Example usage:
#       my $ret = $obj->GetARPInfo("192.1.2.1", "flags");
#       $ret will get SVPCN as flags, depending on which flags are set
#      'network'
#      'mac'
#      'interface'
#      'flags'
#      'expiry'
#
# Input:
#      network   (mandatory)
#      info      (mandatory) -  var in ARP.pm class
#      host      (optional)
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetARPInfo
{
   my $self    = shift;
   my $lifName = shift;
   my $info    = shift;
   my $host    = shift || $self->{hostObj}->{hostIP}; # host on which to do this operation
   my $result = FAILURE;

   if (not defined $lifName ||
       not defined $info ) {
      $vdLogger->Error("One or more param missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $self->{lifs}->{$lifName}) {
      $vdLogger->Error("No such lif exists on host:". $host);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $lifObj = $self->{lifs}->{$lifName};
   $result = $lifObj->ExtractARPInfo();
   if (($result eq FAILURE) || (not defined $result->{$info})) {
      $vdLogger->Error("Info:$info is missing in " .
                        Dumper($lifName));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return $result->{$info};
}


########################################################################
#
# SetTunableParams -
#       This is to set information about VDR Tunable Params
#       Example usage:
#       my $ret = $obj->SetTunableParams("defaultTtl");
#       $ret will 64
#       NOTE:"defaultttl" will not work as its not in right case
#
# Input:
#       var in $self->{tunableparams} user wants to set.
#       Supported are
#       NOTE: They are case sensitive
#       enableFrag          => undef,
#       enableIcmpPMTU      => undef,
#       enableIcmpEcho      => undef,
#       enableBcastIcmpEcho => undef,
#       enableIcmpRateLimit => undef,
#       defaultTtl          => undef,
#
# Results:
#       value of variable, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetTunableParams
{
   my $self  = shift;
   my $name  = shift;
   my $value = shift;
   my ($command, $result);

   if (not defined $name ||
       not defined $value ||
       not defined $self->{tunableparams}->{$name}) {
      $vdLogger->Error("Param missing or not supported. Supported params:" .
                        Dumper($self->{tunableparams}));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # To set any tunable VDR value
   # --instance -o setTunableParams -n <name> -v <value>
   #
   $command =  NET_VDR . INSTANCE . " -o setTunables " .
                  " -n $name " . " -v $value " . $self->{'name'};
   my $host = $self->{hostObj}->{hostIP};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{dirtybit}->{tunableparams} = 1;
   return SUCCESS;
}


########################################################################
#
# ExtractTunableParams
#       This is to extract VDR TunableParams from cli or some
#       other API.
#
# Input:
#
# Results:
#       A hash of VDR instance information
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ExtractTunableParams
{
   my $self = shift;
   my ($command, $result);
   my $host = $self->{hostObj}->{hostIP};

   $command =  NET_VDR . INSTANCE . " -o getTunables " . $self->{'name'};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   my $hash = VDNetLib::Common::Utilities::ConvertRawDataToHash($result->{stdout});

   # Update the object with the instance information
   foreach my $key (keys %$hash) {
      my $value = $hash->{$key};
      $self->{tunableparams}->{$key} = $value;
   }

   $self->{dirtybit}->{tunableparams} = 0;
}


########################################################################
#
# ExtractConnectionInfo -
#       This is to extract VDR Connection information from cli or some
#       other API.
#
# Input:
#
# Results:
#       A hash of VDR connection information
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ExtractConnectionInfo
{
   my $self = shift;
   my ($command, $result);
   my $host = $self->{hostObj}->{hostIP};

   $command =  NET_VDR . CONNECTION . " -l " . $self->{'name'};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   my $hash = $self->VDNetLib::Common::Utilities::ConvertHorizontalRawDataToHash(
                                                              $result->{stdout});

   # Update the object with the instance information
   foreach my $key (keys %$hash) {
      my $nestedHash = $hash->{$key};
      foreach my $nestedKey (keys %$nestedHash) {
         my $nestedValue = $nestedHash->{$nestedKey};
         $self->{connection}->{lc($nestedKey)} = $nestedValue;
      }
   }

   $self->{dirtybit}->{connectioninfo} = 0;
}


########################################################################
#
# ConfigureLIF -
#       This is to add/delete/setIP/setDI on LIF
#
# Input:
#       lifname: name of the lif
#       operation: operation to be done on that lif E.g.
#       add, delete, setDI, setIP, addstaticarp, deletestaticarp
# Results:
#       A hash of VDR instance information
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ConfigureLIF
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{lif};
   my $lifName   = $args{lifname};
   my $hostObj   = $args{host} || $self->{hostObj};
   my $host      = $hostObj->{hostIP};

   my $ret;

   if (not defined $lifName) {
      $vdLogger->Error("lifname is required parameter");
      VDSetLastError("EFAILED");
      return FAILURE;
   }


   $args{stafHelper} = $self->{stafHelper};
   if ($operation =~ /^add$/i) {
      # Create a LIF Obj
      $args{host} = $host;
      $args{vdrname} = $self->{'name'};
      my $lifObj = VDNetLib::Router::VDRComponents::LIF->new(%args);
      # Storing the lifs in $self->{lifs} with name HostIP - lifName
      $self->{lifs}->{$lifName} =  $lifObj;
      if ($lifObj eq FAILURE) {
         $vdLogger->Error("lif obj creation failed for " . Dumper(%args));
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $ret = $lifObj->AddLIFonHost();
      if ($ret eq FAILURE) {
         $vdLogger->Error("lif creation on host failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Created lif:" . $lifName .
                      " on VDR:" . $self->{'name'});
   } elsif ($operation =~ /(^delete$|^remove$)/i) {
     #
      # Find the LIF obj
      # Do the operation on this obj
      #
      $ret = $self->{lifs}->{$lifName}->DeleteLIFonHost();
      if ($ret eq FAILURE) {
         $vdLogger->Error("DeleteLIFonHost failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $self->{lifs}->{$lifName} = undef;
      delete $self->{lifs}->{$lifName};
      $vdLogger->Info("Deleted lif:" . $lifName .  " from VDR:" .
                      $self->{'name'});
   } elsif ($operation =~ /setdi/i)  {
      # if the host is not defined then make the self host
      # as the designated instance.
      if (not defined $args{host}) {
         $vdLogger->Error("host not given for SetLIFDI");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $ret = $self->{lifs}->{$lifName}->SetLIFDI(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("SetLIFDI failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } elsif ($operation =~ /setip/i) {
      $ret = $self->{lifs}->{$lifName}->SetLIFIP(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("SetLIFIP failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } elsif ($operation =~ /addstaticarp/i) {
      $ret = $self->{lifs}->{$lifName}->AddStaticARP(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("AddStaticARP failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } elsif ($operation =~ /deletestaticarp/i) {
      $ret = $self->{lifs}->{$lifName}->DeleteStaticARP(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("DeleteStaticARP failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } elsif ($operation =~ /addbridge/i) {
      $ret = $self->{lifs}->{$lifName}->AddBridge(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("AddBridge failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } elsif ($operation =~ /deletebridge/i) {
      $ret = $self->{lifs}->{$lifName}->DeleteBridge(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("DeleteBridge failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("unknown operation given to ConfigureLIF");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureBridge -
#       This is to add/delete on bridge
#
# Input:
#       lifname1: name of the lif1
#       lifname2: name of the lif1
#       operation: operation to be done
#
# Results:
#       Retruns SUCCESS if the operation is successful
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ConfigureBridge
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{operation}; # add, delete
   my $lifName1   = $args{lifname1};
   my $lifName2   = $args{lifname2};
   my $host      = $args{host} || $self->{hostObj}->{hostIP};
   my $ret;

   if ((not defined $lifName1) || (not defined $lifName2)) {
      $vdLogger->Error("lifname1 and lifname2 are required parameters");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $args{stafHelper} = $self->{stafHelper};
   my $bridgeName;
   if ($operation =~ /add/) {
      # Create a bridge
      $args{host} = $host;
      $args{vdrname} = $self->{'name'};
      my $bridgeObj = VDNetLib::Router::VDRComponents::Bridge->new(%args);
      # Storing the bridges in $self->{bridges} with name HostIP - bridgename
      if ($bridgeObj eq FAILURE) {
         $vdLogger->Error("lif obj creation failed for " . Dumper(%args));
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $ret = $bridgeObj->AddDeleteBridge(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Bridge creation on host failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      # Bridge creation is successful so construct the bridge name
      if ($lifName1->{lifnetworktype} =~ /vlan/i) {
         $bridgeName = "vlan-" . $lifName1->{lifnetworkid} . "-vxlan-" .
                       $lifName2->{lifnetworkid} . "-type-bridging";
      } else {
         $bridgeName = "vlan-" . $lifName2->{lifnetworkid} . "-vxlan-" .
                       $lifName1->{lifnetworkid} . "-type-bridging";
      }
      my $bridgeObjName = $host . "-" . $bridgeName;
      $bridgeObj->{bridgename} = $bridgeName;
      $self->{bridges}->{$bridgeObjName} =  $bridgeObj;
      $vdLogger->Info("Created bridge:" . $bridgeName .
                      " on VDR:" . $self->{'name'});
   } elsif ($operation =~ /delete/) {
      # Find the bridge obj and do the operation on this obj
      if ($lifName1->{lifnetworktype} =~ /vlan/i) {
         $bridgeName = "vlan-" . $lifName1->{lifnetworkid} . "-vxlan-" .
                       $lifName2->{lifnetworkid} . "-type-bridging";
      } else {
         $bridgeName = "vlan-" . $lifName2->{lifnetworkid} . "-vxlan-" .
                       $lifName1->{lifnetworkid} . "-type-bridging";
      }
      my $bridgeObjName = $host . "-" . $bridgeName;
      $ret = $self->{bridges}->{$bridgeObjName}->AddDeleteBridge(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Delete bridge failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $self->{bridges}->{$bridgeObjName} = undef;
      delete $self->{bridges}->{$bridgeObjName};
      $vdLogger->Info("Deleted bridge:" . $bridgeName .  " from VDR:" .
                      $self->{'name'});
   } else {
      $vdLogger->Error("Unsupported operation");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ResolveRoute -
#       This is to resolve routes on VDR
#
# Input:
#       dest ip: ip of destination
#       dest netmask: netmask of dest(optional)
#       host: host on which to do operation(optional)
#
# Results:
#       value - depending on how route is resolved
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ResolveRoute
{
   my $self = shift;
   my %args = @_;
   my $destIP      = $args{destip};
   my $destNetmask = $args{destnetmask};
   my $hostObj     = $args{host} || $self->{hostObj};
   my $host        = $hostObj->{hostIP};

   my ($command, $result);

   if (not defined $destIP) {
      $vdLogger->Error("destIP param missing" . Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # --route -o resolve -i destIp [-M destMask] vdrName
   # Resolve a route in a vdr instance
   #
   $command =  NET_VDR . ROUTE . " -i " . $destIP;
   if (defined $destNetmask) {
      $command = $command . " -M " . $destNetmask;
   }
   $command = $command . " " . $self->{'name'};

   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #TODO: find the resolved route and return it
   return SUCCESS;
}



########################################################################
#
# ConfigureRoute -
#       This is to add/delete routes on VDR
#
# Input:
#       route: add or delete a route
#       dest ip: ip of destination
#       dest netmask: netmask of dest
#       lifname: name of the lif
#       gateway ip: ip of gateway(optional)
#       host: host on which to do operation(optional)
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub ConfigureRoute
{
   my $self = shift;
   my %args = @_;
   my $operation   = $args{route}; # add, delete
   my $destination = $args{routedestination};
   my $hostObj     = $args{host} || $self->{hostObj};
   my $host        = $hostObj->{hostIP};


   if (not defined $operation ||
       ((defined $operation) && ($operation !~ /(add|delete)/i))) {
      $vdLogger->Error("operation not defined or unsupported value:" . $operation);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $destination) {
      $vdLogger->Error("destination param missing" . Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }


   $args{stafHelper} = $self->{stafHelper};
   my $routeObjName = $host ."-" .$destination;
   if ($operation =~ /^add$/i) {
      # Create a route Obj
      $args{host} = $host;
      $args{'vdrname'} = $self->{'name'};
      my $routeObj = VDNetLib::Router::VDRComponents::Route->new(%args);
      # Storing the routes in $self->{routes} with name HostIP - lifName
      $self->{routes}->{$routeObjName} =  $routeObj;
      if ($routeObj eq FAILURE) {
         $vdLogger->Error("route obj creation failed for " . Dumper(%args));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      my $ret = $routeObj->AddDeleteRoute(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("adding route failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   } elsif ($operation =~ /(^remove$|^delete$)/) {
     #
      # Find the router obj
      # Do the operation on this obj
      #
      my $ret = $self->{routes}->{$routeObjName}->AddDeleteRoute(%args);
      if ($ret eq FAILURE) {
         $vdLogger->Error("deleting route failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $self->{routes}->{$routeObjName} = undef;
      delete $self->{routes}->{$routeObjName};
   } else {
      $vdLogger->Error("unknown operation given to ConfigureRoute");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetControllerIP -
#       This is to set controller ip of VDR
#
# Input:
#       'controllerip'
#       host: host on which to do operation(optional)
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetControllerIP
{
   my $self         = shift;
   my $controllerIP = shift;
   my $host         = $self->{hostObj}->{hostIP};
   my ($command, $result);
   #
   # --instance -o setcIp -i controllerIp vdrName
   # Set the controller Ip address for a VDR
   #

   $command =  NET_VDR . INSTANCE . " -o setcIp -i $controllerIP " .
               $self->{'name'};

   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command: $command".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $instanceInfo = $self->GetInstanceInfo('controllerip');
   if ((defined $instanceInfo) && ($instanceInfo =~ /$controllerIP/)) {
      $vdLogger->Info("Successful set $controllerIP as controller ip on".
                      " VDR:".$self->{'name'});
      return SUCCESS;
   } else {
      return FAILURE;
   }
}


########################################################################
#
# SetConnection
#       This is to create or delete a connection between VDR Port and VDS
#
# Input:
#       connection - add/delete (mandatory)
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetConnection
{

   my $self      = shift;
   my %args      = @_;
   my $operation = $args{connection};
   if ($operation =~ /add/) {
      return $self->CreateConnectionVDRPortToVDS(%args);
   } else {
      return $self->DeleteConnectionVDRPortToVDS(%args);
   }
}


########################################################################
#
# CreateConnectionVDRPortToVDS
#       This is create a connection between VDR Port and VDS
#
# Input:
#       vmac (mandatory)
#       connection id (mandatory)
#       vdr port(mandatory)
#       dvs name(mandatory)
#       host: host on which to do operation(optional)
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub CreateConnectionVDRPortToVDS
{

   my $self    = shift;
   my %args    = @_;
   my $dvsname = $args{dvsname};
   my $vdrPortNumber = $args{vdrportnumber} || VDRPORT;
   my $connectionId = $args{connectionid} || int(rand(1000));
   my $vmac    = $args{vmac};
   my $hostObj = $self->{hostObj};
   my $host    = $hostObj->{hostIP};

   my ($command, $result);

   if (not defined $dvsname ||
       not defined $vdrPortNumber ||
       not defined $connectionId) {
      $vdLogger->Error("One or more params missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # --connection -a -s dvsName -p vdrPort -c cnId[-m vmac]
   # Create the connection of vdr port with dvs switch

   $command =  NET_VDR . CONNECTION . " -a -s " .$dvsname .
               " -p " . $vdrPortNumber . " -c " . $connectionId;

   if (defined $vmac) {
      $command = $command . " -m " . $vmac;
   }

   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                    Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully created connection of " . $self->{name} .
                   "and DVS: $dvsname on vdrport ". $vdrPortNumber);

   return SUCCESS;
}


########################################################################
#
# DeleteConnectionVDRPortToVDS
#       This is to delete a connection between VDR Port and VDS
#
# Input:
#       dvsname(mandatory)
#       host: host on which to do operation(optional)
#
# Results:
#       A hash of VDR instance information
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub DeleteConnectionVDRPortToVDS
{

   my $self    = shift;
   my %args    = @_;
   my $vdrPortNumber = $args{vdrportnumber} || VDRPORT;
   my $dvsname = $args{dvsname};
   my $hostObj = $self->{hostObj};
   my $host    = $hostObj->{hostIP};
   my ($command, $result);

   if (not defined $dvsname) {
      $vdLogger->Error("dvsname not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # --connection -d -s dvsName
   # Delete the existing connection of vdr port with dvs switch
   #

   $command =  NET_VDR . CONNECTION . " -d -s " .$dvsname;

   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully deleted connection of " . $self->{name} .
                   "and DVS: $dvsname");
   return SUCCESS;
}


########################################################################
#
# SetControlPlane
#       This is to activate/deactivate control plan of VDR
#
# Input:
#       operation - activate/deactivate
#
# Results:
#       "SUCCESS", in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetControlPlane
{

   my $self      = shift;
   my %args      = @_;
   my $operation = $args{controlplane};
   my ($command, $result);

   if ($operation =~ /setip/i) {
      return $self->SetResetControlPlaneIP(%args);
   } elsif ($operation =~ /^activate$/i) {
      $operation = " -a ";
   } else {
      $operation = " -d ";
   }
   #
   # --cplane -a
   # Activate the VDR control plane
   #

   $command =  NET_VDR . CONTROLPLANE . $operation;

   my $host = $self->{hostObj}->{hostIP};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $operation eq "-a" ? $operation = "Activat" : $operation = "Deactivat";
   $vdLogger->Info($operation ."ing Control plan for VDR " . $self->{name});
   return SUCCESS;
}



########################################################################
#
# SetResetControlPlaneIP
#       This is to set control plan IP of VDR
#
# Input:
#       controlplanip: ip address of control plane(mandatory)
#       host: host on which to do operation(optional)
#
# Results:
#       "SUCCESS", in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetResetControlPlaneIP
{

   my $self           = shift;
   my %args           = @_;
   my $operation      = $args{controlplane};
   my $controlplaneip = $args{controlplaneip};
   my $hostObj;
   my ($command, $result);

   if (not defined $operation) {
      $vdLogger->Error("controlplane operation is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($operation =~ /^setip$/i) {
      if (not defined $controlplaneip) {
         $hostObj        = $args{host} || $self->{hostObj};
         $controlplaneip = $hostObj->{hostIP};
      }
   } else {
      $controlplaneip = "0.0.0.0";
   }

   #
   # --cplane -o setcpIp -i controlPlaneIp vdrName
   # Set the Control Plane Ip address for a VDR
   #

   $command =  NET_VDR . CONTROLPLANE . " -o setcpIp -i " .
               $controlplaneip . " " . $self->{'name'};

   my $host = $self->{hostObj}->{hostIP};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully set control plan IP to $controlplaneip".
	           " on $host");
   return SUCCESS;
}


########################################################################
#
# SetVDRLogLevel
#       This is to set the log level of VDR on a host
#
# Input:
#       loglevel: set log level withing this range, 1-10 (mandatory)
#       host: host on which to do operation(optional)
#
# Results:
#       "SUCCESS", in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetVDRLogLevel
{

   my $self     = shift;
   my $loglevel = shift;
   my ($command, $result);

   if (not defined $loglevel || (defined $loglevel && $loglevel !~ /\d+/)) {
      $vdLogger->Error("loglevel is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # vsish -e set /system/modules/vdrb/loglevels/vdrb 10
   #

   $command =  "vsish -e set /system/modules/vdrb/loglevels/vdrb " . $loglevel;

   my $host = $self->{hostObj}->{hostIP};
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Successfully set vdrloglevel to $loglevel");
   return SUCCESS;
}


########################################################################
#
# DoVDRSetup
#       This is to set vdr environment for testing.
#
# Input:
#       host: host on which to do operation(optional)
#
# Results:
#       "SUCCESS", in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub DoVDRSetup  # TODO ************ Remove this when product is ready *********
{

   my $self  = shift;
   my ($result, $command);
   my $host  = $self->{hostObj}->{hostIP};

   # Disabling firewall
   my @commandArray =  ("vsish -e set /vmkModules/esxfw/globaloptions 0 1 1 1 1 ",
	                "vmkload_mod vdrb",
	                "esxcli system coredump network set -i 10.18.68.182 -v vmk0",
	                "esxcli system coredump network set -e true",
		);

   $command = "vmkload_mod -l | grep vdrb";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0)) {
	   $vdLogger->Trace("Failed to run command:$command on host:$host ".
	               Dumper($result));
      VDSetLastError("ESTAF");
   }

   foreach my $command (@commandArray) {
      $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Trace("Failed to run command:$command on host:$host ".
                          Dumper($result));
         VDSetLastError("ESTAF");
      }
   }

   return SUCCESS;
}



########################################################################
#
# CreateDestroyVDRPort
#       This is to create vdr port on VDS.
#       Note: This is part of VSM. VSM is suppose to create VDR Port
#       100 on VDS. THis API is a stop gap solution as VSM/VSE release
#       cycles are differnet than ESX and we need some way to test
#       the functionality
#
# Input:
#       host: host on which to do operation(optional)
#
# Results:
#       "SUCCESS", in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub CreateDestroyVDRPort
{
   my $self          = shift;
   my %args          = @_;
   my $operation     = $args{vdrport};
   my $dvsname       = $args{dvsname};
   my $vdrPortNumber = $args{vdrportnumber} || VDRPORT;
   my ($result);
   my $host = $self->{hostObj}->{hostIP};
   my $command;

   #
   # Create/Destroy VDR Port
   #
   if ($operation =~ /create/i) {
      $operation = "created";
      $command = "net-dvs -A -p $vdrPortNumber $dvsname";
   } else {
      $operation = "deleted";
      $command = "net-dvs -D -p $vdrPortNumber $dvsname";
   }

   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully $operation vdrport: $vdrPortNumber " .
                   "on DVS: $dvsname");
   return SUCCESS;
}



########################################################################
#
# SetTrunkPort
#       Set VXLAN, VLAN trunking on vdrport
#       Note: This is part of VSM. VSM is suppose to create VDR Port
#       100 on VDS. THis API is a stop gap solution as VSM/VSE release
#       cycles are differnet than ESX and we need some way to test
#       the functionality
#
# Input:
#       host: host on which to do operation(optional)
#
# Results:
#       "SUCCESS", in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetVDRPortProperty
{
   ###### Note: This method needs to be done using VIM API and in
   ###### Switch package, not VDR package.
   my $self           = shift;
   my %args          = @_;
   my $operation     = $args{vdrportproperty} || "enable";
   my $dvsname       = $args{dvsname};
   my $vdrPortNumber = $args{vdrportnumber} || VDRPORT;
   my $networkType   = $args{networktype} || "vxlan";
   my ($result);
   my $host = $self->{hostObj}->{hostIP};

   #
   # Create VDR Port and Enable trunk on it
   #
   my @commandArray =  ();

   #TODO: Do this using VIM API of VDS for vlan vxlan and sink
   if ($networkType =~ /vlan/i) {
      if ($operation =~ /enable/i) {
         push(@commandArray, 'net-dvs -v ";T"  -p' . "$vdrPortNumber $dvsname");
      } else {
         push(@commandArray, 'net-dvs -v ""  -p' . "$vdrPortNumber $dvsname");
      }
   }
   if($networkType =~ /vxlan/i) {
      if ($operation =~ /enable/i) {
         push(@commandArray, "net-dvs -s com.vmware.net.vxlan.trunk -p $vdrPortNumber $dvsname");
      } else {
         push(@commandArray, "net-dvs -u com.vmware.net.vxlan.trunk -p $vdrPortNumber $dvsname");
      }
   }
   if($networkType =~ /(sink|bridge)/i) {
      if ($operation =~ /enable/i) {
         push(@commandArray, "net-dvs --enableSink 1 -p $vdrPortNumber $dvsname");
      } else {
         push(@commandArray, "net-dvs --enableSink 0 -p $vdrPortNumber $dvsname");
      }
   }

   foreach my $command (@commandArray) {
      $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to run command:$command on host:$host ".
                          Dumper($result) . " from commandArray:" .
                          Dumper(@commandArray));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   $vdLogger->Info("Successfully set $networkType property on vdrport: $vdrPortNumber ".
                   "on DVS: $dvsname");
   return SUCCESS;
}

1;


