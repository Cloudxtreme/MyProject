###############################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::DVFilter::DVFilter
#
#   This package allows to perform various operations on DVFilter/Netsec
#   through STAF command and retrieve status related to these operations.
#
###############################################################################

package VDNetLib::DVFilter::DVFilter;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::EsxUtils;
use VDNetLib::Host::HostOperations;
use VDNetLib::Common::SshHost;
use VDNetLib::DVFilter::DVFilterSlowpath;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;

use constant BLDMOUNTSSPATH => "/build/apps/bin/build_mounts.pl";
use constant MODPATH => "/usr/lib/vmware/vmkmod/";
use constant DVFILTERCTL => "generic_fastpath_ctl";
use constant DVFILTER_DIR => "/DVFilter";
use constant DVFILTERFASTPATH => "dvfilter-generic-fastpath";


###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::DVFilter::DVFilter).
#
# Input:
#      Testbed     - reference to testbed object
#      ProtectedVM - protected VM ip
#      Host        - host IP
#      Name        - HOST(ESX)/VM(ProtectedVM)
# Results:
#      An object of VDNetLib::DVFilter::DVFilter package.
#
# Side effects:
#      None
#
###############################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self;
   my $staf_input;
   my $testbed;
   my $type;
   my $result;
   $self->{targetType}= $args{targettype};
   if (!$args{hostobj} && $args{vmobj})  {
      $vdLogger->Error("Host/VM not provided");
      VDSetLastError("EINVALID");
      return undef;
   }

   $self->{stafHelper} = $args{stafhelper};
   if (not defined $self->{stafHelper}) {
      my $staf_input;
      $staf_input->{logObj} = $vdLogger;
      $self->{stafHelper} = VDNetLib::Common::STAFHelper->new($staf_input);
      if (!$self->{stafHelper}) {
         $vdLogger->Error("Failed to create STAF object");
         VDSetLastError("ESTAF");
         return undef;
       }
    }

   $self->{hostObj} = $args{hostobj};
   $self->{hostIP}  = $self->{hostObj}{hostIP};
   $self->{vmObj}   = $args{vmobj};
   $self->{vmIP}    = $self->{vmObj}{vmIP};
   # Set the vmtree for the host build
   $result = $self->{hostObj}->GetVMTree();
   if ($result eq "FAILURE") {
      $vdLogger->Error("Getting VM Tree failed");
      VDSetLastError(VDGetLastError());
      return(FAILURE);
   }
   $self->{vmtree}     =  $self->{hostObj}->{vmtree};
   $self->{buildType}  =  $self->{hostObj}->{buildType};
   $self->{DVFILTER_DIR}     =  "/DVFilter";
   bless ($self, $class);
   return $self;
}


########################################################################
#
# HostSetup --
#      This method copies the Dvfilet/NEtsec related binaries and file
#      to the sut host
#
# Input:
#      DVFilter type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     Depends on the command/script being executed
#
########################################################################

sub HostSetup
{
   my $self  = shift;
   my $filter = shift;
   my $host = $self->{hostIP};
   my $ret;

  $vdLogger->Info("Copy dvfilter-generic-fastpath to /usr/lib/vmware/vmkmod");
  $ret = $self->GetFastpath();
  if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to copy dvfilter-generic-fastpath");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
  $vdLogger->Info("Copy generic-fastpath-ctl to /bin");
   $ret = $self->GetFastpathCtl();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to copy dvfilter-generic-fastpath");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
  $vdLogger->Info("Create DVfilter Directory");
   $ret = $self->CreateDVFilterDir();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to create DVFilter Directory");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
  $vdLogger->Info("Copy files rule_parser.c,fw.c&fw.h to /DVFilter");
   $ret = $self->GetRulesProcessingFiles();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to Copy files rule_parser.c,fw.c&fw.h to /DVFilter");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
  $vdLogger->Info("Load module dvfilter-generic-fastpath");
   $ret = $self->LoadFastpathModule();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to load module dvfilter-generic-fastpath");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }


   return SUCCESS;
}


