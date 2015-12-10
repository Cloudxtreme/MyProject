#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Sample::TemplateTds;

#
# This file contains the structured hash for category, Functional tests
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
   @TESTS = ("Testcase1",);

   %TestSet = (
      'Testcase1' => {
         UID               => "_NNNNNNN",
         Component         => # Component field in buzilla
         Category          => # Category field in buzilla
         SLA               => "Tags like BATS, POTS",
         Type              => "Test case type like Functional,Stress",
         TimeEstimate      => "execution time of the test, " .
                              "for the exact format, lookup the QATLC Docs",
         AutomationStatus  => "automated/not automated/not automatable",
         Priority          => "P0, P1",
         TestSubType       => "sub type., optional",
         Notes             => "key/value pair of parameters,  each parameter" .
                              "is delimited by semi-colon, optional",
         Summary           => "high-level concise description",
         Environment       => {
            Platform       => "ESX/ESXi/WS",
            Build          => "164009. # allow logical operators like >=<",
            Version        => "4.1.0",
            GOS            => "follows VMQA naming convention",
            Driver         => "vmxnet, vmxnet3..",
            DriverVersion  => "Driver Version",
            ToolsVersion   => "Tools version",
            Setup          => "INTER/INTRA., can be extended further",
            NOOFMACHINES   =>  "integer indicating no. of machines in the " .
                                "test bed excluding host",
         },

         PreConditions     => "xxxx.",
         Parameters        =>    {
            Override       =>      # 1/0 to indicate whether values given at
                                   # command line for vnic,switch,pnic should
                                   # be overwritten or not. Default is zero.
                                   # For example, if a test case can work only
                                   # with specified vnic, switch, pnic type
                                   # then the command line options should be
                                   # ignored in that case.
            SUT            => {
               'host'        => 1, # takes 0/1, indicates if host is needed or
                                   # not. Currently default is 1.
               'vm'          => 0, # takes 0/1, indicates whether VM is needed
                                   # or not. default is 0
               'vnic'        => ['vmxnet3:1','e1000:2'], # array of values
                                   # in the format <adapterType>:<count>
                                   # Supported adapter types are e1000, e1000e,
                                   # vmxnet3, vmxnet2, vlance, oxgbe, bnx2
                                   # max count value is 9
               'switch'      => ['vss:1','vds:1'],  # array of values
                                   # in the format <switchType>:<count>
                                   # Supported switch types vss/vds.
               'pnic'        => ['ixgbe:1','bnx2:1'], # array of values
                                   # in the format <pnicType>:<count>
                                   # Supported switch types ixgbe,bnx2.

            },
            helper1     => {
               host        => 1,
                              # host whether specified or not, it is mandatory.
                              # If vnic alone is specified, then vm will be
                              # automatically set to 1 (if not defined) and
                              # switch will set to [vss:1] (if not defined).
                              # if a value of switch is vds, the parameter "vc
                              # will be set to 1
               'vnic'      => ['vmxnet3:1','e1000:2'],
            },                # extended as helper2, helper3, ...helpern
                              # depending on the number helper machines needed
         },
         Procedure         => "function pointer that implements the test",
         Positive          => "True/False. False: it is a negative test case",
         ExpectedResult    => "PASS/FAIL",

         VMX   => {
            SUT      => "command separated vmx entries",
            Helper   => "command separated vmx entries",
         },

         WORKLOADS => {
            Iterations        => "n",
            Sequence          => "An array of array representing the " .
                                 "pattern/sequence/order to run " .
                                 "workloads/steps ",
                                 # Example: [['NetAdapter_1', 'TRAFFIC_1'],
                                 #          ['Command_1','VMOperation_1',]],
            Duration          => "time in seconds",


            "VMOperation_1" => {
               Type           => "VMOperation",
               Iterations     => "n",
               Timeout        => 'X',
               Target         => [SUT, helper],
               OnEvent        => "",
               ONState        => "",
               ExpectedResult => "",
               Verification   => "",
               Operation      => "Name of the operation like SuspendResume, " .
                                 "SnapshotCreate, SnapshotRevert, vmotion",
               WaitTime       => "If the operations are comma separated, " .
                                 "then interval between each operation",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Iterations     => "n",
               Timeout        => 'X',
               Target         => [SUT, helper1],
               Verification   => "method name, or point to another workload " .
                                 "module (mostly traffic module)",
               OnEvent        => "",
               OnState        => "",
               ExpectedResult => "",
               MTU            => "",
               VLAN           => "",

            },

            "Command_1" => {
               Type           => "Command",
               Command        => "ping",
               Args           => "-c 10 10.20.84.51",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               Iterations     => "n",
               Timeout        => 'X',
               OnEvent        => "",
               OnState        => "",
               ExpectedResult => "",
               ToolName       => "netperf,iperf,ping",
               NoOfInbound    => "number of inbound sessions",
               NoOfOutbound   => "number of outbound sessions",
               RoutingScheme  => "unicast,multicast",
               PktFragment    => '',
               MessageSize    => "54-52,1",
               ReceiveSocketSize => '',    #Receive socket buffer size
               SendSocketSize => '',   #Send socket buffer size
               PktInterval    => '',
               AddressFamily  => "AF_INET, AF_INET6",
               TestDuration   => '',
               L3Protocol     => "IPv4,IPv6,ICMP,ICMPv6",  #TCP, UDP
               L4Protocol     => "TCP,UDP",  #TCP, UDP
               BurstType      => "TCP_STREAM,TCP_RR , UDP_RR",
               DataFile       => '', #pointer to data file
               LocalBufferAlignment => '', #to alter alignment of buffer used in
                                           #tx and rx calls on local mahcine
               RemoteBufferAlignment => '', #to alter alignment of buffer used
                                            #in tx and rx calls on remote machine
               PortNumber     => '',   # Port number on which server should listen.
               BufferRings    => '',   # Number of buffers in send/receive
                                       # buffer rings.
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for TestSetTds
#
# Input:
#       none
#
# Results:
#       An instance/object of TestSetTds class
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
   my $self = $class->SUPER::new(\%TestSet);
   return (bless($self, $class));
}

1;
