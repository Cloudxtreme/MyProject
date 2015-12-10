########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Values::ParentValues;

use strict;
use warnings;
use Data::Dumper;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);
use constant CONSTRAINTSDATABASE => {
   'tags' => {
      'type' => "array",
      'instanceType' => "Tag",
      'goodValue' => [ {
         'value' => ["Tag.goodValue[0]", "Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]"],
         'expectedResult' => "201",
      },
      ],
      'badValue' => [{
         'value' => ["Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]"],
         'expectedResult' => "400",
      },
      ],
   },
   'Tag' => {
      'type' => "object",
      'attributes' => ["tag", "scope"],
      'goodValue' => [
      {
       'value' => {
         "tag" => "tag.goodValue[0]",
         "scope" => "scope.goodValue[0]"
       }
      },
      {
       'value' => {
         "tag" => "tag.goodValue[1]",
         "scope" => "scope.goodValue[1]"
       }
      }
      ],
      'badValue' => [
      {
       'value' => {
         "tag" => "tag.badValue[2]",
         "scope" => "scope.badValue[1]"
       }
      }
      ],
   },
   'scope' => {
      'type' => "attribute",
      'goodValue' => [
         {
          'value' => "TAG12345678912345678",
          'expectedResult' => "201",
          'metadata' => {
             'expectedValue' => 'TAG12345678912345678',
             'id' => undef,
           },
         },
         {
          'value' => undef,
          'expectedResult' => "201",
          'metadata' => {
             'expectedValue' => '',
             'id' => undef,
           },
         },
      ],
      'badValue' => [
         {
          'value' => "TAG123456789123456789",
          'expectedResult' => "400",
          'metadata' => {
             'expectedValue' => 'TAG123456789123456789',
             'id' => undef,
           },
         },
         {
          'value' => 1,
          'expectedResult' => "400"
         },
      ],
   },
   'tag' => {
      'type' => "attribute",
      'goodValue' => [
         {
          'value' => "TAG1234567891234567891234567891234567890",
          'expectedResult' => "201",
          'metadata' => {
             'expectedValue' => 'TAG1234567891234567891234567891234567890',
             'id' => undef,
           },
         },
         {
          'value' => "TAG123456789123456789123456789123456789A",
          'expectedResult' => "201",
          'metadata' => {
             'expectedValue' => 'TAG123456789123456789123456789123456789A',
             'id' => undef,
           },
         },
      ],
      'badValue' => [
         {
          'value' => "TAG12345678912345678912345678912345678901",
          'expectedResult' => "400",
         },
         {
          'value' => "FALSE",
          'expectedResult' => "400"
         },
         {
          'value' => 1,
          'expectedResult' => "400"
         },
         {
          'value' => undef,
          'expectedResult' => "400",
         },
      ],
   },
};

########################################################################
#
#  GetConstraintsTable --
#       This method returns the CONSTRAINTSDATABASE of ParentWorkload
#
# Input:
#
# Results:
#      SUCCESS - returns the CONSTRAINTSDATABASE hash.
#
# Side effetcs:
#       None
#
########################################################################

sub GetConstraintsTable
{
   my $self = shift;
   my $currentPackage;
   my $currentPackageKeysDB;
   my $myparent;
   my $myparentKeysDB;

   if (ref($self)) {
      $self =~ /(.*)\=.*/;
      $currentPackage = $1;
   } else {
     $currentPackage = $self;
   }

   # Finding current package's parent
   my @temp = eval "@" . $currentPackage . "::"."ISA";
   $myparent = pop(@temp) if scalar(@temp) > 0;
   if ((defined $myparent) && ($myparent =~ /\w+/)) {
      $myparentKeysDB = $myparent->GetConstraintsTable();
      $currentPackageKeysDB = eval "$currentPackage" ."::" . 'CONSTRAINTSDATABASE';
      foreach my $key (keys %$myparentKeysDB){
         if (!exists $currentPackageKeysDB->{$key}) {
            $currentPackageKeysDB->{$key} = $myparentKeysDB->{$key};
         }
      }
      $vdLogger->Trace("Merged CONSTRAINTSDATABASE of parent:$myparent and ".
                   "child:$currentPackage ");
   } else {
       return eval "$currentPackage" . "::" . 'CONSTRAINTSDATABASE';
   }

   return $currentPackageKeysDB;
}
1;
