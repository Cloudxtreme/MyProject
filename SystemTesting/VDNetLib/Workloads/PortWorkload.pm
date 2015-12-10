##############################################################################
#
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::PortWorkload;
# This package is used to run DV Port Workload workload that involves
#
#
# The interfaces new() are implemented
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::Port::Port object will be created in new function
# In this way, all the Port workloads can be run parallelly with no
# re-entrant issue.
#
###############################################################################

package VDNetLib::Workloads::PortWorkload;

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
#      Method which returns an object of VDNetLib::Workloads::PortWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::PortWorkload object, if successful;
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
   $self->{targetkey} = "testport";
   $self->{managementkeys} = ['type', 'iterations', 'testport'];
   $self->{componentIndex} = undef;
   bless ($self, $class);

   # Extending the KEYSDATABASE of PortGroup
   my $portKeysDatabase = $self->GetKeysTable();
   my $refNewKeysDataBase = {%{$self->{keysdatabase}}, %$portKeysDatabase};
   $self->{keysdatabase} = $refNewKeysDataBase;
   #$self->{keysdatabase} = $self->GetKeysTable();

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
# StorePortRunningConfiguration --
#      This method is used to port running configuration in
#      pswitchport.
#
# Input:
#     testObj - Core API object under test.
#               E.g. HostWorkload will have hostObj as testObj
#     keyName - action/param key name
#     keyValue - action/param key value
#     refToHash - workload hash
#     runtimeResult -
#     paramValue    - Reference to hash where keys are the contents of
#                     'params' and values are the values that are assigned
#                     to these keys in config hash.
#     runtimeResult - Result from the core api
#
# Result:
#      "SUCCESS" - if vnic mac address is found,
#      "FAILURE" - if vnic mac address is not present.
#
# Side effects:
#      None
#
########################################################################

sub StorePortRunningConfiguration
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $switchPort = $testObject->{'switchPort'};
   my $switchRef = $testObject->{switchObj};

   my $portRunConfig = $runtimeResult;
   if ((not defined $portRunConfig) ||
       (not defined $switchPort) ||
       (not defined $testObject)) {
      $vdLogger->Error("One or more parameters missing to set portrunconfig");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $testObject->{switchObj}{portMap}{runConfig}{$switchPort} = $runtimeResult;
   my $result = $self->{testbed}->SetComponentObject($self->{componentIndex}, $testObject);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Updated testbed hash with information of running config ".
                   "of switchport $switchPort");

   return SUCCESS;

}


########################################################################
#
# Verifyvnicswitchport --
#      This method is used to verify is vnic mac address is present
#      in the mac address table of the switch
#
# Input:
#     testObj - Core API object under test.
#               E.g. HostWorkload will have hostObj as testObj
#     keyName - action/param key name
#     keyValue - action/param key value
#     refToHash - workload hash
#     runtimeResult -
#     paramValue    - Reference to hash where keys are the contents of
#                     'params' and values are the values that are assigned
#                     to these keys in config hash.
#     runtimeResult - Result from the core api
#
# Result:
#      "SUCCESS" - if run config is stored properly,
#      "FAILURE" - in case of any failure.
#
# Side effects:
#      None
#
########################################################################

sub VerifyVnicSwitchport
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;

   my $macTable = $runtimeResult;
   my $vnic = $keyValue;
   #my $vnic = $configHash->{"verifyvnicswitchport"};
   my $ref = $self->{testbed}->GetComponentObject($vnic);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref $ref for tuple $vnic");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $vnicObj = $ref->[0];
   my $mac = $vnicObj->{macAddress};

   if (not defined $mac) {
      $vdLogger->Error("MAC address not defined for test adapter $vnic");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $mac =~ s/\.|://g; # remove . or : from  mac address
   my $count = 0;
   $vdLogger->Debug("MAC Table: " . Dumper($macTable));
   foreach my $line (@$macTable) {
      if ($line =~ /(([0-9a-fA-F]{4}[.]){2}[0-9a-fA-F]{4})/i) {
         my $macAddr = $1;
         #
         # Remove . or : from the mac address since there is difference
         # in mac format in the phy switch, example (0021.af45.21a5)
         #
         $macAddr =~ s/\.|://g;
         if (($mac =~ /$macAddr/i) &&
            ($line =~ /$testObject->{switchPort}/i)) {
            $vdLogger->Info("Given vnic index's mac $mac is on " .
                           "vmnic $testObject->{vmnic} port " .
                           $testObject->{switchPort});
            return SUCCESS;
         } # end of if condition
      } # end of checking mac format
   } # end of mactable loop

   $vdLogger->Error("Given vnic index's mac $mac is NOT on " .
                    "vmnic $testObject->{vmnic} port " .
                    $testObject->{switchPort});
   VDSetLastError("ENOTDEF");
   return FAILURE;
}
1;
