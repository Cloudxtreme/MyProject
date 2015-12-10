#############################################################################

# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
##############################################################################
package VDNetLib::InlineJava::Portgroup::DVPortgroup;


use strict;
use warnings;
use base 'VDNetLib::InlineJava::Portgroup::Portgroup';

use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   ABORT VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler);
use constant TRUE  => 1;
use constant FALSE => 0;
use VDNetLib::InlineJava::InlineFilter;


########################################################################
#
# new --
#     Contructor to create an object of
#     VDNetLib::InlineJava::Portgroup::DVPortgroup
#
# Input:
#     named hash:
#        'name' : portgroup name
#        'switchObj' : reference to VDNetLib::InlineJava:::DVS object
#
# Results:
#     blessed reference to this class instance
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my ($class) = shift;
   my %args    = @_;
   my $self = {};
   $self->{'name'} = $args{'name'};
   $self->{'type'} = "vdswitch";

   $self->{'switchObj'} = $args{'switchObj'};
   eval {
      $self->{'anchor'} = $self->{'switchObj'}{'anchor'};
      my $dvpg =
      CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualPortgroup",
                         $self->{anchor});
      $self->{'dvpg'} = $dvpg;
      my $dvportGroupMOR = $dvpg->getDVPortgroupByName(
                                       $self->{'switchObj'}{dvsMOR},
                                       $self->{'name'}
                                       );
      $self->{'dvpgMOR'} = $dvportGroupMOR;

   };
   if ($@) {
    $vdLogger->Error("Failed to create  inline DVPortgroup object");
    InlineExceptionHandler($@);
      return FALSE;
   }
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetPortConnection --
#     Method to get port connection details
#
# Input:
#     None
#
# Results:
#     reference to inline java object of
#     "com.vmware.vc.DistributedVirtualSwitchPortConnect" with attributes
#     set corresponding to this portgroup;
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPortConnection
{
   my $self = shift;
   my $pgName = $self->{'name'};
   my $dvsPortConnection;
   eval {
      my $dvsObj = $self->{'switchObj'};
      my $dvpg = $self->{'dvpg'};
      my $dvportGroupMOR = $self->{'dvpgMOR'};
      my $dvpgConfig = $dvpg->getConfigInfo($dvportGroupMOR);
      $dvsPortConnection =
         CreateInlineObject("com.vmware.vc.DistributedVirtualSwitchPortConnection");
      $dvsPortConnection->setPortgroupKey($dvpgConfig->getKey());
      $dvsPortConnection->setSwitchUuid($dvsObj->{dvs}->getConfig($dvsObj->{dvsMOR})->getUuid());
   };
   if ($@) {
      $vdLogger->Error("Failed to get port connection details");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      return $dvsPortConnection;
   }
}


