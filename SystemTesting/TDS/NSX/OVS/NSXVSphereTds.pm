#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::OVS::NSXVSphereTds;

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
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

#
# Begin test cases
#
{
   %NSXVSphere = (
      'BasicController' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "BasicController",
         Version          => "2" ,
         Summary          => "This is the precheck-in unit test case for NVS " .
                             "with controller ",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::nvpWithNoVCTopology01,
         'WORKLOADS' => {
            'Sequence' => [
               ['SetController'],
               ['AddUplinkOnHost1', 'AddUplinkOnHost2'],
               ['EditUplinkOnHost1','EditUplinkOnHost2'],
               ['CreateTZ'],
               ['CreateTN1'],
               ['CreateTN2'],
               ['CreateLS'],
               ['CreateLP1'],
               ['CreateLP2'],
               ['Traffic'],
               ['Traffic'],
            ],
            ExitSequence => [
              ['RemoveUplinkIPOnHost1', 'RemoveUplinkIPOnHost2'],
              ['RemoveUplinkOnHost1', 'RemoveUplinkOnHost2'],
              ['DeleteTZ'],
            ],
           'Traffic' => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               NoofOutbound      => "1",
               NoofInbound       => "1",
               TestDuration   => "10",
           },
            'RemoveUplinkIPOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkIPOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "remove",
            },
            'RemoveUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "remove",
            },
            'AddUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "add",
            },
            'AddUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "add",
            },
            'EditUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'EditUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            SetController => {
               Type  =>"Switch",
               TestSwitch => "host.[1-2].ovs.[1]",
               ConfigureController => "set",
               controller => "nvpcontroller.[1]"
            },
            "CreateTZ" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_$$",
                     transport_zone_type   => "stt",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_$$"
                     },
                  },
               },

               'sleepbetweencombos' => '10',
            },
            "CreateTN1" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               'sleepbetweenworkloads' => '30',
               transportnode  => {
                  '[1]' => {
                     name => "Host1",
                     credential  =>  {
                        mgmtaddress   => "host.[1]",
                        type          => "MgmtAddrCredential",
                     },
                     transport_connectors  => [
                        {
                           transport_zone_uuid => "nvpcontroller.[1].transportzone.[1]",
                           ip_address => "host.[1].vmnic.[1]",
                           type => "STTConnector",
                        },
                     ],
                     integration_bridge_id  => "br-int",
                  },
               },
            },
            "CreateTN2" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               'sleepbetweenworkloads' => '30',
               transportnode  => {
                  '[2]' => {
                     name => "Host2",
                     credential  =>  {
                        mgmtaddress  => "host.[2]",
                        type         => "MgmtAddrCredential",
                     },
                     transport_connectors  => [
                        {
                           transport_zone_uuid => "nvpcontroller.[1].transportzone.[1]",
                           ip_address => "host.[2].vmnic.[1]",
                           type => "STTConnector",
                        },
                     ],
                     integration_bridge_id  => "br-int",
                  },
               },
            },
            "CreateLS" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               logicalswitch  => {
                  '[1]' => {
                     transportzones => [
                        {
                           'zone_uuid' => "nvpcontroller.[1].transportzone.[1]",
                           'transport_type' => 'stt',
                        },
                     ],
                     replicationmode => "source",
                     name      => "ls_$$",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "ls_$$"
                     },
                  }
               },
            },
            "CreateLP1"  => {
               Type  => "Switch",
               TestSwitch  => "nvpcontroller.[1].logicalswitch.[1]",
               logicalport => {
                  '[1]' => {
                     name  => "lp_$$",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "lp_$$"
                     },
                      attachment  => {
                         type  => 'VifAttachment',
                         vifuuid => "vm.[1].vnic.[1]",
                      },
                  },
               },
            },
            "CreateLP2"  => {
               Type  => "Switch",
               TestSwitch  => "nvpcontroller.[1].logicalswitch.[1]",
               logicalport => {
                  '[1]' => {
                     name  => "lp_$$",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "lp_$$"
                     },
                      attachment  => {
                         type  => 'VifAttachment',
                         vifuuid => "vm.[2].vnic.[1]",
                      },
                  },
               },
            },
            "DeleteTZ"  => {
               Type  => "NSX",
               TestNSX  => "nvpcontroller.[1]",
               deletetransportzone => "nvpcontroller.[1].transportzone.[1]",
               deletetransportnode => "nvpcontroller.[1].transportnode.[1-2]",
               deletelogicalswitch  => "nvpcontroller.[1].logicalswitch.[1]"
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for OVSTds
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
   my $self = $class->SUPER::new(\%NSXVSphere);
   return (bless($self, $class));
}

1;

