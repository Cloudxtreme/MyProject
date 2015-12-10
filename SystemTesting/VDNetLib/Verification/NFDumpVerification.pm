#!/usr/bin/perl
###############################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::NFDumpVerification;

#
# This module is responsible for netflow verification. It
# captures netflow packet information exported by the VDS
# and then analyze the netflow information to make sure that
# protocol, src and destination information is correct in the
# flows. It uses the nfcapd for capturing netflow packets
# exported by the VDS. Once exported it verifies the netflow
# packets through the use of nfdump. The collector is always
# run on the master controller to ease the setup. Running a
# netflow collector is simply starting nfcapd on a specified
# port. We use the default port "1" to run the collecor on.
#

# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;

use VDNetLib::Common::Utilities;
use VDNetLib::Workloads::Utils;

use PLSTAF;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

###############################################################################
#
# new -
#       This method creates an object of NFDumpVerification and returns it
#
# Input:
#       None
#
# Results:
#       Obj of NFDumpVerification module
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

   my @params = ();

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
         'hostobj'      => {
            'hostIP'            =>  'host',
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

   # find the target to be used as netflow collector.
   $self->{port} = VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT;
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
   return "local";
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
   my $srcIP;
   my $dstIP;
   my $protocol;
   my $targetObj;
   my $targetRef;

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
   # Get the src/dst/protocol information directly from the traffic workload
   $srcIP = $self->{workloadhash}->{client}->{testip};
   $dstIP = $self->{workloadhash}->{server}->{testip};
   my $l3protocol = $self->{workloadhash}->{l3protocol};
   if ($self->{workloadhash}->{toolname} =~ m/ping/i) {
      $protocol = "icmp";
   } else {
      $protocol = $self->{workloadhash}->{l4protocol};
   }
   #The nfdump server can be run on MC or VM, default is MC(local) if
   #it isn't passed in.If the nfdump runs on local, it only supports
   #listen on IPv4 address, because there is no IPv6 path between host
   #vmknic and MC.Set the staf anchor according to target,
   #also set the listenIP according to the addressfamily if the nfdump
   #runs on a VM.
   $self->{listenIP} = '';
   if ($self->{target} eq 'local') {
      $self->{host} = 'local';
   } else {
      $self->{host} = $self->{targetip};
      $targetRef = $self->{testbed}->GetComponentObject($self->{target});
      if (not defined $targetRef) {
         $vdLogger->Error("Invalid ref for tuple $self->{target}");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $targetObj = $targetRef->[0];
      if ($self->{expectedchange}->{addressfamily} eq 'ipv6') {
         my $testIPv6;
         my $findFlag = 0;
         my $ipv6Array = $targetObj->GetIPv6Global();
         $vdLogger->Trace("GetIPv6Global returned:".Dumper($ipv6Array));
         foreach my $testip (@$ipv6Array) {
            if ($testip eq "NULL") {
               last;
            }  elsif ($testip =~ m/(^2001:bd6|^fc00:)/i) {
               $testIPv6 = $testip;
               $findFlag = 1;
               last;
            }
         }
         if ($findFlag == 0) {
            $vdLogger->Error("Can't find IPv6 address for the collector");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         # If the IP address is in the format 2001:bd6::000c:2957:426c/80
         # Remove the prefix.
         if ($testIPv6 =~ m/\//i) {
            my @tempIP = split(/\//, $testIPv6);
            $testIPv6 = $tempIP[0];
         }
         $self->{listenIP} = $testIPv6;
      }  else {
         $self->{listenIP} = $targetObj->GetIPv4();
      }
      $vdLogger->Debug("The nfdump server is listening at $self->{listenIP}");
   }
   $self->{flowCount} = $self->{expectedchange}->{flowCount};
   $self->{src} = $srcIP;
   $self->{dst} = $dstIP;
   $self->{protocol} = $protocol;
   $self->{l3protocol} = $l3protocol;
   $vdLogger->Debug("Verification after setting is" .
                                Dumper($self));
   if ($self->BuildToolCommand() ne SUCCESS) {
      $vdLogger->Error("NFDumpVerification BuildToolCommand() didnt".
                       " return Success");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($self->GenerateDumpFiles() ne SUCCESS) {
      $vdLogger->Error("NFDumpVerification GenerateDumpFiles() didnt".
                       " return Success");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GenerateDumpFiles -
#       This method generates file name with unique timestamp which will
#       store the captured netflow packets in raw form.
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

sub GenerateDumpFiles
{
   my $self = shift;
   my ($captureDir, $launchStatusFile);
   my $sourceDir;
   my $result;

   #
   # We always attach sourceDir to be that of linux/MC because that
   # is the case in most scenarios.
   #
   $sourceDir =  VDNetLib::Common::GlobalConfig::GetLogsDir();
   $captureDir = VDNetLib::Common::Utilities::GetTimeStamp();
   # Attaching the pid of the process to file Name
   if ($self->{target} eq 'local') {
      $captureDir = $captureDir . "-" . $self->{target};
   } else {
      $captureDir = $captureDir . "-" . $self->{targetip};
   }
   $launchStatusFile = "stdout-". $captureDir . "-$$.log";

   $captureDir = "netflowCap-". $captureDir ;
   $captureDir = $sourceDir . $captureDir;
   $launchStatusFile = $captureDir . "/".$launchStatusFile;

   #
   # create the directory for nfcapd inside the log directory.
   # The nfcapd generates the capture file
   #
   $vdLogger->Debug("Creating directory $captureDir on $self->{host}");
   $result = $self->{staf}->STAFFSCreateDir($captureDir, $self->{host});
   if (($result->{rc}) || ($result->{exitCode})) {
      $vdLogger->Error("Failure while creating $captureDir on $self->{host}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $self->{logDir} = $captureDir;
   $self->{launchstdout} = $launchStatusFile;

   return SUCCESS;
}


###############################################################################
#
# GetBucket -
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

   my $template = $self->{nfdumpbucket}->{nodes}->{nfdump}->{template};

   # If not defined then we init the tempalte for the first time.
   # else we always return the template stored in capturebucket
   if (defined $template) {
      return $self->{nfdumpbucket};
   }

   $template = {
      source => "SUT:vnic:1",
      destination => "helper1:vnic:1",
   };

   #
   # We store all the expected and actual pktcap stats in a bucket.
   # bucket -> AnyOS -> A node on that OS(SUT:vnic:1)
   # This node will have template, actual pkt capture stats.
   #
   $self->{nfdumpbucket}->{nodes}->{nfdump}->{template} = $template;
   return $self->{nfdumpbucket};
}


###############################################################################
#
# BuildToolCommand -
#       This method builds the command(binary) for the verification module.
#       It requires two binaries, one to capture the netflow packets and
#       other to analyze the dump file captured. Since in our case only
#       master controller can be collector so we just pick the linux 32
#       bit binaries.
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
   my $os = $self->{os};
   my ($command, $result);
   my $tree;
   my $binpath;
   my $host = $self->{host};

   # We use x86_32 nfcapd and nfdump binaries
   my $arch = "x86_32";
   # Get the path to bin, the bin is in different path for MC and VM
   if ($host eq 'local') {
      $tree = VDNetLib::Common::Utilities::GetVDNETSourceTree();
      $binpath = $tree."bin/";
   } else {
      my $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      $binpath = $globalConfigObj->BinariesPath(VDNetLib::Common::GlobalConfig::OS_LINUX);
   }
   my $pathToBin = "$binpath" . "$arch/linux/";
   my $capturebinFile = "nfcapd";
   my $analysisbinFile = "nfdump";
   $self->{capturebin} = $pathToBin.$capturebinFile;
   $self->{analysisbin} = $pathToBin.$analysisbinFile;

   # just checking if the binary works ok
   $command = "$self->{capturebin} -h ";
   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if (($result->{rc}) || ($result->{exitCode})) {
      $vdLogger->Error("Failure while running $command");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $command = "$self->{analysisbin} -h ";
   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if (($result->{rc}) || ($result->{exitCode})) {
      $vdLogger->Error("Failure while running $command");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
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
   my $binary = $self->{capturebin};
   my $port   = $self->{port};
   my $logDir = $self->{logDir};
   my $host   = $self->{host};
   my $time   = 10000;  # we don't want to rotate the files.
   my $opts   = undef;

   $command = "$binary -p $port -l $logDir -t $time";
   #For IPv6 it must use option -b to set the listening address
   if ($self->{listenIP}) {
      $command = $command." -b $self->{listenIP}";
   }
   $vdLogger->Info("Launching netflow collector ($binary) at $host");
   $result = $self->{staf}->STAFAsyncProcess($host, $command,
                                             $self->{launchstdout}, $opts);
   if ($result->{rc}) {
      $vdLogger->Error("Failed to start the $binary on $host");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{processHandle} = $result->{handle};
   $vdLogger->Debug("Successfully launched nfcapd with handle:".
                    "$self->{processHandle}");

   return SUCCESS;
}


###############################################################################
#
# Stop-
#       This method stops the collector nfcapd.
#
#
# Input:
#
# Results:
#       SUCCESS - if nfcapd gets stopped successfully.
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
   my $fileName;
   my $host = $self->{host};
   my $logDir = $self->{logDir};
   my $processHandle = $self->{processHandle};

   $self->{stopCaptureCalled} = 1;
   $vdLogger->Info("Waiting for nfcapd to dump the data");
   sleep 30;

   if (not defined $processHandle) {
      $vdLogger->Error("StopCapture called without processHandle ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $result = $self->{staf}->GetProcessInfo($host, $processHandle);
   if ($result->{rc}) {
      my $launchStdoutFile = $self->{launchstdout};
      my $nfcapdStdout = $self->{staf}->STAFFSReadFile($host,
                                                      $launchStdoutFile);
      if (not defined $nfcapdStdout) {
         $vdLogger->Error("Something went wrong with reading the stdout file ".
                          "of netflow dump . File:$launchStdoutFile on ".
                          "$host");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   my $pid = $result->{pid};
   $command = "kill $pid";

   $vdLogger->Info("Stopping netflow packet Capture on ".
                   "$self->{target} by killing process ".
                   "with PID:$pid");

   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Waiting for killing pid $pid");

   my $counter = 0;
   while ($self->{staf}->STAFSyncProcess($host,
      "ps -e | grep $pid.*nfcapd")->{stdout} ne '' && $counter < 50){
      # Sleep 2 sec for rechecking the process existance.
      sleep 2;
      $counter++;
   }
   #
   # kill nfcapd so that capture file has some content.
   #
   $command = "pkill nfcapd";
   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Waiting for killing process nfcapd");
   $counter = 0;
   while ($self->{staf}->STAFSyncProcess($host,
      "ps -e | grep nfcapd")->{stdout} ne '' && $counter < 50){
      # Sleep 2 sec for rechecking the process existance.
      sleep 2;
      $counter++;
   }

   # update the nfcapd dump file.
   my $files = $self->{staf}->STAFFSListDirectory($host, $logDir);
   if (not defined $files) {
      $vdLogger->Error("No netflow capture file got generated");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach my $file (@{$files}) {
      # the netflow dump file format is nfacapd.<timestamp>
      if ($file =~ m/nfcapd/i) {
         $fileName = $file;
         last;
      }
   }
   if (not defined $fileName) {
      $vdLogger->Error("no netflow dump file is generated");
      $vdLogger->Error("The content of dump directory is..");
      $vdLogger->Error(Dumper($files));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # store the nfcapd dump files which can be used for analysis.
   $self->{fileName} = $logDir."/".$fileName;
   return SUCCESS;
}


###############################################################################
#
# ExtractResults -
#       This method reads the netflow dump files and checks if the flows were
#       actually captured by the collector.
#
# Input:
#      None
#
# Results:
#       integer value of the information to be extract from packet capture
#       FAILURE in case something goes wrong.
#
###############################################################################

sub ExtractResults
{
   my $self = shift;
   my $result;
   my $fileName = $self->{fileName};

   $result = $self->ParseCapturedFile();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure while parsing the netflow data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # if result is success remove the files.
   $result = $self->CleanUP();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to clean up the netflow dump files");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# ParseCapturedFile -
#       This method interprets the information present in the netflow dump
#       files and makes sure that netflow dump file shows the correct flows.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
###############################################################################

sub ParseCapturedFile
{
   my $self = shift;
   my $fileName = $self->{fileName};
   my $binary = $self->{analysisbin};
   my $src = $self->{src};
   my $dst = $self->{dst};
   my $host = $self->{host};
   my $protocol = $self->{protocol};
   my $flowCount = $self->{flowCount};
   my $result;
   my $command;
   my $flows;

   #
   # read the netflow capture file and verify that
   # it has the right flow information.
   #
   if ($self->{l3protocol} eq 'ipv6') {
      $command = "$binary -o extended6";
   } else {
      $command = $binary;
   }

   $command =
     $command." -r $fileName | grep $src | grep $dst | grep -i $protocol";
   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to read the netflow dump file");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $flows = $result->{stdout};
   if (not defined $flows) {
      $vdLogger->Error("The netflow dump file $fileName doesn't have".
                       " any flow information");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #
   # check the number of flows between $src and $dst;
   #
   my @flow = split('\n', $flows);
   my $totalFlows = scalar(@flow);
   if (defined $flowCount) {
      if ($totalFlows != $flowCount) {
         $vdLogger->Error("Total number of flows between $src and $dst".
                          " is not equal to $flowCount");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   elsif ($totalFlows < 1) {
      $vdLogger->Error("Total number of flows between $src and $dst".
                       " is less than 1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info ("Total number of flows between $src and $dst".
                    " for protocol $protocol is $totalFlows");
   $vdLogger->Info("Infromation related to flows - @flow");
   return SUCCESS;
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
   my $logDir = $self->{logDir};
   my $fileName = $self->{fileName};
   my $host = $self->{host};
   my $opts;

   if ($stopCapture == 0) {
      if ($self->Stop() eq FAILURE) {
         $vdLogger->Error("Failed to stop netflow collector");
         VDSetLastError("EOPFAILED");
         return FAILURE;
       }
   }

   #Wait for dumps to be read before deleting
   $vdLogger->Info("Wait 10 sec before deleting capture trace files");
   sleep(10);
   # remove the directory.
   $opts->{recurse} = 1;
   $result = $self->{staf}->STAFFSDeleteFileOrDir($host, $logDir, $opts);
   if (not defined $result) {
      $vdLogger->Error("Failed to delete the netflow directory");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Debug("Deleted all netflow Capture files");
   return SUCCESS;
}

1;
