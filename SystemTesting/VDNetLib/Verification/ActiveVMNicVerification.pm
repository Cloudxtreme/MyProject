#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::ActiveVMNicVerification;

#
# This package inherits VDNetLib::Verification::Verification class.
# This is used for verifying active uplink of a virtual nice
# using the load balancing options set the virtual switch.
# Sample workflow:
#  The load balancing option is set on a virtual switch. The source
#  virtual adapter is connected to this switch. The switch is uplinked
#  to 1 or more phy nics.
#  Before running traffic through the virtual adapter, the active uplink
#  of this adapter is computed. Then, the tx/rx stats are collected from the
#  phy uplink and saved as Starting point.
#  Traffic workload is now between the source virtual adapter and other
#  destination (should be different host). Once traffic is stopped, the
#  tx/rx stats of the phy uplink is computed once again and then the difference
#  is found between the start and end value.
#  Based on the traffic throughput, a decision is made whether traffic went
#  through the active phy uplink.
#
#  NOTE: No parallels sessions of traffic should be run through this phy
#  uplink at the same time. This is avoid false positive in tx stats
#  calculation when external sources send traffic through same vmnic as the
#  virtual adapter under test.
#

# Inherit the parent class.
require Exporter;
# ISA was not doing multiple inheritance thus I am using use base which works well
# for multiple inheritance.
use base qw(VDNetLib::Verification::StatsVerification
            VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;

use PLSTAF;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);


###############################################################################
#
# new -
#       This method creates obj of this class.
#
# Input:
#       none
#
# Results:
#       Obj of ActiveVMNicVerification module, if successful;
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{

   my $class = shift;
   my $self  = {
     'os'          => "vmkernel",
     # We keep arch for esx as 32 as we use most of the 32 bit binaries
     # from vdnet bin folder.
     'arch'        => "x86_32",
     # ActiveVMNic Verification is always done on the vmnic associated with
     # the vNIC on the srcVM
     displaytype => "targetcentric",
   };

   bless ($self, $class);
   return $self;

}


###############################################################################
#
# RequiredParams -
#       This is a child method. It says what param does it need from testbed,
#       traffic or netadapter to intialize verification.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub RequiredParams
{
   my $self = shift;
   my @params;
   @params = ("drivername", "hostobj", "host", "mac");
   return \@params;
}


##############################################################################
#
# GetChildHash --
#       Its a child method. It returns a conversionHash which is specific to
#       what child wants.
#
# Input:
#       none
#
# Results:
#       converted hash - a hash containing node info in language verification
#                        module understands.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
##############################################################################

sub GetChildHash
{
   my $self = shift;
   my $spec = {
      'traffic'    => {
            server => {
               'testip'          => 'servertestip',
            },
            client => {
                'testip'         => 'clienttestip',
            },
            'testduration' => "traffictestduration",
      },
      'testbed'    => {
            'hostobj'         =>  {
                  'hostIP'      => 'host',
            },
            'adapter'         =>   {
                  'driver'            => 'drivername',
                  'macAddress'        => 'mac',
            },
      },
   };

   return $spec;
}


###############################################################################
#
# VerificationSpecificJob -
#       A void method which the child can override and do things which are
#       specific to that child
#       Parents leaves a hook so that future childs can make changes without
#       modifying the parent.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub VerificationSpecificJob
{
   my $self = shift;
   # VSISH is always done in the host. For target srcvm and srchost vsish stats
   # are gathered from host. Thus changing the target to host.
   $self->{targetip} = $self->{host};
   return SUCCESS;
}


###############################################################################
#
# VerificationSpecificDeletion -
#       Remove children which are not supported. Remove childrens for which
#       there is no expectation set.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub VerificationSpecificDeletion
{
   my $self = shift;
   my $target = $self->{target};
   if ($target !~ /src/i) {
      $vdLogger->Info("ActiveVMNic Verification is not supported on $target");
      return "unsupported";
   }
   return SUCCESS;
}


