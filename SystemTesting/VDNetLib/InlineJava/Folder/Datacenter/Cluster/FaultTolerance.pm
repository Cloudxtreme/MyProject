###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Folder::Datacenter::Cluster::FaultTolerance;

#
# This class captures all common methods to configure or get information
# of FaultTolerance. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with Cluster.
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                            InlineExceptionHandler);

use constant TRUE  => 1;
use constant FALSE => 0;


########################################################################
#
# new--
#     Constructor for this class VDNetLib::InlineJava::FaultTolerance
#
# Input:
#     Named value parameters with following keys:
#     anchor      : connection anchor  (Mandtory)
#
# Results:
#     An object of VDNetLib::InlineJava::Cluster class if successful;
#     0 in case of any error;
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
   $self->{'anchor'}  = $options{'anchor'};

   if (not defined $self->{'anchor'}) {
      $vdLogger->Error("Connect anchor not provided as parameter");
      return FALSE;
   }

   eval {
      $self->{'FTHelper'} = CreateInlineObject(
			       "com.vmware.vcqa.vim.FaultToleranceHelper",
			       $self->{'anchor'});
      $self->{'FTConfigSpec'} = CreateInlineObject(
                              "com.vmware.vc.FaultToleranceConfigSpec");
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::FaultTolerance object");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# CreateFaultToleranceConfigSpec--
#
# Input:
#
# Results:
#     TRUE, if success
#     FALSE, on any exceptions;
#
# Side effects:
#     None
#
########################################################################

sub CreateFaultToleranceConfigSpec
{
   return undef;
}

1;
