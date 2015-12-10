########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::Infrastructure::TestPylib;

use strict;
use warnings;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use base 'VDNetLib::Root::Root';
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::Infrastructure::TestPylib
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::Infrastructure::TestPylib
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = VDNetLib::Root::Root->new();
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass}  = 'vmware.testinventory.testcomponent.testcomponent.TestComponent';
   bless $self;
   return $self;
}


sub Action1
{
   my $self = shift;
   my $args = shift;
   my $i = $args;
   for($i; $i>0; $i--) {
      $vdLogger->Info("Sleeping $i secs ...");
      sleep($i);
   }

   return FAILURE;
}
1;
