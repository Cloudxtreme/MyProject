#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::InterruptVerification;

#
# This module gives object of Interrupt verification. It deals with gathering
# initial and final stats before a test is executed and then taking a diff
# between the two stats.
#

# Inherit the parent class.
require Exporter;
# ISA was not doing multiple inheritance thus I am using use base which works well
# for multiple inheritance.
use base qw(VDNetLib::Verification::StatsVerification
            VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

###############################################################################
#
# new -
#       This method creates obj of this InterruptVerification class.
#
# Input:
#       none
#
# Results:
#       Obj of InterruptVerification module, if successful;
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
   return $self;
}



###############################################################################
#
# ConvertRawDataToHash -
#       Converts the raw cat /proc/interrupts into hash.
#
# Input:
#       data (mandatory)
#       initialize counters (optional)
#
# Results:
#       converted hash - in case everything goes well. keys and values of
#       this hash are Intrs on CPUX => '0+%:default'
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ConvertRawDataToHash
{
   my $self = shift;
   my $data = shift;
   my $initCounter = shift;
   my $interface = $self->{interface};

   #         CPU0     CPU1     CPU2     CPU3
   # 67:    24797        0        1     165252  PCI-MSI        eth0
   # 75:   733132        0     2326     4029    IO-APIC-level  vmci, eth1

   # 1) Split the value by '\n'
   # 2) Get the max CPU count
   # 3) Assign INT value to the respective CPU
   # 4) Store them in hash and return the hash.

   my (@counter, $template);
   my @values = split('\n', $data);
   my @cpus = split(/\s+/, $values[0]);
   $values[0] =~ /(.*)cpu(\d+)(.*)$/i;
   my $numCPU = $2;
   if ($numCPU%2 == 0) {
      # this number is even. which means there are odd num of CPUs
      # as it starts with CPU0.
      # There cannot be odd number of vCPUs. Its a bug
      $vdLogger->Error("There cannot be odd number of vCPUs, It is a bug?".
                       Dumper($data));
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   foreach my $value (@values) {
      if ($value =~ /$interface/) {
         # Split according to one or more space
         @counter = split(/\s+/, $value);
         my $intCount = scalar(@counter);
         do {
            if (defined $initCounter) {
               # Set the default expectation to 0+% as part of initialization.
               $template->{"Intrs on CPU".$numCPU} = $initCounter."+%:default";
            } else {
               # This will get the corresponding value of CPU
               #     CPU0   CPU1   CPU2   CPU3
               # 67: 24797  0      1      165252  PCI-MSI  eth0
               # The logic works even if the intr line is shared with
               # another device e.g. IO-APIC-level  vmci, eth1
               $template->{"Intrs on CPU".$numCPU} = $counter[$numCPU + 2];
            }
         } while($numCPU--);
         last;
      } else {
         next;
      }
   }

   return $template;
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
   my $os = $self->{os};

   my @params;
   if ($os =~ /win/i) {
   } elsif ($os =~ /linux/i) {
      @params = ('interface');
   }

   return \@params;
}


###############################################################################
#
# VerificationSpecificDeletion -
#       Remove children which are not supported. Remove childrens for which
#       there is no expectation set.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub VerificationSpecificDeletion
{
   my $self = shift;
   my $target = $self->{target};
   my $nodeid = $self->{nodeid};

   if ($target =~ /host/i || $nodeid =~ /vmknic/i) {
      $vdLogger->Info("Interrupt Verification is not supported on $target");
      return "unsupported";
   }

   return SUCCESS;
}


###############################################################################
#
# ProcessExpectationHash -
#       Overriding parent method just to save time.
#
# Input:
#       hash   - expectation hash supplied by user(mandatory)
#       string - expectation type (default, specific, generic, workload)
#                Ref SetExpectedChange in Verification.pm for details(mandatory)
#
# Results:
#       SUCCESS - in case expectation is not default type OR
#                 in case it default and its set correctly using SetExpectations()
#
# Side effects:
#       None
#
###############################################################################

sub ProcessExpectationHash
{
   #
   # Proc INT will only have 1 kind of expectation "interrupt distribution"
   # A user can expect a CPU to have minimum distribution of 10% which means
   # out of 4 CPUs each should have minimum 10% interrupts.
   # Thus, this method ignores most of the other processing a parent as parent
   # is very generic and takes care of processing every child's expectations
   #
   my $self = shift;
   my $expectedHash = shift;
   my $expectationType = shift;

   if ($expectationType !~ /default/) {
      return SUCCESS;
   }

   return $self->SetExpectations("intrDistribution", "1+%", "default");


}


###############################################################################
#
# SetExpectations -
#       Sets the expectation type and expectation value on counters of the
#       template hash.
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

   my ($allMac, $allNodes, $template, $found, $allErrors);
   if ($expectedKey !~ /intrDistribution/i) {
      # InterruptVerification only supports intrDistribution key
      $vdLogger->Error("Only intrDistribution expectation key is supported".
                       " for this module");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $bucket = $self->GetBucket();
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      # For all nodes get the template and work on it
      foreach my $node (keys %$allNodes) {
         $template = $allNodes->{$node}->{template};
         # For each template get all the counters
         foreach my $templateKey (keys %$template) {
            my $templateValue = $template->{$templateKey};
            if ($templateValue eq '0+%:default') {
               $template->{$templateKey} = $expectedValue .":".
                                           $expectationType;
            }
         }
      } # end of allNodes
   } # end of bucket

   return SUCCESS;

}


