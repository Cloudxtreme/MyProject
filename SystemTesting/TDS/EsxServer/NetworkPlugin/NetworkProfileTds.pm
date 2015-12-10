########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::NetworkProfileTds;

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

   %NetworkProfile = (
      'HostPortGroupNetworkSecurityPolicy'   => {
         TestName         => 'HostPortGroupNetworkSecurityPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit NetworkSecurityPolicy and get '.
                             'compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkSecurityPolicy ' .
           '5. Select NewFixedSecurityPolicyOption  ' .
           '6. Change policy option: allowPromiscuous, ' .
           '7. Does Compliance Check'.
           '8. Change policy option: forgedTransmits ' .
           '9. Does Compliance Check'.
           '10. Change policy option: macChanges' .
           '11. Does Compliance Check'.
           '12. Result: nonCompliant ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT_P0',
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
                 ["GetComplianceStatus"],
                 ["CreateProfile"],
                 ["GenerateAnswerFile"],
                 ["Edit_macChanges"],
                 ["GetComplianceStatus"],
                 ["CreateProfile"],
                 ["GenerateAnswerFile"],
                 ["Edit_forgedTransmits"],
                 ["GetComplianceStatus"],
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
          'GetComplianceStatus' => {
            'Type'         => 'Host',
            'TestHost'     => 'host.[1]',
            'compliancestatus'  => 'false',
            'hostprofilefile'   => '/tmp/hp.xml',
            'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Network Traffic shaping Policy and get compliance status' ,
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
           '10. Does Compliance Check'.
           '11. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                 ['Edit_SHAPING_AVERAGE_BANDWIDTH'],
                 ['Edit_SHAPING_PEAK_BANDWIDTH'],
                 ['Edit_SHAPING_BURST_SIZE'],
                 ['Edit_SHAPING_ENABLE'],
                 ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Networki NicOrder and get compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
	   '4. Select NetworkNicOrderPolicy ' .
           '5. Select FixedNicOrdering option   ' .
	   '6. Edit NIC Order' .
           '7. Does Compliance Check'.
	   '8. Edit STANDBY NIC Order' .
           '9. Does Compliance Check'.
           '10. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                 ["GetComplianceStatus"],
                 ["CreateProfile"],
                 ["GenerateAnswerFile"],
                 ['Edit_NIC_ORDER_STANDBY'],
                 ["GetComplianceStatus"],
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
            'GetComplianceStatus' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'false',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
            },
            'Edit_NIC_ORDER' => {
               Type     => 'Host',
               TestHost => 'host.[1]',
               editprofile => '/tmp/hp.xml',
               profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
               policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
               policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
               name    => VDNetLib::TestData::TestConstants::ACTIVE_NICS,
               value   => VDNetLib::TestData::TestConstants::DEFAULT_NIC,
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
            'Edit_NIC_ORDER_NEG' => {
               Type     => 'Host',
               TestHost => 'host.[1]',
               editprofile => '/tmp/hp.xml',
               profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
               policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
               policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
               name    => VDNetLib::TestData::TestConstants::ACTIVE_NICS,
               value   => VDNetLib::TestData::TestConstants::INVALID_NIC,
               expectedresult => 'FAIL',
            },
         },
      },
      'HostPortGroupNetworkNicOrderPolicyNegative'   => {
         TestName         => 'HostPortGroupNetworkNicOrderPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit Networki NicOrder and get compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Edit FixedNicOrdering with invalid nic    ' .
           '5. ExpectedResult: FAIL ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                 ['Edit_NIC_ORDER_NEG'],
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
            'Edit_NIC_ORDER_NEG' => {
               Type     => 'Host',
               TestHost => 'host.[1]',
               editprofile => '/tmp/hp.xml',
               profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_MANAGEMENT_PATH,
               policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
               policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
               name    => VDNetLib::TestData::TestConstants::ACTIVE_NICS,
               value   => VDNetLib::TestData::TestConstants::INVALID_NIC,
               expectedresult => 'FAIL',
            },
          },
      },
      'HostPortGroupNetworkNicTeamingPolicy'   => {
         TestName         => 'HostPortGroupNetworkNicTeamingPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit NetworkNicTeaming Policy and get compliance status' ,
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
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCID'],
              ["GetComplianceStatus_1"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCMAC'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_LOADBASED_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_EXPLICIT'],
              ["GetComplianceStatus"],
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
            'GetComplianceStatus' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'false',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
            },
            'GetComplianceStatus_1' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'true',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
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
               expectedresult => 'FAIL',
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
         Summary          => 'Edit NetworkNicTeaming Rolling Order and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Edit rollingOrder=False/True  ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                 ["GetComplianceStatus"],
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
            'GetComplianceStatus' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'false',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
              'expectedresult' => 'FAIL',
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
         Summary          => 'Edit NetworkNicTeaming Notify Switch and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Edit notifySwitches=False/True ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup Mtu Policy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select MtuPolicy' .
           '5. Select FixedMtuOption   ' .
           '6. Edit MTU Size ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_HOSTPROUGP_MTU'],
              ["GetComplianceStatus"],
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
            'GetComplianceStatus' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'false',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup mac address and get compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select MacAddressPolicy' .
           '5. Select UserInputMacAddress   ' .
           '6. Get maintenance mode status '.
           '7. Result: Compliamce' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                 ['Edit_HOSTPROUGP_MAC_ADDRESS'],
                 ["GetComplianceStatus"],
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
            'GetComplianceStatus' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'true',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup Vlan Policy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VlanIdPolicy' .
           '5. Select FixedVlanIdOption   ' .
           '6. Edit VlanId'.
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                 ['Edit_VLAN'],
                 ["GetComplianceStatus"],
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
            'GetComplianceStatus' => {
              'Type'         => 'Host',
              'TestHost'     => 'host.[1]',
              'compliancestatus'  => 'false',
              'hostprofilefile'   => '/tmp/hp.xml',
              'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup Vmknic Name and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICNamePolicy' .
           '5. Select FixedVirtualNICNameOption   ' .
           '6. Edit Vmknic Name  ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_VMKName'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup Nic Type and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICTypePolicy' .
           '5. Select FixedNICTypeOption  ' .
           '6. Edit HostPorgroup NicType ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_NicType'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         'Edit_NicType_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_TYPE_POLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::VIRTUAL_NIC_TYPE_OPTION,
            name => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_NAME,
            value   => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_INVALID_VALUE,
            expectedresult => 'FAIL',
         },
       },
      },
      'HostPortGroupNicTypePolicyNegative'   => {
         TestName         => 'HostPortGroupNicTypePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit HostPortGroup Nic Type and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICTypePolicy' .
           '5. Select FixedNICTypeOption  ' .
           '6.  Edit HostPorgroup NicType Policy with invalid nic type ' .
           '7.  expectedresult: Fail' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_NicType_NEG'],
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
         'Edit_NicType_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_TYPE_POLICY,
            policyoption =>  VDNetLib::TestData::TestConstants::VIRTUAL_NIC_TYPE_OPTION,
            name => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_NAME,
            value   => VDNetLib::TestData::TestConstants::VIRTUAL_NIC_INVALID_VALUE,
            expectedresult => 'FAIL',
         },
       },
      },
      'HostPortGroupVnicInstancePolicy'   => {
         TestName         => 'HostPortGroupVnicInstancePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit HostPortGroup vnic instance and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICInstancePolicy' .
           '5. Select FixedVirtualNICInstanceOption  ' .
           '6. Edit HostPorgroup Virtual NIC Instance Policy ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_Instance'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
            expectedresult => 'FAIL',
         },
       },
      },
      'HostPortGroupVnicInstancePolicyNegative'   => {
         TestName         => 'HostPortGroupVnicInstancePolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit HostPortGroup vnic instance and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICInstancePolicy' .
           '5. Select FixedVirtualNICInstanceOption  ' .
           '6  Edit HostPorgroup Virtual NIC Instance Policy with invalid Instance Name' .
           '7. ExpectedResult: FAIL ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_Instance_NEG'],
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
         'Edit_Instance_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::HOSTPROUGP_POLICY_PATH,
            policyid  => VDNetLib::TestData::TestConstants::VIRTUALNICINSTANCEPOLICY,
            policyoption => VDNetLib::TestData::TestConstants::VIRTUALNICINSTANCEPOLICY_FIXED_OPTION,
            name    => VDNetLib::TestData::TestConstants::NETSTACKINSTANCE_NAME,
            value   => VDNetLib::TestData::TestConstants::DEFAULTNETSTACKINSTANCE_INVALID_NAME,
            expectedresult => 'FAIL',
         },
       },
      },
      'HostPortGroupVMKNicPolicy'   => {
         TestName         => 'HostPortGroupVMKNicPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit HostPortGroup VMKNic and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select VirtualNICNamePolicy' .
           '5. Select FixedVirtualNICNameOption   ' .
           '6. Edit HostPorgroup VMKNic Policy ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_VMKName'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit NetworkFailoverPolicy and get compliance status  ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkFailoverPolicy' .
           '5. Select NewFixedFailoverCriteria  ' .
           '6. Change checkBeacon = false ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup Autoconf and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select StatelessAutoconfPolicy' .
           '5. Select StatelessAutoconfOption   ' .
           '6. Edit HostPorgroup STATELESS AUTOCONF POLICY ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_STATELESSAUTOCONFPOLICY'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit HostPortGroup Fixed Dhcp6 Policy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select FixedDhcp6Policy' .
           '5. Select FixedDhcp6Option   ' .
           '6. Edit HostPorgroup GroupFixedDhcp6Policy ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_FixedDhcp6Policy'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch LinkSpecPolicyPnicsbyName and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select LinkSpecPolicy' .
           '5. Select PnicsByName    ' .
           '6. Change nicName = vmnic2 ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_VSWITCH_LINKSPEC'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'Edit_VSWITCH_LINKSPEC' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_LINK_PATH,
            policyid => VDNetLib::TestData::TestConstants::VSWITCH_LINKSPEC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::VSWITCH_LINKSPEC_OPTION,
            name    => VDNetLib::TestData::TestConstants::VSWITCH_NICNAME,
            value   => VDNetLib::TestData::TestConstants::VSWITCH_NICNAME_VALUE,
         },
       },
      },
      'VswitchBeaconConfigPolicy'   => {
         TestName         => 'VswitchBeaconConfigPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit Vswitch BeaconConfig and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Vswitch Profile '.
           '4. Select BeaconConfigPolicy' .
           '5. Select NewFixedBeaconConfig  ' .
           '6. Edit interval = 2 ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_VSWITCH_BEACONCONFIG'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch NumPorts and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Vswitch Profile '.
           '4. Select NumPortsPolicy' .
           '5. Select FixedNumPorts  ' .
           '6. Edit numPorts = 30 ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_VSWITCH_NUM_PORTS'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         TestName         => 'VswitchNumPorts',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit Vswitch NetworkSecurityPolicy and get compliance status  ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkSecurityPolicy' .
           '5. Select NewFixedSecurityPolicyOption  ' .
           '6. Change allowPromiscuous, ' .
           '7. Does Compliance Check'.
           '8. Change forgedTransmits ' .
           '9. Does Compliance Check'.
           '10. Change macChanges' .
           '11. Does Compliance Check'.
           '12. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["Edit_allowPromiscuous"],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_macChanges"],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ["Edit_forgedTransmits"],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch NetworkTrafficShaping Policy and get compliance status  ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NewFixedTrafficShapingPolicyOption  ' .
           '5. Select FixedTrafficShapingPolicyOption ' .
           '6. Change averageBandwidth=1111 ' .
           '7. peakBandwidth=2222 ' .
           '8. burstSize=3333  ' .
           '9. Does Compliance Check'.
           '10. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_SHAPING_AVERAGE_BANDWIDTH'],
              ['Edit_SHAPING_PEAK_BANDWIDTH'],
              ['Edit_SHAPING_BURST_SIZE'],
              ['Edit_SHAPING_ENABLE'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch NetworkNicOrderPolicy and get compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicOrderPolicy' .
           '5. Select FixedNicOrdering    ' .
           '6. Edit activeNics=[vmnic1, vmnic3] ' .
           '7. standbyNics=[vmnic2] ' .
           '8. Does Compliance Check'.
           '9. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NIC_ORDER_STANDBY'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
      'VswitchNetworkNicOrderPolicyNegative'   => {
         TestName         => 'VswitchNetworkNicOrderPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit Vswitch NetworkNicOrderPolicy and get compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicOrderPolicy' .
           '5. Select FixedNicOrdering    ' .
           '6. Edit activeNics with invalid value' .
           '7. Result: FAIL ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_NIC_ORDER_ACTIVE_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NIC_ORDER_STANDBY_NEG'],
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
         'Edit_NIC_ORDER_ACTIVE_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::ACTIVE_NICS,
            value   => VDNetLib::TestData::TestConstants::INVALID_NIC,
            expectedresult => 'FAIL',
         },
         'Edit_NIC_ORDER_STANDBY_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::VSWITCH_NETWORK_PATH,
            policyid => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::NETWORK_ORDER_POLICY_OPTION,
            name    => VDNetLib::TestData::TestConstants::FIXEDNICORDERING_STANDBYNICS,
            value   => VDNetLib::TestData::TestConstants::INVALID_NIC,
            expectedresult => 'FAIL',
         },
       },
      },
      'VswitchNetworkNicTeamingPolicy'   => {
         TestName         => 'VswitchNetworkNicTeamingPolicy',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit Vswitch NetworkNicTeamingPolicy and get compliance status' ,
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
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCID'],
              ["GetComplianceStatus_1"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_SRCMAC'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_LOADBASED_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_NICTEAM_EXPLICIT'],
              ["GetComplianceStatus"],

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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
            expectedresult => 'FAIL',
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
         Summary          => 'Edit Vswitch NetworkNicTeamingPolicy Rolling Order and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Change rollingOrder=False/True  ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],

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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
           'expectedresult'   => 'FAIL' ,
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
         Summary          => 'Edit Vswitch NetworkNicTeaming Notify Switch and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. notifySwitches=False/True ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch NetworkNicTeaming Reverse Policy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select NetworkNicTeamingPolicy' .
           '5. Select FixedNicTeamingPolicyOption   ' .
           '6. Change reversePolicy=False/True ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit DvSwitch  DvsPortSelectionPolicy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. Select DvsPortSelectionPolicy' .
           '5. Select FixedDVPortgroupSelectionOption  ' .
           '6. Edit DVSHOSTNIC NAME ' .
           '7. Does Compliance Check'.
           '8. Edit DVSHOSTNIC PORTGROUP NAME ' .
           '9. Does Compliance Check'.
           '10. Result: compliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVSHOSTNIC_PORTGROUP_NAME'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit DvSwitch DvsEarlyBootVnicPolicy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. Select DvsEarlyBootVnicPolicy' .
           '5. Select VmknicDefaultEarlyBootOption  ' .
	   '6. Edit DVS VNIC ACTIVE UPLINKS ' .
           '7. Does Compliance Check'.
	   '8. Edit DVS VNIC TEAM_IP ' .
           '9. Does Compliance Check'.
	   '10. Edit DVS VNIC TEAM_SRCID' .
           '11 Does Compliance Check'.
           '12. Result: nonCompliant ' ,
         PMT              => '',
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_VNIC_TEAM_IP'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_VNIC_TEAM_SRCID'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch MtuPolicy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit VSwitch Profile '.
           '4. Select MtuPolicy' .
           '5. Select FixedMtuOption   ' .
           '6. Edit MTU Size ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Vswitch NetworkFailoverPolicy and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit HostProgroup Profile '.
           '4. Select NetworkFailoverPolicy' .
           '5. Select NewFixedFailoverCriteria   ' .
           '6. Edit NewFixedFailoverCriteria   ' .
           '   checkBeacon = false ' .
           '7. Does Compliance Check'.
           '8. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit SingularPnicPolicy and get compliance status' ,
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
           '12. Does Compliance Check'.
           '13. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
                        ports   => "4",
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
                     '[2]'   => {
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
              ['EditSingularPnic'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['EditSingularPnic_1'],
              ["GetComplianceStatus_1"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'EditSingularPnic' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::DVS_UPLINK_KEY,
            policyid  => VDNetLib::TestData::TestConstants::DVS_PNIC_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::DVS_PNIC_OPTION,
            name    => VDNetLib::TestData::TestConstants::DVS_PNIC_NAME,
            value   => VDNetLib::TestData::TestConstants::DVS_PNIC_NAME_VALUE,
         },
         'EditSingularPnic_1' => {
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
         Summary          => 'Edit DvSwitchDvsUplinkPortPolicy get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Dvs Profile '.
           '4. Select DvSwitch DvsUplinkPortPolicy ' .
           '5. Select UplinkPortgroupOption   ' .
           '   uplinkPort = "Uplink 1" ' .
           '   uplinkPortGroup = "DVS 6 0-DVSUplinks" ' .
           '6. Does Compliance Check'.
           '7. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DVS_PORTGROUP'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Netstack IPv6Enabled and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Instance Max Connection ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit netstack max connection and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Instance Max Connection ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit netstack congestion control algorithm and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Congestion Ctrl Algorithm ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus_1"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_CONGESTIONCTRLALGORITHM_CUBIC'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit dnsconfig dns server address and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt DNS Server address ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
     'NetStackDnsCOnfigDomainName'   => {
         TestName         => 'NetStackDnsCOnfigDomainName',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit netstack dnsconfig domain name and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Eidt Netstack Dns COnfig DomainName ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit search domain and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Change DnsConfigPolicy option DHCP to false ' .
           '4. Eidt Netstack Dns Config SearchDomain name' .
           '5. Does Compliance Check'.
           '6. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_DNSCONFIG_SEARCHDOMAIN'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit dnsconfig param and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Netstack Instance DnsConfig Dhcp ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit IP address profile and get compliance status ' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit netstack IP address profile ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_IPADDRESS_USERINPUTIPADDRESS'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_DHCP'],
              ['Edit_IPADDRESS_FIXEDDHCPOPTION'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_DHCP'],
              ['Edit_IPADDRESS_USERINPUTIPADDRESS_USEDEFAULT'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_DNSCONFIG_DHCP'],
              ['Edit_IPADDRESS_FIXEDIPCONFIG'],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
         },
         'GetComplianceStatus_1' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
            expectedresult => 'FAIL',
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
         Summary          => 'Edit Static Route and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Netstack Static Route IP Network  ' .
           '4. Does Compliance Check'.
           '5. Edit Netstack STATIC IP ROUTE PREFIX ' .
           '6. Does Compliance Check'.
           '7. Edit Netstack STATIC IP ROUTE GATEWAY ' .
           '8. Does Compliance Check'.
           '9. Result: nonCompliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_PREFIX'],
              ["GetComplianceStatus"],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_GATEWAY'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         Summary          => 'Edit Static Route device and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
           '2. Generate Answer file  ' .
           '3. Edit Netstack STATIC IP ROUTE DEVICE  ' .
           '4. Does Compliance Check'.
           '5. Result: nonCompliant ' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'false',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
           'expectedresult' => 'FAIL',
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
         'Edit_STATIC_IP_ROUTE_FAMILY' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::FAMILY,
            value   => VDNetLib::TestData::TestConstants::FAMILY_TYPE,
            adapter => 'host.[1].vmknic.[0]',
            expectedresult => "FAIL",
         },
       },
     },
     'NetStackStaticRouteFamily'   => {
         TestName         => 'NetStackStaticRouteFamily',
         Category         => 'Host Profiles',
         Component        => 'Network Plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Edit static route - family and get compliance status' ,
         Procedure        =>
           '1. Extract HostProfile  ' .
	   '2. Generate answer file ' .
           '3. Edit Netstack  STATIC IP ROUTE FAMILY with invalid value ' .
	   '4. expected to FAIL ' .
           '5. Extract HostProfile  ' .
	   '6. Generate answer file ' .
           '7. Edit Netstack  STATIC IP ROUTE FAMILY ' .
           '8. Does Compliance Check'.
           '9. Result: Compliant ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
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
              ['Edit_STATIC_IP_ROUTE_FAMILY_NEG'],
              ["CreateProfile"],
              ["GenerateAnswerFile"],
              ['Edit_STATIC_IP_ROUTE_FAMILY'],
              ["GetComplianceStatus"],
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
         'GetComplianceStatus' => {
           'Type'         => 'Host',
           'TestHost'     => 'host.[1]',
           'compliancestatus'  => 'true',
           'hostprofilefile'   => '/tmp/hp.xml',
           'answerfile'   => '/tmp/ans.xml',
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
         'Edit_STATIC_IP_ROUTE_FAMILY_NEG' => {
            Type     => 'Host',
            TestHost => 'host.[1]',
            editprofile => '/tmp/hp.xml',
            profilepath => VDNetLib::TestData::TestConstants::STATIC_ROUTE_KEY,
            policyid  => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_POLICY,
            policyoption => VDNetLib::TestData::TestConstants::STATIC_IP_ROUTE_OPTION,
            name    => VDNetLib::TestData::TestConstants::FAMILY,
            value   => VDNetLib::TestData::TestConstants::FAMILY_TYPE,
            adapter => 'host.[1].vmknic.[0]',
            expectedresult => "FAIL",
         },
       },
     },
   )
}


########################################################################
#
# new --
#       This is the constructor for NetstackProfileTds
#
# Input:
#       none
#
# Results:
#       An instance/object of NetstackProfileTds class
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
   my $self = $class->SUPER::new(\%NetworkProfile);
   return (bless($self, $class));
}

1;