###############################################################################
#
# Stop -
#       StopVerification equivalent method in children for stopping the
#       verification to get the final counters.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub Stop
{
   my $self = shift;
   my $ret = $self->Start("final");
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Stop Stats on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   # We need to set the expected change for Tx Bytes to be greater than
   # throughput. We do this after stop verification bcos at this point
   # traffic must have stopped and got the throughput which we need.
   # Target from where the througput has to be extraced.

   my $target = "dst";
   my $spec = {
      'traffic' => {
         'server' => {
            'throughput'   => 'trafficthroughput',
         },
         'testduration' => "traffictestduration",
      },
   };

   $ret = "unsupported";
   my $convertedNode = $self->ConvertVerificationNode($target, $spec);
   if (not defined $convertedNode) {
      $vdLogger->Error("Node Conversion failed for $target ".Dumper($spec));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }


   my $duration = $convertedNode->{traffictestduration};
   my $throughput = $convertedNode->{trafficthroughput};
   if ((not defined $throughput) || (not defined $duration) ||
       ($throughput eq 0) || ($duration eq 0)){
      $vdLogger->Error("Either throughput or duration not found. Cannot do ".
                       "$self->{veritype} for target $self->{nodeid} failed" .
                       Dumper($convertedNode));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   #
   # From throughput and test duration, get rx data in bytes.
   # Since rx cannot be greater
   # than tx, it is expected the Tx Bytes diff is greater than rx bytes.
   # ** mean raise to - 10 ** 6 is 10 to the power of 6.
   #
   my $rxBytes = (int($duration) * int ($throughput) * (10 ** 6)) / 8;
   $rxBytes = int($rxBytes);
   $vdLogger->Debug("Throughput at Destination($throughput) * ".
                   "test duration($duration) = RxBytes at des($rxBytes)");

   my $bucket = $self->GetBucket();
   foreach my $nodesInBucket (keys %$bucket) {
      my $allNodes = $bucket->{$nodesInBucket};
      foreach my $nodeKey (keys %$allNodes) {
         my $node = $allNodes->{$nodeKey};
         my $template = $node->{template};
         if (not defined $template) {
            $vdLogger->Error("template not defined for $self->{veritype}".
                        "on target $self->{nodeid}");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         # Diff of Tx Bytes should be greater than the traffic throughput
         if (not defined $template->{'txbytes'}) {
            $vdLogger->Error("tx_bytes counter not found in $self->{veritype}".
                             " on target $self->{nodeid} . Dumper($template)");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         $template->{'txbytes'} = "$rxBytes" . "+" . ":" . "specific" ;
      }
   }
   $vdLogger->Info("Throughput at Destination($throughput) * ".
                   "test duration($duration) = RxBytes at des($rxBytes). ".
                   "Expecting txbytes to be in range:100-". $rxBytes);

   return SUCCESS;
}

###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#       This list is used in case user does not specify any verification type
#
# Input:
#       None
#
# Results:
#       array - containing names of child modules
#
# Side effects:
#       None
#
###############################################################################

sub GetMyChildren
{
   return 0;

}


###############################################################################
#
# ProcessExpectationHash -
#       Overriding parent method just to save time.
#
# Input:
#       None
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessExpectationHash
{
   return SUCCESS;
}



###############################################################################
#
# GetDefaultTargets -
#       Returns the default target to do verification on, in case user does
#       not specify any target.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values of default targets.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultTargets
{
   return "srcvm";
}


###############################################################################
#
# GetSupportedPlatform -
#       Returns the platforms supported by this module. Only options are guest
#       and host.
#       If some verification is only supported on win/linux, specific flavor
#       of win/linux, specific kernel version it will be caught later.
#       Every child needs to implement this. Parent should not implement it.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values supported platform
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetSupportedPlatform
{
   return "guest";
}


###############################################################################
#
# GetDefaultNode -
#       Returns the default nodes on each platform type for this kinda of
#       verification.
#
# Input:
#       none
#
# Results:
#       hash  - containing all default nodes.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultNode
{
   my $self = shift;

   my $nodeTemple;

   # For ESX
   # vsish -e get /net/pNics/vmnic0/stats
   # The activeVMnic(pnic = vmnicX) will be calculated based on the
   # load balancing criteria/policy of the switch.

   $nodeTemple = {
      'vmkernel' => {
         "/net/pNics/<ACTIVEVMNIC>/stats" => {
            template => {
               # Setting the expectations here itself for ActiveVMNic.
               # that it should be equal to or greater than throughput
               'txbytes' => "throughput+",
            } # end of tempate hash
         },# end of node hash
      },
   };

   return $nodeTemple;
}


###############################################################################
#
# InitVerification -
#       Initialize verification on this object.
#
# Input:
#       expectation key (mandatory)
#       expectation value (mandatory)
#       expectation type (optional)
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub InitVerification
{
   my $self = shift;
   $self->{os} = "vmkernel" if $self->{os} =~ /(vmkernel|esx)/i;
   my $veriType = $self->{veritype};

   my $allparams = $self->RequiredParams();
   foreach my $param (@$allparams) {
      if (not exists $self->{$param}) {
         $vdLogger->Error("Param:$param missing in InitVerification for".
                          " $veriType".  "Verification");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   my $defaultNode = $self->GetDefaultNode();
   my $allNodes = $defaultNode->{$self->{os}};
   $self->{expectedchange}->{'txbytes'} = "100+";

   foreach my $nodeKey (keys %$allNodes) {
      my $actualNode = $nodeKey;
      # Command will either return 'unsupported' or raw data.
      # in case of later we convert it to hash and store it as template so
      # that we can set expected values on those counters.
      # we also say supported = 'yes/no' for these nodes.
      my $ret = $self->ExecuteStatsCmd($self->{targetip}, $actualNode);
      if ($ret =~ /unsupported/i) {
         $ret = "no";
      } else {
         # Convert from raw data to Hash.
         my $hash = $self->ConvertRawDataToHash($ret, 0);
         $self->{statsbucket}->{nodes}->{$actualNode}->{"template"} = $hash;

         # Extra arguments like dumsw, txpkt, rxbytes, mltcast, rxpkt have
         # to be deleted as ActiveVMNicVerification deals with only txbytes
         # changes. If we want to make use of these arguments in future,
         # we have to remove the deletion for that parameter and add the
         # paramater to child spec everywhere.
         foreach my $key (keys %{$self->{statsbucket}->{nodes}->{$actualNode}->{"template"}}) {
            if ($key eq "txbytes") {
               next;
            } else {
               delete $self->{statsbucket}->{nodes}->{$actualNode}->{"template"}{$key};
            }
         }
         $ret = "yes";
      }
      $self->{statsbucket}->{nodes}->{$actualNode}->{"supported"} = $ret;
   }

   return SUCCESS;

}


###############################################################################
#
# GetBucket -
#       Get the name of the bucket storing stats.
#
# Input:
#       None
#
# Results:
#       ptr to bucket.
#
# Side effects:
#       None
#
###############################################################################

sub GetBucket
{
   my $self = shift;
   return $self->{statsbucket};
}


###############################################################################
#
# DESTROY -
#       This method is destructor for this class.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#
###############################################################################


sub DESTROY
{
   my $self = shift;
   return SUCCESS;
}

1;
