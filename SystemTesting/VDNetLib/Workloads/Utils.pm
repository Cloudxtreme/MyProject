########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::Utils;

#
# This package has utility methods that can be used in common by
# all *Workloads.pm modules
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);


########################################################################
#
# GetAdapterObj--
#     Method to get adapter object from the given node (tuple format)
#
# Input:
#     testbed : Reference to testbed hash
#               (Required)
#     node    : adapter in <machine>:<adapterType>:<index>
#               format (Required)
#
# Results:
#     Reference to NetAdapter object, if successful;
#     FAILURE, in case of error
#
# Side effects:
#     None
#
########################################################################


sub GetAdapterObj
{
   my $testbed = shift;
   my $node    = shift;

   if ((not defined $testbed) || (not defined $node)) {
      $vdLogger->Error("Testbed and/or node value not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my ($machine, $adapterType, $index) = split(/:/, $node);

   my $adapterObj;
   if ($adapterType =~ /vnic/i) {
      $adapterObj = $testbed->{testbed}{$machine}{'Adapters'}{$index};
   } elsif ($adapterType =~ /vmknic/i) {
      $adapterObj = $testbed->{testbed}{$machine}{'Adapters'}{'vmknic'}{$index};
   } elsif ($adapterType =~ /vmnic/i) {
      $adapterObj = $testbed->{testbed}{$machine}{'Adapters'}{'vmnic'}{$index};
   } elsif ($adapterType =~ /pci/i) {
      $adapterObj = $testbed->{testbed}{$machine}{'Adapters'}{'pci'}{$index};
   } else {
      $vdLogger->Error("Unknown adapter type $adapterType given");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $adapterObj) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "node $node");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return $adapterObj;
}


########################################################################
#
# InitVerification -
#       If Verification key is defined then set event and ask parent
#       to provide the verification hash
#
# Input:
#       thisWorkload - $self of workload who is calling this method (mandatory)
#       workloadhash - A workload hash should be a blessed object
#       of any of the trafficworkload, switchworkload's session data.
#       E.g. trafficworkload send session hash as workloadhash (optional)
#
# Results:
#       verification Obj - in case verification was called successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub InitVerification
{
   my $thisWorkload = shift;
   my $workloadhash = shift;
   #
   # Check in cache if we got any verification hash in previous iterations
   # if yes, use it. If no, then see if verification key is defined.
   # if defined get the verification hash.
   #
   my $verifyHash = $thisWorkload->{cache}->{verificationhash};
   if (not defined $verifyHash) {
      #
      # Check if parent has supplied verification hash, if not
      # ask parent to return that hash.
      #
      if (ref($thisWorkload->{'verification'}) =~ /HASH/i) {
         $verifyHash = $thisWorkload->{'verification'};
      } else {
         $vdLogger->Trace("Using SetEvent to ReturnWorkloadHash from parent");
         $verifyHash = $thisWorkload->{testbed}->SetEvent("ReturnWorkloadHash",
                                                 $thisWorkload->{'verification'});
         if (FAILURE eq $verifyHash || (ref($verifyHash) !~ /HASH/)) {
            $vdLogger->Error("Failed to get Verification hash:" .
                             "$thisWorkload->{'verification'} from parent");
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }
      }
      #
      # If we have found the verification hash for the first time
      # then save it in cache for subsequent iterations for traffic
      #
      $thisWorkload->{cache}->{verificationhash} = $verifyHash;
   }

   $vdLogger->Info("Working on Verification of switch functionality ...");
   $vdLogger->Trace(Dumper($verifyHash));
   my $veriModule = "VDNetLib::Verification::Verification";
   eval "require $veriModule";
   if ($@) {
      $vdLogger->Error("Loading Verification.pm, failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # Each Worklod should have his own sub log folder whcih it can
   # store verification logs
   #
   my $verificationLogs = $thisWorkload->{localLogsDir};
   if (not defined $verificationLogs) {
      $vdLogger->Warn("var 'localLogsDir' missing in this workload. ".
                       "Required to collect verification logs");
   }
   my $veriObj = $veriModule->new(testbed => $thisWorkload->{testbed},
                                  verificationhash => $verifyHash,
                                  workloadhash => $workloadhash,
                                  localLogsDir => $verificationLogs
                                 );
   if ($veriObj eq FAILURE) {
      $vdLogger->Error("Verification obj creation failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $thisWorkload->{verificationHandle} = $veriObj;

   if ($veriObj->StartVerification() eq FAILURE) {
      $vdLogger->Error("StartVerification failed in SwitchWorkload");
      $vdLogger->Debug(Dumper($veriObj));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $veriObj;
}


########################################################################
#
# FinishVerification -
#       Calls StopVerification and then GetReesult on verification for
#       the current switch workload combination
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case session is started successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub FinishVerification
{
   my $thisWorkload = shift;
   my $verificationResult;

   # verificationHandle should be defined because FinishVerification()
   # is called only when user defines verification key in the
   # workload hash
   my $veriObj = $thisWorkload->{verificationHandle};
   if (not defined $veriObj) {
      $vdLogger->Error("Verfication Handle missing in SwitchWorkload");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($veriObj->StopVerification() eq FAILURE) {
      $vdLogger->Error("StopVerification failed in TrafficWorkload");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $verificationResult = $veriObj->GetResult();
   #
   # Freeing memory by destroying the obj explicitilty
   #
   $thisWorkload->{verificationHandle} = undef;

   if ($verificationResult ne SUCCESS) {
      $vdLogger->Error("Verification of SwitchWorkload failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $verificationResult;
}
1;
