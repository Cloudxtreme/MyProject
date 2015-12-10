package VDNetLib::Infrastructure::TestInventory;
#
# This package allows to perform various operations on TestInventory
#

use strict;
use warnings;

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use base 'VDNetLib::Root::Root';
use constant attributemapping => {};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger);

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Infrastructure::TestInventory).
#
# Input:
#
# Results:
#      An object of VDNetLib::Infrastructure::TestInventory package.
#
# Side effects:
#      None
#
########################################################################

sub new
{

   my $class = shift;
   my $self = {};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.testinventory.testinventory.TestInventory';
   bless($self,$class);
   return $self;
}

sub GetInlinePyObject
{
    my $self = shift;
    my $parentPyObj = shift;
    my $inlinePyObj;

    eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass});
    };
    if($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   return $inlinePyObj;
}

sub CreateTestComponent
{
   my $self = shift;
   my $args = shift;
   my @arrayOfObjects;

   eval "require  VDNetLib::Infrastructure::TestComponent";

   if ($@) {
      $vdLogger->Error("unable to load module ".
                "VDNetLib::Infrastructure::TestComponent:$@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   foreach my $comp (@$args) {
      my $compObj = VDNetLib::Infrastructure::TestComponent->new(%$comp);
      if ($compObj eq FAILURE) {
         $vdLogger->Error("Failed to creat VDNetLib::Infrastructure::TestComponent");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $compObj->{parentObj} = $self;
      if (defined $comp->{sleep}) {
         my $result = $compObj->Delay($comp->{sleep});
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to delay TestComponent");
            return FAILURE;
         }
      }
      push(@arrayOfObjects, $compObj);
   }
   return \@arrayOfObjects;
}


sub DeleteTestComponent
{
   my $self = shift;
   my $args = shift;
   my @arrayOfObjects;
   foreach my $comp (@$args) {
      $vdLogger->Info("Deleting TestComponent Successfull");
   }
   return  SUCCESS;
}

sub Action1
{
   my $self = shift;
   my $args = shift;
   for (my $i= $args; $i>0; $i--) {
      $vdLogger->Info("Sleeping $i secs ...");
      sleep($i);
   }

   return SUCCESS;
}


1;
