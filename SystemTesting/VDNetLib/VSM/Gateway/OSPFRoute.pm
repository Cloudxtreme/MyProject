########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Gateway::OSPFRoute;
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

use constant attributemapping => {
  'areaid' => {
       'payload' => 'areaid',
       'attribute' => undef,
                     },
  'ospfareas' => {
       'payload' => 'ospfareas',
       'attribute' => undef,
                     },
  'vnic' => {
       'payload' => 'vnic',
       'attribute' => undef,
                     },
  'priority' => {
       'payload' => 'priority',
       'attribute' => undef,
                     },
  'cost' => {
       'payload' => 'cost',
       'attribute' => undef,
                     },
  'enabled' => {
       'payload' => 'enabled',
       'attribute' => undef,
                     },
  'gracefulrestart' => {
       'payload' =>  'gracefulrestart',
       'attribute' => undef,
                },
  'defaultoriginate' => {
       'payload' => 'defaultoriginate',
       'attribute' => undef,
                 },
  'hellointerval' => {
       'payload' => 'hellointerval',
       'attribute' => undef,
                 },
  'deadinterval' => {
       'payload' => 'deadinterval',
       'attribute' => undef,
                 },
  'protocoladdress' => {
       'payload' => 'protocoladdress',
       'attribute' => undef,
                 },
  'forwardingaddress' => {
       'payload' => 'forwardingaddress',
       'attribute' => undef,
                 },
  'ipaddress' => {
       'payload' => 'ipaddress',
       'attribute' => undef,
                 },
  'rules' => {
       'payload' => 'rules',
       'attribute' => undef,
                 },
  'action' => {
       'payload' => 'action',
       'attribute' => undef,
                 },
  'fromprotocol' => {
       'payload' => 'fromprotocol',
       'attribute' => undef,
                 },
  'ospfareatype' => {
       'payload' => 'type',
       'attribute' => undef,
                 },
  'ospfauthenticationtype' => {
       'payload' => 'type',
       'attribute' => undef,
                 },
  'ospfinterfaces' => {
       'payload' => 'ospfinterfaces',
       'attribute' => undef,
                 },
  'authentication' => {
       'payload' => 'authentication',
       'attribute' => undef,
                 },
  'ospfpasswordvalue' => {
       'payload' => 'value',
       'attribute' => undef,
                 },
  'static' => {
       'payload' => 'static',
       'attribute' => undef,
                 },
  'connected' => {
       'payload' => 'connected',
       'attribute' => undef,
                 },

};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Gateway::OSPFRoute
#
# Input:
#        None
# Results:
#     Blessed hash reference to an instance of
#
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
   $self->{gateway} = $args{gateway};
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
   my $inlinePyEdgeObj = $self->{gateway}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('OSPF_routing.OSPF',
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

1;
