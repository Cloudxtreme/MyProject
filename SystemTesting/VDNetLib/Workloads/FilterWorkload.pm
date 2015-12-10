##############################################################################
#
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::FilterWorkload;
# This package is used to run Filter workload that involves
#
#    -- operations related  to Filter in esx host.
#
# The interfaces new() are implemented
#
#
###############################################################################

package VDNetLib::Workloads::FilterWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;

use VDNetLib::Workloads::RulesWorkload;
use VDNetLib::Workloads::AbstractSwitchWorkload;



###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::DatacenterWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::DatacenterWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
###############################################################################

sub new {
   my $class = shift;
   my %options = @_;
   my $self;

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $self = {
      'testbed'        => $options{testbed},
      'workload'       => $options{workload},
      'targetkey'      => "testfilter",
      'managementkeys' => ['type', 'iterations', 'testfilter'],
      'componentIndex' => undef,
      };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}


########################################################################
#
#  PreProcessReconfigureFilter --
#       Method tp preprocess parameters required to edit filter
#       Configuration
#
# Input:
#     testObject  : reference to test adapter object
#     keyName     : key name for which this pre-process method is called
#     keyValue    : value of 'keyName'
#     paramValue  : list of parameters used to edit virtual adapter
#
#
# Results:
#      reference to an array which contains arguments needed to
#      edit filter
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessReconfigureFilter
{
   my $self = shift;
   my ($testObject,$keyName, $keyValue, $paramValue) = @_;
   my @arguments;
   my $specHash = {
      'filtername' => $paramValue->{"filtername"},
      'filterkey' => $testObject->{'filterkey'},
      'rule'       => $paramValue->{'rule'},
   };

  push (@arguments,$specHash);
  return \@arguments;
}

1;
