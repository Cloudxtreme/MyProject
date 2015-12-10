###############################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
###############################################################################
package VDNetLib::Verification::DataDiffVerification;

#
# This module gives object of DataDiff Verification. It deals with gathering
# API or command output  between 2 instances of time and
# checks for strings and patterns in the diff of the output.
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

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

my @operationalKeys = qw(data sleepbeforefinal);


###############################################################################
#
# new -
#       This method returns object of DataDiffVerification.
#
# Input:
#       none.
#
# Results:
#       Obj of DataDiffVerification module
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   return bless {}, $class;
}


###############################################################################
#
# InitVerification -
#       Initialize DataDiff Verification object.
#
# Input:
#       None
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
   my $targetNode = $self->{nodeid};
   my $usercommand = $self->{expectedchange}->{data};
   if (not defined $usercommand) {
      $vdLogger->Error("data key missing in DataDiff Verification hash");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Remove the key as it is not related to expectedchange, expectedchange
   # should only contain the output, values etc which user is expecting
   # from the command/API
   #
   foreach my $key (@operationalKeys) {
      if ((exists $self->{expectedchange}->{$key}) ||
          (exists $self->{expectedchange}->{lc($key)})) {
         $self->{$key} = $self->{expectedchange}->{$key} ||
                         $self->{expectedchange}->{lc($key)};
         delete $self->{expectedchange}->{$key};
         delete $self->{expectedchange}->{lc($key)};
      }
   }

   # To comply with parent's way of doing things.
   my $allCommands = $self->GetCommandHash();
   $self->{commandbucket}->{commands}->{$usercommand} = $allCommands->{$usercommand};

   return SUCCESS;

}


