########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::PacketCapture;
##############################################################################
#                                                                            #
# File Name:                                                                 #
# PacketCapture.pm                                                           #
#                                                                            #
# Purpose:                                                                   #
# This module can be used to remote issue commands to a host to              #
# do the following:                                                          #
# 1. Start a capture                                                         #
# 2. Stop an existing capture                                                #
# 3. Run Filters over existing captured files                                #
# 4. Run tests over existing captured files                                  #
# 5. Get all the captured files from the remote host                         #
#                                                                            #
# Author:                                                                    #
# Priyanka Warade                                                            #
##############################################################################

use strict;
use warnings;

use POSIX qw(:errno_h);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use File::Spec::Functions qw(catdir catfile rel2abs );
use Data::Dumper;
use PLSTAF;
use Carp;

our (@ISA, @EXPORT,$VERSION);
use Exporter;

$VERSION = 1.00;
@ISA=qw(Exporter);

@EXPORT =
 qw(startCapture initCapture stopCapture cleanupCapture getFile getPortGroup
             runFilter runTest $errorString uninitCapture);

#This handle used to communicate with STAF after registering
my $handle;

#Define OS_TYPES as constants
use constant {
   VMKERNEL_OS => 0,
   LINUX_OS => 1,
   WINDOWS_OS => 2,
   SOLARIS_OS => 3,
};

my $np = new VDNetLib::Common::GlobalConfig;
my $binpath = $np->BinariesPath(WINDOWS_OS);
#
# CheckTcpdump() copies Windump.exe from $binpath\\\\x86_32\\\\windows to
# C:\\\\tools
#
my $windump = "C:\\\\tools\\\\WinDump.exe";

# $errorString is set if an error is encountered. On a negative return value
# from the API, this string should be checked for error which occcured
our $errorString;

# A hash table which keeps track fo all the captures which were started in the
# same script. The handle returned to the user is used as a key to retrieve
# that capture's information
my %dataStructure=();

# Handle returned to the user. Start from 1
my $index=1;

# Setting the 'ignore' signal for SIGPIPE
$SIG{PIPE} = 'IGNORE';

#
# Syntax:
# initCapture();
#
# Description:
# This function is used register with STAF. It is to be called only once
# in every script
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub initCapture()
{
   #Registering for STAF handle
   $handle=STAF::STAFHandle->new($0);
   if($handle->{rc}!=$STAF::kOk){
      $errorString = "Error registering with STAF, STAF daemon may not be running";
      return -1;
   }
   return 0;
}

#
# Syntax:
# uninitCapture();
#
# Description:
# This function is used unregister with STAF. It is to be called only once
# in every script
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub uninitCapture()
{
   #Un-registering for STAF handle
   my $result;
   $result = $handle->unRegister();
   if($result != $STAF::kOk){
      $errorString = "Error uregistering with STAF";
      return -1;
   }
}
#
# Syntax:
# startCapture( host, interface, fileName=>?, timeout=>?, filter=>?)
#
# Description:
# This function is used to start capture at the remote host
#
# Input Parameters:
# - The required argument 'host' is the target machine where you want to run
#   the capture
# - The required argument 'interface' is the interface at which you want to sniff on
# - The required argument 'filename' is the name of the file in which the captured
#   packets are to be saved. The captured packets are stored in 20MB files The first
#   file will have the name given by the user. The succeeding files will have the name
#   given by the user succeeded by 1,2.. and so on. For this reason, no filename should
#   end with a number or must have a name similar to that of the
#   an already existing file on the traget host
# - The optional parameter 'sourceDir' where the captured files need to be dumped, by default
#   it is  /tmp on linux and C: on windows
# - The optional parameter 'timeout' specifies the time for which you want to run
#   the capture. If set to 0, it is considered to be no timer
# - The optional paramter 'filter' is used to pass any additional
#   parameters or filters to tcpdump/windump to capture packets
# Returns:
# >0: Success, returns handle
# -1: On failure, $errorString is set to indicate the cause of failure
#

