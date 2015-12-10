#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronVSphereSetupTds;

@ISA = qw(TDS::Main::VDNetMainTds);
#
# This file contains the structured hash for category, Sample tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestConstants;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec qw($OneNeutron_L2L3VSphere_CAT_Setup);
# Import Workloads which are very common across all tests
use TDS::NSX::Neutron::CommonWorkloads ':AllConstants';

#
# Begin test cases
#
{
   %Neutron = (
      'CATSetupSteps' => {
         Component         => "VSM Registration",
         Category          => "Registration",
         TestName          => "CATSetupSteps",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This does CAT SETUP",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["VSMRegistration"],
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
            ],
            "VSMRegistration" => VSM_REGISTRATION,
            "SegmentRangeConfig" => CREATE_SEGMENT_ID_RANGE,
            "MulticastRangeConfig" => CREATE_MULTICAST_IP_RANGE,
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for NeutronTds
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
   my $self = $class->SUPER::new(\%Neutron);
   return (bless($self, $class));
}

1;

