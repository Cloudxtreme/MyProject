#!/usr/bin/perl
###############################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::PktCapUserWorldVerification;

#
# This module gives object for packet capture verification using pktcap-uw tool.
# It deals with filter string generation in 3 parts.
# 1) A constant filter 2) User defined filter values 3) Filter based on
# traffic or any other workload.
# It Capturs packets according to this filter.
# Converts the pktcapuw capture file to human readable format and reads the
# file for errors, packet drops or other desired patterns. Gives out this
# result to user of this package.
#
# Usage:
# Here is an VXLAN example of how to use pktcap-uw tool
# 'PktCapVerificaton' => {
#   'target'       => 'host.[2].vmnic.[1]',
#
#  # pktcapfilter 'vxlan' can followed by vxlan id directly or followed by a tuple
#  # flowdirection can be tx or rx, capturestage can be post or pre
#  # 'pktcapfilter' => 'count 15,vxlan 7676,flowdirection tx,capturestage post',
#    'pktcapfilter' => 'count 15,vxlan vsm.[1].networkscope.[1].virtualwire.[2],flowdirection tx,capturestage post',
#
#  # must specify the verification type to 'pktcapuserworld' if you want to capture vxlan packets,
#   'verificationtype' => 'pktcapuserworld',
#
#  # vxlan id you want to verify, can be vxlan id directly or a tuple
#  #'vxlanid'      => "7676",
#   'vxlanid'      => "vsm.[1].networkscope.[1].virtualwire.[2]",
#
#   'pktcount'     => '10+',
#   'l3protocolheader' => '0x08',     #vxlan header flag
#   'pkttype'      => 'unicast',  #outer packet type
#   'tos'          => '0x0',      #outer packet tos value
#   'pcp'          => '0x0',      #outer packet VLAN PCP value
#   'innerpkttype' => 'unicast',  #inner packet type,can be a mac address or 'unicast', 'broadcast'
#   'innertos'     => '0x0',      #inner packet tos value
#   'innerpcp'     => '0x0',      #inner packet VLAN PCP value
# }
#
# Here is an STT example of how to use pktcap-uw tool
# 'PktCapVerificaton' => {
#   'target'       => 'host.[2].vmnic.[1]',
#
#   flowdirection can be tx or rx, capturestage can be post or pre
#   'pktcapfilter' => 'count 15,stt 7676,flowdirection tx,capturestage post,capturepoint UplinkSnd',
#   'pktcapfilter' => 'count 15,stt nsxmanager.[1].logicalswitch.[2],flowdirection tx,capturestage post',
#
#   The 'capturepoint' filter option adjusts the packet capture tap point
#   within the data path. For a list of valid capture points see
#   @VALID_CAPTUREPOINTS below or 'pktcap-uw -A' on an ESX host.
#
#   must specify the verification type to 'pktcapuserworld' if you want to capture vxlan packets,
#   'verificationtype' => 'pktcapuserworld',
#
#   vni id you want to verify, can be vni id directly or a tuple
#   'vni'      => "7676",
#   'vni'      => "nsxmanager.[1].logicalswitch.[2]",
#
#   'pktcount'     => '10+',
#   'sttflags'     => '0x40',     #stt header flag
#   'vtep'         => '0x08',     #stt header vtep id
#   'tci'          => '0x00',     #stt header VLAN Tci
#   'replicationbit' => '0x00',   #stt header replication bit
#   'pkttype'      => 'unicast',  #outer packet type
#   'tos'          => '0x0',      #outer packet tos value
#   'innerpkttype' => 'unicast',  #inner packet type
#   'innertos'     => '0x0',      #inner packet tos value
#   'innerl3protocol => 'arp'     #inner packet l3 protocol type, like
#                                  arp, icmp, ipv6
# }
#   other keywords may be implemented in future:
#   l4protocolheader
#   innerl3protocolheader
#   innerl4protocolheader
#   vlanid       # normal vlan id
#   srcip        # outer packet source ip
#   dstip        # outer packet destination ip
#   srcmac       # outer packet source mac
#   dstmac       # outer packet destination mac
#   innersrcip   # inner packet source ip
#   innerdstip   # inner packet destination ip
#   innersrcmac  # inner packet source mac
#   innerdstmac  # inner packet destination mac


