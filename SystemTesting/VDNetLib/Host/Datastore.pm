###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::Host::Datastore
#
#   This package allows to perform various operations on datastore.
#
###############################################################################

package VDNetLib::Host::Datastore;

use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use VDNetLib::InlineJava::Host::Datastore;


###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Host::Datastore).
#
# Input:
#      hostObj	    - VC Object
#      datastoreName - Name of the datastore.
#
# Results:
#      An object of VDNetLib::Host::Datastore package.
#
# Side effects:
#      None
#
###############################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self  = {};

   $self->{hostObj}	   = $args{hostObj};
   $self->{datastoreName}   = $args{datastore};

   bless($self, $class );

   return $self;
}


###############################################################################
#
# GetInlineDatastoreObj --
#      Method to get the datastore Inline object
#
# Results:
#      Datastore Inline object.
#
# Side effects:
#      None
#
###############################################################################

sub GetInlineDatastoreObj
{
   my $self = shift;

   my $anchor;

   if (defined $self->{hostObj}->{vcObj}) {
      my $inlineVCSession = $self->{hostObj}->{vcObj}->GetInlineVCSession();
      $anchor = $inlineVCSession->{'anchor'};
   } else {
      my $inlineHostSession = $self->{hostObj}->GetInlineHostSession();
      $anchor = $inlineHostSession->{'anchor'};
   }

   my $hostObj = $self->{hostObj}->GetInlineHostObject();

   my $inlineDatastore = VDNetLib::InlineJava::Host::Datastore->new(
               datastoreName => $self->{datastoreName},
               anchor => $anchor,
               hostMor => $self->{hostObj}->GetInlineHostObject()->{'hostMOR'}
            );
   return $inlineDatastore;
}


###############################################################################
#
# GetMORId --
#      Method to get the datastore MOR ID from Inline object
#
# Results:
#      Datastore MOR ID.
#
# Side effects:
#      None
#
###############################################################################

sub GetMORId
{
   my $self   = shift;
   my $datastoreMORId;

   my $inlinedatastoreObj = $self->GetInlineDatastoreObj();
   if (!($datastoreMORId = $inlinedatastoreObj->GetMORId())) {
      $vdLogger->Error("Failed to get the Managed Object ID for ".
                   "the datastore: $self->{datastoreName}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the datastore:" .
                $self->{datastoreName} .  " is MORId:". $datastoreMORId);
   return $datastoreMORId;
}

1;
