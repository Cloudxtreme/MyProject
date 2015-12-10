########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Common::Parsers;

use Inline::Python qw(py_eval py_new_object py_call_method);


########################################################################
#
# ParseHorizontalTable
#       Parses horizontal table. This is a wrapper around python
#       implementation.
#
# Input:
#       Refer to pylib/vmware/parsers/horizontal_table_parser.py API.
#       Note that the arguments that python method accepts are passed
#       as positional arguments from this wrapper method.
#
# Results:
#       An array of hashes of formatted data. FAILURE in case of errors.
#
# Side effects:
#       None
#
########################################################################

sub ParseHorizontalTable
{
   my $pyModule = "pylib.vmware.parsers.horizontal_table_parser";
   my $pyClass = "HorizontalTableParser";
   my $pyParserObj = undef;
   my $result = undef;
   eval {
      py_eval("import $pyModule");
      $pyParserObj = py_new_object(
         "VDNetLib::InlinePython::$pyClass", $pyModule, $pyClass);
      $result = py_call_method($pyParserObj, "get_parsed_data", @_);
   };
   if ($@) {
      $vdLogger->Error("Failed to parse the data, error: $@");
      return FAILURE;
   }
   if (ref($result) ne "HASH") {
      $vdLogger->Error("Expected the parsed data to be in HASH format");
      return FAILURE;
   }
   return $result->{'table'};
}


########################################################################
#
# ParseTorEmulatorOutput
#       Parses tor emulator cli output. This is a wrapper around python
#       implementation.
#
# Input:
#       Refer to pylib/vmware/parsers/tor_emulator_parser.py API.
#       Note that the arguments that python method accepts are passed
#       as positional arguments from this wrapper method.
#
# Results:
#       An array of hashes of formatted data. FAILURE in case of errors.
#
# Side effects:
#       None
#
########################################################################

sub ParseTorEmulatorOutput
{
   my $pyModule = "pylib.vmware.parsers.tor_emulator_parser";
   my $pyClass = "TorEmulatorParser";
   my $pyParserObj = undef;
   my $result = undef;
   eval {
      py_eval("import $pyModule");
      $pyParserObj = py_new_object(
         "VDNetLib::InlinePython::$pyClass", $pyModule, $pyClass);
      $result = py_call_method($pyParserObj, "get_parsed_data", @_);
   };
   if ($@) {
      $vdLogger->Error("Failed to parse the data, error: $@");
      return FAILURE;
   }
   if (ref($result) ne "HASH") {
      $vdLogger->Error("Expected the parsed data to be in HASH format");
      return FAILURE;
   }
   return $result;
}
1;
