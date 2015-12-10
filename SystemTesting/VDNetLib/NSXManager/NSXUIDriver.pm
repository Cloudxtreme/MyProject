########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::NSXUIDriver;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Inline::Python qw(py_eval
                      py_call_function);
use VDNetLib::Common::VDErrorno qw(FAILURE);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger
                                              CallMethodWithKWArgs);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::NSXUIDriver
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::NSXUIDriver;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = {};
   $self->{ip}       = $args{ip};
   $self->{_pyIdName} = 'id_';
   my $build = $args{build};
   if (defined $args{parentObj}) {
      $self->{parentObj} = $args{parentObj};
   }
   $self->{_pyclass} = 'vmware.nsx.manager.ui_driver.ui_driver_facade.UIDriverFacade';
   bless $self;

   if (defined $build) {
       #TODO:move this to Testbedv2.pm
       eval {
           py_eval("import vmware.nsx.install_ui_appliance");
           py_call_function(
              "vmware.nsx.install_ui_appliance", "install_uas_war", $self->{ip}, $build);
       };

       if ($@) {
           $vdLogger->Error("Exception thrown while running " .
                            "inline function ui_utils:install_uas_war:\n". $@);
           return FAILURE;
       }
   }

   return $self;
}


#####################################################################
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
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              undef,
                                              $self->{ip},
                                              $self->{user},
                                              $self->{password},
                                              $self->{build});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}
1;