# Inherit the parent class.
require Exporter;
use base qw(VDNetLib::Verification::PktCapVerification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;


use VDNetLib::Common::Utilities;

use PLSTAF;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger PERSIST_DATA_REGEX);

# This hash gives the allowed filter values a user can pass.
# This can be extended to support more values a user can pass.
my $allowedFilterWords = {
   'vlan'     => "--vlan",
   'count'    => "-c",
   'src host' => "--srcip",
   'dst host' => "--dstip",
   'flowdirection' => "--dir",
   'capturestage'  => "--stage",
   'capturepoint'  => "--capture",
   'vxlan'    => "--vxlan",
   'stt'      => "--vxlan",
   'ethtype'  => "--ethtype",
};

use constant MAX_PACKET_CAPTURE_COUNT => 5000;

###############################################################################
#
# new -
#       This method creates an object of PktCapUWVerification and returns it
#
# Input:
#       None
#
# Results:
#       Obj of PktCapUWVerification module
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;

   my $self  = {};
   bless ($self, $class);

   return $self
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
   if (defined $self->{expectedchange}->{vxlanid}) {
      $self->{expectedchange}->{vxlanid} =
                    $self->GetVirtualWireID($self->{expectedchange}->{vxlanid});
   } elsif (defined $self->{expectedchange}->{vni}) {
      $self->{expectedchange}->{vni} =
                    $self->GetLogicalSwitchID($self->{expectedchange}->{vni});
   }
   my $expectedChange = $self->{expectedchange};
   foreach my $k (keys %$expectedChange) {
      if ($self->{expectedchange}->{$k} =~ PERSIST_DATA_REGEX) {
         $self->{expectedchange}->{$k} = $self->ReadPersistData($expectedChange, $k);
      }
   }
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
#       string  - comma sepearted values of default target.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultTargets
{
   my $self = shift;
   return "dstvm";

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
   #return "guest,host";
   return "host";

}