sub startCapture($$;%)
{
   my $host;
   my $interface;
   my $portGroup;
   my $fileName;
   my $filterString;
   my $time;
   my $command;
   my $result;
   my $OS;
   my $mc;
   my $entryMap;
   my $staticHandle;
   my $startTime;
   my $returnValue;
   my $processHandle;
   my $service;
   my $rc;
   my $sourceDir;
   my @temp;
   my @args;
   my @rv;
   my $i;
   my $flag=0;
   my %options;

   ($host,$interface,%options)=@_;

   $vdLogger->Debug("Host: $host, Interface:$interface");

   #checking for timer
   $time = defined($options{timeout}) ? $options{timeout} :0;
   if ($time !~ /^\d+$/) {
     $errorString = "Invalid Time: Give time in seconds $time";
     return -1;
   }

   #checking if filter string is given
   $filterString =  defined($options{filter}) ? $options{filter} : "";
   if($filterString =~ /-w/){
     $errorString ="Invalid Filter String: -w flag should be removed";
     return -1;
   }

   #check for invalid file name
   $fileName = defined($options{fileName}) ? $options{fileName} : "Pcap";
   if($fileName =~ /\d+$/){
      $errorString = "Invalid File Name: Cannot end with a number";
      return -1;
   }

   #checking if STAF is running on host
   if(checkSTAF($host) < 0){
      return -1;
   }

   #find if interface is virtual switch n then process
   if($interface=~/vswitch/){
       #If the interface is vswitch, format should be vswitch:<portgroup>:<sniffer_vm_ip>
      @temp=split(/:/,$interface);

      #making the portgroup promiscuous
      if(vswitch($temp[1],$host)<0){
      	 return -1;
      }
      $interface="eth0";
      $host=$temp[2];

      #checking if STAF is running on sniffer
      if(checkSTAF($host) < 0){
         return -1;
      }
   }

   #Getting the OS type for host
   $OS=getOS($host);
   if($OS < 0){
	return -1;
   }
   #Checking if tcpdump is installed on the host
   if(checkTcpdump($host,$OS) < 0){
      return -1;
   }
   $fileName = defined($options{fileName}) ? $options{fileName} : "Pcap";

   #In linux, all the files are stored in /tmp and in Windows in C:\\tmp
   if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
      $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "/tmp";
   }elsif($OS == WINDOWS_OS){
      $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "C:\\tmp";
      $command = "start shell command mkdir -p $sourceDir wait returnstdout";
      $service = "process";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      if ( $interface !~ /^(\d+)$/ ) {
         # it is a not a digit means it is a GUID, get the windumpindex
         my $windex = GetWinDumpIndex($host, $interface);
         if ( $windex =~ /^\d+$/ ) {
            $interface = $windex;
            $vdLogger->Debug("windows interface $windex ");
         } else {
            return -1;
         }
      }
   }

   #check to see if that file name is already present
   $rc = checkFile($host, $OS, $fileName,$sourceDir);
   if($rc == 0){
      $errorString = "$fileName already exists at $sourceDir on $host";
      $vdLogger->Debug("$fileName already exists at $sourceDir on $host");
      return -1;
   }

   #Command to run tcpdump/windump on the remote host depending on the host type and whether or
   #not filter string was given. We run the process aysnchronously and register for it to
   #notify on end to the handle we got when we registered with STAF

   #If linux or solaris
   if($OS==LINUX_OS || $OS==SOLARIS_OS || $OS==VMKERNEL_OS){
      if(defined($filterString)){
         $command = "start shell command tcpdump parms -i $interface -e -vvv -s0 -C 20 -Z root -w
         /$sourceDir/$fileName $filterString async notify onend handle $handle->{handle} returnstderr";
      }else{
         $command = "start shell command tcpdump parms -i $interface -e -vvv -s0 -C 20 -Z root
         -w /$sourceDir/$fileName async notify onend handle $handle->{handle} returnstderr";
      }
   }
   #If windows
   elsif ($OS==WINDOWS_OS){
      if(defined($filterString)){
            $command ="start shell command $windump parms -i $interface -e -vvv -s0 -C 20 -Z root -w
            $sourceDir\\$fileName $filterString async notify onend handle $handle->{handle} returnstderr";
         }else{
            $command ="start shell command $windump parms -i $interface -e -vvv -s0 -C 20 -Z root
            -w $sourceDir\\$fileName async notify onend handle $handle->{handle} returnstderr";
         }
   }

   $vdLogger->Debug("tcpdump: $command ");
   $service = "process";
   $result=$handle->submit($host,$service,$command);
   if(processError($result) < 0){
      return -1;
   }else{
      $processHandle=$result->{result};
   }

   #We sleep for 3 seconds and then query the queue to see if the process
   #failed to start.
   sleep 3;

   $command = "get type STAF/Process/End contains \"$processHandle\"";
   $service = "queue";
   $result = $handle->submit("local",$service,$command);

   if(($result->{rc})!=$STAF::kOk){
      if(($result->{rc})!=29){
         if((length($result->{result}))!=0){
            $errorString = $result->{result};
            return -1;
         }
         $errorString = "STAF generated $result->{rc} error";
         return -1;
      }
   }elsif(length($result->{result})!=0){

      #process returned so checking for error
      $mc =STAF::STAFUnmarshall($result->{result});
      $entryMap=$mc->getRootObject();
      if(length($entryMap->{message}{fileList}[0]{data})!=0){
         #format the errorString
         @rv = split(/\n/,$entryMap->{message}{fileList}[0]{data});
         for($i=0;$i<scalar(@rv);$i++){
            if(!(($rv[$i] =~ /listening on/i)||($rv[$i] =~ /Got/i))){
               if($flag==0){
                  $errorString = $rv[$i];
               }else{
                  $errorString = $errorString.$rv[$i];
               }
               $flag=1;
            }
            $errorString = $errorString."\n";
         }
         if($flag==1){
            chomp($errorString);
            return -1;
         }
      }
   }

   #If the process did not return we create a child process which keeps
   #track of the capture taking place at the remote host. The child will
   #kill the process on the remote host if the script ends without
   #calling stopCapture or setting a timer. If a timer is set, the child
   #will stop the capturing at remote host when the timer expires even
   #if the script has ended

   #setting up a pipe for the parnet-child process
   my($reader,$writer);
   pipe($reader,$writer);

   #making $writer autoflush
   select($writer);
   $|++;
   select(STDOUT);

   #creating a child process for every capture
   if(my $pid=fork){
      close $reader;

      #sending capture details to child
      print $writer "$host,$OS,$processHandle,$time\n";

      #Inserting the capture details in hash table
      $dataStructure{$index}={'host'=>$host,
                              'interface'=>$interface,
                              'fileName'=>$fileName,
			      'sourceDir'=>$sourceDir,
                              'timeout'=>$time,
                              'handle'=>$processHandle,
                              'OS'=>$OS,
                              'pid'=>$pid,
                              'writer'=>$writer};

      $returnValue=$index;
      $index=$index+1;
      return $returnValue;

   #In child process
   }else{
      die "cannot fork: $!" unless defined $pid;
      my $line;
      my @arg;
      my $timer=0;
      my $result;
      my $handle;
      my $host;
      my $service;
      my $command;
      my $processHandle;
      my $OS;

      #setting up a handler for SIGALRM. The handler will stop the process
      #at the remote host
      $SIG{ALRM}=sub{
                       $handle=STAF::STAFHandle->new("My Child");
                       if($handle->{rc}!=$STAF::kOk){
                          exit(0);
                       }
                       #clean up function which stops tcpdump on the remote machine
                       if($OS == LINUX_OS|| $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
                          $command = "stop handle $processHandle using SIGKILLALL";
                       }elsif($OS == WINDOWS_OS){
                          $command = "stop handle $processHandle using WM_CLOSE";
                       }
                       $service = "process";
                       $result=$handle->submit($host,$service, $command);
                       if(($result->{rc})!=$STAF::kOk){
                          exit(0);
                          }
                        exit(0);
                    };
      close $writer;

      #reading from parent, parents sends capture details to child
      chomp($line=<$reader>);
      @arg=split(/,/,$line);
      $host = $arg[0];
      $OS = $arg[1];
      $processHandle = $arg[2];
      if($arg[3]!=0){
         alarm $arg[3];
         $timer=1;
      }

      #The child receives stop when stopCapture is called. It will exit even
      #if the the timer is set
      if(defined($line=<$reader>)){
         if($line=~/STOP/){
            #unset the timer
            alarm 0;
            exit(0);
         }
      }else{

       #if it receives undef from parent, indicates that the parent closed writer
       #Child waits for the alarm to go off if set
            if($timer==1){
               while(1){;}
            }else{

            #If timer is not set it will stop the process at the remote host and exit
               $handle=STAF::STAFHandle->new("My Child");
               if($handle->{rc}!=$STAF::kOk){
                  exit(0);
               }

               #clean up function which stops tcpdump on the remote machine
               if($OS == LINUX_OS|| $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
                  $command = "stop handle $processHandle using SIGKILLALL";
               }elsif($OS == WINDOWS_OS){
                  $command = "stop handle $processHandle using WM_CLOSE";
               }
               $service = "process";
               $result=$handle->submit($host,$service, $command);
               if($handle->{rc}!=$STAF::kOk){
                  exit(0);
               }
               exit(0);
           }
	}

  }

}