########################################################################
#
# SetFailoverOrder --
#     Method to set DVPG's failover order (active|standby uplinks)
#
# Input:
#     refArrayofUplink: Reference of a vdnet lag object and/or Uplink
#                       name array (mandatory)
#     failoverType: active or standby (mandatory)
#
# Results:
#     TRUE , if set dvpg active uplink successfully
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetFailoverOrder
{
   my $self = shift;
   my $refArrayofUplink = shift;
   my $failoverType = shift;
   my $pgName = $self->{'name'};
   my $refArrayofUplinkNames = [];
   my $refArrayofActiveUplink = [];
   my $refArrayofStandbyUplink = [];

   for (my $i = 0; $i < scalar(@$refArrayofUplink); $i++) {
      if ($refArrayofUplink->[$i] =~ m/uplink/i) {
         push @$refArrayofUplinkNames, $refArrayofUplink->[$i];
      } else {
         push @$refArrayofUplinkNames, $refArrayofUplink->[$i]->{lagname};
      }
   }
   $vdLogger->Debug("Setting $pgName failover order for uplink:\n".
                     Dumper(@$refArrayofUplinkNames));

   eval {
      my $dvsObj = $self->{'switchObj'};
      my $dvpg = $self->{'dvpg'};
      my $dvpgMor = $self->{'dvpgMOR'};
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $dvsutil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");

      my $dvpgConfigSpec =
         CreateInlineObject("com.vmware.vc.DVPortgroupConfigSpec");
      my $portSetting =
         CreateInlineObject("com.vmware.vc.VMwareDVSPortSetting");
      my $portOrderPolicy =
         CreateInlineObject("com.vmware.vc.VMwareUplinkPortOrderPolicy");
      my $uplinkTeamingPolicy =
         CreateInlineObject("com.vmware.vc.VmwareUplinkPortTeamingPolicy");

      my $initialFailoverOrder = $self->GetFailoverOrder();
      if ($initialFailoverOrder == FALSE ) {
         $vdLogger->Error("GetFailoverOrder failed, returned FALSE");
         return FALSE;
      }

      #
      # Handle active&standby uplink changes.
      # E.g.  initial:  active --- uplink1,uplink2; standby --- uplink3
      #       target:   active --- uplink1;         standby --- uplink2,uplink3
      #
      if ($failoverType =~ /active/i) {
         $refArrayofActiveUplink = $util->arrayToVector($refArrayofUplinkNames);
         $refArrayofStandbyUplink = $initialFailoverOrder->{standbyUplink};
         for (my $i=0; $i < $refArrayofStandbyUplink->size(); $i++) {
            my $standbyUplink = $refArrayofStandbyUplink->get($i);
            for (my $j= 0; $j < $refArrayofActiveUplink->size(); $j++) {
               my $activeUplink = $refArrayofActiveUplink->get($j);
               if ($standbyUplink eq $activeUplink) {
                  $refArrayofStandbyUplink->remove($i);
                  $i--;
                  $vdLogger->Debug("Move $standbyUplink from standby to active");
               }
            }
         }
      } else {
         $refArrayofActiveUplink = $initialFailoverOrder->{activeUplink};
         $refArrayofStandbyUplink = $util->arrayToVector($refArrayofUplinkNames);
         for (my $i=0; $i < $refArrayofActiveUplink->size(); $i++) {
            my $activeUplink = $refArrayofActiveUplink->get($i);
            for (my $j= 0; $j < $refArrayofStandbyUplink->size(); $j++) {
               my $standbyUplink = $refArrayofStandbyUplink->get($j);
               if ($activeUplink eq $standbyUplink) {
                  $refArrayofActiveUplink->remove($i);
                  $i--;
                  $vdLogger->Debug("Move $activeUplink from active to standby");
               }
            }
         }
      }

      $portOrderPolicy->getActiveUplinkPort()->clear();
      $portOrderPolicy->getActiveUplinkPort()->addAll($refArrayofActiveUplink);
      $portOrderPolicy->getStandbyUplinkPort()->clear();
      $portOrderPolicy->getStandbyUplinkPort()->addAll($refArrayofStandbyUplink);

      $uplinkTeamingPolicy->setUplinkPortOrder($portOrderPolicy);
      $portSetting->setUplinkTeamingPolicy($uplinkTeamingPolicy);
      $dvpgConfigSpec->setDefaultPortConfig($portSetting);
      $dvpgConfigSpec->setConfigVersion($dvpg->getConfigInfo($dvpgMor)->getConfigVersion());
      $dvpg->reconfigure($dvpgMor, $dvpgConfigSpec);
   };

   if ($@) {
      $vdLogger->Error("Failed to set dvpg failover order");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      $vdLogger->Debug("Successfully set dvportgroup $pgName failover order");
      return TRUE;
   }
}

########################################################################
#
# GetFailoverOrder --
#     Method to get DVPG's failover order
#
# Input:
#
# Results:
#     Reference to hash containing following keys
#                        activeUplink => {
#                           $refArrayofActiveUplink
#                        },
#                        standbyUplink => {
#                           $refArrayofStandbyUplink
#                        },
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetFailoverOrder
{
   my $self = shift;
   my $pgName = $self->{'name'};
   my $refArrayofActiveUplink = [];
   my $refArrayofStandbyUplink = [];
   my %returnHash;

   eval {
      my $dvsObj = $self->{'switchObj'};
      my $dvpg = $self->{'dvpg'};
      my $dvpgMor = $self->{'dvpgMOR'};
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");

      my $dvpgConfigInfo = $dvpg->getConfigInfo($dvpgMor);
      my $portSetting = $dvpgConfigInfo->getDefaultPortConfig();
      my $uplinkTeamingPolicy = $portSetting->getUplinkTeamingPolicy();
      my $portOrderPolicy = $uplinkTeamingPolicy->getUplinkPortOrder();
      $refArrayofActiveUplink = $portOrderPolicy->getActiveUplinkPort();
      $refArrayofStandbyUplink = $portOrderPolicy->getStandbyUplinkPort();

      $returnHash{activeUplink} = $refArrayofActiveUplink;
      $returnHash{standbyUplink} = $refArrayofStandbyUplink;
   };

   if ($@) {
      $vdLogger->Error("Failed to get dvpg failover order");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      $vdLogger->Debug("Successfully get dvportgroup $pgName failover order");
      return \%returnHash;
   }
}


