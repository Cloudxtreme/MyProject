#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::N1KV::N1KVTds;

#
# This file contains the structured hash for category, N1KV tests
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
   @TESTS = ("N1KVAPI");

   %N1KV = (
      'N1KVAPI' => {
         Component         => "N1KV",
         Category          => "Esx Server",
         TestName          => "N1KVAPI",
         Summary           => "Running N1KV vDS API script",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['N1KV_VDS_API']],
            Duration          => "time in seconds",

            "N1KV_VDS_API" => {
               Type           => "Host",
               Target         => "SUT",
               TestEsx        => "S -n vmkapi/vmkapi-net-vds.sh",
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
   my $self = $class->SUPER::new(\%N1KV);
   return (bless($self, $class));
}

1;