#
# TODO: All the staf helper routines should be moved to STAFHelper.pm later
# Syntax:
# GetWinDumpIndex(host);
#
# Description:
# This helper function is used get the WinDump Index of a NIC given its GUID
# only applicable for windows
#
# Input Paramters:
# - The required parameters are: 'host IP address' and 'GUID'
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub
GetWinDumpIndex($$)
{
   my $host = shift;
   my $GUID = shift;

   my $command;
   my $result;
   my $service;


   if ( not defined $host ) {
      $vdLogger->Error("Unknown Host");
      return "EHOST";
   }

   $service = "process";
   $GUID =~ s/\^\{//;
   $GUID =~ s/\}\^//;
   # TODO: For now, hard-coding the architecture
   my $path2Bin = "C:\\\\tools\\\\";
   $command = $path2Bin . "WinDump.exe -D";
   $command = $command . " wait returnstdout stderrtostdout";
   $vdLogger->Debug("packetcapture: $command $GUID");
   $command = "start shell command " . "$command";

   $result = $handle->submit("$host", "$service", "$command");

   if ( $result->{rc} != $STAF::kOk ) {
      $vdLogger->Error("STAF error");
      return "ESTAF";
   } else {
      my $mc = STAF::STAFUnmarshall($result->{result});
      my $entryMap=$mc->getRootObject();
      my $winDumpIndex = $entryMap->{fileList}[0]{data};
      chomp($winDumpIndex);
      if ( $winDumpIndex =~ /.*(\d+).\\\S+\\.*$GUID.*/ ) {
         return $1;
      } else {
         return "ENOTFOUND";
      }
   }
}
#
# Syntax:
# checkSTAF(host );
#
# Description:
# This helper function is used to check if the host is reachable and if STAF is running
#
# Input Parameters:
# - The required paramter 'host' is the target machine
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub checkSTAF($)
{
   my $service;
   my $command;
   my $result;
   my $host=shift;
   $service = "ping";
   $command = "ping";
   $result=$handle->submit($host,$service,$command);
   if(($result->{rc})!=$STAF::kOk){
      $errorString="STAF Daemon is not running on $host or no path to $host";
      return -1;
   }
   return 0;
}

#
# Syntax:
# checkTcpdump(host ,OS)
#
# Description:
# This function is used to check is tcpdump/windump is installed on host with
# the environment variable PATH set
#
# Input Parameter:
# - The required parameter 'host' is the target machine
# - The rquired parameter 'OS' is OS of the target machine
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub checkTcpdump($$)
{
   my $host=shift;
   my $OS=shift;
   my $result;
   my $mc;
   my $entryMap;
   my $command;
   if( $OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS ) {
      $command="start shell command tcpdump parms -h wait returnstderr";
   }
   elsif($OS == WINDOWS_OS){
      $command = 'GET ENTRY "C:\\\\Tools\\\\WinDump.exe" TYPE';
      $result=$handle->submit($host,"FS",$command);
      #
      # The following block checks if the given node is file
      # (indirectly checks if the file is present, result will be not equal
      # to F if the file is not present).
      #

      if ($result->{result} ne "F") {
         $command = 'CREATE DIRECTORY "C:\\\\Tools"';
         $result=$handle->submit($host,"FS",$command);
         if ($result->{rc} != 0) {
            return -1;
         }
         my $file = "$binpath" . "x86_32" . "\\\\windows\\\\WinDump.exe";
         $command = "COPY FILE " . STAF::WrapData($file) . " TOMACHINE $host ".
                    "TODIRECTORY " . STAF::WrapData("C:\\\\Tools");
         $result=$handle->submit($host,"FS",$command);
         if ($result->{rc} != 0) {
            return -1;
         }
      }

      $command="start shell command $windump parms -h wait returnstderr";
   }
   $result=$handle->submit($host,"process",$command);
   if(processError($result) < 0){
      return -1;
   }
   else{
      $mc =STAF::STAFUnmarshall($result->{result});
      $entryMap=$mc->getRootObject();
      if(length($entryMap->{fileList}[0]{data})!=0 &&
      ($entryMap->{fileList}[0]{data} =~ /not found/i ||
      $entryMap->{fileList}[0]{data} =~ /not recognized/i)){
         $errorString = "windump/tcpdump is not installed on $host";
         return -1;
      }
      return 0;
   }
}
#
# Syntax:
# getOS(host );
#
# Description:
# This helper function is used get the OS of the remote machine
#
# Input Paramters:
# - The required parameter 'host' is the target host machine
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub getOS($)
{
   my $command;
   my $result;
   my $host;
   my $service;

   $host = shift;
   $service = "var";
   $command="resolve string {STAF/Config/OS/Name}";
   $result=$handle->submit($host,"var",$command);
   if(processError($result) < 0){
      return -1;
   }

   else{
      if(($result->{result})=~/linux/i){
         return LINUX_OS;
      }elsif(($result->{result})=~/win/i){
         return WINDOWS_OS;
      }
      elsif(($result->{result})=~/sun/i){
         return SOLARIS_OS;
      }elsif(($result->{result})=~/vmkernel/i){
         return VMKERNEL_OS;
      }else{
	$errorString = "Unknown OS";
        return -1;
      }
   }
}

