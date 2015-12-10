########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Controller::VXLANControllerOperations;
#
# This package allows to perform various operations on an VXLAN controller
#

use strict;
use warnings;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;



########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Contoller::VXLANControllerOperations).
#
# Input:
#      controllerIP : IP address of the controller.
#               (Required)
#
# Results:
#      An object of VDNetLib::Contoller::VXLANControllerOperations package.
#
# Side effects:
#      None
#
########################################################################

sub new {

   my $class = shift;
   my $controllerIP = shift;

   if (not defined $controllerIP) {
      $vdLogger->Error("Controller IP not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $self = {
      # IP address of Controller
      controllerIP => $controllerIP,
   };
   bless($self,$class);
   return $self;
}


###############################################################################
#
# CheckVNIMacOnController --
#      This method will check the VXLAN MAC on controller.
#
# Input:
#      VNI               : VXLAN ID
#      refObjVtep        : reference to vxlan vmknic object
#      refArrayObjVnic   : reference to an array of vnic objects
#
#
# Results:
#      "SUCCESS", if the check MAC address is successfull.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
###############################################################################

sub CheckVNIMacOnController
{
   my $self              = shift;
   my %args              =@_;
   my $vni               = $args{checkvnimaconcontroller};
   my $refObjVtep        = $args{vtep};
   my $refArrayObjVnic   = $args{adatper};
   my $result;

   # To Do
   my $controllerIP = $self->{controllerIP};
   $vdLogger->Info("The controller IP is $controllerIP");
   $vdLogger->Info("The vni is $vni");
   return SUCCESS;
}
1;