########################################################################
#
# SetLoadBalancing --
#     Method to set DVPG's load balancing policy
#
# Input:
#     policy: load balancing policy
#
# Results:
#     TRUE , if set dvpg load balancing policy successfully
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetLoadBalancing
{
   my $self = shift;
   my $policy = shift;
   my $pgName = $self->{'name'};

   eval {
      my $dvpg = $self->{'dvpg'};
      my $dvpgMor = $self->{'dvpgMOR'};
      my $dvsutil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");

      my $dvpgConfigSpec =
         CreateInlineObject("com.vmware.vc.DVPortgroupConfigSpec");
      my $portSetting =
         CreateInlineObject("com.vmware.vc.VMwareDVSPortSetting");
      my $uplinkTeamingPolicy =
         CreateInlineObject("com.vmware.vc.VmwareUplinkPortTeamingPolicy");

      $uplinkTeamingPolicy->setPolicy($dvsutil->getStringPolicy(0,"$policy"));
      $portSetting->setUplinkTeamingPolicy($uplinkTeamingPolicy);
      $dvpgConfigSpec->setDefaultPortConfig($portSetting);
      $dvpgConfigSpec->setConfigVersion($dvpg->getConfigInfo($dvpgMor)->getConfigVersion());
      $dvpg->reconfigure($dvpgMor, $dvpgConfigSpec);
   };

   if ($@) {
      $vdLogger->Error("Failed to set dvpg load balancing");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      $vdLogger->Debug("Successfully set dvportgroup $pgName load balancing");
      return TRUE;
   }
}


#############################################################################
#
# GetMORId--
#     Method to get DVPortgroup Managed Object ID (MOID)
#
# Input:
#
# Results:
#	dvPortGroup MORId, of the dvPortGroup
#	False, in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetMORId
{
   my $self   = shift;
   my $MORId;
   eval {
      $MORId = $self->{dvpgMOR}->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the dvPortGroup MOR Id " .
                       "of $self->{name}");
      return FALSE;
   }
   return $MORId;
}


########################################################################
#
# GetExistingRules --
#     Method to get rules from filter in DVPG
#
#
# Input:
#     filtername:name of the filter in which rule is configured
#
# Results:
#     return rulearraylist upon success
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub GetExistingRules
{
  my $self = shift;
  my $filtername = shift;
  my @filterKey;
  my $rulekey;
  my $dvsTrafficRuleInfo;
  my @rule;
  my $filterConfig;
  eval {
    $filterConfig = $self->GetDvPortGroupFilterConfig();
    my $filterSize  = $filterConfig->size();
    my $filterKeyCount =0;
    for (my $keyCount = 0; $keyCount < $filterSize; $keyCount++) {
        if (defined $filtername) {
           my $pgFiltername = $filterConfig->get($keyCount)->getAgentName();
           if ($pgFiltername =~ m/$filtername/i) {
             $filterKey[$filterKeyCount] = $filterConfig->get($keyCount);
             $dvsTrafficRuleInfo =  $filterKey[$filterKeyCount]
                                   ->getTrafficRuleset()->getRules();
             my $rulesize =  $dvsTrafficRuleInfo->size();
             for (my $ruleCount = 0 ;$ruleCount < $rulesize; $ruleCount++) {
               $rule[$ruleCount]=$dvsTrafficRuleInfo->get($ruleCount);
             }
            $filterKeyCount++;
           }
        } else {
           $vdLogger->Error("Filter name not defined:$filtername");
           VDSetLastError(VDGetLastError());
               return FAILURE;
        }
    }
  };
  if ($@) {
    $vdLogger->Error("Failed to get existing rules");
    InlineExceptionHandler($@);
    return FALSE;
  }

  return \@rule;
}


