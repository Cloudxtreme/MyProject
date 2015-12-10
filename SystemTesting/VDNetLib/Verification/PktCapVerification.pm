#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::PktCapVerification;

#
# This module gives object for packet capture verification. It deals
# with filter string generation in 3 parts.
# 1) A constant filter 2) User defined filter values 3) Filter based on
# traffic or any other workload.
# It Capturs packets according to this filter.
# Converts the tcpdump capture file to human readable format and reads the
# file for errors, packet drops or other desired patterns. Gives out this
# result to user of this package.
#
# Usage:
# Here is an example of how to use tcpdump tool in a test VM, in the example,
# tcpdump will be launched to capture 5 ICMP echo request packets, matching
# with wanted source ip and destination ip, with ttl 12.

# 'PktCapVerificaton':
#    'verificationtype': 'pktcap'
#    'target': 'vm.[1].vnic.[1]'
#    'pktcapfilter': 'count 5,ttl == 12,icmptype == 8,src host ipv4/vm.[2].vnic.[1],dst host ipv4/vm.[1].vnic.[1]'
#    'pktcount': '1-10'
#
#   # must specify the verification type to 'pktcap' for tcpdump
#   'verificationtype' => 'pktcap',
#
#   count 5          # tcpdump option -c, Exit after receiving 5 packets.
#   ttl == 12        # capture packets whose ttl is 12
#   icmptype == 8    # ICMP echo request
#   src host         # source ip address
#   dst host         # destination ip address
#
# All supported filters may be found in allowedFilterWords below, and more
# filters may be added according to the rules.

# To this knowledge the verification of following is not possible through
# packet capture.
# DeviceStatus
# WoL
# Rings
# Queues
# RSS
# Buffers


# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Verification::Verification);

use strict;
use warnings;
use Storable qw(dclone);
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;


use VDNetLib::Common::Utilities;

use PLSTAF;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger IP_REGEX TRUE FALSE);

use constant DELIMITER_LEN => 60;
use constant ARP_REQUEST => '0x0806';
my @VALID_KEYS = ("dstmac", "pkttype", "l3protocolheader", "tos",
                  "pcp", "arpsourceip", "arpdestinationip",
                  "innerdstmac", "innersrcmac", "innerpkttype",
                  "innerarpsourceip", "innerarpdestinationip",
                  "innertos", "innerl3protocol", "innerl4protocol",
                  "vxlanid", "sttflags", "tci", "vni", "innerpcp",
                  "replicationbit", "vtep","garpdestinationip");
# This hash gives the allowed filter values a user can pass.
# This can be extended to support more values a user can pass.
my $allowedFilterWords = {
   'vlan'     => "vlan",
   'count'    => "-c",
   'size >'   => "greater",
   'size <'   => "less",
   'tos'     => "<hex>",
   'src host' => "src host",
   'dst host' => "dst host",
   'snaplen' => "-s",
   'tcp-syn =='  => "tcp[tcpflags] & tcp-syn ==",
   'tcp-syn !='  => "tcp[tcpflags] & tcp-syn !=",
   'tcp-ack =='  => "tcp[tcpflags] & tcp-ack ==",
   'tcp-ack !='  => "tcp[tcpflags] & tcp-ack !=",
   'tcp-fin =='  => "tcp[tcpflags] & tcp-fin ==",
   'tcp-fin !='  => "tcp[tcpflags] & tcp-fin !=",
   'tcp-push =='  => "tcp[tcpflags] & tcp-push ==",
   'tcp-push !='  => "tcp[tcpflags] & tcp-push !=",
   'tcp-urg =='  => "tcp[tcpflags] & tcp-urg ==",
   'tcp-urg !='  => "tcp[tcpflags] & tcp-urg !=",
   'tcp-rst =='  => "tcp[tcpflags] & tcp-rst ==",
   'tcp-rst !='  => "tcp[tcpflags] & tcp-rst !=",
   'icmptype ==' => "icmp[icmptype] ==",
   'icmpcode ==' => "icmp[icmpcode] ==",
   'dst port' => "dst port",
   'ttl ==' => "ip[8] ==",
   'ether src' => "ether src",
   'ether dst' => "ether dst",
};

# This hash gives the conversion from ipv4 icmpcode to ipv6
# equivalent icmpcode used by tcpdump
# more icmpcodes supported by icmpv6 can be added here as needed
my $icmp_code_ipv4_to_v6 = {
   "0" => "0",   # Network Unreachble
   "10" => "1",  # host is administratively prohibited
   "3" => "4",   # port Unreachable
   "1" => "3",   # host Unreachable
};

# tcpdump does not understand filterstring for eg:"icmp[icmptype] == icmp-reach"
# in case of IPv6 and needs the exact byte offset in the packet and its value
# to filter. The same filter will look like "ip6[40] == 1"
# This hash gives the ipv6 equivalent value for the user passed ipv4 icmptype
# string for use by tcpdump for IPv6.
# more icmptypes supported by icmpv6 can be added here as needed
my $icmp_type_ipv4_to_v6 = {
   "icmp-echoreply" => "129",
   "icmp-unreach" => "1",
   "icmp-redirect" => "137",
   "icmp-echo" => "128",
   "icmp-routeradvert" => "134",
   "icmp-routersolicit" => "133",
   "icmptimxceed" => "3",
   "icmp-paramprob" => "4",
};

# tcpdump does not understand filterstring for eg:"tcp[tcpflags] & tcp-rst != 0"
# in case of IPv6 and needs the exact byte offset in the packet and its value
# to filter. The same filter will look like "ip6[53] & 4 != 0"
# This hash gives the ipv6 equivalent filter value to be used for various
# tcpflags
my $tcpflags_ipv4_to_v6 = {
   "tcp-fin" => "1",
   "tcp-syn" => "2",
   "tcp-rst" => "4",
   "tcp-push" => "8",
   "tcp-ack" => "16",
   "tcp-urg" => "32",
};

use constant MAX_PACKET_CAPTURE_COUNT => 5000;
use constant DEFAULT_PKT_CAP_COUNT_FOR_OLD_TESTCASES => "100+";

###############################################################################
#
# new -
#       This method creates an object of PktCapVerification and returns it
#
# Input:
#       None
#
# Results:
#       Obj of PktCapVerification module
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
# RequiredParams -
#       This is a child method. It says what param does it need from testbed
#       traffic or netadapter to intialize verification.
#
# Input:
#       none
#
# Results:
#       pointer to an arry of params
#
# Side effects:
#       None
#
###############################################################################

sub RequiredParams
{
   #TODO: PR#: 793676
   my $self = shift;
   my $os = $self->{os};

   my @params = ("pktcapinterface");

   return \@params;
}


##############################################################################
#
# GetChildHash --
#       Its a child method. It returns a conversionHash which is specific to
#       what child wants from a testbed and workload hash and how it wants
#       to store that information locally. Advantages 1) Changes in testbed
#       will not affect the entire module, just need to change the key in this
#       hash, 2) Creates local var of that testbed/workload key
#       E.g. macAddress from testbed will be stored as mac locally.
#
# Input:
#       none
#
# Results:
#       conversion hash - a hash containging node info in language verification
#                         module understands.
#
# Side effects:
#       None
#
##############################################################################

