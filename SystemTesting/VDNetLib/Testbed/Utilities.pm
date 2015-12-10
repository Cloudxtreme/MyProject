########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Testbed::Utilities;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   ABORT VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT $sshSession);

use Inline::Python qw(eval_python
                     py_bind_class
		     py_eval
                     py_study_package
		     py_call_function
		     py_call_method
                     py_is_tuple);
py_eval('import pickle');

########################################################################
#
# TrimTestbedObject --
#     This method optimizes the data being stored in zookeeper node.
#     For example, if host object is an attribute of netadapter object,
#     then skip storing serialized host object and keep only the
#     pointer to host object node
#
# Input:
#     value : reference to vdnet core object
#     clean : boolean to remove redundant attributes of an object
#
# Results:
#     reference to a new/trimmed object
#
# Side effects:
#     This trimmed object is only to be used for storing on zookeeper.
#     Trying to use it as regular object may not give desired results
#
########################################################################

sub TrimTestbedObject
{
   my $value = shift;
   my $clean = shift;
   $clean = (defined $clean) ? $clean : 0;

   my $tempValue = {%$value};

   if (($tempValue !~ /HASH/) ||
      (not defined $tempValue->{objID})) {
      return $value;
   }
   my ($className, $varType) = split(/=/, $value);
   bless $tempValue, $className; # bless every copy of blessed hash
   return $tempValue if ($className =~ /InlineJava/i);
   foreach my $attribute (keys %$tempValue) {
      if ((not defined $tempValue->{$attribute})) {
         delete $tempValue->{$attribute} if ($clean);
      } elsif (($tempValue->{$attribute} =~ /HASH/) &&
               ($tempValue->{$attribute} !~ /InlineJava/i) &&
               (defined $tempValue->{$attribute}{objID})) {
         # process only vdnet core objects
         $tempValue->{$attribute} = VDNetLib::Testbed::Utilities::TrimTestbedObject(
                                          $tempValue->{$attribute},
                                          1);
      } elsif (($attribute ne "objID") &&
         ($tempValue->{$attribute} !~ /InlineJava/i) &&
         ($clean)) {
         delete $tempValue->{$attribute};
      } elsif ($tempValue->{$attribute} =~ /InlineJava/i) {
         $vdLogger->Warn("Remove attribute $attribute from $tempValue");
      }
   }
   if (defined $tempValue->{stafHelper}) {
      $tempValue->{stafHelper} = undef;
   }
   return $tempValue;
}


########################################################################
#
# SerializePerlObj
#     This method serializes perl object
#
# Input:
#     value : reference to perl object
#
# Results:
#     string containging serialzed object
#
# Side effects:
#
########################################################################

sub SerializePerlObj
{
   my $value = shift;
   my $trimmedValue = VDNetLib::Testbed::Utilities::TrimTestbedObject($value);
   my $dumper = new Data::Dumper([$trimmedValue]);
   $dumper->Terse(1);
   $dumper->Deepcopy(1);
   $dumper->Deparse(1);
   $dumper->Maxdepth(5);
   $dumper->Purity(1);
   return $dumper->Dump();
}


########################################################################
#
# SerializePerlDataStructure
#     This method serializes perl datastructure
#
# Input:
#     value : reference to perl datastructure
#
# Results:
#     string containging serialzed datastructure
#
# Side effects:
#
########################################################################

sub SerializePerlDataStructure
{
   my $value = shift;
   my $dumper = new Data::Dumper([$value]);
   $dumper->Indent(0);
   # If Terse(0) is used then $VAR1 also
   #  get stored in the file.
   $dumper->Terse(1);
   $dumper->Quotekeys(0);
   Serialized data is ready
   return $dumper->Dump();
}


########################################################################
#
# SerializePythonObj
#     This method serializes python object
#
# Input:
#     value : reference to python object
#
# Results:
#     string containging serialzed object
#
# Side effects:
#
########################################################################

sub SerializePythonObj
{
   my $value = shift;
   eval {
      return py_call_function("pickle", "dumps", $value);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while Serializing Python Objinstance");
      $vdLogger->Debug("obj:" . Dumper($value) ." Error:$@");
      return FAILURE;
   }
}


########################################################################
#
# ConvertVdnetIndexToPath
#     Convert Vdnet Index (tuple form) To path form. Replace brackets
#     with slashes.
#
# Input:
#     $tuple    : vdnet index
#
# Results:
#     returns string where brackets are replaced with slashes.
#
# Side effects:
#     None
#
########################################################################

sub ConvertVdnetIndexToPath
{
   my $tuple = shift;

   $tuple =~ s/\[|\]//g;
   $tuple =~ s/\.x\.x$//g;
   $tuple =~ s/[\.]/\//g;
   return $tuple;
}

1;