########################################################################
#
# GetRuleKey --
#     Method to get rules from filter in DVPG
#
#
# Input:
#     filtername:name of the filter in which rule is configured
#     rulename:name of the rule
#
# Results:
#     return rulekey upon success
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRuleKey
{
  my $self = shift;
  my $filtername = shift;
  my $rulename = shift;
  my @filterKey;
  my $rulekey;
  my $filterConfig;
  eval {
    $filterConfig = $self->GetDvPortGroupFilterConfig();
    my $filterSize  = $filterConfig->size();
    my $filterKeyCount =0;
    for (my $keyCount = 0; $keyCount < $filterSize; $keyCount++) {
       if (defined $filtername) {
          my $pgFiltername = $filterConfig->get($keyCount)->getAgentName();
          if ($pgFiltername =~ m/$filtername/i) {
            $filterKey[$filterKeyCount] = $filterConfig->get($keyCount);
            my $dvsTrafficRuleInfo =  $filterKey[$filterKeyCount]
                                      ->getTrafficRuleset()->getRules();
            my $rulesize =  $dvsTrafficRuleInfo->size();
            for (my $ruleCount = 0; $ruleCount < $rulesize; $ruleCount++) {
                my $pgRulename = $dvsTrafficRuleInfo->get($ruleCount)
                                                       ->getDescription();
                if ($pgRulename =~ m/$rulename/i) {
                    $rulekey = $dvsTrafficRuleInfo->get($ruleCount)
                                                              ->getKey();
                 }
               }

            $filterKeyCount++;
          }
       } else {
           $vdLogger->Error("Filter name not defined:$filtername");
           VDSetLastError(VDGetLastError());
               return FAILURE;
       }
    }
  };
  if ($@) {
    $vdLogger->Error("Failed to get Rule key for Rule:$rulename");
    InlineExceptionHandler($@);
    return FALSE;
  }

  return $rulekey;
}


########################################################################
#
# GetPortKeys --
#     Method to get all portkeys for all ports under DVPortgroup
#
# Input:
#     None
#
# Results:
#     return array reference containing port keys
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPortKeys
{
   my $self   = shift;
   my $portkeys;
   my @arrayOfPortKeys;
   my $dvpgMor    = $self->{'dvpgMOR'};
   eval {
      my $dvpgInlineObj = $self->{'dvpg'};
      $portkeys = $dvpgInlineObj->getPortKeys($dvpgMor);
      my $portKeySize  = $portkeys->size();
      for (my $keyCount = 0; $keyCount < $portKeySize; $keyCount++) {
           push @arrayOfPortKeys, $portkeys->get($keyCount);
      }
   };
   if ($@) {
      $vdLogger->Error("Failed to get the dvpg key");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      $vdLogger->Debug("Following port keys found" . Dumper(\@arrayOfPortKeys));
      return \@arrayOfPortKeys;
   }
}


########################################################################
#
# AddPortsToDVPortGroup --
#     Method to create ports under DVPortgroup using spec
#
# Input:
#     None
#
# Results:
#     SUCCESS when ports are added succesfully
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub AddPortsToDVPortGroup
{
   my $self         = shift;
   my $ports        = shift;
   my $dvpgMor      = $self->{'dvpgMOR'};
   my $dvpgInlineObj = $self->{'dvpg'};

   eval {
      my $dvpgConfigSpec =
         CreateInlineObject("com.vmware.vc.DVPortgroupConfigSpec");
      $dvpgConfigSpec->setNumPorts($ports);
      $dvpgConfigSpec->setConfigVersion(
         $dvpgInlineObj->getConfigInfo($dvpgMor)->getConfigVersion());
      $dvpgInlineObj->reconfigure($dvpgMor, $dvpgConfigSpec);
   };

   if ($@) {
      $vdLogger->Error("Failed to set the ports on dvpg");
      InlineExceptionHandler($@);
      return FAILURE;
   } else {
      return SUCCESS;
   }
}

#######################################################################
#
# ConfigureLAG
#      This method configures (enable/disable) LACPv1 LAG on DVPG.
#
# Input:
#      lagoperation - enable or disable
#      lagmode - active or passive
#
# Results:
#      "TRUE", if configure LACPv1 successfully
#      "FALSE", in case of any error
#
# Side effects:
#
########################################################################

