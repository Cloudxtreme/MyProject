##########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
##########################################################################

package VDNetLib::Common::ParseFile;

##########################################################################
#
# This perl package using remoteAgent parses files either locally or
# or files on the remote machine
#
##########################################################################

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use Getopt::Long;
use File::Copy;

# VMware packages
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::RemoteAgent_Storage;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

##########################################################################
# new --
#
# Input:
#	IP - optional, if not given, the method is executed locally
#	file - absolute path of the File name
#
# Results:
#       Returns blessed reference to this class
#
# Side effects:
#       none
#
##########################################################################

sub new
{
   my $proto = shift;
   my $inputParams = shift;
   my $class = ref($proto) || $proto;
   # caller has to instantiate this class with input params like
   # ip and file
   # the original input params are stored in %param, so that way
   # they are restored after calling the remote agent
   my %params = ();
   my @args;
   my $self = {};
   my $remoteAgent = $class;
   my %pkgArgs;

   %params = %$inputParams;

   if (defined $inputParams->{'ip'}) {
      $remoteAgent = 'VDNetLib::Common::RemoteAgent_Storage';
      my $remoteIp = $inputParams->{'ip'};
      $inputParams->{'ip'} = undef;
      %pkgArgs = %$inputParams;
      @args = (remoteIp=>$remoteIp, pkgArgs=>[$inputParams]);
      $self = new VDNetLib::Common::RemoteAgent_Storage(@args);
      if (ref($self) ne "VDNetLib::Common::RemoteAgent_Storage") {
          $vdLogger->Error("Instantiation of RemoteAgent failed");
          VDSetLastError("EINVALID");
          return FAILURE;
      }
   }
   # Copy each key in actual input into $self, which might have been
   # cleared by remoteAgent
   foreach my $key ( keys %params ) {
      $self->{$key} = $params{$key} if not $self->{$key};
   }

   bless $self, $remoteAgent;
   return $self;
}


########################################################################
#
# GetCurrentPos --
#	Checks if exists and opens it and get the current EOF
#
# Input:
#       none
#
# Results:
#       Returns SUCCESS if no error else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub GetCurrentPos
{
   my $self = shift;
      $vdLogger->Debug("Entered GetCurrentPos");

   if (!(-e $self->{file})) {
      $vdLogger->Error("file: $self->{file} doesn't exist");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (!(open(FP, $self->{file}))) {
      $vdLogger->Info("Unable to open file: $self->{file}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   for ($self->{curpos} = tell(FP); $_ = <FP>; $self->{curpos} = tell(FP)) {
   }
   close(FP);
   return $self->{curpos};
}


########################################################################
#
# SearchPattern --
#	Searches pattern and returns the lines matching the pattern
#
# Input:
#       TODO: right now it only takes one pattern later it should
#       take multiple lines and matches all of them in the file
#       Pattern regex
#
# Results:
#       Returns SUCCESS if no error else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub SearchPattern
{
   my $self = shift;
   my $curpos = shift;
   my $pattern = shift;
   my @list;

   $vdLogger->Debug("Entered SearchPattern $pattern $curpos\n");
   if (!open(FP, $self->{file})) {
      $vdLogger->Error("Unable to open file: $self->{file}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # seek to $self->{curpos} first and start searching the for
   # pattern from that position
   if (defined $curpos) {
      seek(FP, $curpos, 0);
   }
   while (<FP>) {
      # TODO: replace the below two lines with
      # if ($_ =~ /$pattern)
      push(@list, $_);
      if (grep (/$pattern/, @list)) {
         close(FP);
         return VDNetLib::Common::GlobalConfig::TRUE;
      }
   }

   return VDNetLib::Common::GlobalConfig::FALSE;
}

1;
