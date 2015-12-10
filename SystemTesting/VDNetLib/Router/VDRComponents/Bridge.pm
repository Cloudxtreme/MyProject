########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Router::VDRComponents::Bridge;

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
use VDNetLib::Common::Utilities;

use constant NET_VDR        => "net-vdr ";
use constant BRIDGE         => "--bridge ";
use constant MAC_ADDR_TABLE => "--mac-address-table ";


########################################################################
#
# new -
#       This is the constructor module for Bridge
#
# Input:
#       A named parameter (hash) with following keys:
#       Mandatory keys:
#       host
#       stafHelper
#       'vdrName'
#       lif1 - Name of lif1
#       lif2 - Name of lif2
#
# Results:
#       An object of Bridge class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;

   if (not defined $args{'vdrname'} ||
       not defined $args{host} ||
       not defined $args{stafHelper} ||
       not defined $args{lif1} ||
       not defined $args{lif2}) {
      $vdLogger->Error("One or more param missing" . Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self;
   $self = {
      'stafHelper'      => $args{stafHelper},
      'host'            => $args{host},
      'vdrname'         => $args{'vdrname'},
      'lif1'            => $args{lif1},
      'lif2'            => $args{lif2},
      # Below info is filled at run time only. User cannot pass it
      'bridgename'      => undef,
      'bridgeinfo'      => undef,
   };

   bless ($self, $class);
}


########################################################################
#
# AddDeleteBridge -
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

sub AddDeleteBridge
{
   my $self      = shift;
   my %args      = @_;
   my $operation = $args{operation};
   my $lif1      = $self->{lif1};
   my $lif2      = $self->{lif2};
   my $host      = $self->{host};

   if ($operation =~ /add/) {
      $operation = " -a ";
   } else {
      $operation = " -d ";
   }


   my $vdrName = " " . $self->{'vdrname'};

   #
   # To add a bridge
   # --bridge -a -n lifName1 -n lifName2 vdrName
   #
   my $command =  NET_VDR . BRIDGE . $operation;
   $command = $command . " -n " . $lif1 . " -n " . $lif2 . " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
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

1;