sub GetChildHash
{
   my $self = shift;
   my $spec = {
      'testbed'               => {
         'hostobj'         =>  {
            'hostIP'         =>  'host',
            },
         'adapter'         =>   {
            'driver'            => 'drivername',
            'macAddress'        => 'mac',
            # In case of esx we need to use deviceId and netstack for tcpdump
            'deviceId'          => 'esxpktcapinterface',
            'netstack'          => 'netstack',
            # For linux interface will be used.
            'interface'         => 'pktcapinterface',
            # In case of windows we need to use hwid for WinDump
            'hwid'              => 'pktcapinterface',
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
   # To keep the code backward compatible to old testcases.
   my $expectedChange = $self->{expectedchange};
   if ( (!keys %$expectedChange) && $self->GetBackwardCompatibility() ) {
      $self->{expectedchange}->{pktcount} = DEFAULT_PKT_CAP_COUNT_FOR_OLD_TESTCASES;
   }
   if($self->{os} =~ /vmkernel|esx/i) {
      $self->{pktcapinterface} = $self->{esxpktcapinterface};
   }
   if (defined $self->{expectedchange}->{vxlanid}) {
      $self->{expectedchange}->{vxlanid} =
                    $self->GetVirtualWireID($self->{expectedchange}->{vxlanid});
   } elsif (defined $self->{expectedchange}->{vni}) {
      $self->{expectedchange}->{vni} =
                    $self->GetLogicalSwitchID($self->{expectedchange}->{vni});
   }
   return SUCCESS;
}


###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#       This list is used in case user does not specify any child
#       module for this verification type.
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
   #TODO: PR#: 793676
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
   return "guest,host";

}


###############################################################################
#
# InitVerification -
#       Initialize verification on this object. 1) Build Command 2) Build
#       filter string.
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

sub InitVerification
{
   my $self = shift;
   my $veriType = $self->{veritype};

   # Check if we have all the required params needed for this verification.
   my $allparams = $self->RequiredParams();
   foreach my $param (@$allparams) {
      if (not exists $self->{$param}) {
      $vdLogger->Error("Param:$param missing in InitVerification for".
                       " $veriType"."Verification");
      VDSetLastError("ENOTDEF");
      return FAILURE;
      }
   }

   if ($self->BuildToolCommand() ne SUCCESS) {
      $vdLogger->Error("PktCapVerification BuildToolCommand() didnt".
                       " return Success");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # There are three part of the filter we generate
   # 1) Constant + 2) user supplied 3) based on the traffic flow
   if ($self->GenConstantFilter() ne SUCCESS) {
      $vdLogger->Error("PktCapVerification GenConstantFilter() didnt".
                       " return Success");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($self->AttachUserFilter() ne SUCCESS) {
      $vdLogger->Error("PktCapVerification AttachUserFilter() didnt".
                       " return Success");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($self->GenDynamicFilter($self->{workloadhash}) ne SUCCESS) {
      $vdLogger->Error("PktCapVerification GenDynamicFilter() didnt".
                       " return Success");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
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

      # To sepearte the key and values. E.g. count 1000
      $userFilter =~ /(.*) (.*)$/;
      my $userFilterKey = $1;
      my $userFilterValue = $2;
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
      if ($userFilterKey =~ /(ether dst|ether src)$/i) {
         $userFilterValue = $self->GetVnicMac($userFilterValue);
         if ($userFilterValue == -1) {
            $vdLogger->Error("Could not resolve the tuple or Invalid mac address");
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
         if ($filterStr =~ /-s$/) {
            $self->{filterString} =~ s/-s \d+/-s $userFilterValue/;
         } elsif ($filterStr =~ /(icmptype|icmpcode|tcpflags|tcp-)/) {
            # pkttype and inside pkt flag check condition has to be within single
            # quotes
            $self->{filterString} = $self->{filterString} . " \'" . $filterStr .
                                 " " . $userFilterValue . "\'" . " and";
         } else {
            $self->{filterString} = $self->{filterString} . " " . $filterStr .
                                    " " . $userFilterValue . " and";
         }
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
   my $promiscuousFlag;
   #
   # Based on the name of target we can say that its the src/dst or
   # some sniffer node.
   # If a target is srcVM, srcHost, dstVM, dstHost then it means these are nodes
   # actively seens the packets thus no need to enable promiscuous mode as we
   # already capture limited num of packets (without a very specific filter)
   # If a target is say host.[1].vnic.[1] then it is assumed that
   # it is some sniffer node thus we put this node in promiscuous mode
   # A traffic always needs src and dst, thus a node with "." in it will be
   # a sniffer node.
   #
   if ($self->{target} =~ /\./i) {
      # Tcpdump/Windump will be launched on a sniffer VM/Host's interface
      # For putting the adapter in promiscuous mode.
      $promiscuousFlag = " ";
      $vdLogger->Info("Enabling Promiscuous mode on $self->{pktcapinterface} ".
                      "for pcap in $self->{targetip}");
   } else {
      # For not putting the adapter in promiscous mode.
      $promiscuousFlag = " -p ";
   }

   $vdLogger->Trace("Pkts will be captured on ".
                    "$self->{target}($self->{targetip}). ");
   # We always attach sourceDir to be that of linux/MC because that
   # is the case in most scenarios.
   # When it is win we just use perl regex to replace the linux dir
   # with that of win dir.
   $sourceDir =  VDNetLib::Common::GlobalConfig::GetLogsDir();
   # capturefile is for storing stdout info when tcpdump is
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
   # Filter string consists of 1) Static hard-coded values 2) Dynamic values
   # which are based on type of traffic and adapter settings. Static part:
   # -p for promiscuous mode
   # -e for printing the link-level/ethernet header on each dump line
   # -vvv for verbose output.
   # -S is for printing absolute sequence numbers.
   # -s is the number of bytes you want to capture. give 1514 (to get
   #    everything). Larger lenght also increases processing time thus
   #    more packets might get dropped. Setting snaplen to
   #    0 means use the required length to catch whole packets.
   # -C for checking whether the file is currently larger than file_size
   #    and, if so, close the current savefile and open a new one. This is
   #    checked before writing raw packet to a savefile. The captured
   #    packets are stored in 200MB files. The first file will have the name
   #    given by the user. The succeeding files will have the name given
   #    by the user succeeded by 1,2.. and so on. For this reason, no
   #    filename should end with a number.
   # -Z Not sure why we use(Legacy)
   # -n By default tcpdump performs DNS query to lookup hostname
   #    associated with an IP address and uses the hostname in
   #    the output. -n stops conversion of hostname
   if ($self->{os} =~ m/esx|vmkernel/i) {
      $self->{filterString} = $promiscuousFlag . " -e -vvv -S -s 0 -B 100 ".
                                                 "-C 200 -Z root -n";
   } else {
      $self->{filterString} = $promiscuousFlag . " -e -vvv -S -s 0 -C 200 ".
                                                 "-Z root -n";
   }
   return SUCCESS;
}


###############################################################################
#
# GenDynamicFilter -
#       Helps in generating filter string based on the traffic and adapter
#       settings. This translates the verification hash keyworkds into the
#       language which tcpdump understands. E.g. When a hash has l3protocol
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
   my $isL3ProtocolIPv6;
   my $isEncapsulated = 0;
   # Making the keys lower case so as to make
   # the comparision case insensitive
   $workloadPtr->{toolname} = lc($workloadPtr->{toolname});
   my $veriHash = $self->{verihash}->{pktcapverification};
   if (defined $veriHash->{expectencapsulatedtraffic}) {
      if ($veriHash->{expectencapsulatedtraffic} =~ /true|yes/i) {
          $isEncapsulated = 1;
      }
   }
   foreach my $key (keys %$workloadPtr) {
      $appendWord = undef;
      my $value = $workloadPtr->{$key};
      next if $value eq "";
      switch ($key) {
         case m/(^client$)/i {
            # In both inbound and outbound src host is always client
            # reason being SUT or helper can acquire the role of client
            # but for packetcapture client only generates the packets
            # and thus is the src host all the time.
            # Also in inbound session client becomes helper we need not
            # worry if we are capturing RX path packets in inbound session.
            # It is already taken care of. Similarly for TX path.
            # For STT packets, both src and dst won't work because it is
            # encaptured in tunnel
            my $toolname = lc($workloadPtr->{toolname});
            if ($toolname ne "ping" and $toolname ne "arpping" and
                $toolname ne "scapy" and $isEncapsulated == 0) {
               $appendWord = "src host $value->{testip} and";
            }
         }
         case m/(server)/i {
            # In both inbound and outbound dst host is always server.
            if ((defined $workloadPtr->{routingscheme}) &&
                ($workloadPtr->{routingscheme} =~ m/multicast/i) &&
                ($isEncapsulated == 0)) {
               $appendWord = "dst host $value->{multicastip} and";
            } else {
              # For STT packets, both src and dst won't work because it is
              # encaptured in tunnel
              my $toolname = lc($workloadPtr->{toolname});
              if ($toolname ne "ping" and $toolname ne "arpping" and
                  $toolname ne "scapy" and $isEncapsulated == 0) {
                 $appendWord = "dst host $value->{testip} and";
              }
            }
         }
         case m/(testduration)/i {
            # Diff from arping and ping
            if ($workloadPtr->{toolname} =~ m/^ping/i) {
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
         case m/(l4protocol)/i {
            if ($workloadPtr->{routingscheme} =~ m/multicast/i) {
               #TODO: We can try the igmp inside a UDP packet for multicast
               $appendWord = undef;
              # Diff from ping between arping
            } elsif ($workloadPtr->{toolname} =~  m/^ping/i && $value ne "") {
               if ($self->{filterString} !~ /(icmpcode|icmptype)/i &&
                   $isEncapsulated == 0) {
                  # Append the icmp-echo filter if there is NO user specified
                  # icmp filter already present
                  $appendWord = "'icmp[icmptype] == icmp-echo' and";
               }
            } elsif ($value ne "") {
               $appendWord = "$value and";
            }
         }
         case m/(l3protocol)/i {
            if ($value =~ /6$/ && $isEncapsulated == 0) {
               $appendWord = "ip6 and";
               $isL3ProtocolIPv6 = 1;
            } else {
               $appendWord = "ip and";
            }
         }
         case m/(sendmessagesize)/i {
            # We cannot capture packets greater than MTU size.
            # Max possible MTU size can be 9000 with JF.
            # If SendMessageSize > MTU then we set MTU
            # else we set the greater SendMessageSize.
            my $mtu = $workloadPtr->{server}->{mtu};
            if (int($value) < int($mtu)) {
               $appendWord =  "greater $value and"
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

   # If l3Protocol is IPv6, then replace the user specified ipv4 filter strings
   # to corresponding IPv6 filters
   if (defined $isL3ProtocolIPv6 && $isEncapsulated == 0) {
      $vdLogger->Debug("BEFORE IPv4 to IPv6 Conversion FilterString = $self->{filterString}");
      $self->{filterString} =~ s/icmp\[icmptype\]\s+==\s+([\w\-]+)/ip6\[40\] == $icmp_type_ipv4_to_v6->{$1}/i;
      $self->{filterString} =~ s/icmp\[icmpcode\]\s+==\s+(\d+)/ip6\[41\] == $icmp_code_ipv4_to_v6->{$1}/i;
      $self->{filterString} =~ s/tcp\[tcpflags\]\s+&\s+(.*)\s+(!=|==)\s+(\d+)/ip6\[53\] & $tcpflags_ipv4_to_v6->{$1} $2 $3/i;
      $vdLogger->Debug("AFTER IPv4 to IPv6 Conversion FilterString = $self->{filterString}");
   }
   # TODO: See if there is a need to generate filter based on
   # netadapter configuration e.g. vlans mtu etc

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

   my $template = $self->{pktcapbucket}->{nodes}->{tcpdump}->{template};

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
   if (defined $self->{expectedchange}->{vtep}) {
      $template->{vtep} = "0";
   }
   if (defined $self->{expectedchange}->{innerl3protocol}) {
      $template->{innerl3protocol} = "0";
   }
   if (defined $self->{expectedchange}->{innerl4protocol}) {
      $template->{innerl4protocol} = "0";
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
   if (defined $self->{expectedchange}->{dstmac}) {
      $template->{dstmac} = "0";
   }
   if (defined $self->{expectedchange}->{innerdstmac}) {
      $template->{innerdstmac} = "0";
   }
   if (defined $self->{expectedchange}->{innersrcmac}) {
      $template->{innersrcmac} = "0";
   }
   if (defined $self->{expectedchange}->{pcp}) {
      $template->{pcp} = "0";
   }
   if (defined $self->{expectedchange}->{innerpcp}) {
      $template->{innerpcp} = "0";
   }
   if (defined $self->{expectedchange}->{arpsourceip}) {
      $template->{arpsourceip} = "0";
   }
   if (defined $self->{expectedchange}->{arpdestinationip}) {
      $template->{arpdestinationip} = "0";
   }
   if (defined $self->{expectedchange}->{garpdestinationip}) {
      $template->{garpdestinationip} = "0";
   }
   if (defined $self->{expectedchange}->{innerarpsourceip}) {
      $template->{innerarpsourceip} = "0";
   }
   if (defined $self->{expectedchange}->{innerarpdestinationip}) {
      $template->{innerarpdestinationip} = "0";
   }

   $vdLogger->Trace("Using pktcap stats template as:\n" . Dumper($template));
   #
   # We store all the expected and actual pktcap stats in a bucket.
   # bucket -> AnyOS -> A node on that OS(SUT:vnic:1)
   # This node will have template, actual pkt capture stats.
   #
   $self->{pktcapbucket}->{nodes}->{tcpdump}->{template} = $template;
   return $self->{pktcapbucket};
}


###############################################################################
#
# BuildToolCommand -
#       This method builds the command(binary) for this verification tool.
#       1. For linux tcpdump
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

   if (not defined $os)
   {
      $vdLogger->Error("OS Type has not been set/defined");
      return FAILURE;
   }
   if ($os =~ m/linux/i) {
      #TODO: Remove /sbin/ from below after addinf tcpdump to the system path
      $self->{bin} = "tcpdump";
   } elsif ($os =~ m/win/i) {
      my ($globalConfigObj, $binpath, $binFile, $path2Bin);
      $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      $binpath = $globalConfigObj->BinariesPath(
                               VDNetLib::Common::GlobalConfig::OS_WINDOWS
                                               );
      $path2Bin = "$binpath" . "$arch\\\\windows\\\\";
      $binFile = "WinDump.exe";
      $self->{bin}  = $path2Bin . $binFile;
      my $winLocalDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
      #TODO: Consolidate the tool copying algorithm in all tool based modules.
      #Do this when you add copying binaries in SetUpAutomation code.
      $wincmd = "\"my \$localToolsDir=\'$winLocalDir\';".
                                  "my \$ns = \'$winLocalDir$binFile\';".
                                  "my \$src = \'$self->{bin}\';".
                                  "((-d \$localToolsDir)||".
                                   "(mkdir \$localToolsDir))&&".
                                   "(`copy \$src \$localToolsDir`);".
                                   "((-d \'c:\\temp\') || ".
                                   "(mkdir \'c:\\temp\'))\"";

      $command = "perl -e ". $wincmd;
      $result = $self->{staf}->STAFSyncProcess($self->{targetip},
                                               $command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $self->{bin}  = $winLocalDir . $binFile;
      $self->{bin} =~ s/\\\\/\\/g;
      $vdLogger->Debug("binary is changed to $self->{bin} for os:$os");

      # File check needs to be done only in case of windows as tcpdump
      # always exists by default on linux.
      $result = $self->{staf}->IsFile($self->{targetip}, $self->{bin});
      if (not defined $result) {
         $vdLogger->Debug("File:$self->{bin} missing on $self->{targetip}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      } elsif ($result ne 1) {
         $vdLogger->Debug("File:$self->{bin} missing on $self->{targetip}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      $self->{bin}  = "tcpdump-uw";
   } elsif ($os =~ m/mac|darwin/i) {
      my ($globalConfigObj, $binpath, $binFile, $path2bin);
      $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      $binpath = $globalConfigObj->BinariesPath(
                                   VDNetLib::Common::GlobalConfig::OS_MAC);
      $path2bin = "$binpath" . "$arch/mac/";
      $binFile = "tcpdump";
      $self->{bin}  = $path2bin . $binFile;
   } else {
      $vdLogger->Error("Unknown os:$os for building ToolCommand");
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
   # OS. This will help in few flavor os GOS in case tcpdump binary on vdnet
   # does not work on any flavor we will know early.
   if (($result->{stdout} !~ /version/i) && ($result->{stderr} !~ /version/i)) {
      $vdLogger->Error("Something wrong with the $self->{bin} binary".
                       " stdout:$result->{stdout}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # TODO: Can say supported == yes for this node.

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
   my $netstack = $self->{netstack};
   my $interface;
   my $opts = undef;

   # remove the last word "and" from the filter string.
   # remove the word "and" after packet count -c as tcpdump does not like it
   $filterString =~ s/and$//ig;
   $filterString =~ s/-c (\d+) and/-c $1 /ig;

   if ($os =~ m/win/i) {
      # If you launch a program on win using staf, staf creates a cmd terminal
      # and return the PID of that cmd terminal. Thus when you want to kill
      # the program it will kill the cmd process which launched the program
      # and not the program. We pass noshell while launching this command
      # which does not launch process using cmd terminal.
      $opts->{NoShell} = 1;
      # Get the windows directory from GlobalConfig.
      my $winDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
      # Remove the linux dir path and prepend windows dir path
      $fileName =~ s/.+\//$winDir/;
      $stdoutName =~ s/.+\//$winDir/;
      if ($self->{pktcapinterface} !~ /^(\d+)$/) {
         # it is a not a digit means it is a GUID, get the windumpindex
         my $windex = $self->GetWinDumpIndex($self->{targetip},
                                             $self->{pktcapinterface});
         if ($windex =~ /^\d+$/) {
            $self->{pktcapinterface} = $windex;
            $interface = $windex;
            $vdLogger->Debug("Windows windump interface index:$windex ");
         } else {
            $vdLogger->Error("Unable to find windump index:$windex for ".
                             "interface");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      } else {
         # In case it is digit it will already be the index. Though
         # it is rare possbility that testbed will give index instead of
         # GUID.
         $interface = $self->{pktcapinterface};
      }
   } else {
      # For linux/ESX interface would be like ethX.
      $interface = $self->{pktcapinterface};
   }

   #
   # Command to run tcpdump/windump on the remote host.
   # using -w file_name it writes the raw packets to file rather than parsing
   # and printing them on stdout.
   #
   if ($os =~ m/(esx|vmkernel)/i) {
      #
      # for vmkernel when using -v and -w together tcpdump exits. See
      # PR 961944 for details. Once pr 961944 is fixed use -w to dump
      # raw packets to the file.
      #
      $command = "$binary ++netstack=$netstack -i $interface $filterString ".
                 "> $fileName";
      $vdLogger->Info("Launching pcap($binary) with netstack $netstack in ".
                      "$self->{target}($host) at $interface($self->{nodeid})");
   } else {
      $command = "$binary -i $interface -w $fileName $filterString";
      $vdLogger->Info("Launching pcap($binary) in $self->{target}($host) at ".
                   "$interface($self->{nodeid})");
   }

   $vdLogger->Info("Filter-String:$filterString -w $fileName");
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


###############################################################################
#
# UpdateFilterString -
#       Checks for an existing keyword in the filter string and replaces the
#       updated value if it fits the criteria. The criteria depends on the
#       new value.
#
# Input:
#       string(required) - which one wants to find in filter
#       value(required) - which one wants to replace in filterString
#
# Results:
#       SUCCESS - in case the string is found in filter.(It returns success
#       even in the case of string is found & replaced with new value)
#       0 - in case string is not found.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub UpdateFilterString
{
   my ($self, $replaceWord, $replaceValue) = @_;
   if (not defined $replaceWord ||not defined $replaceValue) {
      $vdLogger->Warn("UpdateFilterString missing parameters");
      return 0;
   }

   my $filterString = $self->{filterString};
   my $temp;

   # Taking the example of filter string "-p -e 1521-vvv -C 20 and less 1500"
   # if less is found then we return SUCCESS so that we dont append another
   # less X string to it.
   # Now we also check if the previous value of less = 1500 is greater than
   # new value 1499. In this case we replace less with 1499 and return SUCCESS
   if ($filterString =~ m/$replaceWord/i) {
      # If the filter tag has value then use it else return SUCCESS
      if ($filterString =~ /$replaceWord (.*?) /) {
         $temp = $1;
      } else {
         return SUCCESS;
      }
      if (($replaceWord =~ m/greater/i && $temp < $replaceValue) ||
         ($replaceWord =~ m/less/i && $temp > $replaceValue)) {
         $filterString =~ s/greater (.*?) /$replaceValue/;
         return SUCCESS;
      } else {
         return SUCCESS;
      }
   } else {
      return 0;
   }
   return 0;
}

#TODO: Obsolete method, can be removed after a while when things are stable
# and we realize this method is not need for sure.
###############################################################################
#
# ExtractPacketInfo -
#       Extracts the desired packet Information from the packet statistics
#       hash.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#                              capture session. E.g. "count"
#
# Results:
#       string in case the value is understool by tcpdump.
#       0 in case there is no translation for that key for tcpdump.
#       FAILURE in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractPacketInfo
{
   my $self = shift;
   my $extractInfo = shift;

   my $packetStatHash = $self->ParseCapturedFile();
   if ($packetStatHash =~ m/FAILURE/i) {
      $vdLogger->Error("PacketCaptureStats:$packetStatHash are missing");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (not defined $extractInfo) {
      if (not defined $self->{packetInfo} || $self->{packetInfo} eq "") {
         $extractInfo = "count";
         $self->{packetInfo} = $extractInfo;
      } else {
         $extractInfo = $self->{packetInfo};
      }
   }

   if (not defined $extractInfo) {
      $vdLogger->Error("Information to be extraced from packetStats is ".
                       "missing");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("Extracting PacketInfo:$extractInfo from captured".
                    " packets");
   switch ($extractInfo) {
      case m/(count)/i {
         return $packetStatHash->{pktcount};
      }
      case m/(avgpktlen)/i {
         return $packetStatHash->{avgpktlen};
      }
      case m/(min)/i {
         return $packetStatHash->{minpktsize};
      }
      case m/(max)/i {
         return $packetStatHash->{maxpktsize};
      }
      case m/(checksum)/i {
         return $packetStatHash->{pktcksumerror};
      }
      case m/(badpackets)/i {
         return  $packetStatHash->{badpkt};
      }
      case m/(retransmission)/i {
         return  $packetStatHash->{badpkt};
      }
      case m/(connectionrst)/i {
         return  $packetStatHash->{badpkt};
      }
      case m/(tos)/i {
         return  $packetStatHash->{tos};
      }
      else {
         $vdLogger->Error("Unknown packetInfo:$extractInfo specified");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   return FAILURE;
}

###############################################################################
#
# GetWinDumpIndex -
#       This method is used get the WinDump Index of a NIC given its GUID
#
# Input:
#       None.
#
# Results:
#       winDump index (string) in case of SUCCESS
#       FAILURE in case of failure
#
# Side effects:
#       None
#
###############################################################################

sub GetWinDumpIndex
{
   my $self = shift;
   my $GUID = $self->{pktcapinterface};
   my $command;
   my $result;
   $GUID =~ s/\^\{//;
   $GUID =~ s/\}\^//;

   $command = "$self->{bin} -D";
   $result = $self->{staf}->STAFSyncProcess($self->{targetip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ /.*(\d+).\\\S+\\.*$GUID.*/ ) {
      return $1;
   } else {
      $vdLogger->Error("windump index not found for GUID:$GUID ".
                       "on host:$self->{targetip}. Dumping output:" .
                       $result->{stdout});
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}

###############################################################################
#
# StopVerification -
#       This method builds the command(binary) for this verification tool.
#       1. For linux tcpdump
#       2. For windows
#          a. Based on the OS, get the binariespath from
#             VDNetLib::Common::GlobalConfig
#          b. Set command to the windump path after copying it to another dir.
#
# Input:
#       arch (required)
#       os (required)
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
   my $command;
   my $result;
   my $os = $self->{'os'};
   my $host = $self->{targetip};
   my $processHandle = $self->{processHandle};

   $self->{stopCaptureCalled} = 1;

   if (not defined $processHandle) {
      $vdLogger->Error("StopCapture called without processHandle ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $result = $self->{staf}->GetProcessInfo($host, $processHandle);
   if ((not defined $result) || ((defined $result->{rc}) &&
       ($result->{rc} != 11 && $result->{rc} != 0))) {
      #
      #rc' => '11', means: "Process Already Complete"
      #You are trying to perform an invalid operation on a process that
      #has already completed. For example, you may be trying to stop
      #the process or register for a process end notification.
      #
      $vdLogger->Debug("StopVerification failed:" . Dumper($result));
      my $launchStdoutFile = $self->{launchstdout};
      my $pktcapStdout = $self->{staf}->STAFFSReadFile($host,
                                                      $launchStdoutFile);
      if (not defined $pktcapStdout) {
         $vdLogger->Error("Something went wrong with reading the stdout file ".
                          "of pktcap launch code. File:$launchStdoutFile on ".
                          "$host");
         VDSetLastError("ESTAF");
         return FAILURE;
      } else {
         $vdLogger->Error("PktCap had died after saying:\n$pktcapStdout");
         if ($pktcapStdout =~ m/(SIOCGIFINDEX|SIOCGIFHWADDR|ioctl)/i &&
            $os =~ m/(esx|vmkernel)/i) {
            # tcpdump-uw though needs to be started on vmkX interface
            # if there is no portgroup on it, tcpdump-uw fails with
            # tcpdump-uw: SIOCGIFHWADDR: Invalid argument
            $vdLogger->Warn("Does a portgroup exists on this ".
                             "$self->{pktcapinterface} interface?");
         }
         VDSetLastError("EFAILURE");
         return FAILURE;
      }
   }
   my $pid = $result->{pid};

   if ($os =~ m/win/i) {
      $command = " TASKKILL /FI \"PID eq $pid\" /F";
   } elsif ($os =~ m/esx|vmkernel/i) {
      $command = "kill -SIGINT $pid";
      $vdLogger->Debug("Sending SIGINT to $pid on host $host");
   } else {
      $command = "kill -9 $pid";
   }

   $vdLogger->Info("Stopping packet Capture on ".
                   "$self->{target}($self->{nodeid}) by killing process ".
                   "with PID:$pid");

   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   return SUCCESS;
}

###############################################################################
#
# ExtractResults -
#       This method converts the pcap files into human readable format and
#       then calls GetResult methods on these files to parse required
#       information out of them.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#                              capture session. E.g. "count"
#
#
# Results:
#       integer value of the information to be extract from packet capture
#       FAILURE in case something goes wrong.
#
# Side effects:
#       Even in case of failure the files are deleted and thus are not
#       available for debugging.
#       When GetResult() returns 0 there are two scenarios
#          a) Either filter is very draconian and nothing was captured
#          b) Nothing was capture due to some error with tcpdump
#
###############################################################################

sub ExtractResults
{
   my $self = shift;
   my $packetInfo = shift || undef;
   my $host;
   my $command;
   my $result;
   my $os;
   my $sourceFileName;
   my $fileCount = 1;
   my $fileName;
   $host = $self->{'targetip'};
   $os = $self->{'os'};
   my $binary = $self->{bin};
   $sourceFileName = $self->{'fileName'};
   $fileName = $sourceFileName;
   my $localfile;
   # Get the masterController IP for copying
   # pcap files from target to masterController.
   my $masterControlleraddr;
   if (($masterControlleraddr = VDNetLib::Common::Utilities::GetLocalIP()) eq
       FAILURE) {
      $vdLogger->Error("Not able to get LocalIP:$masterControlleraddr");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }


   # Loop for:
   # 1) Check if pcap file exits or not
   # 2) Copy the file if it exists
   # 3) Convert it to human readable format
   # 4) Continue the loop with pcap1 file
   my $copyFileName;
   while(1)
   {
      if ( $os =~ m/win/i ) {
         my $winDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
         $copyFileName = $sourceFileName;
         $copyFileName =~ s/.+\//$winDir/;
      } else {
         $copyFileName = $sourceFileName;
      }



      # We check if the file exists on remote machine.
      # This method returns undef if the file does not exits on remote host.
      $result = $self->{staf}->IsDirectory($host, $copyFileName);
      if (not defined $result) {
         # If copying any file failed then break from loop
         last;
      } else {
         # Coping files to /tmp for tcpdump to pick up and process.
         $result = $self->{staf}->STAFFSCopyFile("$copyFileName",
                                                 "/tmp",
                                                 "$host",
                                                 "$masterControlleraddr");
         if ($result eq -1) {
            # If at all copying file failed then break from loop and
            # process rest of the files which are already copied.
            last;
         } else {
            $vdLogger->Trace("Copied $host:$copyFileName to ".
                             "$masterControlleraddr:$self->{localLogsDir}");
         }
      }
      $localfile = $sourceFileName;
      # Converting to human readable format to enable parsing
      # This is done in Master Controller itself.
      # Doing it in SUT or Helper would be slow and cumbersome.
      # Coping files to vdnetlogdir for post mortem analysis
      $command = "cp -r $localfile $self->{localLogsDir}";
      $result = $self->{staf}->STAFSyncProcess("local", $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $command = "tcpdump -e -vvv -s0 -r ".
                 "$localfile > $localfile.tmp";
      if ($os =~ m/(esx|vmkernel)/i &&
                 defined $self->{pktcapbucket}->{nodes}->{tcpdump}) {
         $command = "cp ".
                 "$localfile  $localfile.tmp";
      }
      $result = $self->{staf}->STAFSyncProcess("local", $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # If file exists and its size is zero then print warning
      my $fileSize = -s "$localfile.tmp";
      if (-z $localfile .".tmp") {
         $vdLogger->Warn("file:$localfile.tmp has size:$fileSize. ".
                         "Either traffic is not flowing"
                         ." OR your filter expression is very draconian");
         $vdLogger->Debug("Dumping pcap > pcap.tmp's staf output" .
                           Dumper($result));
      }
      $sourceFileName = $fileName . $fileCount;
      $fileCount++;
   }

   # After copying the files locally only local files will be refered.
   $self->{'fileName'}  =~ s/.+\//\/tmp\//;
   $fileName = $self->{'fileName'};

   unless (-e $fileName || -z $fileName) {
      $vdLogger->Error("Not even one capture file filled with packets got ".
                      "created:" . $fileName);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $packetStatHash = $self->ParseCapturedFile();
   if ($packetStatHash =~ m/FAILURE/i) {
      $vdLogger->Error("PacketCaptureStats:$packetStatHash are missing");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (defined $self->{pktcapbucket}->{nodes}->{tcpdump}) {
      $self->{pktcapbucket}->{nodes}->{tcpdump}->{diff} = $packetStatHash;
   } elsif (defined $self->{pktcapbucket}->{nodes}->{pktcapuw}) {
      $self->{pktcapbucket}->{nodes}->{pktcapuw}->{diff} = $packetStatHash;
   }

   my $ret = $self->CompareNodes();
   if ($ret ne SUCCESS) {
      $vdLogger->Error("CompareNodes() on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $ret = $self->CleanUP();
   if ($ret eq FAILURE) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;

}


###############################################################################
#
# ParseCapturedFile -
#       This method interprets the information in the tmp file and collects
#       various stats from it. Stats include checksum errors, bad packets,
#       length of packets, etc. It then saves them in a packetStats hash.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#       Even in case of failure the files are deleted and thus are not
#       available for debugging.
#
###############################################################################

sub ParseCapturedFile
{
   my $self = shift;
   my $fileName = $self->{fileName};
   my $fileCount = 1;
   my $packetStatHash;
   if (not defined $fileName || not defined $fileCount) {
      $vdLogger->Error("InterpretCapturedFile called without required " .
                       "parameters");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my ($line, @temp, @packetLen);
   my $cksumError = 0;
   my $badPackets = 0;
   my $connectionRST = 0;
   my $retransmission = 0;
   my $truncatedPackets = 0;
   my $tos = 0x0;
   my $innertos  = 0x0;
   my $vxlanid   = 0;
   my $l3protocolheader = 0x0;
   my $srcmac = 0x0;
   my $dstmac    = 0x0;
   my $innersrcmac = 0x0;
   my $innerdstmac    = 0x0;
   my $innerpkttype  = 0x0;
   my $tci = 0x0;
   my $vni = 0x0;
   my $pcp = 0x0;
   my $innerpcp = 0x0;
   my $sttflags = 0x0;
   my $replicationbit = 0x0;
   my $vtep = 0x0;
   my $innerl3protocol = 0x0;
   my $innerl4protocol = 0x0;
   my $file = $fileName;
   my $macAddrRegex = VDNetLib::TestData::TestConstants::MAC_ADDR_REGEX;
   my $packetDelim = '-' x DELIMITER_LEN;
   my $packetsDelim = '=' x DELIMITER_LEN;
   my $matchedFields = dclone $self->{expectedchange};
   delete $matchedFields->{pktcount};  # It is calculated later.
   my @suppliedKeys = keys %$matchedFields;
   foreach my $suppliedKey (@suppliedKeys) {
      if (not (grep {$_ eq $suppliedKey} @VALID_KEYS)) {
         $vdLogger->Warn("Not a valid traffic verification key: $suppliedKey");
         delete $matchedFields->{$suppliedKey};
      } else {
         $matchedFields->{$suppliedKey} = FALSE;
      }
   }
   while(1) {
      $file = $file . ".tmp";
      #checking if that file exists on the host
      unless (-e $file) {
         last;
      }
      # If file exists and its size is zero then print warning
      if (-z $file) {
         $vdLogger->Debug("Capture file:$file is empty");
      }
      if (not defined open(FILE, "<$file")) {
         $vdLogger->Error("Unable to open file $file for reading:"
                       ."$!");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      $vdLogger->Info("Parsed readable file is saved to $file");
      my @fileData = <FILE>;
      my $size = @fileData;
      # Collection various stats after looping though all the data
      # of file.
      #
      # VXLAN part:
      # for vxlan packets, we need to do something special since they
      # have double tags as:
      # 21:51:18.483720 00:50:56:69:28:24 (oui Unknown) > 00:26:98:02:ee:41 (oui Unknown), ethertype IPv4 (0x0800), length 1564: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto UDP (17), length 1550)
      #     172.19.133.195.60386 > 172.18.128.209.8472: [no cksum] OTV, flags [I] (0x08), overlay 0, instance 5395
      # 00:50:56:83:d8:6e (oui Unknown) > 00:50:56:83:94:0c (oui Unknown), ethertype IPv4 (0x0800), length 1514: (tos 0x0, ttl 64, id 21079, offset 0, flags [DF], proto TCP (6), length 1500)
      #     192.168.139.92.49152 > 192.168.138.164.49152: Flags [.], cksum 0xf0eb (correct), seq 7264:8712, ack 1, win 46, options [nop,nop,TS val 337868 ecr 79891245], length 1448
      #
      # for vxlan arp message in unicast mode:
      # 01:14:52.691316 00:50:56:6c:d6:25 (oui Unknown) > 00:26:98:02:ee:41 (oui Unknown), ethertype IPv4 (0x0800), length 110: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto UDP (17), length 96)
      #     172.19.134.30.62658 > 172.18.129.17.8472: [no cksum] OTV, flags [I] (0x0a), overlay 0, instance 6105
      # 00:50:56:86:36:3e (oui Unknown) > Broadcast, ethertype ARP (0x0806), length 60: Ethernet (len 6), IPv4 (len 4), Request who-has 192.168.138.227 (Broadcast) tell 192.168.138.168, length 46
      #
      # We have to identify the inner tag from the packets, we search the "instance \d+$" keyword as the start of innter tag, and search the "length \d+$" as the end of inner tag
      #
      # STT part:
      # 21:51:18.483720 00:50:56:69:28:24 (oui Unknown) > 00:26:98:02:ee:41 (oui Unknown), ethertype IPv4 (0x0800), length 1564: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 1550)
      #     10.33.83.118.20 > 10.24.1.1.7471: Flags [P.], cksum 0x1fb1 (correct), seq 0:60, ack 0, win 8192, length 60
      #  STT: version 0x00, flags 0x40, l4offset 0x00, mss 0x00, vlan tci 0x40, vni 1, replication bit 0x0, vtep 554591
      #   00:11:22:33:44:55 (oui Unknown) > 12:34:56:78:9a:00 (oui Unknown), ethertype IPv4 (0x0800), length 42: (tos 0x0, ttl 64, id 1, offset 0, flags [none], proto ICMP (1), length 28)
      #     192.168.0.1 > 192.168.0.2: ICMP echo request, id 0, seq 0, length 8
      #
      # ipv6 stt packet:
      # 01:19:19.558260 00:50:56:62:15:44 (oui Unknown) > 00:50:56:6b:58:70 (oui Unknown), ethertype IPv4 (0x0800), length 190: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 176)
      #     172.21.142.117.57425 > 172.21.142.118.7471: Flags [P.], cksum 0x75b9 (incorrect -> 0x2588), seq 8912896:8913032, ack 708, win 65535, length 136
      #  STT: version 0x00, flags 0x00, l4offset 0x36, mss 0x00, vlan tci 0x00, vni 29448, replication bit 0x0, vtep 621184
      #   00:0c:29:b1:ee:92 (oui Unknown) > 00:0c:29:57:db:25 (oui Unknown), ethertype IPv6 (0x86dd), length 118: (hlim 64, next-header ICMPv6 (58) payload length: 64) 2001:bd6::c:2957:236 > 2001:bd6::c:2957:235: [icmp6 sum ok] ICMP6, echo request, seq 0
      #
      # VLAN packet with PCP (802.1p priority):
      # 20:30:09.797254 00:0c:29:82:64:49 (oui Unknown) > 00:0c:29:a8:4f:81 (oui Unknown), ethertype 802.1Q (0x8100), length 78: vlan 20, p 1, ethertype IPv4, (tos 0x4, ttl 64, id 41598, offset 0, flags [DF], proto TCP (6), length 60)
      #
      my $expectedChange = $self->{expectedchange};
      my $innerFlag = "FALSE";
      my $skipCurrentPacket = "FALSE";
      my $matchedPackets = "";
      my $unMatchedPackets = "";
      my $currentPacket = "";
      for (my $i = 0; $i <$size; $i++) {
         $line = $fileData[$i];
         if (not ((substr($line, 0, 1) eq " ") ||
                  (substr($line, 0, 1) eq "\t"))) {
            # If start of the next packet then check to see if the previous
            # packet matched.
            $skipCurrentPacket = "FALSE";
            $innerFlag = "FALSE";
            my $matchFound = TRUE;
            foreach my $key (keys %$matchedFields) {
                if (not $matchedFields->{$key}) {
                   pop @packetLen;
                   $matchFound = FALSE;
                   last;
                }
            }
            if ($matchFound) {
                $matchedPackets .= "$packetDelim\n$currentPacket" if $currentPacket ne "";
            } else {
                $unMatchedPackets .= "$packetDelim\n$currentPacket" if $currentPacket ne "";
            }
            foreach my $key (keys %$matchedFields) {
                $matchedFields->{$key} = FALSE;
            }
            if ($line =~ m/length (\d+):/i) {
                push(@packetLen, $1);
                $vdLogger->Trace("Collect packet at line $i: $line ");
            }
            $currentPacket = "";
         } elsif ($skipCurrentPacket eq "TRUE") {
            next;
         }
         $currentPacket .= $line;
         if ($innerFlag eq "FALSE") {
            if ($line =~ /($macAddrRegex).*>\s(broadcast|$macAddrRegex)/i) {
               $srcmac = lc($1);
               $dstmac = lc($2);
               if ($dstmac eq 'broadcast') {
                  $dstmac = "ff:ff:ff:ff:ff:ff";
               }
               if (defined $expectedChange->{dstmac}) {
                   if (lc($expectedChange->{dstmac}) ne $dstmac) {
                       $skipCurrentPacket = "TRUE";
                       next;
                   } else {
                       $matchedFields->{dstmac} = TRUE;
                   }
               }
               if (defined $expectedChange->{pkttype}) {
                    if(lc($expectedChange->{pkttype}) ne
                       lc(VDNetLib::Common::Utilities::TypeOfMacAddress($dstmac))) {
                       $skipCurrentPacket = "TRUE";
                       next;
                    } else {
                        $matchedFields->{pkttype} = TRUE;
                    }
               }
            }
            if (($line =~ /(bad tcp chksum|bad udp chksum)/)  ||
                ($line =~ /bad cksum/)  || ($line =~ /incorrect/)) {
               $cksumError++;
            }
            if ($line =~ /Flags \[(.{1,9})\],/) {
               my $flags = $1;
               $connectionRST++ if $flags =~ m/R/;
            }
            if ($line =~ /flags\s\Q[\E.\Q]\E\s\Q(\E(0x[0-9a-fA-F]{1,2})\Q)\E/) {
               $l3protocolheader = $1;
               if (defined $expectedChange->{l3protocolheader}) {
                    if ($expectedChange->{l3protocolheader} ne $l3protocolheader) {
                        $skipCurrentPacket = "TRUE";
                        next;
                    } else {
                        $matchedFields->{l3protocolheader} = TRUE;
                    }
               }
            }
            if ($line =~ /tos\s(0x[0-9a-fA-F]{1,2})/) {
               $tos = $1;
               if (defined $expectedChange->{tos}) {
                    if ($expectedChange->{tos} ne $tos){
                        $skipCurrentPacket = "TRUE";
                        next;
                    } else {
                        $matchedFields->{tos} = TRUE;
                    }
               }
            }
            if ($line =~ /vlan\s+\d+,\s+p\s+(\d+)/) {
               my $pcp = $1;
               if (defined $expectedChange->{pcp}) {
                     if ($expectedChange->{pcp} ne $pcp) {
                        $skipCurrentPacket = "TRUE";
                        next;
                     } else {
                        $matchedFields->{pcp} = TRUE;
                     }
               }
            }
            my $arpRegex = 'ethertype ARP \('. ARP_REQUEST .'\),.*Request\s' .
                           'who-has\s(' . IP_REGEX . ')\stell\s(' . IP_REGEX . '),';
            if ($line =~ /$arpRegex/) {
               my $arpsourceip = $2;
               my $arpdestinationip = $1;
               if (defined $expectedChange->{arpsourceip}) {
                   if ($arpsourceip !~ m/^$expectedChange->{arpsourceip}/) {
                      $skipCurrentPacket = "TRUE";
                      next;
                   } else {
                      $matchedFields->{arpsourceip} = TRUE;
                   }
               }
               if (defined $expectedChange->{arpdestinationip}) {
                   if ($arpdestinationip !~ m/^$expectedChange->{arpdestinationip}/) {
                       $skipCurrentPacket = "TRUE";
                       next;
                    } else {
                       $matchedFields->{arpdestinationip} = TRUE;
                    }
               }
            }
            # Captured garp packet looks like below:
            # 05:24:41.730010 00:0c:29:94:64:34 (oui Unknown) > Broadcast, ethertype ARP (0x0806), length 60: Ethernet (len 6), IPv4 (len 4), Reply 169.0.0.4 is-at 00:0c:29:94:64:34 (oui Unknown), length 46
            my $garpRegex = '> Broadcast.*ethertype ARP \('. ARP_REQUEST .'\).*Reply\s(' .
                           IP_REGEX . ')\sis-at\s';
            if ($line =~ /$garpRegex/i) {
               my $garpdestinationip = $1;
               if (defined $expectedChange->{garpdestinationip}) {
                   if ($garpdestinationip !~ m/^$expectedChange->{garpdestinationip}/) {
                       $skipCurrentPacket = "TRUE";
                       next;
                    } else {
                       $matchedFields->{garpdestinationip} = TRUE;
                    }
               }
            }
            if (($line =~ /bad opt/) || ($line =~ /bad hdr length/)) {
               $badPackets++;
            }
            if ($line =~ /truncated-ip/i) {
               $truncatedPackets++;
            }
           }
           elsif ($innerFlag eq "TRUE") {
            if ($line =~ /($macAddrRegex).*>\s(broadcast|$macAddrRegex)/i) {
               $innersrcmac = lc($1);
               $innerdstmac = lc($2);
               if ($innerdstmac eq 'broadcast') {
                  $innerdstmac = "ff:ff:ff:ff:ff:ff";
               }
               $innerpkttype = VDNetLib::Common::Utilities::TypeOfMacAddress($innerdstmac);
               if (defined $expectedChange->{innerdstmac}) {
                    if (lc($expectedChange->{innerdstmac}) ne $innerdstmac) {
                        $skipCurrentPacket = "TRUE";
                        next;
                    } else {
                        $matchedFields->{innerdstmac} = TRUE;
                    }
               }
               if (defined $expectedChange->{innersrcmac}) {
                    if (lc($expectedChange->{innersrcmac}) ne $innersrcmac) {
                        $skipCurrentPacket = "TRUE";
                        next;
                     } else {
                        $matchedFields->{innersrcmac} = TRUE;
                     }
               }
               if (defined $expectedChange->{innerpkttype}) {
                   if ($expectedChange->{innerpkttype} ne $innerpkttype) {
                       $skipCurrentPacket = "TRUE";
                       next;
                   } else {
                       $matchedFields->{innerpkttype} = TRUE;
                   }
               }
               my $arpRegex = 'ethertype ARP \('. ARP_REQUEST .'\),.*Request\s' .
                              'who-has\s(' . IP_REGEX . ')\stell\s(' . IP_REGEX . '),';
               if ($line =~ /$arpRegex/) {
                  my $innerarpsourceip = $2;
                  my $innerarpdestinationip = $1;
                  if (defined $expectedChange->{innerarpsourceip}) {
                      if ($innerarpsourceip ne $expectedChange->{innerarpsourceip}) {
                          $skipCurrentPacket = "TRUE";
                          next;
                      } else {
                          $matchedFields->{innerarpsourceip} = TRUE;
                      }
                  }
                  if (defined $expectedChange->{innerarpdestinationip}) {
                      if ($innerarpdestinationip ne $expectedChange->{innerarpdestinationip}) {
                          $skipCurrentPacket = "TRUE";
                          next;
                      } else {
                          $matchedFields->{innerarpdestinationip} = TRUE;
                      }
                  }
               }

            }

            if ($line =~ /tos\s(0x[0-9a-fA-F]{1,2})/) {
               $innertos = $1;
               if (defined $expectedChange->{innertos}) {
                    if ($expectedChange->{innertos} ne $innertos) {
                        $skipCurrentPacket = "TRUE";
                        next;
                     } else {
                        $matchedFields->{innertos} = TRUE;
                     }
               }
            }
            if ($line =~ /ethertype\s(\w+)/) {
               $innerl3protocol = lc($1);
               if (defined $expectedChange->{innerl3protocol}) {
                   if ($expectedChange->{innerl3protocol} ne $innerl3protocol) {
                      $skipCurrentPacket = "TRUE";
                      next;
                   } else {
                      $matchedFields->{innerl3protocol} = TRUE;
                   }
               }
               my $innerl4protocol = "";
               # An encapsulated packet looks like the following in the parsed
               # tcpdump file:
# 23:18:23.535375 00:50:56:6c:8c:c2 (oui Unknown) > 00:50:56:67:0d:0a (oui Unknown), ethertype IPv4 (0x0800), length 132: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 118)
#    172.21.141.156.59243 > 172.21.141.157.7471: Flags [P.], cksum 0x48de (correct), seq 0:78, ack 9, win 65535, length 78
# STT: version 0x00, flags 0x04, l4offset 0x22, mss 0x00, vlan tci 0x04, vni 52744, replication bit 0x0, vtep 401920
#  00:0c:29:07:2f:08 (oui Unknown) > Broadcast, ethertype IPv4 (0x0800), length 60: (tos 0x0, ttl 64, id 1, offset 0, flags [none], proto ICMP (1), length 28)
#    192.168.9.21 > 192.168.9.50: ICMP echo request, id 0, seq 0, length 8
               # The second last line prints information about the content of
               # the inner packet (in this case "proto ICMP") which is of
               # interest to us.
               if ($line =~ m/.*length \d+:.*proto (\S+).*/i) {
                   $innerl4protocol = lc($1);
               }
               if (defined $expectedChange->{innerl4protocol}) {
                   if (lc($expectedChange->{innerl4protocol}) ne $innerl4protocol) {
                       $skipCurrentPacket = "TRUE";
                       next;
                    } else {
                      $matchedFields->{innerl4protocol} = TRUE;
                    }
               }
            }
         }
         # mark the innerFlag to TRUE when find "instance \d+$"
         if ($line =~ m/instance (\d+)$/i) {
            $vxlanid = $1;
            $innerFlag = "TRUE";
            if (defined $expectedChange->{vxlanid}) {
                 if ($expectedChange->{vxlanid} ne $vxlanid) {
                     $skipCurrentPacket = "TRUE";
                     next;
                 } else {
                    $matchedFields->{vxlanid} = TRUE;
                 }
            }
         }
         if ($line =~ m/STT:/) {
            $innerFlag = "TRUE";
            if ($line =~ /flags\s(0x[0-9a-fA-F]{1,2})/) {
               $sttflags = $1;
               if (defined $expectedChange->{sttflags}) {
                    if ($expectedChange->{sttflags} ne $sttflags) {
                        $skipCurrentPacket = "TRUE";
                        next;
                    } else {
                        $matchedFields->{sttflags} = TRUE;
                    }
               }
            }
            if ($line =~ /tci\s(0x[0-9a-fA-F]{1,2})/) {
               $tci = $1;
               if (defined $expectedChange->{tci}) {
                   if ($expectedChange->{tci} ne $tci) {
                       $skipCurrentPacket = "TRUE";
                       next;
                   } else {
                       $matchedFields->{tci} = TRUE;
                   }
               }
            }
            if ($line =~ /vni\s(\d+)/) {
               $vni = $1;
               if (defined $expectedChange->{vni}) {
                   if ($expectedChange->{vni} ne $vni) {
                      $skipCurrentPacket = "TRUE";
                      next;
                   } else {
                      $matchedFields->{vni} = TRUE;
                   }
               }
            }
            if ($line =~ /vlan\s+\d+,\s+p\s+(\d+)/) {
               my $innerpcp = $1;
               if (defined $expectedChange->{innerpcp}) {
                   if ($expectedChange->{innerpcp} ne $innerpcp) {
                      $skipCurrentPacket = "TRUE";
                      next;
                   } else {
                      $matchedFields->{innerpcp} = TRUE;
                   }
               }
            }
            if ($line =~ /bit\s(0x[0-9a-fA-F]{1,2})/) {
               $replicationbit = $1;
               if (defined $expectedChange->{replicationbit}) {
                   if ($expectedChange->{replicationbit} ne $replicationbit) {
                       $skipCurrentPacket = "TRUE";
                       next;
                    } else { 
                       $matchedFields->{replicationbit} = TRUE;
                    }
               }
            }
            if ($line =~ /vtep\s(0x[0-9a-fA-F]{1,2})/) {
               $vtep = $1;
               if (defined $expectedChange->{vtep}) {
                    if ($expectedChange->{vtep} ne $vtep) {
                        $skipCurrentPacket = "TRUE";
                        next;
                    } else {
                        $matchedFields->{vtep} = TRUE;
                    }
               }
            }
         }
         if (($i > 1) && ($line =~ /seq/)) {
            $line =~ m/seq (\d+:\d+|\d+), /i;
            my $currentSeq = $1;
            my $prevLine = $fileData[$i - 2];
            $prevLine =~ m/seq (\d+:\d+|\d+), /i;
            my $prevSeq = $1;
            if ($currentSeq =~ /^$prevSeq$/) {
               $retransmission++;
            }
         }
         if (($i == 5) || ((200 < $i) && ($i < 205))) {
            $vdLogger->Trace("Random packet dump $i:" . $line);
         }
      }

      # Moving on to the next file which tcpdump might have saved by
      # appending a number on front of it.
      $file = "$fileName"."$fileCount";
      $fileCount++;
      close(FILE);
      my $matchFlag = TRUE;
      foreach my $key (keys %$matchedFields) {
          if (not $matchedFields->{$key}) {
             $matchFlag = FALSE;
             pop @packetLen;
             last;
          }
      }
      if ($matchFlag) {
         $matchedPackets .= "$packetDelim\n$currentPacket";
      } else {
         $unMatchedPackets .= "$packetDelim\n$currentPacket";
      }
      $vdLogger->Trace("Packets that matched user's expectation in file " .
                       "$file are:\n$packetsDelim\n$matchedPackets\n" .
                       "$packetsDelim\n");
      $vdLogger->Trace("Packets that didn't match user's expectation in " .
                       "file $file are:\n$packetsDelim\n$unMatchedPackets\n" .
                       "$packetsDelim\n");

   }
   #
   #TODO: Do all the calculations on need basis. They are very expensive
   # when number of packets are more.
   #
   my $expectedChange = $self->{expectedchange};
   foreach my $expectedKey (keys %$expectedChange) {
      switch (lc($expectedKey)) {
         case m/(pktcksumerror)/i {
            # Total Checksum Error
            $packetStatHash->{pktcksumerror} = $cksumError;
         }
         case m/(badpkt)/i {
            # Total Bad Packets
            $packetStatHash->{badpkt} = $badPackets;
         }
         case m/(connectionRST)/i {
            # Number of connection RSTs
            $packetStatHash->{connectionRST} = $connectionRST;
         }
         case m/(retransmission)/i {
            # Number of connection RSTs
            $packetStatHash->{retransmission} = $retransmission;
         }
         case m/(truncatedpkt)/i {
            # Number of truncated-ip Packets
            $packetStatHash->{truncatedpkt} = $truncatedPackets;
         }
         case m/(innertos)/i {
            # innertos value in hex
            $packetStatHash->{innertos} = $expectedChange->{innertos};
         }
         case m/(tos)/i {
            # tos value in hex
            $packetStatHash->{tos} = $expectedChange->{tos};
         }
         case m/(innerpkttype)/i {
            # vxlan inner packet address type
            $packetStatHash->{innerpkttype} = $expectedChange->{innerpkttype};
         }
         case m/(pkttype)/i {
            # packet address type
            $packetStatHash->{pkttype} = $expectedChange->{pkttype};
         }
         case m/(l3protocolheader)/i {
            # vxlan flag
            $packetStatHash->{l3protocolheader} = $expectedChange->{l3protocolheader};
         }
         case m/(vxlan)/i {
            # vxlan id
            $packetStatHash->{vxlanid} = $expectedChange->{vxlanid};
         }
         case m/(sttflags)/i {
            # stt flags
            $packetStatHash->{sttflags} = $expectedChange->{sttflags};
         }
         case m/(vni)/i {
            # vni id
            $packetStatHash->{vni} = $expectedChange->{vni};
         }
         case m/(pcp)/i {
            # vlan pcp
            $packetStatHash->{pcp} = $expectedChange->{pcp};
         }
         case m/(innerpcp)/i {
            # vlan pcp on encapsulated frame header
            $packetStatHash->{innerpcp} = $expectedChange->{innerpcp};
         }
         case m/(tci)/i {
            # tci id
            $packetStatHash->{tci} = $expectedChange->{tci};
         }
         case m/(vtep)/i {
            # vtep id
            $packetStatHash->{vtep} = $expectedChange->{vtep};
         }
         case m/(innerl3protocol)/i {
            # inner packet l3 protocol
            $packetStatHash->{innerl3protocol} = $expectedChange->{innerl3protocol};
         }
         case m/(innerl4protocol)/i {
            # inner packet l4 protocol
            $packetStatHash->{innerl4protocol} = $expectedChange->{innerl4protocol};
         }
         case m/(replicationbit)/i {
            # replication bit
            $packetStatHash->{replicationbit} = $expectedChange->{replicationbit};
         }
         case "dstmac" {
            $packetStatHash->{dstmac} = $expectedChange->{dstmac};
         }
         case "innersrcmac" {
            $packetStatHash->{innersrcmac} = $expectedChange->{innersrcmac};
         }
         case "innerdstmac" {
            $packetStatHash->{innerdstmac} = $expectedChange->{innerdstmac};
         }
         case m/(^arpsourceip$)/i {
            $packetStatHash->{arpsourceip} = $expectedChange->{arpsourceip};
         }
         case m/(^arpdestinationip$)/i {
            $packetStatHash->{arpdestinationip} = $expectedChange->{arpdestinationip};
         }
         case m/(^garpdestinationip$)/i {
            $packetStatHash->{garpdestinationip} = $expectedChange->{garpdestinationip};
         }
         case m/(^innerarpsourceip$)/i {
            $packetStatHash->{innerarpsourceip} = $expectedChange->{innerarpsourceip};
         }
         case m/(^innerarpdestinationip$)/i {
            $packetStatHash->{innerarpdestinationip} = $expectedChange->{innerarpdestinationip};
         }
         case m/(avgpktlen|minpktsize|maxpktsize)/i {
            # Logic for findig average length of packets.
            my ($item, $sum);
            $sum = 0;
            foreach $item (@packetLen) {
               $sum = $sum + $item;
            }
            my $numPackets = scalar(@packetLen);
            if ($numPackets > 0) {
               $packetStatHash->{avgpktlen} = $sum / $numPackets;
               # rounding it off.
               $packetStatHash->{avgpktlen} = int($packetStatHash->{avgpktlen});
               # Logic for calculating minimum and maximum packet size
               my @sortedArray = sort {$a <=> $b} (@packetLen);
               $packetStatHash->{minpktsize} = $sortedArray[0];
               $packetStatHash->{maxpktsize}  = $sortedArray[-1];
            } else {
               $packetStatHash->{avgpktlen} = 0;
               $packetStatHash->{minpktsize} = 0;
               $packetStatHash->{maxpktsize}  = 0;
            }
         }
      }
   }

   # Logic for counting number of packets
   $packetStatHash->{pktcount} = scalar(@packetLen);
   if (scalar(@packetLen) == 0) {
      $vdLogger->Trace("Packet capture Stats failed:". Dumper($packetStatHash));
   }

   return $packetStatHash;
}

###############################################################################
#
# CleanUP -
#       This method does cleanup for this class. It takes care of wiping off
#       all the pcap and tmp files created during the session.
#       Launches staf command to cleanup all *.pcap* files from all machines.
#
# Input:
#       None.
#
# Results:
#       SUCCESS - if everything goes well.
#       FAILURE - in case of error.
#
# Side effects:
#       Even in case of failures the files are deleted and thus are not
#       available for debugging.
#
###############################################################################

sub CleanUP
{
   my $self = shift;
   my ($command, $result);
   my $stopCapture = $self->{stopCaptureCalled};
   my $fileName = $self->{fileName};
   my $os = $self->{os};

   if ($stopCapture == 0) {
      if ($self->Stop() eq FAILURE) {
         $vdLogger->Error("Failed to stop packet capturing ".
                          "process");
         VDSetLastError("EOPFAILED");
         return FAILURE;
       }
   }

   # Remove all files of this session which have unique timestamp
   # Thus delete all pcap files of current timestamp
   $fileName =~ m/PktCap-(.*)/;
   my $timeStamp = $1;
   # Command for deleting pcap files on MasterController
   my $localDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $localCommand = "rm -f " . $localDir . "*$timeStamp*";
   # Cleaning up the MasterController of all pcap files.
   $result = $self->{staf}->STAFSyncProcess("local", $localCommand);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # This is for deleting the pcap files sitting on SUT/Helper
   if ($self->{os} =~ /(lin|esx|vmkernel|mac|darwin)/i) {
      $command = $localCommand;
   } else {
     # Generating a string del /Q C:\\Tools\*.pcap*
     # /Q is to supress windows prompt confirming deletion.
     my $winDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
     my $copyFileName = $winDir;
     $copyFileName =~  s/\\\\/\\/g;
     $command = "del /Q $copyFileName"."*$timeStamp";
   }
   $result = $self->{staf}->STAFSyncProcess($self->{targetip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Deleted all packet Capture files");
   return SUCCESS;

}


##############################################################################
#
# GetVnicAddress --
#       Method to get the IPv4/v6 address or mac for using in the dst and src
#       host filters in the tcpdump
#
# Input:
#       component -- a vnic tuple object(required).
#       type -- type of address (mac/ipv4/ipv6global/ipv6local)
#
# Results:
#       IPv4/v6/Mac Address.
#       -1 in case of any error
#
# Side effects:
#       None
#
##############################################################################

sub GetVnicAddress
{
   my $self      = shift;
   my $component = shift;
   my $addrType  = shift || ''; # If no Address type is specified
   my $ref       = undef;
   my $vnicObj   = undef;

   # This regex takes care of ipv4/ipv6 and MAC
   if ($component =~ m/(^[\d]+\.[\d]+\.[\d]+\.[\d]+$|^([0-9A-Fa-f]{1,4}+)([\:]{1,2}[0-9A-Fa-f]{1,4}+){4,6}$)/) {
      # not a tuple, return the value directly
      return $component;
   }
   $ref = $self->{testbed}->GetComponentObject($component);
   if ((not defined $ref) || ($ref eq FAILURE)) {
      $vdLogger->Error("Invalid ref for tuple $component");
      # will not return FAILURE here if error, since VerificationSpecificJob
      # always return SUCCESS
      return -1;
   }
   $vnicObj = $ref->[0];
   if (not defined $vnicObj) {
      return -1;
   }
   switch($addrType) {
      case "" {
         # If nothing is specified then return IPv4 Address
         return $vnicObj->GetIPv4();
      }
      case m/^ipv4$/i {
         return $vnicObj->GetIPv4();
      }
      case m/(^ipv6global$|^ipv6$)/i {
         my $ipv6Array = $vnicObj->GetIPv6Global();
         $vdLogger->Trace("GetIPv6Global returned:".Dumper($ipv6Array));
         my $ipv6;
         foreach my $ip (@$ipv6Array) {
            if ($ip eq "NULL") {
               $vdLogger->Warn("No IPv6 Global addresses Found");
               return -1;
            }  elsif ($ip =~ m/^2001:bd6/i) {
               $vdLogger->Debug("IPv6 Global address Found:$ip");
               $ipv6 = $ip;
               last;
            }
         }
         # If the IP address is in the format 2001:bd6::000c:2957:426c/80
         # Remove the prefix.
         if ($ipv6 =~ m/\//i) {
            my @tempIP = split(/\//, $ipv6);
            $ipv6 = $tempIP[0];
         }
         return $ipv6;
      }
      case m/^ipv6local$/i {
         my $ipv6Array = $vnicObj->GetIPv6Local();
         $vdLogger->Trace("GetIPv6Local returned:".Dumper($ipv6Array));
         my $ipv6 = $ipv6Array->[0];
         if ($ipv6 eq "NULL") {
            $vdLogger->Warn("No IPv6 local addresses Found");
            return -1;
         }
         # If the IP address is in the format 2001:bd6::000c:2957:426c/80
         # Remove the prefix.
         if ($ipv6 =~ m/\//i) {
            my @tempIP = split(/\//, $ipv6);
            $ipv6 = $tempIP[0];
         }
         return $ipv6;
      }
      case m/^mac$/i {
         return $vnicObj->GetMACAddress();
      }
      default {
         vdLogger->Error("Invalid address type:$addrType specified in pktcap".
            " filter");
         return -1;
      }
   }
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


##############################################################################
#
# GetVnicMac --
#       Method to get the vnic MacAddress.
#
# Input:
#       component -- a tuple for a vif/vnic or direct MacAddress.
#
# Results:
#       Mac Address.
#       -1 in case of any error
#
# Side effects:
#       None
#
##############################################################################
sub GetVnicMac
{
   my $self = shift;
   my $component = shift;
   my $vnicObj   = undef;
   my $macAddrRegex = VDNetLib::TestData::TestConstants::MAC_ADDR_REGEX;
   if ($component =~ /$macAddrRegex/i) {
      # Not a tuple, return the mac address directly.
      return $component;
   }
   my $ref = $self->{testbed}->GetComponentObject($component);
   if ((not defined $ref) || ($ref eq FAILURE)) {
      $vdLogger->Error("Invalid ref for tuple $component");
      return -1;
   }
   $vnicObj = $ref->[0];
   if (not defined $vnicObj) {
      $vdLogger->Error("Vnic Object not found for $component.");
      return -1;
   }
   return $vnicObj->{macAddress};
}


##############################################################################
#
# ReadPersistData --
#       Method to read persist data
#
# Input:
#       component -- a persist data tuple object(required).
#
# Results:
#       value of persist data
#       -1 in case of any error
#
# Side effects:
#       None
#
##############################################################################

sub ReadPersistData
{
   my $self       = shift;
   my $configHash = shift;
   my $index      = shift;

   $vdLogger->Info("Start to fetch the runtime data for $configHash->{$index}");
   my $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                              $configHash->{$index},
                                                              $index);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get saved runtime data for $configHash->{$index}");
      VDSetLastError("EOPFAILED");
      return -1;
   }

   $vdLogger->Info("Persist data result is: $result");
   return $result;
}

1;
