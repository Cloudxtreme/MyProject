#######################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::MaintenanceModeNetworkProfileTds;

#
# This file contains the structured hash for category, NetworkPlugin tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS

   %MaintenanceModeNetworkProfile = (
      'HostPortGroupNetworkSecurityPolicy'   => {
         TestName         => 'HostPortGroupNetworkSecurityPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkSecurityPolicy maintenance mode status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkSecurityPolicy ' .
           '5. Select NewFixedSecurityPolicyOption  ' .
           '6. Change policy option: allowPromiscuous, ' .
           '7. Get maintenance mode status' .
           '9. Change policy option: forgedTransmits ' .
           '10. Get maintenance mode status' .
           '11. Change policy option: macChanges' .
           '12. Get maintenance mode status',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => 2,
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         'WORKLOADS' => {
              Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_allowPromiscuous"],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_macChanges"],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_forgedTransmits"],
              ["GetMaintenanceModeStatus"],
          ],
          'Duration' => 'time in seconds',
          'CreateProfile' => {
            'Type'        => 'Host',
            'TestHost'    => 'host.[1]',
            'createprofile' => 'extractprofile',
            'hostprofilefile'     => '/tmp/hp.xml',
          },
          'GenerateAnswerFile' => {
            'Type'         => 'Host',
            'TestHost'     => 'host.[1]',
            'generateanswerfile'  => 'genanswerfile',
            'hostprofilefile'     => '/tmp/hp.xml',
            'answerfile'   => '/tmp/ans.xml',
          },
          'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
          },
          'Edit_allowPromiscuous' => {
	    Type     => 'Host',
	    TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid  => VDNetLib::TestData::TestConstants::SECURITY_POLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::SECURITY_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::ALLOW_PROMISCUOUS,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
          },
          'Edit_macChanges' => {
	    Type     => 'Host',
	    TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid  => VDNetLib::TestData::TestConstants::SECURITY_POLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::SECURITY_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::MAC_CHANGE,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
          },
          'Edit_forgedTransmits' => {
	    Type     => 'Host',
	    TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::SECURITY_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::SECURITY_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::FORGE_TRANSMITS,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
          },
        },
      },
      'HostPortGroupNetworkTrafficShapingPolicy'   => {
         TestName         => 'HostPortGroupNetworkTrafficShapingPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkSecurityPolicy maintenance mode status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NewFixedTrafficShapingPolicy ' .
           '5. Select FixedTrafficShapingPolicyOption ' .
           '6. Edit averageBandwidth ' .
           '7. Edit peakBandwidth ' .
           '8. Edit burstSize  ' .
           '9. Enable Traffic Shaping ' .
           '10. get maintenance mode status',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_SHAPING_AVERAGE_BANDWIDTH'],
              ['Edit_SHAPING_PEAK_BANDWIDTH'],
              ['Edit_SHAPING_BURST_SIZE'],
              ['Edit_SHAPING_ENABLE'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_SHAPING_ENABLE' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::ENABLED,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
          },
         'Edit_SHAPING_AVERAGE_BANDWIDTH' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::AVERAGE_BANDWIDTH,
            value   => VDNetLib::TestData::TestConstants::AVERAGE_BANDWIDTH_VALUE,
         },
         'Edit_SHAPING_PEAK_BANDWIDTH' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::PEAK_BANDWIDTH,
            value   => VDNetLib::TestData::TestConstants::PEAK_BANDWIDTH_VALUE,
         },
         'Edit_SHAPING_BURST_SIZE' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::BURST_SIZE,
            value   => VDNetLib::TestData::TestConstants::BURST_SIZE_VALUE,
         },
       },
      },
      'HostPortGroupNetworkNicOrderPolicy'   => {
         TestName         => 'HostPortGroupNetworkNicOrderPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkNicOrderPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkNicOrderPolicy ' .
           '5. Select FixedNicOrdering option   ' .
           '6. Edit NIC Order' .
           '7. Edit STANDBY NIC Order' .
           '8. Get maintenance mode status',
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NIC_ORDER'],
              ['Edit_NIC_ORDER_STANDBY'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
            'expectedresult'   => 'FAIL' ,
         },
         'Edit_NIC_ORDER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::ACTIVE_NICS,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_NIC_0,
         },
         'Edit_NIC_ORDER_STANDBY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::FIXEDNICORDERING_STANDBYNICS,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_NIC,
         },
       },
      },
      'HostPortGroupNetworkNicTeamingPolicy'   => {
         TestName         => 'HostPortGroupNetworkNicTeamingPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkNicTeamingPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Change teaming policy=loadbalance_srcid ' .
           '          failover_explicit' .
           '          loadbalance_ip ' .
           '          loadbalance_srcmac ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_IP'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCID'],
              ["GetMaintenanceModeStatus_1"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCMAC'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_LOADBASED_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_EXPLICIT'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'GetMaintenanceModeStatus_1' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_TEAMING_ROLLING_ORDER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_ROLLING_ORDER,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
          },
          'Edit_TEAMING_NOTIFY_SWITCHES' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_NOTIFY_SWITCHES,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
         'Edit_NICTEAM_IP' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_IP,
          },
         'Edit_NICTEAM_SRCID' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_SRCID,
         },
         'Edit_NICTEAM_SRCMAC' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_SRCMAC,
         },
         'Edit_NICTEAM_LOADBASED_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_LOADBASED,
            expectedresult => "FAIL",
         },
         'Edit_NICTEAM_EXPLICIT' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_EXPLICIT,
         },
       },
      },
      'HostPortGroupNetworkNicTeamingRollingOrder'   => {
         TestName         => 'HostPortGroupNetworkNicTeamingRollingOrder',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkNicTeaming Rolling Order maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Edit rollingOrder=False/True  ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_TEAMING_ROLLING_ORDER'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_TEAMING_ROLLING_ORDER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_ROLLING_ORDER,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'HostPortGroupNetworkNicTeamingNotifySwitch'   => {
         TestName         => 'HostPortGroupNetworkNicTeamingNotifySwitch',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkNicTeaming Notify Switch maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Edit notifySwitches=False/True ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_TEAMING_NOTIFY_SWITCHES'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
          'Edit_TEAMING_NOTIFY_SWITCHES' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_NOTIFY_SWITCHES,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'HostPortGroupMtuPolicy'   => {
         TestName         => 'HostPortGroupMtuPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup Mtu Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select MtuPolicy' .
           '5. Select FixedMtuOption   ' .
           '6. Edit MTU Size ' .
	   '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_HOSTPROUGP_MTU'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_HOSTPROUGP_MTU' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid => VDNetLib::TestData::TestConstants::VNICPROFILE_MTUPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::VNICPROFILE_MTUPOLICY_FIXEDMTUOPTION,
            name    => VDNetLib::TestData::TestConstants::VSWITCH_MTU_NAME,
            value   => VDNetLib::TestData::TestConstants::VSWITCH_MTU_VALUE,
         },
       },
      },
      'HostPortGroupMacAddressPolicy'   => {
         TestName         => 'HostPortGroupMacAddressPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup MacAddress Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select MacAddressPolicy' .
           '5. Select UserInputMacAddress   ' .
           '6  Edit Mac address policy ' .
	   '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Change_MAC_ADDRESS_Option'],
              ['Edit_HOSTPROUGP_MAC_ADDRESS'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Change_MAC_ADDRESS_Option' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid => VDNetLib::TestData::TestConstants::VNICPROFILE_MACADDRESS_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::VNICPROFILE_MACADDRESS_OPTION,
         },
         'Edit_HOSTPROUGP_MAC_ADDRESS' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid => VDNetLib::TestData::TestConstants::VNICPROFILE_MACADDRESS_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::VNICPROFILE_MACADDRESS_OPTION,
            name    => VDNetLib::TestData::TestConstants::VNICPROFILE_MAC_KEY,
            value   => VDNetLib::TestData::TestConstants::VNICPROFILE_MAC_VALUE,
         },
       },
      },
      'HostPortGroupVlanPolicy'   => {
         TestName         => 'HostPortGroupVlanPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup Vlan Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VlanIdPolicy' .
           '5. Select FixedVlanIdOption   ' .
           '5. Select FixedVirtualNICNameOption   ' .
           '6. Edit VlanId  ' .
           '7. Get maintenance mode status',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VLAN'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_VLAN' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_VLAN_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VLANPROFILE_VLANIDPOLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION,
            name => VDNetLib::TestData::TestConstants::VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION_VLANID,
            value => VDNetLib::TestData::TestConstants::VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION_VLANID_VALUE,
         },
       },
      },
      'HostPortGroupVMKNicNamePolicy'   => {
         TestName         => 'HostPortGroupVMKNicNamePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup Vmknic Name Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICNamePolicy' .
           '5. Select FixedVirtualNICNameOption   ' .
           '6. Edit Vmknic Name  ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VMKName'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_VMKName' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY_FIXED_OPTION,
            name => VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY_PARAM_NAME,
            value   => VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY_PARAM_VALUE,
         },
       },
      },
      'HostPortGroupNicTypePolicy'   => {
         TestName         => 'HostPortGroupNicTypePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup NicType Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICTypePolicy' .
           '5. Select FixedNICTypeOption  ' .
           '6. Edit HostPorgroup NicType ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NicType'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_NicType' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_TYPE_POLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::VIRTUAL_NIC_TYPE_OPTION,
            name => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_NAME,
            value   => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_VALUE,
         },
       },
      },
      'HostPortGroupVnicInstancePolicy'   => {
         TestName         => 'HostPortGroupVnicInstancePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup Virtual NIC Instance Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICInstancePolicy' .
           '5. Select FixedVirtualNICInstanceOption  ' .
           '6. Edit HostPorgroup Virtual NIC Instance Policy ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_Instance_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_Instance'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_Instance' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUALNICINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::VIRTUALNICINSTANCEPOLICY_FIXED_OPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_NAME,
            value   => VDNetLib::TestData::TestConstants::DEFAULTNETSTACKINSTANCE_NAME,
         },
         'Edit_Instance_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUALNICINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::VIRTUALNICINSTANCEPOLICY_FIXED_OPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_NAME,
            value   => VDNetLib::TestData::TestConstants::DEFAULTNETSTACKINSTANCE_INVALID_NAME,
            expectedresult => "FAIL",
         },
       },
      },
      'HostPortGroupVMKNicPolicy'   => {
         TestName         => 'HostPortGroupVMKNicPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup VMKNic Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICNamePolicy' .
           '5. Select FixedVirtualNICNameOption   ' .
           '6. Edit HostPorgroup VMKNic Policy ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VMKName'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_VMKName' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY_FIXED_OPTION,
            name => VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY_PARAM_NAME,
            value   => VDNetLib::TestData::TestConstants::VIRTUALNICNAMEPOLICY_PARAM_VALUE,
         },
       },
      },
      'HostPortGroupNetworkFailoverPolicy'   => {
         TestName         => 'HostPortGroupNetworkFailoverPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify NetworkFailoverPolicy maintenance mode status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkFailoverPolicy' .
           '5. Select NewFixedFailoverCriteria  ' .
           '6. Change checkBeacon = false ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_FAILOVER'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_FAILOVER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
            policyid => VDNetLib::TestData::TestConstants::FAILOVER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::FAILOVER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::CHECK_BEACON,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'HostPortGroupAutoconfPolicy'   => {
         TestName         => 'HostPortGroupAutoconfPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup AutoConf maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select StatelessAutoconfPolicy' .
           '5. Select StatelessAutoconfOption   ' .
           '6. Edit HostPorgroup STATELESS AUTOCONF POLICY ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATELESSAUTOCONFPOLICY'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_STATELESSAUTOCONFPOLICY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_IPADDRESS_PATH,
            policyid  => VDNetLib::TestData::TestConstants::STATELESSAUTOCONFPOLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::STATELESSAUTOCONFPOLICY_OPTION,
            name => VDNetLib::TestData::TestConstants::STATELESSAUTOCONFPOLICY_PARAM_NAME,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_FALSE,
         },
       },
      },
      'HostPortGroupFixedDhcp6Policy'   => {
         TestName         => 'HostPortGroupFixedDhcp6Policy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify HostPortGroup Fixed Dhcp6 Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select FixedDhcp6Policy' .
           '5. Select FixedDhcp6Option   ' .
           '6. Edit HostPorgroup GroupFixedDhcp6Policy ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_FixedDhcp6Policy'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_FixedDhcp6Policy' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_IPADDRESS_PATH,
            policyid  => VDNetLib::TestData::TestConstants::FIXEDDHCP6POLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::FIXEDDHCP6POLICY_OPTION,
            name => VDNetLib::TestData::TestConstants::FIXEDDHCP6POLICY_PARAM_NAME,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'VswitchLinkSpecPolicyPnicsbyName'   => {
         TestName         => 'VswitchLinkSpecPolicyPnicsbyName',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify VswitchLinkSpecPolicyPnicsbyName maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select LinkSpecPolicy' .
           '5. Select PnicsByName    ' .
           '6. Change nicName = vmnic2 ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VSWITCH_LINKSPEC'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_VSWITCH_LINKSPEC' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_LINK_PATH,
            policyid => VDNetLib::TestData::TestConstants::VSWITCH_LINKSPEC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::VSWITCH_LINKSPEC_OPTION,
            name    => VDNetLib::TestData::TestConstants::VSWITCH_NICNAME,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_NIC_0,
         },
       },
      },
      'VswitchBeaconConfigPolicy'   => {
         TestName         => 'VswitchBeaconConfigPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify VswitchBeaconConfigPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Vswitch Profile '.
           '4. Select BeaconConfigPolicy' .
           '5. Select NewFixedBeaconConfig  ' .
           '6. Edit interval = 2 ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VSWITCH_BEACONCONFIG'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_VSWITCH_BEACONCONFIG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_LINK_PATH,
            policyid => VDNetLib::TestData::TestConstants::VSWITCH_BEACONCONFIG_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::VSWITCH_BEACONCONFIG_OPTION,
            name    => VDNetLib::TestData::TestConstants::VSWITCH_BEACONCONFIG_INTERVAL,
            value   => VDNetLib::TestData::TestConstants::VSWITCH_BEACONCONFIG_VALUE,
         },
       },
      },
      'VswitchNumPorts'   => {
         TestName         => 'VswitchNumPorts',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NumPorts maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Vswitch Profile '.
           '4. Select NumPortsPolicy' .
           '5. Select FixedNumPorts  ' .
           '6. Edit numPorts = 30 ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VSWITCH_NUM_PORTS'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_VSWITCH_NUM_PORTS' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NUMPORTS_PATH,
            policyid => VDNetLib::TestData::TestConstants::VSWITCH_NUMPORTS_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::VSWITCH_NUMPORTS_OPTION,
            name    => VDNetLib::TestData::TestConstants::VSWITCH_NUM_PORTS,
            value   => VDNetLib::TestData::TestConstants::VSWITCH_NUM_PORTS_VALUE,
         },
       },
      },
      'VswitchNetworkSecurityPolicy'   => {
         TestName         => 'VswitchNetworkSecurityPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkSecurityPolicy maintenance mode status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkSecurityPolicy' .
           '5. Select NewFixedSecurityPolicyOption  ' .
           '6. Change allowPromiscuous, ' .
           '7. Get maintenance mode status ' .
           '8. Change forgedTransmits ' .
           '9. Get maintenance mode status ' .
           '10. Change macChanges' .
           '11. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_allowPromiscuous"],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_macChanges"],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_forgedTransmits"],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_allowPromiscuous' => {
           Type     => 'Host',
           TestHost => 'host.[1]',
           editprofile => '/tmp/hp.xml',
           profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
           policyid  => VDNetLib::TestData::TestConstants::SECURITY_POLICY,
           policyoption =>  VDNetLib::TestData::TestConstants::SECURITY_POLICY_OPTION,
           name    => VDNetLib::TestData::TestConstants::ALLOW_PROMISCUOUS,
           value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
         'Edit_macChanges' => {
           Type     => 'Host',
           TestHost => 'host.[1]',
           editprofile => '/tmp/hp.xml',
           profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
           policyid  => VDNetLib::TestData::TestConstants::SECURITY_POLICY,
           policyoption =>  VDNetLib::TestData::TestConstants::SECURITY_POLICY_OPTION,
           name    => VDNetLib::TestData::TestConstants::MAC_CHANGE,
           value   => VDNetLib::TestData::TestConstants::DEFAULT_FALSE,
         },
         'Edit_forgedTransmits' => {
           Type     => 'Host',
           TestHost => 'host.[1]',
           editprofile => '/tmp/hp.xml',
           profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
           policyid => VDNetLib::TestData::TestConstants::SECURITY_POLICY,
           policyoption => VDNetLib::TestData::TestConstants::SECURITY_POLICY_OPTION,
           name    => VDNetLib::TestData::TestConstants::FORGE_TRANSMITS,
           value   => VDNetLib::TestData::TestConstants::DEFAULT_FALSE,
         },
       },
      },
      'VswitchNetworkTrafficShapingPolicy'   => {
         TestName         => 'VswitchNetworkTrafficShapingPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkTrafficShaping Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NewFixedTrafficShapingPolicyOption  ' .
           '5. Select FixedTrafficShapingPolicyOption ' .
           '6. Change averageBandwidth=1111 ' .
           '7. peakBandwidth=2222 ' .
           '8. burstSize=3333  ' .
           '9. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_SHAPING_AVERAGE_BANDWIDTH'],
              ['Edit_SHAPING_PEAK_BANDWIDTH'],
              ['Edit_SHAPING_BURST_SIZE'],
              ['Edit_SHAPING_ENABLE'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_SHAPING_ENABLE' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::ENABLED,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
          },
         'Edit_SHAPING_AVERAGE_BANDWIDTH' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::AVERAGE_BANDWIDTH,
            value   => VDNetLib::TestData::TestConstants::AVERAGE_BANDWIDTH_VALUE,
         },
         'Edit_SHAPING_PEAK_BANDWIDTH' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::PEAK_BANDWIDTH,
            value   => VDNetLib::TestData::TestConstants::PEAK_BANDWIDTH_VALUE,
         },
         'Edit_SHAPING_BURST_SIZE' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::TRAFFIC_SHAPING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::BURST_SIZE,
            value   => VDNetLib::TestData::TestConstants::BURST_SIZE_VALUE,
         },
       },
      },
      'VswitchNetworkNicOrderPolicy'   => {
         TestName         => 'VswitchNetworkNicOrderPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkNicOrderPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicOrderPolicy' .
           '5. Select FixedNicOrdering    ' .
           '6. Edit activeNics=[vmnic1, vmnic3] ' .
           '7. standbyNics=[vmnic2] ' .
           '8. Get maintenance mode status ',
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NIC_ORDER'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NIC_ORDER_STANDBY'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
            'expectedresult'   => 'FAIL' ,
         },
         'Edit_NIC_ORDER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::ACTIVE_NICS,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_NIC,
         },
         'Edit_NIC_ORDER_STANDBY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::FIXEDNICORDERING_STANDBYNICS,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_NIC,
         },
       },
      },
      'VswitchNetworkNicTeamingPolicy'   => {
         TestName         => 'VswitchNetworkNicTeamingPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkNicTeamingPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Change policy=loadbalance_srcid ' .
           '          failover_explicit' .
           '          loadbalance_ip ' .
           '          loadbalance_srcmac ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_IP'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCID'],
              ["GetMaintenanceModeStatus_1"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCMAC'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_LOADBASED_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_EXPLICIT'],
              ["GetMaintenanceModeStatus"],

         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'GetMaintenanceModeStatus_1' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_NICTEAM_IP' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_IP,
         },
         'Edit_NICTEAM_SRCID' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_SRCID,
         },
         'Edit_NICTEAM_SRCMAC' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_SRCMAC,
         },
         'Edit_NICTEAM_LOADBASED_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_LOADBASED,
            expectedresult => "FAIL",
         },
         'Edit_NICTEAM_EXPLICIT' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_EXPLICIT,
         },
       },
      },
      'VswitchNetworkNicTeamingRollingOrder'   => {
         TestName         => 'VswitchNetworkNicTeamingRollingOrder',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkNicTeaming Rolling Order maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Change rollingOrder=False/True  ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_TEAMING_ROLLING_ORDER'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_TEAMING_ROLLING_ORDER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_ROLLING_ORDER,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'VswitchNetworkNicTeamingNotifySwitch'   => {
         TestName         => 'VswitchNetworkNicTeamingNotifySwitch',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkNicTeaming Notify Switch maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. notifySwitches=False/True ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_TEAMING_NOTIFY_SWITCHES'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_TEAMING_NOTIFY_SWITCHES' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_NOTIFY_SWITCHES,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'VswitchNetworkNicTeamingReversePolicy'   => {
         TestName         => 'VswitchNetworkNicTeamingReversePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkNicTeaming Reverse Policy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Change reversePolicy=False/True ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_TEAMING_REVERSE_POLICY'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_TEAMING_REVERSE_POLICY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NIC_TEAMING_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::TEAMING_REVERSE_POLICY,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_FALSE,
         },
       },
      },
      'DvsPortSelectionPolicy'   => {
         TestName         => 'DvsPortSelectionPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify DvSwitch  DvsPortSelectionPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. Select DvsPortSelectionPolicy' .
           '5. Select FixedDVPortgroupSelectionOption  ' .
           '6. Edit DVSHOSTNIC NAME ' .
           '7. Does Compliance Check'.
           '8. Edit DVSHOSTNIC PORTGROUP NAME ' .
           '9. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                       'name' => 'Profile-vds',
                        host => "host.[1]",
                     },
                 },
                 dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        name    => "Profile-dvpg",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                 },
               },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVSHOSTNIC_NAME'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVSHOSTNIC_PORTGROUP_NAME'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
             'TestHost'    => 'host.[1]',
             'createprofile' => 'extractprofile',
             'hostprofilefile'     => '/tmp/hp.xml',
           },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_DVSHOSTNIC_NAME' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVSHOSTNIC_PATH,
            policyid => VDNetLib::TestData::TestConstants::DVSPORT_SELECTION_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVSPORT_SELECTION_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_NAME,
            value   => VDNetLib::TestData::TestConstants::DVS_NAME_VALUE,
         },
         'Edit_DVSHOSTNIC_PORTGROUP_NAME' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVSHOSTNIC_PATH,
            policyid => VDNetLib::TestData::TestConstants::DVSPORT_SELECTION_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVSPORT_SELECTION_OPTION,
            name    => VDNetLib::TestData::TestConstants::PORTGROUP_NAME,
            value   => VDNetLib::TestData::TestConstants::PORTGROUP_NAME_VALUE,
         },
       },
      },

      'DvsEarlyBootVnicPolicy'   => {
         TestName         => 'DvsEarlyBootVnicPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify DvSwitch  DvsEarlyBootVnicPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. Select DvsEarlyBootVnicPolicy' .
           '5. Select VmknicDefaultEarlyBootOption  ' .
           '6. Edit DVS VNIC ACTIVE UPLINKS ' .
           '7. Get maintenance mode status ' .
           '8. Edit DVS VNIC TEAM_IP ' .
           '9. Get maintenance mode status ' .
           '10. Edit DVS VNIC TEAM_SRCID' .
           '11. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         PMT              => '',
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                       'name' => 'Profile-vds',
                        host => "host.[1]",
                     },
                 },
                 dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        name    => "Profile-dvpg",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                 },
               },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_VNIC_ACTIVE_UPLINKS'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_VNIC_TEAM_IP'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_VNIC_TEAM_SRCID'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
             'TestHost'    => 'host.[1]',
             'createprofile' => 'extractprofile',
             'hostprofilefile'     => '/tmp/hp.xml',
           },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_DVS_VNIC_ACTIVE_UPLINKS' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVSHOSTNIC_PATH,
            policyid => VDNetLib::TestData::TestConstants::DVS_EARLY_BOOT_VNIC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_EARLY_BOOT_VNIC_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_VNIC_ACTIVE_UPLINKS,
            value   => VDNetLib::TestData::TestConstants::DVS_VNIC_VMNIC,
         },
         'Edit_DVS_VNIC_TEAM_IP' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVSHOSTNIC_PATH,
            policyid => VDNetLib::TestData::TestConstants::DVS_EARLY_BOOT_VNIC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_EARLY_BOOT_VNIC_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_VNIC_TEAM_POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_IP,
         },
         'Edit_DVS_VNIC_TEAM_SRCID' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVSHOSTNIC_PATH,
            policyid => VDNetLib::TestData::TestConstants::DVS_EARLY_BOOT_VNIC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_EARLY_BOOT_VNIC_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_VNIC_TEAM_POLICY,
            value   => VDNetLib::TestData::TestConstants::TEAMING_POLICY_MODE_SRCID,
         },
       },
      },
      'VswitchMtuPolicy'   => {
         TestName         => 'VswitchMtuPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch MtuPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select MtuPolicy' .
           '5. Select FixedMtuOption   ' .
           '6. Edit MTU Size ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_VSWITCH_MTU'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_VSWITCH_MTU' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_PATH,
            policyid => VDNetLib::TestData::TestConstants::VNICPROFILE_MTUPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::VNICPROFILE_MTUPOLICY_FIXEDMTUOPTION,
            name    => VDNetLib::TestData::TestConstants::VSWITCH_MTU_NAME,
            value   => VDNetLib::TestData::TestConstants::VSWITCH_MTU_VALUE,
         },
       },
      },
      'VswitchNetworkFailoverPolicy'   => {
         TestName         => 'VswitchNetworkFailoverPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Vswitch NetworkFailoverPolicy maintenance mode status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkFailoverPolicy' .
           '5. Select NewFixedFailoverCriteria   ' .
           '6. Edit NewFixedFailoverCriteria   ' .
           '   checkBeacon = false ' .
           '7. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_FAILOVER'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_FAILOVER' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::FAILOVER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::FAILOVER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::CHECK_BEACON,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_TRUE,
         },
       },
      },
      'DvSwitchSingularPnicPolicy'   => {
         TestName         => 'DvSwitchSingularPnicPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify SingularPnicPolicy maintenance mode status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. In HostProgroup Profile '.
           '5. Extract HostProfile  ' .
           '6. Select SingularPnicPolicy ' .
           '7. Select PnicsByName option ' .
           '   Edit nicNames = "vmnic2" ' .
           '8. Does Compliance Check'.
           '9. Extract HostProfile  ' .
           '10. Select SingularPnicPolicy ' .
           '11. Select PnicsByName option ' .
           '   Edit nicNames = "vmnic1" ' .
           '12. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                       'name' => 'Profile-vds',
                        host => "host.[1]",
                     },
                 },
                 dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        name    => "Profile-dvpg",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                 },
               },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_UPLINK'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_UPLINK_1'],
              ["GetMaintenanceModeStatus_1"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'GetMaintenanceModeStatus_1' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_DVS_UPLINK' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVS_UPLINK_KEY,
            policyid  => VDNetLib::TestData::TestConstants::DVS_PNIC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_PNIC_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_PNIC_NAME,
            value   => VDNetLib::TestData::TestConstants::DVS_PNIC_NAME_VALUE,
         },
         'Edit_DVS_UPLINK_1' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVS_UPLINK_KEY,
            policyid  => VDNetLib::TestData::TestConstants::DVS_PNIC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_PNIC_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_PNIC_NAME,
            value   => VDNetLib::TestData::TestConstants::DVS_PNIC_NAME_VALUE_1,
         },
       },
     },
     'DvSwitchDvsUplinkPortPolicy'   => {
         TestName         => 'DvSwitchDvsUplinkPortPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify DvSwitchDvsUplinkPortPolicy maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. Select DvSwitch DvsUplinkPortPolicy ' .
           '5. Select UplinkPortgroupOption   ' .
           '   uplinkPort = "Uplink 1" ' .
           '   uplinkPortGroup = "DVS 6 0-DVSUplinks" ' .
           '6. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'dvs',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                       'name' => 'Profile-vds',
                        host => "host.[1]",
                     },
                 },
                 dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        name    => "Profile-dvpg",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                 },
               },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_UPLINK'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_PORTGROUP'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_DVS_UPLINK' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVS_UPLINK_KEY,
            policyid  => VDNetLib::TestData::TestConstants::DVS_UPLINK_PORT_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_UPLINK_PORT_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_UPLINK_UPLINK_PORT,
            value   => VDNetLib::TestData::TestConstants::DVS_UPLINK_UPLINK_PORT_VALUE,
         },
         'Edit_DVS_PORTGROUP' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVS_UPLINK_KEY,
            policyid  => VDNetLib::TestData::TestConstants::DVS_UPLINK_PORT_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_UPLINK_PORT_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_UPLINK_PORTGROUP,
            value   => VDNetLib::TestData::TestConstants::DVS_UPLINK_PORTGROUP_VALUE,
         },
       },
     },
     'NetStackIPv6Enabled'   => {
         TestName         => 'NetStackIPv6Enabled',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify Netstack IPv6Enabled maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Instance Max Connection ' . 
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_IPV6ENABLED'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_IPV6ENABLED' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_PATH,
            policyid  => VDNetLib::TestData::TestConstants::NETSTACKINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_FIXEDOPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_IPV6ENABLED,
            value   => VDNetLib::TestData::TestConstants::DEFAULT_FALSE,
         },
       },
     },
     'NetStackMaxConnection'   => {
         TestName         => 'NetStackMaxConnection',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify netstack max connection maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Instance Max Connection ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_MAXCONNECTION'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_MAXCONNECTION' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_PATH,
            policyid  => VDNetLib::TestData::TestConstants::NETSTACKINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_FIXEDOPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_MAXCONNECTION,
            value   => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_MAXCONNECTION_DEFAULT,
         },
       },
     },
     'NetStackCongestionCtrlAlgorithm'   => {
         TestName         => 'NetStackCongestionCtrlAlgorithm',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify netstack congestion control algirithm maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Congestion Ctrl Algorithm ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_CONGESTIONCTRLALGORITHM_NEWRENO'],
              ["GetMaintenanceModeStatus_1"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_CONGESTIONCTRLALGORITHM_CUBIC'],
              ["GetMaintenanceModeStatus_1"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'GetMaintenanceModeStatus_1' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_CONGESTIONCTRLALGORITHM_NEWRENO' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_PATH,
            policyid  => VDNetLib::TestData::TestConstants::NETSTACKINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_FIXEDOPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM,
            value   => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM_NEWRENO,
         },
         'Edit_CONGESTIONCTRLALGORITHM_CUBIC' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_PATH,
            policyid  => VDNetLib::TestData::TestConstants::NETSTACKINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_FIXEDOPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM,
            value   => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM_CUBIC,
         },
       },
     },
     'NetStackDnsConfigDnsServerAddr'   => {
         TestName         => 'NetStackDnsConfigDnsServerAddr',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify dnsconfig dns server address maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt DNS Server address ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
	 Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_DNSCONFIG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_DNSCONFIG_PATH,
            policyid  => VDNetLib::TestData::TestConstants::DNSCONFIGPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDDNSCONFIG,
            name    => VDNetLib::TestData::TestConstants::DNSSERVERADDR,
            value   => VDNetLib::TestData::TestConstants::DNSSERVERADDR_VALUE,
         },
       },
     },
     'NetStackDnsConfigDomainName'   => {
         TestName         => 'NetStackDnsConfigDomainName',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify netstack dnsconfig domain name maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Dns COnfig DomainName ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_DOMAINNAME'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_DNSCONFIG_DOMAINNAME' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_DNSCONFIG_PATH,
            policyid  => VDNetLib::TestData::TestConstants::DNSCONFIGPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDDNSCONFIG,
            name    => VDNetLib::TestData::TestConstants::DOMAINNAME,
            value   => VDNetLib::TestData::TestConstants::DOMAINNAME_VALUE,
         },
       },
     },
     'NetStackDnsConfigSearchDomain'   => {
         TestName         => 'NetStackDnsConfigSearchDomain',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify dnsconfig search domain maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Dns Config SearchDomain name' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_SEARCHDOMAIN'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_DNSCONFIG_SEARCHDOMAIN' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_DNSCONFIG_PATH,
            policyid  => VDNetLib::TestData::TestConstants::DNSCONFIGPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDDNSCONFIG,
            name    => VDNetLib::TestData::TestConstants::SEARCHDOMAIN,
            value   => VDNetLib::TestData::TestConstants::SEARCHDOMAIN_VALUE,
         },
       },
     },
     'NetStackDnsConfigDhcp'   => {
         TestName         => 'NetStackDnsConfigDhcp',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify dnscnfig dhcp maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Netstack Instance DnsConfig Dhcp ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_DHCP'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_DNSCONFIG_DHCP' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_DNSCONFIG_PATH,
            policyid  => VDNetLib::TestData::TestConstants::DNSCONFIGPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDDNSCONFIG,
            name    => VDNetLib::TestData::TestConstants::DHCP,
            value   => VDNetLib::TestData::TestConstants::DHCP_VALUE,
         },
       },
     },
     'HostPortGroupIPAddress'   => {
         TestName         => 'HostPortGroupIPAddress',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify hostportgroup ip address maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit netstack IP address profile ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss,batnovc',
         PMT              => '',
         AutomationLevel  => 'Automated',
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
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_DHCP'],
              ['Edit_IPADDRESS_FIXEDDHCPOPTION'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'GetMaintenanceModeStatus_1' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_DNSCONFIG_DHCP' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::NETSTACK_DNSCONFIG_PATH,
            policyid  => VDNetLib::TestData::TestConstants::DNSCONFIGPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDDNSCONFIG,
            name    => VDNetLib::TestData::TestConstants::DHCP,
            value   => VDNetLib::TestData::TestConstants::DHCP_VALUE,
         },
         'Edit_IPADDRESS_USERINPUTIPADDRESS' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_IPADDRESS_PATH,
            policyid  => VDNetLib::TestData::TestConstants::IPADDRESSPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::USERINPUTIPADDRESS,
         },
         'Edit_IPADDRESS_FIXEDDHCPOPTION' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_IPADDRESS_PATH,
            policyid  => VDNetLib::TestData::TestConstants::IPADDRESSPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDDHCPOPTION,
         },
         'Edit_IPADDRESS_FIXEDIPCONFIG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_IPADDRESS_PATH,
            policyid  => VDNetLib::TestData::TestConstants::IPADDRESSPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::FIXEDIPCONFIG,
         },
         'Edit_IPADDRESS_USERINPUTIPADDRESS_USEDEFAULT' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_IPADDRESS_PATH,
            policyid  => VDNetLib::TestData::TestConstants::IPADDRESSPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::USERINPUTIPADDRESS_USEDEFAULT,
         },
       },
     },
     'NetStackStaticRoute'   => {
         TestName         => 'NetStackStaticRoute',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify netstack static route maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Netstack Static Route IP Network  ' .
           '4. Get maintenance mode status ' .
           '5. Edit Netstack STATIC IP ROUTE PREFIX ' .
           '6. Get maintenance mode status ' .
           '7. Edit Netstack STATIC IP ROUTE GATEWAY ' .
           '8. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            'host' => {
              '[1]' => {
                'vmnic' => {
                  '[1-2]' => {
                    'driver' => 'any'
                  },
                },
                'vmknic' => {
                  '[0]' => {
                    'portgroup' => "host.[1].portgroup.[0]",
                    'interface' => "vmk0",
                  }
                },
                'portgroup' => {
                  '[0]' => {
                    'vss' => "host.[1].vss.[0]",
                    'name' => "VMKernel",
                  }
                },
                'vss' => {
                  '[0]' => {
                    'name' => "vSwitch0",
                  }
                },
              },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_NETWORK'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_PREFIX'],
              ["GetMaintenanceModeStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_GATEWAY'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_STATIC_IP_ROUTE_NETWORK' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::NETWORK,
            value   => VDNetLib::TestData::TestConstants::NETWORK_IP,
            adapter => 'host.[1].vmknic.[0]',
         },
         'Edit_STATIC_IP_ROUTE_PREFIX' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::PREFIX,
            value   => VDNetLib::TestData::TestConstants::PREFIX_VALUE,
            adapter => 'host.[1].vmknic.[0]',
         },
         'Edit_STATIC_IP_ROUTE_GATEWAY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::GATEWAY,
            value   => VDNetLib::TestData::TestConstants::GATEWAY_IP,
            adapter => 'host.[1].vmknic.[0]',
         },
       },
     },
     'NetStackStaticRouteDevice'   => {
         TestName         => 'NetStackStaticRouteDevice',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify netstack static route maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Netstack STATIC IP ROUTE DEVICE  ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            'host' => {
              '[1]' => {
                'vmnic' => {
                  '[1-2]' => {
                    'driver' => 'any'
                  },
                },
                'vmknic' => {
                  '[0]' => {
                    'portgroup' => "host.[1].portgroup.[0]",
                    'interface' => "vmk0",
                  }
                },
                'portgroup' => {
                  '[0]' => {
                    'vss' => "host.[1].vss.[0]",
                    'name' => "VMKernel",
                  }
                },
                'vss' => {
                  '[0]' => {
                    'name' => "vSwitch0",
                  }
                },
              },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_DEVICE'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'true',
         },
         'Edit_STATIC_IP_ROUTE_DEVICE' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::DEVICE,
            value   => VDNetLib::TestData::TestConstants::DEVICE_NAME,
            adapter => 'host.[1].vmknic.[0]',
         },
       },
     },
     'NetStackStaticRouteFamily'   => {
         TestName         => 'NetStackStaticRouteFamily',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify netstack static route maintenance mode status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate answer file ' .
           '3. Edit Netstack  STATIC IP ROUTE FAMILY ' .
           '4. Get maintenance mode status ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'vss',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            'host' => {
              '[1]' => {
                'vmnic' => {
                  '[1-2]' => {
                    'driver' => 'any'
                  },
                },
                'vmknic' => {
                  '[0]' => {
                    'portgroup' => "host.[1].portgroup.[0]",
                    'interface' => "vmk0",
                  }
                },
                'portgroup' => {
                  '[0]' => {
                    'vss' => "host.[1].vss.[0]",
                    'name' => "VMKernel",
                  }
                },
                'vss' => {
                  '[0]' => {
                    'name' => "vSwitch0",
                  }
                },
              },
            },
         },
         WORKLOADS => {
         Sequence => [
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_FAMILY'],
              ["GetMaintenanceModeStatus"],
         ],
         'CreateProfile' => {
           'Type'        => 'Host',
           'TestHost'    => 'host.[1]',
           'createprofile' => 'extractprofile',
           'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'generateanswerfile'  => 'genanswerfile',
           'hostprofilefile'     => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost'     => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'Edit_STATIC_IP_ROUTE_FAMILY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::FAMILY,
            value   => VDNetLib::TestData::TestConstants::FAMILY_TYPE_IPV4,
            adapter => 'host.[1].vmknic.[0]',
         },
       },
     },
     'RemoveVSS' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'RemoveVSS',
        'Summary' => 'Verify remove vss maintenance mode status',
        'ExpectedResult' => 'PASS',
        'Tags' => 'vss',
        'Version' => 2,
        'Status' => 'Execution Ready',
        'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
        'Developer' => 'sho',
        'TestcaseLevel' => 'Functional',
        'Product' => 'ESX',
        'Duration' => '',
        'PMT' => '6599',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
        'TestcaseType' => 'Functional',
        'Testbed' => '',
        'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::RemoveVSS',
        'Procedure' =>
            '1. Extract host profile ' .
            '2. Generates an Answer File for the given profile ' .
            '3. Add Virtual Standard Switch ' .
            '4. Get maintenance mode status ' .
            '5.Delete Virtual Standard Switch.',
        'Priority' => 'P0',
        'FullyAutomatable' => 'Y',
        'AutomationLevel' => 'Automated',
        'WORKLOADS' => {
          'Sequence' => [
              ['CreateProfile'],
              ['GenerateAnswerFile'],
              ['AddVswitch'],
              ['GetMaintenanceModeStatus'],
          ],
          'ExitSequence' => [
              ['DeleteVswitch'],
          ],
          'Duration' => 'time in seconds',
          'CreateProfile' => {
             'Type'        => 'Host',
             'TestHost'    => 'host.[1]',
             'createprofile' => 'extractprofile',
             'hostprofilefile'     => '/tmp/hp.xml',
          },
          'GenerateAnswerFile' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'generateanswerfile'  => 'genanswerfile',
              'hostprofilefile'     => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
          },
          'GetMaintenanceModeStatus' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'hostprofilefile' => '/tmp/hp.xml',
              'answerfile'      => '/tmp/ans.xml',
              'maintenancemodestatus' => 'true',
          },
          'AddVswitch' => {
             'Type' => 'Host',
             'TestHost' => 'host.[1]',
             'vss' => {
               '[1]' => {
                'name' => 'vSwitch2'
              }
            }
          },
          'DeleteVswitch' => {
             'Type' => 'Host',
             'TestHost' => 'host.[1]',
             'deletevss' => 'host.[1].vss.[1]'
          }
        }
     },
     'AddVSS' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'AddVSS',
        'Summary' => 'Verify add vss maintenance mode status',
        'ExpectedResult' => 'PASS',
        'Tags' => 'vss',
        'Version' => 2,
        'Status' => 'Execution Ready',
        'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
        'Developer' => 'sho',
        'FullyAutomatable' => 'Y',
        'AutomationLevel' => 'Automated',
        'TestcaseLevel' => 'Functional',
        'Product' => 'ESX',
        'Duration' => '',
        'PMT' => '6599',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
        'TestcaseType' => 'Functional',
        'Testbed' => '',
        'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::AddVSS',
        'Procedure' =>
             '1. Add Virtual Standard Switch ' .
             '2. Extract host profile ' .
             '3. Delete Virtual Standard Switch ' .
             '4. Generates an Answer File for the given profile' .
             '5. Get maintenance mode status ',
        'Priority' => 'P0',
           'WORKLOADS' => {
             'Sequence' => [
               ['AddVswitch'],
               ['CreateProfile'],
               ['GenerateAnswerFile'],
               ['DeleteVswitch'],
               ['GetMaintenanceModeStatus'],
             ],
         'Duration' => 'time in seconds',
         'CreateProfile' => {
            'Type'        => 'Host',
            'TestHost'    => 'host.[1]',
            'createprofile' => 'extractprofile',
            'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
            'Type'         => 'Host',
            'TestHost'     => 'host.[1]',
            'generateanswerfile'  => 'genanswerfile',
            'hostprofilefile'     => '/tmp/hp.xml',
            'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
         },
         'AddVswitch' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'vss' => {
              '[1]' => {
                'name' => 'vSwitch2'
              }
            }
         },
         'DeleteVswitch' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'deletevss' => 'host.[1].vss.[1]'
         },
       }
     },
     'AddVmPortgroup' => {
       'Component' => 'Network Plugin',
       'Category' => 'Host Profiles',
       'TestName' => 'AddVmPortgroup',
       'Summary' => 'Verify Add vmPortgroup maintenance mode status',
       'ExpectedResult' => 'PASS',
       'Tags' => 'vss',
       'Version' => 2,
       'Status' => 'Execution Ready',
       'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
       'Developer' => 'sho',
       'FullyAutomatable' => 'Y',
       'AutomationLevel' => 'Automated',
       'TestcaseLevel' => 'Functional',
       'Product' => 'ESX',
       'Duration' => '',
       'PMT' => '6599',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
       'TestcaseType' => 'Functional',
       'Testbed' => '',
       'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::AddVmPortgroup',
       'Procedure' =>
            '1. Add Virtual Standard Switch ' .
            '2. Add PortGroup ' .
            '3. Extract host profile ' .
            '4. Generates an Answer File for the given profile ' .
            '5. Delete PortGroup ' .
            '6. Get maintenaceMode status ' .
            '7. Delete Virtual Standard Switch',
       'Priority' => 'P0',
       'FullyAutomatable' => 'Y',
       'AutomationLevel' => 'Automated',
       'WORKLOADS' => {
         'Sequence' => [
             ['AddVswitch'],
             ['AddPortgroup'],
             ['CreateProfile'],
             ['GenerateAnswerFile'],
             ['DeletePortgroup'],
             ['GetMaintenanceModeStatus'],
         ],
         'ExitSequence' => [
             ['DeleteVswitch'],
         ],
         'Duration' => 'time in seconds',
          'CreateProfile' => {
             'Type'        => 'Host',
             'TestHost'    => 'host.[1]',
             'createprofile' => 'extractprofile',
             'hostprofilefile'     => '/tmp/hp.xml',
          },
          'GenerateAnswerFile' => {
             'Type'         => 'Host',
             'TestHost'     => 'host.[1]',
             'generateanswerfile'  => 'genanswerfile',
             'hostprofilefile'     => '/tmp/hp.xml',
             'answerfile'   => '/tmp/ans.xml',
          },
          'GetMaintenanceModeStatus' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'hostprofilefile' => '/tmp/hp.xml',
            'answerfile'      => '/tmp/ans.xml',
            'maintenancemodestatus' => 'false',
          },
          'AddVswitch' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'vss' => {
              '[1]' => {
                'name' => 'vSwitch2'
              }
            }
          },
          'AddPortgroup' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'portgroup' => {
              '[1]' => {
                'name' => 'testpg',
                'vss' => 'host.[1].vss.[1]'
              }
            }
          },
          'DeletePortgroup' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'deleteportgroup' => 'host.[1].portgroup.[1]'
          },
          'DeleteVswitch' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'deletevss' => 'host.[1].vss.[1]'
          }
        }
     },
     'RemoveHostPortgroupVMotion' => {
       'Component' => 'Network Plugin',
       'Category' => 'Host Profiles',
       'TestName' => 'RemoveHostPortgroupVMotion',
       'Summary' => 'Verify remove hostPortgroup-vMotion maintenance mode status',
       'ExpectedResult' => 'PASS',
       'Tags' => 'vss',
       'Version' => 2,
       'Status' => 'Execution Ready',
       'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
       'Developer' => 'sho',
       'FullyAutomatable' => 'Y',
       'AutomationLevel' => 'Automated',
       'TestcaseLevel' => 'Functional',
       'Product' => 'ESX',
       'Duration' => '',
       'PMT' => '6599',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
       'TestcaseType' => 'Functional',
       'Testbed' => '',
       'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::RemoveHostPortgroupVMotion',
       'Procedure' =>
           '1. Add Virtual Standard Switch ' .
           '2. Add PortGroup ' .
           '3. Add Vmknic ' .
           '4. Extract host profile ' .
           '5. Generates an Answer File for the given profile ' .
           '6. Add VMotionTag '.
           '7. Get maintenaceMode status ' .
           '8. Remove VMotionTag ' .
           '9. Remove Vmknic ' .
           '10. Remove PortGroup ' .
           '11. Remove Virtual Standard Switch',
       'Priority' => 'P0',
       'WORKLOADS' => {
         'Sequence' => [
             ['AddVswitch'],
             ['AddPortgroup'],
             ['AddVmknic'],
             ['CreateProfile'],
             ['GenerateAnswerFile'],
             ['AddVMotionTag'],
             ['GetMaintenanceModeStatus'],
         ],
         'ExitSequence' => [
             ['RemoveVMotionTag'],
             ['RemoveVmknic'],
             ['DeletePortgroup'],
             ['DeleteVswitch'],
         ],
         'Duration' => 'time in seconds',
         'CreateProfile' => {
            'Type'        => 'Host',
            'TestHost'    => 'host.[1]',
            'createprofile' => 'extractprofile',
            'hostprofilefile'     => '/tmp/hp.xml',
         },
         'GenerateAnswerFile' => {
            'Type'         => 'Host',
            'TestHost'     => 'host.[1]',
            'generateanswerfile'  => 'genanswerfile',
            'hostprofilefile'     => '/tmp/hp.xml',
            'answerfile'   => '/tmp/ans.xml',
         },
         'GetMaintenanceModeStatus' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'hostprofilefile' => '/tmp/hp.xml',
           'answerfile'      => '/tmp/ans.xml',
           'maintenancemodestatus' => 'false',
         },
         'AddVswitch' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'vss' => {
             '[1]' => {
               'name' => 'vSwitch2'
             }
           }
         },
         'AddPortgroup' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'portgroup' => {
             '[1]' => {
               'name' => 'testpg',
               'vss' => 'host.[1].vss.[1]'
             }
           }
         },
         'AddVmknic' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'vmknic' => {
             '[1]' => {
               'portgroup' => 'host.[1].portgroup.[1]',
               ipv4address => "1.1.1.1",
               netmask => "255.255.255.0",
               prefixlen => "24",
             }
           }
         },
         "AddVMotionTag" => {
           Type => "NetAdapter",
           TestAdapter => "host.[1].vmknic.[1]",
           Tagging => "add",
           tagname => "VMotion",
         },
         "RemoveVMotionTag" => {
           Type => "NetAdapter",
           TestAdapter => "host.[1].vmknic.[1]",
           Tagging => "remove",
           tagname => "VMotion",
         },
         'RemoveVmknic' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'deletevmknic' => 'host.[1].vmknic.[1]'
         },
         'DeletePortgroup' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'deleteportgroup' => 'host.[1].portgroup.[1]'
         },
         'DeleteVswitch' => {
           'Type' => 'Host',
           'TestHost' => 'host.[1]',
           'deletevss' => 'host.[1].vss.[1]'
         }
       }
     },
  )
}


########################################################################
#
# new --
#       This is the constructor for MaintenanceModeNetworkProfileTds
#
# Input:
#       none
#
# Results:
#       An instance/object of MaintenanceModeNetworkProfileTds class
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
   my $self = $class->SUPER::new(\%MaintenanceModeNetworkProfile);
   return (bless($self, $class));
}

1;
