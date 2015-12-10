###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::InlineRule;

#
# This class captures all inline Java related Filter code
#

use strict;
use warnings;
use Data::Dumper;
#
# Inherit the parent class Filter.
# we write non inlineFilter related code in the abstract layer Filter::Filter
# and write inline APIs in this package
#
use base qw(VDNetLib::Filter::Rule);


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
# Input:Rule spec with optional parameters
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
#     An object of VDNetLib::InlineJava::InlineRule class
#     FALSE, Otherwise
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %args       = @_;
   my $self;

   eval {
    my $rulename =$args{rulename};
    $self->{'rulename'} = $rulename;
    my $ipQualifier =
             CreateInlineObject("com.vmware.vc.DvsIpNetworkRuleQualifier");
    $self->{'ipQualifier'} = $ipQualifier;
    my $macQualifier =
             CreateInlineObject("com.vmware.vc.DvsMacNetworkRuleQualifier");
    $self->{'macQualifier'} = $macQualifier;
    my $filterruleset = $args{filterruleset};
    $self->{'filterruleset'} = $filterruleset;
   };
   if ($@) {
      $vdLogger->Error("Fail to create inline rule Objects");
      InlineExceptionHandler($@);
       return FALSE;
   }

   bless($self, $class);

   return $self;
}


#######################################################################
#
# ConfigureRules--
#      To configure Rules on the inline java Filter obj
#
# Input: Rule spec.Each spec may conain one or all of these
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
#      arraylist of rules,If rules are created successfully
#      "Failure",in case of any error
#
# Side effects:
#      None
#
#######################################################################

sub ConfigureRules
{
   my $self = shift;
   my %args = @_;
   my $rulename        = $args{name};
   my $ruleaction      = $args{action};
   my $srcip           = $args{sourceip};
   my $srcport         = $args{sourceport};
   my $srcmac          = $args{sourcemac};
   my $srcmacmask      = $args{sourcemacmask};
   my $srcipnegation   = $args{sourceipnegation};
   my $srcmacnegation  = $args{sourcemacnegation};
   my $srcportnegation = $args{sourceportnegation};
   my $dstip           = $args{destinationip};
   my $dstport         = $args{destinationport};
   my $dstmac          = $args{destinationmac};
   my $dstmacmask      = $args{destinationmacmask};
   my $dstipnegation   = $args{destinationipnegation};
   my $dstmacnegation  = $args{destinationmacnegation};
   my $dstportnegation = $args{destinationportnegation};
   my $costag          = $args{qostag};
   my $dscptag         = $args{dscptag};
   my $ruledirection   = $args{direction};
   my $vlan            = $args {vlan};
   my $systemTraffic   = $args{systemtraffic};
   my $protocol        = $args{protocol};
   my $protocolType    = $args{protocoltype};
   my $count           = $args{count};
   my $dvsNetworkTrafficRule;

   eval {
    my $ipNetworkRuleQualifier =
             CreateInlineObject("com.vmware.vc.DvsIpNetworkRuleQualifier");
    my $systemTrafficNetworkRuleQualifier =
     CreateInlineObject("com.vmware.vc.DvsSystemTrafficNetworkRuleQualifier");
    my $qualifierArrayList = CreateInlineObject('java.util.ArrayList');
    my $macNetworkRuleQualifier =
             CreateInlineObject("com.vmware.vc.DvsMacNetworkRuleQualifier");
    $dvsNetworkTrafficRule = CreateInlineObject("com.vmware.vc.DvsTrafficRule");
    if (!defined ($rulename)) {
        my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();
        $rulename = "rule"."-".$timestamp."-".$timestamp;
        $self->{'rulename'} = $rulename;
     }

    $dvsNetworkTrafficRule->setDescription($rulename);
    $dvsNetworkTrafficRule->setSequence($count);
    if (defined ($srcip || $dstip || $srcport || $dstport) ) {
       my $ipqualifier = $self->ProcessIP(srcip    => $srcip,
                                          srcport  => $srcport,
                                          srcipnegation => $srcipnegation,
                                          srcportnegation => $srcportnegation,
                                          dstip    => $dstip,
                                          dstport  => $dstport,
                                          dstipnegation => $dstipnegation,
                                          dstportnegation => $dstportnegation,
                                          protocol => $protocol
                                         );
       $qualifierArrayList->add($ipqualifier);
       $dvsNetworkTrafficRule->setQualifier($qualifierArrayList);
    }
    if (defined ($srcmac || $dstmac) ) {
       my $macqualifier = $self->ProcessMAC(srcmac    => $srcmac,
                                           dstmac    => $dstmac,
                                           srcmacmask => $srcmacmask,
                                           dstmacmask => $dstmacmask,
                                           srcmacnegation => $srcmacnegation,
                                           dstmacnegation => $dstmacnegation,
                                           protocol => $protocolType,
                                           );
       $qualifierArrayList->add($macqualifier);
       $dvsNetworkTrafficRule->setQualifier($qualifierArrayList);
    }
    if (defined $systemTraffic) {
       my $systraffic = $self->SetSystemTrafficValue($systemTraffic);
       $systemTrafficNetworkRuleQualifier->setTypeofSystemTraffic($systraffic);
       $qualifierArrayList->add($systemTrafficNetworkRuleQualifier);
       $dvsNetworkTrafficRule->setQualifier($qualifierArrayList);
    }
    if (defined $ruleaction) {
       my $action = $self->GetRuleAction(
                                        action => $ruleaction,
                                        costag => $costag,
                                        dscptag => $dscptag
                                       );
       $dvsNetworkTrafficRule->setAction($action);
    }
    if (defined $ruledirection) {
       $dvsNetworkTrafficRule->setDirection($ruledirection);
    }
   };
   if ($@) {
      $vdLogger->Error("Fail to configure rules on " . $self->{ruleaction});
      InlineExceptionHandler($@);
      return FALSE;
   }
   my %rulehash = (rulename => $rulename,
               trafficrule => $dvsNetworkTrafficRule);
  return \%rulehash;
}


