###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Host::VmknicManager;

#
# This package contains attributes and methods to configure a datastore
# on a Host
#
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

use VDNetLib::Common::GlobalConfig qw ($vdLogger);
use VDNetLib::TestData::TestConstants;
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler
                                            NewDataHandler);


use constant TRUE  => 1;
use constant FALSE => 0;
my %INLINELIB = (
   vc => "VDNetLib::InlineJava::VDNetInterface::com::vmware::vc",
);


########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::Host::VirtualNicManager
#
# Input:
#     anchor :
#
# Results:
#     Blessed reference of VDNetLib::InlineJava::Host::VirtualNicManager
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;

   my $self;
   $self->{'anchor'}    = $options{'anchor'};

   eval {
      $self->{'vmknicObj'} = CreateInlineObject("com.vmware.vcqa.vim.host.VirtualNicManager",
                                                $self->{'anchor'});
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::Host::" .
                       "VmknicManager obj");
      return FALSE;
   }

   bless $self, $class;

   return $self;
}


#############################################################################
#
# ModifyVmkService -
#     Method to enable/disable FTLogging/VMotion on a particular host.
#
# Input:
#     hostMor - Managed object referece for the host
#     service - Type of virtual nic(vmotion or faultToleranceLogging)
#               that needs to be enabled/disabled.
#     enable  - true for enabling FT/VMotion on a particular vNic otherwise false.
#     deviceid - deviceid of the vmknic for modifying the service
#
# Results:
#     True if service is enabled.
#     False if serive is not enabled.
#
# Side effects:
#     MethodFault, Exception
#
########################################################################

sub ModifyVmkService
{
   my $self   = shift;
   my %options = @_;
   my $service = $options{'service'};
   my $enable = $options{'enable'};
   my $hostMor = $options{'hostMor'};
   my $deviceid = $options{'device'};
   my $vnicObj = $self->{'vmknicObj'};
   my $result;
   my $nicType;
   if ($service eq "FTLOGGING"){
        $nicType = VDNetLib::TestData::TestConstants::FTLOGGING;
   }elsif($service eq "VMOTION") {
        $nicType = VDNetLib::TestData::TestConstants::VMOTION;
   }elsif($service eq "MANAGEMENT") {
        $nicType = VDNetLib::TestData::TestConstants::MANAGEMENT;
   }
   eval {
          my $array ;
          $array = $vnicObj->getVMKernalvNics($hostMor);
          my $vmknicobj = $self->GetHostVirtualNicObj(hostvirtualnicobjs => $array,
                                                      device_id          => $deviceid);
          $result =$vnicObj->modifyvmkNicType($hostMor,$nicType,$vmknicobj,$enable);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to change type ofthe VMKnic". $@);
      return FALSE;
   }
   return TRUE;
}


#############################################################################
#
# GetHostVirtualNicObj -
#     Method to get Host Virtual Nic Object.
#
# Input:
#     hostvirtualnicobjs - an array of host virtual Nic object
#     deviceid - deviceid of the vmknic for modifying the service
#
# Results:
#      return host virtual nic object that matches the deviceid.
#
# Side effects:
#     MethodFault, Exception
#
########################################################################

sub GetHostVirtualNicObj
{
   my $self = shift;
   my %options = @_;
   my $hostvirtualnicobj_arr = $options{'hostvirtualnicobjs'};
   my $device_id = $options{'device_id'};
   my $size = $hostvirtualnicobj_arr->length();
   my $index = $size-1;
   my $i;
   for($i=0; $i<=$index ;$i++){
      my $vmk = $hostvirtualnicobj_arr->[$i]->getDevice();
      if ($vmk =~ m/$device_id/){
          return $hostvirtualnicobj_arr->[$i];
      }
   }
}
1;

