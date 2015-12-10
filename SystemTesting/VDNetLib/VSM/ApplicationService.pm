########################################################################
# Copyright (C) 2014 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::ApplicationService;
#
# This package allows to perform Application Service related operations on VSM
#

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
use Inline::Python qw(eval_python
                     py_bind_class
                     py_eval
                     py_study_package
                     py_call_function
                     py_call_method
                     py_is_tuple);
# Database of attribute mappings

use constant attributemapping => {};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      vsm : vsm ip(Required)
#
# Results:
#      An object of VDNetLib::VSM::Application
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{vsm} = $args{vsm};
   bless $self, $class;

   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();

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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('application.Application',
                                               $inlinePyVSMObj,
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $inlinePyObj->{id} = $self->{id};
   return $inlinePyObj;
}


########################################################################
#
# GetApplicationServiceAttributes --
#      Method to make a server call for Application Service endpoint
#      and fetch the attributes before verifying with the user input
#      attributes
#
# Input:
#      None
#
# Results:
#      A result hash containing the following attribute
#         status_code => SUCCESS/FAILURE
#         response => array consisting of serverdata and attributeMapping
#
# Side effects:
#      None
#
########################################################################


sub GetApplicationServiceAttributes
{
   my $self = shift;

   #
   # Make a GET Server call for the endpoint
   #
   my $resultObj;
   my $inlinePyObj = $self->GetInlinePyObject();
   my $resultHash = {
      'status'   => "FAILURE",
      'response' => undef,
   };
   eval{
      $resultObj = py_call_method($inlinePyObj,
                                  "read");
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while verifying " .
                       ":\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{'response'} = $@;
      return $resultHash;
   }
   my $payload = {};
   $payload->{'name'} = $resultObj->{name};
   $payload->{'description'} = $resultObj->{description};
   $payload->{'element'}->{'applicationprotocol'} = $resultObj->{element}->{applicationProtocol};
   $payload->{'element'}->{'sourceport'} = $resultObj->{element}->{sourcePort};
   $payload->{'element'}->{'value'} = $resultObj->{element}->{value};
   $payload->{'inheritanceallowed'} = $resultObj->{inheritanceAllowed};

   $resultHash = {
      'status'   => "SUCCESS",
      'response' => $payload,
   };
   return $resultHash;
}


#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName
{
   return "vsm";
}


1;