########################################################################
#
# GetFastpath --
#      Copy dvfilter-generic-fastpath to /usr/lib/vmware/vmkmod
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetFastpath
{
   my $self = shift;

   my $vmtree = $self->{vmtree};
   my $host = $self->{hostIP};
   my $cmd;
   my $result;
   $cmd ="cp $vmtree/build/scons/package/devel/".
                   "linux32/" . lc($self->{buildType}) . "/esx/vmkmod-vmkernel64/" .
                   DVFILTERFASTPATH . "/" .DVFILTERFASTPATH . MODPATH;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }


   return SUCCESS;
}


########################################################################
#
# GetFastpathCtl --
#      Copy generic-fastpath-ctl to /bin
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetFastpathCtl
{
   my $self = shift;

   my $vmtree = $self->{vmtree};
   my $host   = $self->{hostIP};
   my $cmd;
   my $result;

   $cmd ="cp $vmtree/build/scons/package/devel/".
                   "linux32/" . lc($self->{buildType}) . "/esx/apps/" . DVFILTERCTL . "/" .
                   DVFILTERCTL . " /bin ";

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

  $cmd ="chmod +x /bin/" . DVFILTERFASTPATH;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

  $cmd ="ln -s /bin/" . DVFILTERFASTPATH .
                   " /sbin/" . DVFILTERFASTPATH;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

   return SUCCESS;
}

