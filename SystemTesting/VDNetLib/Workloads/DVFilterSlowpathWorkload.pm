########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

###############################################################################
#
# package VDNetLib::Workloads::DVFilterSlowpathWorkload;
#
# This package is used to setup DVFilter Slowpath VM and provide some interfaces
# to use the functions of DVFilterSlowpath.
#    -- InitSlowpathVM
#    -- StartSlowpath1Agent / CloseSlowpath1Agent
#    -- StartSlowpath2UserspaceAgent / CloseSlowpath2UserspaceAgent
#    -- StartSlowpath2KernelAgent / CloseSlowpath2KernelAgent
#    -- RunFloodAttackSlowpath / RunStressRestartAgent
#
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
#
###############################################################################

package VDNetLib::Workloads::DVFilterSlowpathWorkload;

use FindBin qw($Bin);
use lib "$FindBin::Bin/../";
use strict;
use warnings;
use Storable 'dclone';
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);

use VDNetLib::DVFilterSlowpath::DVFilterSlowpath;

########################################################################
#
# new --
#      Method which returns an object of VDNetLib::DVFilterSlowpathWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::DVFilterSlowpathWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $self;

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return undef;
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'    => "testdvfilter",
      'managementkeys' => ['type','testdvfilter'],
      'componentIndex' => undef
      };

   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}
1;
