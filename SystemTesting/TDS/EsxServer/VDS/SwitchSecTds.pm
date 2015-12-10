#!/usr/bin/perl
#########################################################################
#Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::VDS::SwitchSecTds;

#
# This file contains the structured hash for category, TDS tests
# The following lines explain the keys of the internal Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{

   %SwitchSecTds = (
      'IPDiscoveryTrustedTrueAll'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryTrustedTrueAll',
         Summary          => 'Ensure the E-2-E Functionality  of IP Discovery in '.
			     'trusted (true) mode.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups '.
                             '2. Configure IP Discovery in trusted = true mode'.
                             '3. Test the End to End Functionality.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryTrustedFalse_IPSrcGuardDAIDisable'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryTrustedFalse_IPSrcGuardDAIDisable',
         Summary          => 'Ensure the E-2-E Functionality  of IP Discovery in '.
			     'trusted (false) mode with DAI and IP Src Guard Disabled',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Keep DAI and IP Source Guard disabled'.
                             '4. Test the End to End Functionality.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryTrustedFalse_IPSrcGuardDAIEnable'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryTrustedFalse_IPSrcGuardDAIEnable',
         Summary          => 'Ensure the E-2-E Functionality  of IP Discovery in '.
			     'trusted (false) mode with DAI and IP Src Guard Enabled',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Enable DAI and IP Source Guard'.
                             '4. Test the End to End Functionality.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryStaticIPAddition'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryStaticIPAddition',
         Summary          => 'Ensure that the Static IP addresses added '.
			     'are properly stored in the Authoritative DB.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true mode'.
                             '3. Add the Static Entries in to the DB.'.
                             '4. Check the DB Addition & DB clear options.'.
                             '5. Now Configure IP Discovery in trusted = false'.
                             '6. Again add the Static Entries in to the DB.'.
                             '7. Check the DB Addition & DB clear options.'.
                             '8. The DB entries should be cleared/added as expected.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoverySpecificDBEntryDeletion'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoverySpecificDBEntryDeletion',
         Summary          => 'Ensure that the Specific DB Entries are properly '.
			     'deleted from Authoritative DB.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups '.
                             '2. Configure IP Discovery in trusted = true mode'.
                             '3. See the DB Entries are added by Static/DHCP Snooping'.
                             '4. Clear a specific DB Entry.'.
                             '5. Now Configure IP Discovery in trusted = false'.
                             '6. Clear a specific DB Entry and validate it.'.
                             '7. Check if the specified entry is removed from DB.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryMaxDBSize'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryMaxDBSize',
         Summary          => 'Ensure that Setting the DB Size will exactly '.
			     'limit the number of entries in the DB.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true/false modeis'.
                             '3. Set the DB size to some positive integer value > 0.'.
                             '4. The Max DB size can be extended upto 64'.
                             '5. Add the static and Dynamic IP Entries to DB'.
                             '6. Check if the DB size is properly taken care.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoverySwitchingModes'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoverySwitchingModes',
         Summary          => 'Ensure the Non Authorized DB is removed when trusted '.
			     'option is switched between trusted & non trusted.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true mode'.
                             '3. Generate traffic from VM configured with Static IP.'.
                             '4. By means of TOFU and DAI the IP addresses are learnt'.
                             '5. Switch the trusted mode to false.'.
                             '6. Non Authoritative DB need to be removed in this mode.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryBlockARPPoisoning'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryBlockARPPoisoning',
         Summary          => 'Ensure that the ARP Poisoning is blocked with the '.
			     'IP Discovery and IP Source Guard.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On IP Discovery and IP Source Guard.'.
                             '4. Generate the ARP Poisoning traffic'.
                             '5. The ARP Poisoning traffic should be blocked',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryBlockARPFlooding'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryBlockARPFlooding',
         Summary          => 'Ensure that the ARP Flooding is blocked '.
			     'with the DAI and rate limiting options.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On IP Discovery, DAI & IP Source Guard.'.
                             '4. Generate the ARP Flooding traffic'.
                             '5. The ARP Flooding traffic should be blocked',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryPreventIPSpoofing'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryPreventIPSpoofing',
         Summary          => 'Ensure that the IP Address Spoofing is prevented '.
			     'with the IP Discovery and IP Source Guard in place.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Discovery, DAI & IP Source Guard.'.
                             '4. Let the IP Discovery detect the IP address '.
                             '5. Generate the IP Spoofed TCP/UDP traffic'.
                             '6. The ARP Flooding traffic should be blocked',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'SwitchSecurityCounters'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'SwitchSecurityCounters',
         Summary          => 'Ensure that the statistics of the IP Source Gurad '.
			     'and DAI goes into the respective VSI Counters and in '.
			     'their respective PortGroups/Ports/DVS.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On IP Discovery, DAI & IP Source Guard.'.
                             '4. Generate the ARP Flooding/IP Spoofing traffics'.
                             '5. Check if the respective counters at respective levels are updated',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryDBQueries'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryDBQueries',
         Summary          => 'DB entries to be queried on the port/port group level.'.
			     'For given IP even we be able to query the DB Entries.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On IP Discovery, DAI & IP Source Guard.'.
                             '4. Generate the traffic and populate the DB entries'.
                             '5. Query the DB for the list with the APIs provided',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'SwitchSecurityEventsNotifications'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'SwitchSecurityEventsNotifications',
         Summary          => 'Notification is generated to update the registered users and '.
			     'on any other events to the DB entries',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On IP Discovery, DAI & IP Source Guard.'.
                             '4. Generate the traffic and populate the DB entries'.
                             '5. Add Static IP addresses to the IP Discovery DB '.
                             '6. Check if the event is raised for the IP addition',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'SwitchSecurityHotFilterAdd'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'SwitchSecurityHotFilterAdd',
         Summary          => 'Hot Filter - Adding and removing functions should '.
			     'allowed and filters drop traffic respectively',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On IP Discovery, DAI & IP Source Guard.'.
                             '4. Check this functionality both with static & dynamic IP'.
                             '5. Generate the traffic and this traffic should be blocked'.
                             '6. Trun Off IP Discovery, DAI & IP Source Guard.'.
                             '7. Generate the traffic and this traffic should be Allowed',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryDAIAllowARPProbes'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryDAIAllowARPProbes',
         Summary          => 'Ensure that ARP probes are not filtered even when DAI is enabled.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Discovery, DAI'.
                             '4. Generate ARP and they should not be blocked',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPSourceGuardDAI_EventsonTrafficViolation'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPSourceGuardDAIEventsonTrafficViolation',
         Summary          => 'Event to raised to the VC upon violation occurred '.
			     'due to DAI and IP Source Guard.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On DAI & IP Source Guard'.
                             '4. Generate traffic causing the IP/ARP Flooding, Poisoning attacks'.
                             '5. Upon traffic violaitions the respective events should be raised.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryDBEntriesintact'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryDBEntriesintact',
         Summary          => 'Ensure that the Port DB rules which is exposed/added shoud be in Sync '.
			     'with the rules that are dumped from VSI at any instance of time.'.
			     'Check the DB entries upon Reboot case even.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Trun On DAI & IP Source Guard'.
                             '4. Generate DHCP traffic & let the DB be populated'.
                             '5. DB Entries should be in tact at any instance of time in UI/CLI'.
                             '6. Reboot the Host'.
                             '7. Check the status of the DB upon reboot',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDicsoverywithDHCPServerBlock'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDicsoverywithDHCPServerBlock',
         Summary          => 'Ensure the feature functions properly with the DHCP Server Block '.
			     'feature Enabled and Disabled.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Generate DHCP traffic & let the DB be populated'.
                             '4. DB Entries should be in tact at any instance of time in UI/CLI'.
                             '5. Reboot the Host'.
                             '6. Check the status of the DB upon reboot',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryDBEntriesTimoutValues'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryDBEntriesTimoutValues',
         Summary          => 'Ensure that all the DB entires Timeouts/removed automatically after the '.
			     'respective durations of their timeouts ',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Generate DHCP traffic & let the DB be populated'.
                             '4. Let these entries timeout depending on the way they are learnt'.
                             '5. No stray entries retained',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'DAI_ErrorRateLimit_ErrorRateLimitPeriod'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'DAI_ErrorRateLimit_ErrorRateLimitPeriod',
         Summary          => 'Check the Error Rate Limit and Error Rate Period functionalities.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On DAI and set the Rate limit along with Error Limit Values'.
                             '4. Generate flood of packets to hit the rate limit'.
                             '5. Check if the Rate limit & Error limit is imposed.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPSourceGuard_DAI_SwitchSecurityOverrideAllowed'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPSourceGuard_DAI_SwitchSecurityOverrideAllowed',
         Summary          => 'Ensure the properties set at the port level is overridden by the '.
			     'properties set at the Port group level.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On DAI and set the Rate limit along with Error Limit Values'.
                             '4. Set the above options at different levels as port/PG/DVS.'.
                             '5. Check if the precedence is taken care properly.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_IPSourceGuard_DAI_vMotion'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_IPSourceGuard_DAI_vMotion',
         Summary          => 'Ensure that the functionality of the DAI and IP Source Guard '.
			     'behaves properly even after the vMotion',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Source Guard and DAI with Rate Limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Generate the traffic between VMs acrros different hosts.'.
                             '6. Let the protected VM be vMotioned.'.
			     '7. Even after vmotion the security ipolicies for the '.
			     'protected vm be intact.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_IPSourceGuard_DAI_HA_FT'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_IPSourceGuard_DAI_HA_FT',
         Summary          => 'Ensure that the functionality of the DAI and IP Source Guard '.
			     'behaves properly even after the HA FT',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Source Guard and DAI with Rate Limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Generate the traffic between VMs acrros different hosts.'.
                             '6. Execute HA-FT trigger in and the traffic should flow properly',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_IPSourceGuard_DAI_PVLAN'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_IPSourceGuard_DAI_PVLAN',
         Summary          => 'Ensure traffic flows properly with PVLAN Configured along '.
			     'with the IP Source Guard and DAI.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Source Guard and DAI with Rate Limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Configure PVLAN Setting to the ports/port groups'.
                             '6. These packets should flow properly without any issue',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_IPSourceGuard_DAI_VLAN'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_IPSourceGuard_DAI_VLAN',
         Summary          => 'Ensure traffic flows properly with VLAN Configured along '.
			     'with the IP Source Guard and DAI.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Source Guard and DAI with Rate Limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Configure VLAN Setting to the ports/port groups'.
                             '6. These packets should flow properly without any issue',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_IPSourceGuard_DAI_JumboFrame'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_IPSourceGuard_DAI_JumboFrame',
         Summary          => 'Ensure Jumbo frames are honoured properly when configured '.
			     'along with the IP Source Guard and DAI.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Source Guard and DAI with Rate Limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Configure Jumbo Frames and Allow the Jumbo packets on those ports'.
                             '6. These packets should flow properly without any impact',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_IPSourceGuard_DAI_IPV6'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_IPSourceGuard_DAI_IPV6',
         Summary          => 'Ensure IPv6 packets are honoured properly when configured '.
			     'along with the IP Source Guard and DAI.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On IP Source Guard and DAI with Rate Limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Configure IPv6.'.
                             '6. IPv6 traffic should flow without any impact.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'DAI_RateLimit_ErrorLimit_ErrorLimitPeriod_Negative'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'DAI_RateLimit_ErrorLimit_ErrorLimitPeriod_Negative',
         Summary          => 'Ensure that the Rate Limit/ Error Rate/ Error Rate Period takes in '.
			     'proper values are security patterns and negative cases',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn On DAI with Rate Limit & Error limit Values'.
                             '4. Now let the IP Discovery DB be populated'.
                             '5. Configure the DAI Configuration parameters with negative '.
			     'and security patterns',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryStaticInvalidIPEntries_Negative'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryStaticInvalidIPEntries_Negative',
         Summary          => 'Ensure that the DB takes all the properly validated MAC/IP and VLAN Values.'.
			     'This should be covering all the negative and security patterns even.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true/false mode'.
                             '3. Now let the IP Discovery DB be populated'.
                             '4. Configure the Static IP Addresses to the IP Discovery DB.'.
                             '5. Configure the entries with negative and security patterns',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryMaxDBSize_Negative'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryMaxDBSize_Negative',
         Summary          => 'Ensure that the DB Limit takes in proper values to some valid Limit.'.
			     'This should be covered for the security patterns.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true/false modes'.
                             '3. Now let the IP Discovery DB be populated'.
                             '4. Configure the DB Size with negative and security patterns',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryStaticIP_PortGroupDVS_UnExposed'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryStaticIP_PortGroupDVS_UnExposed',
         Summary          => 'Ensure that adding of Static IP addresses should not be '.
			     'allowed/exposed under the port group/dvs levels.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true/false modes'.
			     '3. Now add the static IP addresses to the DB.'.
			     '4. It should be allowed at the port level.'.
			     '5. The static IP addition should only be allowed at the port '.
			     'levels not at the Port Group levels.'.
			     '6. The UI should be either masked and not allowed to accept the '.
			     'static IP addresses at the port group levels.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryNoLearning'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryNoLearning',
         Summary          => 'Ensure No learning happens when the IP Discovery is turned Off '.
			     'with DAI and IP Source Guard Enabled.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = false mode'.
                             '3. Turn on DAI and IP Source Guard'.
			     '4. Now let the IP Discovery DB be populated'.
                             '5. Now Turn Off IP Discovery'.
			     '6. Check if the DAI & IP Source Guard still functions'.
                             'Note: As per Rahul these two options will even be disabled',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscoveryMaxDBSizeToggle_Negative'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscoveryMaxDBSizeToggle_Negative',
         Summary          => 'Ensure that the DB Limit takes in proper values to some valid Limit.'.
			     'The max size value toggling from low to high values taken care.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true/false modes'.
                             '3. Now let the IP Discovery DB be populated'.
                             '4. Configure the DB Size with negative and toggle the values',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_DAI_IPSrcGuard_FeatureMaskedInTrustedMode'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_DAI_IPSrcGuard_FeatureMaskedInTrustedMode',
         Summary          => 'Ensure that DAI and IP Source Guard is not allowed '.
			     'to be configured in trusted mode.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true mode'.
                             '3. Now let the IP Discovery DB be populated'.
                             '4. Ensure DAI and IP Source guard is not exposed '.
			     'for  configuration',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'IPDiscovery_DBLimit'   => {
         Category         => 'ESX Server',
         Component        => 'vDS, vDS Port and Port Groups',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\Switch Security',
         TestName         => 'IPDiscovery_DBLimit',
         Summary          => 'Ensure that the Server is not hung or paniced or '.
			     'PSODed reaching the maximum number of entries.',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '6647',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Configure IP Discovery in trusted = true/false modes'.
                             '3. Now let the IP Discovery DB be populated'.
                             '4. Allow these Db entries to fill max DB size without PSOD.',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'N',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Negative',
         Priority         => 'P1',
         Developer        => 'vnagendra',
         Testbed          => '',
         Version          => '2' ,

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
#       This is the constructor for SwitchSec
#
# Input:
#       none
#
# Results:
#       An instance/object of SwitchSecTds class
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
      my $self = $class->SUPER::new(\%SwitchSec);
      return (bless($self, $class));
}

1;
