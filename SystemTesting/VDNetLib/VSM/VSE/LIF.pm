########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::VSE::LIF;

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

use constant attributemapping => {};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::VSE::LIF
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::VSE::LIF
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
   $self->{vse} = $args{vse};
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
   my $inlinePyEdgeObj = $self->{vse}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('interfaces.Interfaces',
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
#     Method to process the given array of LIF spec
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
   foreach my $spec (@$arrayOfSpec) {
      my $interface;
      $interface->{name} = $spec->{name};
      $interface->{mtu}  = $spec->{adapter_mtu} || "1500";
      $interface->{type} = $spec->{type} || "internal";
      $interface->{connectedtoid} = $spec->{portgroup}->GetId();
      if (defined $spec->{connected} && ($spec->{connected} == 0)) {
         $interface->{isconnected}   = "false";
      } else {
	      # by default we want it connected
         $interface->{isconnected}   = "true";
      }
      if (defined $spec->{addressgroup}) {
	      my $inputArrayRef = $spec->{addressgroup};
         my $arrayOfAddressGroups;
         my $addressgroup;
         my $addressType;
         if(scalar (@$inputArrayRef)== 1) {
            $addressType = "primary";
	      }
	      foreach my $groupHash (@$inputArrayRef){
            $addressgroup->{addresstype} = $groupHash->{addresstype} || $addressType;
            $addressgroup->{primaryaddress} = $groupHash->{ipv4address};
            $addressgroup->{subnetmask}     = $groupHash->{netmask};
	            if (not defined $addressgroup->{addresstype}) {
                  $vdLogger->Error("addressType not passed in addressgroup");
      	         VDSetLastError("ENOTDEF");
	               return FAILURE;
	            }
            push(@$arrayOfAddressGroups, $addressgroup);
	      }
         $interface->{addressgroups} = \@$arrayOfAddressGroups;
      }
      push(@arrayofInterfaces, $interface);
   }
   $tempSpec->{interfaces} = \@arrayofInterfaces;
   push(@newArrayOfSpec, $tempSpec);
   return \@newArrayOfSpec;
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
 return "vse";
}


1;
