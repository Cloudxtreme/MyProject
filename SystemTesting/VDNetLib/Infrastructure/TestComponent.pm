########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Infrastructure::TestComponent;
#
# This package allows to perform various operations on TestComponent
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../VDNetLib/";

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';
use base 'VDNetLib::Root::Root';

use VDNetLib::Common::Utilities;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger);

use constant attributemapping => {
   'name' => {
      'payload' => 'display_name',
      'attribute' => 'undef'
   },
   'schema' => {
      'payload' => 'schema',
      'attribute' => undef
   },
   'ipaddress' => {
      'payload' => 'address',
      'attribute' => 'GetIPAddress'
   },
   'username' => {
      'payload' => 'user',
      'attribute' => 'user'
   },
   'password' => {
      'payload' => 'password',
      'attribute' => 'password'
   },
   'zone' => {
      'payload' => 'zone',
      'attribute' => 'zone',
   },
};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Infrastructure::TestComponent).
#
# Input:
#
# Results:
#      An object of VDNetLib::Infrastructure::TestComponent package.
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class   = shift;
   my %options = @_;
   # Initialize attributes of Root
   # status_code and exception
   my $self = VDNetLib::Root::Root->new();
   $self->{'name'}     = $options{'name'};
   $self->{'schema'}   = "3";
   $self->{'ip'}       = $options{'ipaddress'};
   $self->{'user'}     = $options{'username'};
   $self->{'password'} = $options{'password'};
   $self->{'zone'}     = "6.0";
   $self->{attributemapping} = attributemapping;
   $self->{bar} = $options{'bar'};
   $self->{baz} = $options{'baz'};
   $self->{alpha} = $options{'alpha'};
   $self->{foo} = $options{'foo'};
   $self->{conf} = $options{'conf'};
   $self->{sleep} = $options{'sleep'};
   $self->{parentObj} = $options{parentObj};
   $self->{_pyclass} = 'vmware.testinventory.testcomponent.testcomponent.TestComponent';
   $self->{_pyIdName} = 'id_';
   $self->{id} = '0000';
   bless($self,$class);
   return $self;
}

sub Delay
{
   my $self = shift;
   my $value = shift;

   if ((defined $value) && ($value > 0) && ($value <= 1000)) {
      $vdLogger->Info("Sleep $value " .
                      "seconds for test component");
      sleep($value);
   }
   return SUCCESS;
}

sub GetIPAddress
{
   my $self = shift;
   return $self->{'ip'};
}


#
# All CRUDAQ methods are public methods.
#

########################################################################
#
# Create --
#      Method to create component
#
# Input:
#      None
#
# Results:
#      Failure as it not implemented
#
# Side effects:
#      None
#
########################################################################

sub Create
{
   my $self = shift;
   $vdLogger->Error("Method not implemented");
   return FAILURE;
}


########################################################################
#
# Read --
#      Method to read the component
#
# Input:
#      None
#
# Results:
#      Failure as it not implemented
#
# Side effects:
#      None
#
########################################################################

sub Read
{
   my $self = shift;
   $vdLogger->Info("Making server call to read the endpoint");
   #
   # Server call
   #
   my $payload = {
      'ipaddress'      => '10.10.10.10',
   };

   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $payload,
   };
   return $resultHash;
}


########################################################################
#
# Update --
#      Method to Update component
#
# Input:
#      None
#
# Results:
#      Failure as it not implemented
#
# Side effects:
#      None
#
########################################################################

sub Update
{
   my $self = shift;
   $vdLogger->Error("Method not implemented");
   return FAILURE;
}


########################################################################
#
# Delete --
#      Method to Delete component
#
# Input:
#      None
#
# Results:
#      Failure as it not implemented
#
# Side effects:
#      None
#
########################################################################

sub Delete
{
   my $self = shift;
   $vdLogger->Error("Method not implemented");
   return FAILURE;
}


########################################################################
#
# Action --
#      Method to Action component
#
# Input:
#      None
#
# Results:
#      Failure as it not implemented
#
# Side effects:
#      None
#
########################################################################

