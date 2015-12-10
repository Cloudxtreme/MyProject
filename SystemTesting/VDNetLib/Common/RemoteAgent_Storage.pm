##########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
##########################################################################
package VDNetLib::Common::RemoteAgent_Storage;
##########################################################################
=head1 NAME

VDNetLib::Common::RemoteAgent_Storage - Is the generic Module to execute  a routine on another machine.

=head1 DESCRIPTION

Any function that needs to be executed remotely can use this package,
For EX: VMOperations package needs to be launched on workstation machine ( which
becomes a remote machine), so in the VMOperations package when the remoteIp is specified,
it branches and does  the below code to launch the VDNetLib::Common::RemoteAgent_Storage's methods..

package VMOperations;
sub new {
     my ($self, %options) = @_;
     if ($options{remoteIp}) {
         delete($options{remoteIp});
         delete($options{osType});
         my @args = (remoteIp=>$remoteIp,osType=>1,pkgArgs=>[@thisPkgArgs,%options]);
         $self = VDNetLib::Common::RemoteAgent_Storage->new(@args);
         bless $self, VDNetLib::Common::RemoteAgent_Storage;
         return $self;
     }
}


After this point, any routine that you launch from the above package will be performed on the
remote machine...

For EX: When you do VMOpsPowerOn ..

It goes to the remote machine does the following steps.

my $obj = new VMOperations(@args)
$obj->VMOpsPowerOn(@args);

=head1 METHODS

=over

=cut

use FindBin;
#Use all common libraries to the search path,
use Data::Dumper;
use VDNetLib::Common::CommonConfig;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use strict;
use PLSTAF;
our $AUTOLOAD;

=item new

   my $remoteAgent  =  VDNetLib::Common::RemoteAgent_Storage->new(remoteIp=>'10.20.84.54');

Create and return a new remoteAgent object for the given IP, so any routines launched via this package will pick up AUTOLOAD,
which will launch  a remote process on the Ip with the given package and the routine called.

=cut

sub new {

   my ($proto, %args) = @_;
   my $class = ref($proto) || $proto;
   my $self;
   $self->{remoteIp} =  defined($args{remoteIp}) ? $args{remoteIp} : die("Provide remoteIp");

   $self->{osType} = defined($args{osType}) ? $args{osType} : _findOs(machine=>$self->{remoteIp});
   $self->{pkgArgs} = defined($args{pkgArgs}) ? $args{pkgArgs} : [];
   $self->{package} =defined($args{package})? $args{package} : caller();
   bless($self,$class);
   $vdLogger->Debug(Dumper($self));
   return $self;
}

=item _findOs

Internal routine to determine the kind os OS running on the remoteIP

=cut

sub _findOs {
   my (%options) = @_;
   my $machine = defined($options{machine}) ? $options{machine}: "local";
   my $errorStr;
   my $handle = STAF::STAFHandle->new("VDNetLib::Common::RemoteAgent_Storage::findOs");
   my $ostype;
   if ($handle->{rc} != $STAF::kOk) {
      die("Error registering with STAF, RC: $handle->{rc}");
   }

   # Check connectivity with remote machine using STAF ping service
   my $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$machine, "ping", "ping");
   if ($result->{rc} != $STAF::kOk) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      $errorStr = "Error on STAF  ping $machine,Expected RC: 0,Received RC: ".
                  "$result->{rc}, Result: $result->{result}";
      die($errorStr);
   }

   my $request = "RESOLVE STRING {STAF/Config/OS/Name}";

   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$machine, "VAR", $request);
   if ($result->{rc} != $STAF::kOk) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      $errorStr = "Error on staf var resolving string $request";
      die($errorStr);
   }

   if ($result->{result} =~ /Win/i)  {
      $ostype = 2;
   } elsif ($result->{result} =~ /Linux|VMkernel/i) {
      $ostype = 1;
   } else {
      $errorStr = "Unsupported OS: OS is not linux  or Windows";
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      die($errorStr);
   }
   # Close the STAF handle created in this sub-routine
   $result = $handle->unRegister();

   return $ostype;
}

=item AUTOLOAD

This is the default routine that gets invoked for all the routines, which will
launch a new  process on remote machine with the routine to be invoked

=cut

