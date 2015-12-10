#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Sample::TestEsxTds;

#
# This file contains the structured hash for category, Sample testesx tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("testcase1", "testcase2");

   %TestEsx = (
      'testcase1' => {
         Component         => "Test Esx",
         Category          => "Esx Server",
         TestName          => "testcase1",
         Summary           => "Running vmktest-required.sh script",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
            helper1     => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['TestEsx_1']],
            Duration          => "time in seconds",

            "TestEsx_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestEsx        => "-S -n net/vmknet-required.sh",
            },

         },
      },

      'testcase2' => {
         Category          => "Esx Server",
         Component         => "Test Esx",
         TestName          => "testcase2",
         Summary           => "Running vmknet-testesx.py script",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
            helper1     => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['TestEsx_2']],
            Duration          => "time in seconds",

            "TestEsx_2" => {
               Type           => "Host",
               Target         => "SUT",
               TestEsx        => "-S -n net/vmknet-testesx.py ",
            },
         },
      },

    );
}


########################################################################
#
# new --
#       This is the constructor for SampleTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleTds class
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
   my $self = $class->SUPER::new(\%TestEsx);
   return (bless($self, $class));
}

1;
