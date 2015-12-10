#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronVSphereRealizationTds;

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
      'TZRealization' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-vSphere",
         TestName          => "TZRealization",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case creates a Transport Cluster on Neutron to realize a TZ on VSM",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                ["VSMRegistration"],
                ["TransportZoneCreation"],
                ["LogicalSwitchCreation"],
                ["TransportClusterCreation"],
                ["CheckTZRealization"],
                ["CheckLSRealization"],
            ],
            ExitSequence => [
                ["DeleteLogicalSwitch"],
                ["DeleteTransportCluster"],
                ["DeleteTransportZone"],
            ],
            "VSMRegistration" => VSM_REGISTRATION,
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "CheckTZRealization" => {
                Type          => "TransportZone",
                TestTransportZone       => "neutron.[1].transportzone.[1]",
                checkifrealized => "vsm.[-1].networkscope.[]",
            },
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
             "CheckLSRealization" => {
                Type          => "Switch",
                TestSwitch       => "neutron.[1].logicalswitch.[1]",
                checkifrealized => "vsm.[-1].networkscope.[].virtualwire.[]",
                expectedresult => "FAILURE",
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
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

