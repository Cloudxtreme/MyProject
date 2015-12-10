########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::SpirentTool;
my $version = "1.0";

use FindBin;
use lib "$FindBin::Bin/../../../";

# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Workloads::TrafficWorkload::TrafficTool);

#
# TODO: For now Spirent Core Api Packages are not part of
# vdnet. As it is big in size and contains more than 400000
# files. So to use spirent, please copy the Spirent API's
# and relevant packages into VDNetlib/Spirent.
#
#
# This will be removed before check-in once the Spirent pkgs will be copied
# into VDNetlib/Spirent directory.
#
use lib $ENV{VDNET_SPIRENT_LIB} || "/dbc/pa-dbc1102/gaggarwal/vdnet/main/VDNetLib/Spirent/";
require SpirentTestCenter;

use Data::Dumper;
use Switch;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

#
# Mapping of supported protocol headers types with their
# respective handling methods.
#
our $supportedHeaders = {
   ethernet  => AddEthernetHeader,
   ipv4	     => AddIpv4Header,
   arp	     => AddARPHeader,
};


########################################################################
#
# new --
#       Instantiates Spirent object
#
# Input:
#       none
#
# Results:
#       returns object of SpirentTool class
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class    = shift;

   my $self  = {
      'toolname'     => "spirent",
      'testOptions'   => undef,
      'testResults'   => undef,
      'spirentHandle' => undef,
   };

}


sub SupportedKeys
{
   return SUCCESS;
}


sub BuildToolCommand
{
   return SUCCESS;
}


sub ToolSpecificJob
{
   return SUCCESS;
}


########################################################################
#
# GetToolOptions --
#       This translates the traffic keyworkds into the language which
#       Spirent understands.
#
# Input:
#       Session Key (required)   - E.g. localsendsocketsize
#       Session Value (required) - E.g. 4198
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       string in case of success
#       0 in case there is no translation for that key
#       FAILURE in case of failure
#
# Side effects:
#       None
#
########################################################################