########################################################################
#
# CreateDVFilterDir --
#      Create /DVFilter directory on the Host
#
# Input:
#      vmIP:  proctected vm's IP
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateDVFilterDir
{

   my $self = shift;
   my $vmIP = $self->{vmIP};
   my $host = $self->{hostIP};
   my $cmd;
   my $result;
   $cmd ="rm -rf "  . DVFILTER_DIR;

   $vdLogger->Info("Executing $cmd");
   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
    # Process the result
    if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

    $cmd = "mkdir -p " .  DVFILTER_DIR;

    $vdLogger->Info("Executing $cmd");
    $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
    # Process the result
    if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
     }

     # create DVFILTER Directory in protected VM
     $cmd = "rm -rf $self->{DVFILTER_DIR}; mkdir -p $self->{DVFILTER_DIR}";

     $vdLogger->Info("Executing $cmd");
     $result = $self->{stafHelper}->STAFSyncProcess($vmIP,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

   #remove any existing setup
   #command to delete vmknic if exist
   my $ret;
   my $command;
   $command = "esxcfg-vmknic --del SlowpathVMKPG";
   $ret = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create vswitch failed:" . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #command to delete vmknic if exist
   $command = "esxcfg-vswitch --delete DVFilterSwitch";
   $ret = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create vswitch failed:" . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}


########################################################################
#
# GetRulesProcessingFiles --
#      create directory /DVFilter and copy files rule_parser.c,fw.c&fw.h
#       to /DVFilter
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetRulesProcessingFiles
{
   my $self = shift;

   my $vmtree = $self->{vmtree};
   my $host   = $self->{hostIP};
   my $cmd;
   my $result;

   $cmd = "cp $vmtree/apps/lib/dvfilter/tests/rule_parser.c " . DVFILTER_DIR,;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

  $cmd ="cp $vmtree/apps/lib/dvfilter/tests/fw.c " . DVFILTER_DIR;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

    $cmd = "cp $vmtree/modules/vmkernel/dvfilter-generic-fastpath/public/fw.h  " .
                    DVFILTER_DIR;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

   return SUCCESS;
}


########################################################################
#
# LoadFastpathModule --
#    Unload and  Load module dvfilter-generic-fastpath
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub LoadFastpathModule
{
   my $self = shift;

   my $vmtree = $self->{vmtree};
   my $host = $self->{hostIP};
   my $cmd;
   my $result;

   $cmd = "vmkload_mod -u  " . DVFILTERFASTPATH;

      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }
   $cmd = "vmkload_mod " . MODPATH . DVFILTERFASTPATH;
      $vdLogger->Info("Executing $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }


   return SUCCESS;
}


#########################################################################
#
#  AddRules
#      ADD rules to the file rules.txt
#
#  Input:
#      rule     :rules that need to be added to the rules.txt,
#                 the rules has to be spilt at ";"
#      sourceIP :IP address of testvm/protected VM
#      sourceMAC:MAC address of test VM /proetcted VM
#      desIP    :AUX VM IP
#      desMAC   :AUX VM MAC
#
#  Results:
#      Returns "SUCCESS", if no errors
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub AddRules
{
   my $self = shift;
   my $args = shift;
   my $target = $self->{targetType};
   my $host = $self->{hostIP};
   my $vm   = $self->{vmIP};
   my $result;
   my @rules ;
   my $command;
   my @tempArray1;
   my @tempArray2;
   my $item;
   my $targetIP;

   if ((not defined $args->{adapter}) ||
       (not defined $args->{supportadapter}) ||
       (not defined $args->{addrules})) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("ENOTDEF");
       return FAILURE;
   }

   my $rule = $args->{addrules};
   my $sourceVnicObj   = $args->{adapter};
   my $desVnicObj      = $args->{supportadapter};

   my $sourceIP  = $sourceVnicObj->GetIPv4();
   my $sourceMAC = $sourceVnicObj->{"macAddress"};
   my $desIP   = $desVnicObj->GetIPv4();
   my $desMAC  = $desVnicObj->{'macAddress'};

   if ($target =~ m/host/i) {
       $targetIP = $host;
     } else {
       $targetIP = $vm;
   }
   $vdLogger->Info(" Will add rules $rule On $targetIP");

   my $count = 0;
   @rules = split(';',$rule);
   $self->{rulesCount} = @rules;
   foreach my $eachRule(@rules) {
      @tempArray1 = split(' ',$eachRule);
       foreach $item(@tempArray1) {
          if ($item =~ m/(IP_DA=)(support*)/i) {
               $item = $1 . $desIP;
             } elsif ($item =~ m/(IP_SA=)(test*)/i) {
               $item = $1 . $sourceIP;
            } elsif ($item =~ m/(ETH_DA=)(support*)/i) {
               $item = $1 . $desMAC;
            } elsif ($item =~ m/(ETH_SA=)(test*)/i) {
               $item = $1 . $sourceMAC;
              }
          }#end of foreach of temArray
           $tempArray2[$count] = join(' ' ,@tempArray1);
           $count++;
      }#end of outerforeach
   my  @line = join("\n", @tempArray2);

   $vdLogger->Info("ADD rules");

   #adding rules like
   #DPORT=1000 ACTION=PUNT
   #DPORT=4000 ACTION=LOG
   #to the the file /DVFILTER/rules.txt
   my $rulesFile = DVFILTER_DIR .  "/rules.txt" ;
   $command = "echo '@line'"  ;

   $vdLogger->Debug("Output file for Rules is " .
                   "$rulesFile");
   $vdLogger->Debug("Add rule command : $command");
   my $ret = $self->{stafHelper}->STAFAsyncProcess($targetIP,
                                                   $command,
                                                   $rulesFile);
  # if the mode is async, save the pid
   $self->{childHandle} = $ret->{handle};
   $ret = $self->{stafHelper}->GetProcessInfo($targetIP, $ret->{handle});
   if ($ret->{rc}) {
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($ret));
      return FAILURE;
   }

  $self->{pid} = $ret->{pid};

  $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($targetIP,$rulesFile);
   if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                       "of pushrule. File:$rulesFile".
                       " on $host");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ((defined $self->{stdout}) &&
            ($self->{stdout} eq " ")) {
      $vdLogger->Error("ADD  failed with stdout\n".
                       "stdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

    # Process the result
    if (($ret->{rc}) && ($ret->{exitCode})) {
         $vdLogger->Error("Failed to execute $command");
         VDSetLastError("ESTAF");
         $vdLogger->Debug("Error:" . Dumper($ret));
         $vdLogger->Error(Dumper($ret));
         return FAILURE;
      }

   return SUCCESS;
}


#########################################################################
#
#  PushRules
#      Push rule to the slowpath or SUTVM Dvport
#
#  Input:
#      pushruletarget :target like slowpath/dvport of sutvm
#      filter         :filtername that is used in protected VM
#      slowpathIP     :Ip of the control nic in slowpath(e1000)
#      sourceMAC      :Mac address of the protected vm
#      sourceIP       :IP address of the protected vm
#      desIP          :IP address of the auxillary VM
#      desMAC         :Mac address of the auxillary VM
#      rule           :Rules that need to be added to rules.txt
#
#  Results:
#      Returns "SUCCESS", if no errors
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub PushRules
{
  my $self = shift;
  my %args = @_;
  my $pushruleTarget = $args{pushruletarget};
  my $filter = $args{filter};
  my $slowpathIP = $args{slowpathip};
  my $host = $self->{hostIP};
  my $command;
  my $result;
  my $ret;

   if (not defined $pushruleTarget) {
       $vdLogger->Error("Target for push rule not defined");
        VDSetLastError("ENOTDEF");
         return FAILURE;
   }

   if (not defined $filter) {
       $vdLogger->Error("filter not defined");
        VDSetLastError("ENOTDEF");
         return FAILURE;
   }

  my $filterID = $self->GetFilterID($filter);
  #remove the instance number from the filterID for PR964116
  if ($filterID =~ /(.*\d)(\-\d)$/){
      $filterID = $1;
  }
  $vdLogger->Info("Push rules down to filter ID ".$filterID);
#  $vdLogger->Info("Push rules");
  $command = "/bin/generic_fastpath_ctl -N ". "'" . $filterID . "'"
                  . " -H " . $slowpathIP . " -R " ."/DVFilter/rules.txt";
  $self->{pushruleFile} = "/DVFilter/pushrulelog.log";
  print "the push rule command is :$command\n";
  $vdLogger->Debug("Output file for Rules is " .
                                        "$self->{pushruleFile}");

  $result = $self->{stafHelper}->STAFAsyncProcess($host,
                                                   $command,
                                                   $self->{pushruleFile});
   # if the mode is async, save the pid
   $self->{childHandle} = $result->{handle};
   my $timeout = 10;
        do {
            sleep(5);
            $timeout--;
            # If endTimeStamp is defined it means the process is already completed
            # if not then we wait for process to be completed.
            $ret = $self->{stafHelper}->GetProcessInfo($host, $self->{childHandle});
            if ($ret->{rc}) {
                if (not defined $ret->{endTimestamp}) {
                    $vdLogger->Error("endTimeStamp not defined and rc != 0 for ".
                                                "$self->{childHandle} on $host");
                    VDSetLastError("ESTAF");
                    return FAILURE;
                  }
              }
           } while($timeout > 0 && (not defined $ret->{endTimestamp}) != 0);

    if ($timeout == 0) {
        $vdLogger->Debug("Hit Timeout=$timeout min for ".
                            "$self->{childHandle} on $host. Still trying ".
                                                           "to read stdout");
     }

    $self->{pid} = $result->{pid};

   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($host,$self->{pushruleFile});
   if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                       "of pushrule. File:$self->{pushruleFile}:$self->{stdout}".
                       " on $host");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ((defined $self->{stdout}) &&
            ($self->{stdout} eq " ") && ($self->{stdout} ne  "refused")) {
      $vdLogger->Error("PushRule  failed with stdout\n".
                       "stdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $count = $self->VerifyRules($filter);
   $vdLogger->Info("The rules count in vsish node is :$count");
   if ($count == 0) {
       $vdLogger->Error("No rules are found in vsish node");
        return FAILURE;
     }

  return SUCCESS;
}


#########################################################################
#
#  GetFilterID
#      Get the filterID from the vsish node
#
#  Input:
#    filter:filtername passed to the protected VM
#
#  Results:
#      Returns  filterID
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub GetFilterID
{
   my $self =shift;
   my $filter=shift;
   my $host = $self->{hostIP};

   if (not defined $filter){
       $vdLogger->Error("Filter name not specified");
        VDSetLastError("ENOTDEF");
        return FAILURE;
     }

   my $command = "vsish -e ls  /vmkModules/dvfilter-generic-fastpath/agents/"
                                                    . $filter . "/filters/";
   $vdLogger->Info("Executing $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);

   if (($result->{rc}) &&($result->{exitCode})) {
       VDSetLastError("ESTAF");
       $vdLogger->Error("Execution of the Command : $command" .
                       " failed with error: Dumper{$result}");

       return FAILURE;
    } elsif ($result->{stderr} =~ /(invalid option|not found)/i) {
       $vdLogger->Error("Couldn't get the filterid from VSISH," .
                       " failed with error: Dumper($result)");
       return FAILURE;
    }
    if ($result->{stdout}=~ m/(.*$filter.*)\//) {
        $self->{filterID} = $1;
     } else {
       $vdLogger->Error("Not a valid filterID:$result->{stdout}");
       VDSetLastError("ESTAF");
       return FAILURE;
      }

   return $self->{filterID};
}


#########################################################################
#
#  ClearRules
#  Clear the rules in the slowpath/DVport of the the SUT/protectedVM
#
#  Input:
#     clearRuleTarget:slowpath/VM
#     filter : filtername of the SUT/Protected VM
#     slowpathIP:Ip of the control Nic(e1000) in slowpath
#
#  Results:
#      Returns "SUCCESS", if no errors
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub ClearRules
{
  my $self =shift;
  my $clearRuleTarget=shift;
  my $filter =shift;
  my $slowpathIP=shift;
  my $host = $self->{hostIP};
  my $command;
  my $result;

   if (not defined $clearRuleTarget) {
       $vdLogger->Error("Target for clear rule not defined");
        VDSetLastError("ENOTDEF");
        return FAILURE;
   }

   if (not defined $filter) {
       $vdLogger->Error("filter not defined");
        VDSetLastError("ENOTDEF");
        return FAILURE;
   }

   my $filterID=$self->GetFilterID($filter);
   #remove the instance number from the filterID for PR964116
  if ($filterID =~ /(.*\d)(\-\d)$/){
      $filterID = $1;
  }
   if ($clearRuleTarget =~ m/slowpath/i){
       $command = "/bin/generic_fastpath_ctl -N ". "'" . $filterID . "'"
                                        . " -H " . $slowpathIP . " -C ";
       $vdLogger->Info("Executing $command");
       $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                            $command);
        if ($result->{rc}) {
           VDSetLastError("ESTAF");
           return FAILURE;
        } elsif ($result->{stderr} =~ /(invalid option|not found)/i) {
               $vdLogger->Error("The rules could not be cleared on ESX," .
                       " failed with error: $result->{stderr}");
        }#end of if
    } else {
          $vdLogger->Error("code for clear rules to dvport"
                                 ." is not availabe");
          return FAILURE;
    }# end of if

    my $count = $self->VerifyRules($filter);
    if ($count != 0) {
       $vdLogger->Error("The rules are not cleared");
       return FAILURE;
    }

  return SUCCESS;

}


#########################################################################
#
#  VerifyRules
#  Verify the rules set by pushrules in the vsish node
#
#  Input:
#      filter    :filtername used in the SUT/proctected VM
#
#  Results:
#      Returns rules in array format
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub VerifyRules
{
   my $self = shift;
   my $filter = shift;
   my $host = $self->{hostIP};
   my $filterID = $self->GetFilterID($filter);
   my $command = "vsish -e ls  /vmkModules/dvfilter-generic-fastpath/agents/"
                       . $filter . "/filters/". "'" .$filterID ."'"."/rules/";
   $vdLogger->Info("Executing $command");
   my  $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc}) && ($result->{exit})) {
        $vdLogger->Error("Failed to execute command:Dumper($result)");
        VDSetLastError("ESTAF");
        return FAILURE;
    } elsif ($result->{stderr} =~ /(invalid option|not found)/i) {
            $vdLogger->Error("Couldn't get the filterid from VSISH," .
                       " failed with error: Dumper($result)");
        return FAILURE;
      }

   my @tempArray = split(/\n/,$result->{stdout});

   return @tempArray;
}