########################################################################
#
# ProcessIP --
#     Method to add source/destination ip and protocol to the
#     Rulequalifier
#
# Input:
#      srcip:Ip of the SUT VM
#      destip:IP of the destination/helper VM
#      Protocol:Protocol like TCP/ICMP/UDP..etc
#
# Results:
#     return the iprulequalifier,if success
#     "FAILURE",in case of error
#
# Side effects:
#     None
#
########################################################################

sub ProcessIP
{
  my $self = shift;
  my %args = @_;
  my $srcip           = $args{'srcip'};
  my $destip          = $args{'dstip'};
  my $protocol        = $args{'protocol'};
  my $srcport         = $args{'srcport'};
  my $dstport         = $args{'dstport'};
  my $srcipnegation   = $args{'srcipnegation'};
  my $dstipnegation   = $args{'dstipnegation'};
  my $srcportnegation = $args{'srcportnegation'};
  my $dstportnegation = $args{'dstportnegation'};
  my $ipRuleQualifier = $self->{'ipQualifier'};

  eval {
    if (defined $srcip) {
      my  $sourceip =  CreateInlineObject("com.vmware.vc.SingleIp");
      $sourceip->setAddress($srcip);
      if (defined $srcipnegation) {
       $sourceip->setNegate($srcipnegation);
      }
      $ipRuleQualifier->setSourceAddress($sourceip);
    }
    if (defined $srcport) {
      my $srcPort =  CreateInlineObject("com.vmware.vc.DvsSingleIpPort");
      $srcPort->setPortNumber($srcport);
      if (defined $srcportnegation) {
       $srcPort->setNegate($srcportnegation);
      }
      $ipRuleQualifier->setSourceIpPort($srcPort);
    }
    if (defined $destip) {
      my  $destinationip =  CreateInlineObject("com.vmware.vc.SingleIp");
      $destinationip->setAddress($destip);
      if (defined $dstipnegation) {
       $destinationip->setNegate($dstipnegation);
      }
      $ipRuleQualifier->setDestinationAddress($destinationip);
    }
    if (defined $dstport) {
      my $destPort =  CreateInlineObject("com.vmware.vc.DvsSingleIpPort");
      $destPort->setPortNumber($dstport);
      if (defined $dstportnegation) {
       $destPort->setNegate($dstportnegation);
      }
      $ipRuleQualifier->setDestinationIpPort($destPort);
    }
   if (defined $protocol) {
     my $proto = $self->SetProtocolValue($protocol);
     $ipRuleQualifier->setProtocol($proto);
   }
 };
 if ($@) {
      $vdLogger->Error("Fail to Process source/destination ip");
      InlineExceptionHandler($@);
      return FALSE;
 }

 return $ipRuleQualifier;
}


#######################################################################
#
# ProcessMAC --
#     Method to add source/destination MAC and protocol to the
#     Rulequalifier
#
# Input:
#      srcmac:MAC of the SUT VM
#      destmac:MAC of the destination/helper VM
#      Protocol:ProtocolType-EtherType for TCP/UDP...etc
#
# Results:
#     return the macrulequalifier,if success
#     "FAILURE",in case of error
#
# Side effects:
#     None
#
########################################################################