sub waitCapture {
   my ($handle) = @_;
   if(!(exists $dataStructure{$handle})){
      $errorString = "Handle does not exist";
     return -1;
   }
   my $capture_pid = $dataStructure{$handle}->{pid};
   waitpid(0,$capture_pid);
   return 0;
}
#
# Syntax:
# stopCapture( handle)
#
# Description:
# This function is used to stop capture at the remote host
#
# Input Parameters:
# - The required paramter 'handle' is the handle returned by the corresponding
#   startCapture
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub stopCapture
{
   my $index;
   my $host;
   my $processHandle;
   my $command;
   my $result;
   my $writer;
   my $service;
   my $mc;
   my $OS;
   my $entryMap;
   my @args;
   my $status;
   my @rv;
   my $i;

   @args = @_;
   #checking for correct number of parameters
   if(scalar(@args) < 1){
      $errorString = "USAGE: stopCapture( HANDLE );";
      return -1;
   }

   #extracting the details of the capture from the hash table using
   #handle as key
   $index = $args[0];
   if(!(exists $dataStructure{$index})){
     $errorString = "Handle does not exist";
     return -1;
   }
   $host = $dataStructure{$index}->{'host'};
   $processHandle = $dataStructure{$index}->{'handle'};
   $writer = $dataStructure{$index}->{'writer'};
   $OS = $dataStructure{$index}->{'OS'};

   #writing to the child to indicate stopCapture was called. If received
   #SIGPIPE that means timer was set and child closed reader after stoppping
   #process at host. Remove the message notification and exit

   #checking if STAF is running on host
   if(checkSTAF($host) < 0){
      return -1;
   }

   $status = print $writer "STOP\n";
   if(!$status && $! == EPIPE){
      #ignore the  error remove from queue and exit successfully
      $service="queue";
      $command="get type STAF/Process/End contains \"$processHandle\"";
      $result=$handle->submit("local",$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      return 0;
   }

   #Otherwise stop the process at the remote host
   $service="process";
   if( $OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS ) {
      $command = "stop handle $processHandle using SIGKILLALL";
   }elsif($OS == WINDOWS_OS){
      $command = "stop handle $processHandle using WM_CLOSE";
   }
   $result=$handle->submit($host,$service,$command);
   if(($result->{rc})!=$STAF::kOk){

    #checking if the process terminated abnormally before calling stopCapture
      if(($result->{rc})==11){
         $service="queue";
         $command="get type STAF/Process/End contains \"$processHandle\"";
         $result=$handle->submit("local",$service,$command);
         if(($result->{rc})!=$STAF::kOk){
            if((($result->{rc})!=29) && (length($result->{result})!=0)){
               $errorString = $result->{result};
               return -1;
            }
            $errorString = "STAF generated $result->{rc} error";
            return -1;
         }elsif(length($result->{result})!=0){

            #get the cause of error
            $mc =STAF::STAFUnmarshall($result->{result});
            $entryMap=$mc->getRootObject();
            if(length($entryMap->{message}{fileList}[0]{data})!=0){

               #format errorString
               @rv = split(/\n/,$entryMap->{message}{fileList}[0]{data});
               for($i=0;$i<scalar(@rv);$i++){
                  if(!($rv[$i] =~ /listening on/)){
                     if($i==0){
                        $errorString = $rv[$i];
                     }else{
                     $errorString = $errorString.$rv[$i];
                  }
               }
               $errorString = $errorString."\n";
            }
            chomp($errorString);
            return -1;
            }
         }
      }elsif(length($result->{result})!=0){
         $errorString = $result->{result};
         return -1;
      }else{
         $errorString = "STAF generated $result->{rc} error";
         return -1;
      }
   }
   return 0;
}
#
# Syntax:
# getFile( handle,destFileName=>?,sourceHost=>?, sourceFileName=>?, sourceDir=>?)
#
# Description:
# This function is used to get files from the remote host
#
# Input Parameters:
# - The required argument 'handle' is the handle returned by startCapture in
#   the same script. Id '0' then source_host, source_filename and source_dir need
#   to be specified
# - The optional argument 'destFileName' is the filename as which you want to
#   store the files.
# - The optional argument 'sourceHost' is the target machine. It is ignored if
#   handle is given. It is required if handle is 0
# - The optional argument 'sourceFileName' is the file you want. It is ignored if
#   handle is given. It is required if handle is 0
# - The optional argument 'sourceDir' is the directory where the files are.
#   It is ignored if handle is given. If not given if handle =0 then the default
#   directory is C:\ for Windows and /tmp for Linux and Solaris
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub getFile($;%)
{
   my $index;
   my $host;
   my $command;
   my $result;
   my $fileName1;
   my $fileName2;
   my $sourceFileName;
   my $sourceDir;
   my $destFileName;
   my $destDir;
   my $OS;
   my $fileCount=1;
   my $service;
   my $workDir = "/tmp";
   my $mc;
   my $entryMap;
   my $rc;
   my %options;

   ($index , %options) = @_;

   #checking for correct number of args
   if($index eq "0" && ! defined($options{sourceHost})){
      $errorString = "USAGE: getFile( HANDLE, destFileName=>, sourceHost=> , sourceFileName=>?, sourceDir=>?); \n
                      if HANDLE = 0 SOURCE_HOST SOURCE_FILENAME and SOURCE_DIR should be given";
      return -1;
   }


   #If handle is '0' then getting the other arg

   $destFileName = defined($options{destFileName}) ? $options{destFileName} : "destPcap";

   if($index eq "0"){
      $host = $options{sourceHost};
      $sourceFileName = defined($options{sourceFileName}) ? $options{sourceFileName} : "Pcap";
      $OS=getOS($host);
      #In linux, all the files are stored in /tmp and in Windows in C:\
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
          $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "/tmp";
      }elsif($OS == WINDOWS_OS){
          $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "C:\\tmp";
      }
      if(($sourceDir =~ /(.*)(\/)+$/) || ($sourceDir =~ /(.*)(\\)+$/)){
         $sourceDir = $1;
      }else{
         $sourceDir = $sourceDir;
      }

      if($OS < 0){
         return -1;
      }
   #If not then extracting for has table
   }else{
      #Extracting from the hash table
      if(!(exists $dataStructure{$index})){
         $errorString = "Handle does not exist";
         return -1;
      }
      $host=$dataStructure{$index}->{'host'};
      $OS=$dataStructure{$index}->{'OS'};
      $sourceFileName=$dataStructure{$index}->{'fileName'};

   }

   $fileName1 = $sourceFileName;
   $fileName2 = $destFileName;

   #checking if STAF is running on host
   if(checkSTAF($host)==-1){
      return -1;
   }
   #setting up default directories for linux/solaris/windows
   if(($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS )&& !(defined($sourceDir))){
      $sourceDir = "/tmp";
   }
   elsif($OS==WINDOWS_OS && !(defined($sourceDir))){
      $sourceDir = "C:\\tmp";
   }

   while(1){
      #checking if the file at host exists
      $rc = checkFile($host,$OS,$sourceFileName,$sourceDir);
      if($rc == -1){
         if($fileCount == 1){
            return -1;
         }
         last; # This means that there are no more files to get
      }elsif($rc == -2){
          return -1;
      }
      #copying the files to the local machine
      $service = "fs";
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
         $command="copy file $sourceDir/$sourceFileName tofile $destFileName";
      }
      elsif($OS == WINDOWS_OS){
         $command="copy file $sourceDir\\$sourceFileName tofile $destFileName";
      }
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      #removing the files from the target host
      $service = "process";
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
         $command="start shell command rm -f $sourceDir/$sourceFileName wait";
      }elsif($OS == WINDOWS_OS){
           $command="start shell command del /F $sourceDir\\$sourceFileName wait";
      }
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      $sourceFileName = $fileName1.$fileCount;
      $destFileName = $fileName2.$fileCount;
      $fileCount++;
   }
   return 0;
}

