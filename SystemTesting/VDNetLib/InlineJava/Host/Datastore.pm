###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Host::Datastore;

#
# This package contains attributes and methods to configure a datastore
# on a Host
#
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler
                                            NewDataHandler);


use constant TRUE  => 1;
use constant FALSE => 0;
my %INLINELIB = (
   vcqa => "VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa",
   vc => "VDNetLib::InlineJava::VDNetInterface::com::vmware::vc",
);


########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::Host::Datastore
#
# Input:
#     datastoreName : Name of datastore to fetch
#     anchor        :
#     hostMor       :
#
# Results:
#     Blessed reference of VDNetLib::InlineJava::VM::VirtualAdapter
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;

   my $self;
   $self->{'datastoreName'} = $options{'datastoreName'};
   $self->{'anchor'}    = $options{'anchor'};
   $self->{'hostMor'}  = $options{'hostMor'};

   eval {
      $self->{'datastoreObj'} = CreateInlineObject(
					"com.vmware.vcqa.vim.Datastore",
					$self->{'anchor'});
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::Host::" .
		       "Datastore obj");
      return FALSE;
   }

   my $datastore = $self->{'datastoreObj'};
   $self->{'datastoreMor'} = $datastore->getHostDataStoreByName(
                                                    $self->{'hostMor'},
						                            $self->{'datastoreName'}
   );

   bless $self, $class;

   return $self;
}


#############################################################################
#
# GetMORId--
#     Method to get datacenter Managed Object ID (MOID)
#
# Input:
#
# Results:
#	datacenter MORId, of the dataceneter
#	False, in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetMORId
{
   my $self   = shift;
   my $morId;
   eval {
      $morId = $self->{datastoreMor}->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the datastore MOR Id " .
                       "of".$self->{'datastoreName'});
      return FALSE;
   }
   return $morId;
}

1;