sub ConfigureLAG
{
   my $self = shift;
   my $lagOperation = shift;
   my $lagMode = shift;
   my $pgName = $self->{'name'};

   eval {
      my $dvpg = $self->{'dvpg'};
      my $dvpgMor = $self->{'dvpgMOR'};
      my $isEnable =
         CreateInlineObject("com.vmware.vc.BoolPolicy");
      my $mode =
         CreateInlineObject("com.vmware.vc.StringPolicy");
      my $lacpPolicy =
         CreateInlineObject("com.vmware.vc.VMwareUplinkLacpPolicy");
      my $portSetting =
         CreateInlineObject("com.vmware.vc.VMwareDVSPortSetting");
      my $dvpgConfigSpec =
         CreateInlineObject("com.vmware.vc.DVPortgroupConfigSpec");

      if ($lagOperation =~ m/disable/i) {
         $isEnable->setValue("false");
      } else {
         $isEnable->setValue("true");
      }
      $mode->setValue($lagMode);
      $lacpPolicy->setEnable($isEnable);
      $lacpPolicy->setMode($mode);
      $portSetting->setLacpPolicy($lacpPolicy);
      $dvpgConfigSpec->setDefaultPortConfig($portSetting);
      $dvpgConfigSpec->setConfigVersion($dvpg->getConfigInfo($dvpgMor)->getConfigVersion());
      $dvpg->reconfigure($dvpgMor, $dvpgConfigSpec);
   };

   if ($@) {
      $vdLogger->Error("ConfigureLAG failed");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      $vdLogger->Debug("Successfully $lagOperation LACPv1 on dvportgroup".
                       " $pgName with mode $lagMode");
      return TRUE;
   }
}


########################################################################
#
# GetFilterKey --
#     Method to Filter key  from DVPG
#
# Input:
#     Filtername:name of filter
#
# Results:
#     Return Filterkey,If successful
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetFilterKey
{
  my $self = shift;
  my $filtername = shift;
  my $filterKey;
  my $filterConfig;
  eval {
    $filterConfig = $self->GetDvPortGroupFilterConfig();
    my $filterSize  = $filterConfig->size();
    for (my $keyCount = 0; $keyCount < $filterSize; $keyCount++) {
       my $pgFiltername = $filterConfig->get($keyCount)->getAgentName();
       if ($pgFiltername =~ m/$filtername/i) {
          $filterKey = $filterConfig->get($keyCount)->getKey();;
       }
     }
  };
  if ($@) {
    $vdLogger->Error("Failed to get Filter key for Filter:$filtername");
    InlineExceptionHandler($@);
    return FALSE;
  }
  return $filterKey;
}


########################################################################
#
# RemoveFilter --
#     Method to Remove Filter from DVPG
#
# Input:
#    args: spec of the filter to be deleted
#
# Results:
#     Return Filterobject,If successful
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub RemoveFilter
{
   my $self =shift;
   my %args = @_;

   my $dvportObj = $args{dvportObj};
   my $filterObject;
   my $filterPolicy;
   my $filterArrayList;
   my $filtername;
   eval {
    $filtername = $args{name};
    my $filterkey = $args{filterkey};
    $filterObject = VDNetLib::InlineJava::InlineFilter->new(%args);
    $filterArrayList = $filterObject->DeleteFilter($filtername , $filterkey);
    $filterPolicy = CreateInlineObject("com.vmware.vc.DvsFilterPolicy");
    $filterPolicy->setFilterConfig($filterArrayList);

    $self->ReconfigureFilterPolicy($filterPolicy);
   };
   if ($@) {
       $vdLogger->Error("Failed to Remove Filter ");
       InlineExceptionHandler($@);
       return FALSE;
   }

  $vdLogger->Info("Successfully Removed Filter :$filtername ");
  return SUCCESS;

}


########################################################################
#
# AddFilter --
#     This method add filter on DVPG
#
#
# Input:
#     Filter specs.Each spec may contain one or all of these:
#     filtername : dvfilter-generic-vmware
#     rule{
#           srcip
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
#        }
#
# Results:
#     Return inlinefilterobjects ,if filter is created successfully
#     "FAILURE", in case of any error,
#
# Side effects:
#     None
#
########################################################################

sub AddFilter
{
   my $self =shift;
   my %args = @_;
   my $filtername = $args{'name'};
   my $dvportObj = $args{dvportObj};
   my $inlinefilterObject;

   eval {
     $inlinefilterObject = VDNetLib::InlineJava::InlineFilter->new(%args);
     my $filterPolicy = $inlinefilterObject->ConfigureFilter(%args);
       $self->ReconfigureFilterPolicy($filterPolicy);
       $inlinefilterObject->{'filterkey'} =  $self->GetFilterKey(
                                                         $filtername
                                                         );
  };
  if ($@) {
      $vdLogger->Error("Failed to Add Filter:$filtername");
      InlineExceptionHandler($@);
      return FALSE;
  }
  $vdLogger->Info("Successfully Added Filter:$filtername");
  return $inlinefilterObject;

}