#
# Syntax:
# getPortGroup( esxhost, interface, vm_directory)
#
# Description:
# This function is used to get the port group from the remote ESX host
#
# Input Parameters:
# - The required parameter 'esxhost' is the esx host ip on which the VM resides
# - The required parameter 'interface' is the interface of the VM whose
#   port group is need
# - The required parameter 'vm_directory is where the VM folder resides
#
# Returns:
# (0,portgroup): 1st value indicates success, 2nd value is portgroup
# (-1,0): 1st value indicates failure, 2nd value is always 0, $errorString is set
sub getPortGroup
{
   my $esxHost;
   my $interface;
   my $path;
   my $OS;
   my $command;
   my $service;
   my $workDir;
   my $vmxFile;
   my $result;
   my $mc;
   my $entryMap;
   my @temp;
   my $portGroup;
   my @args;

   @args = @_;
   #checking for correct number of args
   if(scalar(@args) < 3){
      $errorString = "USAGE: getPortGroup( HOST, INTERFACE, VM_DIRECTORY)";
      return (-1,0);
   }
   $esxHost = $args[0];
   $interface = $args[1];
   $workDir = $args[2];

   #checking if STAF is running on host
   if(checkSTAF($esxHost) < 0){
      return (-1,0);
   }

   #Getting the OS type for host
   $OS=getOS($esxHost);
   if($OS != 0||$OS < 0){
      return (-1,0);
   }
   #finding the vmx file in the VM folder
   $command="start shell command find . -name \"*.vmx\" workdir $workDir
   wait returnstdout";
   $service="process";
   $result=$handle->submit($esxHost,$service,$command);
   if(processError($result) < 0){
      return (-1,0);
   }
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})==0){
      $errorString = ".vmx file not present in the specified folder";
      return (-1,0);
   }
   @temp=split(/.\//,$entryMap->{fileList}[0]{data});
   $vmxFile=$temp[1];

   ##find the line in the vmx file which specified which port
   #group the vm is connected to
   $command="start shell command grep \"$interface.networkName\" $vmxFile
   workdir $workDir wait stderrtostdout returnstdout";
   $service="process";
   $result=$handle->submit($esxHost,$service,$command);
   if(processError($result) < 0){
      return (-1,0);
   }
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})==0){
      $errorString="No such interface";
      return (-1,0);
   }
   #extracting the port group
   @temp=split(/ethernet0.networkName = /,$entryMap->{fileList}[0]{data});
   @temp=split(/"/,$temp[1]);
   $portGroup=$temp[1];
   return (0,$portGroup);

}

#
# Syntax:
# vswitch( portgroup, host)
#
# Description:
# This function is used to set the given portgroup in promiscuous mode
#
# Input Parameters:
# - The required parameter 'esxhost' is the esx host ip on which the VM resides
# - The required parameter 'portgroup' is the portgroup name
#
# Returns:
# Port group: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub vswitch($$)
{
   my $portGroup=shift;
   my $host=shift;
   my $command;
   my $service;
   my $result;
   my $mc;
   my $entryMap;

   my $np = new VDNetLib::Common::GlobalConfig;
   my $testcodepath = $np->TestCasePath(0);
   my $script_to_promiscuous = $testcodepath . 'pktCaptureVswitch.sh';

   #running the script
   $command = "start shell command \" $script_to_promiscuous $portGroup \" wait returnstdout";
   $service="process";
   $result=$handle->submit($host,$service,$command);
   if(processError($result) < 0){
      return -1;
   }
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})!=0){
      if($entryMap->{fileList}[0]{data} =~ /absent/i){
         $errorString = "Invalid portgroup $portGroup";
         return -1;
      }
   }

}

