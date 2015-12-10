package VDNetLib::Values::transportzoneValues;

use strict;
use warnings;
# Inherit the parent class.

use base qw(VDNetLib::Values::NSXValues);

use constant CONSTRAINTSDATABASE => {
   'transportzone' => {
      'type' => "object",
      'attributes' => ["name", "tags"],
      'goodValue' => [
        {'value' => {
          "tags" => "tags.goodValue[0]",
          "name" => "name.goodValue[1]"
         },
        },
      ],
      'badValue' => [
        {'value' => {
          "tags" => "tags.goodValue[0]",
          "name" => "name.badValue[1]"
        }
       }
      ],
   },
   'name' => {
      'type' => "attribute",
      'goodValue' => [
         {
          'value' => 'TZ1',
          'metadata' => {
             'expectedvalue' => 'TZ1',
             'expectedresultcode' => '201',
             'id' => undef,
             'keyundertest' => 'display_name',
             },
         },
         {
          'value' => 'T123456789012345678901234567890123456789',
          'metadata' => {
             'expectedvalue' => 'T123456789012345678901234567890123456789',
             'expectedresultcode' => '201',
             'id' => undef,
             'keyundertest' => 'display_name',
             },
         },
         {
          'value' => undef,
          'metadata' => {
             'expectedvalue' => undef,
             'expectedresultcode' => '201',
             'id' => undef,
             'keyundertest' => 'display_name',
             },
         },
      ],
      'badValue' => [
         {
          'value' => 'T1234567890123456789012345678901234567890'.
                     'T1234567890123456789012345678901234567890'.
                     'T1234567890123456789012345678901234567890'.
                     'T1234567890123456789012345678901234567890'.
                     'T1234567890123456789012345678901234567890'.
                     'T1234567890123456789012345678901234567890'.
                     'T1234567890',
          'metadata' => {
             'expectedresultcode' => '400',
          },
         },
         {
          'value' => 1,
          'metadata' => {
             'expectedresultcode' => '400',
          },
         },
      ],
   },
   'tags' => {
      'type' => "array",
      'instanceType' => "Tag",
      'goodValue' => [ {
         'value' => ["Tag.goodValue[0]", "Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]"],
          'metadata' => {
             'expectedresultcode' => '201',
          },
      },
      ],
      'badValue' => [{
         'value' => ["Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]","Tag.goodValue[0]"],
          'metadata' => {
             'expectedresultcode' => '400',
          },
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
       },
        'metadata' => {
             'expectedresultcode' => '201',
          },
      },
      {
       'value' => {
         "tag" => "tag.goodValue[1]",
         "scope" => "scope.goodValue[1]"
       },
        'metadata' => {
             'expectedresultcode' => '201',
          },
      }
      ],
      'badValue' => [
      {
       'value' => {
         "tag" => "tag.badValue[2]",
         "scope" => "scope.badValue[1]"
       },
       'metadata' => {
             'expectedresultcode' => '400',
          },
      }
      ],
   },
   'scope' => {
      'type' => "attribute",
      'goodValue' => [
         {
          'value' => "TAG12345678912345678",
          'metadata' => {
             'expectedresultcode' => '201',
             'id' => undef,
           },
         },
         {
          'value' => undef,
          'metadata' => {
             'expectedvalue' => '',
             'expectedresultcode' => '201',
             'id' => undef,
           },
         },
      ],
      'badValue' => [
         {
          'value' => "TAG123456789123456789",
          'metadata' => {
             'expectedvalue' => 'TAG123456789123456789',
             'expectedresultcode' => '400',
             'id' => undef,
           },
         },
         {
          'value' => 1,
          'metadata' => {
             'expectedresultcode' => "400"
           },
         },
      ],
   },
   'tag' => {
      'type' => "attribute",
      'goodValue' => [
         {
          'value' => "TAG1234567891234567891234567891234567890",
          'metadata' => {
             'expectedvalue' => 'TAG1234567891234567891234567891234567890',
             'expectedresultcode' => '201',
             'id' => undef,
           },
         },
         {
          'value' => "TAG123456789123456789123456789123456789A",
          'metadata' => {
             'expectedvalue' => 'TAG123456789123456789123456789123456789A',
             'id' => undef,
             'expectedresultcode' => '201',
           },
         },
      ],
      'badValue' => [
         {
          'value' => "TAG12345678912345678912345678912345678901".
                     "TAG12345678912345678912345678912345678901".
                     "TAG12345678912345678912345678912345678901".
                     "TAG12345678912345678912345678912345678901".
                     "TAG12345678912345678912345678912345678901".
                     "TAG12345678912345678912345678912345678901".
                     "0123456789",
          'metadata' => {
            'expectedresultcode' => "400",
          },
         },
         {
          'value' => "FALSE",
          'metadata' => {
            'expectedresultcode' => "400",
          },
         },
         {
          'value' => 1,
          'metadata' => {
            'expectedresultcode' => "400",
          },
         },
         {
          'value' => undef,
          'metadata' => {
            'expectedresultcode' => "400",
          },
         },
      ],
   },
};

sub new
{
   my $class = shift;
   my $self = {};
   bless($self, $class);

   # Adding Constraint Database

   $self->{constraintValue} = $self->GetConstraintsTable();

   return $self;
}
1;
