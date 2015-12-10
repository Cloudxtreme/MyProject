#########################################################
# Copyright 2013 VMware, Inc.  All rights reserved.
# VMware Confidential
##########################################################

package VDNetLib::InlinePython::VDNetInterface;
@VDNetLib::InlinePython::VDNetInterface::ISA = qw(Exporter) ;
@EXPORT_OK = qw(CreateInlinePythonObject LoadInlinePythonModule Boolean
                ConfigureLogger CallMethodWithKWArgs ConvertToPythonBool
                ConvertYAMLToHash ConfigureReporter);

use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$FindBin::Bin/../";
use Inline::Python qw(py_bind_class py_eval
                     py_study_package py_call_function
                     py_is_tuple py_call_method);

use VDNetLib::Common::GlobalConfig qw($vdLogger TRUE FALSE);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError
                                   VDGetLastError VDCleanErrorStack);
use constant PY_SUCCESS => "1000";

########################################################################
#
# ConvertToPythonBool--
#     Method to return a suitable type that is interpreted as True/False
#     by python.
#
# Input:
#     attributeValue: Actual boolean value
#
# Results:
#     Interpretable boolean type for Python.
#
# Side effects:
#     None
#
########################################################################


sub ConvertToPythonBool
{
   my $self           = shift;
   my $attributeValue = shift;
   if ($attributeValue) {
      return $Inline::Python::Boolean::true;
   }
   else {
      return $Inline::Python::Boolean::false;
   }
}

########################################################################
#
# CreateInlinePythonObject --
#     Method to create an instance of the given Python class
#
# Input:
#     class : name of the class in the format <moduleName>.<className>
#
# Results:
#     Bless reference to Inline Python object
#
# Side effects:
#     None
#
########################################################################

sub CreateInlinePythonObject
{
   my $class = shift;
   # split the string based on . delimiter
   my @array = split (/\./, $class);
   # get the python class name used for initialization
   my $className = pop @array;
   # construct the string used for importing python module
   my $module = join ('.', @array);
   my $temp;
   $vdLogger->Debug("Loading python $module");
   eval {
      LoadInlinePythonModule($module);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while importing $module");
      $vdLogger->Debug("Error: $@");
      return FALSE;
   }
   my $bindClass = 'VDNetLib::InlinePython::' . $className;
   $vdLogger->Debug("Importing python class $className into perl package $bindClass.");
   eval {
      py_bind_class($bindClass, $module, $className);
      $temp = $bindClass->new(@_);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating instance of ".
                       "$module.$className $@: " . Dumper(@_));
      return FALSE;
   }
   return $temp;
}


########################################################################
#
# Boolean --
#     Utility method to convert given integer to Python boolean value.
#     Perl's 1 and 0 are not equivalent to true and false in Python
#
# Input:
#     value : 1 or 0
#
# Results:
#     if input is 1, Python's 'true' will be returned
#     if input is 0, Python's 'false' will be returned
#
# Side effects:
#     None
#
########################################################################

sub Boolean
{
   my $value = shift;
   if ((defined $value) && ($value)) {
      return $Inline::Python::Boolean::true;
   } else {
      return $Inline::Python::Boolean::false;
   }
}


########################################################################
#
# ConfigureLogger --
#     method to configure logger from Python modules
#
# Input:
#     logDir: absolute path to the log directory
#
# Results:
#     1, if logDir configured successfully;
#     0, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureLogger
{
   my $logDir = shift;
   eval {
      LoadInlinePythonModule("vmware.common.global_config");
      $vdLogger->Debug("Inline logs at $logDir");
      # Configure global logger before anything else as it configures root
      # logger which is also used by MH lib. Once root logger is configured,
      # other loggers can propagate log messages to it as needed.
      py_call_function("vmware.common.global_config", "configure_global_pylogger",
                       $logDir, "pylib", "INFO", "DEBUG", "root");
      py_call_function("vmware.common.global_config", "configure_logger",
                       $logDir, "nsx_sdk", "INFO", "DEBUG");
      # set paramiko logger to critical level and disable stdout logging
      py_call_function("vmware.common.global_config", "configure_logger",
                       $logDir, "paramiko", "CRITICAL", "CRITICAL", undef, undef,
                       Boolean(0));
   };
   if ($@) {
      $vdLogger->Error("Failed to configure InlinePython logger: $@");
      VDSetLastError("EINLINE");
      return 0;
   }
   return 1;
}