#########################################################################
#
#  GenerateRulesParserExec
#  Generate the .packetRuleset file required for pushing rules to DVPort
#
#  Input:
#      Proctected VM :vmIP
#
#  Results:
#      Returns "SUCCESS" in case of no error.
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub GenerateRulesParserExec
{
   my $self = shift;
   my $vmIP  = shift;
   my $hostIP   = $self->{hostIP};
   my $cmd;
   my $result;
   my $dstFile = "/DVFilter/";
   #
   # check if the rule_parser.c,  fw.c, and fw.h is available in the /DVFilter
   # directory on the esx host
   #
   $vdLogger->Debug("entered GenerateRulesParserExec");
   $cmd = "ls " . DVFILTER_DIR . "/rule_parser.c;ls  "
                  . DVFILTER_DIR ."/fw.c; ls " . DVFILTER_DIR . "/fw.h;";

   $vdLogger->Info("Executing $cmd");
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                  $cmd);
   # Process the result
   if (($result->{rc} ne 0) || ($result->{exitCode} ne 0)) {
      $vdLogger->Info("rule parser aren't there at " . DVFILTER_DIR
                      . " direcotry");
      $vdLogger->Info("Copy files rule_parser.c,fw.c&fw.h to /DVFilter");
      $result = $self->GetRulesProcessingFiles();
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to Copy files rule_parser.c,fw.c&fw.h to /DVFilter");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
    }
   #
   #copy the rule_parser code to the SUT VM and compile,
   #verify the binary is created
   #
   my $srcFile = DVFILTER_DIR . "/rule_parser.c";
   $result = $self->{stafHelper}->STAFFSCopyFile($srcFile,
                                                 $dstFile,
                                                 $hostIP,
                                                 $vmIP);
   # Process the result
   if ($result != 0) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   $srcFile = DVFILTER_DIR . "/fw.c";

   $result = $self->{stafHelper}->STAFFSCopyFile($srcFile,
                                                 $dstFile,
                                                 $hostIP,
                                                 $vmIP);
   # Process the result
   if ($result != 0) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   $srcFile = DVFILTER_DIR . "/fw.h";

   $result = $self->{stafHelper}->STAFFSCopyFile($srcFile,
                                                 $dstFile,
                                                 $hostIP,
                                                 $vmIP);
   # Process the result
   if ($result != 0) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   $cmd = "cd  /DVFilter; gcc \-o rule_parser rule_parser\.c fw\.c ; ";
   $vdLogger->Info("Executing $cmd");

   $result = $self->{stafHelper}->STAFSyncProcess($vmIP,
                                                  $cmd);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

  $cmd = "cd  /DVFilter;\./rule_parser rules.txt; ";
  $vdLogger->Info("Executing $cmd");

  $result = $self->{stafHelper}->STAFSyncProcess($vmIP,
                                                  $cmd);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   my $logDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $masterControlIP =  VDNetLib::Common::Utilities::GetLocalIP();
   # copy the .packedRuleset to MC
   $vdLogger->Info("Copying .packedRuleset file to MC Log directory");
   $srcFile = "/DVFilter/.packedRuleset";
   $dstFile = $logDir;

   $result = $self->{stafHelper}->STAFFSCopyFile($srcFile,
                                                 $dstFile,
                                                 $vmIP,
                                                 $masterControlIP);
   # Process the result
   if ($result != 0) {
      $vdLogger->Error("Failed to copy $srcFile to MC");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
 return SUCCESS;
}

