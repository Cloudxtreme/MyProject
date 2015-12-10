##############################################################################
#
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::PortGroupWorkload;
# This package is used to run PortGroup Workload workload that involves
#
#
# The interfaces new() are implemented
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::Portgroup::PortGroup object will be created in new function
# In this way, all the PortGroup workloads can be run parallelly with no
# re-entrant issue.
#
###############################################################################

package VDNetLib::Workloads::PortGroupWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::AbstractSwitchWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::PortGroupWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::PortGroupWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
###############################################################################

sub new {
   my $class = shift;
   my %options = @_;

   if ((not defined $options{testbed}) || (not defined $options{workload})) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $self = VDNetLib::Workloads::AbstractSwitchWorkload->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::Workloads::AbstractSwitchWorkload" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{targetkey} = "testportgroup";
   $self->{managementkeys} = ['type', 'iterations', 'testportgroup', 'expectedresult'];
   $self->{componentIndex} = undef;
   bless ($self, $class);

   # Extending the KEYSDATABASE of PortGroup
   my $portGroupKeysDatabase = $self->GetKeysTable();
   my $refNewKeysDataBase = {%{$self->{keysdatabase}}, %$portGroupKeysDatabase};
   $self->{keysdatabase} = $refNewKeysDataBase;

   return $self;
}


########################################################################
#
# ConfigureComponent --
#      This method is used to configure devices using the
#      ConfigureComponet() of ParentWorkload
#
# Input:
#      dupWorkload : a copy of the workload
#      $testObject : datacenter object
#
# Result:
#      "SUCCESS" - if all the network configurations are successful,
#      "FAILURE" - in case of any error.
#      "SKIP"    - incase the return value is SKIP
#
# Side effects:
#      None
#
########################################################################

sub ConfigureComponent
{
   my $self = shift;
   my %args        = @_;
   my $dupWorkload = $args{configHash};
   my $testObject  = $args{testObject};

   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $dupWorkload,
                                                 'testObject' => $testObject);

   if (defined $result) {
      if ($result eq "FAILURE") {
         return "FAILURE";
      } elsif ($result eq "SKIP") {
         return "SKIP";
      } elsif ($result eq "SUCCESS") {
         return "SUCCESS";
      }
   }
}


########################################################################
#
# PreProcessSetFailoverOrder --
#     Method to process failover order for dvportgroup
#
# Input:
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#     reference to array which contains argument required to
#     call SetFailoverOrder() method
#
# Side effects:
#     None
#
########################################################################

sub PreProcessSetFailoverOrder
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;
   my @array ;
   my $refArrayofUplink = [];

   if (not defined $keyValue) {
      $vdLogger->Error("keyvalue variable is not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my @uplinkarr = split(/;;/,$keyValue);
   foreach my $param (@uplinkarr) {
      if ($param =~ m/lag/i) {
         my $refArrayofTuples = $self->{testbed}->GetAllComponentTuples($param);
         my $refArrayofObjects = $self->GetArrayOfObjects($refArrayofTuples);
         push (@$refArrayofUplink, @$refArrayofObjects);
      } elsif ($param =~ m/uplink/i) {
         my @arr = VDNetLib::Common::Utilities::HelperProcessTuple(split /\[(.*?)\]/,
                                                             lc($param), -1);

         push (@$refArrayofUplink, @arr);
      } else {
         $vdLogger->Error("No LAG <vc.[x].vds.[x].lag.[x]> or " .
                          "uplink <uplink1/2/N> given");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   push (@array, $refArrayofUplink);

   foreach my $parameter (@$paramList){
      if ((defined $paramValue->{$parameter}) && ($parameter =~ /failovertype/i)) {
         push(@array, $paramValue->{$parameter});
      }
   }

   return \@array;
}

1;
