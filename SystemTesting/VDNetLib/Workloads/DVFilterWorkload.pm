########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

###############################################################################
#
# package VDNetLib::Workloads::DVFilterWorkload;
#
# This package is used to expose all the DVFIlter/NETSEC related API's
#
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# DVFilter Operation Keys:-
# --------------------------
# HostSetUp     => "filtername",
# StartSlowpath => "filtername",
# StopSlowpath     => None,
#
###############################################################################

package VDNetLib::Workloads::DVFilterWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::Iterator;
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);

use VDNetLib::DVFilter::DVFilterSlowpath;
use VDNetLib::DVFilter::DVFilter;


########################################################################
#
# new --
#      Method which returns an object of VDNetLib::DVFilterWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::DVFilterWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $self;
   $self->{slowpathvm}=undef;
   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return undef;
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'    => "testdvfilter",
      'componentIndex' => undef
      };

   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}


########################################################################
#
# StartWorkload --
#      This method will process the workload hash of type 'DVFilter'
#      and execute necessary operations
#
# Input:
#      -- slowpath_vm name
#      -- operation name
#      -- filter name
#
# Results:
#     "PASS", if successful,
#     "FAIL", in case of any error;
#
# Side effects:
#     Depends on the network environment
#
########################################################################

sub StartWorkload
{
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};
   my $method;
   my $name;
   my $filter;
   my $operation;
   my $retResult;
   my $machine_obj;
   my @params;
   my $hostObj;
   my $vmObj;
   my $netadapterObj;
   my $stafHelper;
   my $testDvfilter;
   my $testAdapter;
   my $role;
   my $machine;
   my $result;

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;
   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);


    $stafHelper = $self->{testbed}->{stafHelper};
    if ($self->{testbed}{version} == 1) {
       ($machine,$role) = split(":",$dupWorkload->{'target'});
        $testDvfilter   = "$machine.vm.1";
    } else {
        $testDvfilter = $dupWorkload->{'testdvfilter'};
        $role        = $dupWorkload->{'role'};
    }

    my $reftestDvfilter = $self->{testbed}->GetComponentObject($testDvfilter);
    $vmObj           = $reftestDvfilter->[0];
    $hostObj         = $vmObj->{'hostObj'};


    if ($role =~ m/slowpath/i ) {
         my $slowpathType = $dupWorkload->{'slowpathtype'};
         my $testAdapter;
         my $refAdapter ;
         my @adapterArray;
         my $reftestAdapter ;

         if ($self->{testbed}{version} == 1) {
             my $allAdapters;
             $allAdapters = $self->{testbed}->GetAllSupportAdapters();
             #
             #Replace $machine:vnic:1 with $machine.vnic.1 to get tuple
             #format of array
             #
             map(s/\:/\./g,@$allAdapters);
             #
             #Get the helper vnics from the adapter object
             #
             @adapterArray = grep(m/$machine\.vnic\.\d+/, @$allAdapters);
             $testAdapter = \@adapterArray;
         } else {
             $testAdapter = $dupWorkload->{'testadapters'};
         }

         $reftestAdapter = $self->GetArrayOfObjects($testAdapter);
         if ($reftestAdapter eq "FAILURE") {
             $vdLogger->Error("Test adapter not found" .
                           Dumper($reftestAdapter));
             VDSetLastError(VDGetLastError());
             return "FAIL";
         }
         $machine_obj = VDNetLib::DVFilter::DVFilterSlowpath->new
                                           (slowpathobj    => $vmObj,
                                            slowpathvm     => $machine,
                                            netadapterobj  => $reftestAdapter,
                                            hostobj        => $hostObj,
                                            slowpathtype   => $slowpathType,
                                            stafhelper     => $stafHelper);
     } else {
        $machine_obj = VDNetLib::DVFilter::DVFilter->new
                                            (hostobj  => $hostObj,
                                             stafhelper => $stafHelper,
                                             vmobj      => $vmObj,
                                             targettype => $role);
     }


   # Number of Iterations to run the test for
   my $iterations = $dupWorkload->{'iterations'};

   if (not defined $iterations) {
      $iterations = 1;
   }

   my @mgmtKeys = ('target','type', 'iterations', 'testdvfilter');
   foreach my $key (@mgmtKeys) {
      delete $dupWorkload->{$key};
   }

   my $configCount = 1;
   my $iteratorObj;
   my %combo;
   my $comboHash;


    # Run for the given number of iterations
   $vdLogger->Info("Number of Iterations to run: $iterations");
   for (my $i=1; $i<=$iterations; $i++) {
      $vdLogger->Info("Running Iteration: $i");

   #
   # Create an VDNetLib::Common::Iterator object by passing the dupWorkload hash
   #
   $iteratorObj = VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload);

   #
   # NextCombination() method gives one set of keys from the list of available
   # combinations.
   #
   %combo = $iteratorObj->NextCombination();
   $comboHash = \%combo;
   $vdLogger->Info("Running DvfilterWorkload ");
   my $ret = "PASS";
   # Run the following until a valid combination is present
   while (%combo) {
      $vdLogger->Info("Working on configuration set $configCount");
      $result = $self->ProcessTestKeys($dupWorkload, $machine_obj);
      if (($result eq FAILURE) || ($result eq "FAIL")) {
           $vdLogger->Error("DvfilterWorkload failed execute the hash" .
                           Dumper($result));
           VDSetLastError(VDGetLastError());
           return "FAIL";
      }

      #
      # Consecutive NextCombination() calls iterates through the list of all
      # available combination of hashes
      #
      %combo = $iteratorObj->NextCombination();
      $configCount++;
  }
  }#end of iteration loop

   return "PASS";
}


