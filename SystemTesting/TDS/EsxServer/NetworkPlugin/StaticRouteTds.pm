#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::StaticRouteTds;

#
# This file contains the structured hash for category, StaticRoute tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %StaticRoute = (

      'ModifyExistingStaticRoute'   => {
         TestName         => 'ModifyExistingStaticRoute',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Modification of existing Static Route ' .
                             'in hostprofile verify static route status ',
         Procedure        =>
           '1. Add static Route to netstack instance  ' .
           '2. Extract Hostprofile '.
           '3. Edit network and prefix params of static route  ' .
           '4. Enter maintenance Mode ' .
           '   esxcli system maintenanceMode set --enable true ' .
           '5. Associate profile' .
           '6. Compliance Check' .
           '7. Apply Profile' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         PMT              => '',
         AutomationLevel  => 'Automated',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_Netstack,

         WORKLOADS => {
           Sequence => [
                        ["AddVmknicInterface"],
                        ["SetNetStackGateway"],
                        ["CreateProfile"],
                        ["ModifyNetStackGateway"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["GetAnswerFile"],
                        ["ApplyProfile"],
                       ],
           ExitSequence =>
                       [
                        ["DeleteVmknicInterface"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                       ],

            "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                vmknic => {
                "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
                },
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                deletevmknic => "host.[1].vmknic.[2]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1].x.[x]",
               compliancestatus => "nonCompliant",
            },
            "GetProfileInfo" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               Getprofileinfo => "testprofile",
               subprofile     => "networkprofile",
            },
            "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               SrcHost        => "host.[1].x.[x]",
               exportanswerfile => "myanswerfile.xml",
            },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               getanswerfile => "screen",
               SrcHost       => "host.[1].x.[x]",
            },
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               importanswer   => "myanswerfile.xml",
               SrcHost       => "host.[1].x.[x]",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               createprofile  => "profile",
               SrcHost        => "host.[1].x.[x]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               associateprofile  => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               applyprofile   => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               destroyprofile => "testprofile",
            },
           "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "false",
           },
           "ModifyNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::EDIT_NETWORK_1,
           },
           "SetNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
        },
      },
      'AddNewStaticRoute'   => {
         TestName         => 'AddNewStaticRoute',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Addition of new static route and verify static route status ' .
                             'in hostprofile ',
         Procedure        =>
           '1. Add static route to default instance '.
           '2. Extract Hostprofile '.
           '3. Delete the static route from host ' .
           '4. Enter maintenance Mode ' .
           '5. Associate profile' .
           '6. Compliance check' .
           '7. Verify that older static route is added back after apply' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         AutomationStatus => 'Automated',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_Netstack,

        WORKLOADS => {
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["AddVmknicInterface"],
                        ["SetNetStackGateway"],
                        ["CreateProfile"],
                        ["GetProfileInfo"],
                        ["RemoveNetStackGateway"],
                        ["DeleteVmknicInterface"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                       ],
           ExitSequence =>
                        [
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"] ],

            "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                vmknic => {
                "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
                },
            },
           "GetProfileInfo" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               Getprofileinfo => "testprofile",
               subprofile     => "networkprofile",
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                deletevmknic => "host.[1].vmknic.[2]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1].x.[x]",
               compliancestatus => "nonCompliant",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               createprofile  => "profile",
               SrcHost        => "host.[1].x.[x]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               associateprofile  => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               applyprofile   => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               destroyprofile => "testprofile",
           },
           "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "true",
           },

           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "false",
           },
           "SetNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
           "RemoveNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "remove",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
        },
      },
      'RemoveExistingStaticRoute'   => {
         TestName         => 'RemoveExistingStaticRoute',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Addition of new static route and verify status route status ' ,
         Procedure        =>
           '1. Extract Hostprofile '.
           '2. Add static route to default instance '.
           '3. Enter maintenance Mode ' .
           '4. Compliance check' .
           '5. Apply Profile' .
           '6. Verify that added static route is deleted from host after apply' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         PMT              => '',
         AutomationLevel  => 'Automated',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_Netstack,

         WORKLOADS => {
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["AddVmknicInterface"],
                        ["CreateProfile"],
                        ["SetNetStackGateway"],
                        ["AssociateProfile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                       ],
           ExitSequence =>
                        [
                        ["DeleteVmknicInterface"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],

            "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                vmknic => {
                "[2]" =>{
                  portgroup => "vc.[1].dvportgroup.[2]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
                },
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                deletevmknic => "host.[1].vmknic.[2]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1].x.[x]",
               compliancestatus => "nonCompliant",
            },
            "GetProfileInfo" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               Getprofileinfo => "testprofile",
               subprofile     => "networkprofile",
            },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               getanswerfile => "screen",
               SrcHost       => "host.[1].x.[x]",
            },
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               importanswer   => "myanswerfile.xml",
               SrcHost       => "host.[1].x.[x]",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               createprofile  => "profile",
               SrcHost        => "host.[1].x.[x]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               associateprofile  => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               applyprofile   => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               destroyprofile => "testprofile",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               SrcHost        => "host.[1].x.[x]",
               exportanswerfile => "myanswerfile.xml",
           },
           "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "false",
           },
           "SetNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
        },
      },
      'RemoveExistingStaticRouteVSS'   => {
         TestName         => 'RemoveExistingStaticRouteVSS',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Addition of new static route and verify status route status ' ,
         Procedure        =>
           '1. Extract Hostprofile '.
           '2. Add static route to default instance '.
           '3. Enter maintenance Mode ' .
           '4. Associate Profile' .
           '5. Compliance Check' .
           '6. Apply Profile' .
           '5. Verify that added static route is deleted from host after apply' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVSS_Netstack,

         WORKLOADS => {
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["AddVmknicInterface"],
                        ["CreateProfile"],
                        ["SetNetStackGateway"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                       ],
           ExitSequence =>
                       [
                        ["DeleteVmknicInterface"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                       ],

           "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                vmknic => {
                "[2]" =>{
                  portgroup => "host.[1].portgroup.[2]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1].x.[x]",
                deletevmknic => "host.[1].vmknic.[2]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1].x.[x]",
               compliancestatus => "nonCompliant",
            },
            "GetProfileInfo" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               Getprofileinfo => "testprofile",
               subprofile     => "networkprofile",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               createprofile  => "profile",
               SrcHost        => "host.[1].x.[x]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               associateprofile  => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               applyprofile   => "testprofile",
               SrcHost        => "host.[1].x.[x]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => 'vc.[1].x.[x]',
               destroyprofile => "testprofile",
           },
           "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "false",
           },
           "SetNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
        },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for StaticRouteTds
#
# Input:
#       none
#
# Results:
#       An instance/object of StaticRouteTds class
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
   my $self = $class->SUPER::new(\%StaticRoute);
   return (bless($self, $class));
}

1;