#
# Syntax:
# runFilter( handle, filterstring, destFileName=>, sourceHost=>, sourceFileName=>, sourceDir=>)
#
# Description:
# This function is used to run filters over captured pcap files
#
# Input Parameters:
# - The required argument 'handle' is the handle returned by startCapture in
#   the same script. Id '0' then source_host, source_filename and source_dir need
#   to be specified
# - The required argument 'filterstring' is the filter you want to run over
#   the captured files
# - The required argument 'dest_filename' is the filename as which you want to
#   store the files.
# - The optional argument 'source_host' is the target machine. It is ignored if
#   handle is given. It is required if handle is 0
# - The optional argument 'source_filename' is the file you want. It is ignored if
#   handle is given. It is required if handle is 0
# - The optional argument 'source_dir' is the directory where the files are.
#   It is ignored if handle is given. If not given if handle =0 then the default
#   directory is C:\ for Windows and /tmp for Linux and Solaris
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub runFilter($$;%)
{
   my $index;
   my $host;
   my $sourceFileName;
   my $destFileName;
   my $filterString;
   my $command;
   my $result;
   my $OS;
   my $service;
   my $fileCount=1;
   my $sourceDir;
   my $fileName1;
   my $fileName2;
   my $mc;
   my $entryMap;
   my $rc;
   my @args;
   my @rv;
   my $i;
   my $flag=0;
   my %options;
   my @description;
   my $size;

   ($index, $filterString, %options) = @_;
   #checking for correct number of args
   $destFileName = defined($options{destFileName}) ? $options{destFileName} : "Pcap";

   if(($index eq "0") && ! defined($options{sourceHost})){
      $errorString = "USAGE: runFilter( HANDLE, FILTER_STRING, DEST_FILENAME, SOURCE_HOST? , SOURCE_FILENAME?, SOURCE_DIR?); \n
                      if HANDLE = 0 SOURCE_HOST and SOURCE_FILENAME should be given";
      return -1;
   }
   #If handle is 0 then getting the other args
   $host = $options{sourceHost};
   $OS=getOS($host);
      if($OS < 0){
         return (-1,0);
      }

      #In linux, all the files are stored in /tmp and in Windows in C:\
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
          $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "/tmp";
      }elsif($OS == WINDOWS_OS){
          $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "C:\\tmp";
      }

   if($index eq "0"){
      $host = $options{sourceHost};
     $sourceFileName = defined($options{sourceFileName}) ? $options{sourceFileName} : "Pcap";
      if(defined($options{sourceDir})){
         if(($options{sourceDir} =~ /(.*)(\/)+$/) || ($options{sourceDir} =~ /(.*)(\\)+$/)){
            $sourceDir = $1;
         }else{
            $sourceDir = $options{sourceDir};
         }
      }
   #if not then extract from the hash table
   }else{
      if(!(exists $dataStructure{$index})){
         $errorString = "Handle does not exist";
         return -1;
      }
      $host=$dataStructure{$index}->{'host'};
      $OS=$dataStructure{$index}->{'OS'};
      $sourceFileName=$dataStructure{$index}->{'fileName'};
   }

   $fileName1 = $sourceFileName;
   $fileName2 = $destFileName;

   #checking if STAF is running on host
   if(checkSTAF($host)==-1){
      return -1;
   }
   #Checking if tcpdump is installed on the host
   if(checkTcpdump($host,$OS)==-1){
      return -1;
   }

   #setting default paths for linux/solaris/windows
   if(($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS) && !(defined($sourceDir))){
      $sourceDir = "/tmp";
   }
   if($OS == WINDOWS_OS && !(defined($sourceDir))){
      $sourceDir = "C:\\tmp";
   }
   while(1)
   {
      #checking if that file exists on the host
      $rc = checkFile($host,$OS,$sourceFileName,$sourceDir);
      if($rc == -1){
         if($fileCount == 1){
            return -1;
         }
         last;
      }elsif($rc == -2){
          return -1;
      }
      # checking if the source pcap file is a null file.
      $rc = checkFileSize($host,$OS,$sourceFileName,$sourceDir);
      if($rc == 0) {
          $vdLogger->Warn("pcap file is empty");
          return -1;
      } elsif ($rc == -1){
          $vdLogger->Error(" File $sourceFileName not found & file count is $fileCount");
          return -1;
      }
      #applying the filter to the files
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
         $command = "start shell command tcpdump parms -e -vv -s0 -r $sourceDir/$sourceFileName -w $sourceDir/$destFileName $filterString wait returnstderr";
      }elsif ($OS==WINDOWS_OS){
         $command ="start shell command $windump parms -e -vv -s0 -r $sourceDir\\$sourceFileName -w $sourceDir\\$destFileName $filterString wait returnstderr";
      }
      $service="process";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      $mc =STAF::STAFUnmarshall($result->{result});
      $entryMap=$mc->getRootObject();
      if(length($entryMap->{fileList}[0]{data})!=0){
      #formatting the errorString
         @rv = split(/\n/,$entryMap->{fileList}[0]{data});
         for($i=0;$i<scalar(@rv);$i++){
            if(!($rv[$i] =~ /truncated/i || $rv[$i] =~ /reading/i)){
               if($flag==0){
                  $errorString = $rv[$i];
               }else{
                  $errorString = $errorString.$rv[$i];
               }
               $flag=1;
            }
            $errorString = $errorString."\n";
         }
         if($flag==1){
            chomp($errorString);
            return -1;
         }
      }
      #move to the next file
      $sourceFileName=$fileName1.$fileCount;
      $destFileName = $fileName2.$fileCount;
      $fileCount++;
   }
   return 0;
}
#
# Syntax:
# runTest( handle, test_name, sourceHost=>?, sourceFileName=>?, sourceDir=>?)
#
# Description:
# This function is used to run filters over captured pcap files
#
# Input Parameters:
# - The required argument 'handle' is the handle returned by startCapture in
#   the same script. Id '0' then source_host, source_filename and source_dir need
#   to be specified
# - The required argument 'test_name' is the test you want to perform on the
#   captured packets
# - The optional argument 'sourceHost' is the target machine. It is ignored if
#   handle is given. It is required if handle is 0
# - The optional argument 'sourceFileName' is the file you want. It is ignored if
#   handle is given. It is required if handle is 0
# - The optional argument 'sourceDir' is the directory where the files are.
#   It is ignored if handle is given. If not given if handle =0 then the default
#   directory is C:\ for Windows and /tmp for Linux and Solaris
#
# Returns:
# (0,Result):1st value indicates success, 2nd value is the output of the test
# (0,0): 1st value indicates success, 2nd value means no packets were found in the dump
# (-1,0): 1st indicates failure,2nd value is always 0, $errorString is set to cause
#
sub runTest($$;%)
{
   my $host;
   my $service;
   my $command;
   my $result;
   my @args;
   my $OS;
   my $sourceFileName;
   my $sourceDir;
   my $rc;
   my $mc;
   my $entryMap;
   my $fileCount = 1;
   my $fileName;
   my $rv;

   my($index,$testName,%options) = @_;
   $vdLogger->Debug("runTest: $index $testName ");
   $vdLogger->Debug(Dumper(\%options));
   if ($index eq "0") {
	if (! defined($options{sourceHost}) ) {
	    $errorString = "USAGE: if HANDLE = 0 SOURCE_HOST should be given";
        }
   }

   #If handle is 0 then getting the other args
   $host = $options{sourceHost};
   $OS=getOS($host);
      if($OS < 0){
         return (-1,0);
      }

      #In linux, all the files are stored in /tmp and in Windows in C:\
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
          $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "/tmp";
      }elsif($OS == WINDOWS_OS){
          $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "C:\\tmp";
      }

   if($index eq "0"){
      $host = $options{sourceHost};
     $sourceFileName = defined($options{sourceFileName}) ? $options{sourceFileName} : "Pcap";
      if(defined($options{sourceDir})){
         if(($options{sourceDir} =~ /(.*)(\/)+$/) || ($options{sourceDir} =~ /(.*)(\\)+$/)){
            $sourceDir = $1;
         }else{
            $sourceDir = $options{sourceDir};
         }
      }
   #if not then extract from the hash table
   }else{
      if(!(exists $dataStructure{$index})){
         $errorString = "Handle does not exist";
         return (-1,0);
      }
      $host=$dataStructure{$index}->{'host'};
      $OS=$dataStructure{$index}->{'OS'};
      $sourceFileName=$dataStructure{$index}->{'fileName'};
   }

   #checking if STAF is running on host
   if(checkSTAF($host)==-1){
      return (-1,0);
   }
   #Checking if tcpdump is installed on the host
   if(checkTcpdump($host,$OS)==-1){
      return (-1,0);
   }
   #checking if Perl is installed on host
   if(checkPerl($host,$OS) < 0){
      return (-1,0);
   }
   #setting default directories for linux/windows/solaris
   if(($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS) && !(defined($sourceDir))){
      $sourceDir = "/tmp";
   }
   if($OS==WINDOWS_OS && !(defined($sourceDir))){
      $sourceDir = "C:\\tmp";
   }
   $fileName = $sourceFileName;
   while(1)
   {
      #checking if the files are present on the host
      $rc = checkFile($host,$OS,$sourceFileName,$sourceDir);
      if($rc == -1){
         if($fileCount == 1){
         return (-1,0);
         }
         last; #This means that there are no more files to be coverted
      }elsif($rc == -2){
         return (-1,0);
      }
      #convert to human readable format to enable parsing
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
         $command = "start shell command tcpdump parms -e -vv -s0 -r $sourceDir/$sourceFileName > $sourceDir/$sourceFileName.tmp wait returnstderr returnstdout";
      }elsif ($OS==WINDOWS_OS){
         $command ="start shell command $windump parms -e -vv -s0 -r $sourceDir\\$sourceFileName > $sourceDir\\$sourceFileName.tmp wait returnstderr returnstdout";
      }
      $service="process";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return (-1,0);
      }
      $sourceFileName=$fileName . $fileCount;
      $fileCount++;
   }

   $fileCount--;
   my $np = new VDNetLib::Common::GlobalConfig;
   my $testcodepath = $np->TestCasePath($OS);
   my $Path = "$testcodepath" . 'pktCaptureMacros.pl';

   #running the script on the host
   if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
   $command = "start shell command perl $Path $sourceDir/$fileName
               $fileCount $testName wait returnstdout";
   }elsif($OS == WINDOWS_OS){
   $command = "start shell command perl $Path $sourceDir\\$fileName
               $fileCount $testName wait returnstdout";
   }
   $service="process";
   $result=$handle->submit($host,$service,$command);
   if(processError($result) < 0){
      return (-1,0);
   }
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})!=0){
      $rv = $entryMap->{fileList}[0]{data};
   }else{
      $rv = 0;
   }
   no strict;
   my $macro_hash = eval $rv;
   #$vdLogger->Debug(Dumper($macro_hash);
   if ($@) {
      $vdLogger->Error($@);
      return (-1,0);
   }

   #cleaning up all the temporary files created
   $fileCount=1;
   $sourceFileName = $fileName;
   my $cleanup = defined ($options{cleanup}) ? $options{cleanup} : '1';
   if($cleanup){
      while(1)
      {
          $rc = checkFile($host,$OS,$sourceFileName,$sourceDir);
          if($rc == -1){
             if($fileCount == 1){
                return (-1,0);
             }
             last;
          }elsif($rc == -2){
             return (-1,0);
          }
          if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
             $command = "start shell command rm -f $sourceDir/$sourceFileName.tmp wait returnstderr";
          }elsif ($OS==WINDOWS_OS){
             $command ="start shell command del /F $sourceDir\\$sourceFileName.tmp wait returnstderr";
          }

          $service="process";
          $result=$handle->submit($host,$service,$command);
          if(processError($result) < 0){
             return (-1,0);
          }
          if(processStderr($result) < 0){
             return (-1,0);
          }
          $sourceFileName=$fileName.$fileCount;
          $fileCount++;
       }
   }
   return (0,$macro_hash);
}