########################################################################
#
# ProcessTestKeys --
#      This method will process the workload hash  of  DVfilter workload
#      and execute necessary operations.
#
# Input:
#      dupWorkload :Reference to test keys Hash
#      testObject  :Dvfilter Object
#
# Results:
#      "SUCCESS", if all the network configurations are successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#      none
#
#
########################################################################

sub ProcessTestKeys
{
   my $self        = shift;
   my $dupWorkload = shift;
   my $testObject  = shift;

   my $runworkload;
   if (defined $dupWorkload->{'runworkload'}) {
      $runworkload = $dupWorkload->{'runworkload'};
      delete $dupWorkload->{'runworkload'};
   }

   #
   # Create an iterator object and find all possible combination of workloads
   # to be run. The iterator module takes care ofidentifying these different
   # data types and generates combination if more than one VM Operation is
   # provided.
   #
   my $iteratorObj = VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload);

   my $configCount = 1;
   # NextCombination() method gives the first combination of keys
   my %testOps = $iteratorObj->NextCombination();
   my $testOpsHash = \%testOps;
   while (%testOps) {
      $vdLogger->Info("Working on configuration set $configCount :" .
                       Dumper($testOpsHash));
      my $result = $self->ConfigureComponent(configHash => $testOpsHash,
                                             testObject => $testObject);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
        return FAILURE;
      }

      if (defined $runworkload) {
         $vdLogger->Info("Processing runworkload hash for workload " .
                          "verification.");
         if ($self->RunChildWorkload($runworkload) eq FAILURE) {
            $vdLogger->Error("Failed to execute runworkload for verification: " .
                             Dumper($runworkload));
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      #
      # Consecutive NextCombination() calls iterates through the list of all
      # available combination of hashes
      #
      %testOps = $iteratorObj->NextCombination();
      $configCount++;
   }
   return SUCCESS;
}


########################################################################
#
# CleanUpWorkload --
#      This method will do all cleanup functions. This method has to be
#      implemented since it is mandatory to work with
#      VDNetLib::Workloads.
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     Depends on the command/script being executed
#
########################################################################

sub CleanUpWorkload
{
   return "SUCCESS";
}

###############################################################################
#
# ConfigureComponent --
#      This method executes DVfilter operations on the given Target Machine
#      (example: hostsetup,Startslowpath,CloseSlowpath..etc).
#
# Input:
#      dvfilterObj : DVfilter Object of the SUT/helper VM
#      dvfilterOpsHash/Config : A part of workload hash with dvfilter
#                               "operation" keys which is returned by Iterator
#                               after processing differernt data types
#
#
# Results:
#      "SUCCESS", if all the network configurations are successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#     None
#
###############################################################################

