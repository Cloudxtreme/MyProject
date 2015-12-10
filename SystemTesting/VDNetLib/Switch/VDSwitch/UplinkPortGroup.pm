#######################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::VDSwitch::UplinkPortGroup;

#
# This package is responsible for handling all the interaction with
# VMware VDS uplink portgroup
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Switch::VDSwitch::DVPortGroup);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );
use VDNetLib::InlineJava::Portgroup::DVPortgroup;
use Data::Dumper;

#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::Switch::VDSwitch::UplinkPortGroup.
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'DVPGName'  : name of the DV portgroup (Required)
#      'switchObj' : Object of the switch(vDS) to which the given portgroup
#                    belongs (Required)
#      'stafHelper': reusing the staf helper of vc
#
# Results:
#      An object of VDNetLib::Switch::VDSwitch::DVPortgroup, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#######################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $switchObj  = $args{switchObj};
   my $DVPGName   = $args{DVPGName};
   my $stafHelper = $args{stafHelper};
   my $self;

   if (not defined $switchObj) {
      $vdLogger->Error("vds switch object not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $DVPGName) {
      $vdLogger->Error("vds uplink portgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{pgName}     = $DVPGName;
   $self->{stafHelper} = $stafHelper;
   $self->{switchObj}  = $switchObj;

   bless($self,$class);
   return $self;
}

1;