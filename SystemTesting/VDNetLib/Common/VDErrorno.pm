########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Common::VDErrorno;

########################################################################
# This package imitates error reporting in Win32::API.
# Some of the error codes are imported from errno.h. Customized error codes
# used in VD automation can be added here.
# In addition to storing the last error occured, VDSetLastError() prepends
# error to the global variable $ERRSTRING.
#
# The stack of error messages will be cleared when VDGetLastError() is called
# by any application (which is not a package). But, when called by sub-routines
# in a package, the error buffer ($ERRSTRING) will not be cleared.
#
# Instructions -
# Adding the new error codes in alphabetical order would help reading.
########################################################################

use FindBin qw($Bin);
use lib "$FindBin::Bin/../";
use base 'Exporter';
use File::Basename;
use strict;
use warnings;

# Applications using this package must explicitly import
# the modules VDGetLastError() and VDSetLastError()

our @EXPORT = qw( FAILURE SUCCESS ABORT SKIP CONTINUE SUCCESS_OR_FAILURE
                  VDSetLastError VDGetLastError VDCleanErrorStack
                  VDGetAllErrors IsFailure);

use constant FAILURE => "FAILURE";
use constant SUCCESS => "SUCCESS";
use constant ABORT   => "ABORT";
use constant SKIP    => "SKIP";
use constant CONTINUE => "CONTINUE";
use constant SUCCESS_OR_FAILURE => "(SUCCESS|FAILURE)";
use vars qw( $ERRSTRING );
my $ERRSTRING = ''; # Initialize error buffer
my %errorHash = (
   "EFAIL" => "Generic Error",
   "EHOSTUNREACH" => "Host is unreachable",
   "EINVALCMD" => "Invalid Command",
   "EINVALIDERR" => "Error code not defined",
   "EINVALID" => "Invalid data",
   "ELOADMOD" => "Module failed to load",
   "EMISMATCH" => "Data mismatch occurred after set operation",
   "ENETDOWN" => "Network is down",
   "ENETRESET" => "Connection aborted by network",
   "ENODEV" => "No such device",
   "ENOENT" => "No such file or directory",
   "ENOTDEF" => "Data not defined",
   "ENOTIMPL" => "Not Implemented",
   "ENOTSUP" => "Operation not supported",
   "EOPFAILED" => "Operation failed",
   "EOSNOTSUP" => "Operating system not supported",
   "EPERM" => "Operation not permitted",
   "ESTAF" => "STAF error",
   "ETIMEDOUT" => "Connection timed out",
   "EMOUNT" => "Mount Point doesn't exist",
   "ECMD" => "Shell Command failed with error",
   "EINLINE" => "VDNet Inline Java related error",
   "EATS"    => "Error related to ATS test framework",
   "ERUNTIMEERROR"  => "This error shall be only set in case of a " .
                       "infratsructure error" ,
   "EOPVERIFY" => "Verification failed",
   "ESESSION" => "Session failure",
  );

# All the errors reported will be
# stored in this array
my @RESULTARRAY = qw//;

use constant STATUS_CODES => "/../pylib/vmware/common/status_codes.yaml";
use constant TRUE  => 1;
use constant FALSE => 0;

#######################################################################
# VDSetLastError --
#       This module sets the formatted error description in the global variable
#       $ERRORSTRING. If $ERRSTRING has already some error information in it,
#       then this function will prepend the new formatted error message to
#       $ERRSTRING. Users can pass any of the error codes mentioned in
#       %errorhash or formatted error message from VDGetLastError() call.
#
# Input:
#       Error codes mentioned in %errorhash or formatted error message from
#       VDGetLastError() call. (Required)
#
# Results:
#       If the error code passed to this module is invalid, formatted
#       error description of EINVALIDERR will be stored in $ERRSTRING.
#       Otherwise, formatted error description corresponding
#       to the value defined in %errorHash will be stored in $ERRSTRING
#
# Side effects:
#       None.
#
#######################################################################

sub VDSetLastError
{
   my $rawInput      = shift;
   my $response_data = shift;
   my $reason        = shift;
   my $error         = shift;
   my $inputErr      = $rawInput;

   my $resultHash;
   # FIXME(Prabuddh): This should never happen, but is added to have backward
   # compatibility where VDSetLastError(VDGetLastError()) is called, which is
   # no-op with the new implementation
   if ((defined $rawInput) && (ref($rawInput) eq 'HASH')) {
      push @RESULTARRAY, $rawInput;
   } else {
      if ((defined $rawInput) || (defined $error)) {
         $resultHash->{status_code} = $rawInput;
         $resultHash->{error} = $error;
         $resultHash->{reason} = $reason;
         $resultHash->{response_data} = $response_data;
         push @RESULTARRAY, $resultHash;
      }
   }
   return 0;
}

#######################################################################
# VDGetLastError --
#       This module returns the last updated value of the global variable
#       $ERRSTRING. If this function is called by any sub-routines that is part
#       of a package, then $ERRSTRING will not be cleared. But when an
#       application calls this function, $ERRSTRING will be cleared
#
# Input:
#       None
#
# Results:
#       If the error code passed to this module is invalid, error description
#       of EINVALIDERR will be returned.
#       Otherwise, formatted error description corresponding to the value
#       defined in %errorHash will be returned
#
# Side effects:
#       None.
#
########################################################################

sub VDGetLastError
{
   my $resultHash = $RESULTARRAY[-1];
   if (not defined $resultHash) {
      # error stack is emtpy
      return undef;
   }
   return $resultHash;
}


#######################################################################
# VDGetAllError --
#       This module returns the entire error stack.
#
# Input:
#       None
#
# Results:
#       return reference to array of hashes @RESULTARRAY
#
# Side effects:
#       None.
#
########################################################################

sub VDGetAllErrors
{
   return \@RESULTARRAY;
}

########################################################################
#
# VDCleanErrorStack --
#      Clears the variable $ERRSTRING that stores the error stack.
#
# Input:
#      None
#
# Results:
#      None
#
# Side effects:
#      The entire error stack for the process in which vdError package
#      is loaded will be deleted.
#
########################################################################

sub VDCleanErrorStack
{
   @RESULTARRAY = qw//;
}


#####################################################################
#
# GetStatusCodes --
#    This method is used to fetch the status_code
#
# Input:
#    None
#
# Results:
#    Returns status code hash
#
# Side effects:
#     None
#
#######################################################################

sub GetStatusCodes
{
   my $self = shift;
   my $fileCurrent = $Bin . STATUS_CODES;

   # Convert yaml to perl hash
   my $statusCode = VDNetLib::Common::Utilities::ConvertYAMLToHash($fileCurrent);
   return $statusCode;
}


#######################################################################
# IsFailure --
#       This function checks if a variable is string "FAILURE", if yes
#       returns TRUE. If not, returns FALSE;
#
# Input:
#       $input: Input variable
#
# Results:
#       Returns TRUE if $input equals FAILURE.
#       Returns FALSE if else
#
# Side effects:
#       None.
#
########################################################################

sub IsFailure
{
   my $input = shift;
   if (not defined $input) {
      return FALSE;
   }
   if ($input eq FAILURE) {
      return TRUE;
   }
   return FALSE;
}

1;