###############################################################################
#
# Start -
#       To get the initial and final output of command.
#       For better debugging we try to store everything relavant to a data type
#       in a single location. E.g. initial value, final value, diff, method,
#       params, preprecess, postprocess etc for 'getlacp' data type will be
#       in a single hash. Thus we store the data we get through API in the
#       same object along with state(initial or final)
#
# Input:
#       state - inital state or final state(optional)
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
   my $state = shift;
   my $ret;
   my ($objPtr, $method, $params, @value);


   if (not defined $state){
      $state = "initial";
   }
   #
   # For all commands, if the command type is supported by the target
   # then get the values of all the counters on that node.
   #
   my $commandList = $self->{commandbucket}->{commands};
   foreach my $commandType (keys %$commandList) {
      my $commandHash = $commandList->{$commandType};
      # Doing preprocesing first.
      if (defined $commandHash->{preprocess}) {
         my $preMethodArray = $commandHash->{preprocess};
         #
         # Preprocess should not return any value. If at all it wants
         # to send something it can put it in the $commandHash's param
         # and the actual method will be called with those params
         #
         foreach my $preMethod (@$preMethodArray) {
            my $preResult = $self->$preMethod($commandHash);
            if ($preResult eq FAILURE) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
      #
      # A command type stores the method and obj by which that command
      # can be obtained. E.g.
      # "lacp" => {
      #      'method'   => 'GetLACP',
      #      'obj'      => 'switchobj',
      #   },
      #
      if ((not defined $commandHash->{obj}) ||
          (not defined $commandHash->{method})) {
         $vdLogger->Error("$commandType"."'s Get() method missing for ".
                      "($self->{nodeid}) on $self->{targetip}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Gathering $state \'$commandType\' data for ".
                      "($self->{nodeid}) on $self->{targetip}");
      #
      # Generating the obj->Method(parameters) to get the commands
      # from the remote machine.
      #
      $objPtr = $commandHash->{obj};
      $method = $commandHash->{method};

      if (defined $commandHash->{params}) {
         $params = $commandHash->{params};
         #
         # Either user can define the input params to the Get Method
         # in the hash itself or it can set it in the hash during
         # the preprocess routine.
         #
         push(@value, %$params);
      }
      if(defined $self->{$objPtr}) {
         my $obj = $self->{$objPtr};
         $ret = $obj->$method(@value);
         if (defined $ret &&
            ($ret eq FAILURE) || ($ret =~ /unsupported/)) {
            $vdLogger->Error("obj:$obj method:$method failed for ".
                             "$self->{targetip}:$self->{nodeid}");
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         $commandHash->{$state} = $ret;
      } else {
         $vdLogger->Error("ObjPtr:$objPtr required for method:$method is ".
                          "missing in self ");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   return SUCCESS;
}


###############################################################################
#
# Stop -
#       StopVerification equivalent method in children for stopping the
#       verification to get the final output.
#
# Input:
#       none.
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
   if (defined $self->{sleepbeforefinal}) {
      $vdLogger->Info("Waiting for $self->{sleepbeforefinal} sec before ".
                      "gathering final data...");
      sleep(int($self->{sleepbeforefinal}));
   }
   my $ret = $self->Start("final");
   if($ret ne SUCCESS) {
      $vdLogger->Error("Stop on $self->{veritype} command for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# ProcessExpectationHash -
#       Overriding parent method just to save processing time.
#
# Input:
#       None
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessExpectationHash
{
   return SUCCESS;
}


###############################################################################
#
# SetExpectations -
#       Sets the expectation type and expectation value on command strings of the
#       template command hash.
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

sub SetExpectations
{
   my $self = shift;
   my $expectedKey = shift;
   my $expectedValue = shift;
   my $expectationType = shift;

   my $allCommands;
   my $bucket = $self->GetBucket();
   foreach my $commandsInBucket (keys %$bucket) {
      $allCommands = $bucket->{$commandsInBucket};
      foreach my $commandType (keys %$allCommands) {
         # for each command set the string and its exptectation type in
         # the template hash.
         $allCommands->{$commandType}->{template}->{$expectedKey} =
                                          $expectedValue . ":" .$expectationType;
      } # end of allNodes
   } # end of bucket

   return SUCCESS;

}


###############################################################################
#
# ExtractResults -
#       GetResults equivalent method in children for getting the results.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractResults
{
   my $self = shift;
   # 1) Perform a diff of intial and final output of command.
   my $ret = $self->DoDiff();
   if($ret ne SUCCESS) {
      $vdLogger->Error("Performing diff on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Do post processing before calling compareNodes
   my $commandList = $self->{commandbucket}->{commands};
   foreach my $commandType (keys %$commandList) {
      my $commandHash = $commandList->{$commandType};
      # Doing preprocesing first.
      if (defined $commandHash->{postprocess}) {
         my $postMethodArray = $commandHash->{postprocess};
         #
         # Preprocessing should not return any value. If at all it wants
         # to send something it can put it in the $commandHash's param
         # and the actual method will be called with those params
         #
         foreach my $postMethod (@$postMethodArray) {
            my $postResult = $self->$postMethod($commandHash);
            if ($postResult eq FAILURE) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
   }


   # 2) Compare the actual value(diff) with the expected value
   # and set pass/fail for the respective strings in each command file's diff
   $ret = $self->CompareNodes();
   if($ret ne SUCCESS) {
      $vdLogger->Error("CompareNodes() on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
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
   return $self->{commandbucket};
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
   my $command = $self->{expectedchange}->{data};
   if (not defined $command) {
      $vdLogger->Error("Data key not defined Verification hash ".
                        Dumper($self->{expectedchange}));
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   my $entireHash = $self->GetCommandHash();
   my @params;

   #
   # Irrespective of any key in DataDiff Verification. obj is the required
   # param. If there are other run time params user can check them in
   # pre or post processing. E.g. throughput is avaialble after the test
   # is finished thus its will be checked in post processing.
   #
   foreach my $key (keys %$entireHash) {
      my $value = $entireHash->{$key};
      if ($key =~ /$command/i) {
         if (defined $value->{requiredparams}) {
            @params = (@{$value->{requiredparams}});
         } else {
            @params = ($value->{obj});
         }
      }
   }

   if (scalar(@params) == 0) {
      $vdLogger->Error("Cannot find command:\'$command\' in commandHash".
                        Dumper($entireHash));
      VDSetLastError("EFAILED");
      return FAILURE;
   }
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
      'testbed'   => {
         'switches'  =>  'myswitches',
         'hostobj'   =>  'hostobj',
         'adapter'   =>   {
            'interface'  => 'myinterface',
         },
      },
   };

   return $spec;
}


###############################################################################
#
# GetMyChildren -
#       Overriding Verification.pm method as DataDiffVerification does not have
#       any children of its own.
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


##############################################################################
#
# FindKeyInHash --
#       If the diff is a nested hash and the user is interested in one of the
#       key in this nested hash, then find that key and return the value
#
# Input:
#       hash (mandotory) - in which key is to be found
#       key (mandatory) - key to be searched
#
# Results:
#       undef if not found
#       value of the key if found
#
# Side effects:
#       None
#
##############################################################################

sub FindKeyInHash
{
   my $self = shift;
   my $searchHash = shift;
   my $key = shift;
   my $result = undef;
   if ((not defined $searchHash) || (not defined $key)) {
      return undef;
   }

   # E.g.
   # User says command => 'esxcli lacp get status'
   # he expects key state to change => "independent-bundled"
   # Now GetLACPStatus API willl return a hash of all VDSes, all LAGID in
   # that VDS, all vmnics in each LAGID. Return value is thus a hash of
   # hash of hash. We need to find the 'state' key in this hash.
   #

   # TODO: find the key based on the 'traverseguide' var, this is in case
   # there are multiple keys of same name
   # traverseguide var will be in commandHash for that command
   foreach my $searchHashkey (keys %$searchHash) {
      if (ref($searchHash->{$searchHashkey}) =~ /HASH/) {
         $result = $self->FindKeyInHash($searchHash->{$searchHashkey}, $key);
      } else {
         if (defined $searchHash->{$key}) {
            return $searchHash->{$key};
         } else {
            my $dupHash = $searchHash;
            my %tempHash = %$dupHash;
            my $newHash = \%tempHash;
            %$newHash = (map { lc $_ => $newHash->{$_}} keys %$newHash);
            if (defined $newHash->{$key}) {
               return $newHash->{$key};
            }
         }
      }
   }

   return $result;
}


###############################################################################
#
# GetCommandHash -
#       Returns the command hash containing obj, method and params to run the
#       command.
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

sub GetCommandHash
{
   my $self = shift;
   return {
      #
      # One can create a subroutine in this package and say obj => $self
      # to call that subroutine for verification,
      # but if an API exists use that first.
      # One can have a key called params which should be a hash of params
      # to be passed to the API or one can write a preprocess routine and
      # generate the params hash and attach it to the command hash.
      #
      # These are two main examples.
      # Example 1. In getlacp, see that you can call array of methods as part of
      # preprocessing and postprocessing. You can also write wrapper method
      # and just call that one method
      # Example 2. getlacpconfig shows that you can mention params in the hash
      # itself. In example1 you call method to fill params.
      #
      # 'requiredparams' is an array containing params from testbed or
      # workload without which we cannot proceed.
      # We won't be able to construct obj without them
      # In case the obj is readily avaialble, there is no need for requiredparams
      # For values already known use params
      "lacpstatus" => {
         'preprocess'     => ['GetTestSwtichObj','GetLACPStatusParams'],
         'requiredparams' => ['myswitches','myinterface'],
         'obj'            => 'switchobj',
         'method'         => 'GetLACP',
         'postprocess'    => [],
         # Commenting this code just to show as an example
         #'params'      => {
         #    infotype => 'status',
         #    uplink => $self->{myinterface}
         #                 },
      },
      "lacpconfig" => {
         'preprocess'     => ['GetTestSwtichName', 'GetLACPConfigParams'],
         'requiredparams' => ['myswitches'],
         'obj'            => 'switchobj',
         'method'         => 'GetLACP',
         'postprocess'    => [],
         #'params'      => {
         #    infotype => 'config',
         #    dvsname  => $self->{dvsname},
         #                 },
      },
      # You can call the hash by any name, its just an id
      "lacpstats" => {
         'preprocess'     => ['GetTestSwtichObj'],
         'requiredparams' => ['myswitches','myinterface'],
         'obj'            => 'switchobj',
         'method'         => 'GetLACP',
         'params'      => {
             infotype => 'stats',
             uplink => $self->{myinterface}
                          },
      },
      "activeportstats" => {
         'requiredparams' => ['hostobj'],
         'obj'            => 'hostobj',
         'method'         => 'GetActivePortStats',
         'postprocess'    => [],
      },
   };

}


###############################################################################
#
# GetLACPStatusParams -
#       Routine for getlacp command key. It sets the params required to get
#       lacp info.
#
# Input:
#       commandHash
#
# Results:
#       none
#
# Side effects:
#       None
#
###############################################################################

sub GetLACPStatusParams
{
   my $self = shift;
   my $commandHash = shift;
   if (not defined $self->{myinterface}) {
      $vdLogger->Error("Interface missing, cannot proceed ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $params = {
       infotype => 'status',
       uplink  => $self->{myinterface},
   };
   $commandHash->{params} = $params;

   return SUCCESS;
}


###############################################################################
#
# GetLACPConfigParams -
#       Routine for getlacp command key. It sets the params required to get
#       lacp info.
#
# Input:
#       commandHash
#
# Results:
#       none
#
# Side effects:
#       None
#
###############################################################################

sub GetLACPConfigParams
{
   my $self = shift;
   my $commandHash = shift;
   if (not defined $self->{switchname}) {
      $vdLogger->Error("switchName missing, cannot proceed ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $params = {
       infotype => 'config',
       dvsname  => $self->{switchname},
   };
   $commandHash->{params} = $params;

   return SUCCESS;
}


###############################################################################
#
# GetTestSwtichObj -
#       Routine to get TestSwitch Obj from a list of switches.
#
# Input:
#       none
#
# Results:
#       none
#
# Side effects:
#       None
#
###############################################################################

sub GetTestSwtichObj
{
   my $self = shift;
   my $testSwitch;
   if ((defined $self->{workloadhash}->{workload}->{testswitch}) &&
       ($self->{workloadhash}->{workload}->{testswitch} =~ /\d+/)) {
      $testSwitch = $1 - 1;
   } else {
      $testSwitch = 0;
   }
   my @switchObj = @{$self->{myswitches}};
   $self->{switchobj} = $switchObj[$testSwitch];

   return SUCCESS;
}


###############################################################################
#
# GetTestSwtichName -
#       Routine to get name of the TestSwitch
#
# Input:
#       none
#
# Results:
#       none
#
# Side effects:
#       None
#
###############################################################################

sub GetTestSwtichName
{
   my $self = shift;
   if (not defined $self->{switchobj}) {
      $self->GetTestSwtichObj();
   }
   $self->{switchname} = $self->{switchobj}->{switch} ||
                                 $self->{switchobj}->{name};
   return SUCCESS;
}


1;






