########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::IPPool;

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
#     VDNetLib::NVP::NVPOperations
#
# Input:
#     ip : ip address of the nvp controller
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NVP::NVPOperations;
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
   $self->{vsm} = $args{vsm};
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('ipam_address_pool.IPAMAddressPool',
                                               $inlinePyVSMObj,
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
#     Method to process the given array of ippoolspec
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
   foreach my $spec (@$arrayOfSpec) {
      my $tempSpec;
      my $ippool;
      $ippool->{name} = $spec->{name};
      $ippool->{gateway}  = $spec->{gateway};
      $ippool->{prefixlength}  = $spec->{prefixlength};
      if (defined $spec->{ipranges}) {
	 my $inputArrayRef = $spec->{ipranges};
         my $arrayOfIPRanges;
	 foreach my $iprange (@$inputArrayRef){
            my ($startaddress, $endaddress) = split('-', $iprange);
            my $iprangeSpec;
            $iprangeSpec->{startaddress} = $startaddress;
            $iprangeSpec->{endaddress} = $endaddress;
            push(@$arrayOfIPRanges, $iprangeSpec);
	 }
         $ippool->{ipranges} = \@$arrayOfIPRanges;
      }
      push(@newArrayOfSpec, $ippool);
   }
   return \@newArrayOfSpec;
}
1;
