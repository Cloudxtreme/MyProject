#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::VDR::VDRTds;

#
# This file contains the structured hash for VDR TDS.
# The following lines explain the keys of the internal
# hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %VDR = (
      'CreateDeleteVDRInstance'   => {
         TestName         => 'CreateDeleteVDRInstance',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that VDR instance can be created ' .
                             'and deleted ',
         Procedure        => '1. Create a VDR instance on a host ' .
                             '2. Verify the instance is created successfully'.
                             '3. Delete the VDR created in step 1 ' .
                             '4. Verify the instance is deleted successfully',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  'vdr' => {
                     '[1]' => {
                        'vdrname' => "testbed-$$",
                     },
                     '[2]' => {
                     },
                     '[3]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Iterations     => "2", # TODO: make it 100
            Sequence       => [
                               ['AddInstance'],
                               ['DeleteInstance']
                              ],

            "AddInstance" => {
               Type         => "Host",
               Testhost     => "host.[1]",
               'vdr' => {
                  '[5]' => {
                     'vdrname' => "CreateDeleteVDRInstance-$$",
                  },
                  '[6]' => {
                     'vdrname' => "CreateDeleteVDRInstance2-$$",
                  },
                  '[7-8]' => {
                  },
               },
            },
            "DeleteInstance" => {
               Type         => "Host",
               Testhost     => "host.[1]",
               deletevdr    => "host.[1].vdr.[-1]",
            },
         },
      },
      'AddDeleteLIFs'   => {
         TestName         => 'AddDeleteLIFs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that LIFs can be added and deleted ' .
                             ' from the VDR instance ' ,
         Procedure        => '1. Create a VDR instance' .
                             '2. Add LIFs to the VDR instance '.
                             '3. Verify LIFs are added '.
                             '4. Delete LIFs from the VDR instance'.
                             '5. Verify LIFs are deleted'.
                             '6. Delete the VDR instance'.
                             '7. Verify the instance is deleted successfully' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "600",
                        vlantype => "access",
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             #['EnableVDL2_1'],
                             ['CreateVXLANNetwork'],
                             ['CreateVXLANNetwork2'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANandVXLANProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVXLANLIF2'],
                             ['CreateVLANLIF'],
                             ['CreateVLANLIF2'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteLIF3'],
                             ['DeleteLIF4'],
                             ['DetachVDL2_1'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "CreateVXLANNetwork2" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[4]",
               VDL2ID         => "3200",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortVLANandVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlanAndVxlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVXLANLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3200",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "CreateVLANLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF3" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF4" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      'ChangeNetworkIdAfterLIFCreation'   => {
         TestName         => 'ChangeNetworkIdAfterLIFCreation',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that LIFs can be added and deleted ' .
                             ' from the VDR instance ' ,
         Procedure        => '1. Create a VDR instance' .
                             '2. Add LIFs to the VDR instance '.
                             '3. Verify LIFs are added ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
#                        vlan => "17",
#                        vlantype => "access",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
#                        vlan => "600",
#                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['EnableVDL2_1'],
                             ['CreateVXLANNetwork'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],

                             ['AddConnection'],
                             ['DisableVDL2_1'],
                             ['SetVDRPortVLANandVXLANPropertyFAIL'],

                             ['EnableVDL2_1'],
                             ['SetVDRPortVLANandVXLANProperty'],
                             ['DisableVDL2_1FAIL'],

                             ['DeleteConnection'],
                             ['CreateVXLANLIFFAIL'],
                             ['CreateVLANLIFFAIL'],

                             ['AddConnection'],
                             ['ResetVDRPortVLANandVXLANProperty'],
                             ['CreateVXLANLIFFAIL'],
                             ['CreateVLANLIFFAIL'],

                             ['SetVDRPortVLANandVXLANProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['ResetVDRPortVLANandVXLANPropertyFAIL'], # Seems like a bug
                             ['DisableVDL2_1FAIL'],
                             ['DeleteConnectionFAIL'],

                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['ResetVDRPortVLANandVXLANProperty'],
                             ['DisableVDL2_1'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                             ['DisableVDL2_1'],
                             ['DetachVDL2_1'],
                            ],
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortVLANandVXLANPropertyFAIL" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlanAndVxlan",
            },
            "SetVDRPortVLANandVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlanAndVxlan",
            },
            "ResetVDRPortVLANandVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "disable",
               networktype  => "vlanAndVxlan",
            },
            "ResetVDRPortVLANandVXLANPropertyFAIL" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "disable",
               networktype  => "vlanAndVxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnectionFAIL" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIFFAIL" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVLANLIFFAIL" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DisableVDL2_1FAIL" => {
               Type           => "VC",
               ExpectedResult => "FAIL",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      'SetAllLIFProperties'   => {
         TestName         => 'SetAllLIFProperties',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that LIFs can be added and deleted ' .
                             ' from the VDR instance ' ,
         Procedure        => '1. Create a VDR instance' .
                             '2. Add LIFs to the VDR instance '.
                             '3. Verify LIFs are added '.
                             '4. Set Designated instance ip'.
                             '5. Add static ARP'.
                             '6. Delete static ARP',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['CreateVLANLIF'],
                             ['SetLIFDI'],
                             ['SetControlPlaneIP'],
                             ['AddStaticARPonLIF'],
                             ['DeleteStaticARPonLIF'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIFDI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               host         => "host.[1]",
            },
            "SetControlPlaneIP" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "AddStaticARPonLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addstaticarp",
               lifname      => "subnet16lif",
               arpnetwork   => "172.31.1.1",
               arpmac       => "00:50:51:52:53:54",
            },
            "DeleteStaticARPonLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletestaticarp",
               lifname      => "subnet16lif",
            },
            "DeleteLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      # Implement with VSM
      'DeleteVDRWithLIFs'   => {
         TestName         => 'DeleteVDRWithLIFs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that VDR cannot be deleted without ' .
                             'deleting LIFs' ,
         Procedure        =>
            '1. Create a VDR instance' .
            '2. Add LIFs to the VDR instance '.
            '3. Verify LIFs are added '.
            '4. Try deleting the VDR instance, this should fail since'.
              ' it has LIFs (this will not fail with net-vdr)'.
            '5. Now delete the LIFs and delete the VDR' .
            '6. Verify the instance is deleted successfully' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  'vdr' => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Iterations   => "2", # TODO: make it 100
            Sequence     => [
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['DeleteInstance'],
                             #['DeleteLIF1'],
                             #['DeleteLIF2'],
                            ],

            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3200",
            },
            "DeleteInstance" => {
               Type         => "Host",
               Testhost     => "host.[1]",
               deletevdr    => "host.[1].vdr.[1]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
      'AddDeleteVLANLIFSameHostTrafficStress'   => {
         TestName         => 'AddDeleteVLANLIFSameHostTrafficStress',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that LIFs can be added and deleted ' .
                             ' from the VDR instance' ,
         Procedure        => '1. Create 10 VDR instances' .
                             '2. Add 100 LIFs to each VDR instance '.
                             '3. Verify LIFs are added '.
                             '4. Add 100 routes'.
                             '5. Run TCP/UPDP traffic between two networks'.
                             '6. Delete routes and LIFs while the traffic is flowing'.
                             '7. Add the routes and LIFs again while the traffic is still flowing'.
                             '8. Delete routes, LIFs from the VDR instances'.
                             '9. Verify routes and LIFs are deleted'.
                             '10. Delete the VDR instances'.
                             '11. Verify the instance is deleted successfully'.
                             '12. Run steps 1-7 in a loop of size maybe 100',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'Stress',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
         TestcaseType     => 'Stress',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1-2]' => {
                     },
                  },
                  vdr => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1'],
                             ['AddVmk2','SetLogLevel','DisableControlPlane'],
                             ['AddVmk3','CreateVDRPort'],
                             ['AddVmk4','AddConnection'],
                             ['SetVDRPortProperty'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetSameHost2'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['TrafficDifferentSubnetSameHostFAIL'],
                             ['TrafficDifferentSubnetSameHostFAIL2'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             # Running adddelete and traffic in parallel
                             ['DeleteAddLIFLoop1','DeleteAddLIFLoop2',
                             'TrafficDifferentSubnetSameHostIntervals',
                             'TrafficDifferentSubnetSameHostIntervals2'],
                             # Verify after add delete stress
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetSameHost2'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
           "AddVDR" => {
               Type => "Host",
               TestHost => "host.[1]",
               vdr => {
                  '[1]' => {
                  },
               },
            },
           "DeleteVDR" => {
               Type => "Host",
               TestHost => "host.[1]",
               deletevdr => "host.[1].vdr.[-1]",
            },
            'AddVmk1' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHostFAIL" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ExpectedResult => "FAIL",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHostFAIL2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ExpectedResult => "FAIL",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHostIntervals" => {
               Type           => "Traffic",
               ExpectedResult => "FAIL",
               ToolName       => "Ping",
               TestDuration   => "1-60,5",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHostIntervals2" => {
               Type           => "Traffic",
               ExpectedResult => "FAIL",
               ToolName       => "Ping",
               TestDuration   => "3-63,5",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[4]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllVmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteAddLIFLoop1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete,add",
               Iterations   => "100",
               sleepbetweencombos => "10",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "DeleteAddLIFLoop2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Iterations   => "100",
               lif          => "delete,add",
               sleepbetweencombos => "10",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      'AddDeleteVXLANLIFTrafficDifferentHost'   => {
         TestName         => 'AddDeleteVXLANLIFTrafficDifferentHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs spanning multiple hosts',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VNIs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk5'],
                             ['AddVmk2','AddVmk6'],
                             ['AddVmk3','AddVmk7'],
                             ['AddVmk4','AddVmk8'],
                             ['CreateVTEP'],
                             ['AttachVDL2_1','ChangeVDL2VmknicIP'],
                             ['AttachVDL2_2','ChangeVDL2VmknicIP2'],
                             ['CreateVDR1'],
                             ['CreateVDR2'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetTrunk'],
                             ['CreateLIF1','SetNetstack1Gateway'],
                             ['CreateLIF2','SetNetstack2Gateway'],
                             ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
                             ['TrafficSameSubnetDifferentHost','TrafficSameSubnetDifferentHost2'],
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetDifferentHost'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                             ['DeleteVDR1'],
                             ['DeleteVDR2'],
                             ['TrafficDifferentSubnetSameHostFAIL'],
                             ['TrafficDifferentSubnetDifferentHostFAIL'],
                             ['CreateVDR1'],
                             ['CreateVDR2'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             # Running adddelete and traffic in parallel
                             ['DeleteAddLIFLoop1','DeleteAddLIFLoop2',
                             'TrafficDifferentSubnetSameHostIntervals',
                             'TrafficDifferentSubnetDifferentHostIntervals2'],
                             # Verify after add delete stress
                             ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmksHost1'],
                             ['RemoveAllVmksHost2'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                             ['DeleteVDR1'],
                             ['DeleteVDR2'],
                             ['RemoveVTEP'],
                            ],
	    # This is bug in vdnet, its not reading other properties
	    # while creating vdr
            "CreateVDR1" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vdr => {
                  '[1]' => {
                     vdrname      => "Adddelete-VXLAN-Diff-Host",
                     vdrloglevel  => "0",
                     vdrsetup     => "1",
                  },
               },
            },
            "CreateVDR2" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               vdr => {
                  '[1]' => {
                     vdrname      => "Adddelete-VXLAN-Diff-Host",
                     vdrloglevel  => "0",
                     vdrsetup     => "1",
                  },
               },
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDR1" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               deletevdr      => "host.[1].vdr.[1]",
            },
            "DeleteVDR2" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               deletevdr      => "host.[2].vdr.[1]",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficSameSubnetDifferentHost2" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "6",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHostFAIL" => {
               Type           => "Traffic",
               TestDuration   => "60",
               ToolName       => "Ping",
               ExpectedResult => "FAIL",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHostFAIL" => {
               Type           => "Traffic",
               TestDuration   => "60",
               ToolName       => "Ping",
               ExpectedResult => "FAIL",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               TestDuration   => "60",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               TestDuration   => "60",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
            },
            "TrafficDifferentSubnetSameHostIntervals" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               ToolName       => "Ping",
               TestDuration   => "1-60,5",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetDifferentHostIntervals2" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               ToolName       => "Ping",
               TestDuration   => "3-63,5",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.10",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "10.10.1.20",
              Netmask         => "255.255.255.0"
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteAddLIFLoop1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete,add",
               Iterations   => "1000",
               sleepbetweencombos => "10",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteAddLIFLoop2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Iterations   => "1000",
               lif          => "delete,add",
               sleepbetweencombos => "10",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            'RemoveAllVmksHost1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmksHost2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      'CreateVDRAndLIFWithInvalidChars'   => {
         TestName         => 'CreateVDRAndLIFWithInvalidChars',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify, trying to create VDR with invalid' .
                             'names or long names doesnot crash and returns
                             proper error msgs' ,
         Procedure        => '1. Create a VDR instance with special chars' .
                             '2. This should return error saying invalid name '.
                             '3. Create a VDR instance with 128 chars including
                                 letters and numbers' .
                             '4. This should pass'.
                             '6. Create a VDR with valid name '.
                             '7. Try creating the LIFs with special chars, long
                                  names '.
                             '8. This should return error saying invalid name '.
                             '9. Now create LIFs with valid names'.
                             '10. Now delete the LIFs and delete the VDR' .
                             '11. Verify the instance is deleted successfully' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  'vdr' => {
                     '[5]' => {
                     vdrname => "test",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['CreateVDR1'],
                             ['CreateVDR2'],
                             ['CreateVDR3'],
                             #['EnableVDL2_1'],
                             ['CreateVXLANNetwork'],
                             ['DisableControlPlane'],
#                             ['CreateVDRPort'],
#                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['CreateDeleteVXLANLIF'],
                             ['CreateDeleteVLANLIF'],
                            ],
           ExitSequence  => [
#                             ['DeleteLIF1'],
#                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "CreateVDR1" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vdr => {
                  '[1]' => {
                     vdrname => "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" .
                                "qwertyuiop12345678990asdfghjklmnbvcxz" ,
                    vdrport   => "create",
                    dvsname   => "vc.[1].vds.[1]",
                    Connection   => "add",
                    connectionid => "1",
                  },
               },
            },
            "CreateVDR2" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               ExpectedResult => "FAIL",
               vdr => {
                  '[2]' => {
                     vdrname => '!@#$%^&*()_+~',
                  },
               },
            },
            "CreateVDR3" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               ExpectedResult => "FAIL",
               vdr => {
                  '[3]' => {
                     vdrname => '<F12><F12><Undo><F11>:9443/v/#',
                  },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateDeleteVXLANLIF" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add,delete",
               lifname      => "ASDFGHJKLZXCVBNMQWERTYUIOP" .
                               "ASDFGHJKLZXCVBNMQWERTYUIOP".
                               "ASDFGHJKLZXCVBNMQWERTYUIOP".
                               "ASDFGHJKLZXCVBNMQWERTYUIOP".
                               "ASDFGHJKLZXCVBNMQWERTYUIOP".
                               "ASDFGHJKLZXCVBNMQWERTYUIOP",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateDeleteVLANLIF" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add,delete",
               lifname      => '!@#$%%%^^^^^^&**()_+',
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      'ADDVDRsLIFsWithSameName'   => {
         TestName         => 'ADDVDRsLIFsWithSameName',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that multiple VDRs or LIFs cannot be ' .
                             'created with same name' ,
         Procedure        =>
            '1. Create a VDR instance' .
            '2. Add LIFs to the VDR instance '.
            '3. Verify LIFs are added '.
            '4. Create 2nd VDR instance with same name as the first one'.
            '5. This should return error saying duplicate name'.
            '6. Now try with a new name and verify it is created' .
            '7. Add a LIF to this VDR' .
            '8. Now try to add the same LIF again' .
            '9. This should return error saying duplicate name'.
            '10. Add a VLAN LIF to the VDR instance '.
            '11. Add a new LIF to the VDR instance for the same VLAN but with a '.
               'different name'.
            '12. This should return error' .
            '13. Add a VXLAN LIF to the VDR instance '.
            '14. Add a new LIF to the VDR instance for the same VXLAN but with a '.
               'different name'.
            '15. This should return error' .
            '16. Now try with a new LIF name for a different VLAN or VXLAN' .
            '17. This should pass' .
            '18. Now delete the LIFs and delete both VDRs' .
            '19. Verify the instances are deleted' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VDR_NAME_1"
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['CreateVDR2'],
                             ['CreateVDR3'],
                             #['EnableVDL2_1'],
                             ['CreateVXLANNetwork'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateSameNameVLANLIF'],
                             ['CreateNewVLANLIF'],
                             ['SameIPDifferentNetwork'],
                             ['SameNetworkDifferentIP'],
                             ['CreateAnotherVLANLIF'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteLIF3'],
                             ['DetachVDL2_1'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],

            "CreateVDR2" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               ExpectedResult => "FAIL",
               vdr => {
                  '[2]' => {
                     vdrname => "VDR_NAME_1"
                  },
               },
            },
            "CreateVDR3" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vdr => {
                  '[2]' => {
                     vdrname => "VDR_NAME_2"
                  },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "LIF_NAME_1",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "LIF_NAME_1",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateSameNameVLANLIF" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "LIF_NAME_1",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "CreateNewVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "LIF_NAME_2",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "LIF_NAME_2",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SameIPDifferentNetwork" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "LIF_NAME_3",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "SameNetworkDifferentIP" => {
               Type         => "LocalVDR",
               ExpectedResult => "FAIL",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "LIF_NAME_3",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.21.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "CreateAnotherVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "LIF_NAME_3",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.21.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "DeleteLIF3" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "LIF_NAME_3",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      'ADDLIFsWithSameVLANorVXLANAcrossVDRs'   => {
         TestName         => 'ADDLIFsWithSameVLANorVXLANAcrossVDRs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that multiple LIFs can be ' .
                             'be created with same VLAN or VXLAN across VDRs' ,
         Procedure        => '1. Create 2 VDR instances' .
                             '2. Add a VLAN LIF to the 1st VDR instance '.
                             '3. Add a new LIF to the 2nd VDR instance with the'.
                             ' same VLAN but with a different name'.
                             '4. The LIF should be added successfully' .
                             '5. Add a 2nd VLAN LIF to the 1st VDR instance '.
                             '6. Add a new LIF to the 2nd VDR instance with the'.
                             '   same VLAN and same name'.
                             '7. The LIF should be added successfully' .
                             '8. Add a VXLAN LIF to the 1st VDR instance '.
                             '9. Add a new LIF to the 2nd VDR instance with the'.
                             '   same VXLAN but with a different name'.
                             '10. The LIF should be added successfully' .
                             '11. Add a 2nd VXLAN LIF to the 1st VDR instance '.
                             '12. Add a new LIF to the 2nd VDR instance with the'.
                             '    same VXLAN and same name'.
                             '13. The LIF should be added successfully' .
                             '14. Now delete the LIFs and delete the VDRs' .
                             '15. Verify the VDRs are deleted' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[1]",
                        vlan => "17",
                        vlantype => "access",
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANandVXLANProperty'],
                             ['CreateVLANLIF1onVDR1'],
                             ['CreateVLANLIF1onVDR2SameVLANDifferentName'],
                             ['CreateVLANLIF2onVDR1'],
                             ['CreateVLANLIF2onVDR2SameVLANSameName'],
                             # Do the same test on vxlan
                             #['EnableVDL2_1'],
                             ['CreateVXLANNetwork'],
                             ['CreateVXLANNetwork2'],
                             ['CreateVXLANLIF1onVDR1'],
                             ['CreateVXLANLIF1onVDR2SameVXLANDifferentName'],
                             ['CreateVXLANLIF2onVDR1'],
                             ['CreateVXLANLIF2onVDR2SameVXLANSameName'],
                            ],
           ExitSequence  => [
                             ['DeleteVLANLIF1VDR1'],
                             ['DeleteVLANLIF1VDR2'],
                             ['DeleteVLANLIF2VDR1and2'],
                             ['DeleteVXLANLIF1VDR1'],
                             ['DeleteVXLANLIF1VDR2'],
                             ['DeleteVXLANLIF2VDR1and2'],
                             ['DetachVDL2_1'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],

            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "CreateVXLANNetwork2" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[4]",
               VDL2ID         => "3200",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortVLANandVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlanAndVxlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF1onVDR1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVXLANLIF1onVDR2SameVXLANDifferentName" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[2]",
               lif          => "add",
               lifname      => "subnet3100lif-vdr2",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVXLANLIF2onVDR1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3200",
            },
            "CreateVXLANLIF2onVDR2SameVXLANSameName" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[2]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkid => "3200",
            },
            "CreateVLANLIF1onVDR1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "CreateVLANLIF1onVDR2SameVLANDifferentName" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[2]",
               lif          => "add",
               lifname      => "subnet16lif-vdr2",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "CreateVLANLIF2onVDR1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "CreateVLANLIF1onVDR2SameVLANSameName" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[2]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "DeleteVLANLIF1VDR1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVLANLIF1VDR2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3100lif-vdr2",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVLANLIF2VDR1and2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1-2]",
               lif          => "remove",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVXLANLIF1VDR1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVXLANLIF1VDR2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "subnet3100lif-vdr2",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVXLANLIF2VDR1and2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1-2]",
               lif          => "remove",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1-2]",
               controlplane => "deactivate",
            },
         },
      },
      # Implement with VSM
      'VerifyDefaultVDRRoute'   => {
         TestName         => 'VerifyDefaultVDRRoute',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that a default route is added to the ' .
                             'VDR after it is instantiated' ,
         Procedure        => '1. Create a VDR instance' .
                             '2. Dump the route info for the VDR, verify a
                                 default route (to VSE) is added to the VDR'.
                             '3. ADD LIFs and routes to the VDR '.
                             '4. Dump the route info again, it should have the
                                 added routes along with the default route
                                 (VSE should be up and running for this test)'.
                             '5. Now delete the LIFs and delete the VDR' .
                             '6. Verify the instance is deleted successfully' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VDRRouteResolve'   => {
         TestName         => 'VDRRouteResolve',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify net-vdr can be used to resolve routes' ,
         Procedure        =>
            '1. Create a VDR instance' .
            '2. ADD 4 LIFs and 4 routes to the VDR '.
            '3. Use net-vdr command to check which route is selected when'.
            '   sending traffic across different subnets'.
            '4. ADD a ARP entry for a particular LIF '.
            '5. ADD a route so that it conflicts with the ARP entry '.
            '6. Send traffic to the destination for which we added the'.
            '   ARP entry, now the pkt should go to the interface specified'.
            '   by the route and not where the ARP entry says. FIB should '.
            '   take precedence over ARP'.
            '7. Verify traffic reaches the destination'.
            '8. Dump the route info again, it should have the added routes'.
            '   along with the default route'.
            '9. Now delete routes, LIFs and the VDR' .
            '10. Verify the instance is deleted successfully' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VDRRouteResolvePrefixCheck'   => {
         TestName         => 'VDRRouteResolvePrefixCheck',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR can resolve routes properly with' .
                             'longest prefix match'.
         Procedure        =>
            '1. Create a VDR instance' .
            '2. ADD 4 LIFs and 4 routes to the VDR '.
            '3. The added routes should be like two /24 networks, '.
               'one /16 network and one /8 network'.
            '4. Send traffic from one source to all these 4 networks,'.
               ' VDR should resolve the routes properly and send it to the'.
               ' relevant destination'.
            '5. Verify traffic reaches the destination in all 4 cases'.
            '6. Now delete routes, LIFs and the VDR' .
            '7. Verify the instance is deleted successfully' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      # PR 986927
      'VXLANTrafficSameHost'   => {
         TestName         => 'VXLANTrafficSameHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs on same host',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VXLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with test vNICs on different'.
                             '   VNIs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM. Send unicast, multicast and'.
                             '         broadcast traffic'.
                             '7. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,1host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1-2]'   => {
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1'],
                             ['AddVmk2'],
                             ['AddVmk3'],
                             ['AddVmk4'],
                             #['EnableVDL2_1'],
                             ['CreateVTEP'],
                             ['AttachVDL2_1'],
                             ['AttachVDL2_2'],
                             ['ChangeVDL2VmknicIP'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficSameSubnetSameHost'],
                             ['TrafficDifferentSubnetSameHost'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            # ['DetachVDL2_1'],['DetachVDL2_2'],
                             ['RemoveVTEP'],
                            # ['DisableVDL2_1'],
                            ],
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "600",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1],host.[1].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[3],host.[1].vmknic.[4]",
               MaxTimeout     => "39000",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
#               VMKNICIP       => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_IP_A,
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost       => "host.[1]",
              IPAddr          => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_IP_A,
              Netmask         => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_NETMASK_A,
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty     => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DetachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
            },
            'RemoveAllVmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },

         },
      },
      'VXLANTrafficSameHostWithVMs'   => {
         TestName         => 'VXLANTrafficSameHostWithVMs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs on same host',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VXLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with test vNICs on different'.
                             '   VNIs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM. Send unicast, multicast and'.
                             '         broadcast traffic'.
                             '7. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds      => "vc.[1].vds.[1]",
                        name     => "vxlan3100-dvpg-$$",
                        ports    => "4",
                     },
                     '[2]'   => {
                        vds      => "vc.[1].vds.[1]",
                        name     => "vxlan3200-dvpg-$$",
                        ports    => "4",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                        name => "vxlan3100-netstack",
                     },
                     '[2]' => {
                        name => "vxlan3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        controlplane => "deactivate",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        networktype    => "vxlan",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '192.31.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '192.32.1.100',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '192.31.1.102',
                        netmask    => "255.255.255.0",
                        route      => "add",
                        network    => "192.32.1.0",
                        gateway    => "192.31.1.1",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                        ipv4       => '192.32.1.102',
                        netmask    => "255.255.255.0",
                        route      => "add",
                        network    => "192.31.1.0",
                        gateway    => "192.32.1.1",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             #['EnableVDL2_1'],
                             ['AttachVDL2_1'],
                             ['AttachVDL2_2'],
                             ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficSameDifferentHostVmknics'],
                             ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetSameHost2'],
                             ['TrafficDifferentSubnetSameHostVMs'],
                             ['TrafficDifferentSubnetSameHostVMs'],
			     #['TrafficDifferentSubnetSameHostVMsOvernight'],
                             ['TrafficDifferentSubnetSameHostVMs2'],
                             ['TrafficDifferentSubnetSameHostVMs3'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "ReSetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "AddRouteinVM1" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               route          => "add",
               network        => "192.32.1.0",
               netmask        => "255.255.255.0",
               gateway        => "192.32.1.1",
            },
            "AddRouteinVM2" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[2].vnic.[1]",
               route          => "add",
               network        => "192.31.1.0",
               netmask        => "255.255.255.0",
               gateway        => "192.31.1.1",
            },
            "TrafficSameDifferentHostVmknics" => {
               Type           => "Traffic",
               TestDuration   => "6",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "10",
               #L4Protocol     => "udp,tcp",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               TestDuration   => "10",
               #L4Protocol     => "udp,tcp",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               # Broadcast from VM not working, check
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "10",
               #L4Protocol     => "udp,tcp",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               Routingscheme  => "multicast",
               Multicasttimetolive => "32",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TrafficDifferentSubnetSameHost2"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               #L4Protocol          => "udp,tcp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               TestAdapter          => "host.[1].vmknic.[2]",
               SupportAdapter       => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentSubnetSameHostVMsOvernight"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
	       sleepBetweenCombos   => "50",
               TestDuration         => "600-6,50",
               #L4Protocol           => "tcp,udp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               ParallelSession      => "yes",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[1].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "TrafficDifferentSubnetSameHostVMs"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               TestDuration         => "60",
               L4Protocol           => "tcp,udp",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               #ParallelSession      => "yes",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentSubnetSameHostVMs2"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               # Make duration to 60 before checkin
               TestDuration         => "60",
               NoofOutbound         => "50",
               NoofInbound          => "50",
               ParallelSession      => "yes",
               Routingscheme        => "multicast,unicast",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[1].vnic.[1]",
               MaxTimeout           => "9000",
            },
            "TrafficDifferentSubnetSameHostVMs3"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,48504,64564,80624,96684,112744,128804",
               LocalSendSocketSize  => "131072",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[1].vnic.[1]",
               MaxTimeout           => "9000",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "192.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[2]",
               setnetstackgateway => "add",
               route => "192.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty     => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "192.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "192.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },

         },
      },
      'VXLANTrafficDifferentHost'   => {
         TestName         => 'VXLANTrafficDifferentHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs spanning multiple hosts',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VNIs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
					vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Different-Host-$$",
#                        vdrloglevel  => "0",
#                        vdrsetup     => "1",
#                        controlplane => "deactivate",
#                        vdrport      => "create",
#                        dvsname      => "vc.[1].vds.[1]",
#                        Connection   => "add",
#                        connectionid => "1",
#                        vdrportproperty=> "enable",
#                        networktype    => "vxlan",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk5'],
                             ['AddVmk2','AddVmk6'],
                             ['AddVmk3','AddVmk7'],
                             ['AddVmk4','AddVmk8'],
                        #     ['EnableVDL2_1'],
                             ['CreateVTEP'],
                             ['AttachVDL2_1'],
                             ['AttachVDL2_2'],
			     ['ChangeVDL2VmknicIP'],
			     ['ChangeVDL2VmknicIP2'],
			     ['DisableControlPlane'],
			     ['CreateVDRPort'],
			     ['AddConnection'],
			     ['SetTrunk'],
#                             ['AttachVDL2_1'],
#                             ['AttachVDL2_2'],
#			     ['ChangeVDL2VmknicIP'],
#			     ['ChangeVDL2VmknicIP2'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
			     #TODO: Remove this 
			     #['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
			     #['TrafficSameSubnetDifferentHost'],
			     #['TrafficDifferentSubnetSameHost'],
			     #['TrafficDifferentSubnetDifferentHost'],
			     #['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks1'],
                             ['RemoveAllVmks2'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                             ['RemoveVTEP'],
                            ],
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "6",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
	       #TODO: replace before checking
               TestDuration   => "6",
	       #TestDuration   => "6000",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
               MaxTimeout     => "96000",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.10",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "10.10.1.20",
              Netmask         => "255.255.255.0"
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DetachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },

         },
      },
      'VXLANTrafficDifferentHostJustPing'   => {
         TestName         => 'VXLANTrafficDifferentHostJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
#         Summary          => 'Verify VDR can route VXLAN traffic to ' .
#                             ' different VNIs spanning multiple hosts',
#         Procedure        => '1. Create 2 VXLANs ' .
#                             '2. Create VDR instances on each host and add'.
#                             '   2 LIFs to route between the VXLANs '.
#                             '   (this will come from VSE)'.
#                             '3. Verify the route info in the VDR'.
#                             '4. Create 1 VM on each host with test vNICs'.
#                             '   on different VNIs'.
#                             '5. In the VMs, set the default gateway to'.
#                             '   respective VDRs'.
#                             '6. Send traffic between the VMs and make sure it'.
#                             '   goes through. From the source VM it should go'.
#                             '   to VDR on that host and it should route'.
#                             '   the pkts to VDR on the destination host.'.
#                             '   Once the pkts reach VDR on the destination'.
#                             '   host, it should forward the pkts to the'.
#                             '   destination VM'.
#                             '7. Send unicast, multicast and broadcast traffic'.
#                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host,sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
		        vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Different-Host-$$",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk5'],
                             ['AddVmk2','AddVmk6'],
                             ['AddVmk3','AddVmk7'],
                             ['AddVmk4','AddVmk8'],
                             ['CreateVTEP'],
                             ['AttachVDL2_1'],
                             ['AttachVDL2_2'],
			     ['ChangeVDL2VmknicIP'],
			     ['ChangeVDL2VmknicIP2'],
			     ['DisableControlPlane'],
			     ['CreateVDRPort'],
			     ['AddConnection'],
			     ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
			     ['TrafficSameSubnetDifferentHost'],
			     ['TrafficDifferentSubnetSameHost'],
			     ['TrafficDifferentSubnetDifferentHost'],
			     ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks1'],
                             ['RemoveAllVmks2'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                             ['RemoveVTEP'],
                            ],
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
	      #IPAddr          => "10.10.1.10",
	      #Netmask         => "255.255.255.0"
              IPAddr          => "172.20.1.1",
              Netmask         => "255.255.0.0",
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
	      #IPAddr          => "10.10.1.20",
	      #Netmask         => "255.255.255.0"
              IPAddr          => "172.20.1.2",
              Netmask         => "255.255.0.0",
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DetachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },

         },
      },
      'VXLANTrafficDifferentHostWithVMsJustPing'   => {
         TestName         => 'VXLANTrafficDifferentHostWithVMsJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs spanning multiple hosts',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VNIs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,2host,WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Diff-Host-WithVMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.31.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => '172.32.1.100',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Diff-Host-WithVMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => '172.31.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => '172.32.1.200',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.31.1.102',
                        netmask    => "255.255.255.0",
                        route      => "add",
                        network    => "172.32.1.0",
                        gateway    => "172.31.1.1",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.32.1.102',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.31.1.0",
                        gateway     => "172.32.1.1",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.31.1.202',
                        netmask    => "255.255.255.0",
                        route      => "add",
                        network    => "172.32.1.0",
                        gateway    => "172.31.1.1",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.32.1.202',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.31.1.0",
                        gateway     => "172.32.1.1",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['CreateVTEP'],
                             ['AttachVDL2_1'],
                             ['AttachVDL2_2'],
                             ['ChangeVDL2VmknicIP'],
                             ['ChangeVDL2VmknicIP2'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficAllHostAllSubnetVmknics'],
                             ['TrafficAllHostAllSubnetVMs'],
                             ['TrafficDifferentSubnetDifferentHost'],
                             ['TrafficDifferentSubnetDifferentHost2'],
			     ['TrafficDifferentSubnetDifferentHostVMs2'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
			     ['DetachVDL2_1'],
			     ['DetachVDL2_2'],
                             ['RemoveVTEP'],
                            ],
            "TrafficAllHostAllSubnetVmknics" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[3]",
            },
            "TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               TestDuration   => "60",
               ParallelSession=> "yes",
               ToolName       => "Ping",
               NoofInbound    => 3,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-4].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "10",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "10",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost2"  => {
               Type           => "Traffic",
               TestDuration   => "5",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "host.[2].vmknic.[3]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHostVMs2"  => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofOutbound   => "10",
               NoofInbound    => "10",
               ParallelSession=> "yes",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               MaxTimeout     => "96000",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               #VLANID         => "0",
               #VMKNICIP       => "10.10.1.30"
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.10",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "10.10.1.20",
              Netmask         => "255.255.255.0"
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DetachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
         },
      },
      'VXLANTrafficDifferentHostWithVMs'   => {
         TestName         => 'VXLANTrafficDifferentHostWithVMs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs spanning multiple hosts',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VNIs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host,WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Diff-Host-WithVMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.31.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => '172.32.1.100',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Diff-Host-WithVMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => '172.31.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => '172.32.1.200',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.31.1.102',
                        netmask    => "255.255.255.0",
                        route      => "add",
                        network    => "172.32.1.0",
                        gateway    => "172.31.1.1",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.32.1.102',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.31.1.0",
                        gateway     => "172.32.1.1",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.31.1.202',
                        netmask    => "255.255.255.0",
                        route      => "add",
                        network    => "172.32.1.0",
                        gateway    => "172.31.1.1",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.32.1.202',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.31.1.0",
                        gateway     => "172.32.1.1",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             #['EnableVDL2_1'],
                             ['CreateVTEP'],
                             ['AttachVDL2_1'],
                             ['AttachVDL2_2'],
                             ['ChangeVDL2VmknicIP'],
                             ['ChangeVDL2VmknicIP2'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficAllHostAllSubnetVmknics'],
                             ['TrafficAllHostAllSubnetVMs'],
                             ['TrafficDifferentSubnetDifferentHost'],
                             ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentSubnetDifferentHostVMs'],
                             ['TrafficDifferentSubnetDifferentHostVMs'],
			     ['TrafficDifferentSubnetDifferentHostVMs2'],
			     ['TrafficDifferentSubnetDifferentHostVMs3'],
			     ['TrafficDifferentSubnetDifferentHostVMsOvernight'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
			     ['DetachVDL2_1'],
			     ['DetachVDL2_2'],
                             ['RemoveVTEP'],
			     ['DisableVDL2_1'],
                            ],
            "TrafficAllHostAllSubnetVmknics" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[3]",
            },
            "TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               TestDuration   => "60",
               ToolName       => "Ping",
               NoofInbound    => 3,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-4].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "10",
               #L4Protocol     => "udp,tcp",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               Routingscheme  => "multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost2"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               #L4Protocol          => "udp,tcp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               TestAdapter          => "host.[2].vmknic.[3]",
               SupportAdapter       => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHostVMsOvernight"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
	       sleepBetweenCombos   => "50",
               TestDuration         => "600-6,50",
               #L4Protocol           => "tcp,udp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               ParallelSession      => "yes",
               TestAdapter          => "vm.[1].vnic.[1]",
               SupportAdapter       => "vm.[4].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "TrafficDifferentSubnetDifferentHostVMs"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               TestDuration         => "60",
               L4Protocol           => "tcp,udp",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               #ParallelSession      => "yes",
               TestAdapter          => "vm.[1].vnic.[1]",
               SupportAdapter       => "vm.[4].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHostVMs2"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               # Make duration to 60 before checkin
               TestDuration         => "60",
               NoofOutbound         => "50",
               NoofInbound          => "50",
               ParallelSession      => "yes",
               # Broadcast won't work untill Product PR is fixed
               Routingscheme        => "multicast,unicast",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[3].vnic.[1]",
               MaxTimeout           => "9000",
            },
            "TrafficDifferentSubnetDifferentHostVMs3"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,48504,64564,80624,96684,112744,128804",
               ExpectedResult       => "Ignore",
               LocalSendSocketSize  => "131072-100,5000",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[3].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'AddHost1Vmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => '172.31.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => '172.32.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk1' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup => "vc.[1].dvportgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv4address => '172.31.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk3' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[2].netstack.[2]",
                  ipv4address => '172.32.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               #VLANID         => "0",
               #VMKNICIP       => "10.10.1.30"
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.10",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "10.10.1.20",
              Netmask         => "255.255.255.0"
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DetachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
         },
      },

      'VXLANTrafficDifferentHostDifferentVDSes'   => {
         TestName         => 'VXLANTrafficDifferentHostDifferentVDSes',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR spanning across multiple VDSes'.
                             'can route pkts between networks.',
         Procedure        => '1. Create 2 VDSes one on each host ' .
                             '2. Create a VDR spanning across both the VDSes'.
                             '3. Create 2 VXLAN networks'.
                             '4. Add 2 LIFs for VDR for both the networks'.
                             '   created so that it can route the pkts'.
                             '5. Create VMs with test vNICs on each VXLAN'.
                             '6. Send traffic between the 2 VMs'.
                             '   VDR should route the traffic'.
                             '7. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                     '[2]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[2]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[3-4]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Different-Host-$$",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.31.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup   => "vc.[1].dvportgroup.[3]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.31.1.101',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.32.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[4]' => {
                        portgroup   => "vc.[1].dvportgroup.[4]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.32.1.101',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet3100-netstack",
                     },
                     '[2]' => {
                        name => "subnet3200-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "VXLAN-Different-Host-$$",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.31.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup   => "vc.[1].dvportgroup.[3]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.31.1.201',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.32.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[4]' => {
                        portgroup   => "vc.[1].dvportgroup.[4]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.32.1.201',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
		             #['EnableVDL2_1'],
		             ['EnableVDL2_2'],
                             ['CreateVTEP'],
                             ['CreateVTEP2'],
                             ['AttachVDL2_1'],
                             ['ChangeVDL2VmknicIP'],
                             ['ChangeVDL2VmknicIP2'],
                             ['ChangeVDL2VmknicIP3'],
                             ['ChangeVDL2VmknicIP4'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetTrunk'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficSameSubnetSameHost'],
                             ['TrafficSameSubnetSameHost2'],
                             ['TrafficSameSubnetDifferentHost'],
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetDifferentHost'],
                             ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
			     ['DetachVDL2_1'],
			     #['RemoveVTEP'],
			     ['DisableVDL2_1'],
                            ],
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.1.1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1-2]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1-2]",
               connectionid => "1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "6",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "EnableVDL2_2" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[2]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP2" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[2]",
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "10.10.1.10",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.20",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP3" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[2]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.30",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP4" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[2]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.40",
              Netmask         => "255.255.255.0"
            },
            "AttachVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1-3]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "AttachVDL2_2" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "attachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[2-4]",
               VDL2ID          => "3200",
               MCASTIP         => "239.0.0.1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