########################################################################
#
# LoadInlinePythonModule --
#     Routine to load given Python module
#
# Input:
#     module: name of the module
#
# Results:
#     1, if logDir configured successfully;
#     0, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub LoadInlinePythonModule
{
   my $module = shift;
   eval {
      py_eval(
"try:
    import logging
    import $module
except Exception, e:
    logging.exception(e)
    raise");
   };
   if ($@) {
      $vdLogger->Error("Failed to load module $module: $@");
      return 1;
   }
   return 0;
}


########################################################################
#
# InsertPath --
#     Routine to insert given path to sys.path
#
# Input:
#     path: path to be inserted
#
# Results:
#     1, if logDir configured successfully;
#     0, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub InsertPath
{
   my $path = shift;
   eval {
      py_eval(
"try:
    import sys
    sys.path.insert\(1, \"$path\"\)
except Exception, e:
    print 'ERROR: while inserting $path: %r' % e
    raise");
   };
   if ($@) {
      $vdLogger->Error("Failed to insert path $path: $@");
      return 1;
   }
   return 0;
}


########################################################################
#
# CallMethodWithKWArgs --
#     Routine to call given Python method by passing named parameters
#
# Input:
#     object: reference to the Inline Python object
#     method: name of the method
#     args: reference to hash containing named parameters as key value
#           pairs
#
# Results:
#     returns hash in case of FAILURE
#     returns value/string in case of SUCCESS
#
# Side effects:
#     None
#
########################################################################

sub CallMethodWithKWArgs
{
   my $object = shift;
   my $method = shift;
   my $args   = shift;
   my $result;

   # Get the current working directory to fetch the status_codes
   # from yaml file
   my $cwd = $Bin . '/../pylib/vmware/common/';
   my $StatusCodesFile = $cwd . 'status_codes' . '.' . 'yaml';
   # Convert yaml to perl hash
   my $status_code = ConvertYAMLToHash($StatusCodesFile,
                                       $vdLogger->GetLogDir());

   eval  {
      LoadInlinePythonModule("vmware.common.utilities");
      $vdLogger->Debug("Calling method $method with args:" .
                      Dumper($args));
      # TODO(Prabuddh): Remove this hack and update HandleVerificationKey
      # instead.
      if (scalar(@_)) {
          # If we are here then this implies that we received positional
          # arguments and the last of theses positional arguments is a hash
          # that we need to pass to the python method.
          $result = py_call_function("vmware.common.utilities",
                                     "py_call_method_kwargs",
                                     $object, $method, @_[scalar(@_) - 1]);
      }
      else {
          $result = py_call_function("vmware.common.utilities",
                                     "py_call_method_kwargs",
                                     $object, $method, $args);
      }
   };
   # Check for result as dict
   if (ref($result) eq 'HASH') {
      # Expectation on status_code and exception:
      #      status_code     | exception |  expectation
      #  empty or '' or undef|    N      | return result
      #  empty or '' or undef|    Y      | log.error exc and return failure
      #  SUCCESS or CREATED  |    N      | return result
      #  SUCCESS or CREATED  |    Y      | log.warn exc and return result
      #        others        |    N      | return failure
      #        others        |    Y      | log.error exc and return failure

      $vdLogger->Debug("Python method $method returned: " .
                       (defined $result) ? Dumper($result) : 'None');
      if (not defined $result->{status_code} or
          $result->{status_code} eq '') {
          # Empty cases
          if (defined $result->{exc}) {
              $vdLogger->Error("Exception=" . $result->{exc} .
                               " not expected with empty status_code");
              VDSetLastError($result->{status_code},
                             $result->{response_data},
                             $result->{reason},
                             $result->{exc});
              return FAILURE;
          }
      } elsif ($result->{status_code} eq $status_code->{"SUCCESS"} or
               $result->{status_code} eq $status_code->{"CREATED"}) {
          # Positive cases
          if (defined $result->{exc}) {
              $vdLogger->Warning("Exception=" . $result->{exc} . " not expected
                                 with positive status_code=" . $result->{status_code});
              VDSetLastError($result->{status_code},
                             $result->{response_data},
                             $result->{reason},
                             $result->{exc});
          }
      } else {
          # Negative cases
          if (defined $result->{exc}) {
              $vdLogger->Error("Python method $method returned exception:" .
                               $result->{exc} . " with status_code=" .
                               $result->{status_code});
          }
          VDSetLastError($result->{status_code},
                         $result->{response_data},
                         $result->{reason},
                         $result->{exc});
          return FAILURE;
      }
    }
    return $result;
}

########################################################################
#
# ConvertYAMLToHash
#     Routine to load yaml using python pyYAML loader and convert to PerlHash
#
# Input:
#    yamlFile: full path to the yamlFile
#    logDir: log directory to store the logs and temporary files
#
# Results:
#     FAILURE, in case of error or syntax issues;
#     return perlHash from the yamlFile loaded and all aliases resolved
#
# Side effects:
#     None
#
########################################################################

sub ConvertYAMLToHash
{
   my $yamlFile = shift;
   my $logDir = shift;
   my $loggingEnabled = shift;
   my $perlHash;
   eval {
      LoadInlinePythonModule("vdnet_spec");
      if ($loggingEnabled) {
          $perlHash = py_call_function(
             "vdnet_spec", "configure_logging", $logDir);
      }
      $perlHash = py_call_function(
          "vdnet_spec", "load_yaml", $yamlFile, $logDir);
      };
   if ($@ or !$perlHash) {
      if ($@) {
         $vdLogger->Error("Exception thrown while loading yaml: $@");
      } elsif (!$perlHash) {
         $vdLogger->Error("EmptyHash returned by loading yaml: $perlHash");
      }
      $vdLogger->Debug("Given YAML config: $yamlFile");
      return FAILURE;
   }
   return $perlHash;
}

########################################################################
#
# ConfigureReporter --
#     Method to configure test status reporter on logger for Python modules.
#
# Input:
#     $reporterConfigHandle: handle describing the target reporter, such as
#        Racetrack
#
# Results:
#     TRUE, if reporter configured successfully
#     FALSE, in case of error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureReporter
{
   my $reporterConfigHandle = shift;
   # TODO(jschmidt): The structure for reporter configuration handle is
   # loosely bound throughout the use across implementation languages.
   # Create a single datatype definition and use it everywhere.
   # TODO(jschmidt): Defensive validation of ConfigHandle structure.
   eval {
     $vdLogger->Debug("Configuring reporting handle on logger:\n" .
                  Dumper($reporterConfigHandle));
     LoadInlinePythonModule("vmware.common.reporter");
     py_call_function("vmware.common.reporter", "configure_pylogger_reporter",
                      $reporterConfigHandle);
   };
   if ($@) {
      $vdLogger->Error("Failed to configure test reporter for InlinePython " .
                       "logger:\n" . Dumper($@));
      VDSetLastError("EINLINE");
      return FALSE;
   }
   return TRUE;
}

1;