sub Action
{
   my $self = shift;
   $vdLogger->Error("Method not implemented");
   return FAILURE;
}


########################################################################
#
# Query --
#      Method to Query component
#
# Input:
#      None
#
# Results:
#      Failure as it not implemented
#
# Side effects:
#      None
#
########################################################################

sub Query
{
   my $self = shift;
   $vdLogger->Error("Method not implemented");
   return FAILURE;
}


########################################################################
#
# ASimpleServerCall --
#      Method to make a server call
#
# Input:
#      inventoryObj - inventory object
#
# Results:
#      A result hash containing the following attribute
#         status_code => SUCCESS/FAILURE
#         response    => array consisting of serverdata and attributeMapping
#         error       => error code
#         reason      => error reason
#
# Side effects:
#      None
#
########################################################################

sub ASimpleServerCall
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;


   #
   # Server call
   #
   my $payload = [{
     'abc' => [{
      'display_name' => $self->{'name'},
      #'display_name' => "test3",
      'schema'       => $self->{'schema'} ,
      'address'      => $self->{'ip'},
      'user'         => $self->{'user'},
      'password'     => $self->{'password'},
      'extra_args1'  => "dummy",
      'extra_args2'  => "dummy",
      'extra_args3'  => "dummy",
      'array'        => [
                     {
                      'cdf' => {
                        'zone' => "6.0",
                       },
                     },
                     ],
   },]}];

   my $mapping = $self->{attributemapping};
   my $serverData = VDNetLib::Common::Utilities::FillServerForm($payload,
                                                                $serverForm,
                                                                $mapping);
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverData,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}

sub NestedUnitTest
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;

   $serverForm->{bar} = $self->{bar};
   $serverForm->{baz} = $self->{baz};
   $serverForm->{alpha} = $self->{alpha};
   $serverForm->{foo} = $self->{foo};
   $serverForm->{conf} = $self->{conf};
   $serverForm->{sleep} = $self->{sleep};

   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverForm,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}

sub NestedNegativeUnitTest
{
   my $self = shift;
   my $form;

   $form->{bar}{foo} = "12345678";
   $form->{bar}{component_mac} = "12345678";
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $form,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}

sub NetstedActionParamsUnitTest
{
   my $self         = shift;
   my $nestedStructure   = shift;
   print Dumper($nestedStructure);
   return "SUCCESS";
}


sub AnotherSimpleServerCall
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;


   #
   # Server call
   #
   $serverForm =   [
          {
            'sourceaddrs' => [
                        {
                          'ip' => ['192.168.1.1', '192.168.1.2'],
                          'mac' => "ABCDEFG",
                        },
                    ],
            'mcastversion' => '3',
            'groupaddr' => '239.1.1.1',
            'mcastmode' => 'exclude',
            'mcastprotocol' => 'IGMP'
          },
        ];
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverForm,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}

sub Action1
{
   my $self = shift;
   my $args = shift;
   for (my $i=$args; $i>0; $i--) {
      $vdLogger->Info("Sleeping $i secs ...");
      sleep($i);
   }

   return SUCCESS;
}


#######################################################################
#
# DummyRetrieveTestData --
#     Dummy Method to return the test_data saved in the zookeeper.
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub DummyRetrieveTestData
{
   my $self = shift;
   my $unUsed = shift;
   my $userDataHash = shift;
   # XXX(salman): Method in component classes don't receive any back
   # reference to the keys that invoked them, that is why it is
   # hardcoded here for testing.
   if (not defined $userDataHash) {
      $vdLogger->Error("No user input provided to get_test_data key");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (ref($userDataHash) ne 'HASH') {
      $vdLogger->Error("Expected a hash, got\n:" . Dumper($userDataHash));
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $userDataHash->{get_test_data}) {
      $vdLogger->Error("Key get_test_data not passed in\n:" . Dumper($userDataHash));
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $userDataHash->{get_test_data};
}

1;
