###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::Host::Netstack
#
#   This package allows to perform various operations on netstack instance.
#
###############################################################################

package VDNetLib::Host::Netstack;

use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use Net::IP;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Parsers;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

our $vmknic = "/sbin/esxcli network ip";

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Host::Netstack).
#
# Input:
#      hostObj	    - VC Object
#      netstackName - Name of the netstack instance.
#      stafHelper  - STAFHelper Object
#
# Results:
#      An object of VDNetLib::Host::Netstack package.
#
# Side effects:
#      None
#
###############################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self  = {};

   $self->{hostObj}	   = $args{hostObj};
   $self->{netstackName}   = $args{netstack};
   $self->{stafHelper}     = $args{stafHelper};

   bless($self, $class );

   return $self;
}


###############################################################################
#
# GetDefaultGateway --
#     Method to get the default gateway for the netstack.
#
# Input:
#     None
#
# Results:
#     On Success returns the ip of the default gateway
#     FAILURE otherwise.
#
# Side effects:
#     None
#
################################################################################

sub GetDefaultGateway
{
   my $self = shift;
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   if (not defined $instance) {
      VDSetLastError("ENODEF");
      $vdLogger->Error("Netstack name is not set!");
      return FAILURE;
   }
   if (not defined $host) {
      VDSetLastError("ENODEF");
      $vdLogger->Error("Host IP is not set!");
      return FAILURE;
   }
   my $result;
   my $command;
   $command = "esxcfg-route --netstack=$instance -l";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to get the routes through netstack $instance");
      VDSetLastError("EFAIL");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   my $parsedData = VDNetLib::Common::Parsers::ParseHorizontalTable(
      $result->{stdout}, undef, 1);
   if ($parsedData eq FAILURE) {
       return FAILURE;
   }
   foreach my $hashref (@$parsedData) {
      if ($hashref->{network} eq 'default') {
          return $hashref->{gateway};
      }
   }
   $vdLogger->Error("Unable to find default gateway for netstack $instance " .
                    "in: " . Dumper($parsedData));
   return FAILURE;
}


#######################################################################
#
# ReadComponent--
#     Method to read attributes of the netstack object.
#
# Input:
#     args: List of arguments that need to be read from the object.
#
# Results:
#     Result hash containing the response.
#
# Side effects:
#     None
#
########################################################################

sub ReadComponent
{
   my $self = shift;
   my $args = shift;
   my $result = {};
   my $resultHash = {
      'status' => undef,
      'response' => undef,
      'error' => undef,
      'reason' => undef,
   };
   my $readableAttributes = {'defaultgateway' => 'GetDefaultGateway'};
   foreach my $key (keys %$args) {
      if (grep {$_ eq $key} (keys %$readableAttributes)) {
         $key = lc($key);
         my $method = $readableAttributes->{$key};
         $result->{$key} = $self->$method();
      } else {
         $vdLogger->Error("Following attribute can not be read off of the " .
                          "netstack object: " . Dumper($key));
         $resultHash->{'status'} = "FAILURE";
         $resultHash->{'error'} = "Attempted to read an invalid attribute";
         $resultHash->{'reason'} = "$key can not be read off a netstack object";
         return $resultHash;
      }
   }
   $resultHash->{'status'} = 'SUCCESS';
   $resultHash->{'response'} = $result;
   return $resultHash;
}

###############################################################################
#
# GetNetstackProperties--
#     Method to get the properties of a tcpip instance.
#
# Input:
#     Instance: Name of the tcpip instance.
#
# Results:
#     On Success returns the properties of the tcpip instance.
#     FAILURE If getting instance properties fails.
#
# Side effects:
#     None
#
################################################################################

sub GetNetstackProperties
{
   my $self = shift;
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $str = "Unable to find a Netstack instance $instance";
   my $result;
   my $command;

   $command = "$vmknic netstack get -N $instance";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to get the properties of netstack $instance");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ($result->{stdout} =~/$str/i) {
      # instance doesn't exist, return FAILURE;
      return FAILURE;
   } else {
      return $result->{stdout};
   }
}


###############################################################################
#
# SetNetstackGateway--
#     Method to set the routing properties of netstack
#
# Input:
#    Operation - Operation which specifies whether to add or remove.
#    Gateway - Gateway to be set (required). If this is set to string
#       'different' then a gateway different then the already existing default
#       gateway will be set. e.g. if the existing gateway is set to 192.169.2.3
#       then the 24 bit netmask is used and the IP proceeding the existing IP
#       will be set on the interface, in this case it would be 192.169.2.4
#    network - Network address, (if not specified use the default one)
#
# Results:
#     On Success sets the gateway to the specified network.
#     FAILURE if setting gateway fails.
#
# Side effects:
#     None
#
################################################################################

