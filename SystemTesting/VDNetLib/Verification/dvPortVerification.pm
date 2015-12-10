#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::dvPortVerification;

#
# This module gives object of dvPortStats verification of Unicast, Mulitcast
# and Broadcast packets. It deals with gathering initial and final stats before
# a test is executed and then taking a diff between the two stats.
#

# VM-A ----------------------> VM-B
# VM's send different types of (Unicast, Multicast and Broadcast) packets.
# Find the ESX host IP and DVS port number of the VM.
# Get the Unicast, Multicast and Broadcast packet information using the following commands:
# net-dvs -l | grep -A 34 "port 131:" | grep -i -E 'pkts|bytes'
#
# In the above command port number should be the DVS port number to which the VM is connected.
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

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

###############################################################################
#
# new -
#       This method reads the verification hash provided. Fetch required
#       details from verification hash like controlip testip, os,
#       interface on which to run the capture.
#
# Input:
#       verification hash (required) - a specificaton in form of hash which
#       contains traffic details as well as testbed details.
#
# Results:
#       Obj of dvPortStatsVerification module - in case everything goes well.
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
   };

   bless ($self, $class);
   return $self;
}


###############################################################################
#
# RequiredParams -
#       This is a child method. It says what param does it need from testbed
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
   # This is child method. Move it.
   my $self = shift;
   my $os = $self->{os};

   my @params;
   @params = ("trafficroutingscheme");

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
#       converted hash - a hash containging node info in language verification
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
      'testbed'    => {
            'host'            =>  'host',
            'hostObj'         =>  'hostobj',
            'adapter'         =>   {
               'macAddress'   => 'mac',
            },
      },
      'traffic'    => {
            'noofinbound'   => "inbound",
            'noofoutbound'  => "outbound",
            'routingscheme' => "trafficroutingscheme",
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
   # dvPort Stats is always gathered from host. For target srcvm and srchost vsish stats
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
# GetDefaultTargets -
#       Returns the default target to do verification on, in case user does
#       not specify any target.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values of default target.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultTargets
{
   return "srcvm,srchost,dstvm,dsthost";
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

   $nodeTemple = {
      'vmkernel' => {
         "net-dvs -l | grep -A 43" => {
         },
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
      if(not exists $self->{$param}) {
      $vdLogger->Error("Param:$param missing in InitVerification for $veriType".
                       "Verification");
      }
   }

   my $dvport = $self->{expectedchange}->{dvportnum};
   delete $self->{expectedchange}->{dvportnum};
   if ((not defined $dvport) || ($dvport eq "")) {
       $vdLogger->Trace("dvPortNum not defined in traffic. Checking in ".
                        "verification input hash");
      $dvport = $self->{dvportnum};
      if ((not defined $dvport) || ($dvport eq "")) {
         $vdLogger->Trace("Not able to get dvPortNum from traffic or user ".
                          "input. Will resolve at run time");
         $dvport = $self->GetDVPortNum("dvportnum");
         if ($dvport  eq FAILURE) {
            $vdLogger->Error("Not able to find DVPORTNUM for $self->{mac}");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      }
   }

   my $defaultNode = $self->GetDefaultNode();
   my $allNodes = $defaultNode->{$self->{os}};

   # Add inbound/outbound based on the traffic
   # Add multicast, unicast, broadcast based on the traffic.
   my $statsType = $self->{expectedchange}->{dvportstatstype};
   delete $self->{expectedchange}->{dvportstatstype};
   if ((not defined $statsType) || ($statsType eq "")) {
      $vdLogger->Trace("dvportstatsType not defined by user. ".
                       "Calculating from traffic");
      my $inbound = $self->{inbound};
      my $outbound = $self->{outbound};
      my $routing = $self->{trafficroutingscheme};
   #Fix PR942795,from vds' perspective,outbound traffic from VM is inbound for vds
      if((defined $inbound)&&($inbound ne "")) {
         $statsType = "out";
      }
      if((defined $outbound)&&($outbound ne "")) {
         $statsType = "in";
      }

      if ((not defined $statsType) || ($statsType eq "")) {
         $vdLogger->Error("Not able to get inbound/outbound info from traffic hash");
         return "unsupported";
      }

      if(not defined $routing) {
         $vdLogger->Error("Not able to get routingscheme from traffic hash");
         return "unsupported";
      }
      $statsType = $statsType . $routing;
   }

#   $self->->{expectedchange}->{"all" . $statsType} = "1+";



   foreach my $nodeKey (keys %$allNodes) {
      my $actualNode = $nodeKey;
      # Command will either return 'unsupported' or raw data.
      # in case of later we convert it to hash and store it as template so
      # that we can set expected values on those counters.
      # we also say supported = 'yes/no' for these nodes.
      $actualNode = $actualNode . " \"port $dvport\" | grep -i -E \"bytes|pkts\" ";

      my $ret = $self->ExecuteStatsCmd($self->{targetip}, $actualNode);
      if ($ret =~ /unsupported/i) {
         $vdLogger->Error("Cmd:$actualNode not supported on " .
                          $self->{targetip});
         $ret = "no";
      } else {
         # Convert from raw data to Hash.
         my $hash = $self->ConvertRawDataToHash($ret, 0);
         foreach my $key (keys %$hash) {
            if($key =~ /$statsType/i) {
                $hash->{$key} = "1+:specific";
            }
         }
         $self->{statsbucket}->{nodes}->{$actualNode}->{"template"} = $hash;
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
   return SUCCESS;
}

1;
