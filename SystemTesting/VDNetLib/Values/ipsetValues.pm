########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################


package VDNetLib::Values::ipsetValues;

use strict;
use warnings;
# Inherit the parent class.

use base qw(VDNetLib::Values::NSXValues);

use constant CONSTRAINTSDATABASE => {
   'ipset' => {
      'type' => "object",
      'attributes' => ["value", "name"]
   },
   'value' => {
      'type' => "attribute",
      'goodValue' => [
         {
          'value' => "192.168.0.1",
          'metadata' => {
            'expectedvalue' => "192.168.0.1",
            'expectedresultcode' => "201",
            'keyundertest' => "value",
          },
         },
       ],
       'badValue' => [
         {
          'value' => 1,
          'metadata' => {
            'expectedresultcode' => "400",
          },
         },
       ],
   },
 };

########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Values::ipsetValues
#      class.
#
# Input:
#      None
#
# Results:
#      Returns a VDNetLib::Values::ipsetValues object, if successful;
#
# Side effects:
#      None
#
########################################################################

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
