#######################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::VDSwitch::DVPort;

#
# This package is responsible for handling all the interaction with
# VMware vNetwork Distributed Switch DVPorts.
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );
use VDNetLib::InlineJava::Port::DVPort;

#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::Switch::VDSwitch::DVPort
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'DVPGObj': object of the DV portgroup (Required).
#      'DVPortId': Name of the dvport(Required).
#      'stafHelper': Reference to the staf helper object.
#
# Results:
#      An object of VDNetLib::Switch::VDSwitch::DVPort, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $tag = "DVPort : new : ";
   my $self;
   my $DVPGObj = $args{DVPGObj};
   my $DVPort = $args{DVPort};
   my $stafHelper = $args{stafHelper};
   my $result;

   # check parameters.
   if (not defined $DVPGObj) {
      $vdLogger->Error("$tag DVPortGroup object param not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $DVPort) {
      $vdLogger->Error("$tag Port Id not defined for the dvport");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{DVPGObj} = $DVPGObj;
   $self->{stafHelper} = $stafHelper;
   $self->{DVPortID} = $DVPort;

   # create stafHelper if it is not passed.
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }
   bless($self,$class);
}


#####################################################################
#
# AddFilter --
#     This method add filter and Rules on DVPort
#
#
# Input:
#     Array of Filter specs.Each spec may contain one or all of these:
#     filtername
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
#     Return array of filter and rule objects ,If SUCCESS
#     "FAILURE", in case of any error,
#
# Side effects:
#     None
#
#########################################################################

sub AddFilter
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my $dvpgObj  = $self->{'DVPGObj'};
   my $dvportID  = $self->{'DVPortID'};
   my $refToArrayOfRuleObject;
   my (@arrayOfFilterObjects);
   foreach my $element (@$arrayOfSpecs){
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Filter spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $filterHash = {};
      my %options = %$element;
      my ($filterConfig, $filterObject);

      # 1) Create a vdnet Filter.pm vdnet Object
      # 2) Call AddFilter using Inline Java
      # 3) return the vdnet filter object.
      $options{stafHelper} = $self->{stafHelper};
      $options{dvportObj} = $self;
      $options{DVPortID}  = $dvportID;
      $options{operation} = "add";
      my $inlineObj = $self->GetInlineObject();
      if (not defined $inlineObj  || ($inlineObj  eq FAILURE)) {
         $vdLogger->Error("Failed to create InlineDVPgObject");
         VDSetLastError(VDGetlastError());
         return FAILURE;
      }
      my  $inlinefilterObject = $inlineObj->AddFilter(%options);
      if (not defined $inlinefilterObject) {
         $vdLogger->Error("Not able to create VDNetLib::Filter::Filter obj");
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      $options{filterkey} =  $inlinefilterObject->{'filterkey'};
      $filterObject = VDNetLib::Filter::Filter->new(%options);
      $filterHash->{'object'} =   $filterObject;


      if (defined $options{'rule'}) {
          my $ruleHash = {};
          my $arrayOfRuleSpecs = $options{'rule'};
          $filterObject = VDNetLib::Filter::Filter->new(%options);
          $refToArrayOfRuleObject = $filterObject->AddRule($arrayOfRuleSpecs);
          $filterHash->{'rule'} = $refToArrayOfRuleObject;
      }
      push (@arrayOfFilterObjects, $filterHash);
   }
   $vdLogger->Info("Added filter successfully");
   return \@arrayOfFilterObjects;
}


#####################################################################
#
# DeleteFilter --
#     Method to delete filter
#
#
# Input:
#     arrayofFilterObjects: array of filter objects to be deleted
#
# Results:
#     return SUCCESS upon deleting filter
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub DeleteFilter
{
   my $self = shift;
   my $arrayOfFilterObjects = shift ;
   my $dvpgObj  = $self->{'DVPGObj'};
   my $dvportID  = $self->{'DVPortID'};

   foreach my $element (@$arrayOfFilterObjects) {
      my %options = %$element;

      my $inlineObj = $self->GetInlineObject();
      if (not defined $inlineObj || ($inlineObj eq FAILURE)) {
         $vdLogger->Error("Failed to create InlinedvportObject");
         VDSetLastError(VDGetlastError());
         return FAILURE;
      }

      my $result = $inlineObj->RemoveFilter(%options);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to remove filter from dvport");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
    }

    $vdLogger->Debug("Filter removal operation is successful ".
                               "for dvport:$dvportID ");
    return SUCCESS;
}


#####################################################################
#
# GetInlineDVPortObject --
#      Method to return inlineDVport object
#
# Input:
#      None
#
# Results:
#      return value of new() in
#      VDNetLib::InlineJava::Port::DVport
#
# Side effects:
#      None
#
#########################################################################

sub GetInlineDVPortObject
{
   my $self = shift;
   my $dvpgObj  = $self->{'DVPGObj'};
   my $dvportid    = $self->{'DVPortID'};

   my $dvpginlineObj = $dvpgObj->GetInlinePortgroupObject();
   my $result = VDNetLib::InlineJava::Port::DVPort->new(
                                      'DVPortID'    => $dvportid,
                                      'DVPGObj'     => $dvpginlineObj,
                                      );

   if (not defined $result) {
      $vdLogger->Error("Not able to create inline DVPort obj");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   return $result;
}


#####################################################################
#
# GetInlineObject --
#      Wrapper method for inlineDVport object
#
# Input:
#      None
#
# Results:
#      return value of new() in
#      VDNetLib::InlineJava::Port::DVport
#      FAILURE:otherwise
#
# Side effects:
#      None
#
#########################################################################

sub GetInlineObject
{
   my $self = shift;

   my $result = $self->GetInlineDVPortObject();
   if (not defined $result) {
      $vdLogger->Error("Not able to create inline DVPort obj");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   return $result;
}

1;
