#######################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::OpenVswitch::Port;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Switch::Port::Port);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );

use constant NVS_VS_CTL => "nsx-dbctl-internal";

#######################################################################
#
# new --
#      Constructur to create an instance of this class
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'portid'    : port if
#      'switchObj' : open vswitch object.
#      'stafHelper': Reference to the staf helper object.
#
# Results:
#      An object of VDNetLib::Switch::OpenVswitch::Port, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;

   #
   # Create an instance of parent class and inherit
   # all attributes
   #
   my $self = VDNetLib::Switch::Port::Port->new(%args);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::TestSesn" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# GetOFPort --
#     Method to get ofport number for the given port
#
# Input:
#     None
#
# Results:
#     ofport, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetOFPort
{
   my $self = shift;
   my $command = NVS_VS_CTL . " get interface " . $self->{portid} . " ofport";
   my $hostIP = $self->{switchObj}{hostOpsObj}{hostIP};
   my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                     $command);

   $vdLogger->Debug("Get OFPort on $hostIP: $command");
   if (($result->{rc} != 0) || ($result->{exitCode})) {
      $vdLogger->Error("Failed to add flow on $hostIP");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $result->{stdout};
}
1;
