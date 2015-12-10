#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::NIOCVerification;

#
# This package inherits VDNetLib::Verification::Verification and
# VDNetLib::Verification::StatsVerification classes.
#
#
# The objective of the package is to verify vnic bandwidth entitlement.
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
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );


###############################################################################
#
# new -
#       This method creates obj of this class.
#
# Input:
#       none
#
# Results:
#       Object of this class, if successful;
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $self  = {
      'verihash' => $options{verihash},
   };
   foreach my $hash (keys %{$self->{verihash}}) {
      if ($self->{verihash}{$hash}{verificationtype} eq "NIOC") {
         $self->{uplinks} = $self->{verihash}{$hash}{uplinks};
      }
   }
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
   return ["hostobj", "adapterobj"];
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

   # We need to set the expected change for bytesOut to be greater than
   # throughput. We do this after stop verification bcos at this point
   # traffic must have stopped and got the throughput which we need.
   # Target from where the througput has to be extraced.

   my $target = $self->{'target'};
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
   # than tx, it is expected the bytesOut diff is greater than rx bytes.
   # ** mean raise to - 10 ** 6 is 10 to the power of 6.
   #
   my $rxBytes = (int($duration) * int ($throughput) * (10 ** 6)) / 8;
   $rxBytes = int($rxBytes);
   $vdLogger->Info("Bytes diff computed using traffic tool: $rxBytes");
   my $defaultNode = $self->GetDefaultNode();
   my $allNodes = $defaultNode->{$self->{os}};
   foreach my $nodeKey (keys %$allNodes) {
      my $actualNode = $nodeKey;
      # Command will either return 'unsupported' or raw data.
      # in case of later we convert it to hash and store it as template so
      # that we can set expected values on those counters.
      # we also say supported = 'yes/no' for these nodes.
      my $ret = $self->ExecuteStatsCmd($self->{targetip}, $actualNode);
      # Convert from raw data to Hash.
      my $hash = VDNetLib::Common::Utilities::ProcessVSISHOutput(RESULT => $ret);
      $allNodes->{$actualNode}{'final'} = $hash;
   }

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
         "/vmkModules/netsched/hclk/devs/<SCHEDVMNIC>/qleaves/<SCHEDNODE>/info" => {
         },
      },
   };

   return $nodeTemple;
}


########################################################################
#
# FindSchedulerVMNic --
#     Method to find the vmnic on which the given target is placed
#
# Input:
#     None
#
# Results:
#     updates the following attributes of $self->{macnode}
#     portID      : port id of the target adapter
#     schedvmnic  : vmnic on which the target adapter is placed
#     schednode   : node name/index of this adapter on scheduler
#
# Side effects:
#     None
#
########################################################################

sub FindSchedulerVMNic
{
   my $self = shift;
   my $adapterobj = $self->{adapterobj};
   my $portID = $adapterobj->GetPortID();

   $self->{macnode}->{portID} = $portID;
   my $niocInfo = $adapterobj->GetNIOCInfo($portID);
   $self->{macnode}->{schedvmnic} = $niocInfo->{'uplinkDev'};
   my $schedulerInfo = $adapterobj->GetNetSchedulerInfo($niocInfo);
   $self->{macnode}->{schednode} = $schedulerInfo->{'poolId'};
   return SUCCESS;
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
   my $target = $self->{'target'};
   my $spec = {
      'traffic' => {
         'testduration' => "traffictestduration",
      },
   };

   my $convertedNode = $self->ConvertVerificationNode($target, $spec);
   if (not defined $convertedNode) {
      $vdLogger->Error("Node Conversion failed for $target ".Dumper($spec));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{adapterObj} = $convertedNode->{adapterObj};

   my $duration = $convertedNode->{traffictestduration};
   if ((not defined $duration) || ($duration eq 0)) {
      $vdLogger->Error("duration not found. Cannot do ".
                       "$self->{veritype} for target $self->{nodeid} failed" .
                       Dumper($convertedNode));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $uplinks = $self->{'uplinks'};
   my $refArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($uplinks);

   my $uplinkHash;
   foreach my $tuple (@$refArray) {
      my $uplinkObjects = $self->{testbed}->GetComponentObject($tuple);
      my $uplink = $uplinkObjects->[0];
      my $args = $uplink->{'interface'};
      my $schedTree = ExecuteRemoteMethod($uplink->{'controlIP'},
                                          "GetPortEntitlement",
                                          $args);
      $uplinkHash->{$args} = $schedTree;
   }
   $self->{uplinkHash} = $uplinkHash;
   my $defaultNode = $self->GetDefaultNode();
   my $allNodes = $defaultNode->{$self->{os}};

   if ($self->FindSchedulerVMNic() eq FAILURE) {
      $vdLogger->Error("Not able to find scheduler vmnic $self->{mac}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{expectedchange}->{'bytesOut'} = undef;
   my $portID = $self->{macnode}->{portID};
   foreach my $uplink (keys %$uplinkHash) {
      if (defined $uplinkHash->{$uplink}{'vm'}{$portID}) {
         my $entitlement = $uplinkHash->{$uplink}{'vm'}{$portID}{'entitlement'};
         $vdLogger->Info("Throughput expected: $entitlement");
         my $rxBytes = int(($duration) * ($entitlement) * (10 ** 6) / 8);
         $self->{expectedchange}{'bytesOut'} = $rxBytes;
         $vdLogger->Trace("Expected bytes out: $rxBytes");
         last;
      }
   }
   foreach my $nodeKey (keys %$allNodes) {
      my $actualNode = $nodeKey;
      $self->{statsbucket}->{nodes}->{$actualNode}->{"template"}{'bytesOut'} =
         $self->{expectedchange}{'bytesOut'} . "+:specific";
      $self->{statsbucket}->{nodes}->{$actualNode}->{"supported"} = "yes";
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