sub cleanupCapture($;%) {

  my ($index, %options) = @_;
  my ($sourceFileName, $sourceDir, $sourceHost );
  my ($host, $OS, $service, $result, $command, $rc );
  my $fileCount=1;
  if ($index eq "0") {
      if (! defined($options{sourceHost})) {
	  $errorString = "USAGE: if HANDLE = 0 sourceHost  should be given";
      }
  } else {
      $sourceFileName=$dataStructure{$index}->{'fileName'};
      $sourceHost=$dataStructure{$index}->{'host'};
      $sourceDir=$dataStructure{$index}->{'sourceDir'};
  }
  #Getting the other args
  $host = $options{sourceHost};
  $OS=getOS($host);
  if($OS < 0){
      return (-1,0);
  }
  $sourceFileName = defined($options{sourceFileName}) ? $options{sourceFileName} : "Pcap";
  if($OS == WINDOWS_OS) {
      $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "C:\\tmp";
  }else {
      $sourceDir = defined($options{sourceDir}) ? $options{sourceDir}: "/tmp";
  }
  my $fileToDelete = $sourceFileName;
  while(1)
  {
      $rc = checkFile($host,$OS,$fileToDelete,$sourceDir);
      if($rc < 0){
	  $vdLogger->Debug("All $sourceFileName<1..n> Files are cleaned");
	  last;
      }
      if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
	  $command = "start shell command rm -f $sourceDir/$fileToDelete wait returnstderr";
      }elsif ($OS==WINDOWS_OS){
	  $command ="start shell command del /F $sourceDir\\$fileToDelete wait returnstderr";
      }
      $service="process";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
	  return (-1,0);
      }
      if(processStderr($result) < 0){
	  return (-1,0);
      }
      $fileToDelete=$sourceFileName.$fileCount;
      $fileCount++;
  }
  return 0;

}