#########################################################################
#
#  GetOpaqueData
#  Generate opaque data for the ruleset
#
#  Input:
#      None
#
#  Results:
#      Returns rules in byte array format
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub GetOpaqueData
{
   my $self = shift;
   my $hostIP = $self->{hostIP};
   my $result;
   my $cmd;
   my $opaqueData;

   my $logDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $masterControlIP =  VDNetLib::Common::Utilities::GetLocalIP();
   $cmd = "ls -al " . $logDir .".packetRuleset";
   $vdLogger->Info("Executing $cmd");

   $result = $self->{stafHelper}->STAFSyncProcess($masterControlIP,
                                                  $cmd);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   my $fileName = $logDir . ".packedRuleset";
   $result = open(INF, $fileName);
   if (not defined $result) {
       $vdLogger->Error("Unable to open the $fileName");
       return -1;
     }

   my $fileSize = -s $fileName;
   my $spec;

   read(INF, $spec, $fileSize);

   my @arr = unpack("c*", $spec);
   my $opaquedata =  \@arr;
   return $opaquedata;
}


#########################################################################
#
#
#  CheckClassicSlowpathSetup
#  Checking if the classic vmkernel network is intact after reboot
#
#  Input:
#      None
#
#  Results:
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub CheckClassicSlowpathSetup
{
   my $self = shift;
   my $host = $self->{hostIP};
   my $result;
   my $cmd;

   $cmd = "esxcfg-advcfg -g /Net/DVFilterBindIpAddress";

   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $cmd");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }
    #After reboot the IP address should be available
   if ( $result->{stdout} !~ /192.168.\d+.\d+/i){
         $vdLogger->Error("DVFilterBindIpAddress does not exist");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
     }
    return SUCCESS;
}


1;