sub SetNetstackGateway
{
   my $self = shift;
   my $operation = shift || "add";
   my $gateway = shift;
   my $network = shift || "default";
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if (not defined $gateway) {
      $vdLogger->Error("Gateway Address not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($operation !~ m/add|remove/i) {
      $vdLogger->Error("Invalid operation - $operation, valid operation ".
                       "are add,remove");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (lc($gateway) eq 'different') {
      my $existingGateway = $self->GetDefaultGateway();
      my @octets = split(/\./, $existingGateway);
      my $lastOctet = @octets[scalar(@octets) - 1];
      $lastOctet = (int($lastOctet) + 1) % 255;
      splice(@octets, -1, 1, $lastOctet);
      $gateway = join('.', @octets);
   }

   # check if the gateway to be set is for ipv4 or ipv6.
   if ($gateway =~ m/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/i) {
      $command = "$vmknic route ipv4 ";
   } else {
      $command = "$vmknic route ipv6 ";
   }
   if ( $operation =~ m/remove/i) {
      $command = "$command remove -g $gateway -n $network -N $instance";
   } else {
      $command = "$command add -g $gateway -n $network -N $instance";
   }
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to $operation gateway $gateway for $network for ".
                       "netstack $instance using command: $command");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("Gateway $operation to $gateway for $network for netstack ".
                    "$instance");
   return SUCCESS;
}


###############################################################################
#
# SetNetstackDNS--
#     Method to set the dns server for the netstack instance.
#
# Input:
#    Operation - to specify add/remove of dns.
#    dns server - IP/Name of the dns server.
#
# Results:
#     SUCCESS if setting dns suceeds.
#     FAILURE if setting dns fails.
#
# Side effects:
#     None
#
################################################################################

sub SetNetstackDNS
{
   my $self = shift;
   my $operation = shift || "add";
   my $dns = shift;
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if (not defined $dns) {
      $vdLogger->Error("DNS is not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($operation !~ m/add|remove/i) {
      $vdLogger->Error("Invalid operation - $operation, valid operation ".
                       "are add,remove");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }


   if ( $operation =~ m/remove/i) {
      $command = "$vmknic dns server remove -s $dns -N $instance";
   } else {
      $command = "$vmknic dns server add -s $dns -N $instance";
   }
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to $operation DNS $dns for ".
                       "netstack $instance");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("$operation DNS to $dns for netstack $instance Success");
   return SUCCESS;
}


###############################################################################
#
# SetCongestionControlAlgorithm--
#     Method to set the congestion control algorithm for the netstack instance.
#
# Input:
#    ccalgorithm - name of the cc algorithm to be set for the netstack instance.
#
# Results:
#     SUCCESS if setting cc algorithm is successful
#     FAILURE if setting cc algorithm fails.
#
# Side effects:
#     None
#
################################################################################

sub SetCongestionControlAlgorithm
{
   my $self = shift;
   my $ccAlgorithm = shift || "cubic";
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if ($ccAlgorithm !~ m/cubic|newreno/i) {
      $vdLogger->Error("Wrong cc algorithm - $ccAlgorithm ".
                       "Supported values are - cubic and newreno");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "$vmknic netstack set -c $ccAlgorithm -N $instance";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set cc algorithm to $ccAlgorithm for ".
                       "netstack $instance");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Checking whether value was set correctly
   if ($self->VerifyCongestionControlAlgorithm("default",
                                               $ccAlgorithm,
                                               $instance) eq FAILURE) {
      $vdLogger->Error("Failed to set cc algorithm to $ccAlgorithm for ".
                       "netstack $instance");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("CC Algorithm set to $ccAlgorithm for netstack $instance");
   return SUCCESS;
}


###############################################################################
#
# VerifyCongestionControlAlgorithm--
#     Method to verify the default/available Congestion Control Algorithms
#     present in a given netstack
#
# Input:
#     verifycc      - specify whether to check available or default CCA
#     ccname        - name of cc algorithm to verify
#
# Results:
#     SUCCESS if cc algorithm is verified successfully
#     FAILURE if any error
#
# Side effects:
#     None
#
################################################################################

sub VerifyCongestionControlAlgorithm
{
   my $self = shift;
   my $verifyCc = shift;
   my $ccName = shift;
   my $netstackName = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if ($verifyCc =~ m/default/i) {
      $verifyCc = "defaultcc";
   } elsif ($verifyCc =~ m/available/i) {
      $verifyCc = "availablecc";
   } else {
      $vdLogger->Error("Wrong cc type to verify - $verifyCc ".
                       "Supported values are - available and default");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($ccName !~ m/cubic|newreno/i) {
      $vdLogger->Error("Wrong cc algorithm name - $ccName ".
                       "Supported values are - cubic and newreno");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "vsish -e get /net/tcpip/instances/$netstackName/$verifyCc";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to retrieve cc algorithm for ".
                       "netstack $netstackName");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Verifying retrieved CCA value
   chomp($result->{stdout});
   if ($result->{stdout} !~ /$ccName/i) {
      $vdLogger->Error("Rerieved value of CCA: ".$result->{stdout}." is not ".
                       "the same as the value checked for: $ccName for ".
                       "netstack $netstackName");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("CC Algorithm verified successfully");
   return SUCCESS;
}


###############################################################################
#
# VerifyConnectionCongestionControlAlgorithm--
#     Method to verify the Congestion Control Algorithm that is being used by
#     a connection in a specified netstack
#
# Input:
#     verifyconnectioncc - name of cc algorithm to verify
#
# Results:
#     SUCCESS if cc algorithm is verified successfully
#     FAILURE if any error
#
# Side effects:
#     None
#
################################################################################

sub VerifyConnectionCongestionControlAlgorithm
{
   my $self = shift;
   my $ccName = shift;
   my $netstackName = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if ($ccName !~ m/cubic|newreno/i) {
      $vdLogger->Error("Wrong cc algorithm name - $ccName ".
                       "Supported values are - cubic and newreno");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Retrieving the connection list for the given netstack
   $result = $self->GetIpConnectionList();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to retrieve connection list for ".
                       "netstack $netstackName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Verifying retrieved conection value
   if ($result !~ /$ccName/i) {
      $vdLogger->Error("Rerieved value of connection list: ".$result.
                       "does not contain the CCA: $ccName for ".
                       "netstack $netstackName");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("CCA connection list verified successfully");
   return SUCCESS;
}


###############################################################################
#
# GetIpConnectionList--
#     Method to retrieve output of command:
#        esxcli network ip connection list
#
# Input:
#     param - either the netstack name, or the connection type [OPTIONAL]
#             Netstack name is retrieved from the test hash itself
#             Valid input params for connection type are:
#                "ip", "tcp", "udp" or "all"
#
# Results:
#     Command output is returned if retrieved successfully
#     FAILURE if any error
#
# Side effects:
#     None
#
################################################################################

sub GetIpConnectionList
{
   my $self = shift;
   my $param = shift;
   my $netstackName = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if ((defined $param) && ($param !~ m/ip|udp|tcp|all/i)) {
      $vdLogger->Error("Wrong connection type specified - $param ".
                       "Supported values are - ip, tcp, udp, all");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "$vmknic connection list";
   if (defined $param) {
      $command = $command." -t $param";
   } else {
      $command = $command." -N $netstackName";
   }

   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to retrieve connection list for ".
                       "netstack $netstackName");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


###############################################################################
#
# SetMAXConnections--
#     Method to set the max connection paramter for netstack instance.
#
# Input:
#    connections - parameter specifying the max connections for the netstack.
#
# Results:
#     SUCCESS if setting max connections is successful,
#     FAILURE if setting max connections fails,
#
# Side effects:
#     None
#
################################################################################

sub SetMAXConnections
{
   my $self = shift;
   my $connections = shift;
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if (not defined $connections) {
      $vdLogger->Error("Max connections parameter not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "$vmknic netstack set -m $connections -N $instance";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set max connections $connections for ".
                       "netstack $instance");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("maxConnections set to $connections for netstack ".
                    "$instance");
   return SUCCESS;
}

###############################################################################
#
# SetNetstackName--
#     Method to set the name for the netstack.
#
# Input:
#    name - name of the netstack to be set.
#
# Results:
#     SUCCESS if setting name for the netstack is successful,
#     FAILURE if setting name fails,
#
# Side effects:
#     None
#
################################################################################

sub SetNetstackName
{
   my $self = shift;
   my $name = shift;
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   if (not defined $name) {
      $vdLogger->Error("name to be set for netstack $instance not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "$vmknic netstack set -n $name -N $instance";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set netstack name to $name for ".
                       "netstack $instance");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("name set to $name for netstack ".
                    "$instance");
   return SUCCESS;

}


###############################################################################
#
# SetIPv6--
#     Method to set the ipv6 status for the netstack instance.
#
# Input:
#    operation - operation to specify the ipv6 enable/disable for netstack
#
# Results:
#     SUCCESS if enable/disable ipv6 for netstack is successful,
#     FAILURE if setting ipv6 status fails,
#
# Side effects:
#     None
#
################################################################################

sub SetIPv6
{
   my $self = shift;
   my $operation = shift || "Enable";
   my $instance = $self->{netstackName};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;
   my $enable;

   if ($operation !~ m/Enable|Disable/i) {
      $vdLogger->Error("Invalid value $operation, valid values ".
                       "Enable or Disable");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($operation =~ m/Enable/i) {
      $enable = "true";
   } else {
      $enable = "false";
   }

   $command = "$vmknic netstack set -i $enable -N $instance";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set ipv6 status to $enable for ".
                       "netstack $instance");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("IPv6 status set to $enable for netstack ".
                    "$instance");
   return SUCCESS;
}


1;
