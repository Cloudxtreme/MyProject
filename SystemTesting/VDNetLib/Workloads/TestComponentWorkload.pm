########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TestComponentWorkload;

use strict;
use warnings;
use Data::Dumper;
use Storable 'dclone';
use VDNetLib::Common::Compare;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Workloads::Utils;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::TestComponentWorkload class
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::Workloads::TestComponentWorkload object,
#      if successful;
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
      return "FAILURE";
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      };
   $self->{targetkey} = "testcomponent";
   $self->{managementkeys} = ['type', 'iterations', 'testcomponent', 'expectedresult'];

   bless ($self, $class);
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}


sub PreProcessFoo
{
   my $self = shift;
   my ($keyValue, $testObject, $keyName) = @_;
   if ($keyValue eq "disable") {
      return "0000 0000";
   } else {
      return "0000 1111";
   }
}

sub PreProcessVerificationABCD
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      #
      # If $parameter equal to $keyName, that means
      # the value is a spec which needs special treatment.
      # In below case if the spec has tuples whose objects
      # have attribute mapping, then the following method
      # should work. Else the user has to implement their
      # own method to process this spec.
      #
      # For Example, if the verification key 'checkifexists'
      # (key is present in TestComponentWorkload) is part
      # of @$paramList, then the value held by this key
      # "checkifexists" is a spec that will be used to obtain
      # user data. In order to get the userdata using
      # ProcessUserDataForVerification() from this key,
      # we need to do the following check so that above method
      # is invoked.
      #
      if ($parameter eq $keyName) {
         $userData = [
          {
            'sourceaddrs' => [
                        {
                          'ip' => ['192.168.1.1', '192.168.1.2'],
                          'mac[?]equal_to' => "ABCDEFG",
                        },
                    ],
            'mcastprotocol' => 'IGMP',
            'groupaddr' => '239.1.1.1',
            'mcastmode' => 'exclude',
            'mcastversion' => '3'
          }
        ];
      } else {
          $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }

   return \@array;
}
1;