# Syntax:
# processError( result)
#
# Description:
# This helper function is used to check for standard error
#
# Input Parameters:
# - The required argument 'result' is the result returned by the submit command
#
#
# Returns:
# 0: On Success
# -1: On Failure, $errorString is set to indicate cause of failure
#
sub processError($)
{
   my $result = shift;
   my $mc;
   my $entryMap;
   if(($result->{rc})!=$STAF::kOk){
      if(length($result->{result})!=0){
         $errorString=$result->{result};
         $vdLogger->Error("Error encountered: $errorString");
         return -1;
      }
      $errorString = "STAF generated $result->{rc} error";
      $vdLogger->Error("Error encountered: $errorString");
      return -1;
   }
   return 0;
}
# Syntax:
# processStdErr( unmarshalledresult)
#
# Description:
# This helper function is used to check for standard error returned by process
#
# Input Parameters:
# - The required argument 'unmarshalledresult' is the unmarshalled result
#   which is processed to extract the any return error
#
# Returns:
# 0: On Success
# -1: On Failure, $errorString is set to indicate cause of failure
#
sub processStderr($)
{
   my $mc;
   my $entryMap;
   my $result=shift;
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})!=0){
   #error occurred
      $errorString = $entryMap->{fileList}[0]{data};
      return -1;
   }
   return 0;
}
# Syntax:
# checkFile( host, OS, filename, dir)
#
# Description:
# This helper function is used to check if a file fo the same name exists
#
# Input Parameters:
# - The required argument 'host' is the target machine
# - The required argument 'OS' is the OS of the target machine
# - The required argument filename is name of the file
# - The required argument dir is directory in which the check is to be done
#
# Returns:
# 0: On Success
# -1: On Failure, $errorString is set to indicate cause of failure
#
sub checkFile($$$$)
{
   my $service;
   my $host;
   my $command;
   my $OS;
   my $sourceFileName;
   my $sourceDir;
   my $mc;
   my $entryMap;
   my $result;

   $host = $_[0];
   $OS = $_[1];
   $sourceFileName = $_[2];
   $sourceDir = $_[3];
   $vdLogger->Debug("checkFile: $host $OS $sourceFileName $sourceDir ");
   #find the file name
   $service="process";
   if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
      $command="start shell command ls $sourceDir/$sourceFileName wait returnstdout";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      $mc =STAF::STAFUnmarshall($result->{result});
      $entryMap=$mc->getRootObject();
      if ($entryMap->{fileList}[0]{data} !~ /$sourceFileName/) {
         $errorString = "$sourceFileName File at $sourceDir File not present on $host";
         return -1;
      }
   }elsif($OS == WINDOWS_OS){
      $command="start shell command dir $sourceFileName /s workdir $sourceDir\\ wait returnstdout";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
      	$vdLogger->Error("ERROR");
         return -1;
      }
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})!=0 && (!($entryMap->{fileList}[0]{data} =~ /directory of/i))){
      $errorString = "$sourceFileName File at $sourceDir not present on $host";
      return -1;
   }
   }
   return 0;
}

#
# Syntax:
# checkPerl(host );
#
# Description:
# This helper function is used to check if the host has perl installed and is
# present in the PATH environment variable
#
# Input Parameters:
# - The required parameter 'host' is the target machine
# - The required parameter 'OS' is the OS of the target machine
#
# Returns:
# 0: Success
# -1: On failure, $errorString is set to indicate the cause of failure
#
sub checkPerl($$)
{
   my $service;
   my $command;
   my $result;
   my $mc;
   my $entryMap;
   my $host=shift;
   my $OS=shift;


   $service = "process";
   $command = "start shell command \"perl -h\" wait returnstderr";
   $result = $handle->submit($host,$service,$command);
   if(processError($result) < 0){
      return -1;
   }else{

      $mc =STAF::STAFUnmarshall($result->{result});
      $entryMap=$mc->getRootObject();
      if(length($entryMap->{fileList}[0]{data})!=0){
         $errorString = "Perl not present on $host";
         return -1;
      }
   }
   return 0;
}

# Syntax:
# checkFileSize( host, OS, filename, dir)
#
# Description:
# This helper function is used to return the size of file
#
# Input Parameters:
# - The required argument 'host' is the target machine
# - The required argument 'OS' is the OS of the target machine
# - The required argument filename is name of the file
# - The required argument dir is directory in which the check is to be done
#
# Returns:
# 0: On Success
# -1: On Failure, $errorString is set to indicate cause of failure
#
sub checkFileSize($$$$)
{
   my $service;
   my $host;
   my $command;
   my $OS;
   my $sourceFileName;
   my $sourceDir;
   my $mc;
   my $entryMap;
   my $result;
   my @num;

   $host = $_[0];
   $OS = $_[1];
   $sourceFileName = $_[2];
   $sourceDir = $_[3];
   $vdLogger->Debug("checkFileSize: $host $OS $sourceFileName $sourceDir ");
   $service="process";
   if($OS == LINUX_OS || $OS == VMKERNEL_OS || $OS == SOLARIS_OS){
      $command="start shell command stat -c %s $sourceDir/$sourceFileName wait returnstdout";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
         return -1;
      }
      $mc =STAF::STAFUnmarshall($result->{result});
      $entryMap=$mc->getRootObject();
      $result=$entryMap->{fileList}[0]{data};
   }elsif($OS == WINDOWS_OS){
      $command="start shell command dir $sourceFileName /s workdir $sourceDir\\ wait returnstdout";
      $result=$handle->submit($host,$service,$command);
      if(processError($result) < 0){
        $vdLogger->Error("ERROR ");
         return -1;
      }
   $mc =STAF::STAFUnmarshall($result->{result});
   $entryMap=$mc->getRootObject();
   if(length($entryMap->{fileList}[0]{data})!=0 && (!($entryMap->{fileList}[0]{data} =~ /directory of/i))){
      $errorString = "$sourceFileName File at $sourceDir not present on $host";
      return -1;
   }
   if(($entryMap->{fileList}[0]{data} =~ /1 File/i) && ($entryMap->{fileList}[0]{data} =~ /\s*(\S+) bytes/i)){
   $result=$1;
   # Remove if any "," Char in the file size
   if($result=~/\,/) {
   @num = split(",", $result);
   $result = join("", @num);
   }
   }
   }
   return $result;
}


# Syntax:
# ESXUWPacketCapture( captureType, function, vxlanId, numOfPackets,
#                     pattern, hostObj)
#
# Description:
# This function is used to get pktcap-uw output with given pattern
#
# Input Parameters:
# - The required argument 'captureType' is the pktcap-uw support type
# - The required argument 'function' is the is the pktcap-uw support function
# - The required argument 'vxlanId' is the vxlan id
# - The required argument 'numOfPackets' is capture packet number
# - The required argument 'pattern' is filter pattern
# - The required argument 'hostObj' is the target host object
#
# Returns:
# Return pktcap-uw output
# FAILURE: On Failure, get pktcap-uw output error
#

sub ESXUWPacketCapture($$$$$$)
{
   my $captureType = shift;
   my $function   = shift;
   my $vxlanId = shift;
   my $numOfPackets = shift;
   my $pattern = shift;
   my $hostObj = shift;

   my $command = "pktcap-uw --capture $captureType -f $function " .
                 "--vxlan $vxlanId  -c $numOfPackets | grep $pattern";
   my $hostIP = $hostObj->{hostIP};
   my $result = $hostObj->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
       $vdLogger->Error("Failed to run command:$command" .
                         " on host:$hostIP".
                         Dumper($result));
       VDSetLastError("ESTAF");
       return "FAILURE";
   }
   return $result->{stdout};
}

1;
