########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::VSE::BGPRoute;
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
  'localas' => {
       'payload' => 'localas',
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
   'bgpneighbours' => {
       'payload' =>  'bgpneighbours',
       'attribute' => undef,
                },
   'defaultoriginate' => {
       'payload' => 'defaultoriginate',
       'attribute' => undef,
                 },
   'remoteas' => {
       'payload' => 'remoteas',
       'attribute' => undef,
                     },
   'weight' => {
       'payload' =>  'weight',
       'attribute' => undef,
                },
   'holddowntimer' => {
       'payload' => 'holddowntimer',
       'attribute' => undef,
                 },
   'keepalivetimer' => {
       'payload' => 'keepalivetimer',
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
   'password' => {
       'payload' => 'password',
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
#     VDNetLib::VSM::VSE::BGPRoute
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
   my $inlinePyObj = CreateInlinePythonObject('BGP_routing.BGP',
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
