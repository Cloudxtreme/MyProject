########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Gateway::Vnic;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant attributemapping => {
   'addressgroups' => {
       'payload' => 'addressgroups',
       'attribute' => undef,
                 },
   'myaddressgroup' => {
       'payload' =>  'addressgroup',
       'attribute' => undef,
                 },
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Gateway::Vnic
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Gateway::Vnic
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{gateway} = $args{gateway};
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyEdgeObj = $self->{gateway}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('vnics.Vnics',
                                              $inlinePyEdgeObj,
                                             );
   $inlinePyObj->{id} = $self->{id};
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


########################################################################
#
# ProcessSpec --
#     Method to process the given array of VNIC spec
#     and convert them to a form required by Inline Python API
#
# Input:
#     Reference to an array of hash
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpec = shift;
   my @newArrayOfSpec;
   my @arrayofInterfaces;
   my $tempSpec;
   my $index = 1;
   foreach my $spec (@$arrayOfSpec) {
      my $interface;
      $interface->{name} = $spec->{name};
      $interface->{type} = $spec->{type} || "internal";
      $interface->{mtu} = $spec->{adapter_mtu} || "1600";
      $interface->{portgroupid} = $spec->{portgroup}->GetId();
      $interface->{index} = $spec->{index};
      if (defined $spec->{connected} && ($spec->{connected} == 0)) {
         $interface->{isconnected}   = "false";
      } else {
         # By default we want it connected
         $interface->{isconnected}   = "true";
      }
      if (defined $spec->{subinterface}) {
        $interface->{subinterfaces} = $self->ProcessSubInterfaces($spec->{subinterface});
      }
      my $arrayOfAddressGroups;
      my $addressgroup;
      if (defined $spec->{ipv4address}) {
         $addressgroup->{primaryaddress} = $spec->{ipv4address};
         $addressgroup->{subnetmask}     = $spec->{netmask};
      }
     # Adding prefix length for IPv6 addresses
      if (defined $spec->{ipv6addr}) {
         $addressgroup->{primaryaddress} = $spec->{ipv6addr};
         $addressgroup->{subnetprefixlength} = $spec->{prefixlen};
      }
      if (defined $addressgroup) {
         push(@$arrayOfAddressGroups, $addressgroup);
         $interface->{addressgroups} = \@$arrayOfAddressGroups;
      }
      push(@arrayofInterfaces, $interface);
      $index++;
   }
   $tempSpec->{vnics} = \@arrayofInterfaces;
   push(@newArrayOfSpec, $tempSpec);
   return \@newArrayOfSpec;
}

########################################################################
#
# ProcessSubInterfaces --
#     Method to process the given array of subinterface  spec
#     and convert them to a form required by Inline Python API
#
# Input:
#     Reference to an array of hash
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessSubInterfaces
{
   my $self = shift;
   my $subInterfaceSpec = shift;
   my @arrayOfSubInterfaces;
   foreach my $subInterfaces (@{$subInterfaceSpec}) {
      my $subInterface;
      $subInterface->{name} = $subInterfaces->{name};
      $subInterface->{tunnelid} = $subInterfaces->{tunnelid};
      if (defined $subInterfaces->{portgroup}) {
         $subInterface->{logicalswitchid} = $subInterfaces->{portgroup}->GetId();
      }
      if (defined $subInterfaces->{vlan}) {
         $subInterface->{vlanid} = $subInterfaces->{vlan};
      }
      if ((defined $subInterfaces->{connected}) &&
          ($subInterfaces->{connected} == 0)) {
           $subInterface->{isconnected} = "false";
      } else {
           $subInterface->{isconnected} = "true";
      }
      if (defined $subInterfaces->{mtu}) {
           $subInterface->{mtu} = $subInterfaces->{mtu};
      }
      my $arrayOfAddressGroups;
      my $addressgroup;
      $addressgroup->{primaryaddress} = $subInterfaces->{ipv4address};
      $addressgroup->{subnetmask}     = $subInterfaces->{netmask};
      push(@$arrayOfAddressGroups, $addressgroup);
      $subInterface->{addressgroups} = \@$arrayOfAddressGroups;
      push @arrayOfSubInterfaces, $subInterface;
   }
   return \@arrayOfSubInterfaces;
}

#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName

{
 return "gateway";
}

1;