# *************** vdnet bug vds.[1-2] is not working.
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
               connectionid => "1",
            },
            "SetTrunk" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
               connectionid => "1",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
               lifip        => "172.31.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3100",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3100lif",
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
               lifip        => "172.32.1.1",
               lifnetmask   => "255.255.255.0",
               networktype  => "vxlan",
               lifnetworkId => "3200",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet3200lif",
               dvsname      => "vc.[1].vds.[1],vc.[1].vds.[2]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1-4]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1-2]",
               VLANID          => "0",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1-2]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1-2]",
            },

         },
      },
      'VXLANTrafficDifferentHostChangingUplinks'   => {
         TestName         => 'VXLANTrafficDifferentHostChanginguplinks',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs spanning multiple hosts by'.
                             ' changing the uplinks of the VDS',
         Procedure        =>
            '1. Create 2 VXLANs ' .
            '2. Create VDR instances on each host and add'.
            '   2 LIFs to route between the VXLANs '.
            '   (this will come from VSE)'.
            '3. Verify the route info in the VDR'.
            '4. Create 1 VM on each host with test vNICs'.
            '   on different VNIs'.
            '5. In the VMs, set the default gateway to'.
            '   respective VDRs'.
            '6. Send traffic between the VMs and make sure it'.
            '   goes through. From the source VM it should go'.
            '   to VDR on that host and it should route'.
            '   the pkts to VDR on the destination host.'.
            '   Once the pkts reach VDR on the destination'.
            '   host, it should forward the pkts to the'.
            '   destination VM'.
            '7. Send unicast, multicast and broadcast traffic',
            '8. Now change the uplinks of the VDS and send the traffic again. '.
            'Verify the traffic goes through',
            '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VXLANTrafficDifferentHostWithTeaming'   => {
         TestName         => 'VXLANTrafficDifferentHostWithTeaming',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VXLAN traffic to ' .
                             ' different VNIs spanning multiple hosts with'.
                             ' teaming enabled',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VNIs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic',
                             '8. Have multiple uplinks to the VDS and create a'.
                             ' team and test source port, source MAC, LAG'.
                             ' and VXLAN team with different traffic'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'Interop',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      # PR 986927
      # Add broadcast after
     'VLANTrafficSameHost'   => {
         TestName         => 'VLANTrafficSameHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs on same host',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with test vNICs on different'.
                             '   VLANs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,1host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['SetLogLevel'],
                             ['AddVmk1'],
                             ['AddVmk2'],
                             ['AddVmk3'],
                             ['AddVmk4'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortProperty'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficSameSubnetSameHost'],
                             ['TrafficSameSubnetSameHost2'],
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetSameHost2'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
           "AddNetstack1" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  '[1]' => {}
               }, 
            },
           "AddNetstack2" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  '[2]' => {}
               }, 
            },
            'AddVmk1' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               Routingscheme  => "unicast,multicast",
               Multicasttimetolive => "32",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2"  => {
               Type                 => "Traffic",
               TestDuration         => "60",
               #L4Protocol          => "udp,tcp",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,48504,64564,80624,96684,112744,128804",
               LocalSendSocketSize  => "131072",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "host.[1].vmknic.[2]",
               SupportAdapter       => "host.[1].vmknic.[4]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllVmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
     'VLANTrafficSameHostWithVMs'   => {
         TestName         => 'VLANTrafficSameHostWithVMs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs on same host',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with test vNICs on different'.
                             '   VLANs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds      => "vc.[1].vds.[1]",
                        name     => "vlan16-dvpg-$$",
                        ports    => "4",
                        vlan     => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds      => "vc.[1].vds.[1]",
                        name     => "vlan17-dvpg-$$",
                        ports    => "4",
                        vlan     => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
#                  vss   => {
#                     '[1]'   => { # create VSS
#                     },
#                  },
#                  portgroup   => {
#                     '[1]'   => { # create a vm portgroup on vss
#                        vss  => "host.[1].vss.[1]",
#                     },
#                  },
                  vdr => {
                     '[1]' => {
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        controlplane => "deactivate",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        vdrportproperty=> "enable",
                        networktype    => "vlan",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "vlan16-netstack",
                     },
                     '[2]' => {
                        name => "vlan17-netstack",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        switch      => "vc.[1].vds.[1]",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '192.16.1.110',
                        netmask     => "255.255.255.0",
                     },
                     '[2]' => {
                        switch      => "vc.[1].vds.[1]",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '192.17.1.110',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '192.16.1.112',
                        netmask    => "255.255.255.0",
                        # Not workking from here. Find out why
                        VLAN       => "16",
                        route      => "add",
                        network    => "192.17.1.0",
                        gateway    => "192.16.1.1",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                        ipv4       => '192.17.1.112',
                        netmask    => "255.255.255.0",
                        # Not workking from here. Find out why
                        VLAN       => "17",
                        route      => "add",
                        network    => "192.16.1.0",
                        gateway    => "192.17.1.1",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
#                             ['AddRouteinVM1'],
                             ['AddVlanVM1vNIC1'],
#                             ['AddRouteinVM2'],
                          #   ['AddVlanVM2vNIC1'],
#                             ['SetLogLevel'],
#                             ['DisableControlPlane'],
#                             ['CreateVDRPort'],
#                             ['AddConnection'],
#                             ['SetVDRPortProperty'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             #['AddRouteinVM1'],
                             #['AddRouteinVM2'],
                             ['TrafficSameDifferentHostVmknics'],
                             ['TrafficSameSubnetSameHost'],
                             ['TrafficSameSubnetSameHost2'],
                             ['TrafficDifferentSubnetSameHost'],
                             ['TrafficDifferentSubnetSameHost2'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "SetVDRPortProperty" => {
               Type           => "LocalVDR",
               Testvdr        => "host.[1].vdr.[1]",
               dvsname        => "vc.[1].vds.[1]",
               vdrportproperty=> "enable",
               networktype    => "vlan",
            },
            "AddVlanVM1vNIC1" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               vlan           => "16",
                        ipv4       => '192.16.1.112',
                        netmask    => "255.255.255.0",
            },
            "AddVlanVM2vNIC1" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[2].vnic.[1]",
               vlan           => "17",
            },
            "AddRouteinVM1" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               route          => "add",
               network        => "192.16.1.0",
               netmask        => "255.255.255.0",
               gateway        => "192.16.1.1",
            },
            "AddRouteinVM2" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[2].vnic.[1]",
               route          => "add",
               network        => "192.17.1.0",
               netmask        => "255.255.255.0",
               gateway        => "192.17.1.1",
            },
            "TrafficSameDifferentHostVmknics" => {
               Type           => "Traffic",
               TestDuration   => "60",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               TestDuration   => "60",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TrafficDifferentSubnetSameHost2"  => {
               Type                 => "Traffic",
               TestDuration         => "60",
               #L4Protocol          => "udp,tcp",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,48504,64564,80624,96684,112744,128804",
               LocalSendSocketSize  => "131072",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "host.[1].vmknic.[2]",
               SupportAdapter       => "vm.[1].vnic.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllVmks' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkId => "16",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkId => "17",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      # Implement broadcast after this is fixed.
      # 990733
      'VLANTrafficDifferentHostJustPing'   => {
         TestName         => 'VLANTrafficDifferentHostJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host,sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        mtu => "1600",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-Different-Host-$$",
#                        vdrloglevel  => "0",
#                        vdrsetup     => "1",
#                        vdrport      => "create",
#                        dvsname      => "vc.[1].vds.[1]",
#                        Connection   => "add",
#                        connectionid => "1",
#                        vdrportproperty=> "enable",
#                        networktype    => "vlan",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk5'],
                             ['AddVmk2','AddVmk6'],
                             ['AddVmk3','AddVmk7'],
                             ['AddVmk4','AddVmk8'],
			     ['CreateVDRPort'],
			     ['AddConnection'],
			     ['SetVDRPortProperty'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
			     ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
			     ['TrafficDifferentSubnetSameHost','TrafficDifferentSubnetSameHost2'],
			     ['TrafficSameSubnetDifferentHost'],
			     ['TrafficDifferentSubnetDifferentHost'],
			     ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllHost1Vmks'],
                             ['RemoveAllHost2Vmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddVmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "ReSetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "SetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "SetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
      'VLANTrafficDifferentHost'   => {
         TestName         => 'VLANTrafficDifferentHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        mtu => "1600",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-Different-Host-$$",
#                        vdrloglevel  => "0",
#                        vdrsetup     => "1",
#                        vdrport      => "create",
#                        dvsname      => "vc.[1].vds.[1]",
#                        Connection   => "add",
#                        connectionid => "1",
#                        vdrportproperty=> "enable",
#                        networktype    => "vlan",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk5'],
                             ['AddVmk2','AddVmk6'],
                             ['AddVmk3','AddVmk7'],
                             ['AddVmk4','AddVmk8'],
			     ['CreateVDRPort'],
			     ['AddConnection'],
			     ['SetVDRPortProperty'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
			     ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
			     ['TrafficDifferentSubnetSameHost','TrafficDifferentSubnetSameHost2'],
			     ['TrafficSameSubnetDifferentHost'],
			     ['TrafficDifferentSubnetDifferentHost'],
			     ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllHost1Vmks'],
                             ['RemoveAllHost2Vmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddVmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               #TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               #TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2" => {
               Type           => "Traffic",
               #TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type                 => "Traffic",
               TestDuration         => "60",
               #L4Protocol          => "udp,tcp",
               NoofInbound          => "3",
               NoofOutbound         => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,96684,112744,128804",
               LocalSendSocketSize  => "131072",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "host.[2].vmknic.[1]",
               SupportAdapter       => "host.[1].vmknic.[3]",
               MaxTimeout           => "9000",
            },
            # Long Duration so not many combinations
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               TestDuration   => "6",
	       TestDuration   => "6000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
               MaxTimeout     => "9000",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "ReSetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "SetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "SetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
      'VLANTrafficDifferentHostWithVMsJustPing'   => {
         TestName         => 'VLANTrafficDifferentHostWithVMsJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,2host,WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                        ipv4address => '172.16.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => '172.17.1.100',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => '172.16.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => '172.17.1.200',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4        => '172.16.1.101',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.17.1.0",
                        gateway     => "172.16.1.1",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.17.1.101',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.16.1.0",
                        gateway     => "172.17.1.1",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4        => '172.16.1.201',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.17.1.0",
                        gateway     => "172.16.1.1",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.17.1.201',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.16.1.0",
                        gateway     => "172.17.1.1",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['CreateVDRPort'],
                             ['SetVDRPortProperty'],
                             ['AddConnection'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficAllHostAllSubnetVmknics'],
                             ['TrafficAllHostAllSubnetVMs'],
                             ['TrafficDifferentSubnetDifferentHost'],
                             ['TrafficDifferentSubnetDifferentHost2'],
			     ['TrafficDifferentSubnetDifferentHostVMs2'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "TrafficAllHostAllSubnetVmknics" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[3]",
            },
            "TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               TestDuration   => "60",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               NoofInbound    => 3,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-4].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "10",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "10",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost2"  => {
               Type           => "Traffic",
               TestDuration   => "5",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "host.[2].vmknic.[3]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHostVMs2"  => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ExpectedResult => "Ignore",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofOutbound   => "10",
               NoofInbound    => "10",
               ParallelSession=> "yes",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               MaxTimeout     => "96000",
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "SetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "SetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
      # PR 988558
      'VLANTrafficDifferentHostWithVMs'   => {
         TestName         => 'VLANTrafficDifferentHostWithVMs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                        ipv4address => '172.16.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => '172.17.1.100',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => '172.16.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => '172.17.1.200',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4        => '172.16.1.101',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.17.1.0",
                        gateway     => "172.16.1.1",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.17.1.101',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.16.1.0",
                        gateway     => "172.17.1.1",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4        => '172.16.1.201',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.17.1.0",
                        gateway     => "172.16.1.1",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.17.1.201',
                        netmask     => "255.255.255.0",
                        route       => "add",
                        network     => "172.16.1.0",
                        gateway     => "172.17.1.1",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['CreateVDRPort'],
                             ['SetVDRPortProperty'],
                             ['AddConnection'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
			     # This makes sure connectivity across
			     # all end points.
                             ['TrafficAllHostAllSubnetVmknics'],
                             ['TrafficAllHostAllSubnetVMs'],
                             ['TrafficDifferentSubnetDifferentHost'],
                             ['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentSubnetDifferentHostVMs'],
                             ['TrafficDifferentSubnetDifferentHostVMs'],
			     ['TrafficDifferentSubnetDifferentHostVMs2'],
			     ['TrafficDifferentSubnetDifferentHostVMs3'],
			     ['TrafficDifferentSubnetDifferentHostVMsOvernight'],
                            ],
           ExitSequence  => [
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "TrafficAllHostAllSubnetVmknics" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[3]",
            },
            "TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               NoofInbound    => 3,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-4].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "10",
               #L4Protocol     => "udp,tcp",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               Routingscheme  => "multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHost2"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               #L4Protocol          => "udp,tcp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               TestAdapter          => "host.[2].vmknic.[3]",
               SupportAdapter       => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHostVMsOvernight"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
	       sleepBetweenCombos   => "50",
               TestDuration         => "600-6,50",
               #L4Protocol           => "tcp,udp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               ParallelSession      => "yes",
               TestAdapter          => "vm.[1].vnic.[1]",
               SupportAdapter       => "vm.[4].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "TrafficDifferentSubnetDifferentHostVMs"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               TestDuration         => "60",
               L4Protocol           => "tcp,udp",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               #ParallelSession      => "yes",
               TestAdapter          => "vm.[1].vnic.[1]",
               SupportAdapter       => "vm.[4].vnic.[1]",
            },
            "TrafficDifferentSubnetDifferentHostVMs2"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               # Make duration to 60 before checkin
               TestDuration         => "60",
               NoofOutbound         => "50",
               NoofInbound          => "50",
               ParallelSession      => "yes",
               # Broadcast won't work untill Product PR is fixed
               Routingscheme        => "multicast,unicast",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[3].vnic.[1]",
               MaxTimeout           => "9000",
            },
            "TrafficDifferentSubnetDifferentHostVMs3"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,48504,64564,80624,96684,112744,128804",
               ExpectedResult       => "Ignore",
               LocalSendSocketSize  => "131072-100,5000",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[3].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "SetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "SetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },

      'VLAN2VXLANTrafficDifferentHosts'   => {
         TestName         => 'VLAN2VXLANTrafficDifferentHosts',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-3]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-3]",
                        vmnicadapter => "host.[1-3].vmnic.[1]",
			# Bug in vdnet. vmnicadpater is called before
			# numuplinkports which tries to delete Uplink2-4
			# but a vmnicX already gets attached to it by then
			# we need dependency key here
			#numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-3]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-3Host-diffDI-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        controlplane => "activate",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        vdrportproperty=> "enable",
                        networktype    => "vlan",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
                        speed  => "1G",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddHost1Vmk1','AddHost2Vmk1'],
                             ['AddHost1Vmk2','AddHost2Vmk2'],
                             ['AddHost1Vmk3','AddHost2Vmk3'],
                             ['AddHost1Vmk4','AddHost2Vmk4'],
                             ['SetControlPlaneIP'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetHost1asLIF1DI'],
                             ['SetHost1asLIF2DI'],
                             ['TrafficDifferentHostAllSubnet'],
                             ['SetHost2asLIF1DI'],
                             ['SetHost2asLIF2DI'],
                             ['TrafficDifferentHostAllSubnet'],
                             ['SetHost3asLIF1DI'],
                             ['SetHost3asLIF2DI'],
                             ['TrafficDifferentHostAllSubnet'],
			     # Do the test again after flushing ARPs
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetHost3asLIF1DI'],
                             ['SetHost3asLIF2DI'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllHost1Vmks'],
                             ['RemoveAllHost2Vmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddHost1Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost3Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[3]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[3].netstack.[1]",
                  ipv4address => '172.16.1.300',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost3Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[3]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[3].netstack.[1]",
                  ipv4address => '172.16.1.301',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost3Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[3]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[3].netstack.[2]",
                  ipv4address => '172.17.1.300',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost3Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[3]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[3].netstack.[2]",
                  ipv4address => '172.17.1.301',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "SetNetstack1GatewayHost3" => {
               Type => "Netstack",
               TestNetstack => "host.[3].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2GatewayHost3" => {
               Type => "Netstack",
               TestNetstack => "host.[3].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
	       #TODO: Remove this. If througput is less than 10 on pHost its 
	       # a bug
               MinExpResult   => "1",
               TestDuration   => "120",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2-4]",
               MaxTimeout     => "9000",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            'RemoveAllHost3Vmks' => {
               Type => "Host",
               TestHost => "host.[3]",
               removevmknic => "host.[3].vmknic.[-1]",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "SetHost1asLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "SetHost1asLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[1]",
            },
            "SetHost2asLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[2]",
            },
            "SetHost2asLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetHost3asLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[3]",
            },
            "SetHost3asLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[3]",
            },
            "SetControlPlaneIP" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               controlplane => "setIP",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               controlplane => "deactivate",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
      # Blocked by bug 988558
      'VLANTrafficDifferentHostFalseConfig'   => {
         TestName         => 'VLANTrafficDifferentHostFalseConfig',
         Summary          => 'Verify VDR can route VLAN <-> VXLAN traffic ' .
                             ' on multiple hosts',
         Procedure        => '1. Create 1 VLAN and 1 VXLAN ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLAN and VXLAN '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on one host with test vNICs'.
                             '   on VLAN and the other VM on 2nd host with'.
									  '   test vNICs on VXLAN'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic',
                             '8. Send traffic in both directions VLAN <-> VXLAN',
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

       'VLANTrafficDifferentHostsChagingUplinks'   => {
         TestName         => 'VLANTrafficDifferentHostsChangingUplinks',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLANDiffHost-FalseConf-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        controlplane => "deactivate",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        vdrportproperty=> "enable",
                        networktype  => "vlan",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk5'],
                             ['AddVmk2','AddVmk6'],
                             ['AddVmk3','AddVmk7'],
                             ['AddVmk4','AddVmk8'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['TrafficAllHostAllSubnet'],
                             ['SetControlPlaneIPHost1False'],
                             ['TrafficAllHostAllSubnetIgnoreResult'],
                             ['ResetControlPlaneIPHost2'],
                             ['TrafficAllHostAllSubnetIgnoreResult'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetLIF1DIFalse'],
                             ['TrafficAllHostAllSubnetIgnoreResult'],
                             ['SetLIF1DI'],
                             ['ResetLIF2DI'],
                             ['TrafficAllHostAllSubnetIgnoreResult'],
                             ['SetLIF2DIToBroadcast'],
                             ['TrafficAllHostAllSubnetIgnoreResult'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['TrafficAllHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllHost1Vmks','RemoveAllHost2Vmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddVmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficAllHostAllSubnetIgnoreResult" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               TestDuration   => "30",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2-4]",
            },
            "TrafficAllHostAllSubnet" => {
               Type           => "Traffic",
               TestDuration   => "30",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2-4]",
               MaxTimeout     => "9000",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "SetLIF1DIFalse" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[2]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "ResetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
	       lifdesignatedinstanceip => "0.0.0.0"
            },
            "SetLIF2DIToBroadcast" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
	       lifdesignatedinstanceip => "255.255.255.255"
            },
            "SetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "SetControlPlaneIPHost1False" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "ResetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplaneip => "reset",
               host         => "host.[2]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
      'VLANTrafficDifferentHostChagingUplinks'   => {
         TestName         => 'VLANTrafficDifferentHostChangingUplinks',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts by'.
                             ' changing the uplinks to the VDS',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Now change the uplinks of the VDS and send'.
                             '         the traffic again. Verify the traffic'.
                             '         goes through'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      #TODO: increse to 3 vmnics team
      'VLANTrafficDifferentHostWithTeaming'   => {
         TestName         => 'VLANTrafficDifferentHostWithTeaming',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts with'.
                             ' teaming enabled',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Have multiple uplinks to the VDS and create a'.
                             '   team and test source port, source MAC and LAG'.
                             '   with different traffic'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'Interop',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
			# vdnet bug, 1-2 is not working for vmnic
                        vmnicadapter => "host.[1-2].vmnic.[1-2]",
                        mtu => "1600",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-DiffHost-Team-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        networktype  => "vlan",
                        vdrportproperty=> "enable",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.16.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.16.1.101',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.17.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[4]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.17.1.101',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  vdr => {
                     '[1]' => {
                        vdrname => "VLAN-DiffHost-Team-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        networktype  => "vlan",
                        vdrportproperty=> "enable",
                     },
                  },
                  netstack => {
                     '[1]' => {
                        name => "subnet16-netstack",
                     },
                     '[2]' => {
                        name => "subnet17-netstack",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.16.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        netstack    => "host.[1].netstack.[1]",
                        ipv4address => '172.16.1.201',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.17.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[4]' => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        netstack    => "host.[1].netstack.[2]",
                        ipv4address => '172.17.1.201',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
#                             ['AddVmk1','AddVmk5'],
#                             ['AddVmk2','AddVmk6'],
#                             ['AddVmk3','AddVmk7'],
#                             ['AddVmk4','AddVmk8'],
#                             ['SetLogLevel','DisableControlPlane'],
#                             ['CreateVDRPort'],
#                             ['AddConnection'],
#                             ['SetVDRPortProperty'],
                             ['CreateLIF1'],
                             ['CreateLIF2'],
                             ['SetLIF1DI'],
                             ['SetLIF2DI'],
                             ['SetControlPlaneIPHost1'],
                             ['SetControlPlaneIPHost2'],
                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
# TODO: remove this 
			     #['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
			     #['TrafficDifferentSubnetSameHost','TrafficDifferentSubnetSameHost2'],
			     #['TrafficSameSubnetDifferentHost'],
			     #['TrafficDifferentSubnetDifferentHost'],
			     #['TrafficDifferentSubnetDifferentHost2'],
                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
#                             ['RemoveAllHost1Vmks'],
#                             ['RemoveAllHost2Vmks'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddVmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.16.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.17.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk5' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk6' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.16.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk7' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk8' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.17.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.16.1.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.17.1.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               #TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               #TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2" => {
               Type           => "Traffic",
               #TestDuration   => "60",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               TestDuration   => "60",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               Routingscheme  => "unicast,multicast",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type                 => "Traffic",
               TestDuration         => "60",
               #L4Protocol          => "udp,tcp",
               NoofInbound          => "3",
               NoofOutbound         => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,96684,112744,128804",
               LocalSendSocketSize  => "131072",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "host.[2].vmknic.[1]",
               SupportAdapter       => "host.[1].vmknic.[3]",
               MaxTimeout           => "9000",
            },
            # Long Duration so not many combinations
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
	       #TODO: replace before checking
               TestDuration   => "2200",
	       #TestDuration   => "6000",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-4]",
               MaxTimeout     => "9000",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "ReSetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.16.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "16",
            },
            "SetLIF1DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet16lif",
               host         => "host.[1]",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet16lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
               lifip        => "172.17.1.1",
               lifnetmask   => "255.255.255.0",
               networktype => "vlan",
               lifnetworkid => "17",
            },
            "SetLIF2DI" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "setDI",
               lifname      => "subnet17lif",
               host         => "host.[2]",
            },
            "SetControlPlaneIPHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[1]",
            },
            "SetControlPlaneIPHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               controlplane => "setIP",
               host         => "host.[2]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "delete",
               lifname      => "subnet17lif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
         },
      },
     # VSE based test
     'VXLANTrafficSameHostWithNoLIF'   => {
         TestName         => 'VXLANTrafficSameHostNoLIF',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route to default route when' .
                             ' there is no corresponding route',
         Procedure        => '1. Create 2 VXLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VXLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with test vNICs on different'.
                             '   VNIs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '   Add a static ARP for the default gateway'.
                             '   on the VM'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM'.
                             '7. Now delete one LIF while the traffic is going
                                 on, VDR should route to the VSE for that
                                 particular traffic'.
                             '8. Add the LIF again, VDR should route to the
                                 destination listed in the LIF and not the
                                 default route'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      # VSE based test.
      'VLANTrafficSameHostWithNoLIF'   => {
         TestName         => 'VLANTrafficSameHostNoLIF',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route to default route when' .
                             ' there is no corresponding route',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with test vNICs on different'.
                             '   VLANs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM'.
                             '7. Now delete one LIF while the traffic is going
                                 on, VDR should route to the VSE for that
                                 particular traffic'.
                             '8. Add the LIF again, VDR should route to the
                                 destination listed in the LIF and not the
                                 default route'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VLAN2VXLANTrafficSameHostWithNoLIF'   => {
         TestName         => 'VLAN2VXLANTrafficSameHostNoLIF',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route to default route when' .
                             ' there is no corresponding route',
         Procedure        => '1. Create 1 VLAN and 1 VXLAN ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLAN and VXLAN (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with 1st VM vNICs on VLAN'.
                             '   and the other VM vNICs on VXLAN'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR and VDR should route it to the'.
                             '   destination VM'.
                             '7. Now delete one LIF while the traffic is going
                                 on, VDR should route to the VSE for that
                                 particular traffic'.
                             '8. Add the LIF again, VDR should route to the
                                 destination listed in the LIF and not the
                                 default route'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VXLANTrafficWithvNICOffloadsSameHost'   => {
         TestName         => 'VXLANTrafficWithvNICOffloadsSameHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route vNIC offloads traffic from
                              VMs to different VNIs on same host',
         Procedure        => '1. Create 2 VXLANs '.
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VXLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with vmxnet3 test vNICs on'.
                             '   different VNIs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send TCP/UDP/ICMP traffic between the VMs and'.
                             '   make sure it goes through. From the source VM'.
                             '   it should go to VDR and VDR should route it '.
                             '   to the destination VM'.
                             '7. Enable TX and RX CSO in the VMs and verify CSO
                                 happens as expected'.
                             '8. Enable TSO in the src VM and disable LRO in
                                 the dest VM and verify it receives TSO pkts'.
                             '9. Enable TSO in the src VM and enable LRO in
                                 the dest VM and verify it receives LRO pkts',
                             '10. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VLANTrafficWithVNICOffloadsSameHost'   => {
         TestName         => 'VLANTrafficWithvNICOffloadsSameHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route vNIC offloads traffic from
                              VMs to different VLANs on same host',
         Procedure        => '1. Create 2 VLANs ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLANs (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with vmxnet3 test vNICs on'.
                             '   different VLANs'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send TCP/UDP/ICMP traffic between the VMs and'.
                             '   make sure it goes through. From the source VM'.
                             '   it should go to VDR and VDR should route it '.
                             '   to the destination VM'.
                             '7. Enable TX and RX CSO in the VMs and verify CSO
                                 happens as expected'.
                             '8. Enable TSO in the src VM and disable LRO in
                                 the dest VM and verify it receives TSO pkts'.
                             '9. Enable TSO in the src VM and enable LRO in
                                 the dest VM and verify it receives LRO pkts',
                             '10. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VLANTrafficWithVNICOffloadsDifferentHost'   => {
         TestName         => 'VLANTrafficWithvNICOffloadsDifferentHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route vNIC offloads traffic from
                              VMs to different VLANs on different hosts',
         Procedure        => '1. Create 2 VLANs spanning across 2 hosts' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLANs (this will come from VSE) on
                                 each host'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with vmxnet3 test vNICs on'.
                             '   different VLANs on each host'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send TCP/UDP/ICMP traffic between the VMs and'.
                             '   make sure it goes through. From the source VM'.
                             '   it should go to VDR and VDR should route it '.
                             '   to the destination VM. Send the traffic to
                                 VMs on both the hosts'.
                             '7. Enable TX and RX CSO in the VMs and verify CSO
                                 happens as expected'.
                             '8. Enable TSO in the src VM and disable LRO in
                                 the dest VM and verify it receives TSO pkts'.
                             '9. Enable TSO in the src VM and enable LRO in
                                 the dest VM and verify it receives LRO pkts',
                             '10. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VXLANTrafficWithVNICOffloadsDifferentHost'   => {
         TestName         => 'VXLANTrafficWithvNICOffloadsDifferentHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route vNIC offloads traffic from
                              VMs to different VNIs on different hosts',
         Procedure        => '1. Create 2 VNIs spanning across 2 hosts' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VNIs (this will come from VSE) on
                                 each host'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs with vmxnet3 test vNICs on'.
                             '   different VNIs on each host'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send TCP/UDP/ICMP traffic between the VMs and'.
                             '   make sure it goes through. From the source VM'.
                             '   it should go to VDR and VDR should route it '.
                             '   to the destination VM. Send the traffic to
                                 VMs on both the hosts'.
                             '7. Enable TX and RX CSO in the VMs and verify CSO
                                 happens as expected'.
                             '8. Enable TSO in the src VM and disable LRO in
                                 the dest VM and verify it receives TSO pkts'.
                             '9. Enable TSO in the src VM and enable LRO in
                                 the dest VM and verify it receives LRO pkts',
                             '10. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VLAN2VXLANTrafficWithVNICOffloadsSameHost'   => {
         TestName         => 'VLAN2VXLANTrafficWithvNICOffloadsSameHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route vNIC offloads traffic from
                              VLAN VMs to VXLAN VMs on same host',
         Procedure        => '1. Create 1 VLAN and a VXLAN ' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between VLAN and VXLAN (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs on each host with vmxnet3 test vNICs and put'.
                             '   1st VM vNICs on VLAN and the other VM vNICs on VXLAN'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send TCP/UDP/ICMP traffic between the VMs and'.
                             '   make sure it goes through. From the source VM'.
                             '   it should go to VDR and VDR should route it '.
                             '   to the destination VM'.
                             '7. Enable TX and RX CSO in the VMs and verify CSO
                                 happens as expected'.
                             '8. Enable TSO in the src VM and disable LRO in
                                 the dest VM and verify it receives TSO pkts'.
                             '9. Enable TSO in the src VM and enable LRO in
                                 the dest VM and verify it receives LRO pkts'.
                             '10. Send traffic in both the directions from
                                  VLAN to VXLAN and also VXLAN to VLAN'.
                             '11. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VLAN2VXLANTrafficWithVNICOffloadsDifferentHosts'   => {
         TestName         => 'VLAN2VXLANTrafficWithvNICOffloadsDifferentHosts',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route vNIC offloads traffic from
                              VLAN VMs to VXLAN VMs on different hosts',
         Procedure        => '1. Create 1 VLAN and 1 VXLAN spanning across 2 hosts' .
                             '2. Create a VDR instance and add 2 LIFs to route'.
                             '   between the VLAN and VXLAN (this will come from VSE) on
                                 each host'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 2 VMs on each host with vmxnet3 test vNICs and put'.
                             '   1st VM vNICs on VLAN and the other VM vNICs on VXLAN'.
                             '5. In the VMs, set the default gateway to VDR'.
                             '6. Send TCP/UDP/ICMP traffic between the VMs and'.
                             '   make sure it goes through. From the source VM'.
                             '   it should go to VDR and VDR should route it '.
                             '   to the destination VM. Send the traffic to
                                 VMs on both the hosts'.
                             '7. Enable TX and RX CSO in the VMs and verify CSO
                                 happens as expected'.
                             '8. Enable TSO in the src VM and disable LRO in
                                 the dest VM and verify it receives TSO pkts'.
                             '9. Enable TSO in the src VM and enable LRO in
                                 the dest VM and verify it receives LRO pkts',
                             '10. Send traffic in both the directions from
                                  VLAN to VXLAN and also VXLAN to VLAN'.
                             '11. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'IPServicesOnVDR'   => {
         TestName         => 'IPServicesOnVDR',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR can provide IP services ' .
                             'like ping, traceroute, fragmentation and TTL',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Add 2 LIFs' .
                             '4. Now try to ping the IP address of the LIF'.
                             '5. It should respong to ping'.
                             '6. Run traceroute to IP address of the LIF'.
                             '7. traceroute should give the path to this IP'.
                             '8. Assign MTU 9000 to 1st LIF and 1500 to 2nd
                                                                                        LIF'.
                             '9. Send jumbo pkts on both the networks, 1st LIF
                                                                                        should allow jumbo pkts but the 2nd LIF should
                                                                                        fragment the pkts before sending out'.
                             '10. Send pkts with TTL 1 to both the LIFs'.
                             '11. The LIFs should drop the pkts'.
                             '12. Remove the LIFs, vdrb port and the VDR'.
                             '13. Verify VDR is removed successfully',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
     },
     'AddDeleteBridge'   => {
         TestName         => 'AddDeleteBridge',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge ports can be created ' .
                             'and deleted ',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Add 2 LIFs' .
                             '4. Configure a bridge with the 2 LIFs'.
                             '5. Verify the bridge is created'.
                             '6. Remove the LIFs, bridge, vdrb port and VDR'.
                             '7. Verify bridge & vdr are removed successfully',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vdr => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             #['EnableVDL2_1'],
                             ['CreateVXLANNetwork'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['SetVDRPortSinkProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFs'],
                            ],
           ExitSequence  => [
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "SetVDRPortSinkProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "bridge",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "16",
            },
            "BridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vlanlif",
               bridgeto     => "vxlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vlanlif",
               bridgeto     => "vxlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "DisableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "disablevdl2",
               TestSwitch      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
         },
      },
      'BridgeTrafficSameHost'   => {
         TestName         => 'BridgeTrafficSameHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on the same host',
         Procedure        =>
            '1. Create a DVS and create a vdrb port' .
            '2. Create a VDR instance'.
            '3. Create a VLAN and a VXLAN'.
            '4. Create 2 VMs with test vNICs on VLAN and'.
            '   VXLAN respectively'.
            '5. Add 2 LIFs for these 2 networks' .
            '6. Configure a bridge with the 2 LIFs'.
            '7. Verify the bridge is created'.
            '8. Send traffic between the test vNICs on each'.
            '   of the VMs. The bridge port should do the '.
            '   translation between VLAN/VXLAN and send the'.
            '   pkts to the destination VM'.
            '9. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,1host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]'   => {
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1'],
                             ['AddVmk2'],
                             ['AddVmk3'],
                             ['AddVmk4'],
                             #['EnableVDL2_1'],
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
                             ['ChangeVDL2VmknicIP'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['SetVDRPortSinkProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFs'],
                             ['SetNetstackGateway'],
                             ['TrafficSameNetworkSameHost'],
                             ['TrafficDifferentNetworkSameHost'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks'],
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost       => "host.[1]",
              IPAddr          => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_IP_A,
              Netmask         => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_NETMASK_A,
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "TrafficSameNetworkSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentNetworkSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1],host.[1].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[3],host.[1].vmknic.[4]",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortSinkProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "bridge",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "BridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            'RemoveAllVmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      # PSOD 986148
      'BridgeTrafficSameHostDifferentNetStack'   => {
         TestName         => 'BridgeTrafficSameHostDifferentNetStack',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on the same host',
         Procedure        =>
            '1. Create a DVS and create a vdrb port' .
            '2. Create a VDR instance'.
            '3. Create a VLAN and a VXLAN'.
            '4. Create 2 VMs with test vNICs on VLAN and'.
            '   VXLAN respectively'.
            '5. Add 2 LIFs for these 2 networks' .
            '6. Configure a bridge with the 2 LIFs'.
            '7. Verify the bridge is created'.
            '8. Send traffic between the test vNICs on each'.
            '   of the VMs. The bridge port should do the '.
            '   translation between VLAN/VXLAN and send the'.
            '   pkts to the destination VM'.
            '9. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,1host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1-2]'   => {
                     },
                  },
                  vdr => {
                     '[1]' => {
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1'],
                             ['AddVmk2'],
                             ['AddVmk3'],
                             ['AddVmk4'],
                             #['EnableVDL2_1'],
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
                             ['ChangeVDL2VmknicIP'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['SetVDRPortSinkProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFs'],
                             ['SetNetstackGateway'],
                             ['TrafficSameNetworkSameHost'],
                             ['TrafficDifferentNetworkSameHost'],
                             ['TrafficDifferentNetworkSameHost2'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks'],
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost       => "host.[1]",
              IPAddr          => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_IP_A,
              Netmask         => VDNetLib::Common::GlobalConfig::VDNET_VMKNIC_NETMASK_A,
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1-2]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "TrafficSameNetworkSameHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentNetworkSameHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentNetworkSameHost2" => {
               Type           => "Traffic",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[4]",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.21.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.21.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortSinkProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "bridge",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "BridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            'RemoveAllVmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      # PR 993138
      'BridgeTrafficDifferentHostJustPing'   => {
         TestName         => 'BridgeTrafficDifferentHostJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on different hosts'.
                             'with bridge on one of the hosts and bridge on'.
                             ' a 3rd host',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VLAN and a VXLAN'.
                             '4. Create 1 VM on each host with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '9. Delete the bridge and configure it again'.
                             ' with the 2 LIFs on a different host'.
                             '10. Verify the bridge is created'.
                             '11. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '12. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host,sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "21",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-Different-Host-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                        mtu    => "1600",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk3'],
                             ['AddVmk2','AddVmk4'],
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
			     ['ChangeVDL2VmknicIP'],
			     ['ChangeVDL2VmknicIP2'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['SetVDRPortSinkProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFsOnHost1'],
                             ['SetNetstackGateway'],
                             ['TrafficSameNetworkDifferentHost','TrafficSameNetworkDifferentHost2'],
                             ['TrafficDifferentNetworkSameHost','TrafficDifferentNetworkSameHost2'],
                             ['TrafficDifferentNetworkDifferentHost'],
                             ['TrafficDifferentNetworkDifferentHost2'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks1'],
                             ['RemoveAllVmks2'],
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.21.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.21.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.21.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "172.20.1.1",
              Netmask         => "255.255.0.0",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "172.20.1.2",
              Netmask         => "255.255.0.0",
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "TrafficDifferentNetworkSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "10",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentNetworkSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "20",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficSameNetworkDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "30",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
            },
            "TrafficSameNetworkDifferentHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "40",
               TestAdapter    => "host.[2].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentNetworkDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "50",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficDifferentNetworkDifferentHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[1]",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "2100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortSinkProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "bridge",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "2100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "21",
            },
            "BridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      'BridgeTrafficDifferentHost'   => {
         TestName         => 'BridgeTrafficDifferentHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on different hosts'.
                             'with bridge on one of the hosts and bridge on'.
                             ' a 3rd host',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VLAN and a VXLAN'.
                             '4. Create 1 VM on each host with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '9. Delete the bridge and configure it again'.
                             ' with the 2 LIFs on a different host'.
                             '10. Verify the bridge is created'.
                             '11. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '12. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "21",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-Different-Host-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                        mtu    => "1600",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk3'],
                             ['AddVmk2','AddVmk4'],
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
			     ['ChangeVDL2VmknicIP'],
			     ['ChangeVDL2VmknicIP2'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortVLANProperty'],
                             ['SetVDRPortVXLANProperty'],
                             ['SetVDRPortSinkProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFsOnHost1'],
                             ['SetNetstackGateway'],
                             ['TrafficSameNetworkDifferentHost','TrafficSameNetworkDifferentHost2'],
                             ['TrafficDifferentNetworkSameHost'],
                             ['TrafficDifferentNetworkSameHost2'],
                             ['TrafficDifferentNetworkDifferentHost'],
                             ['TrafficDifferentNetworkDifferentHost2'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks1'],
                             ['RemoveAllVmks2'],
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.21.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.21.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.21.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "172.20.1.1",
              Netmask         => "255.255.0.0",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "172.20.1.2",
              Netmask         => "255.255.0.0",
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "TrafficDifferentNetworkSameHost" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentNetworkSameHost2" => {
               Type           => "Traffic",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
	    # TODO: Remove all ExpectedResult => "Ignore", from below 4 workloads
            "TrafficSameNetworkDifferentHost" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
            },
            "TrafficSameNetworkDifferentHost2" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[2].vmknic.[2]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficDifferentNetworkDifferentHost" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[2]",
            },
            "TrafficDifferentNetworkDifferentHost2" => {
               Type           => "Traffic",
               ExpectedResult => "Ignore",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[1]",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "2100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortSinkProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "bridge",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "2100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "21",
            },
            "BridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      'BridgeTrafficDifferentHostWithVMsJustPing'   => {
         TestName         => 'BridgeTrafficDifferentHostWithVMsJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on different hosts'.
                             'with bridge on one of the hosts and bridge on'.
                             ' a 3rd host',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VLAN and a VXLAN'.
                             '4. Create 1 VM on each host with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '9. Delete the bridge and configure it again'.
                             ' with the 2 LIFs on a different host'.
                             '10. Verify the bridge is created'.
                             '11. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '12. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,2host,WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds      => "vc.[1].vds.[1]",
                        ports    => "8",
                        vlan     => "21",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			#TODO: uncomment before checking
			# speed  => "1G",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                        ipv4address => '172.21.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => '172.21.1.110',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			#TODO: uncomment before checking
			# speed  => "1G",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => '172.21.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => '172.21.1.210',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.21.1.102',
                        netmask    => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.21.1.112',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.21.1.202',
                        netmask    => "255.255.255.0",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.21.1.212',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
			     ['ChangeVDL2VmknicIP'],
			     ['ChangeVDL2VmknicIP2'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFsOnHost1'],
                             ['SetNetstackGateway'],
                             ['TrafficAllHostAllNetworkTypeVmknics'],
                             ['TrafficAllHostAllNetworkTypeVMs'],
                             ['TrafficDifferentNetworkTypeDifferentHost'],
                             ['TrafficDifferentNetworkTypeDifferentHost2'],
                             ['TrafficDifferentNetworkTypeDifferentHostVMs'],
                             ['TrafficDifferentNetworkTypeDifferentHostVMs2'],
                            ],
           ExitSequence  => [
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "TrafficAllHostAllNetworkTypeVmknics" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[3]",
            },
            "TrafficAllHostAllNetworkTypeVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofInbound    => 3,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-4].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "10",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHost2"  => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "5",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "host.[2].vmknic.[3]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHostVMs"  => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[4].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHostVMs2"  => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               NoofOutbound   => "10",
               NoofInbound    => "10",
               ParallelSession=> "yes",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               MaxTimeout     => "96000",
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "172.20.1.1",
              Netmask         => "255.255.0.0",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "172.20.1.2",
              Netmask         => "255.255.0.0",
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
	       # To get DHCP ip for VTEP vmknic
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "2100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlanAndVlanAndbridge",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "2100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "21",
            },
            "BridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC          => "vc.[1]",
               testHost        => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC          => "vc.[1]",
               testHost        => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      # PR 986927 
      'BridgeTrafficDifferentHostWithVMs'   => {
         TestName         => 'BridgeTrafficDifferentHostWithVMs',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on different hosts'.
                             'with bridge on one of the hosts and bridge on'.
                             ' a 3rd host',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VLAN and a VXLAN'.
                             '4. Create 1 VM on each host with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '9. Delete the bridge and configure it again'.
                             ' with the 2 LIFs on a different host'.
                             '10. Verify the bridge is created'.
                             '11. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '12. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'WithVMs',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds      => "vc.[1].vds.[1]",
                        ports    => "8",
                        vlan     => "21",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			#TODO: uncomment before checking
			# speed  => "1G",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                        ipv4address => '172.21.1.100',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => '172.21.1.110',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-DiffHost-VMs-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			#TODO: uncomment before checking
			# speed  => "1G",
                        mtu => "1600",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => '172.21.1.200',
                        netmask     => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => '172.21.1.210',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.21.1.102',
                        netmask    => "255.255.255.0",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.21.1.112',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        ipv4       => '172.21.1.202',
                        netmask    => "255.255.255.0",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver      => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4        => '172.21.1.212',
                        netmask     => "255.255.255.0",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
			     ['ChangeVDL2VmknicIP'],
			     ['ChangeVDL2VmknicIP2'],
                             ['DisableControlPlane'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetVDRPortProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFsOnHost1'],
                             ['SetNetstackGateway'],
                             ['TrafficAllHostAllNetworkTypeVmknics'],
                             ['TrafficAllHostAllNetworkTypeVMs'],
                             ['TrafficDifferentNetworkTypeDifferentHost'],
                             ['TrafficDifferentNetworkTypeDifferentHost2'],
                             ['TrafficDifferentNetworkTypeDifferentHostVMs'],
                             ['TrafficDifferentNetworkTypeDifferentHostVMs'],
			     ['TrafficDifferentNetworkTypeDifferentHostVMs2'],
			     ['TrafficDifferentNetworkTypeDifferentHostVMs3'],
			     ['TrafficDifferentNetworkTypeDifferentHostVMsOvernight'],
                            ],
           ExitSequence  => [
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
			     ['DisableVDL2_1'],
                            ],
            "TrafficAllHostAllNetworkTypeVmknics" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[3]",
            },
            "TrafficAllHostAllNetworkTypeVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "60",
               NoofInbound    => 3,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-4].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHost" => {
               Type           => "Traffic",
               ExpectedResult       => "Ignore",
               TestDuration   => "10",
               #L4Protocol     => "udp,tcp",
               NoofOutbound   => "3",
               NoofInbound    => "3",
               Routingscheme  => "multicast",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHost2"  => {
               Type                 => "Traffic",
               ExpectedResult       => "Ignore",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               #L4Protocol          => "udp,tcp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               TestAdapter          => "host.[2].vmknic.[3]",
               SupportAdapter       => "vm.[1].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHostVMsOvernight"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
	       sleepBetweenCombos   => "50",
               TestDuration         => "600-6,50",
               #L4Protocol           => "tcp,udp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               ParallelSession      => "yes",
               TestAdapter          => "vm.[1].vnic.[1]",
               SupportAdapter       => "vm.[4].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "TrafficDifferentNetworkTypeDifferentHostVMs"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               TestDuration         => "60",
               L4Protocol           => "tcp,udp",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               #ParallelSession      => "yes",
               TestAdapter          => "vm.[1].vnic.[1]",
               SupportAdapter       => "vm.[4].vnic.[1]",
            },
            "TrafficDifferentNetworkTypeDifferentHostVMs2"  => {
               Type                 => "Traffic",
               # TODO: Remove before checking
               ExpectedResult       => "Ignore",
               # Make duration to 60 before checkin
               TestDuration         => "60",
               NoofOutbound         => "50",
               NoofInbound          => "50",
               ParallelSession      => "yes",
               # Broadcast won't work untill Product PR is fixed
               Routingscheme        => "multicast,unicast",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[3].vnic.[1]",
               MaxTimeout           => "9000",
            },
            "TrafficDifferentNetworkTypeDifferentHostVMs3"  => {
               Type                 => "Traffic",
               # Make duration to 60 before checkin
               TestDuration         => "5",
               NoofOutbound         => "3",
               NoofInbound          => "3",
               BurstType            => "stream,rr",
               SendMessageSize      => "16384,32444,48504,64564,80624,96684,112744,128804",
               ExpectedResult       => "Ignore",
               LocalSendSocketSize  => "131072-100,5000",
               RemoteSendSocketSize => "131072",
               TestAdapter          => "vm.[2].vnic.[1]",
               SupportAdapter       => "vm.[3].vnic.[1]",
               MaxTimeout           => "96000",
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "172.20.1.1",
              Netmask         => "255.255.0.0",
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "172.20.1.2",
              Netmask         => "255.255.0.0",
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
	       # To get DHCP ip for VTEP vmknic
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "2100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlanAndVlanAndbridge",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "2100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "21",
            },
            "BridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC          => "vc.[1]",
               testHost        => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC          => "vc.[1]",
               testHost        => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      'BridgeTrafficDifferentHostAlreadyTagged'   => {
         TestName         => 'BridgeTrafficDifferentHostAlreadyTagged',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on different hosts'.
                             'with bridge on one of the hosts and bridge on'.
                             ' a 3rd host',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VLAN and a VXLAN'.
                             '4. Create 1 VM on each host with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '9. Delete the bridge and configure it again'.
                             ' with the 2 LIFs on a different host'.
                             '10. Verify the bridge is created'.
                             '11. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '12. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter     => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host           => "host.[1-2]",
                        vmnicadapter   => "host.[1-2].vmnic.[1]",
                        numuplinkports => "1",
                        mtu            => "1600",
			vxlan          => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
			# Even though its a VXLAN dvPG
                        vlan => "21",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "21",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname      => "Bridge-AlreadyTagged-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                        controlplane => "deactivate",
                        vdrport      => "create",
                        dvsname      => "vc.[1].vds.[1]",
                        Connection   => "add",
                        connectionid => "1",
                        vdrportproperty=> "enable",
                        networktype    => "vxlan",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                        mtu    => "1600",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ['AddVmk1','AddVmk3'],
                             ['AddVmk2','AddVmk4'],
                             #['EnableVDL2_1'],
                             ['CreateVTEP'],
                             ['CreateVXLANNetwork'],
			     #['ChangeVDL2VmknicIP'],
			     #['ChangeVDL2VmknicIP2'],
			     #['DisableControlPlane'],
			     #['CreateVDRPort'],
			     #['AddConnection'],
			     #['SetVDRPortProperty'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['BridgeBothLIFsOnHost1'],
                             ['SetNetstackGateway'],
			     ['TrafficDifferentNetworkTypeDifferentHost'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmks1'],
                             ['RemoveAllVmks2'],
                             ['UnBridgeBothLIFs'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            "TrafficDifferentNetworkTypeDifferentHost"  => {
               Type                 => "Traffic",
               # TODO: Negative testing 
               ExpectedResult       => "Ignore",
	       sleepBetweenCombos   => "50",
               TestDuration         => "100",
               L4Protocol           => "tcp,udp",
               NoofOutbound         => "1",
               NoofInbound          => "1",
               ParallelSession      => "yes",
               TestAdapter          => "host.[1-2].vmknic.[1]",
               SupportAdapter       => "host.[1-2].vmknic.[2]",
               MaxTimeout           => "96000",
            },
            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlanAndVlanAndbridge",
            },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.21.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.21.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.21.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "172.21.1.1",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "172.21.1.2",
              Netmask         => "255.255.255.0"
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "21",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "2100",
               MCASTIP        => "239.0.0.1",
            },
            "SetVDRPortSinkProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "bridge",
            },
            "SetVDRPortVLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetVDRPortVXLANProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlan",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "2100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "21",
            },
            "BridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFs" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            'RemoveAllVmks1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmks2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      'BridgeTraffic3HostDifferentBridges'   => {
         TestName         => 'BridgeTraffic3HostDifferentBridges',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VLAN/VXLAN on different hosts'.
                             'with bridge on one of the hosts and bridge on'.
                             ' a 3rd host',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VLAN and a VXLAN'.
                             '4. Create 1 VM on each host with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '9. Delete the bridge and configure it again'.
                             ' with the 2 LIFs on a different host'.
                             '10. Verify the bridge is created'.
                             '11. Send traffic between the test vNICs on each'.
                             '   of the VMs. The bridge port should do the '.
                             '   translation between VLAN/VXLAN and send the'.
                             '   pkts to the destination VM'.
                             '12. Remove the LIFs, bridge, vdrb port and VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1-3]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
			#configurehosts => "add",
			#host => "host.[1-3]",
			#vmnicadapter => "host.[1-3].vmnic.[1]",
                        numuplinkports => "1",
                        mtu => "1600",
			vxlan => "enable",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-3]'   => {
                  netstack => {
                     '[1]' => {
                        name => "Vxlan-netstack",
                     },
                     '[2]' => {
                        name => "Vlan-netstack",
                     },
                  },
                  vdr => {
                     '[1]' => {
                        vdrname => "Bridge-Different-Host-$$",
                        vdrloglevel  => "0",
                        vdrsetup     => "1",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                        mtu => "1600",
			#TODO: Remove before checkin
			#speed  => "1G",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence     => [
                             ['AddHostsToVDS'],
                             ['AddVmk1','AddVmk3'],
                             ['AddVmk2','AddVmk4','CreateVTEP'],
                             ['CreateVXLANNetwork'],
                             ['ChangeVDL2VmknicIP'],
                             ['ChangeVDL2VmknicIP2'],
                             ['ChangeVDL2VmknicIP3'],
                             ['CreateVDRPort'],
                             ['AddConnection'],
                             ['SetAllPropertiesOnVDRPort'],
                             ['CreateVXLANLIF'],
                             ['CreateVLANLIF'],
                             ['SetNetstackGateway'],
                             ['BridgeBothLIFsOnHost1'],
                             ['TrafficAllNetworkAllHost'],
                             ['UnBridgeBothLIFsOnHost1'],

                             ['BridgeBothLIFsOnHost2'],
                             ['TrafficAllNetworkAllHost'],
                             ['UnBridgeBothLIFsOnHost2'],

                             ['BridgeBothLIFsOnHost3'],
                             ['TrafficAllNetworkAllHost'],
			     #['UnBridgeBothLIFsOnHost3'],
                            ],
           ExitSequence  => [
                             ['RemoveAllVmksHost1'],
                             ['RemoveAllVmksHost2'],
                             ['DeleteLIF1'],
                             ['DeleteLIF2'],
                             ['DetachVDL2_1'],
                             ['RemoveVTEP'],
                             ['DeleteConnection'],
                             ['DeleteVDRPort'],
                            ],
            'AddHostsToVDS' => {
               Type           => "Switch",
               TestSwitch     => "vc.[1].vds.[1]",
	       configurehosts => "add",
	       host           => "host.[1-3]",
	       vmnicadapter   => "host.[1-3].vmnic.[1]",
	    },
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.21.1.200',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.21.1.201',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk3' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.21.1.100',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddVmk4' => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.21.1.101',
                  netmask     => "255.255.255.0",
               },
               },
            },
            "ChangeVDL2VmknicIP" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[2]",
              testHost        => "host.[2]",
              IPAddr          => "10.10.1.20",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP2" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[1]",
              testHost        => "host.[1]",
              IPAddr          => "10.10.1.10",
              Netmask         => "255.255.255.0"
            },
            "ChangeVDL2VmknicIP3" => {
              Type            => "VC",
              TestVC          => "vc.[1]",
              OPT             => "changevmknic",
              VDSIndex        => "vc.[1].vds.[1]",
              Host            => "host.[3]",
              testHost        => "host.[3]",
              IPAddr          => "10.10.1.30",
              Netmask         => "255.255.255.0"
            },
            "SetNetstackGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-2].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.21.1.1",
            },
            "TrafficAllNetworkAllHost" => {
               Type           => "Traffic",
	       #TODO: Remove this. If througput is less than 10 on pHost its 
	       # a bug
               MinExpResult   => "1",
               #L4Protocol     => "udp,tcp",
               TestAdapter    => "host.[1-2].vmknic.[1]",
               SupportAdapter => "host.[1-2].vmknic.[2]",
            },
            "EnableVDL2_1" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "enablevdl2",
               TestSwitch     => "vc.[1].vds.[1]",
            },
            "CreateVTEP" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "createvdl2vmknic",
               TestSwitch     => "vc.[1].vds.[1]",
               VLANID         => "0",
            },
            "CreateVXLANNetwork" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT            => "attachvdl2",
               TestSwitch     => "vc.[1].vds.[1]",
               TestPG         => "vc.[1].dvportgroup.[1]",
               VDL2ID         => "3100",
               MCASTIP        => "239.0.0.1",
            },
            "SetAllPropertiesOnVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vxlanAndvlanAndbridge",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               vdrport      => "create",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteVDRPort" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               vdrport      => "delete",
               dvsname      => "vc.[1].vds.[1]",
            },
            "AddConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               Connection   => "add",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            "CreateVXLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "add",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vxlan",
               lifnetworkid => "3100",
            },
            "CreateVLANLIF" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "add",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
               networktype  => "vlan",
               lifnetworkid => "17",
            },
            "BridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFsOnHost1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "BridgeBothLIFsOnHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFsOnHost2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[2].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "BridgeBothLIFsOnHost3" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[3].vdr.[1]",
               lif          => "addbridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "UnBridgeBothLIFsOnHost3" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[3].vdr.[1]",
               lif          => "deletebridge",
               lifname      => "vxlanlif",
               bridgeto     => "vlanlif",
            },
            "DeleteLIF1" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "remove",
               lifname      => "vlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "DeleteLIF2" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               lif          => "remove",
               lifname      => "vxlanlif",
               dvsname      => "vc.[1].vds.[1]",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "DisableControlPlane" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-3].vdr.[1]",
               controlplane => "deactivate",
            },
            "DetachVDL2_1" => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "detachvdl2",
               TestSwitch      => "vc.[1].vds.[1]",
               TestPG          => "vc.[1].dvportgroup.[1]",
            },
            'RemoveAllVmksHost1' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllVmksHost2' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            "RemoveVTEP"     => {
               Type            => "VC",
               TestVC         => "vc.[1]",
               testHost       => "host.[1]",
               OPT             => "removevdl2vmknic",
               TestSwitch      => "vc.[1].vds.[1]",
               VLANID          => "0",
            },
         },
      },
      'BridgeVXLAN2PhysicalHost'   => {
         TestName         => 'BridgeVXLAN2PhysicalHost',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that bridge port can bridge the ' .
                             'traffic between VXLAN and physical hosts',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance'.
                             '3. Create a VXLAN and configure VLAN on a'.
                             '   physical host'.
                             '4. Create 1 VM on a host with test vNIC on'.
                             '   VXLAN. Add one pNIC on physical host to the'.
                             '   test VLAN'.
                             '5. Add 2 LIFs for these 2 networks' .
                             '6. Configure a bridge with the 2 LIFs'.
                             '7. Verify the bridge is created'.
                             '8. Send traffic between the test vNIC and the'.
                             '   pNIC on the physical host. The bridge port '.
                             '   should do the translation between VLAN/VXLAN'.
                             '   and send the pkts to the destination host'.
                             '9. Remove the LIFs, bridge, vdrb port and VDR'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
       'EnableRoutingBridgingOnVDR'   => {
         TestName         => 'EnableRoutingBridgingOnVDR',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can enable both routing and ' .
                             'bridging on the VDR and both do their respective'.
                                                                          ' operations ',
         Procedure        => '1. Create a DVS and create a vdrb port' .
                             '2. Create a VDR instance on 2 hosts'.
                             '3. Create a VLAN1 and a VXLAN1 on 1 host and
                                                                                   create a different VXLAN on the 2nd host'.
                             '4. Create 2 VMs on host1 with test vNICs on'.
                             '   VLAN and VXLAN respectively'.
                             '5. Create 1 VM on host2 with test vNICs on'.
                             '   VXLAN2'.
                             '6. Add 2 LIFs for the 2 networks on host 1' .
                             '7. Configure a bridge with these 2 LIFs'.
                             '8. Verify the bridge is created'.
                             '9. Add 1 LIF on host2 to route pkts between
                                                                                   VXLAN2 and VXLAN1' .
                             '10. Send traffic between VXLAN2 and VLAN1.'.
                             '   The pkts should get routed first to VXLAN1'.
                             '   and then they should be bridged to VLAN1.'.
                             '11. Verify the traffic goes through'.
                             '12. Remove the LIFs, bridge, routes, vdrb port
                                                                                         and VDR and delete the VMs.'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'For2014',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
     'RouteVLANTrafficBetween2Tenants'   => {
         TestName         => 'RouteVLANTrafficBetween2Tenants',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify we cannot route pkts between 2 tenants'.
                             ' each with their own VDR.',
         Procedure        => '1. Create a DVS and create 2 VDR instances ' .
                             '2. Create 2 VLAN networks for each tenant'.
                             '3. Add 2 LIFs for each VDR for the networks'.
                             '   created so that it can route the pkts'.
                             '4. Create 2 VMs for each tenant with test vNICs'.
                             '   on each VLAN'.
                             '5. Send traffic between the 2 VMs in the same'.
                             '   tenant. VDR should route the traffic'.
                             '6. Send traffic between the 2 VMs on different'.
                             '   tenants. VDR should not be able to route the'.
                             '   traffic'.
                             '7. Assign same IPs for the respective interfaces
                                                                                        in both the tenants. There should not be IP
                                                                                        conflicts since the tenants cannot see each
                                                                                        other traffic'.
                             '8. Send traffic between the 2 VMs on different'.
                             '   tenants. VDR should not be able to route the'.
                             '   traffic'.
                             '9. Send traffic between the 2 VMs in the same'.
                             '   tenant. VDR should route the traffic'.
                             '10. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'RouteVXLANTrafficBetween2Tenants'   => {
         TestName         => 'RouteVXLANTrafficBetween2Tenants',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify we cannot route pkts between 2 tenants'.
                             ' each with their own VDR.',
         Procedure        => '1. Create a DVS and create 2 VDR instances ' .
                             '2. Create 2 VXLAN networks for each tenant'.
                             '3. Add 2 LIFs for each VDR for the networks'.
                             '   created so that it can route the pkts'.
                             '4. Create 2 VMs for each tenant with test vNICs'.
                             '   on each VXLAN'.
                             '5. Send traffic between the 2 VMs in the same'.
                             '   tenant. VDR should route the traffic'.
                             '6. Send traffic between the 2 VMs on different'.
                             '   tenants. VDR should not be able to route the'.
                             '   traffic'.
                             '7. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'SameVXLANDifferentHostsDifferentVDSes'   => {
         TestName         => 'SameVXLANDifferentHostsDifferentVDSes',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR can have VXLAN spanning across multiple VDSes'.
                             'on different hosts.',
         Procedure        => '1. Create 2 VDSes one on each host ' .
                             '2. Create a VDR spanning across both the VDSes'.
                             '3. Create a VXLAN network spanning across both the VDSes'.
                             '4. Add a LIFs for VDR for that network'.
                             '5. Create VMs with test vNICs on that VXLAN'.
                             '6. Send traffic between the 2 VMs.'.
                             '   The traffic should go through'.
                             '7. Also create a VLAN across 2 VDSes and route between VLAN
                                 and VXLAN'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'SameVXLANSameHostDifferentVDSes'   => {
         TestName         => 'SameVXLANSameHostDifferentVDSes',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR can have VXLAN spanning across multiple VDSes'.
                             'on same host.',
         Procedure        => '1. Create 2 VDSes one on same host ' .
                             '2. Create a VDR spanning across both the VDSes'.
                             '3. Create a VXLAN network spanning across both the VDSes'.
                             '4. Add a LIFs for VDR for that network'.
                             '5. Create VMs with test vNICs on that VXLAN'.
                             '6. Send traffic between the 2 VMs.'.
                             '   The traffic should go through'.
                             '7. Also create a VLAN across 2 VDSes and route between VLAN
                                 and VXLAN'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

       'AddMultipleIPsForLIF'   => {
         TestName         => 'AddMultipleIPsForLIF',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that multiple IPs can be set to a LIF' ,
         Procedure        => '1. Create a VDR instance' .
                             '2. Add a LIF to the VDR instance '.
                             '3. Verify LIF is added '.
                             '4. Add 8 different IPs which are on same subnet
                                 to the LIF. Verify traffic can be sent via
                                 those IPs'.
                             '5. Add 8 different IPs which are on different subnets
                                 to the LIF. Verify traffic can be sent via
                                 those IPs'.
                             '6. Delete LIFs from the VDR instance'.
                             '7. Delete the VDR instance'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # VDR control plane tests. These tests cover the following control plane
      # interactions..
      # VSM -> Host/Controller
      # Userworld -> Controller
      # Controller -> Userworld
      # VSE -> Userworld
      # VSM -> VSE

      'CreateVDRUsingVSM'   => {
         TestName         => 'CreateVDRUsingVSM',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can create VDR instance'.
                             ' using VSM.',
         Procedure        => '1. Create a VDS and crate a router dvport ' .
                             '2. Use VSM to create a VDR instance'.
                             '3. Once it is created VSM should push this info'.
                             '   to all the hosts in the VDR and to the'.
                             '   controller'.
                             '4. Check if the hosts and controller got this'.
                             '   info'.
                             '5. Delete the VDR instance from VSM'.
                             '6. VSM should propagate this info to the
                                 respective hosts and the controller'.
                             '7. Check if the instance is deleted from the
                                 hosts and the controller',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'CreateLIFsUsingVSM'   => {
         TestName         => 'CreateLIFsUsingVSM',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can create VDR instance'.
                             ' and LIFs using VSM.',
         Procedure        => '1. Use VSM to deploy a VSE and select the type as
                                 Distributed Router'.
                             '2. Select Enable flag for "hypervisorAssist".'.
                             '3. Confgure the mgmt interface which is used for
                                 HA, syslog and SSH for the VSE'.
                             '4. Try to configure upto 999 LIFs and make sure
                                 this info propagates to the hosts and controller'.
                             '5. Create the underlying stub networks for 4 LIFs
                                 and see if you can route between them'.
                             '6. Delete the configured LIFs and make sure
                                 this info propagates to the hosts and controller'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'UpdateLIFsUsingVSM'   => {
         TestName         => 'UpdateLIFsUsingVSM',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can update the LIFs using VSM.',
         Procedure        => '1. Create a VDS and crate a router dvport ' .
                             '2. Use VSM to create a VDR instance'.
                             '3. Once it is created VSM should push this info'.
                             '   to all the hosts in the VDR and to the'.
                             '   controller'.
                             '4. Check if the hosts and controller got this'.
                             '   info'.
                             '5. Create 2 LIFs using VSM'.
                             '6. VSM should propagate this info to the
                                 controller and the VSE'.
                             '7. Controller should send the LIFs info to all
                                 the hosts in the VDR'.
                             '8. The hosts now should add the LIFs to the local
                                 VDR instance'.
                             '9. Check if the controller received the LIFs
                                 info. Then check if hosts added that info to
                                 the local VDR instance'.
                             '10. Update 1 newley added LIF using VSM'.
                             '11. VSM should propagate this info to the
                                 controller and the VSE'.
                             '12. Controller should send the LIF info to all
                                 the hosts in the VDR'.
                             '13. The hosts now should update the LIF in the
                                 local VDR instance'.
                             '14. Check if the controller updated the LIF
                                 info. Then check if hosts updated this info in
                                 the local VDR instance'.
                             '15. Delete the LIFs and VDR instance from VSM'.
                             '16. VSM should propagate this info to the
                                 respective hosts and the controller'.
                             '17. Check if the instance & LIFs are deleted from
                                  the hosts and the controller',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'CreateSedimentedLIFsUsingVSM'   => {
         TestName         => 'CreateSedimentedLIFsUsingVSM',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can create VDR instance'.
                             ' and sedimented LIFs using VSM.',
         Procedure        => '1. Use VSM to deploy a VSE and select the type as
                                 Services Gateway (default)'.
                             '2. Select Enable flag for "hypervisorAssist". This flag
                                 controls the sedimentation.'.
                             '3. Next the we need to configure the appliances :
                                 resourcePool and datastore has to be selected for the placement'.
                             '4. Try to configure 9 vNICs for sedimented LIFs and make sure
                                 this info propagates to the hosts and controller'.
                             '5. With this edgeType, all features are available. But the NAT,
                                  firewall, routing will be sedimented to the hypervisor and
                                  other features like LB, VPN, etc will be served by the edgeVMs.
                                  Once created, the edgeType cannot be changed',
                             '6. Disable the configured vNICs for sedimented LIFs and make sure
                                 this info propagates to the hosts and controller'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'AddRoutesUsingVSE'   => {
         TestName         => 'AddRoutesUsingVSE',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can add routes to VDR instance'.
                             ' using VSE.',
         Procedure        => '1. Create a VDS and crate a router dvport ' .
                             '2. Use VSM to create a VDR instance and LIFs'.
                             '3. Use VSE to add new routes to VDR instance on a
                                 host. Add both static and dynamic routes'.
                             '4. VSE should propagate this info to the
                                 userworld on that particular host'.
                             '5. Userworld should send this info to the
                                 controller'.
                             '6. Controller now should propagate this info
                                 to all the hosts in the VDR instance'.
                             '7. Check if the route info is propagated to the
                                 controller'.
                             '8. Now check if all the hosts have the newly
                                 added routes both static and dynamic'.
                             '9. Delete these routes using VSE, LIFs and VDR
                                 instance using VSM'.
                             '10. VSM should propagate this info to the
                                 respective hosts and the controller'.
                             '11. Check if the instance and LIFs are deleted
                                  from the hosts and the controller',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

       'AddBlackholeRouteUsingVSE'   => {
         TestName         => 'AddBlackholeRouteUsingVSE',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that blackhole route can be added to VDR instance'.
                             ' using VSE.',
         Procedure        => '1. Create a VDS and crate a router dvport ' .
                             '2. Use VSM to create a VDR instance and LIFs'.
                             '3. Use VSE to add a blackhole route to VDR instance on a
                                 host.'.
                             '4. VSE should propagate this info to the
                                 userworld on that particular host'.
                             '5. Userworld should send this info to the
                                 controller'.
                             '6. Controller now should propagate this info
                                 to all the hosts in the VDR instance'.
                             '7. Check if the route info is propagated to the
                                 controller'.
                             '8. Now check if all the hosts have the newly
                                 added blackhole route'.
                             '9. Delete this route using VSE, LIFs and VDR
                                 instance using VSM'.
                             '10. VSM should propagate this info to the
                                 respective hosts and the controller'.
                             '11. Check if the instance and LIFs are deleted
                                  from the hosts and the controller',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

     'DeleteRoutesUsingVSE'   => {
         TestName         => 'DeleteRoutesUsingVSE',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can delete routes in VDR'.
                             ' using VSE.',
         Procedure        => '1. Create a VDS and crate a router dvport ' .
                             '2. Use VSM to create a VDR instance and LIFs'.
                             '3. Use VSE to add 2 routes to VDR instance on a
                                 host'.
                             '4. VSE should propagate this info to the
                                 userworld on that particular host'.
                             '5. Userworld should send this info to the
                                 controller'.
                             '6. Controller now should propagate this info
                                 to all the hosts in the VDR instance'.
                             '7. Check if the route info is propagated to the
                                 controller'.
                             '8. Now check in all the hosts if the route are
                                 added'.
                             '9. Use VSE to delete 1 newly added route'.
                             '10. VSE should propagate this info to the
                                 userworld on that particular host'.
                             '11. Userworld should send this info to the
                                 controller'.
                             '12. Controller now should propagate this info
                                 to all the hosts in the VDR instance'.
                             '13. Check if the route info is propagated to the
                                 controller'.
                             '14. Now check in all the hosts if the route is
                                 deleted'.
                             '15. Delete the remaining routes using VSE, LIFs
                                  and VDR instance using VSM'.
                             '16. VSM should propagate this info to the
                                 respective hosts and the controller'.
                             '17. Check if the instance and LIFs are deleted
                                  from the hosts and the controller',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'UpdateRoutesUsingVSE'   => {
         TestName         => 'UpdateRoutesUsingVSE',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can update routes in VDR'.
                             ' using VSE.',
         Procedure        => '1. Create a VDS and crate a router dvport ' .
                             '2. Use VSM to create a VDR instance and LIFs'.
                             '3. Use VSE to add 2 routes to VDR instance on a
                                 host'.
                             '4. VSE should propagate this info to the
                                 userworld on that particular host'.
                             '5. Userworld should send this info to the
                                 controller'.
                             '6. Controller now should propagate this info
                                 to all the hosts in the VDR instance'.
                             '7. Check if the route info is propagated to the
                                 controller'.
                             '8. Now check in all the hosts if the route are
                                 added'.
                             '9. Use VSE to update 1 newly added route'.
                             '10. VSE should propagate this info to the
                                 userworld on that particular host'.
                             '11. Userworld should send this info to the
                                 controller'.
                             '12. Controller now should propagate this info
                                 to all the hosts in the VDR instance'.
                             '13. Check if the route info is propagated to the
                                 controller'.
                             '14. Now check in all the hosts if the route is
                                 updated'.
                             '15. Delete the routes using VSE, LIFs
                                  and VDR instance using VSM'.
                             '16. VSM should propagate this info to the
                                 respective hosts and the controller'.
                             '17. Check if the instance & LIFs are deleted from
                                  the hosts and the controller',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'AddDeleteBridgeUsingVSM'   => {
         TestName         => 'AddDeleteBridgeUsingVSM',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that we can create a bridge'.
                             ' using VSM.',
         Procedure        => '1. This should work for both the edgeTypes "Servcies Gateway"
                                 and "Distributed Router"'.
                             '2. One end of the bridge has to be VLAN and the other has
                                 to be VXLAN. Trying same should fail'.
                             '3. One vlan or virtual-wire can be bridged only once.
                                 Bridging multiple times should fail'.
                             '4. The bridge source and destination inputs have to be on
                                 the same dvSwitch. Also try with different DVSes (this should
                                 not be allowed)'.
                             '5. Create the respective VLAN and VXLAN networks and send
                                 traffic between them and make sure the bridge
                                 bridges the traffic'.
                             '6. Remove the bridge and make sure it cleans up the state in
                                 VSM/VSE and also hosts',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

     'LIFDIReport'   => {
         TestName         => 'LIFDIReport',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller selects a DI and sends'.
                             ' LIF update msg when a new VLAN LIF is added to it.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'DISwichover'   => {
         TestName         => 'DISwichover',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller selects a new DI '.
                             ' when the original DI dies.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'DIAddnewhost'   => {
         TestName         => 'DIAddnewhost',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller keeps the same DI '.
                             ' when we add a new host on that VLAN.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'HostWithNoDI'   => {
         TestName         => 'HostWithNoDI',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that host requests controller to update DI '.
                             ' info if it doesnot know already. This is to
                               simulate the case when host controller connection goes
                              down and comes back up again and for some reason host
                              lost DI info',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # Not supported yet (Mar 2013)
      'VerifyErrorNotifications'   => {
         TestName         => 'VerifyErrorNotifications',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller reponds with proper error'.
                             ' codes when something goes wrong.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VDRQueryHost2Controller'   => {
         TestName         => 'VDRQueryHost2Controller',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller reponds with VDR tables'.
                             ' when the host sends a query msg.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'HostRebootScenarios'   => {
         TestName         => 'HostRebootScenarios',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Try host reboot for both stateful and
                              stateless host',
        Procedure        => '1. Verify that when the host reboots in the VDR environment
                                when it comes back up and cannot make connections
                                to either VSM or Controller it should just have VDR
                                instance info persisted in the UW and nothing else.'.
                            '2. But if it can make connection with just controller
                                then it should create VDR instance with the info in UW and
                                get the LIF/routes from controller.'.
                            '3. When the host can make connection to VSM too, it should get
                                the latest info from VSM and update the local info.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # Only soft flush, hard flush is not supported (for OP)
      'VDRFlushVSE2Controller'   => {
         TestName         => 'VDRFlushVSE2Controller',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that when VSE send a FLUSH msg to
                              controller, it flushes routing table for the '.
                             ' specified VDR instance in the controller.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # Host reboot scenario
      'VDRFlushController2Host'   => {
         TestName         => 'VDRFlushController2Host',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that when controller sends a FLUSH msg to
                              the host, it flushes routing table for the '.
                             'specified VDR instance in the host.',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # netcpa should keep on trying to connect to all the controllers in the
      # cluster until the VSM says there are no controllers
      'ReconnectController2Host'   => {
         TestName         => 'ReconnectController2Host',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that when controller is reconnected to
                              the host, it sends the route info again',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # Not required now (for OP)
      'UpdateKeepaliveInterval'   => {
         TestName         => 'UpdateKeepaliveInterval',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that Keepalive interval can be updated',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # Not required now (for OP)
      'UpdateConfigurationUsingReconfig'   => {
         TestName         => 'UpdateConfigurationUsingReconfig',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that Reconfig msg can be used to update'.
                             ' the configuration parameters',
         Procedure        => '' ,
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'UWAgentBooting' => {
         TestName         => 'UWAgentBooting',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify controller behavior during UW Agent'.
                             'Booting.',
         Procedure        =>
            '1. After the agent starts up, it sends a Control Plane Init message to'.
            ' the kernel. '.
            '2. Kernel deactivates all the VDR instances to keep track that it is'.
            ' going through the INIT process.'.
            '3. UW agent tries to setup message bus communication channel with
                VSM. If it is successful it sends a request to get the controller IP table from
                VSM. If it is unsuccessful it keeps on retrying. Controller IP table is also
                persisted on the UWA so it can start making the controller connections even if
                VSM connection is unsuccessful.'.
            '4. VSM responds with the controller IP table. UWA agent compares
                with its persisted information and applies the new configuration
                to UWA database making the necessary changes'.
            '5. UW agent picks one random controller IP out of the list and
                tries to make a connection. If it is unsuccessful it tries other controllers in
                round robin fashion'.
            '6. Once the connection is successful UW agent requests the
                sharding table from the controller. Controller will respond with the sharding
                data. UW makes connections with all controllers irrespective of
                sharding info but only one will be active for an instance
                others will be dormant until the main controller goes down'.
            '7. UWA agents query the VDR instance table from the VSM. VSM would
                respond with the data. If VSM connection is not available UWA
                also persists the VDRIDs and would try to create the VDR based
                on the persisted data.'.
            '8. UWA agent sends the information to Kernel to create the VDRs.'.
            '9. Based on the sharding data UW agent makes connection to the
                controllers for different VDR instances.'.
            '10. Once controller connection is successful UWA sends a LINK UP
                 to the Kernel. Kernel would respond with the VDR Instance JOIN.'.
            '11. Controller sends a SOFT FLUSH message for LIF and ROUTES to the
                 Kernel per IP FAM instance. This is required in the case when
                 Kernel already has some entries from past. These entries need
                 to be refreshed based on the latest controller information.'.
            '12. On receiving SOFT FLUSH messages Kernel marks ALL the LIFs and Routes for
		           the IP FAM in Soft Flush state.'.
            '13. Controller will then send the complete dump for LIFs and Routes. After
		           the DUMP it will also send a <EOM> to notify that he has sent all the
                 entries. <EOM> is nothing but an empty LIF update or empty route
                 update with no information.'.
            '14. On receiving the updates Kernel would remove the mark for the entries
                 that exists already. After <EOM> all the entries that still have the
                 mark would be deleted.'.
            '15. VDR should be operational at this stage.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VDRInitialSetup' => {
         TestName         => 'VDRInitialSetup',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR Instance creation scenario.',
         Procedure        =>
            '1. When a new VDR instance is created it checks if the control plane'.
            '   is active [agent already running].'.
            '2. If control plane is active kernel send the controller IP'.
            '   configuration for the VDR instance to Agent. UW gets the
                controller IPs from VSM.'.
            '3. If agent already has the connection to controller it sends the'.
            '   Link Change UP message directly to kernel. If not it would try to'.
            '   make a connection to controller and send the Link Change UP'.
            '   message when the connection is established.'.
            '4. Rest of the message exchange is similar to steps 6 to 11 as in UW'.
            '   Agent Booting.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VDRInstanceDeletionCleanup' => {
         TestName         => 'VDRInstanceDeletionCleanup',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify VDR Instance deletion scenario.',
         Procedure        =>
            '1. When a VDR instance is deleted from Kernel it checks if control'.
            '   plane is active [agent already running].'.
            '2. If control plane is active Kernel sends the VDR instance report to'.
            '   controller to delete the instance mapping from the controller. '.
            '3. Controller removes the instance mapping for that VDR removing the'.
            '   host from the connection list. If this is the last connection for'.
            '   the VDR, controller also cleans up all its tables.'.
            '4. Then Kernel sends the controller IP configuration with operation as'.
            '   DELETE for the VDR instance to UW Agent.'.
            '5. Agent checks if it is the last VDR instance that connects to the'.
            '   controller. If it is last connection, UW disconnects from'.
            '   controller and send LINK DOWN message to Kernel for the'.
            '   VDR instance. It does not actually disconnect the TCP connection
                with controller, it only cleans up the logical connection to clean
                up the state in controller.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VSEConnectionComingUP' => {
         TestName         => 'VSEConnectionComingUP',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller is affected '.
                             'by VSE Connection Coming up.',
         Procedure        =>
            '1. VSE makes a connection to UW. LINK_UP msg is sent to VSE
                when UW makes connection with controller.
                It is same like UW <-> kernel LINK_UP message.'.
            '1. VSE sends the SOFT FLUSH (Routes) to controller for the affected'.
            '   VDR instance.'.
            '2. Controller marks the routes in Soft Flush state. This would imply'.
            '   that the routes may be affected and VSE needs to send a Route'.
            '   Dump.'.
            '3. VSE sends the new route updates to controller. Controller clears'.
            '   the marks for existing routes.'.
            '4. VSE sends <EOM> once it is done sending all the updates. <EOM> is a'.
            '   Route update message with no information i.e. 0 ADDs and 0 Deletes.'.
            '5. Controller keeps sending new added routes to the hosts. On'.
            '   receiving <EOM> all the routes that are still marked are'.
            '   deleted from controller and updates are sent to host.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VSEConnectionGoingDown' => {
         TestName         => 'VSEConnectionGoingDown',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller is not affected '.
                             'by VSE Switchover.',
         Procedure        =>
            '1. UW Agent detects the VSE connection going down. No action is taken'.
            '   by the UW agent.'.
            '2. Kernel and Controller continues to use the existing route'.
            '   information learned from VSE.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VSEHA' => {
         TestName         => 'VSEHA',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when HA is enabled for VSE it doesnot
                              lose the connection to UW even duing failures.',
         Procedure        =>  ' ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VSEHASplitBrain' => {
         TestName         => 'VSEHASplitBrain',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'This is to simulate the split brain problem
                              by breaking the keepalive link between active
                              and standby VSEs.',
         Procedure        =>  ' ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VSMReboot' => {
         TestName         => 'VSMReboot',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that VSM connection coming up event is'.
                             'handled properly.',
         Procedure        =>
            '1. UW tires to connect to VSM, once it establishes the connection
                it queries the VSM for latest info'.
            '2. If the VSM is coming UP after going down VSM would not send again
                any information on its own. UW requests the information on VDR
                instances',
            '3. When the VSM goes down, controller detects it and no action is taken'.
            '4. Kernel and Controller continues to use the existing Instance/LIF'.
            '   information learned from VSM.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'ControllerLinkComingUp'   => {
         TestName         => 'ControllerLinkComingUp',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that controller coming up event is '.
                             'detected and following actions are done.',
         Procedure        =>
            '1. In controller link comes UP, UW agent detects it and send LINK UP'.
            '   message for each VDR instance to the host.'.
            '2. Kernel activates the control plane for each VDR instance.  Send'.
            '   instance report to the controller and enter an init state. In'.
            '   the state it marks all the LIFs and Routes and waits for'.
            '   updates from controller.'.
            '3. VSE also send the Instance JOIN message. And UW sends the Link UP to VSE'.
            '4. Controller sends the updates'.
            '   to Kernel and Kernel unmark the existing routes. Controller also'.
            '   sends an <EOM> at which the Kernel deletes all the marked Route'.
            '   entries as they are no longer present.'.
            '5. Controller request VSE for a resync of All route entries'.
            '8. VSE responds with Route information. Controller sends the
                updates to Kernel and Kernel unmark the existing routes. Controller
                also sends an <EOM> at which the Kernel deletes all the marked Route
                entries as they are no longer present',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'ControllerLinkGoingDown'   => {
         TestName         => 'ControllerLinkGoingDown',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that kernel deactives the Control Plane'.
                             ' for each host when controller link goes down (one
                               controller case).',
         Procedure        =>
            '1. In controller link goes down UW agent detects'.
               'it and send LINK DOWN message for each VDR instance to the host.'.
            '2. Controller will delete all the mappings learned from UW'.
            '3. UW sends LINK_DOWN to VSE and kernel'.
            '3. Kernel will deactivate the control plane for each VDR instance.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'MessageBusFailures'   => {
         TestName         => 'MessageBusFailures',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify that message bus failures doesnot directly'.
                             ' impact the working deployment even if it fails during
                               run time or if the communication is not UP in first place',
         Procedure        =>
            '1. The Hosts are isolated in such cases and should continue to
                run with the configuration present on them'.
            '2. When the connection comes back up UWA agent should query the vDR
                instance table from VSM. Based on the information UWA compare the
                vDR information and create or delete any new vDR instances',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      # Controller specific tests
      'DeployControllersUsingVSM'   => {
         TestName         => 'DeployControllersUsingVSM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify controllers can be deployed using VSM.'.
                             'They can be deployed using REST API or UI',
         Procedure        =>
            '1. Use REST API or UI to deploy the controllers'.
            '2. Verify the controllers are deployed and the VSM
                updates the hosts about the controllers'.
            '3. Verify the controllers push the sharding info to the hosts
                when the UW makes the connection with the controllers',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'DeleteControllersUsingVSM'   => {
         TestName         => 'DeleteControllersUsingVSM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify controllers can be deleted using VSM.'.
                             'They can be deleted using REST API or UI',
         Procedure        =>
            '1. Use REST API or UI to delete the controllers'.
            '2. Verify VSM throws proper error mesgs when the
                user tries to delete more than the allowed number
                of controllers for normal operation.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'AddNewVNIUsingVSM'   => {
         TestName         => 'AddNewVNIUsingVSM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when a new VNI is created using VSM'.
                             'it pushes that data to the controller cluster
                              even if no hosts are participating in that VNI.',
         Procedure        =>
            '1. Use REST API or UI to create a new VNI'.
            '2. Verify VSM updates the controllers about new VNI
                even if no hosts are participating in that VNI.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'DeleteAVNIUsingVSM'   => {
         TestName         => 'DeleteAVNIUsingVSM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when a VNI is deleted using VSM'.
                             'it pushes that data to the controller cluster
                              even if no hosts are participating in that VNI.',
         Procedure        =>
            '1. Use REST API or UI to delete a VNI'.
            '2. Verify VSM updates the controllers about this VNI
                deletion even if no hosts are participating in that VNI.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'CheckUWAndControllerConnections'   => {
         TestName         => 'CheckUWAndControllerConnections',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when a UW makes connections to the
                              respective controllers based on the sharding info',
         Procedure        =>
            '1. After the UW gets the controllers info from VSM
                make sure it makes connnections to the respective controllers
                based on the sharding info.'.
            '2. Then make sure UW sends the LINK UP messages to the kernel.',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'ControllerGoingDown'   => {
         TestName         => 'ControllerGoingDown',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when a controller goes down ZooKeeper
                              picks a new controller for the VNIs it is handling',
         Procedure        =>
            '1. When the controller goes down, the cluster should detect that
                and pass the VNIs the orignal controller is handling to the
                current functioning controllers.'.
            '2. Then it should send the new sharding info to all the UWs.'.
            '3. UWs should now make connections to these new controllers if
                required (when the host has respective VNIs)'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'ControllerComingUp'   => {
         TestName         => 'ControllerComingUp',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when a controller comes up the cluster
                              load balances the VNIs across this new controller too',
         Procedure        =>
            '1. When the controller comes up, the cluster should detect that
                and redistribute the VNIs among this controller too'.
            '2. Then it should send the new sharding info to all the UWs.'.
            '3. UWs should now make connections to these new controllers if
                required (when the host has respective VNIs)'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'AddNewControllers'   => {
         TestName         => 'AddNewControllers',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when new controllers are added to the cluster
                              using VSM, it updates the hosts about the new controllers',
         Procedure        =>
            '1. If there 3 controllers in the cluster initially, when we add 2 more
                using VSM, it should update the hosts about the new controllers'.
            '2. Then the cluster should compute new sharding table and it should
                send the new sharding info to all the UWs.'.
            '3. UWs should now make connections to these new controllers if
                required (when the host has respective VNIs)'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'DeleteControllers'   => {
         TestName         => 'DeleteControllers',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when controllers are deleted from the cluster
                              using VSM, it updates the hosts',
         Procedure        =>
            '1. If there 5 controllers in the cluster initially, when we delete 2
                using VSM, it should update the hosts about the remaining controllers'.
            '2. Then the cluster should compute new sharding table and it should
                send the new sharding info to all the UWs.'.
            '3. UWs should now make connections to these new controllers if
                required (when the host has respective VNIs)'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'HostControllerLinkDownUp'   => {
         TestName         => 'HostControllerLinkDownUp',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when host-controller link goes down for few secs
                              and comes back up, it is functional again',
         Procedure        =>
            '1. In a fully operating vxlan domain, disconnect the host from the
                network temporarily (by either shutting down the uplink, or vmknic,
                etc). Wait for 15 seconds'.
            '2. The master controllers will detect the host as down and updates all
                other VTEPs.  Now reconnect the host back to the network and it should
                re-establish connections with the controllers and download the relevant
                vni forwarding data',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'ControllerClusterGoingDown'   => {
         TestName         => 'ControllerClusterGoingDown',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when controller cluster goes down
                              things are still functional',
         Procedure        =>
            '1. When the whole cluster goes down, UW should detect that and send LINK
                DOWN to the kernel'.
            '2. The traffic should still flow based on the data that is already in the hosts'.
            '3. When the controller cluster comes back up, the sharding table should
                be computed again and send it to the hosts.'.
            '4. Now the UWs should make the respective connections with the
                controllers.'.
            '5. Also make cluster doesnot function unless there are at least
                2 controllers',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'PrepareHostsUsingVSM'   => {
         TestName         => 'PrepareHostsUsingVSM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify a cluster can be prepped using VSM',
         Procedure        =>
            '1. When the cluster is prepped, all hosts in the cluster should
                get the vibs installed and VTEP network should be created'.
            '2. If the preparation is successful, the cluster should go to
                ready state',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'UnprepareHostsUsingVSM'   => {
         TestName         => 'UnprepareHostsUsingVSM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify a cluster can be prepped using VSM',
         Procedure        =>
            '1. When the cluster is unprepped, all hosts in the cluster should
                unistall the vibs and delete the VTEP network'.
            '2. If the unprep is successful, the cluster should go to
                not ready state',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VmotionVM'   => {
         TestName         => 'VmotionVM',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when we vmotion a VM to a new host
                              it has connectivity to all the networks that it
                              has before',
         Procedure        =>
            '1. vmotioning a VM to a new host should not disrupt routing of
                traffic in/out of that VM'.
            '2. Bridging also should work',
            '3. vmotion the VM back to the original host, everything should
                work as expected'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VmotionController'   => {
         TestName         => 'VmotionController',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when we vmotion a controller to a new host
                              it serves the VDRs that it was serving before seamlessly',
         Procedure        =>
            '1. vmotioning a controller to a new host should service the VDRS with little
                interruption'.
            '2. Bridging also should work',
            '3. vmotion the controller back to the original host, everything should
                work as expected'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'VmotionVSE'   => {
         TestName         => 'VmotionVSE',
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'To verify when we vmotion a VSE to a new host
                              it serves the VDRs that it was serving before seamlessly',
         Procedure        =>
            '1. vmotioning a VSE to a new host should service the VDRs with little
                interruption'.
            '2. vmotion the controller back to the original host, everything should
                work as expected'.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'MultipleComponentsRebootScenarios'   => {
         TestName         => 'MultipleComponentsRebootScenarios',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'This is to verify the behavior when multiple
                              components in VDR environment are rebooted
                              at once or in intervals',
        Procedure        => '1. The first scenario is to reboot all hosts, VSE, VSM
                                and controllers'.
                            '2. Then try to reboot these components at random intervals',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'AddDeleteHostsInVLANCluster'   => {
         TestName         => 'AddDeleteHostsInVLANCluster',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'This is to verify the behavior when the hosts
                              in a cluster that are part of a VLAN are added
                              and/or deleted',
        Procedure        => '1. Setup the cluster for VLAN routing then add a new host to the
                                cluster and make sure it gets the LIF and routes info'.
                            '2. Delete the host from the cluster and make sure the LIFs and the
                                routes gets deleted from the host',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },

      'AddDeleteHostsInVXLANCluster'   => {
         TestName         => 'AddDeleteHostsInVXLANCluster',
         Category         => 'Networking',
         Component        => 'Virtual Router',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'This is to verify the behavior when the hosts
                              in a cluster that are part of a VXLAN are added
                              and/or deleted',
        Procedure        => '1. Setup the cluster for VXLAN routing then add a new host to the
                                cluster and make sure it gets the LIF and routes info'.
                            '2. Delete the host from the cluster and make sure the LIFs and the
                                routes gets deleted from the host',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },


   );
}

##########################################################################
# new --
#       This is the constructor for VDR TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VDR class
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
      my $self = $class->SUPER::new(\%VDR);
      return (bless($self, $class));
}

1;
