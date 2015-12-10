#!/usr/bin/perl

=head1 NAME

RemoteAgent - Is the generic Module to execute  a routine on another machine.

=head1 DESCRIPTION

Any function that needs to be executed remotely can use this package, 
For EX: VMOperations package needs to be launched on workstation machine ( which 
becomes a remote machine), so in the VMOperations package when the remoteIp is specified,
it branches and does  the below code to launch the RemoteAgent's methods..

package VMOperations;
 sub new {
     my ($self, %options) = @_;
     if ($options{remoteIp}) {
         delete($options{remoteIp});
         delete($options{osType});
         my @args = (remoteIp=>$remoteIp,osType=>1,pkgArgs=>[@thisPkgArgs,%options]);
         $self = RemoteAgent->new(@args);
         bless $self, RemoteAgent;
         return $self;
     }
}


After this point, any routine that you launch from the above package will be performed on the 
remote machine... 

For EX: When you do VMOpsPowerOn ..

It goes to the remote machine does the following steps.

my $obj = new VMOperations(@args)
$obj->VMOpsPowerOn(@args);

=cut

package RemoteAgent;

use FindBin;
#Use all common libraries to the search path, 
use Data::Dumper;
use CommonConfig;
use strict;
use PLSTAF;
our $AUTOLOAD;

use constant OS_LINUX	 =>	1;
use constant OS_WINDOWS	 =>	2;


sub new {
   
   my ($proto, %args) = @_;
   my $class = ref($proto) || $proto;
   my $self;
   $self->{remoteIp} =  defined($args{remoteIp}) ? $args{remoteIp} : die("Provide remoteIp");

   $self->{osType} = defined($args{osType}) ? $args{osType} : _FindOS(machine=>$self->{remoteIp});
   $self->{pkgArgs} = defined($args{pkgArgs}) ? $args{pkgArgs} : [];
   $self->{package} =defined($args{package})? $args{package} : caller();
   bless($self,$class);
    print Dumper ($self);
   return $self;
}