sub GetToolOptions
{
   my $self	  = shift;
   my %args	  = @_;
   my $sessionKey = $args{'sessionkey'};
   my $sessionID  = $args{'sessionID'};
   my $sessionValue;

   if ((not defined $sessionKey) || (not defined $sessionID)) {
      $vdLogger->Error("one or more parameters missing in ".
                       "GetToolOptions.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $sessionValue = $sessionID->{$sessionKey};

   if ((not defined $sessionValue) || $sessionValue eq "") {
      return 0;
   }

   switch ($sessionKey) {
      case m/(testduration)/i {
	 $self->{testOptions}{testDuration}	= $sessionValue;
      }
      case m/(client)/i {
	 $self->{testOptions}{source}		= $sessionValue;
      }
      case m/(server)/i {
	 $self->{testOptions}{destination}	= $sessionValue;
      }
      case m/(noofinbound)/i {
	 $self->{testOptions}{noOfInStreams}	= $sessionValue;
      }
      case m/(noofoutbound)/i {
	 $self->{testOptions}{noOfOutStreams}	= $sessionValue;
      }
      case m/(StreamBlockSizeType)/i {
	 $self->{testOptions}{strBlockSizeType}	= $sessionValue;
      }
      case m/(StreamBlockSize)/i {
	 $self->{testOptions}{strBlockSize}	= $sessionValue;
      }
      case m/(stream)/i {
	 $self->{testOptions}{stream}		= $sessionValue;
      } else {
	 last;
      }
   }

   return 0;
}


sub AppendTestOptions
{
   return SUCCESS;
}


########################################################################
#
# StartClient --
#       This module takes care of creating Spirent Traffic from given
#	source to given destination.
#
# Input:
#       sessionID    : Object of Session Class. (Mandatory)
#
# Results:
#      "SUCCESS", if Spirent traffic is started successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub StartClient
{
   my $self      = shift;
   my $sessionID = shift;

   my $stc = new StcPerl;
   my $srcPort;
   my $dstPort;
   my @stb;
   my $i;

   if ($stc !~ /Hash/i) {
      $vdLogger->Error("Failed to create a SpirentTestcenter object.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $stc->config("automationoptions", loglevel=>"info",
		logto=>"$sessionID->{sessionlogs}"."mylog.txt");

   my $project = $stc->create("project");

   $self->{spirentHandle}  = $stc;
   $self->{spirentProject} = $project;

   $self->ConnectChassis("source");
   $srcPort = $self->{testOptions}{source}{port};

   #
   # Connection to destination will only be established if the destination
   # is also a spirent vnic.
   #
   if ($self->{testOptions}{destination}{os} =~ /spirent/i) {
      $self->ConnectChassis("destination");
      $dstPort = $self->{testOptions}{destination}{port};
   }

   $vdLogger->Info("Creating stream blocks...\n");

   # Create as many parallel streams as given by noofoutbound key
   for (my $i = $self->{testOptions}{noOfOutStreams}; $i > 0 ; $i--) {
      my $index	   = $self->{testOptions}{noOfOutStreams} - $i + 1;
      $stb[$index-1] = $self->CreateStream($srcPort, $index, "outbound");
      if ($stb[$index-1] eq FAILURE) {
	 VDSetLastError("EFAIL");
	 return FAILURE;
      }
   }
   $self->{testOptions}{source}{streams} = \@stb;

   # Configure the generator on source port
   my $genList = $self->ConfigureGenerator($sessionID, $srcPort);
   $self->{testOptions}{source}{generator} = $genList;

   $vdLogger->Info("Starting the generator...\n");
   $stc->perform("GeneratorStart", GeneratorList=>"$genList");

   return SUCCESS;
}


########################################################################
#
# ConnectChassis --
#       This module takes care of establishing the connection with
#	the given target chassis.
#
# Input:
#       target    : Target chassis IP address. (Mandatory)
#
# Results:
#      "SUCCESS", if connection is established successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub ConnectChassis
{
   my $self    = shift;
   my $target  = shift;
   my $stc     = $self->{spirentHandle};
   my $project = $self->{spirentProject};

   my $chassis = $self->{testOptions}{$target}{controlip};

   #
   # TODO : Will add the logic to detect the required slot based
   # on the given MAC address in source and destination
   #
   my $slot ="$chassis/1/1";

   $vdLogger->Info("Connecting to the chassis: $slot...\n");
   $stc->connect($chassis);
   $stc->reserve($slot);

   my $port = $stc->create("port", under=>$project, location=>$slot);

   $stc->perform("setupportmappings");
   $stc->apply();
   $self->{testOptions}{$target}{port} = $port;

   return SUCCESS;
}

########################################################################
#
# CreateStream --
#       This module takes care of creating the raw streams with given
#	parameters and returns the handler of the same.
#
# Input:
#       srcPort      : Source Port.  (Mandatory)
#	index	     : Stream index. (Mandatory)
#	type	     : inbound/outbound. (Optional)
#
# Results:
#      stream, handler for the created raw steram in case of success.
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub CreateStream
{
   my $self    = shift;
   my $srcPort = shift;
   my $index   = shift;
   my $type    = shift || "outbound";
   my $stc     = $self->{spirentHandle};
   my $source;
   my $destination;
   my $stream;

   if ($type =~ /outbound/i) {
      $source	   = "source";
      $destination = "destination";
   } else {

      # This is for inbound traffic.
      $source	   = "destination";
      $destination = "source";
   }

   my $frameSize;
   if (defined $self->{testOptions}{frameSizeValue}) {
      $frameSize = $self->{testOptions}{frameSizeValue};
   } else {
      $frameSize = "1500";
   }

   $stream     = $stc->create("StreamBlock", under=>$srcPort,
			      name=>"StreamBlock".$index,
			      FixedFrameLength=>$frameSize, FrameConfig=>"");
   if((not defined $stream) || $stream !~ /streamblock/i) {
      $vdLogger->Error("Failed to create a StreamBlock.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #
   # If user does not specify any fancy stream format, then
   # a simple Ethernet/L2Header Frame will be used to carry
   # on the traffic.
   #
   if (not defined $self->{testOptions}{stream}) {
      $self->{testOptions}{stream} = "ethernet";
   }

   $result = $self->AddHeaders($stream, $self->{testOptions}{stream},
			       $source, $destination);
   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $stc->perform("StreamBlockUpdate", streamblock=>$stream);

   return $stream;
}

########################################################################
#
# AddHeaders --
#       This module takes care of adding headers to given raw stream
#	based on the user provided input.
#
# Input:
#       stream	     : Stream Handler.         (Mandatory)
#	payload	     : Next Payload hash to be processed. (Mandatory)
#	source	     : source of traffic.      (Mandatory)
#	destination  : destination of traffic. (Mandatory)
#
# Results:
#      "SUCCESS", if required headers are attached to stream successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub AddHeaders
{
   my $self	   = shift;
   my $stream	   = shift;
   my $payload	   = shift;
   my $source	   = shift;
   my $destination = shift;
   my $type	   = $payload->{type} || "ethernet";	# Default Type
   my $result;

   # Converting the keys in payload hash into lowercase
   %$payload = (map { lc $_ => $payload->{$_}} keys %$payload);


   if (not defined $supportedHeaders->{$type}) {
      $vdLogger->Error("Unsupported Header requested: $type");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $method = $supportedHeaders->{$type};

   $result = $self->$method($stream, $payload, $source, $destination);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to add header: $type");
      $vdLogger->Debug("Header options passed are: ". Dumper($payload));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (defined $payload->{payload}) {
      my $innerPayloadType  = $payload->{payload};
      my $innerPayload      = $payload->{$innerPayloadType};
      # Setting itself's type in innner payload
      $innerPayload->{type} = $innerPayloadType;
      return $self->AddHeaders($stream, $innerPayload,
			       $source, $destination);
   } elsif (defined $payload->{data}) {
      #
      # Use this option later to fill this data in the current stream.
      # Currently Spirent automatically fills the data portion.
      #
   }

   return SUCCESS;
}


########################################################################
#
# AddEthernetHeader --
#       This module takes care of appending ethernet header to the
#	given stream, with the user provided parameters.
#
# Input:
#       stream	     : Stream Handler.         (Mandatory)
#	payload	     : Next Payload hash to be processed. (Mandatory)
#	source	     : source of traffic.      (Mandatory)
#	destination  : destination of traffic. (Mandatory)
#
# Results:
#      "SUCCESS", if ethernet header is added successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub AddEthernetHeader
{
   my $self	   = shift;
   my $stream	   = shift;
   my $payload	   = shift;
   my $source	   = shift;
   my $destination = shift;
   my $stc	   = $self->{spirentHandle};
   my $result;

   my $srcMac;
   my $dstMac;

   if (defined $payload->{srcmac}) {
      $srcMac = $payload->{srcmac};
   } else {
      $srcMac = $self->{testOptions}{$source}{macaddress};
   }

   if (defined $payload->{dstmac}) {
      $dstMac = $payload->{dstmac};
   } else {
      $dstMac = $self->{testOptions}{$destination}{macaddress};
   }

   $result = $stc->create("ethernet:EthernetII", under=>$stream, srcMac=>$srcMac, dstMac=>$dstMac);

   if ($result !~ /ethernet/i) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# AddIpv4Header --
#       This module takes care of appending Ipv4 header to the
#	given stream, with the user provided parameters.
#
# Input:
#   stream	     : Stream Handler.         (Mandatory)
#	payload	     : Next Payload hash to be processed. (Mandatory)
#	source	     : source of traffic.      (Mandatory)
#	destination  : destination of traffic. (Mandatory)
#
# Results:
#      "SUCCESS", if Ipv4 header is added successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub AddIpv4Header
{
   my $self	   = shift;
   my $stream	   = shift;
   my $payload	   = shift;
   my $source	   = shift;
   my $destination = shift;
   my $stc	   = $self->{spirentHandle};
   my $result;

   my $srcIP;
   my $dstIP;

   if (defined $payload->{srcip}) {
      $srcIP = $payload->{srcip};
   } else {
      $srcIP = $self->{testOptions}{$source}{testip};
   }

   if (defined $payload->{dstip}) {
      $dstIP = $payload->{dstip};
   } else {
      $dstIP = $self->{testOptions}{$destination}{testip};
   }

   $result = $stc->create("ipv4:IPv4", under=>$stream, sourceaddr=>$srcIP, destaddr=>$dstIP, gateway=>$dstIP);

   if ($result !~ /ipv4/i) {
      $vdLogger->Error("Failed to create Ipv4 header.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# AddARPHeader --
#       This module takes care of appending ARP header to the
#       given stream, with the user provided parameters.
#
# Input:
#       stream	     : Stream Handler.         (Mandatory)
#	payload	     : Next Payload hash to be processed. (Mandatory)
#	source	     : source of traffic.      (Mandatory)
#	destination  : destination of traffic. (Mandatory)
#
# Results:
#      "SUCCESS", if Ipv4 header is added successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub AddARPHeader
{
   my $self	   = shift;
   my $stream	   = shift;
   my $payload	   = shift;
   my $source	   = shift;
   my $destination = shift;
   my $stc	       = $self->{spirentHandle};
   my $result;

   my $srcMac;
   my $dstMac;

   if (defined $payload->{srcmac}) {
      $srcMac = $payload->{srcmac};
   } else {
      $srcMac = $self->{testOptions}{$source}{macaddress};
   }

   if (defined $payload->{dstmac}) {
      $dstMac = $payload->{dstmac};
   } else {
      $dstMac = $self->{testOptions}{$destination}{macaddress};
   }


   my $srcIP;
   my $dstIP;

   if (defined $payload->{srcip}) {
      $srcIP = $payload->{srcip};
   } else {
      $srcIP = $self->{testOptions}{$source}{testip};
   }

   if (defined $payload->{dstip}) {
      $dstIP = $payload->{dstip};
   } else {
      $dstIP = $self->{testOptions}{$destination}{testip};
   }

   # ARP Request(default)
   if (not defined $payload->{operation} ||
       (defined $payload->{operation} && $payload->{operation} == 1)) {
      $vdLogger->Info("Generating ARP Request stream");
      $result = $stc->create("arp:ARP",
                          under        => $stream,
                          senderHwAddr => $srcMac,
                          senderPAddr  => $srcIP,
                          targetHwAddr => "00:00:00:00:00:00",
                          targetPAddr  => $dstIP,
                          );
   } else {
      # ARP Reply
      $result = $stc->create("arp:ARP",
                          under        => $stream,
                          operation    => "2",
                          senderHwAddr => $srcMac,
                          senderPAddr  => $srcIP,
                          targetHwAddr => $dstMac,
                          targetPAddr  => $dstIP,
                          );
   }

   if ($result !~ /arp/i) {
      $vdLogger->Error("Failed to create ARP header.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureGenerator --
#       This module takes care of configure the Spirent Generator on
#	the given chassis port.
#
# Input:
#       port	     : Chassis port, where generator should be configured.
#		       (Mandatory)
#
# Results:
#      genlist, if generator is configured successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub ConfigureGenerator
{
   my $self      = shift;
   my $sessionID = shift;
   my $port      = shift;
   my $stc       = $self->{spirentHandle};

   my (@gen, @genConfig);

   $gen[1]       = $stc->get($port, "children-generator");
   $genConfig[1] = $stc->get($gen[1], "children-GeneratorConfig");

   $stc->config($genConfig[1], SchedulingMode=>"RATE_BASED",
                        Duration=>$self->{testOptions}{testDuration},
                        DurationMode=>"SECONDS", LoadUnit=>"FRAMES_PER_SECOND",
                        LoadMode=>"FIXED", FixedLoad=>"100");

   $stc->apply();
   $stc->perform("SaveAsXmlCommand",
                 filename=>"$sessionID->{sessionlogs}"."stream_config.xml");

   return join(" ", @gen);
}


########################################################################
#
# DisconnectChassis --
#       This module takes care of releasing the chassis, it's port and
#	other Spirent Chassis resources.
#
# Input:
#	none
#
# Results:
#      "SUCCESS", After the current spirent handle is destroyed successfully;
#
# Side effects:
#       none
#
########################################################################

sub DisconnectChassis
{
   my $self = shift;
   my $stc  = $self->{spirentHandle};

   $stc->destroy();

   return SUCCESS;
}


########################################################################
#
# GetResult --
#       This module takes care of calculating and reporting the results
#	for all the streams in current Spirent test session.
#
# Input:
#       sessionID    : Object of Session Class. (Mandatory)
#	timeout	     : Wait timeout. (in seconds) (Optional)
#	minExpResult : Minimum expected result. (in Mbps) (Optional)
#	maxThroughput: Maximum throughput expected. (Optional)
#
# Results:
#      "SUCCESS", if results are reported successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#       none
#
########################################################################

sub GetResult
{
   my $self	     = shift;
   my $sessionID     = shift;
   my $timeout	     = shift;
   my $minExpResult  = shift || undef;
   my $maxThroughput = shift || undef;
   my $result	     = SUCCESS;

   my $stc	     = $self->{spirentHandle};
   my $project	     = $self->{spirentProject};
   my $testDuration = $sessionID->{testduration};
   my @stb	     = @{$self->{testOptions}{source}{streams}};
   my $i;

   my (@hTxStreamResults, @hRxStreamResults);
   my (@txStreamResult, @rxStreamResult);

   $stc->subscribe(Parent=>$project, ConfigType=>"Streamblock",
		  resulttype=>"RxStreamSummaryResults",
		  filenameprefix=>"RxStream_results",
		  viewAttributeList=>'FrameCount');

   $stc->subscribe(Parent=>$project, ConfigType=>"Streamblock",
		   resulttype=>"TxStreamResults",
		   filenameprefix=>"TxStream_results",
		   viewAttributeList=>'FrameCount');

   # Check if the timout specifiied by user or test is draconian
   # if yes, override it.
   if ((not defined $timeout) ||
       $timeout < VDNetLib::Common::GlobalConfig::WAIT_TIMEOUT ||
       $timeout < $testDuration) {
      $timeout = $testDuration + VDNetLib::Common::GlobalConfig::WAIT_TIMEOUT;
   }

   $stc->perform("GeneratorWaitForStop", WaitTimeout=>$timeout,
                  GeneratorList=>"$self->{testOptions}{source}{generator}");
   sleep 2;

   for ($i = 0; $i <= $#stb; $i++) {
      $hTxStreamResults[$i] = $stc->get($stb[$i], "children-TxStreamResults");
      $hRxStreamResults[$i] = $stc->get($stb[$i], "children-RxStreamSummaryResults");

      $txStreamResult[$i]   = $stc->get($hTxStreamResults[$i], "FrameCount");
      $rxStreamResult[$i]   = $stc->get($hRxStreamResults[$i], "FrameCount");

      $vdLogger->Info('Tx count for stream['. $i-1 .'] is : '. $txStreamResult[$i]."\n");
      $vdLogger->Info('Rx count for stream['. $i-1 .'] is : '. $rxStreamResult[$i]."\n\n");
   }

   for ($i = 0; $i <= $#stb; $i++) {
      if ($txStreamResult[$i] == 0) {
	 if ((defined $minExpResult) && $minExpResult =~ /IGNORE/i) {
	    $vdLogger->Info("Ignoring traffic verification as per test requirement.");
	 } else {
	    $vdLogger->Error('Tx count for stream['. $i-1 . "] is : 0");
	    $result = FAILURE;
	 }
      }
   }

   $vdLogger->Info("Releasing the ports and disconnecting from the chassis...\n");
   $self->DisconnectChassis();

   return $result;
}

1;
