########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Router::VDRComponents::Route;

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

use constant NET_VDR => "net-vdr ";
use constant ROUTE => "--route ";


########################################################################
#
# new -
#       This is the constructor module for VDRComponents::Route class
#
# Input:
#       A named parameter (hash) with following keys:
#       Mandatory keys:
#       stafHelper
#       'vdrname'
#       destination - destination ip
#       genmask     - netmask
#       optional keys:
#       gateway     - gateway ip
#       interface   - lifName
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
   my %args  = @_;

   if (not defined $args{'vdrname'} ||
       not defined $args{host} ||
       not defined $args{stafHelper} ||
       not defined $args{routedestination} ||
       not defined $args{routegenmask} ||
       not defined $args{routegateway} || 
       not defined $args{lifname}) {
      $vdLogger->Error("One or more param missing" . Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self;
   $self = {
      'stafHelper'       => $args{stafHelper},
      'host'             => $args{host},
      'vdrname'          => $args{'vdrname'},
      'routedestination' => $args{routedestination}, # destination ip
      'routegenmask'     => $args{routegenmask},
      'routegateway'     => $args{routegateway},
      'lifname'          => $args{lifname},
   };

   return bless ($self, $class);
}


########################################################################
#
# AddDeleteRoute -
#       This method adds/deletes physical routes on the VDR
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

sub AddDeleteRoute
{
   my $self = shift;
   my %args = @_;
   my $operation= $args{route};
   my $destIP   = $self->{routedestination};
   my $destMask = $self->{routegenmask};
   my $gateway  = $args{routegateway}     || $self->{routegateway};
   my $lifName  = $args{lifname}     || $self->{lifname};
   my $host     = $self->{host};

   if ($operation =~ /add/) {
      $operation = " -a ";
   } else {
      $operation = " -d ";
   }

   my $vdrName = " " . $self->{'vdrname'};
   #
   # To add a route
   # --route -a -i destIp -M destMask [-g gwIp | -G lifName] vdrName
   # Add a route
   #
   my $command =  NET_VDR . ROUTE . $operation;
   $command = $command . " -i " . $destIP . " -M " . $destMask;

   if (defined $gateway) {
      $command = $command . " -g " . $gateway;
   }

   if (defined $lifName) {
      $command = $command . " -G " . $lifName;
   }
   $command = $command . " " . $vdrName;

   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result;

}


########################################################################
#
# ExtractRouteInfo -
#       This is to extract VDR Route information from cli or some
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

sub ExtractRouteInfo
{
   my $self      = shift;
   my $interface = $self->{lifname};
   my $host      = $self->{host};

   #
   # Generating command
   # net-vdr -R -l vdr_test
   #
   my $command =  NET_VDR . ROUTE . " -l " . $self->{'vdrname'};
   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to run command:$command on host:$host ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hash = VDNetLib::Common::Utilities::ConvertHorizontalRawDataToHash($result->{stdout});

   my $nestedHash = $hash->{$self->{routedestination}};
   my $ret;
   foreach my $nestedKey (keys %$nestedHash) {
      my $nestedValue = $nestedHash->{$nestedKey};
      $ret->{"route" . lc($nestedKey)} = $nestedValue;
   }
   return $ret;
}


1;


