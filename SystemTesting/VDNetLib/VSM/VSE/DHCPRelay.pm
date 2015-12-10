########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::VSE::DHCPRelay;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant attributemapping => {};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::VSE::DhcpRelay
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::VSE::DhcpRelay
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{vse} = $args{vse};
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyEdgeObj = $self->{vse}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('dhcp_relay.DHCPRelay',
                                              $inlinePyEdgeObj,
                                             );
   $inlinePyObj->{id} = $self->{id};
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


########################################################################
#
# ProcessSpec --
#     Method to process the given array of LIF spec
#     and convert them to a form required by Inline Python API
#
# Input:
#     Reference to an array of hash
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpecRef = shift;
   my $arrayOfRelayAgents;
   my $arrayOfIP;
   foreach my $spec (@$arrayOfSpecRef) {
      $arrayOfIP = $spec->{ip_addresses};
      $arrayOfRelayAgents = $spec->{relayagent};
   }
   my $tempspec;
   my @arrayOfRelays ;
   my @newArrayOfSpec = ();
   foreach my $agent (@$arrayOfRelayAgents) {
       my $lif;
       $lif->{'vnicindex'} = $agent->{'id'};
       $lif->{'giaddress'} = $agent->get_interface_ip();
       push(@arrayOfRelays, $lif);
   }
   $tempspec->{relayagents} = \@arrayOfRelays;
   $tempspec->{relayserver}->{ipaddress} = $arrayOfIP;
   push(@newArrayOfSpec, $tempspec);
   return \@newArrayOfSpec;
}


1;
