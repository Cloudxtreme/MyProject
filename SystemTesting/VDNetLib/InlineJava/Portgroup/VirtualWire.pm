########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::InlineJava::Portgroup::VirtualWire;

#
# This package is a base class which stores attributes and
# implements methods relevant to virtual wire
#
use strict;
use warnings;

use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use constant FALSE => 0;


########################################################################
#
# new --
#     Contructore to create an object of
#     VDNetLib::InlineJava::Portgroup::VirtualWire
#
# Input:
#     named hash:
#        'name' : virtual wire id
#
# Results:
#     blessed reference to this class instance
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
   $self->{'name'} = $options{'name'};
   $self->{'type'} = "vwire";
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetPortConnection --
#     Method to get port connection object for the virtual wire
#
# Input:
#     inlineJavaVMObj : inline java VM object
#
# Results:
#     reference to portconnection object;
#     0, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPortConnection
{
   my $self              = shift;
   my %args              = @_;
   # For putting vmknic on virtualwire
   my $inlineJavaHostObj = $args{inlineJavaHostObj};
   # For putting vnic on virtualwire
   my $inlineJavaVMObj   = $args{inlineJavaVMObj};
   # We need anyone of the obj to work on at any given time
   my $inlineJavaObj     = $args{inlineJavaVMObj} || $args{inlineJavaHostObj};
   my $hostMOR;
   if (defined $inlineJavaHostObj ) {
      $hostMOR = $inlineJavaHostObj->{'hostMOR'};
   } elsif (defined $inlineJavaVMObj) {
      $hostMOR = $inlineJavaVMObj->{vmObj}->getHost($inlineJavaVMObj->{vmMOR});
   }
   if (not defined $hostMOR) {
      $vdLogger->Error("Not able to get hostMOR");
      return FALSE;
   }

   my $dvsPortConnection;
   eval {
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",
                                          $inlineJavaObj->{'anchor'});
      my $networkVector = $hostSystem->getAllHostNetwork($hostMOR);
      for (my $i = 0; $i < $networkVector->size(); $i++) {
         # for all the networks seen on the host, filter the dvpg networks
         my $value = $networkVector->get($i)->getValue();
         if ($value =~ /dvport/i) {
            my $dvpgObj =
               CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualPortgroup",
                                  $inlineJavaObj->{'anchor'});
            my $configInfo = $dvpgObj->getConfigInfo( $networkVector->get($i));
            my $key = $configInfo->getKey();
            my $name = $configInfo->getName();
            # from the filtered dvpg networks, filter the network that has
            # virtual wire id in the name
            # matchName is to prevent matching virtualwire-1 to virtualwire-10
	    my $matchName = $self->{name} . '-';
            if ($name =~ /$matchName/i) {
               my $dvs = $configInfo->getDistributedVirtualSwitch();
               my $dvsObj = CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualSwitch",
                                               $inlineJavaObj->{anchor});
               my $switchUuid = $dvsObj->getConfig($dvs)->getUuid();
               $dvsPortConnection =
                  CreateInlineObject("com.vmware.vc.DistributedVirtualSwitchPortConnection");
               $dvsPortConnection->setPortgroupKey($key);
               $dvsPortConnection->setSwitchUuid($switchUuid);
	       $self->{dvpgBacking} = $name;
               last;
            }
         }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in GetPortConnection. Please check vdNetInlineJava logs");
      return FALSE;
   }
   return $dvsPortConnection;
}
1;