###############################################################################
#
# CompareNodes -
#       Comparison specific to proc Intrs thus overriding parent
#       Compare the diff(final - initial) computed with expected value set
#       by user or workload. Based upon comparison of expected value and
#       actual value(diff) set pass/fail on the respective counter.
#       i.e. Get the value of intrs on CPU1 before the test and after the test
#       take a diff. Now compare the diff with what the user expected the diff
#       to be and based on it decided pass or fail.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub CompareNodes
{
   my $self = shift;

   # Get all the nodes from the stats bucket.
   # For each node compare diff and template. i.e.
   # Compare each counter's expected value and actual value
   # and tag pass/fail on that counter.
   my ($allNodes, $resultHash);
   my $bucket = $self->{statsbucket};
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      foreach my $nodeKey (keys %$allNodes) {
         my $node = $allNodes->{$nodeKey};
         if ((not defined $node->{diff}) ||
             (not defined $node->{template})) {
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         my $diffHash = $node->{diff};
         my $tempalateHash = $node->{template};

         # First convert the diff in terms of % so that
         # its same unit with that given by user.
         my @cpuValues;
         my $intrSummation = 0;
         foreach my $cpu (keys %$diffHash) {
            $intrSummation = $intrSummation + int($diffHash->{$cpu});
         }

         # Calculating % of intr on each CPU
         foreach my $cpu (keys %$diffHash) {
            if ($intrSummation != 0) {
               $diffHash->{$cpu} = (int($diffHash->{$cpu})/$intrSummation) * 100;
            }
            # Attach the % symbol to keep the units same for actual
            # and expected value.
            $diffHash->{$cpu} = $diffHash->{$cpu} . "%";
         }

         # For each expected counter key in template, comparing it with
         # the actual value.
         my $expectedCounterFound = 0;
         foreach my $key (keys %$tempalateHash) {
            $expectedCounterFound = 1;
            #
            # Split the expectation type and expected value.
            # as we store it as "4+:user" which means user expects it to be
            # equal to 4 or more than 4
            #
            my @tempExpValue = split(':',$tempalateHash->{$key});
            my $expValue = $tempExpValue[0];
            my $actualValue = $diffHash->{$key};
            my $counterResult;
            #
            # Set the result, expectation type, expected value, actual value,
            # intial and final value for each counter. Thus, a
            # CPUN, where N is CPU num hash will have all the above
            # mentioned values and we store all these counters in their
            # respective nodes.
            #
            if (defined $diffHash->{$key}) {
               $counterResult = $self->CompareCounterValues($expValue, $actualValue);
               if ($counterResult eq FAILURE) {
                  $vdLogger->Error("CompareCounterValues failed for ".
                                   "$key, $expValue, $actualValue");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               $resultHash->{$key}->{result} = $counterResult;
               $resultHash->{$key}->{expectationtype} = $tempExpValue[1];
               $resultHash->{$key}->{expectedvalue} = $expValue;
               $resultHash->{$key}->{actualvalue} = $actualValue;
               if (defined $node->{initial}) {
                  $resultHash->{$key}->{initial} = $node->{initial}->{$key};
               } else {
                    $resultHash->{$key}->{initial} = undef;
               }
               if (defined $node->{final}) {
                  $resultHash->{$key}->{final} = $node->{final}->{$key};
               } else {
                  $resultHash->{$key}->{final} = undef;
               }
            } else {
               $vdLogger->Error("Templatekey:$key is missing in diff");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }

         }
         # If there was no expectation with this node then delete the node so
         # that we dont display blank result line in DisplayStats
         if ($expectedCounterFound == 0) {
            delete $allNodes->{$nodeKey};
         }

         # A node will thus have hashes which are all counters containing
         # all states.
         $node->{result} = $resultHash;
         $resultHash = undef;
         # Freeing up resources to conserve memory.
         delete $node->{template};
         # Not deleting diff as some other obj might need it for
         # relative comparison of counters.
         if (defined $node->{initial}) {
            delete $node->{initial};
         }
         if (defined $node->{final}) {
            delete $node->{final};
         }
      }
   }

   return SUCCESS;

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
#       converted hash - a hash containging node info in language that
#		         verification module understands.
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
         'adapter'   =>   {
            'interface'   => 'interface',
         },
      },
   };

   return $spec;
}


###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#       This list is used in case user does not specify any verification type
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
   # Interrupt Verification has no children.
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
   return "dstvm,srcvm";

}


###############################################################################
#
# GetSupportedPlatform -
#       Returns the platforms supported by this module. Only options are guest
#       and host.
#       If some verification is only supported on win/linux, specific flavor
#       of win/linux, specific kernel version, they will be caught later.
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

   # This verification is supported inside the guest
   # as well as on host.
   # TODO: Ask if anyone knows of any way to get interrupt stats from host
   return "guest,host";

}


###############################################################################
#
# GetDefaultNode -
#       Returns the default nodes on each platform type for this kinda of
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

sub GetDefaultNode
{
   my $self = shift;

   my $nodeTemple;

   # This is our specification. We will get the intrs on CPUs
   # according to this specification.
   # For Windows we will have to find a tool
   # For Linux, we use
   # cat /proc/interrupts

   $nodeTemple = {
      'linux'  =>  {
         "cat /proc/interrupts" => {},
      },
   };

   return $nodeTemple;
}


###############################################################################
#
# DESTROY -
#       This method is destructor for this class.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#
###############################################################################

sub DESTROY
{
   return SUCCESS;
}

1;
