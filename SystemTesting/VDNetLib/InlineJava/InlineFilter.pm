###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::InlineFilter;

#
# This class captures all inline Java related Filter code
#

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::InlineJava::Portgroup::DVPortgroup;
use VDNetLib::InlineJava::InlineRule;

#
# Inherit the parent class Filter.
# we write non inlineFilter related code in the abstract layer Filter::Filter
# and write inline APIs in this package
#
use base qw(VDNetLib::Filter::Filter);


#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                            InlineExceptionHandler);

use constant TRUE  => 1;
use constant FALSE => 0;

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::InlineFilter
#
# Input:
#      FilterSpec
# Results:
#     An object of VDNetLib::InlineJava::InlineFilter class
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $filtername = $args{'name'};
   my $dvpgObj    = $args{dvpgObj};
   my $dvportObj  = $args{dvportObj};
   my $filterkey  = $args{filterkey};
   my $self;
   $self->{name}       = $filtername;
   $self->{dvpgObj}    = $dvpgObj;
   $self->{dvportObj}  = $dvportObj;
   $self->{filterkey}  = $filterkey;
   eval {
     my $filterConfigArrayList = CreateInlineObject('java.util.ArrayList');
     $self->{'filterConfigArrayList'} = $filterConfigArrayList;
     my $filterRuleset = CreateInlineObject("com.vmware.vc.DvsTrafficRuleset");
     $self->{'filterRuleset'}  = $filterRuleset;
     my $filterConfigSpec = CreateInlineObject("com.vmware.vc.DvsTrafficFilterConfigSpec");
     $self->{'filterConfigSpec'} = $filterConfigSpec;
     my $filterPolicy = CreateInlineObject("com.vmware.vc.DvsFilterPolicy");
     $self->{'filterPolicy'} = $filterPolicy;
  };
  if ($@) {
      $vdLogger->Error("Fail to create inline Filter Objects");
      InlineExceptionHandler($@);
       return FALSE;
  }

  bless($self, $class);
  return $self;
}


#######################################################################
#
# ConfigureFilter--
#      To configure filter on the inline java Filter obj
#
# Input:
#      args: filterspec
#            'filtername' => 'dvfilter-generic-vmware',
#             'rule' => {
#                '[1]' => {
#                          'ruleoperation' => 'add',
#                          'srcip'        => 'srcip',
#                          'ruleaction'   => 'drop',
#                          'protocol'     => 'icmp',
#                         },
#
#                },
#
# Results:
#       return FilterPolicy in case of success
#       FAILURE in case of any error
#
# Side effects:
#      None
#######################################################################

