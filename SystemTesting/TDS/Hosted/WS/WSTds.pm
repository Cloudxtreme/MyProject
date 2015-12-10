#!/usr/bin/perl
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Hosted::WS::WSTds;

use FindBin;
use lib "$FindBin::Bin/..";
use Data::Dumper;
use TDS::Main::VDNetMainTds;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ();
   %WorkStation = (
   );
}
########################################################################
#
# new --
#       This is the constructor for WorkStation
#
# Input:
#       none
#
# Results:
#       An instance/object of WorkStation class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%WorkStation);
   return (bless($self, $class));
}
1;