###############################################################################
#
# AttachUserFilter -
#       Get the user defined filter words and attach them to filter string.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub AttachUserFilter
{
   my $self = shift;

   # 1) Read the filter options given by user.
   # 2) Keep them in an array after splitting from ','

   my $userFilter = $self->{expectedchange}->{pktcapfilter};
   delete $self->{expectedchange}->{pktcapfilter};
   my @filterArry;
   if (defined $userFilter) {
      if ($userFilter =~ /\,/i) {
         @filterArry = split(',',$userFilter);
      } else {
         $filterArry[0] = $userFilter;
      }
   } else {
      $vdLogger->Trace("No filter option given by user");
      return SUCCESS;
   }

   # 3) For each filter words given by user match it with the
   # filter word allowed.
   # 4) If it matches then generate filter expression using the
   # value passed by user and option from the allowe filter hash
   my $match = 0;
   foreach my $userFilter (@filterArry) {
      $match = 0;
      # To sepearte the key and values. E.g. count 1000
      $userFilter =~ /(.*)\s+(.*)$/;
      my $userFilterKey = $1;
      my $userFilterValue = $2;
      if ($userFilterKey =~ /vxlan$/i) {
         $userFilterValue = $self->GetVirtualWireID($userFilterValue);
      }
      if ($userFilterKey =~ /stt$/i) {
         $userFilterValue = $self->GetLogicalSwitchID($userFilterValue);
      }
      if ($userFilterKey =~ /flowdirection$/i) {
         if ($userFilterValue =~ /rx$/i) {
            $userFilterValue = 0;
         } elsif ($userFilterValue =~ /tx$/i) {
            $userFilterValue = 1;
         } else {
            $vdLogger->Error("filter flowdirection only support 'rx' or 'tx'");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      if ($userFilterKey =~ /capturestage$/i) {
         if ($userFilterValue =~ /pre$/i) {
            $userFilterValue = 0;
         } elsif ($userFilterValue =~ /post$/i) {
            $userFilterValue = 1;
         } else {
            $vdLogger->Error("filter capturestage only support 'pre' or 'post'");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      my @VALID_CAPTUREPOINTS = (
         'UplinkRcv',
         'UplinkSnd',
         'Vmxnet3Tx',
         'Vmxnet3Rx',
         'PortInput',
         'IOChain',
         'EtherswitchDispath',
         'EtherswitchOutput',
         'PortOutput',
         'TcpipDispatch',
         'PreDVFilter',
         'PostDVFilter',
         'Drop',
         'VdrRxLeaf',
         'VdrTxLeaf',
         'VdrRxTerminal',
         'VdrTxTerminal',
         'PktFree',
      );
      if ($userFilterKey =~ /capturepoint$/i) {
         if ($userFilterValue ~~ @VALID_CAPTUREPOINTS) {
            1;
         } else {
            $vdLogger->Error("filter capturepoint supports points listed by " .
                             "pktcap-uw -A: @VALID_CAPTUREPOINTS\n" .
                             "got capture point: " . Dumper($userFilterValue));
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      }
      if ($userFilterKey =~ /(dst host|src host)$/i) {
         my($type,$filterValue);
         if ($userFilterValue =~ /\//) {
            ($type,$filterValue) = split "/",$userFilterValue;
         } else {
            $filterValue = $userFilterValue;
         }
         $userFilterValue = $self->GetVnicAddress($filterValue,$type);
         if ($userFilterValue == -1) {
            $vdLogger->Error("Could not resolve the tuple or Invalid address".
               " type specified");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      }

      # Match the key with each filter option in $allowedFilterWords hash.
      foreach my $allowedFilter (keys %$allowedFilterWords) {
         my $userFilterKey = $userFilter;
         $userFilterKey =~ s/(\w+) (.*)/$1/;
         if ($allowedFilter =~ /$userFilterKey/i) {
            $match = 1;
            last;
         }
      }
      # Attach the filter option if it matched.
      if ($match == 0) {
         $vdLogger->Error("Unknown filter option passed by user:$userFilter");
         $vdLogger->Info("Allowed filters and usage:");
         foreach my $allowedFilter (keys %$allowedFilterWords) {
            $vdLogger->Info("$allowedFilter VALUE");
         }
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         my $filterStr = $allowedFilterWords->{$userFilterKey};
         $vdLogger->Debug("Attaching user given filter:".$filterStr . " " .
                          $userFilterValue);
         $self->{filterString} = $self->{filterString} . " " . $filterStr .
                                 " " . $userFilterValue . " and";
      }
   }

   return SUCCESS;

}


###############################################################################
#
# GenConstantFilter -
#       This method generates the constant part of filter and also
#       1. Generate file name with unique timestamp which will store captured
#          packets in raw form.
#       2. Checks if promiscuous mode needs to be enabled or not.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GenConstantFilter
{
   my $self = shift;
   my ($captureFile, $launchStatusFile);
   my $sourceDir;
   # We always attach sourceDir to be that of linux/MC because that
   # is the case in most scenarios.
   # When it is win we just use perl regex to replace the linux dir
   # with that of win dir.
   $sourceDir =  VDNetLib::Common::GlobalConfig::GetLogsDir();
   # capturefile is for storing stdout info when pktcapuw is
   # launched as async process. We attach useful info in the
   # filename to help in debugging.
   $captureFile = VDNetLib::Common::Utilities::GetTimeStamp();
   # Attaching the pid of the process to file Name
   $captureFile = $captureFile . "-" . $self->{target};
   # Seems like some flavors of windows dont like ":"
   # in the filename thus we replace : with -
   $captureFile =~ s/:/-/g;
   $launchStatusFile = "stdout-". $captureFile . "-$$.log";
   $launchStatusFile = $sourceDir . $launchStatusFile;

   $captureFile = "PktCap-". $captureFile . "-$$.pcap";
   $captureFile = $sourceDir . $captureFile;

   $self->{fileName} = $captureFile;
   $self->{launchstdout} = $launchStatusFile;
   # This flag maintains if the stopCapture method was called or not
   # if it is not called due to any error condition whatsoever it will
   # be called from Destructor, as destructor is called indefinately.
   $self->{stopCaptureCalled} = 0;
   if ($self->{os} =~ m/esx|vmkernel/i ) {
      $self->{filterString} = "-s 0";
   }
   return SUCCESS;
}


###############################################################################
#
# GenDynamicFilter -
#       Helps in generating filter string based on the traffic and adapter
#       settings. This translates the verification hash keyworkds into the
#       language which pktcapuw understands. E.g. When a hash has l3protocol
#       as IPv6 this method converts it into ip6. Simiarly, for a
#       sessionport of 49165 into "port 49165".
#       In future more keys can be interpreted and added to the filter.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GenDynamicFilter
{
   my $self = shift;
   my $workloadPtr = shift;
   my $appendWord;

   foreach my $key (keys %$workloadPtr) {
      $appendWord = undef;
      my $value = $workloadPtr->{$key};
      next if $value eq "";
      switch ($key) {
         case m/(^client$)/i {
            if ($workloadPtr->{toolname} != m/ping/i) {
               $appendWord = "--srcip $value->{testip} and";
            }
         }
         case m/(server)/i {
            # pktcap-uw tool cannot capture icmp messages if define srcip/dstip filters,
            # no matter it filters the inner packets ip or outer packets ip
            if ($workloadPtr->{toolname} != m/ping/i) {
               # In both inbound and outbound dst host is always server.
               if ((defined $workloadPtr->{routingscheme}) &&
                   ($workloadPtr->{routingscheme} =~ m/multicast/i)) {
                  $appendWord = "--dstip $value->{multicastip} and";
               } else {
                  $appendWord = "--dstip $value->{testip} and";
               }
            }
         }
         case m/(testduration)/i {
            if ($workloadPtr->{toolname} =~ m/ping/i) {
               # For ping we send number of packets equal to the
               # test duration. Thus we will capture only that number
               # of packets.
               $appendWord = "-c $value";
            } else {
               # In case of other tools we will capture number of
               # packets based on duration of test.
               # The current logic will capture 6000 packet in 60
               # sec. Thus more packets for larger duration tests
               # This way we can capture connection rst in long duration
               # tests, which is difficult in small duration/less packets test.
               my $pktCount = int($value) * 100;
               if (int($pktCount) > MAX_PACKET_CAPTURE_COUNT) {
                  $pktCount = MAX_PACKET_CAPTURE_COUNT;
               }
               $appendWord = "-c $pktCount";
            }
         }
         case m/(l3protocol)/i {
            if ($value =~ /6$/) {
               $appendWord = "ip6 and";
            } else {
               $appendWord = "ip and";
            }
         }
         else {
            next;
         }
      }
      # Dont attach the filter string in case user has already
      # set the value for that filter option
      if (defined $appendWord) {
         # We get the first word from the filter option e.g. count 5000
         # and if count is already there in filter string then we don't
         # append it as we dont want to override the filter values set
         # by the user.
         my $wordAnd = "";
         if ($appendWord =~ / and$/i) {
            $appendWord =~ s/ and//;
            $wordAnd = " and";
         }
         $appendWord =~ m/(.*) (.*)$/i;
         my $firstWord = $1;
         if (defined $firstWord) {
            if ($self->{filterString} !~ / $firstWord /) {
               # count is not allowed at end of filter
               # WRONG -Z root -n src host 172.188.1.1 and dst host 172.188.1.2 and -c 1000
               # RIGHT -c 1000 -Z root -n src host 172.188.1.1 and dst host 172.188.1.2
               # Thus adding count -c at the beginning of filter String.
               $appendWord = $appendWord . $wordAnd;
               if ($firstWord =~ /\-c/) {
                  $self->{filterString} = $appendWord ." " . $self->{filterString};
               } else {
                  $self->{filterString} = $self->{filterString} . " " . $appendWord;
               }
            } else {
               $vdLogger->Debug("Not appending filter option: $appendWord to".
                                " filter as it exits: $self->{filterString}");
            }
         } # if defined firstword block
      } # if defined appendword block
   }

   return SUCCESS;

}


###############################################################################
#
# GetTemplate -
#       Returns the default nodes on each platform type for this kind of
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

sub GetBucket
{
   my $self = shift;

   # This is our specification. We generate the packet stats according
   # to this specification.
   # This template works for any OS. We store it this way to comply with
   # the parent interface.

   my $template = $self->{pktcapbucket}->{nodes}->{pktcapuw}->{template};

   # If not defined then we init the tempalte for the first time.
   # else we always return the template stored in capturebucket
   if (defined $template) {
      return $self->{pktcapbucket};
   }

   $template = {
      # Expect 1 or more packets as default. Otherwise a 0-count expectation
      # can be matched and yield Workload PASS without capturing packets.
      pktcount       => "1+",
      minpktsize     => "0",
      maxpktsize     => "0",
      pktcksumerror  => "0",
      badpkt         => "0",
      retransmission => "0",
      avgpktlen      => "0",
      connectionRST  => "0",
      truncatedpkt   => "0",
      tos            => "0",
   };
   if ((defined $self->{expectedchange}) &&
       (exists $self->{expectedchange}->{pktcount})) {
         $template->{pktcount} = $self->{expectedchange}->{pktcount};
         $vdLogger->Info("pktcount in stats template is set to $template->{pktcount}");
   }

   if (defined $self->{expectedchange}->{innertos}) {
      # for vxlan packets we have the req that we should verify the outer tos
      # copied from inner tos
      $template->{innertos} = "0";
   }
   if (defined $self->{expectedchange}->{vxlanid}) {
      $template->{vxlanid} = "0";
   }
   if (defined $self->{expectedchange}->{sttflags}) {
      $template->{sttflags} = "0";
   }
   if (defined $self->{expectedchange}->{tci}) {
      $template->{tci} = "0";
   }
   if (defined $self->{expectedchange}->{vni}) {
      $template->{vni} = "0";
   }
   if (defined $self->{expectedchange}->{pcp}) {
      $template->{pcp} = "0";
   }
   if (defined $self->{expectedchange}->{innerpcp}) {
      $template->{innerpcp} = "0";
   }
   if (defined $self->{expectedchange}->{vtep}) {
      $template->{vtep} = "0";
   }
   if (defined $self->{expectedchange}->{innerl3protocol}) {
      $template->{innerl3protocol} = "0";
   }
   if (defined $self->{expectedchange}->{replicationbit}) {
      $template->{replicationbit} = "0";
   }
   if (defined $self->{expectedchange}->{l3protocolheader}) {
      $template->{l3protocolheader} = "0";
   }
   if (defined $self->{expectedchange}->{pkttype}) {
      $template->{pkttype} = "0";
   }
   if (defined $self->{expectedchange}->{innerpkttype}) {
      $template->{innerpkttype} = "0";
   }
   if (defined $self->{expectedchange}->{arpsourceip}) {
      $template->{arpsourceip} = "0";
   }
   if (defined $self->{expectedchange}->{arpdestinationip}) {
      $template->{arpdestinationip} = "0";
   }
   #
   # We store all the expected and actual pktcap stats in a bucket.
   # bucket -> AnyOS -> A node on that OS(SUT:vnic:1)
   # This node will have template, actual pkt capture stats.
   #
   $self->{pktcapbucket}->{nodes}->{pktcapuw}->{template} = $template;
   return $self->{pktcapbucket};
}


###############################################################################
#
# BuildToolCommand -
#       This method builds the command(binary) for this verification tool.
#       1. For linux pktcapuw
#       2. For windows
#          a. Based on the OS, get the binariespath from
#             VDNetLib::Common::GlobalConfig
#          b. Set command to the windump path after copying it to another dir.
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub BuildToolCommand
{
   my $self = shift;
   my $arch = $self->{arch};
   my $os = $self->{os};
   my $targetIP = $self->{targetip};
   my ($command, $wincmd, $result);


   if ($os =~ m/(esx|vmkernel)/i) {
      $self->{bin} = "pktcap-uw";
   }
   else {
      $vdLogger->Error("OS $os not supported for building ToolCommand.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "$self->{bin} -h ";
   $result = $self->{staf}->STAFSyncProcess($self->{targetip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # A -h query on the tool make sure the tool is working on the remote
   # OS. This will help in few flavor os GOS in case pktcapuw binary on vdnet
   # does not work on any flavor we will know early.

   # 'pktcap-uw -h' command output not have version info, use 'usage' instead
   if ($result->{stdout} !~ /usage/i) {
      $vdLogger->Error("Something wrong with the $self->{bin} binary".
                       " stdout:$result->{stdout}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Trace("Built command:$self->{bin} for os:$os");
   return SUCCESS;
}

###############################################################################
#
# Start -
#       Checks if the filter string is appropriate. Runs staf command to start
#       capture process on respective OS. Queries the process handle to see
#       if the process was started successfully. Saves the process handle.
#
# Input:
#       None.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub Start
{
   my $self = shift;
   my ($command, $result);
   my $host = $self->{targetip};
   my $fileName = $self->{fileName};
   my $stdoutName = $self->{launchstdout};
   my $filterString = $self->{filterString};
   my $os = $self->{os};
   my $binary = $self->{bin};
   my $interface;
   my $opts = undef;

   # remove the last word "and" from the filter string.
   # remove the word "and" after packet count -c as pktcapuw does not like it
   $filterString =~ s/and$//ig;
   $filterString =~ s/-c (\d+) and/-c $1 /ig;
   # PR 1389572: no "and" after "--vxlan"|"--dir"
   $filterString =~ s/--vxlan (\d+) and/--vxlan $1 /ig;
   $filterString =~ s/--dir (\d+) and/--dir $1 /ig;

   if ($os =~ m/(esx|vmkernel)/i) {
      # For linux/ESX interface would be like ethX.
      $interface = $self->{pktcapinterface};
      # handle pktcap-uw capture tool here
      if ($self->{adapterobj}->{intType} eq "vmnic") {
         $command = "$binary --uplink $interface ";
      } elsif ($self->{adapterobj}->{intType} eq "vmknic") {
         $command = "$binary --vmk $interface ";
      }
      $command = "$command $filterString -o $fileName";
      $vdLogger->Info("Launching pcap($binary) in ".
                     "$self->{target}($host) at $interface($self->{nodeid})");
   }

   $vdLogger->Info("Filter-String:$filterString -o $fileName");
   $result = $self->{staf}->STAFAsyncProcess($host, $command,
                                             $stdoutName, $opts);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{processHandle} = $result->{handle};
   $vdLogger->Debug("Successfully launched PacketCapture with handle:".
                    "$self->{processHandle}");
   return SUCCESS;

}


##############################################################################
#
# GetVirtualWireID --
#       Method to get the virtual wire vxlan id
#
# Input:
#       component -- a virtual wire tuple object(required).
#
# Results:
#       Virtual Wire vxlan id.
#       -1 in case of any error
#
# Side effects:
#       None
#
##############################################################################

sub GetVirtualWireID
{
   my $self      = shift;
   my $component = shift;
   my $ref       = undef;
   my $vWireObj  = undef;

   if ($component =~ /^\d+$/) {
      # not a tuple, return the vWireId directly
      return $component;
   }
   $ref = $self->{testbed}->GetComponentObject($component);
   if ((not defined $ref) || ($ref eq FAILURE)) {
      $vdLogger->Error("Invalid ref for tuple $component");
      # will not return FAILURE here if meet error, since VerificationSpecificJob
      # always return SUCCESS
      return -1;
   }
   $vWireObj = $ref->[0];
   return $vWireObj->{vxlanId};
}


##############################################################################
#
# GetLogicalSwitchID --
#       Method to get the logical switch vni id
#
# Input:
#       component -- a logical switch tuple object(required).
#
# Results:
#       local switch vni id
#       -1 in case of any error
#
# Side effects:
#       None
#
##############################################################################

# TODO(mqing, jschmidt): Could remove this duplicate method let fall through
# to the parent's implementation. Others as well?
sub GetLogicalSwitchID
{
   my $self      = shift;
   my $component = shift;
   my $ref       = undef;
   my $switchObj  = undef;

   if ($component =~ /^\d+$/) {
      # not a tuple, return the vni id directly
      return $component;
   }
   $ref = $self->{testbed}->GetComponentObject($component);
   if ((not defined $ref) || ($ref eq FAILURE)) {
      $vdLogger->Error("Invalid ref for tuple $component");
      # will not return FAILURE here if meet error, since
      # VerificationSpecificJob always return SUCCESS
      return -1;
   }
   $switchObj = $ref->[0];
   return $switchObj->get_switch_vni({});
}
1;
