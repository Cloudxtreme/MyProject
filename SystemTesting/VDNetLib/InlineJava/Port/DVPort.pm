#############################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
##############################################################################
package VDNetLib::InlineJava::Port::DVPort;


use strict;
use warnings;

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


########################################################################
#
# new --
#     Contructor to create an object of
#     VDNetLib::InlineJava::Port::DVPort
#
# Input:
#     named hash:
#        'DVPortID' : portID that is connected
#        'dvpgObj' : reference to VDNetLib::InlineJava::Portgroup
#                     ::Dvportgroup object
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
   $self->{'DVPortID'} = $args{'DVPortID'};
   $self->{'type'} = "dvport";
   $self->{'DVPGObj'} = $args{'DVPGObj'};

   bless $self, $class;
   return $self;
}


########################################################################
#
# ReconfigureFilterPolicy --
#     Method to reconfigure filter on DVPort
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
   my $switchObj =  $self->{'DVPGObj'}{'switchObj'};
   my $dvsHelper = $switchObj->{'dvsHelper'};
   my $dvsMor = $switchObj->{'dvsMOR'};;
   my $dvportID = $self->{'DVPortID'};
   eval {

       $dvsHelper->reconfigureFilterPolicyToPort($dvsMor, $filterPolicy,
                                                             $dvportID);
   };
  if ($@) {
      $vdLogger->Error("Failed to Configure Filter policy in " .
                                                     "dvport:$dvportID ");
      InlineExceptionHandler($@);
      return FALSE;
  }
  $vdLogger->Info("Configured Filter policy in dvport:$dvportID ");
  return TRUE;
}


########################################################################
#
# GetDvPortFilterConfig --
#     Method to get FilterConfig  from DVPort
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

sub GetDvPortFilterConfig
{
  my $self = shift;
  my $switchObj =  $self->{'DVPGObj'}{'switchObj'};
  my $dvs = $switchObj->{'dvs'};
  my $dvsMOR = $switchObj->{'dvsMOR'};;
  my $dvportID = $self->{'DVPortID'};
  my $filterConfig;
  eval {
     #converting integer into string array format for Portkey
     my @portKey =unpack('c1', pack('I',$dvportID));
     my $portConfigSpec = $dvs->getPortConfigSpec($dvsMOR,\@portKey);
     my $filterPolicy = $portConfigSpec->[0]->getSetting()->
                                                    getFilterPolicy();
     $filterConfig = $filterPolicy->getFilterConfig();
     my $filterSize = $filterConfig->size();
     my $filterKey = $filterPolicy->getFilterConfig()->get(0)->getKey();
  };
  if ($@) {
    $vdLogger->Error("Failed to get FilterConfig for dvport:$dvportID");
    InlineExceptionHandler($@);
    return FALSE;
  }
  return $filterConfig;
}


#######################################################################
#
# GetFilterKey --
#     Method to Filter key  from DVPort
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
   $filterConfig = $self->GetDvPortFilterConfig();
    my $filterSize  = $filterConfig->size();
    for (my $keyCount = 0; $keyCount < $filterSize; $keyCount++) {
       my $portFiltername = $filterConfig->get($keyCount)->getAgentName();
       if ($portFiltername =~ m/$filtername/i) {
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


#######################################################################
#
# GetRuleKey --
#     Method to get rules from filter in DVPort
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
    $filterConfig = $self->GetDvPortFilterConfig();
    my $filterSize  = $filterConfig->size();
    my $filterKeyCount =0;
    for (my $keyCount = 0; $keyCount < $filterSize; $keyCount++) {
       if (defined $filtername) {
          my $portFiltername = $filterConfig->get($keyCount)->getAgentName();
          if ($portFiltername =~ m/$filtername/i) {
            $filterKey[$filterKeyCount] = $filterConfig->get($keyCount);
            my $dvsTrafficRuleInfo =  $filterKey[$filterKeyCount]
                                      ->getTrafficRuleset()->getRules();
            my $rulesize =  $dvsTrafficRuleInfo->size();
            for (my $ruleCount = 0; $ruleCount < $rulesize; $ruleCount++) {
                my $portRulename = $dvsTrafficRuleInfo->get($ruleCount)
                                                       ->getDescription();
                if ($portRulename =~ m/$rulename/i) {
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


#######################################################################
#
# GetExistingRules --
#     Method to get rules from filter in DVPort
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
    $filterConfig = $self->GetDvPortFilterConfig();
    my $filterSize  = $filterConfig->size();
    my $filterKeyCount =0;
    for (my $keyCount = 0; $keyCount < $filterSize; $keyCount++) {
        if (defined $filtername) {
           my $portFiltername = $filterConfig->get($keyCount)->getAgentName();
           if ($portFiltername =~ m/$filtername/i) {
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


#######################################################################
#
# AddFilter --
#     This method add filter on DVPort
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


#######################################################################
#
# RemoveFilter --
#     Method to Remove Filter from DVPort
#
# Input:
#     Filtername: name of filter
#     FilterKey : key for the filter
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




1;