sub ConfigureComponent
{
   my $self = shift;
   my %args = @_;
   my $dvfilterOpsHash = $args{configHash};
   my $dvfilterObj     = $args{testObject};
   my $testbed         = $self->{testbed};
   my $method = undef;
   my @params = ();
   my $operation = undef;
   my $slowpathip;
   my $result;

   # For ver2 we will call the ConfigureComponent from parent class first.
   $result = $self->SUPER::ConfigureComponent('configHash' => $dvfilterOpsHash,
                                              'testObject' => $dvfilterObj);

   if (defined $result) {
      if ($result eq "FAILURE") {
         return "FAILURE";
      } elsif ($result eq "SKIP") {
         return "SKIP";
      } elsif ($result eq "SUCCESS") {
         return "SUCCESS";
      }
   }

   my %supportedOperations =(
               'hostsetup'         => 1,
               'startslowpath'     => 1,
               'pushrules'         => 1,
               'setupslowpathbin'  => 1,
               'closeslowpath'     => 1,
               'clearrules'        => 1,
               'verificationtype'  => 1,
               'slowpathsetup'     => 1,
   );

   foreach $operation (keys %{$dvfilterOpsHash}) {

    if (not defined $supportedOperations{$operation}) {
         next;
      }
    if ($operation eq "hostsetup") {
       $method = "HostSetup";
       push(@params, $dvfilterOpsHash->{hostsetup});
     }
    if ($operation eq "setupslowpathbin") {
        $method = "SetupSlowpathBinaries";
        push(@params, $dvfilterOpsHash->{'setupslowpathbin'});
     }
    if ($operation eq "closeslowpath") {
        $method = "KillSlowpathAgent";
        push(@params, $dvfilterOpsHash->{'slowpathtype'});
     }
    if ($operation eq "verificationtype") {
        $method = "VerifyPuntPackets";
       # push(@params, $dvfilterOpsHash->{'slowpathtype'});
     }
    if ($operation eq "slowpathsetup") {
        $method = "CheckClassicSlowpathSetup";
     }
    if ($operation eq "startslowpath") {
        my $slowpathtype = $dvfilterOpsHash->{slowpathtype};
        if ($slowpathtype =~ m/VMCI/i) {
            $method = "StartVMCISlowpath";
          } else {
            $method = "StartSlowpath";
          }
         push(@params, $dvfilterOpsHash->{startslowpath},$slowpathtype);
      }
     if (($operation eq "pushrules")||($operation eq "clearrules")) {
         my $count;
         my $slowpathip;
         my $slowpathvm;
         my $testAdapter;
         my $adapterCount;
         my $reftestAdapter;

         #getting slowpathIp
         if ($self->{testbed}{version} == 1) {
           my @adapterArray;
           my $allAdapters;
           $slowpathvm = $dvfilterOpsHash->{'slowpathtarget'};
           $allAdapters = $self->{testbed}->GetAllSupportAdapters();
           map(s/\:/\./g,@$allAdapters);
           $adapterCount = scalar @$allAdapters;
           @adapterArray = grep(m/$slowpathvm\.vnic\.\d+/, @$allAdapters);
           $testAdapter = \@adapterArray;
         } else {
           $testAdapter = $dvfilterOpsHash->{'testadapters'};
         }

         $reftestAdapter = $self->GetArrayOfObjects($testAdapter);
         if ($reftestAdapter eq "FAILURE") {
             $vdLogger->Error("Test adapter not found" .
                           Dumper($reftestAdapter));
             VDSetLastError(VDGetLastError());
             return "FAIL";
         }
         my $netadapterObj;
         if ($dvfilterOpsHash->{'pushrules'} =~ m/VMCI/i) {
            $netadapterObj = $reftestAdapter->[0];
            $slowpathip = $netadapterObj->GetIPv4();
         } else {
            for ($count = 0,$count <= $adapterCount,$count++) {
               $netadapterObj = $reftestAdapter->[$count];
               my $drivername = $netadapterObj->{'driver'};

               if($drivername =~ m/e1000/i) {
                  $slowpathip = $netadapterObj->{'controlIP'};
               } #end of If loop
            }#end of For loop
         } #end of if loop

         if ($operation eq "pushrules") {
           $method = "PushRules";
           my %paramHash;
           %paramHash = ( pushruletarget   => $dvfilterOpsHash->{'pushrules'},
                           filter           => $dvfilterOpsHash->{'filter'},
                           slowpathip       => $slowpathip,
                          );
           push(@params, %paramHash);
         } else {
           $method = "ClearRules";
           push(@params, $dvfilterOpsHash->{'clearrules'},
                       $dvfilterOpsHash->{'filter'},
                       $slowpathip);
         }
       }#end of if loop for operation push and clear rules
    }#end of foreach loop

   # After figuring out the method name and parameters to execute a DVFilter
   # operation, call the appropriate method.
   #
   $result = "FAILURE";
   $result = $dvfilterObj->$method(@params);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to execute $operation");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


1;
