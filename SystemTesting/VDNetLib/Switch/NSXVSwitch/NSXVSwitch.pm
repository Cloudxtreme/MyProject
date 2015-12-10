########################################################################
#  Copyright (C) 2013 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::NSXVSwitch::NSXVSwitch;

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);

use VDNetLib::InlinePython::VDNetInterface qw(CallMethodWithKWArgs);

#Inheritance
use base 'VDNetLib::Root::Root';

########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     named hash parameter with following keys:
#     hostOpsObj  : reference to host object
#
# Results:
#     bless hash reference to instance of this class
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self = {};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} =
      'vmware.vsphere.esx.nsxvswitch.nsxvswitch_facade.NSXVSwitchFacade';
   bless $self;
   return $self;
}


########################################################################
#
# ConfigureUplinks --
#     Method to configure uplinks on the given switch
#
# Input:
#     action:        add/edit/delete
#     vmnicArrayRef: reference to vmnic/netadapter objects
#     executionType: api/cli
#     ipv4address  : ip address to configure on the uplink
#                    (for action:edit)
#
# Results:
#     SUCCESS, if the uplinks are configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureUplinks
{
   my $self = shift;
   my $operation = shift;
   my $uplinkAdapter = shift;
   my $packageName = blessed $self;
   my $pyObj;
   my $uplinks;
   $pyObj = $self->GetInlinePyObject();
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to create inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("Created pyObj, now executing configure_uplink method");
   my $refHash;
   $refHash->{operation} = $operation;
   my $result;
   eval {
      $result = CallMethodWithKWArgs($pyObj, 'configure_uplinks',
                                     {'operation' => $self->{id},
                                      'uplink' => $uplinks});
      if ($result eq FAILURE) {
          $vdLogger->Error("Failed to execute configure_uplink method in python class ".
                           "$self->{_pyclass}");
          VDSetLastError("ENOTDEF");
          return FAILURE;
      }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $packageName:\n". $@);
      return FAILURE;
   }
   $vdLogger->Info("Configured uplink properties successfully");
   return SUCCESS;
}

1;
