########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Router::VDRComponents::LIF;

use strict;
use warnings;
use Data::Dumper;

# Load modules
use FindBin;
use lib "$FindBin::Bin/../../../";
use lib "$FindBin::Bin/../../../VDNetLib/CPAN/5.8.8/";

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack );

use constant NET_VDR => " net-vdr ";
use constant LIF     => " --lif ";
use constant ARP     => " --nbr ";
use constant BRIDGE         => " --bridge ";
use constant MAC_ADDR_TABLE => " --mac-address-table ";

use VDNetLib::Common::Utilities;

########################################################################
#
# new -
#       This is the constructor module for LIF
#
# Input:
#       A named parameter (hash) with following keys:
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self;

   if ((not defined $args{lifname}) ||
       (not defined $args{host}) ||
       (not defined $args{vdrname}) ||
       (not defined $args{dvsname}) ||
       (not defined $args{networktype}) ||
       (not defined $args{lifnetworkid}) ||
       (not defined $args{stafHelper})) {
      $vdLogger->Error("One or more param missing:" . Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self = {
      'stafHelper'            => $args{stafHelper},
      'host'                  => $args{host},
      'vdrname'               => $args{'vdrname'},
      'lifname'               => $args{lifname},
      'dvsname'               => $args{dvsname},
      'lifip'                 => $args{lifip},
      'lifnetmask'            => $args{lifnetmask},
       # Network type is vxlan or vlan
      'lifnetworktype'        => $args{networktype},
       # id of vxlan or vlan network
      'lifnetworkid'          => $args{lifnetworkid},
      'lifdesignatedinstanceip'=> $args{lifdesignatedinstanceip},
      'lifmode'               => undef,
      'lifstate'              => undef,
      'arpnetwork'            => undef,
      'bridgedto'             => undef, # array of ptr to other lifs
   };

   bless ($self, $class);
}


########################################################################
#
# AddLIFonHost -
#       This method adds lif on host
#
# Input:
#       ip: ip of lif
#       netmask: netmask of lif
#       designatedip: designated ip of lif
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub AddLIFonHost
{
   my $self = shift;
   my %args = @_;
   my $ip      = $args{lifip}      || $self->{lifip};
   my $netmask = $args{lifnetmask} || $self->{lifnetmask};
   my $DI_IP   = $args{lifdesignatedinstanceip} || $self->{lifdesignatedinstanceip};

   my $host = $self->{host};
   my $operation = " -a ";
   my $lifName = " -n " . $self->{lifname};
   my $vdrName = " " . $self->{'vdrname'};

   #
   # To add a lif
   # --lif -a -n name -s dvsName [-i Ip -M Mask] -t [vlan | vxlan]
   # -v id [-D designateIp] vdrName
   #
   my $command =  NET_VDR . LIF . $operation . $lifName;
   $command = $command . " -s " . $self->{dvsname};
   if ((defined $ip) && (defined $netmask)) {
      $command = $command . " -i " . $ip . " -M " . $netmask;
   }
   $command = $command . " -t " . $self->{lifnetworktype} . " -v " . $self->{lifnetworkid};
   if (defined $DI_IP) {
      $command = $command . " -D " . $DI_IP;
   }
   if ($self->{lifnetworktype} =~ /vxlan/i) {
      $command = $command . " -D 239.0.0.1";
   }
   $command = $command . " " . $vdrName;


   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # Update the obj also on success.
   $self->{lifip} =  $ip;
   $self->{lifnetmask} = $netmask;
   $self->{lifdesignatedinstanceip} = $DI_IP;
   return SUCCESS;

}


########################################################################
#
# DeleteLIFonHost -
#       This method deletes lif on host
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

sub DeleteLIFonHost
{
   my $self = shift;
   my $host = $self->{host};
   my $lifName = " -n " . $self->{lifname};
   my $vdrName = " " . $self->{vdrname};
   my $operation = " -d ";

   # --lif -d -n lifName -s dvsName vdrName
   # Delete a LIF
   my $command =  NET_VDR . LIF . $operation . $lifName;
   $command = $command . " -s " . $self->{dvsname};
   $command = $command . " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;

}


########################################################################
#
# SetLIFDI -
#       This method sets lif designated ip
#
# Input:
#       designatedip: designated ip of lif
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetLIFDI
{
   my $self = shift;
   my %args = @_;
   my $DI_host = $args{host};
   my $DI_IP   = $args{lifdesignatedinstanceip} || $DI_host->{hostIP};

   if (not defined $DI_IP) {
      $vdLogger->Error("Designated IP missing in input param:" .
                        Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $host = $self->{host};
   my $operation = " -o setDI ";
   my $lifName = " -n " . $self->{lifname};
   my $vdrName = " " . $self->{vdrname};

   #
   # --lif -o setDI -n lifName -D [designated Ip] vdrName
   # Set/unset Designated Instance for LIF
   #
   my $command =  NET_VDR . LIF . $operation . $lifName;
   $command = $command . " -D " . $DI_IP;
   $command = $command . " " . $vdrName;

   # Update the obj also on success.
   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully set LIF DI $DI_IP on $lifName of $vdrName");
   $self->{lifdesignatedinstanceip} = $DI_IP;
   return SUCCESS;

}


########################################################################
#
# SetLIFIP -
#       This method sets lif ip and netmask
#
# Input:
#       ip: ip of lif
#       netmask: netmask of lif
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetLIFIP
{
   my $self = shift;
   my %args = @_;
   my $ip      = $args{lifip}      || $self->{lifip};
   my $netmask = $args{lifnetmask} || $self->{lifnetmask};

   if (not defined $ip ||
       not defined $netmask) {
      $vdLogger->Error("IP or netmask missing in input param:" .
                        Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $host = $self->{host};
   my $lifName = " -n " . $self->{lifname};
   my $vdrName = " " . $self->{vdrname};
   my $operation = " -o setIp ";

   #
   # --lif -o setIp -n lifName  [-i Ip -M Mask] vdrName
   # Set/unset Ip address for a LIF
   #
   my $command =  NET_VDR . LIF . $operation . $lifName;
   $command = $command . " -i " . $ip . " -M " . $netmask;
   $command = $command . " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # Update the obj also on success.
   $self->{lifip} = $ip;
   $self->{lifnetmask} = $netmask;
   $vdLogger->Info("Successfully set LIFIP $ip on $lifName of $vdrName");
   return SUCCESS;

}


########################################################################
#
# ExtractLIFInfo -
#       This is to extract VDR LIF information from cli or some
#       other API.
#
# Input:
#
# Results:
#       SUCCESS, in case everything goes well
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub ExtractLIFInfo
{
   my $self = shift;
   my $lifName = $self->{lifname};
   my $host = $self->{host};

   #
   # LIF information on all hosts should be same, as its per VDR so just get it
   # from first host in the array.
   #
   #
   # Generating command
   # net-vdr -I -l vdr_test | grep -ri -A 8 LIF_NAME
   #
   my $command =  NET_VDR . LIF . " -l " . $self->{'vdrname'} .
                  " | grep -ri -A 8 -B 1 " . $lifName;
   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hash = VDNetLib::Common::Utilities::ConvertRawDataToHash($result->{stdout});
   #
   # TODO: Split the Ip(Mask):            192.1.2.4(255.255.255.255)
   # into ip and netmask
   #
   # Update the object with the instance information
   my $ret;
   foreach my $key (keys %$hash) {
      my $value = $hash->{$key};
      $ret->{lc("lif" . $key)} = $value;
   }

   return $ret;
}


########################################################################
#
# AddStaticARP -
#       This method adds static ARPs on the LIF
#
# Input:
#       destination: destination ip
#       netmask: netmask of lif
#       di ip: designated instance ip
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub AddStaticARP
{

   my $self     = shift;
   my %args     = @_;

   if ((not defined $args{arpnetwork}) ||
       (not defined $args{arpmac})) {
      $vdLogger->Error("One or more param missing" . Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $destNetwork   = $args{arpnetwork};
   my $destMac = $args{arpmac};
   my $lifName  = $self->{lifname};
   my $host     = $self->{host};
   my $vdrName  = $self->{'vdrname'};

   #
   # To add a ARP
   #  --nbr -a -i destIp -m destMac -n lifName vdrName
   # Add a neighbor (a.k.a ARP) entry
   #
   my $command =  NET_VDR . ARP . " -a " . " -i " . $destNetwork .
                  " -m " . $destMac . " -n " .  $lifName . " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully set staticARP $destMac for $destNetwork ".
                   "on LIF $lifName of $vdrName");
   $self->{arpnetwork} = $destNetwork;
   return SUCCESS;

}


########################################################################
#
# DeleteStaticARP -
#       This method deletes static ARPs on the LIF
#
# Input:
#       destination: destination ip
#       netmask: netmask of lif
#       di ip: designated instance ip
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub DeleteStaticARP
{
   my $self     = shift;
   my $destNetwork   = $self->{arpnetwork};
   my $lifName  = $self->{lifname};
   my $host     = $self->{host};
   my $vdrName  = $self->{'vdrname'};

   #
   # To add a ARP
   # --nbr -d -i destIp -n lifName vdrName
   # Delete a neighbor (a.k.a ARP) entry
   #
   my $command =  NET_VDR . ARP . " -d " . " -i " . $destNetwork .
                  " -n " .  $lifName . " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully delete staticARP for $destNetwork ".
                   "on LIF $lifName of $vdrName");

   return SUCCESS;
}



########################################################################
#
# ExtractARPInfo -
#       This is to extract VDR ARP information from cli or some
#       other API.
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

sub ExtractARPInfo
{
   my $self      = shift;
   my $interface = $self->{lifname};
   my $host      = $self->{host};

   #
   # ARP information on all hosts should be same, as its per VDR
   # so just get it from first host in the array.
   #

   #
   # Generating command
   # net-vdr -R -l vdr_test
   #
   my $command =  NET_VDR . ARP . " -l " . $self->{'vdrname'};
   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hash = VDNetLib::Common::Utilities::ConvertHorizontalRawDataToHash($result->{stdout});

   my $nestedHash = $hash->{$self->{network}} if defined $hash;
   my $ret;
   foreach my $nestedKey (keys %$nestedHash) {
      my $nestedValue = $nestedHash->{$nestedKey};
      $ret->{"arp" . lc($nestedKey)} = $nestedValue;
   }
   return $ret;
}


########################################################################
#
# AddBridge -
#       This method adds/deletes a bridge
#
# Input:
#       operation: add or delete
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub AddBridge
{
   my $self        = shift;
   my %args        = @_;
   my $operation   = $args{lif};
   my $bridgetolif = $args{bridgeto};
   my $thislif     = $self->{lifname};
   my $host        = $self->{host};
   my $vdrName     = " " . $self->{'vdrname'};
   my $bridgeName  = $thislif . "-" . $bridgetolif;
   my $bridgeOperation;
   my $bridgeId    = 100;

   $operation = " -a ";
   $bridgeOperation = "addBridge";

   #
   # To add a bridge
   #
   my $command =  NET_VDR . BRIDGE . $operation;
   $command = $command . " -B " . $bridgeName .  " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $command =  NET_VDR . LIF . " -o " . $bridgeOperation . " -B " .
               $bridgeName . " -r " . $bridgeId . " -n " . $thislif .
	       $vdrName;
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $command =  NET_VDR . LIF . " -o " . $bridgeOperation . " -B " .
               $bridgeName . " -r " . $bridgeId . " -n " . $bridgetolif.
	       $vdrName;
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("Successfully $operation lif:$thislif and ".
                   "lif:$bridgetolif of $vdrName");
   # Construct the bridge name in the caller of this method in Route.pm
   # eg: vlan-401-vxlan-5392-type-bridging and store it in the bridge object
   return SUCCESS;
}


########################################################################
#
# DeleteBridge -
#       This method deletes a bridge
#
# Input:
#       operation: add or delete
#
# Results:
#       SUCCESS, in case of success
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub DeleteBridge
{
   my $self        = shift;
   my %args        = @_;
   my $operation   = $args{lif};
   my $bridgetolif = $args{bridgeto};
   my $thislif     = $self->{lifname};
   my $host        = $self->{host};
   my $vdrName     = " " . $self->{'vdrname'};
   my $bridgeName  = $thislif . "-" . $bridgetolif;
   my $bridgeOperation;
   my $bridgeId    = 100;

   $operation = " -d ";
   $bridgeOperation = "delBridge";

   my $command =  NET_VDR . LIF . " -o " . $bridgeOperation . " -B " .
               $bridgeName . " -r " . $bridgeId . " -n " . $thislif .
	       $vdrName;
   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $command =  NET_VDR . LIF . " -o " . $bridgeOperation . " -B " .
               $bridgeName . " -r " . $bridgeId . " -n " . $bridgetolif.
	       $vdrName;
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $command =  NET_VDR . BRIDGE . $operation;
   $command = $command . " -B " . $bridgeName .  " " . $vdrName;

#   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
#   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
#      $vdLogger->Error("Failed to run command:$command on host:$host ".
#                       Dumper($result));
#      VDSetLastError("ESTAF");
#      return FAILURE;
#   }


   $vdLogger->Info("Successfully $operation lif:$thislif and ".
                   "lif:$bridgetolif of $vdrName");
   # Construct the bridge name in the caller of this method in Route.pm
   # eg: vlan-401-vxlan-5392-type-bridging and store it in the bridge object
   return SUCCESS;
}


########################################################################
#
# ExtractBridgeInfo -
#       This is to extract bridge information from cli.
#
# Input:
#
# Results:
#       Returns SUCCESS and updates bridge obj with the bridge info
#       or "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ExtractBridgeInfo
{
   my $self       = shift;
   my $bridgeName = $self->{'bridgename'};
   my $host       = $self->{host};
   my ($command, $result);

   #
   # Generating command
   # net-vdr -b -l vdr_test
   #
   $command =  NET_VDR . BRIDGE . " -l " . $self->{'vdrname'} .
               " | grep -ri -A 18 " . $bridgeName;
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hash = VDNetLib::Common::Utilities::ConvertRawDataToHash($result->{stdout});
   foreach my $key (keys %$hash) {
      $self->{'bridgeinfo'}->{lc($key)} = $hash->{$key};
   }

   return SUCCESS;
}


########################################################################
#
# ExtractMACAddressTable -
#       This is to extract MAC address table using cli.
#
# Input:
#       destAddress: MAC address entry to retirieve from the table
#
# Results:
#       A hash of MAC address table
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ExtractMACAddressTable
{
   my $self        = shift;
   my $destAddress = shift;
   my $bridgeName = $self->{'bridgename'};
   my $host        = $self->{host};
   my ($command, $result);

   #
   # Generating command
   # net-vdr -b -l vdr_test
   #
   $command =  NET_VDR . MAC_ADDR_TABLE . " -b " . $self->{'vdrname'} .
               " | sed -n '/" . $bridgeName . "/,/vlan-/p' | sed '\$d'";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hash = VDNetLib::Common::Utilities::ConvertHorizontalRawDataToHash($result->{stdout});
   if ($hash eq FAILURE) {
      $vdLogger->Error("Couldn't process the output");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ((defined $destAddress) && (defined $hash->{$destAddress})) {
      my $nestedHash = $hash->{$destAddress};
      return $nestedHash;
   }
   return $hash;
}


########################################################################
#
# GetBridgeName -
#       This is to get the bridge name of the bridge between this and
#       other lif
#
# Input:
#       bridgeto: lifObj/lifname to which this lif is bridged
#
# Results:
#       bridgename, in case of success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetBridgeName
{
   # TODO: Yet to be implemented.
   return SUCCESS;
}
1;


