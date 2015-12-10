########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::InlinePython::IOUtility;

use strict;
use warnings;
use Data::Dumper;
use vars qw{$AUTOLOAD};
use Storable 'dclone';

use Inline::Python qw(eval_python
                     py_bind_class
		     py_eval
                     py_study_package
		     py_call_function
		     py_call_method
                     py_is_tuple);

use VDNetLib::Common::GlobalConfig qw ($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use constant TRUE  => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;

########################################################################
#
# IOToolMap
#     Method to return the information about a tool such
#     as Python Class
#
# Input:
#     toolname: name of the tool
#
# Results:
#     Reference to a hash which contains information about the tool
#
# Side effects:
#     None
#
########################################################################

sub IOToolMap
{
   my $toolName      = shift;
   my $toolMappingHash = {
      'dt'   => {
         'pythonClass'  => 'dt.DTTool',
      },
   };
   return $toolMappingHash->{$toolName};
}


########################################################################
#
# CreatePyIOSession
#     Method to create python session object. This
#     method invokes Py layer's base_disk_io_session
#
# Input:
#     processedSpecs : hash containing toolname and other tool details
#
# Results:
#     Python object, if successful;
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub CreatePyIOSession
{
   my %args       = @_;
   my $toolName   = $args{toolname};
   if ((not defined $toolName)) {
      $vdLogger->Error("ToolName not given in CreateNetworkStorageSession()");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $toolInfo = VDNetLib::InlinePython::IOUtility::IOToolMap($toolName);
   my $toolClass = $toolInfo->{'pythonClass'};
   $vdLogger->Debug("Creating python obj for $toolClass with:" . Dumper(%args));
   my $inlinePyObj = CreateInlinePythonObject($toolClass,
                                             \%args);
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object for $toolClass");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}

1;