sub ProcessMAC
{
 my $self = shift;
 my %args = @_;
 my $srcMAC          = $args{'srcmac'};
 my $destMAC         = $args{'dstmac'};
 my $protocol        = $args{'protocol'};
 my $srcmacMask      = $args{'srcmacmask'};
 my $destmacMask     = $args{'dstmacmask'};
 my $srcmacNegation  = $args{'srcmacnegation'};
 my $destmacNegation = $args{'dstmacnegation'};
 my $qualifier       = $self->{'macQualifier'};

 eval {
    if (defined $srcMAC) {
      my  $sourceMac;
      if (defined $srcmacMask) {
          $sourceMac =  CreateInlineObject("com.vmware.vc.MacRange");
      } else {
          $sourceMac =  CreateInlineObject("com.vmware.vc.SingleMac");
      }
      $sourceMac->setAddress($srcMAC);
      if (defined $srcmacMask) {
       $sourceMac->setMask($srcmacMask);
      }
      if (defined $srcmacNegation) {
       $sourceMac->setNegate($srcmacNegation);
      }
      $qualifier->setSourceAddress($sourceMac);
    }
    if (defined $destMAC) {
      my $destinationMac;
      if (defined $destmacMask) {
        $destinationMac =  CreateInlineObject("com.vmware.vc.MacRange");
      } else {
        $destinationMac =  CreateInlineObject("com.vmware.vc.SingleMac");
      }
      $destinationMac->setAddress($destMAC);
      if (defined $destmacMask) {
       $destinationMac->setMask($destmacMask);
      }
      if (defined $destmacNegation) {
       $destinationMac->setNegate($destmacNegation);
      }
      $qualifier->setDestinationAddress($destinationMac);
    }

   if (defined $protocol) {
     my $proto = $self->SetProtocolValue($protocol);
     $qualifier->setProtocol($proto);
   }
 };
 if ($@) {
      $vdLogger->Error("Fail to Process source/destination MAC");
      InlineExceptionHandler($@);
      return FALSE;
 }

 return $qualifier;

}

######################################################################
#
# SetProtocolValue --
#     Method to set protocol
#
# Input:
#      Protocol:Protocol like TCP/ICMP/UDP..etc
#
# Results:
#     return the protocol,if success
#     "FAILURE",in case of error
#
# Side effects:
#     None
#
########################################################################

sub SetProtocolValue
{
 my $self = shift;
 my $proto = shift;
 my $protocol;

 eval {
    $protocol =  CreateInlineObject("com.vmware.vc.IntExpression");
    $protocol->setValue($proto);
 };
 if ($@) {
      $vdLogger->Error("Fail to set Protocol value for : $proto");
      InlineExceptionHandler($@);
      return FALSE;
 }

 return $protocol;
}


######################################################################
#
# SetSystemTrafficValue --
#     Method to set System Traffic Value
#
# Input:
#      systemtraffic:type of system traffic like FCOE/VM..etc
#
# Results:
#     return the protocol,if success
#     "FAILURE",in case of error
#
# Side effects:
#     None
#
########################################################################

sub SetSystemTrafficValue
{
 my $self = shift;
 my $systraffic = shift;
 my $systemTraffic;

 eval {
    $systemTraffic =  CreateInlineObject("com.vmware.vc.StringExpression");
    $systemTraffic->setValue($systraffic);
 };
 if ($@) {
      $vdLogger->Error("Fail to set Protocol value for : $systraffic");
      InlineExceptionHandler($@);
      return FALSE;
 }

 return $systemTraffic;
}


######################################################################
#
# GetRuleAction --
#     Method to set Rule Action
#
# Input:
#      ruleaction:Accept/drop/punt/log(Required)
#      costag :<0-7> (optional)
#      dscptag :<0-63> (optional)
#
# Results:
#     return the protocol,if success
#     "FAILURE",in case of error
#
# Side effects:
#     None
#
########################################################################

sub GetRuleAction
{
 my $self = shift;
 my %args  = @_;
 my $ruleaction = $args{'action'};
 my $costag     = $args{'costag'};
 my $dscptag    = $args{'dscptag'};
 my $action;

 eval {
    if ($ruleaction =~ m/drop/i) {
      $action = CreateInlineObject("com.vmware.vc.DvsDropNetworkRuleAction");
    } elsif ($ruleaction =~ m/accept/i) {
      $action = CreateInlineObject("com.vmware.vc.DvsAcceptNetworkRuleAction");
    } elsif ($ruleaction =~ m/log/i) {
      $action = CreateInlineObject("com.vmware.vc.DvsLogNetworkRuleAction");
    }  elsif ($ruleaction =~ m/punt/i) {
      $action = CreateInlineObject("com.vmware.vc.DvsPuntNetworkRuleAction");
    } elsif ($ruleaction =~ m/tag/i) {
      $action =
           CreateInlineObject("com.vmware.vc.DvsUpdateTagNetworkRuleAction");
       if (defined $costag) {
           $action->setQosTag($costag);
       }
       if (defined $dscptag) {
           $action->setDscpTag($dscptag);
       }
    } else {
        $vdLogger->Error("Not a valid rule action " . $self->{ruleaction});
        return FALSE;
   }

 };
 if ($@) {
      $vdLogger->Error("Fail to set action : $ruleaction");
      InlineExceptionHandler($@);
      return FALSE;
 }

 return $action;
}
1;