sub AUTOLOAD {
   my $self = shift;
   my $fullFuncName = $AUTOLOAD;
   return if ($fullFuncName =~ /::DESTROY$/);
   my $result;
   my ($package,  $functionName) =  ($fullFuncName =~ /^(.*)::(.*)$/);
   my $handle = STAF::STAFHandle->new("VDNetLib::Common::RemoteAgent_Storage::$functionName");
   my $cc = new VDNetLib::Common::CommonConfig($self->{osType});
   my $scriptsPath = $cc->ScriptsPath();
   my $pkgArgs = _serializeArgs($self->{pkgArgs});
   my $argString = _serializeArgs(\@_);
   my $cmd = "perl " . "$scriptsPath" . "remoteAgent_Storage.pl ";
   my $cmdArgs = "-p $self->{package} -n \"$pkgArgs\" -f $functionName -a \"$argString\"";
   $cmd =~ s/{/^{/g;
   $cmdArgs =~ s/{/^{/g;

   # create parent shared variable name with timestamp appended
   my @timeStamp = localtime(time);
   my $sharedVarName = "$functionName-$timeStamp[2]-$timeStamp[1]-$timeStamp[0]";

   # Submit a PROCESS START request and wait for it to complete
   my $request = "START SHELL COMMAND " . STAF::WrapData($cmd) .
     " PARMS " . STAF::WrapData($cmdArgs) .
     " RETURNSTDOUT  STDERRTOSTDOUT WAIT ENV PARENT_SHARED_VAR=" .
     $sharedVarName . " ENV VDNET_LOGLEVEL=" . $ENV{VDNET_LOGLEVEL} .
     " ENV VDNET_LOGTOFILE=0" . " ENV VDNET_VERBOSE=1";

   # Executing command:$request
   $vdLogger->Debug("Sending STAF CMD to IP $self->{remoteIp}, $request");
   my $processResult = VDNetLib::Common::Utilities::STAFSubmit($handle,$self->{remoteIp}, "PROCESS", $request);
   if ($processResult->{rc} != $STAF::kOk) {
      $result = $handle->unRegister();
      $vdLogger->Error("Expected RC: 0, Received RC: $processResult->{rc}");
      $vdLogger->Debug("Result: $processResult->{result}");
      if ($result != $STAF::kOk) {
         $vdLogger->Warn("failed to unregister staf handle, RC:$result");
      }
       return (-1,"Remote Agent STAF ERROR: $request ");
   } else {
      my $mc = STAF::STAFUnmarshall($processResult->{result});
      my $root = $mc->getRootObject();
      my $procRC = $root->{rc};
      my $stdOut = $root->{fileList}[0]{data};
      my $stdErr = $root->{fileList}[1]{data};
      $vdLogger->Trace("Executing function $functionName on $self->{remoteIp}");
      $vdLogger->Trace($stdOut);
      if ( $procRC !=0 ) {
         $vdLogger->Error("STDOUT: $stdOut");
      }
      if ( $procRC!=0 ) {
         $vdLogger->Error("STDERR:  $stdErr");
      }
   }

   #Get the output of the module executed above. The remote module
   # will store the return value in the shared variable $sharedVarName
   # Read the return value using STAF's VAR service

   my $getSharedVarCmd = "get SHARED var $sharedVarName";
   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$self->{remoteIp}, "var", $getSharedVarCmd);
   no strict;
   if ($result->{rc} != $STAF::kOk) {
      #_deleteStafVar($sharedVarName,machine=>$self->{remoteIp});
      $result = $handle->unRegister();
      $vdLogger->Error("Received RC: " . $result->{rc} . "Result: " .
                       $result->{resultObj}->{fileList}[0]{data});
      if ($result != $STAF::kOk) {
         $vdLogger->Warn("failed to unregister staf handle, RC:$result");
      }
      $vdLogger->Error("Received RC: " . $result->{rc} . "Result: " .
                       $result->{resultObj}->{fileList}[0]{data});
      return (-1,
                 "Remote Agent Process Return ERROR: " .
                 "Could not get the output from the process ");
   }

   my $mc = STAF::STAFUnmarshall($STAF::Result);
   my $returnValue = $mc->getRootObject();   # gets the return value of the
                                             # remote method/sub-routine
   no strict;
   my $resultHash = eval($returnValue);
   #$vdLogger->Error(Dumper($resultHash);
   _deleteStafVar($sharedVarName,machine=>$self->{remoteIp});
   if ($resultHash->{'DIE'}) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      if ($result != $STAF::kOk) {
         $vdLogger->Warn("failed to unregister staf handle, RC:$result");
      }
      die($resultHash->{'DIE'});
   }
   # Close the STAF handle created in this sub-routine
   $result = $handle->unRegister();
   if ($result != $STAF::kOk) {
      $vdLogger->Warn("failed to unregister staf handle, RC:$result");
   }
   if (wantarray()) {
      return ($resultHash->{RC}, $resultHash->{RetRef});
   } else {
      return $resultHash->{RC};
   }
}

=item _deleteStafVar

Will delete the staf variable that got created for result reporting of the
subroutine that got invoked on the remote machine.

=cut


sub _deleteStafVar {
   my ($stafVar, %options) = @_;
   my $machine = defined($options{machine}) ? $options{machine}: "local";
   my $errorStr;
   my $result;
   my $handle = STAF::STAFHandle->new("VDNetLib::Common::RemoteAgent_Storage::DeleteSTAFVar");
   if ($handle->{rc} != $STAF::kOk) {
      $errorStr = "Error registering with STAF, RC: $handle->{rc} ";
      $vdLogger->Error($errorStr);
      $result = $handle->unRegister();
      return(-1);
   }

   # Check connectivity with remote machine using STAF ping service
   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$machine, "ping", "ping");
   if ($result->{rc} != $STAF::kOk) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      $errorStr = "Error on STAF  ping $machine,Expected RC: 0,Received RC: $result->{rc}, Result: $result->{result} ";
      $vdLogger->Error($errorStr);
      return (-1);
   }

   my $deleteStafVarCmd = "delete SHARED var $stafVar";

   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$machine, "var", $deleteStafVarCmd);
   if ($result->{rc} != $STAF::kOk) {
      $result = $handle->unRegister();
      $vdLogger->Error("Received RC: $result->{rc}, Result: $result->{result}");
      return -1;
   }
   # Close the STAF handle created in this sub-routine
   $result = $handle->unRegister();
   if ($result != $STAF::kOk) {
      $vdLogger->Warn("failed to unregister staf handle, RC:$result");
   }
   return 0;
}

=item _serializeArgs

Will format the args from DataDumper to remove newlines and be converted to a
string.

=cut

sub _serializeArgs {
   my ($thisArg) =@_;
   my $dumper = new Data::Dumper([$thisArg]);
   $dumper->Terse(1)->Indent(0);
   return $dumper->Dump();
}

1;