sub _FindOS {
   my (%options) = @_;
   my $machine = defined($options{machine}) ? $options{machine}: "local";
   my $errorStr;
   my $handle = STAF::STAFHandle->new("RemoteAgent::FindOS");
   my $ostype;
   if ($handle->{rc} != $STAF::kOk) {
      die("Error registering with STAF, RC: $handle->{rc}");
   }

   # Check connectivity with remote machine using STAF ping service
   my $result = $handle->submit($machine, "ping", "ping");
   if ($result->{rc} != $STAF::kOk) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      $errorStr = "Error on STAF  ping $machine,Expected RC: 0,Received RC: $result->{rc}, Result: $result->{result}";   
      die($errorStr);
   }

   my $request = "RESOLVE STRING {STAF/Config/OS/Name}";

   $result = $handle->submit($machine, "VAR", $request);
   if ($result->{rc} != $STAF::kOk) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      $errorStr = "Error on staf var resolving string $request";
      die($errorStr);
   }

   if ($result->{result} =~ /Win/i)  {
      $ostype = 2;
   } elsif ($result->{result} =~ /Linux/i) {
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



sub AUTOLOAD {
   my $self = shift;
   my $fullFuncName = $AUTOLOAD;
   return if ($fullFuncName =~ /::DESTROY$/);
   my $result;
   my ($package,  $functionName) =  ($fullFuncName =~ /^(.*)::(.*)$/);
   my $handle = STAF::STAFHandle->new("RemoteAgent::$functionName");
   my $cc = new CommonConfig($self->{osType});
   my $binPath = $cc->BinPath();
#   my $testPath =  GetTestPath($self->{osType});
   my $pkgArgs = _SerializeArgs($self->{pkgArgs});
   my $argString = _SerializeArgs(\@_);
   my $cmd = "perl " . "$binPath" . "RemoteAgent.pl ";
   my $cmdArgs = "-p $self->{package} -n \"$pkgArgs\" -f $functionName -a \"$argString\"";
   $cmd =~ s/{/^{/g;
   $cmdArgs =~ s/{/^{/g;

   # create parent shared variable name with timestamp appended
   my @timeStamp = localtime(time);
   my $sharedVarName = "$functionName-$timeStamp[2]-$timeStamp[1]-$timeStamp[0]";
   
   # Submit a PROCESS START request and wait for it to complete
   my $request = "START SHELL COMMAND " . STAF::WrapData($cmd) .
     " PARMS " . STAF::WrapData($cmdArgs) . 
       " RETURNSTDOUT  STDERRTOSTDOUT WAIT ENV PARENT_SHARED_VAR=". $sharedVarName ;
   # Executing command:$request
   print ("Sending STAF CMD to IP $self->{remoteIp}, $request \n");
   my $processResult = $handle->submit($self->{remoteIp}, "PROCESS", $request);
   if ($processResult->{rc} != $STAF::kOk) {
#      _DeleteStafVar($sharedVarName,machine=>$self->{remoteIp});
      $result = $handle->unRegister();
      print "Error on STAF local PROCESS $request\n";
      print "Expected RC: 0\n";
      print "Received RC: $processResult->{rc}, Result: $processResult->{result}\n";
      if ($result != $STAF::kOk) {
         warn "failed to unregister staf handle, RC:$result\n";
      }
       return (-1,"Remote Agent STAF ERROR: $request ");
   } else {
      my $stdoutData = $processResult->{resultObj}->{fileList}[0]{data};
      my $stderr = $processResult->{resultObj}->{fileList}[1]{data};
      print "STDOUT: $stdoutData \n";
      print "STDERR:  $stderr \n";
   }
   
   #Get the output of the module executed above. The remote module
   # will store the return value in the shared variable $sharedVarName
   # Read the return value using STAF's VAR service

   my $getSharedVarCmd = "get SHARED var $sharedVarName";
   my $result = $handle->submit($self->{remoteIp}, "var", $getSharedVarCmd);
   no strict;
   if ($result->{rc} != $STAF::kOk) {
      #_DeleteStafVar($sharedVarName,machine=>$self->{remoteIp});
      $result = $handle->unRegister();
      print "Received RC: " . $result->{rc} . "Result: " .
        $result->{resultObj}->{fileList}[0]{data} . "\n";
      if ($result != $STAF::kOk) {
         warn "failed to unregister staf handle, RC:$result\n";
      }
      print "Received RC: " . $result->{rc} . "Result: " .
             $result->{resultObj}->{fileList}[0]{data} . "\n";
      return (-1, "Remote Agent Process Return ERROR: Could not get the output from the process ");
   }

   my $mc = STAF::STAFUnmarshall($STAF::Result);
   my $returnValue = $mc->getRootObject();   # gets the return value of the
                                             # remote method/sub-routine
   no strict;
   my $resultHash = eval($returnValue);
   #print Dumper($resultHash);
   _DeleteStafVar($sharedVarName,machine=>$remoteIP);
   if ($resultHash->{'DIE'}) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      if ($result != $STAF::kOk) {
         warn "failed to unregister staf handle, RC:$result\n";
      }
      die($resultHash->{'DIE'});
   }
   # Close the STAF handle created in this sub-routine
   $result = $handle->unRegister();
   if ($result != $STAF::kOk) {
      warn "failed to unregister staf handle, RC:$result\n";
   }
   return($returnHash{RC}, $returnHash{RetRef});
}




sub _DeleteStafVar {
   

   my ($stafVar, %options) = @_;
   my $machine = defined($options{machine}) ? $options{machine}: "local";
   my $errorStr;   
   my $result;
   my $handle = STAF::STAFHandle->new("RemoteAgent::DeleteSTAFVar");
   if ($handle->{rc} != $STAF::kOk) {
      $errorStr = "Error registering with STAF, RC: $handle->{rc} \n";
      print($errorStr);
      $result = $handle->unRegister();
      return(-1);
   }

   # Check connectivity with remote machine using STAF ping service
   $result = $handle->submit($machine, "ping", "ping");
   if ($result->{rc} != $STAF::kOk) {
      # Close the STAF handle created in this sub-routine
      $result = $handle->unRegister();
      $errorStr = "Error on STAF  ping $machine,Expected RC: 0,Received RC: $result->{rc}, Result: $result->{result} \n";   
      print($errorStr);
      return (-1);
   }
   
   my $deleteStafVarCmd = "delete SHARED var $stafVar";

   $result = $handle->submit($machine, "var", $deleteStafVarCmd);
   if ($result->{rc} != $STAF::kOk) {
      $result = $handle->unRegister();
      print "Received RC: $result->{rc}, Result: $result->{result}\n";
      return -1;
   }
   # Close the STAF handle created in this sub-routine
   $result = $handle->unRegister();
   if ($result != $STAF::kOk) {
      warn "failed to unregister staf handle, RC:$result\n";
   }
   return 0;
}



sub _SerializeArgs {
   my ($thisArg) =@_;
   my $dumper = new Data::Dumper([$thisArg]);
   $dumper->Terse(1)->Indent(0);
   return $dumper->Dump();
}

sub GetTestPath($)
{
   my $osType = shift;
   if ($osType == OS_LINUX) {
      return "/PAutomation/export/common/lib/";
   } elsif ($osType == OS_WINDOWS) {
      return "C:\\\\Perl\\\\site\\\\lib\\\\";
   } else {
      return "";
   }
}


1;