########################################################################
#
# ReconfigureFilterPolicy --
#     Method to reconfigure filter on DVPG
#
#
# Input:
#     FilterPolicy:Filterpolicy of the filter
#
# Results:
#     return true upon reconfiguring
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub ReconfigureFilterPolicy
{
   my $self =shift;
   my $filterPolicy = shift;
   my $pgName  = $self->{'name'};
   my $dvpg    = $self->{'dvpg'};
   my $dvpgMor = $self->{'dvpgMOR'};
   eval {
       $dvpg->reconfigureFilterPolicyToDVPG($dvpgMor, $filterPolicy);
   };
   if ($@) {
       $vdLogger->Error("Failed to Configure Filter policy in $pgName ");
       InlineExceptionHandler($@);
       return FALSE;
   }
   $vdLogger->Info("Configured Filter policy in $pgName ");
   return TRUE;
}


########################################################################
#
# EditFilter --
#     Method to edit filter on DVPG
#
#
# Input:
#     Filter specs.Each spec may contain one or all of these:
#     filtername : dvfilter-generic-vmware
#     rule{
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
#        }
#
# Results:
#     return inlinefilterobject upon editing
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub EditFilter
{
   my $self =shift;
   my %args = @_;

   my $pgName  = $self->{'name'};
   my $dvpg    = $self->{'dvpg'};
   my $dvpgMor = $self->{'dvpgMOR'};
   my $filterObject;
   my $filterPolicy;
   my $filtername;
   eval {
      $filtername = $args{name};
      my $filterKeys = $args{filterkey};
      $filterObject = VDNetLib::InlineJava::InlineFilter->new(%args);
      $args{'filterkey'} = $filterKeys;
      my $filterPolicy = $filterObject->ConfigureFilter(%args);
      $self->ReconfigureFilterPolicy($filterPolicy);
      $filterObject = VDNetLib::Filter::Filter->new(%args);
   };
   if ($@) {
       $vdLogger->Error("Failed to Configure policy in $pgName ");
       InlineExceptionHandler($@);
       return FALSE;
   }

  $vdLogger->Info("Reconfigured Filter $filtername in dvportgroup $pgName");
  return $filterObject;
}


#####################################################################
#
# ConfigureAdvanced --
#     Method to enable/disable overridePort Polices present in
#     Advanced at dvportgroup
#
#
# Input:
#     arrayOfAdvancedSpecs-Reference to hash of advance config spec
#     Hash of Advanced config spec to be overriden
#    overrideport = {
#                      Trafficfilterandmarking = allowed/disabled
#                   }
#
# Results:
#     return SUCCESS upon Configuring the override policy
#     FAILURE in cae of any error
#
# Side effects:
#     None:
#
########################################################################

