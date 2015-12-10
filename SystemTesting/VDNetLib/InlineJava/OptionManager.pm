###############################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::OptionManager;

#
# This class captures all operations that involves the managed object
# "OptionManager"
# This package mainly uses VDNetLib::InlineJava::VDNetInterface class to
# interact with VC.
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
#     Constructor for this class VDNetLib::InlineJava::OptionManager
#
# Input:
#     sessionObj  : VDNetLib::InlineJava::Session Object (Required)
#
# Results:
#     An object of VDNetLib::InlineJava::GenericVCOps class if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class   = shift;
   my %options = @_;

   my $self;
   $self->{'sessionObj'} = $options{'sessionObj'};

   if (not defined $self->{'sessionObj'}) {
      $vdLogger->Error("VDNetLib::InlineJava::Session object not provided");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# UpdateVPXDConfigValue--
#     Method to update VPXD configuration values in the given VC
#
# Input:
#     key   : configuration/key to be updated (Required)
#     value : value to updated for the given key (Required)
#
# Results:
#     1 - if the given key is updated successfully;
#     0 - in case of any error/exception
#
# Side effects:
#     check the documentation on the configuration/key being updated
#
########################################################################

sub UpdateVPXDConfigValue
{
   my $self = shift;
   my $key  = shift;
   my $value = shift;

   if ((not defined $key) || (not defined $value)) {
      $vdLogger->Error("VPXD key and/or value to be updated is not provided");
      return FALSE;
   }

   my $anchor = $self->{'sessionObj'}{'anchor'};

   eval {
      my $optionMgrObj = CreateInlineObject("com.vmware.vcqa.vim.option.OptionManager",
                                            $anchor);

      my $optionMgrMor = $optionMgrObj->getOptionManager();

      $optionMgrObj->updateVpxdCfgValue($optionMgrMor, $key, $value);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to update vpxd configuration $key " .
                       "with value $value");
      return FALSE;
   }

   $vdLogger->Debug("VPXD configuration $key successfully updated with " .
                    "value $value");
   return TRUE;
}


########################################################################
#
# GetVPXDConfigValue--
#     Method to get configured value of the given VPXD option
#
# Input:
#     key : name of the configuration/key (Required)
#
# Results:
#     configured value (string) in case of success;
#     0 - in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetVPXDConfigValue
{
   my $self = shift;
   my $key  = shift;

   if (not defined $key) {
      $vdLogger->Error("VPXD configuration key is not provided");
      return FALSE;
   }

   my $value = undef;
   my $anchor = $self->{'sessionObj'}{'anchor'};

   eval {
      my $optionMgrObj = CreateInlineObject("com.vmware.vcqa.vim.option.OptionManager",
                                            $anchor);

      my $optionMgrMor = $optionMgrObj->getOptionManager();
      $value = $optionMgrObj->getOptionValue($optionMgrMor, $key);
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $value;
}
1;