sub ConfigureFilter
{
   my $self = shift;
   my %args  = @_;
   my $filtername         = $self->{name};
   my $operation          = $args{'operation'};
   my $rule               = $args{'rule'};
   my $arrayofruleobjects =  $args{'arrayofruleobjects'};
   my $filterConfig       = $self->{'filterConfig'};
   my $filterConfigSpec   = $self->{'filterConfigSpec'};
   my $filterPolicy       = $self->{'filterPolicy'};
   my $filterRuleset      = $self->{'filterRuleset'};
   my $filterConfigArrayList = $self->{'filterConfigArrayList'};

   eval {
       if ($operation =~ m/add/i) {
         $filterConfigSpec->setOperation("add");
       } else {
         my $filterKey = $args{'filterkey'};
         $filterConfigSpec->setOperation("edit");
         $filterConfigSpec->setKey($filterKey);
       }
       $filterConfigSpec->setAgentName($filtername);
       $filterConfigSpec->setTrafficRuleset($filterRuleset);
       $filterConfigArrayList->add($filterConfigSpec);
       $filterPolicy->setFilterConfig($filterConfigArrayList);
   };
   if ($@) {
      $vdLogger->Error("Fail to configure filter  " . $filtername);
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $filterPolicy;
}


#######################################################################
#
# DeleteFilter--
#      Method to delete filter
#
# Input:
#      FilterKey :key of the filter in edit mode
#      Filtername:name of the filter (eg)dvfilter-generic-vmware
#
# Results:
#       return Filterarraylist in case of success
#       FAILURE in case of any error
#
# Side effects:
#      None
#######################################################################

sub DeleteFilter
{
  my $self = shift;
  my $filtername = shift;
  my $filterKey = shift;
  my $dvsNetworkTrafficFilterConfig  = $self->{'filterConfigSpec'};
  my $dvsNetworkTrafficFilterRuleset = $self->{'filterRuleset'};
  my $dvsNetworkTrafficFilterPolicy  = $self->{'filterPolicy'};
  my $dvsNetworkTrafficFilterConfigArrayList = $self->{'filterConfigArrayList'};
  eval {
     $dvsNetworkTrafficFilterConfig->setAgentName($filtername);
     $dvsNetworkTrafficFilterConfig->setOperation("remove");
     $dvsNetworkTrafficFilterConfig->setKey($filterKey);
     $dvsNetworkTrafficFilterConfig->setTrafficRuleset(
                                     $dvsNetworkTrafficFilterRuleset);
     $dvsNetworkTrafficFilterConfigArrayList->add(
                                     $dvsNetworkTrafficFilterConfig );
  };

  if ($@) {
      $vdLogger->Error("Fail to configure filter  " . $filtername);
      InlineExceptionHandler($@);
      return FALSE;
  }

  return $dvsNetworkTrafficFilterConfigArrayList;
}


#######################################################################
#
# AddRule--
#      This method add rule  trafficrule object
#
# Input:
#      rule spec that has optional parameters
#           srcip           : <192.168.2.1>
#           srcport         : <17000>
#           srcmac          : <00:0c:29:c3:6a:b8>
#           srcipnegation   : <yes/no>
#           srcportnegation : <yes/no>
#           srcmacnegation  : <yes/no>
#           dstip           : <192.168.0.3>
#           dstport         : <17000>
#           dstmac          : <00:0c:29:c8:6a:b4>
#           dstipnegation   : <yes/no>
#           dstportnegation : <yes/no>
#           dstmacnegation  : <yes/no>
#           qostag          : <0-7>
#           dscptag         : <0-63>
#           ruleaction      : <Accept/drop/punt>
#           ruledirection   : <incoming/outgoing/both>
#           vlan            : <0-1045>
#
# Results:
#       return inlineruleobject in case of success
#       FAILURE in case of any error
#
# Side effects:
#      None
#######################################################################

sub AddRule
{
   my $self =shift;
   my %args = @_;
   my $filtername = $self->{name};
   my $count = $args{count};
   my $ruleinlineObject;
   my %traffichash;

   eval {
      $ruleinlineObject = VDNetLib::InlineJava::InlineRule->new(%args);
      my  $trafficRule = $ruleinlineObject->ConfigureRules(%args);
      %traffichash = %$trafficRule;
      $ruleinlineObject->{'trafficrule'} =  $traffichash{trafficrule};
      $ruleinlineObject->{'rulename'} =  $traffichash{rulename};
   };

   if ($@) {
      $vdLogger->Error("Fail to configure Rules on  " . $filtername);
      InlineExceptionHandler($@);
      return FALSE;
   }

  return $ruleinlineObject;
}


#######################################################################
#
# AddRuletoFilter--
#      To add rule to a filter
#
# Input:
#      rule spec that has optional parameters
#           srcip           : <192.168.2.1>
#           srcport         : <17000>
#           srcmac          : <00:0c:29:c3:6a:b8>
#           srcipnegation   : <yes/no>
#           srcportnegation : <yes/no>
#           srcmacnegation  : <yes/no>
#           dstip           : <192.168.0.3>
#           dstport         : <17000>
#           dstmac          : <00:0c:29:c8:6a:b4>
#           dstipnegation   : <yes/no>
#           dstportnegation : <yes/no>
#           dstmacnegation  : <yes/no>
#           qostag          : <0-7>
#           dscptag         : <0-63>
#           ruleaction      : <Accept/drop/punt>
#           ruledirection   : <incoming/outgoing/both>
#           vlan            : <0-1045>
#
# Results:
#       return True in case of success
#       FAILURE in case of any error
#
# Side effects:
#      None
#######################################################################

sub AddRuleToFilter
{
   my $self =shift;
   my $ruleSpec = shift;
   my $filtername       = $self->{name};
   my $filterConfigSpec = $self->{'filterConfigSpec'};
   my $filterPolicy     = $self->{'filterPolicy'};
   my $filterRuleset    = $self->{'filterRuleset'};
   my $dvportObj        = $self->{dvportObj};
   my $obj;
   my $inlineObj;
   if($dvportObj) {
     $obj = $self->{dvportObj};
   } else {
     $obj  = $self->{dvpgObj};
   }
   $inlineObj = $obj->GetInlineObject();
   my $filterKey = $inlineObj->GetFilterKey($filtername);
   my $ruleArrayList = CreateInlineObject('java.util.ArrayList');
   my $filterConfigArrayList = $self->{'filterConfigArrayList'};
   #check for any existing rules
   my $existingRules = $inlineObj->GetExistingRules($filtername);
   if ($existingRules) {
      my $rulesize = @$existingRules;
      for (my $rulecount = 0 ;$rulecount < $rulesize; $rulecount++) {
          $ruleArrayList->add(${$existingRules}[$rulecount]);
      }
   }

  foreach my $rule (@$ruleSpec) {
    $ruleArrayList->add($rule);
  }
  $filterRuleset->setRules($ruleArrayList);
  $filterRuleset->setEnabled("true");
  $filterConfigSpec->setOperation("edit");
  $filterConfigSpec->setKey($filterKey);
  $filterConfigSpec->setAgentName($filtername);
  $filterConfigSpec->setTrafficRuleset($filterRuleset);
  $filterConfigArrayList->add($filterConfigSpec);
  $filterPolicy->setFilterConfig($filterConfigArrayList);
  $inlineObj->ReconfigureFilterPolicy($filterPolicy);
  return TRUE;
}


#######################################################################
#
# DeleteRule--
#      To delete rule from  filter
#
# Input:
#      rule spec that has optional parameters
#           srcip           : <192.168.2.1>
#           srcport         : <17000>
#           srcmac          : <00:0c:29:c3:6a:b8>
#           srcipnegation   : <yes/no>
#           srcportnegation : <yes/no>
#           srcmacnegation  : <yes/no>
#           dstip           : <192.168.0.3>
#           dstport         : <17000>
#           dstmac          : <00:0c:29:c8:6a:b4>
#           dstipnegation   : <yes/no>
#           dstportnegation : <yes/no>
#           dstmacnegation  : <yes/no>
#           qostag          : <0-7>
#           dscptag         : <0-63>
#           ruleaction      : <Accept/drop/punt>
#           ruledirection   : <incoming/outgoing/both>
#           vlan            : <0-1045>
#
# Results:
#       return True in case of success
#       FAILURE in case of any error
#
# Side effects:
#      None
#######################################################################

sub DeleteRule
{
  my $self = shift;
  my %args = @_;
  my $rulename       = $args{rulename};
  my $filtername     = $args{filtername};
  my $filterConfig   = $self->{'filterConfigSpec'};
  my $filterRuleset  = $self->{'filterRuleset'};
  my $filterPolicy   = $self->{'filterPolicy'};
  my $ruleArrayList  = CreateInlineObject('java.util.ArrayList');
  my $dvpgObj        = $self->{dvpgObj};
  my $inlinedvpgObj  = $dvpgObj->GetInlinePortgroupObject();
  if (not defined $inlinedvpgObj || ($inlinedvpgObj eq "FAILURE")) {
     $vdLogger->Error("Failed to create InlinePortgroupObject");
     VDSetLastError(VDGetlastError());
     return FALSE;
  }
  my $filterKey      = $inlinedvpgObj->GetFilterKey($filtername);
  my $ruleKey        = $inlinedvpgObj->GetRuleKey($filtername, $rulename);
  my $filterConfigArrayList = $self->{'filterConfigArrayList'};

  my $existingRules  = $inlinedvpgObj->GetExistingRules($filtername);
  if ($existingRules) {
     my $rulesize = @$existingRules;
     for(my $rulecount = 0 ;$rulecount < $rulesize; $rulecount++) {
       my $existingRuleKey = ${$existingRules}[$rulecount]->getKey();
        if($existingRuleKey ne $ruleKey) {
          $ruleArrayList->add(${$existingRules}[$rulecount]);
        }
     }
  }

  eval {
     $filterRuleset->setRules($ruleArrayList);
     $filterRuleset->setEnabled("true");
     $filterConfig->setAgentName($filtername);
     $filterConfig->setOperation("edit");
     $filterConfig->setKey($filterKey);
     $filterConfig->setTrafficRuleset($filterRuleset);
     $filterConfigArrayList->add($filterConfig );
     $filterPolicy->setFilterConfig($filterConfigArrayList);
     if (defined $dvpgObj) {
       $inlinedvpgObj->ReconfigureFilterPolicy($filterPolicy);
     }
  };
  if ($@) {
      $vdLogger->Error("Fail to configure filter  " . $filtername);
      InlineExceptionHandler($@);
      return FALSE;
  }

  return TRUE;
}

1;
