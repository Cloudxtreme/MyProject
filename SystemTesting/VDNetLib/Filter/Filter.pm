########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Filter::Filter;

#
# This package is the entry point for interaction with
# Filter components. Filter Component includes Rules.
#
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::Utilities;
use VDNetLib::InlineJava::InlineRule;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS
                                   VDSetLastError VDGetLastError);
use VDNetLib::InlineJava::Portgroup::DVPortgroup;
use VDNetLib::Switch::VDSwitch::DVPortGroup;

########################################################################
#
# new --
#      This method is the entry point to this package.
#
# Input:
#      A named parameter hash with following keys:
#      'Name' : The Filter name that need to get added
#                      like "dvfilter-generic-vmware" (Required)
#      'dvpgObj'  : Object of the dvpg(vDS) (Required)
#      'dvportObj'  : Object of the dvport(vDS) (Required)
#      'FilterKey(optional)' : The key of the filter
#
# Results:
#      An object of filter If successful
#      FAILURE,otherwise
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;

   if (not defined( $args{dvpgObj} || $args{dvportObj})) {
      $vdLogger->Error("Either dvportgroup or" .
                                  "dvport is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (defined( $args{dvpgObj} && $args{dvportObj})) {
      $vdLogger->Error("Either dvportgroup or " .
                                "dvport need to be defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $args{name}) {
      $vdLogger->Error("FilterName is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self;
   $self->{dvpgObj}    = $args{'dvpgObj'};
   $self->{dvportObj}  = $args{'dvportObj'};
   $self->{name}       = $args{'name'};
   $self->{filterkey}  = $args{'filterkey'};
   bless ($self,$class);
   return $self;
}


#######################################################################
#
# AddRule --
#      This method add rules to the filter
#      1) Create a vdnet Rules.pm vdnet Object
#      2) Call AddRules using Inline Java
#      3) return the vdnet rule object.
#
# Input:
#     Array of Rule specs.Each spec may contain one or all of these:
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
#
# Results:
#     array of rule objects,if filter and rule
#     created successfully
#     "FAILURE", in case of any error,
#
# Side effects:
#     None
#
########################################################################

sub AddRule
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my ($arrayOfRuleObjects) = [];
   my $count = 0 ;
   my $ruleObject ;
   my $ruleinlineObject ;
   my $rulename;
   my $rulearray = [];
   my $filterObj;
   foreach my $element (@$arrayOfSpecs) {
     if (ref($element) !~ /HASH/) {
       $vdLogger->Error("Rule spec not in hash form");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }

     my %options = %$element;
     $rulename = $options {name};
     $filterObj = $self->GetInlineFilterObject();
     $options{filterObj} = $filterObj;
     $options{count} = $count;
     my $rulehash = {};
     $ruleinlineObject = $filterObj->AddRule(%options);
     $options{trafficrule} = $ruleinlineObject->{'trafficrule'};
     push (@$rulearray,$ruleinlineObject->{'trafficrule'}) ;
     $options{name} = $ruleinlineObject->{'rulename'};

     $ruleObject = VDNetLib::Filter::Rule->new(%options);
     if (not defined $ruleObject) {
        $vdLogger->Error("Not able to create VDNetLib::Filter::Rule obj");
         VDSetLastError("EFAILED");
         return FAILURE;
     }
     $count++;
     $rulehash->{'object'} = $ruleObject;
     push (@$arrayOfRuleObjects,$rulehash);
   }

  $filterObj->AddRuleToFilter($rulearray);
  $vdLogger->Info("Added Rules successfully");
  return $arrayOfRuleObjects;
}


########################################################################
#
# GetInlineFilterObject --
#      Method to edit a filter
#
# Input:
#      none
#
# Results:
#      Object of type VDNetLib::InlineJava::InlineFilter
#      FAILURE: otherwise
#
# Side effects:
#      None
#
########################################################################

sub GetInlineFilterObject
{
  my $self = shift;
  my $dvportObj  = $self->{'dvportObj'};
  my $dvpgObj    = $self->{'dvpgObj'};
  my $filtername = $self->{'name'};

  my $result = VDNetLib::InlineJava::InlineFilter->new(
                                      'name'       => $filtername,
                                      'dvpgObj'    => $dvpgObj,
                                      'dvportObj'  => $dvportObj
                                      );

  if (not defined $result) {
      $vdLogger->Error("Not able to create inline Filter obj");
      VDSetLastError("EFAILED");
      return FAILURE;
  }
  return $result;
}


########################################################################
#
# EditFilter --
#      Method to edit filter
#
# Input:
#     arrayOfSpecs:the spec of the filter to be edited and
#                rule spec to be added
#     Array of Rule specs.Each spec may contain one or all of these:
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
#      return Filter and rule objects
#
# Side effects:
#      None
#
########################################################################

sub EditFilter
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my $dvportObj    = $self->{dvportObj};
   my $dvpgObj      = $self->{dvpgObj};
   my $filterspec;
   my (@arrayOfFilterObjects);
   my $filterHash = {};
   my %options = %$arrayOfSpecs;
   my ($filterConfig, $filterObject);
   $options{stafHelper} = $self->{stafHelper};
   $options{operation} = "edit";
   $options{dvpgObj} = $dvpgObj;
   if (defined $options{'rule'}) {
      my $arrayOfRuleSpecs = $options{'rule'};
      my $refToArrayOfRuleObject = $self->AddRule($arrayOfRuleSpecs);
      $filterHash->{'rule'} = $refToArrayOfRuleObject;
    }
   my $obj;
   if (defined $dvpgObj) {
      $obj = $dvpgObj;
   }else {
      $obj = $dvportObj;
   }
   my $inlineObj = $obj->GetInlineObject();
   if (not defined $inlineObj || ($inlineObj eq FAILURE)) {
       $vdLogger->Error("Failed to create inline Dvport/DvPG object");
       VDSetLastError(VDGetlastError());
       return FAILURE;
   }
   $filterObject = $inlineObj->EditFilter(%options);
   $filterHash->{'object'} = $filterObject;
   if (not defined $filterObject) {
      $vdLogger->Error("Not able to create VDNetLib::Filter::Filter obj");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   push (@arrayOfFilterObjects, $filterHash);
   $vdLogger->Info("Edited filter successfully");
   return \@arrayOfFilterObjects;
}


########################################################################
#
# DeleteRule --
#      Method to Delete Rule
#
# Input:
#     rulespec:the spec of the rule to be deleted
#
#
# Results:
#      return SUCCESS,If rule is deleted
#      FAILURE ,in case of any error
#
# Side effects:
#      None
#
########################################################################

sub DeleteRule
{
   my $self = shift;
   my $rulespec  = shift;
   my $dvportObj = $self->{dvportObj};
   my $switchObj = $self->{switchObj};
   my $dvpgObj   = $self->{dvpgObj};
   my $arrayOfFilterObjects  ;
   my %options;
   my $result;
   foreach my $element (@$rulespec) {
      %options = %$element;
      $options{switchObj} = $self;
      $options{stafHelper} = $self->{stafHelper};
      $options{dvpgObj} = $dvpgObj;
      my $filterObj = $self->GetInlineFilterObject();
      $options{filterkey} = $filterObj->{filterkey};
      $options{filtername} = $self->{name};
      if (defined $dvpgObj) {
          my $dvpginlineObj = $dvpgObj->GetInlinePortgroupObject();
          if (not defined $dvpginlineObj || ($dvpginlineObj eq FAILURE)) {
             $vdLogger->Error("Failed to create InlinePortgroupObject");
             VDSetLastError(VDGetlastError());
             return FAILURE;
          }
          $result = $filterObj->DeleteRule(%options);
      } else {
         #port specifications will be here
      }
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to remove filter");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   $vdLogger->Debug("Filter removal operation is successful ".
                               "for dvpg ");
   return SUCCESS;
}
1;