sub ConfigureAdvanced
{
   my $self =shift;
   my %args = @_;
   my $dvpg    = $self->{'dvpg'};
   my $dvpgMor = $self->{'dvpgMOR'};

   eval {
       if ($args{TrafficFilterandmarking} =~ m/allowed/i) {
           $dvpg->setTrafficFilterOverrideAllowed($dvpgMor, 1);
       } else {
           $dvpg->setTrafficFilterOverrideAllowed($dvpgMor, 0);
       }
   };
   if ($@) {
       $vdLogger->Error("Failed to configure Advanced override port" .
                                                         " policies");
       InlineExceptionHandler($@);
       return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# GetDvPortGroupFilterConfig --
#     Method to get FilterConfig  from DVPortGroup
#
# Input:
#     none
#
# Results:
#     Return FilterConfig,If successful
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDvPortGroupFilterConfig
{
  my $self = shift;
  my $pgName  = $self->{'name'};
  my $dvpg    = $self->{'dvpg'};
  my $dvpgMor = $self->{'dvpgMOR'};
  my $filterConfig;
  eval {
     my $vmwareDVSConfigInfo =  $dvpg->getConfigInfo($dvpgMor);
     my $networkFilterPolicy = $vmwareDVSConfigInfo->
                             getDefaultPortConfig()->getFilterPolicy();
     $filterConfig = $networkFilterPolicy->getFilterConfig();
  };
  if ($@) {
    $vdLogger->Error("Failed to get FilterConfig for pgname:$pgName");
    InlineExceptionHandler($@);
    return FALSE;
  }
  return $filterConfig;
}


#######################################################################
#
# ConfigureIpfix
#      This method configures (enable/disable) Ipfix on DVPG.
#
# Input:
#      ipfixOperation - enable or disable
#
# Results:
#      "TRUE", if configure Ipfix successfully
#      "FALSE", in case of any error
#
# Side effects:
#
########################################################################

sub ConfigureIpfix
{
   my $self = shift;
   my $ipfixOperation = shift;
   my $pgName = $self->{'name'};

   eval {
      my $dvpg = $self->{'dvpg'};
      my $dvpgMor = $self->{'dvpgMOR'};
      my $isEnable =
         CreateInlineObject("com.vmware.vc.BoolPolicy");
      my $portSetting =
         CreateInlineObject("com.vmware.vc.VMwareDVSPortSetting");
      my $dvpgConfigSpec =
         CreateInlineObject("com.vmware.vc.DVPortgroupConfigSpec");

      if ($ipfixOperation =~ m/disable/i) {
         $isEnable->setValue("false");
      } else {
         $isEnable->setValue("true");
      }
      $portSetting->setIpfixEnabled($isEnable);
      $dvpgConfigSpec->setDefaultPortConfig($portSetting);
      $dvpgConfigSpec->setConfigVersion($dvpg->getConfigInfo($dvpgMor)->getConfigVersion());
      $dvpg->reconfigure($dvpgMor, $dvpgConfigSpec);
   };

   if ($@) {
      $vdLogger->Error("ConfigureIpfix failed");
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      $vdLogger->Debug("Successfully $ipfixOperation Ipfix on dvportgroup".
                       " $pgName");
      return TRUE;
   }
}


########################################################################
#
# ConfigPortGroupSecurityPolicy --
#     Method to configure vds port group security policy
#
# Input:
#     policytype     : ALLOW_PROMISCUOUS, MAC_CHANGE or FORGE_TRANSMITS
#                      (required)
#     flag           : enable/disable(required)
#
# Results:
#     TRUE if successfully configured the port group security policy
#     FALSE in case of any error;
#
# Side effects:
#     None
#
#########################################################################

sub ConfigPortGroupSecurityPolicy
{
   my $self          = shift;
   my $policy        = shift;
   my $flag          = shift;
   my $portGroupName = $self->{'name'};

   eval {
      my $iDVPortgroup = CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualPortgroup",
                                            $self->{'anchor'});
      my $dvpgMor      = $iDVPortgroup->getDVPortgroupByName($self->{'switchObj'}{dvsMOR},
                                                             $portGroupName);
      my $dvpgCfg      = CreateInlineObject("com.vmware.vc.DVPortgroupConfigSpec");
      my $dvsUtil      = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $setting      = CreateInlineObject("com.vmware.vc.VMwareDVSPortSetting");
      my $securityPolicy = CreateInlineObject("com.vmware.vc.DVSSecurityPolicy");
      my $isEnable       = CreateInlineObject("com.vmware.vc.BoolPolicy");

      if ($flag =~ m/disable/i) {
         $isEnable->setValue(0);
         $isEnable->setInherited(1);
      } else {
         $isEnable->setValue(1);
         $isEnable->setInherited(0);
      }
      if (lc($policy) eq lc(VDNetLib::TestData::TestConstants::ALLOW_PROMISCUOUS)) {
         $securityPolicy->setAllowPromiscuous($isEnable);
      } elsif (lc($policy) eq lc(VDNetLib::TestData::TestConstants::MAC_CHANGE)) {
         $securityPolicy->setMacChanges($isEnable);
      } else {
         $securityPolicy->setForgedTransmits($isEnable);
      }

      $setting->setSecurityPolicy($securityPolicy);
      $dvpgCfg->setDefaultPortConfig($setting);
      $dvpgCfg->setConfigVersion($iDVPortgroup->getConfigInfo($dvpgMor)->getConfigVersion());
      $iDVPortgroup->reconfigure($dvpgMor, $dvpgCfg);
   };
   if ($@) {
      $vdLogger->Error("Failed to configure port group $portGroupName security policy");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}
1;
